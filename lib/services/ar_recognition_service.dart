import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'calculator_engine.dart';

/// AR recognition service for camera-based number recognition
class ARRecognitionService {
  final TextRecognizer _textRecognizer;
  CameraController? _cameraController;

  ARRecognitionService() : _textRecognizer = TextRecognizer();

  /// Initialize camera
  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
    } catch (e) {
      // Handle error
    }
  }

  /// Get camera controller
  CameraController? get cameraController => _cameraController;

  /// Recognize text from camera frame
  Future<String?> recognizeFromFrame(CameraImage image) async {
    try {
      final inputImage = _cameraImageToInputImage(image);
      if (inputImage == null) return null;

      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      // Extract mathematical expressions from recognized text
      String? expression = _extractMathExpression(recognizedText.text);

      if (expression != null) {
        // Validate and calculate
        final result = CalculatorEngine.evaluate(expression);
        return result;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Convert CameraImage to InputImage
  InputImage? _cameraImageToInputImage(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final imageRotation = InputImageRotation.rotation0deg;

      final inputImageData = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: imageRotation,
        format: InputImageFormat.yuv420,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
    } catch (e) {
      return null;
    }
  }

  /// Extract mathematical expression from recognized text
  String? _extractMathExpression(String text) {
    // Simple heuristic to find mathematical expressions
    // Remove spaces and check for patterns
    final cleaned = text.replaceAll(' ', '');

    // Look for patterns like: number operator number
    final pattern = RegExp(r'\d+[+\-*/×÷]\d+');
    final match = pattern.firstMatch(cleaned);

    if (match != null) {
      return match.group(0);
    }

    return null;
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _textRecognizer.close();
    await _cameraController?.dispose();
  }
}
