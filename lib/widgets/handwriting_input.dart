import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Handwriting input widget for drawing mathematical expressions
class HandwritingInput extends StatefulWidget {
  final Function(String) onExpressionRecognized;

  const HandwritingInput({super.key, required this.onExpressionRecognized});

  @override
  State<HandwritingInput> createState() => _HandwritingInputState();
}

class _HandwritingInputState extends State<HandwritingInput> {
  final List<List<Offset>> _strokes = <List<Offset>>[];
  List<Offset> _currentStroke = <Offset>[];
  final GlobalKey _paintKey = GlobalKey();

  /// Clear the drawing
  void clear() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
  }

  /// Recognize handwriting and convert to expression using OCR on captured image
  Future<void> recognize() async {
    if (_strokes.isEmpty && _currentStroke.isEmpty) return;
    try {
      final boundary =
          _paintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final file = await File(
        '${Directory.systemTemp.path}/hand_${DateTime.now().millisecondsSinceEpoch}.png',
      ).create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);

      final recognizer = TextRecognizer();
      final input = InputImage.fromFilePath(file.path);
      final recognized = await recognizer.processImage(input);
      await recognizer.close();

      String? candidate;
      final List<String> lines = recognized.text
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      final RegExp mathLike = RegExp(r'^[0-9\s\.,\-\+\*/xX÷×%()=]+$');
      for (final line in lines) {
        if (mathLike.hasMatch(line)) {
          candidate = line;
          break;
        }
      }
      candidate ??= recognized.text.replaceAll('\n', ' ');

      String expr = candidate
          .replaceAll(' ', '')
          .replaceAll(',', '.')
          .replaceAll('x', '×')
          .replaceAll('X', '×')
          .replaceAll('*', '×')
          .replaceAll('/', '÷');
      if (expr.endsWith('=')) {
        expr = expr.substring(0, expr.length - 1);
      }
      if (RegExp(r'[0-9]').hasMatch(expr)) {
        widget.onExpressionRecognized(expr);
      }
    } catch (_) {
      // ignore errors
    } finally {
      clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Drawing area
        RepaintBoundary(
          key: _paintKey,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: GestureDetector(
              onPanStart: (details) {
                setState(() {
                  _currentStroke = [details.localPosition];
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _currentStroke.add(details.localPosition);
                });
              },
              onPanEnd: (details) {
                setState(() {
                  if (_currentStroke.isNotEmpty) {
                    _strokes.add(List.from(_currentStroke));
                    _currentStroke.clear();
                  }
                });
              },
              child: CustomPaint(
                painter: HandwritingPainter(_strokes, _currentStroke),
                child: Container(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Control buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: clear,
              icon: const Icon(Icons.clear),
              label: const Text('Clear'),
            ),
            ElevatedButton.icon(
              onPressed: recognize,
              icon: const Icon(Icons.check),
              label: const Text('Recognize'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Custom painter for handwriting strokes
class HandwritingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  HandwritingPainter(this.strokes, this.currentStroke);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw all completed strokes
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      for (int i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
    }

    // Draw current stroke being drawn
    if (currentStroke.length >= 2) {
      for (int i = 0; i < currentStroke.length - 1; i++) {
        canvas.drawLine(currentStroke[i], currentStroke[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(HandwritingPainter oldDelegate) {
    return oldDelegate.strokes.length != strokes.length ||
        oldDelegate.currentStroke.length != currentStroke.length;
  }
}
