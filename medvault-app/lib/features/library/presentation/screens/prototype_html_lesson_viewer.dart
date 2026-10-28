import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Displays a self-contained HTML lesson without importing or saving it.
///
/// HTML and its inline CSS/JavaScript are rendered by the platform WebView,
/// preserving the original lesson layout and interactions.
class PrototypeHtmlLessonViewer extends StatefulWidget {
  const PrototypeHtmlLessonViewer({
    required this.html,
    required this.resourceUuid,
    super.key,
  });

  final String html;
  final String resourceUuid;

  @override
  State<PrototypeHtmlLessonViewer> createState() =>
      _PrototypeHtmlLessonViewerState();
}

class _PrototypeHtmlLessonViewerState
    extends State<PrototypeHtmlLessonViewer> with WidgetsBindingObserver {
  late final WebViewController _controller;
  String? _error;

  String get _scrollKey =>
      'clinical_crumbs_html_scroll_${widget.resourceUuid}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'LessonScroll',
        onMessageReceived: (message) {
          final offset = double.tryParse(message.message);
          if (offset != null && offset.isFinite && offset >= 0) {
            _saveScrollOffset(offset);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null || uri.scheme == 'about') {
              return NavigationDecision.navigate;
            }

            // Keep lesson navigation inside the self-contained document.
            return NavigationDecision.prevent;
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame != true) return;
            setState(() {
              _error = 'The HTML lesson could not be displayed: '
                  '${error.description}';
            });
          },
        ),
      );

    _loadHtml();
  }

  Future<void> _saveScrollOffset(double offset) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_scrollKey, offset);
    } catch (_) {
      // A storage failure must not interrupt reading.
    }
  }

  Future<void> _restoreScrollOffset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offset = prefs.getDouble(_scrollKey) ?? 0;
      await _controller.runJavaScript('''
        (() => {
          if (window.__clinicalCrumbsScrollTracking) return;
          window.__clinicalCrumbsScrollTracking = true;
          let lastSent = -1;
          window.addEventListener('scroll', () => {
            const current = Math.round(window.scrollY);
            if (current !== lastSent) {
              lastSent = current;
              LessonScroll.postMessage(String(current));
            }
          }, {passive: true});
        })();
      ''');

      // Retry after layout: long lessons may not have their full scroll
      // extent immediately after loadHtmlString completes.
      for (var attempt = 0; attempt < 8; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        await _controller.runJavaScript('''
          (() => {
            const target = $offset;
            const max = Math.max(
              document.documentElement.scrollHeight,
              document.body ? document.body.scrollHeight : 0
            ) - window.innerHeight;
            window.scrollTo(0, Math.min(target, Math.max(0, max)));
            LessonScroll.postMessage(String(Math.round(window.scrollY)));
          })();
        ''');
      }
    } catch (_) {
      // Some WebView states may not be ready to restore yet.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _captureScrollOffset();
    }
  }

  Future<void> _captureScrollOffset() async {
    try {
      final result =
          await _controller.runJavaScriptReturningResult('String(window.scrollY)');
      final normalized = result.toString().replaceAll('"', '');
      final offset = double.tryParse(normalized);
      if (offset != null && offset.isFinite && offset >= 0) {
        await _saveScrollOffset(offset);
      }
    } catch (_) {
      // The WebView may already be closing.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _captureScrollOffset();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PrototypeHtmlLessonViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html) {
      _error = null;
      _loadHtml();
    }
  }

  Future<void> _loadHtml() async {
    try {
      final html = widget.html;

      await _controller.loadHtmlString(
        html,
        baseUrl: 'about:blank',
      );
      await _restoreScrollOffset();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'The HTML lesson could not be loaded: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_error != null)
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: Material(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!),
              ),
            ),
          ),
      ],
    );
  }
}
