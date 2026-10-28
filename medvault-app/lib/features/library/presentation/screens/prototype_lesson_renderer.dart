import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Renders the newer, read-only Clinical Crumbs lesson prototype format.
class _TwoBranchConnectorPainter extends CustomPainter {
  static const _connectorColor = Color(0xFF0C7C78);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _connectorColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final leftX = size.width / 4 - 2;
    final rightX = size.width * 3 / 4 + 2;
    const branchY = 7.0;

    canvas.drawLine(Offset(centerX, 0), Offset(centerX, branchY), paint);
    canvas.drawLine(Offset(leftX, branchY), Offset(rightX, branchY), paint);
    canvas.drawLine(Offset(leftX, branchY), Offset(leftX, size.height), paint);
    canvas.drawLine(
        Offset(rightX, branchY), Offset(rightX, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _TwoBranchConnectorPainter oldDelegate) => false;
}

class _MechanismShapePainter extends CustomPainter {
  const _MechanismShapePainter(this.shape);

  final String shape;

  static const _red = Color(0xFFD8434B);
  static const _darkRed = Color(0xFFB52F38);
  static const _kidneyRed = Color(0xFFC4565A);
  static const _airway = Color(0xFF526777);
  static const _blue = Color(0xFF2F6FB0);
  static const _paleBlue = Color(0xFF9EC7E6);
  static const _palePink = Color(0xFFF4B6B6);
  static const _alveolusPink = Color(0xFFFDF1F1);
  static const _alveolusYellow = Color(0xFFE8C14F);

  Path _path(List<Offset> points, {bool close = false}) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    if (close) path.close();
    return path;
  }

  void _drawLungs(Canvas canvas, bool fluid) {
    final lungPaint = Paint()
      ..color = fluid ? _paleBlue : _palePink
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = fluid ? _blue : _kidneyRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final airwayPaint = Paint()
      ..color = _airway
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(40, 8), const Offset(40, 34), airwayPaint);
    canvas.drawLine(const Offset(40, 30), const Offset(24, 40), airwayPaint);
    canvas.drawLine(const Offset(40, 30), const Offset(56, 40), airwayPaint);

    final left = Path()
      ..moveTo(34, 22)
      ..cubicTo(14, 22, 8, 46, 12, 66)
      ..cubicTo(14, 74, 28, 74, 34, 66)
      ..cubicTo(36, 52, 36, 36, 34, 22)
      ..close();
    final right = Path()
      ..moveTo(46, 22)
      ..cubicTo(66, 22, 72, 46, 68, 66)
      ..cubicTo(66, 74, 52, 74, 46, 66)
      ..cubicTo(44, 52, 44, 36, 46, 22)
      ..close();

