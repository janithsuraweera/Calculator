import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../services/calculator_engine.dart';

/// Handwriting input widget for drawing mathematical expressions
class HandwritingInput extends StatefulWidget {
  final Function(String) onExpressionRecognized;

  const HandwritingInput({super.key, required this.onExpressionRecognized});

  @override
  State<HandwritingInput> createState() => _HandwritingInputState();
}

class _HandwritingInputState extends State<HandwritingInput> {
  final List<Offset> _points = <Offset>[];
  final ui.PictureRecorder _recorder = ui.PictureRecorder();
  late ui.Canvas _canvas;

  @override
  void initState() {
    super.initState();
    _canvas = ui.Canvas(_recorder);
  }

  /// Clear the drawing
  void clear() {
    setState(() {
      _points.clear();
    });
  }

  /// Recognize handwriting and convert to expression
  Future<void> recognize() async {
    // Simplified recognition - in production, use ML Kit or similar
    // This is a placeholder that converts drawn strokes to text
    if (_points.isEmpty) return;

    // For now, return a placeholder
    // In a real implementation, this would use handwriting recognition
    widget.onExpressionRecognized('2+2'); // Placeholder
    clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Drawing area
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _points.add(details.localPosition);
              });
            },
            onPanEnd: (details) {
              setState(() {
                _points.add(Offset.zero); // Mark end of stroke
              });
            },
            child: CustomPaint(
              painter: HandwritingPainter(_points),
              child: Container(),
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
  final List<Offset> points;

  HandwritingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.zero && points[i + 1] != Offset.zero) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(HandwritingPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
