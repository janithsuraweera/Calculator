import 'package:flutter/material.dart';

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

  /// Clear the drawing
  void clear() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
  }

  /// Recognize handwriting and convert to expression
  Future<void> recognize() async {
    // Simplified recognition - in production, use ML Kit or similar
    // This is a placeholder that converts drawn strokes to text
    if (_strokes.isEmpty && _currentStroke.isEmpty) return;

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