    canvas.drawPath(left, lungPaint);
    canvas.drawPath(right, lungPaint);
    canvas.drawPath(left, outline);
    canvas.drawPath(right, outline);
  }

  void _drawKidney(Canvas canvas) {
    final kidney = Path()
      ..moveTo(46, 10)
      ..cubicTo(22, 6, 8, 26, 12, 46)
      ..cubicTo(16, 66, 36, 74, 54, 66)
      ..cubicTo(42, 58, 42, 50, 52, 44)
      ..cubicTo(40, 38, 42, 20, 46, 10)
      ..close();
    canvas.drawPath(
      kidney,
      Paint()
        ..color = _kidneyRed
        ..style = PaintingStyle.fill,
    );
  }

  void _drawAlveoli(Canvas canvas, bool pneumonia) {
    final fill = Paint()
      ..color = pneumonia ? _alveolusYellow : _alveolusPink
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = pneumonia ? const Color(0xFFB7871F) : _kidneyRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (final entry in const [
      (Offset(28, 28), 20.0),
      (Offset(54, 32), 18.0),
      (Offset(40, 56), 20.0),
    ]) {
      canvas.drawCircle(entry.$1, entry.$2, fill);
      canvas.drawCircle(entry.$1, entry.$2, outline);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 80, size.height / 80);

    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (shape) {
      case 'disc':
        canvas.drawCircle(const Offset(40, 40), 32, fill..color = _red);
        canvas.drawCircle(const Offset(40, 40), 13, fill..color = _darkRed);
        break;
      case 'sickle':
        final path = Path()
          ..moveTo(12, 62)
          ..cubicTo(14, 34, 36, 14, 68, 14)
          ..cubicTo(52, 24, 44, 38, 46, 50)
          ..cubicTo(47, 58, 52, 63, 60, 66)
          ..cubicTo(42, 74, 22, 72, 12, 62)
          ..close();
        canvas.drawPath(path, fill..color = _darkRed);
        break;
      case 'strep':
        for (final point in const [
          Offset(14, 46),
          Offset(31, 40),
          Offset(48, 38),
          Offset(65, 42),
        ]) {
          canvas.drawCircle(point, 9, fill..color = const Color(0xFF6B5CA5));
        }
        break;
      case 'heart':
        final path = Path()
          ..moveTo(40, 70)
          ..cubicTo(10, 48, 8, 24, 24, 18)
          ..cubicTo(32, 15, 38, 20, 40, 26)
          ..cubicTo(42, 20, 48, 15, 56, 18)
          ..cubicTo(72, 24, 70, 48, 40, 70)
          ..close();
        canvas.drawPath(path, fill..color = _red);
        break;
      case 'valve':
        canvas.drawCircle(
            const Offset(40, 40), 30, fill..color = const Color(0xFFFBE3E3));
        canvas.drawCircle(
          const Offset(40, 40),
          30,
          stroke
            ..color = _red
            ..strokeWidth = 7,
        );
        break;
      case 'narrowed':
        canvas.drawCircle(const Offset(40, 40), 33, fill..color = _red);
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(40, 40), width: 34, height: 9),
          fill..color = const Color(0xFFFBE3E3),
        );
        break;
      case 'prerenal':
        _drawKidney(canvas);
        final dash = Paint()
          ..color = _blue
          ..strokeWidth = 5
          ..style = PaintingStyle.stroke;
        for (var y = 12.0; y < 43; y += 8) {
          canvas.drawLine(Offset(68, y), Offset(68, y + 4), dash);
        }
        canvas.drawPath(
          _path(const [Offset(60, 40), Offset(68, 56), Offset(76, 40)],
              close: true),
          fill..color = _blue,
        );
        break;
      case 'intrinsic':
        _drawKidney(canvas);
        for (final entry in const [
          (Offset(28, 32), 5.0),
          (Offset(26, 50), 5.0),
          (Offset(40, 42), 4.0),
        ]) {
          canvas.drawCircle(
              entry.$1, entry.$2, fill..color = const Color(0xFF6E1D2A));
        }
        break;
      case 'postrenal':
        _drawKidney(canvas);
        canvas.drawLine(
          const Offset(54, 54),
          const Offset(68, 76),
          stroke
            ..color = _kidneyRed
            ..strokeWidth = 6,
        );
        final cross = Paint()
          ..color = const Color(0xFF222222)
          ..strokeWidth = 3;
        canvas.drawLine(const Offset(58, 64), const Offset(76, 72), cross);
        canvas.drawLine(const Offset(76, 64), const Offset(58, 72), cross);
        break;
      case 'alveolus_normal':
        _drawAlveoli(canvas, false);
        break;
      case 'alveolus_pneumonia':
      case 'alveolus_birth-asphyxia':
        _drawAlveoli(canvas, true);
        break;
      case 'lungs_fluid':
        _drawLungs(canvas, true);
        break;
      case 'lungs_air':
        _drawLungs(canvas, false);
        break;
      default:
        canvas.drawCircle(
            const Offset(40, 40), 28, fill..color = const Color(0xFFDFF5F1));
        canvas.drawCircle(
          const Offset(40, 40),
          28,
          stroke
            ..color = const Color(0xFF075653)
            ..strokeWidth = 2,
        );
        canvas.drawLine(
          const Offset(24, 40),
          const Offset(56, 40),
          stroke
            ..color = const Color(0xFF075653)
            ..strokeWidth = 3,
        );
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MechanismShapePainter oldDelegate) =>
      oldDelegate.shape != shape;
}

class _GoldenMinuteStopwatchPainter extends CustomPainter {
  const _GoldenMinuteStopwatchPainter();

  static const _slate = Color(0xFF526777);
  static const _red = Color(0xFFE8394D);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 80;
    canvas.save();
    canvas.scale(scale, scale);

