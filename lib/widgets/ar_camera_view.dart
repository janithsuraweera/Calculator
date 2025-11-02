import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/ar_recognition_service.dart';

/// AR Camera view for number recognition
class ARCameraView extends StatefulWidget {
  final Function(String) onExpressionRecognized;

  const ARCameraView({super.key, required this.onExpressionRecognized});

  @override
  State<ARCameraView> createState() => _ARCameraViewState();
}

class _ARCameraViewState extends State<ARCameraView> {
  ARRecognitionService? _arService;
  bool _isInitialized = false;
  String? _recognizedText;
  bool _isRecognizing = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    _arService = ARRecognitionService();
    await _arService!.initializeCamera();
    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _captureAndRecognize() async {
    if (_arService?.cameraController == null || _isRecognizing) return;

    setState(() {
      _isRecognizing = true;
    });

    try {
      final image = await _arService!.cameraController!.takePicture();
      // Process image for recognition
      // Note: This is simplified - actual implementation would process the image
      // and use ML Kit for text recognition

      setState(() {
        _recognizedText = 'Recognition in progress...';
        _isRecognizing = false;
      });
    } catch (e) {
      setState(() {
        _recognizedText = 'Error: $e';
        _isRecognizing = false;
      });
    }
  }

  @override
  void dispose() {
    _arService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('AR Calculator')),
      body: Stack(
        children: [
          // Camera preview
          if (_arService?.cameraController != null)
            CameraPreview(_arService!.cameraController!),

          // Recognition overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.7)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_recognizedText != null)
                    Text(
                      _recognizedText!,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isRecognizing ? null : _captureAndRecognize,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Capture & Recognize'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
