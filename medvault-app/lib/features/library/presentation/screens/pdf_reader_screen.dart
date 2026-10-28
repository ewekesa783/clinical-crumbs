import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/injector.dart';
import '../../../home/presentation/providers/home_dashboard_provider.dart';

/// Displays a locally stored PDF learning resource.
class PdfReaderScreen extends ConsumerStatefulWidget {
  const PdfReaderScreen({
    required this.resourceUuid,
    required this.title,
    required this.filePath,
    super.key,
  });

  final String resourceUuid;
  final String title;
  final String filePath;

  @override
  ConsumerState<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends ConsumerState<PdfReaderScreen> {
  static const _readingModeKey = 'pdf_reader_continuous_mode';
  static const _lastPageKeyPrefix = 'pdf_reader_last_page_';

  PdfControllerPinch? _pinchController;
  PdfController? _pageController;
  SharedPreferences? _preferences;

  int? _pageCount;
  int _currentPage = 1;
  Object? _documentError;
  bool _continuousMode = true;
  bool _isBookmarked = false;
  bool _bookmarkStateLoaded = false;
  bool _bookmarkActionRunning = false;

  @override
  void initState() {
    super.initState();
    _loadPreferencesAndBookmark();
  }

  String get _lastPageKey => '$_lastPageKeyPrefix${widget.resourceUuid}';

  PdfControllerPinch _createPinchController() => PdfControllerPinch(
        document: PdfDocument.openFile(widget.filePath),
        initialPage: _currentPage,
      );

  PdfController _createPageController() => PdfController(
        document: PdfDocument.openFile(widget.filePath),
        initialPage: _currentPage,
      );

  Future<void> _loadPreferencesAndBookmark() async {
    var continuous = true;
    var bookmarked = false;

    try {
      final preferences = await SharedPreferences.getInstance();
      _preferences = preferences;
      continuous = preferences.getBool(_readingModeKey) ?? true;
      _currentPage = preferences.getInt(_lastPageKey) ?? 1;
      if (_currentPage < 1) _currentPage = 1;

      final service = await ref.read(libraryServiceProvider.future);
      bookmarked = await service.isPdfBookmarked(widget.resourceUuid);
    } catch (_) {
      // Continue with safe defaults if preferences or bookmark state fails.
    }

    if (!mounted) return;
    setState(() {
      _continuousMode = continuous;
      _isBookmarked = bookmarked;

      if (continuous) {
        _pinchController = _createPinchController();
      } else {
        _pageController = _createPageController();
      }

      _bookmarkStateLoaded = true;
    });
  }

  @override
  void dispose() {
    _pinchController?.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _toggleBookmark() async {
    if (_bookmarkActionRunning) return;

    setState(() => _bookmarkActionRunning = true);
    try {
      final service = await ref.read(libraryServiceProvider.future);
      if (_isBookmarked) {
        await service.unbookmarkPdf(widget.resourceUuid);
      } else {
        await service.bookmarkPdf(widget.resourceUuid);
      }

      if (!mounted) return;
      setState(() {
        _isBookmarked = !_isBookmarked;
        _bookmarkActionRunning = false;
      });
      ref.invalidate(homeDashboardProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isBookmarked ? 'PDF bookmarked' : 'PDF bookmark removed',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _bookmarkActionRunning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update this bookmark.')),
      );
    }
  }

  Future<void> _setReadingMode(bool continuous) async {
    if (_continuousMode == continuous) return;

    if (continuous) {
      _pageController?.dispose();
      _pageController = null;
      _pinchController?.dispose();
      _pinchController = _createPinchController();
    } else {
      _pinchController?.dispose();
      _pinchController = null;
      _pageController = _createPageController();
    }

    setState(() {
      _continuousMode = continuous;
      _documentError = null;
    });

    try {
      final preferences = _preferences ?? await SharedPreferences.getInstance();
      _preferences = preferences;
      await preferences.setBool(_readingModeKey, continuous);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reading mode changed but could not be saved.'),
        ),
      );
    }
  }

  void _onDocumentLoaded(PdfDocument document) {
    if (!mounted) return;
    setState(() => _pageCount = document.pagesCount);
  }

  void _onDocumentError(Object error) {
    if (!mounted) return;
    setState(() => _documentError = error);
  }

  void _onPageChanged(int page) {
    if (!mounted || page < 1) return;
    setState(() => _currentPage = page);

    // Persist progress on every page change, not only when leaving the reader.
    final preferences = _preferences;
    if (preferences != null) {
      preferences.setInt(_lastPageKey, page);
    } else {
      SharedPreferences.getInstance().then((value) {
        _preferences = value;
        return value.setInt(_lastPageKey, page);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_pageCount != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text('$_currentPage / $_pageCount'),
              ),
            ),
          PopupMenuButton<String>(
            tooltip: 'PDF options',
            onSelected: (value) {
              switch (value) {
                case 'bookmark':
                  _toggleBookmark();
                case 'continuous':
                  _setReadingMode(true);
                case 'single':
                  _setReadingMode(false);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'bookmark',
                enabled: _bookmarkStateLoaded && !_bookmarkActionRunning,
                child: Row(
                  children: [
                    Icon(
                      _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isBookmarked ? 'Remove bookmark' : 'Bookmark this PDF',
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              CheckedPopupMenuItem<String>(
                value: 'continuous',
                checked: _continuousMode,
                child: const Text('Continuous scrolling'),
              ),
              CheckedPopupMenuItem<String>(
                value: 'single',
                checked: !_continuousMode,
                child: const Text('Single page'),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<bool>(
        future: File(widget.filePath).exists(),
        builder: (context, fileSnapshot) {
          if (fileSnapshot.hasError || fileSnapshot.data == false) {
            return const _PdfErrorMessage(
              message: 'This PDF file could not be found on this device.',
            );
          }

          if (!fileSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_documentError != null) {
            return const _PdfErrorMessage(
              message: 'This PDF could not be opened. The file may be damaged '
                  'or password-protected.',
            );
          }

          if (!_bookmarkStateLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_continuousMode) {
            final controller = _pinchController;
            if (controller == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return PdfViewPinch(
              key: const ValueKey('continuous-pdf-view'),
              controller: controller,
              onDocumentLoaded: _onDocumentLoaded,
              onDocumentError: _onDocumentError,
              onPageChanged: _onPageChanged,
              builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                options: const DefaultBuilderOptions(),
                documentLoaderBuilder: (_) =>
                    const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, error) => const _PdfErrorMessage(
                  message: 'Unable to render this PDF.',
                ),
              ),
            );
          }

          final controller = _pageController;
          if (controller == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return PdfView(
            key: const ValueKey('single-page-pdf-view'),
            controller: controller,
            scrollDirection: Axis.horizontal,
            onDocumentLoaded: _onDocumentLoaded,
            onDocumentError: _onDocumentError,
            onPageChanged: _onPageChanged,
            builders: PdfViewBuilders<DefaultBuilderOptions>(
              options: const DefaultBuilderOptions(),
              documentLoaderBuilder: (_) =>
                  const Center(child: CircularProgressIndicator()),
              errorBuilder: (_, error) => const _PdfErrorMessage(
                message: 'Unable to render this PDF.',
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PdfErrorMessage extends StatelessWidget {
  const _PdfErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.picture_as_pdf_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