    final slate = Paint()
      ..color = _slate
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final crown = Paint()
      ..color = _slate
      ..style = PaintingStyle.fill;
    final face = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(33, 4, 14, 9),
        const Radius.circular(2),
      ),
      crown,
    );
    canvas.drawCircle(const Offset(40, 52), 30, face);
    canvas.drawCircle(const Offset(40, 52), 30, slate);

    final hand = Paint()
      ..color = _red
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(40, 52), const Offset(40, 30), hand);
    canvas.drawCircle(const Offset(40, 52), 3, crown);

    final label = TextPainter(
      text: const TextSpan(
        text: '60 s',
        style: TextStyle(
          color: _slate,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    label.paint(canvas, Offset(40 - label.width / 2, 65));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GoldenMinuteStopwatchPainter oldDelegate) =>
      false;
}

class PrototypeLessonRenderer extends StatefulWidget {
  const PrototypeLessonRenderer({
    required this.lesson,
    required this.onChooseAnother,
    required this.resourceUuid,
    this.assets = const {},
    super.key,
  });

  final Map<String, dynamic> lesson;
  final VoidCallback onChooseAnother;
  final String resourceUuid;
  final Map<String, Uint8List> assets;

  @override
  State<PrototypeLessonRenderer> createState() =>
      _PrototypeLessonRendererState();
}

class _PrototypeLessonRendererState extends State<PrototypeLessonRenderer>
    with WidgetsBindingObserver {
  static const _teal = Color(0xFF0C7C78);
  static const _deep = Color(0xFF075653);
  static const _mint = Color(0xFFDFF5F1);
  static const _ink = Color(0xFF102A43);
  static const _muted = Color(0xFF526777);
  static const _line = Color(0xFFDCE5EA);
  static const _red = Color(0xFFC83F49);

  int _index = 0;
  final Map<String, int> _answers = {};
  final Map<String, bool> _flipped = {};
  final Map<String, double> _pageOffsets = {};
  late final ScrollController _scrollController;
  bool _restoringProgress = true;
  bool _progressLoaded = false;

  String get _progressKey => 'clinical_crumbs_lesson_progress_${widget.resourceUuid}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController = ScrollController()
      ..addListener(_saveCurrentOffset);
    _restoreProgress();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveCurrentOffset();
      _persistProgress();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveCurrentOffset();
    _persistProgress();
    _scrollController
      ..removeListener(_saveCurrentOffset)
      ..dispose();
    super.dispose();
  }

  Future<void> _restoreProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIndex = prefs.getInt('${_progressKey}_page') ?? 0;
      final rawOffsets = prefs.getString('${_progressKey}_offsets');

      if (rawOffsets != null) {
        final decoded = jsonDecode(rawOffsets);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            final value = entry.value;
            if (value is num) {
              _pageOffsets[entry.key.toString()] = value.toDouble();
            }
          }
        }
      }

      if (!mounted) return;
      if (_pages.isNotEmpty) {
        _index = savedIndex.clamp(0, _pages.length - 1);
      }
    } catch (_) {
      // A missing or invalid saved position should not prevent reading.
    }

    if (!mounted) return;
    setState(() {
      _restoringProgress = false;
      _progressLoaded = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final offset = _pageOffsets[_currentId] ?? 0;
      _scrollController.jumpTo(
        offset.clamp(
          0,
          _scrollController.position.maxScrollExtent,
        ),
      );
    });
  }

  void _saveCurrentOffset() {
    if (_restoringProgress || !_progressLoaded ||
        !_scrollController.hasClients) {
      return;
    }
    _pageOffsets[_currentId] = _scrollController.offset;
    _persistProgress();
  }

  Future<void> _persistProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${_progressKey}_page', _index);
      await prefs.setString(
        '${_progressKey}_offsets',
        jsonEncode(_pageOffsets),
      );
    } catch (_) {
      // Reading remains available if progress cannot be saved.
    }
  }

  List<dynamic> get _pages =>
      widget.lesson['pages'] is List ? widget.lesson['pages'] as List : [];

  Map<String, dynamic> _map(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<dynamic> _list(Object? value) => value is List ? value : [];

  String _text(Object? value, [String fallback = '']) {
    if (value == null) return fallback;
    final result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  String _humanize(String value) => value
      .replaceAll('_', ' ')
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match[1]} ${match[2]}',
      )
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  Map<String, dynamic> get _currentPage => _map(_pages[_index]);

  String get _currentId => _text(_currentPage['id'], 'page-$_index');

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty) {
      return const Center(child: Text('This lesson has no pages to display.'));
    }

    final page = _currentPage;
    final title = _text(widget.lesson['title'], 'Clinical Crumbs');
    final total = _pages.length;

    return ColoredBox(
      color: const Color(0xFFF3F7F8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 10, 12, 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: _line)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CLINICAL CRUMBS',
                        style: TextStyle(
                          color: _deep,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .5,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(_index + 1).toString().padLeft(2, '0')} / '
                  '${total.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                IconButton(
                  tooltip: 'Choose another lesson',
                  onPressed: widget.onChooseAnother,
                  icon: const Icon(Icons.folder_open_outlined),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 4,
            child: LinearProgressIndicator(
              value: (_index + 1) / total,
              backgroundColor: const Color(0xFFE2E9ED),
              color: _teal,
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: SingleChildScrollView(
                key: ValueKey(_currentId),
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
                child: _renderPage(page),
              ),
            ),
          ),
          _pageDots(total),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: _line)),
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _index == 0 ? null : () => _go(_index - 1),
                  icon: const Icon(Icons.arrow_back, size: 17),
                  label: const Text('Back'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    onPressed: () => _go(_index == total - 1 ? 0 : _index + 1),
                    icon: Icon(
                      _index == total - 1 ? Icons.replay : Icons.arrow_forward,
                      size: 17,
                    ),
                    label:
                        Text(_index == total - 1 ? 'Start again' : 'Continue'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _go(int index) {
    if (index < 0 || index >= _pages.length || index == _index) return;

    if (_scrollController.hasClients && _progressLoaded) {
      _pageOffsets[_currentId] = _scrollController.offset;
    }

    setState(() => _index = index);
    _persistProgress();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final offset = _pageOffsets[_currentId] ?? 0;
      _scrollController.jumpTo(
        offset.clamp(
          0,
          _scrollController.position.maxScrollExtent,
        ),
      );
    });
  }

  Widget _pageDots(int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 5,
        runSpacing: 5,
        children: [
          for (var i = 0; i < total; i++)
            InkWell(
              onTap: () => _go(i),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: i == _index ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _index ? _teal : const Color(0xFFCCD8DD),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _renderPage(Map<String, dynamic> page) {
    final type = _text(page['type']).toLowerCase();
    final title = _text(page['title'], 'Untitled page');

    switch (type) {
      case 'cover':
        return _cover(page);
      case 'case':
        return _casePage(page, title);
      case 'objectives':
        return _objectives(page, title);
      case 'mechanism':
        return _mechanism(page, title);
      case 'groups':
        return _groups(page, title);
      case 'redflags':
        return _redFlags(page, title);
      case 'flow':
        return _flow(page, title);
      case 'investigations':
        return _investigations(page, title);
      case 'management':
        return _management(page, title);
      case 'flashcards':
        return _flashcards(page, title);
      case 'quiz':
        return _quiz(page, title);
      case 'sources':
        return _sources(page, title);
      default:
        return _fallback(page, title);
    }
  }

  Uint8List? _coverArtworkBytes(Map<String, dynamic> page) {
    final embedded = page['artwork_base64'];
    if (embedded is String && embedded.trim().isNotEmpty) {
      try {
        return base64Decode(embedded);
      } on FormatException {
        return null;
      }
    }

    final path = page['artwork'];
    if (path is String) return widget.assets[path];
    return null;
  }

  Widget _coverIllustration(Map<String, dynamic> page) {
    final declared = _text(page['illustration']).toLowerCase().trim();
    final title = _text(page['title']).toLowerCase();
    final isMuac = declared == 'muac' ||
        declared == 'muac_tape' ||
        (declared.isEmpty &&
            (title.contains('malnutrition') ||
                title.contains('muac') ||
                title.contains('sam')));

    if (isMuac) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x66FFFFFF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _muacSegment('<11.5 cm', const Color(0xFFC83F49)),
              _muacSegment('11.5–12.4', const Color(0xFFF59E0B)),
              _muacSegment('≥12.5 cm', const Color(0xFF3AA86B)),
            ],
          ),
        ),
      );
    }

    if (declared == 'lungs' || declared == 'lung' || declared == 'pulmonary') {
      return _lungsIllustration();
    }

    return _genericCoverIllustration();
  }

  Widget _genericCoverIllustration() {
    return Center(
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x66FFFFFF)),
        ),
        child: const Icon(
          Icons.auto_stories_outlined,
          color: Color(0xFFE0F8F4),
          size: 40,
        ),
      ),
    );
  }

  Widget _muacSegment(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 11),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _lungsIllustration() {
    Widget lung({required bool right}) {
      return Transform.rotate(
        angle: right ? -0.26 : 0.26,
        child: SizedBox(
          width: 72,
          height: 99,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                top: 0,
                child: Container(
                  width: 10,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4FFF8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  width: 72,
                  height: 84,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8F3E8),
                    border:
                        Border.all(color: const Color(0x88FFFFFF), width: 4),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(right ? 35 : 45),
                      topRight: Radius.circular(right ? 45 : 35),
                      bottomLeft: Radius.circular(right ? 38 : 42),
                      bottomRight: Radius.circular(right ? 42 : 38),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          lung(right: false),
          const SizedBox(width: 10),
          lung(right: true),
        ],
      ),
    );
  }

  Widget _cover(Map<String, dynamic> page) {
    switch (_text(page['hero_design']).trim().toLowerCase()) {
      case 'golden_minute':
        return _goldenMinuteCover(page);
      default:
        return _standardCover(page);
    }
  }

  Widget _goldenMinuteCover(Map<String, dynamic> page) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 255),
          padding: const EdgeInsets.fromLTRB(21, 24, 21, 24),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_deep, _teal, Color(0xFF46B9A8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -70,
                top: 25,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0x19FFFFFF),
                      width: 26,
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _text(page['eyebrow'], 'CLINICAL CRUMBS'),
                    style: const TextStyle(
                      color: Color(0xFFBDF4E8),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: Text(
                      _text(page['title']),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: Text(
                      _text(page['subtitle']),
                      style: const TextStyle(
                        color: Color(0xFFE0F8F4),
                        height: 1.5,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomPaint(
                            size: Size(72, 82),
                            painter: _GoldenMinuteStopwatchPainter(),
                          ),
                          SizedBox(width: 14),
                          Text(
                            'VENTILATE\nWITHIN 60 s',
                            style: TextStyle(
                              color: Color(0xFF526777),
                              fontSize: 18,
                              height: 1.15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'THE GOLDEN MINUTE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _coverDetails(page,
            'A concise visual walkthrough for clinical students: from first assessment to safe reassessment.'),
      ],
    );
  }

  Widget _coverDetails(Map<String, dynamic> page, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final chip in _list(page['chips']))
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FFFE),
                  border: Border.all(color: const Color(0xFFCFE5E2)),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _text(chip),
                  style: const TextStyle(
                    color: _deep,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(description, style: const TextStyle(color: _muted, height: 1.55)),
        _callout(page['takeaway']),
      ],
    );
  }

  Widget _standardCover(Map<String, dynamic> page) {
    final artworkBytes = _coverArtworkBytes(page);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 245),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_deep, _teal, Color(0xFF46B9A8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _eyebrow(_text(page['eyebrow'], 'CLINICAL CRUMBS')),
              const SizedBox(height: 12),
              Text(
                _text(page['title']),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 31,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _text(page['subtitle']),
                style: const TextStyle(
                  color: Color(0xFFE0F8F4),
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 18),
              if (artworkBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    artworkBytes,
                    width: double.infinity,
                    height: 110,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        _coverIllustration(page),
                  ),
                )
              else
                _coverIllustration(page),
              const SizedBox(height: 22),
              const SizedBox(height: 12),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _coverDetails(
          page,
          'A concise visual walkthrough for clinical students.',
        ),
      ],
    );
  }

  Widget _casePage(Map<String, dynamic> page, String title) {
    final id = _text(page['id'], _currentId);
    final options = _list(page['options']);
    final answer = _answers[id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow('CLINICAL CASE'),
        _heading(title),
        if (page['story'] != null)
          _card(
            'Presentation',
            Text(_text(page['story']), style: _bodyStyle),
          ),
        if (_list(page['observations']).isNotEmpty)
          _observationGrid(_list(page['observations'])),
        if (page['question'] != null) ...[
          _card(
            'Think first',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_text(page['question']), style: _bodyStyle),
                const SizedBox(height: 8),
                for (var i = 0; i < options.length; i++)
                  _option(
                    id: id,
                    index: i,
                    label: _text(options[i]),
                    correct: _asInt(page['answer']),
                    selected: answer,
                  ),
                if (answer != null) _feedback(_text(page['explanation'])),
              ],
            ),
          ),
        ],
        _callout(page['takeaway']),
      ],
    );
  }

  Widget _objectives(Map<String, dynamic> page, String title) {
    final items = _list(page['items']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow('LEARNING MAP'),
        _heading(title),
        for (var i = 0; i < items.length; i++)
          _card(
            '',
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _number('${i + 1}'),
                const SizedBox(width: 12),
                Expanded(child: Text(_text(items[i]), style: _bodyStyle)),
              ],
            ),
          ),
        _callout(page['takeaway']),
      ],
    );
  }

  Widget _mechanism(Map<String, dynamic> page, String title) {
    final comparisons = _list(page['comparison']);
    final visual = _map(page['visual']);
    final visualItems = _list(visual['items']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow('CORE CONCEPT'),
        _heading(title),
        Text(_text(page['body']), style: _bodyStyle),
        const SizedBox(height: 12),
        if (comparisons.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < comparisons.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i == 0 ? 5 : 0,
                      left: i == 0 ? 0 : 5,
                    ),
                    child: _comparisonCard(_map(comparisons[i])),
                  ),
                ),
            ],
          ),
        if (visualItems.isNotEmpty)
          _mechanismVisual(
            _text(visual['label'], 'VISUAL MODEL'),
            visualItems,
          ),
        _callout(page['takeaway']),
      ],
    );
  }

  Widget _mechanismVisual(String label, List<dynamic> items) {
    return _card(
      label,
      LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 12) / 2;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final rawItem in items)
                Builder(
                  builder: (context) {
                    final item = _map(rawItem);
                    final shape = _text(item['shape']).toLowerCase();

                    return SizedBox(
                      width: itemWidth,
                      child: Column(
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CustomPaint(
                              painter: _MechanismShapePainter(shape),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            _text(item['caption']),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _groups(Map<String, dynamic> page, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow('CAUSES & CONTRIBUTORS'),
        _heading(title),
        for (final item in _list(page['groups']))
          _card(
            _text(_map(item)['title']),
            _bulletList(_map(item)['items']),
          ),
        _callout(page['takeaway']),
      ],
    );
  }

  Widget _redFlags(Map<String, dynamic> page, String title) {
    final sections = _list(page['sections']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow('RECOGNITION'),
        _heading(title),
        for (var i = 0; i < sections.length; i++)
          _card(
            '${i == 1 ? '⚠ ' : ''}${_text(_map(sections[i])['title'])}',
            _bulletList(_map(sections[i])['items']),
            tint: i == 1 ? const Color(0xFFFFF5DF) : Colors.white,
          ),
        _callout(page['takeaway']),
      ],
    );
  }

  Widget _flow(Map<String, dynamic> page, String title) {
    final diagram = _list(page['diagram']);
    final nodes = diagram.isNotEmpty ? diagram : _list(page['nodes']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow('CLINICAL REASONING'),
        _heading(title),
        for (var i = 0; i < nodes.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Center(
                child: Icon(Icons.arrow_downward, color: _teal, size: 20),
              ),
            ),
          _flowNode(nodes[i]),
          if (nodes[i] is List && _list(_at(nodes[i], 2)).isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                final branches = _list(_at(nodes[i], 2));
                final branchWidth = (constraints.maxWidth - 8) / 2;

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    children: [
                      if (branches.length == 2)
                        CustomPaint(
                          size: Size(constraints.maxWidth, 14),
                          painter: _TwoBranchConnectorPainter(),
                        ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 14,
                        alignment: WrapAlignment.center,
                        children: [
                          for (var branchIndex = 0;
                              branchIndex < branches.length;
                              branchIndex++)
                            SizedBox(
                              width: branchWidth,
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.arrow_downward,
                                    color: _teal,
                                    size: 18,
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE5F5F2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _text(_at(branches[branchIndex], 0)),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: _deep,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _flowNode([
                                    _at(branches[branchIndex], 1),
                                    _at(branches[branchIndex], 2),
                                  ]),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
        if (page['note'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              _text(page['note']),
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }

  Widget _investigations(Map<String, dynamic> page, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow('INVESTIGATIONS'),
        _heading(title),
        _callout(page['principle']),
        for (final item in _list(page['items']))
          _card(
            _text(_at(item, 0)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_text(_at(item, 1)), style: _bodyStyle),
                const SizedBox(height: 8),
                _tag(_text(_at(item, 2))),
              ],
            ),
          ),
        _callout(page['takeaway']),
      ],
    );
  }

  Widget _management(Map<String, dynamic> page, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow('MANAGEMENT FRAMEWORK'),
        _heading(title),
        for (final step in _list(page['steps']))
          _card(
            '',
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _number(_text(_at(step, 0))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_text(_at(step, 1)),
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      Text(_text(_at(step, 2)), style: _bodyStyle),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (page['warning'] != null) _warning(_text(page['warning'])),
      ],
    );
  }

  Widget _flashcards(Map<String, dynamic> page, String title) {
    final cards = _list(page['cards']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow('ACTIVE RECALL'),
        _heading(title),
        const Text(
          'Tap a card to reveal the answer, then tap again to return to the question.',
          style: TextStyle(color: _muted, height: 1.5),
        ),
        for (var i = 0; i < cards.length; i++)
          InkWell(
            onTap: () => setState(
              () => _flipped['$_currentId-$i'] =
                  !(_flipped['$_currentId-$i'] ?? false),
            ),
            borderRadius: BorderRadius.circular(17),
            child: _card(
              '',
              Column(
                children: [
                  Text(
                    _text(_at(
                        cards[i], _flipped['$_currentId-$i'] == true ? 1 : 0)),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _flipped['$_currentId-$i'] == true
                        ? '↻ Show question'
                        : 'Tap to reveal answer',
                    style: const TextStyle(
                      color: _teal,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _quiz(Map<String, dynamic> page, String title) {
    final questions = _list(page['questions']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow('KNOWLEDGE CHECK'),
        _heading(title),
        for (var i = 0; i < questions.length; i++)
          _card(
            'QUESTION ${i + 1} / ${questions.length}',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_text(_at(questions[i], 0)),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                for (var j = 0; j < _list(_at(questions[i], 1)).length; j++)
                  _option(
                    id: 'quiz-$_currentId-$i',
                    index: j,
                    label: _text(_at(_at(questions[i], 1), j)),
                    correct: _asInt(_at(questions[i], 2)),
                    selected: _answers['quiz-$_currentId-$i'],
                  ),
                if (_answers.containsKey('quiz-$_currentId-$i'))
                  _feedback(_text(_at(questions[i], 3))),
              ],
            ),
          ),
      ],
    );
  }

  Widget _sources(Map<String, dynamic> page, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow('REVIEW GATE'),
        _heading(title),
        if (page['body'] != null) Text(_text(page['body']), style: _bodyStyle),
        _card('Before approval', _bulletList(page['checks'])),
        _card('References to add', _bulletList(page['sources'])),
        _callout(page['takeaway']),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Educational prototype · Clinical review required',
            style: TextStyle(color: _muted, fontSize: 11, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _fallback(Map<String, dynamic> page, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(_humanize(_text(page['type'], 'lesson page'))),
        _heading(title),
        for (final entry in page.entries)
          if (!{'id', 'type', 'title'}.contains(entry.key)) ...[
            _card(
              _humanize(entry.key),
              _genericValue(entry.value),
            ),
          ],
      ],
    );
  }

  Widget _genericValue(Object? value) {
    if (value == null) return const Text('—');
    if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in value)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: item is Map
                  ? _genericValue(item)
                  : Text('• ${_text(item)}', style: _bodyStyle),
            ),
        ],
      );
    }
    if (value is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in value.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_humanize(entry.key.toString()),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  _genericValue(entry.value),
                ],
              ),
            ),
        ],
      );
    }
    return SelectableText(_text(value), style: _bodyStyle);
  }

  Widget _heading(String title) => Padding(
        padding: const EdgeInsets.only(top: 7, bottom: 14),
        child: Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontSize: 25,
            height: 1.12,
            fontWeight: FontWeight.w900,
            letterSpacing: -.6,
          ),
        ),
      );

  Widget _eyebrow(String value) => Text(
        value.toUpperCase(),
        style: const TextStyle(
          color: _teal,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      );

  Widget _card(String title, Widget child, {Color tint = Colors.white}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: tint,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(17),
        boxShadow: const [
          BoxShadow(
              color: Color(0x07102A43), blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );
  }

  Widget _callout(Object? value) {
    if (value == null || _text(value).isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _mint,
        border: Border.all(color: const Color(0xFFC8E9E3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '✦  ${_text(value)}',
        style: const TextStyle(color: _deep, fontSize: 13, height: 1.5),
      ),
    );
  }

  Widget _warning(String value) => Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3DE),
          border: Border.all(color: const Color(0xFFF1D9A8)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text('⚠  $value',
            style: const TextStyle(
                color: Color(0xFF7D5107), height: 1.5, fontSize: 12)),
      );

  Widget _tag(String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F5F1),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(value,
            style: const TextStyle(
                color: _teal, fontSize: 10, fontWeight: FontWeight.w800)),
      );

  Widget _number(String value) => Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: _mint, borderRadius: BorderRadius.circular(10)),
        child: Text(value,
            style: const TextStyle(
                color: _deep, fontWeight: FontWeight.w900, fontSize: 12)),
      );

  Widget _bulletList(Object? value) {
    final items = _list(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  ',
                    style:
                        TextStyle(color: _teal, fontWeight: FontWeight.w900)),
                Expanded(child: Text(_text(item), style: _bodyStyle)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _observationGrid(List<dynamic> observations) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.8,
        children: [
          for (final item in observations)
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_text(_at(item, 0)),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(_text(_at(item, 1)),
                      style: const TextStyle(color: _muted, fontSize: 11)),
                ],
              ),
            ),
        ],
      );

  Widget _option({
    required String id,
    required int index,
    required String label,
    required int correct,
    required int? selected,
  }) {
    final answered = selected != null;
    final isCorrect = index == correct;
    final isSelected = index == selected;
    Color background = Colors.white;
    Color border = _line;
    if (answered && isCorrect) {
      background = const Color(0xFFE5F7EF);
      border = const Color(0xFF5ABF91);
    } else if (isSelected && !isCorrect) {
      background = const Color(0xFFFFF0EF);
      border = const Color(0xFFE5A09A);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(13),
      ),
      child: InkWell(
        onTap: answered ? null : () => setState(() => _answers[id] = index),
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${String.fromCharCode(65 + index)}. ',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, color: _teal)),
              Expanded(
                  child: Text(label,
                      style: const TextStyle(fontSize: 13, height: 1.45))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feedback(String value) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEDF7F4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(value,
            style: const TextStyle(fontSize: 13, height: 1.5, color: _deep)),
      );

  Widget _comparisonCard(Map<String, dynamic> comparison) {
    final tone = _text(comparison['tone']);
    final color =
        tone == 'amber' ? const Color(0xFFFFF5DF) : const Color(0xFFE3F6F2);
    final items = _list(comparison['items']);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_text(comparison['title']),
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 7),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text('• ${_text(item)}',
                  style: const TextStyle(fontSize: 12, height: 1.4)),
            ),
        ],
      ),
    );
  }

  Widget _flowNode(Object? value) {
    final parts = value is List ? value : [value, 'process'];
    final label = _text(_at(parts, 0));
    final kind = _text(_at(parts, 1), 'process');
    final decision = kind == 'decision';
    final danger = kind == 'danger';
    final color = danger
        ? const Color(0xFFFFF0EF)
        : decision
            ? const Color(0xFFFFF4DC)
            : const Color(0xFFE5F5F2);
    final border = danger
        ? const Color(0xFFE9B7B3)
        : decision
            ? const Color(0xFFF1D69B)
            : const Color(0xFFC4E7E1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(decision ? 22 : 12),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: danger ? _red : _ink,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          height: 1.45,
        ),
      ),
    );
  }

  Object? _at(Object? value, int index) {
    if (value is List && index >= 0 && index < value.length) {
      return value[index];
    }
    return null;
  }

  int _asInt(Object? value) =>
      value is int ? value : int.tryParse('$value') ?? -1;

  static const _bodyStyle = TextStyle(
    color: Color(0xFF344E60),
    fontSize: 13,
    height: 1.55,
  );
}
