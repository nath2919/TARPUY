import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rimana Ayni',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F8A8B)),
        useMaterial3: true,
      ),
      home: const SignDetectionPage(),
    );
  }
}

class SignDetectionPage extends StatefulWidget {
  const SignDetectionPage({super.key});

  @override
  State<SignDetectionPage> createState() => _SignDetectionPageState();
}

class _SignDetectionPageState extends State<SignDetectionPage> {
  CameraController? _cameraController;
  final FlutterTts _tts = FlutterTts();
  bool _cameraReady = false;
  bool _isDetecting = false;
  String _currentLabel = 'Sin seña';
  String _lastSpoken = '';

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('es-ES');
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _currentLabel = 'Permiso de cámara requerido');
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() => _currentLabel = 'No hay cámara disponible');
      return;
    }

    final camera = cameras.first;
    _cameraController = CameraController(camera, ResolutionPreset.medium, enableAudio: false);
    await _cameraController!.initialize();

    if (!mounted) return;

    setState(() => _cameraReady = true);
    _cameraController!.startImageStream(_handleFrame);
  }

  Future<void> _handleFrame(CameraImage image) async {
    if (_isDetecting || !mounted) return;

    _isDetecting = true;
    final label = _guessSignFromImage(image);

    if (label != null && label != _lastSpoken) {
      _lastSpoken = label;
      setState(() => _currentLabel = label);
      await _tts.speak(label);
    } else if (label == null) {
      setState(() => _currentLabel = 'Sin seña');
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _isDetecting = false;
      }
    });
  }

  String? _guessSignFromImage(CameraImage image) {
    final yPlane = image.planes[0].bytes;
    if (yPlane.isEmpty) return null;

    int brightPixels = 0;
    int totalPixels = 0;

    for (int i = 0; i < yPlane.length; i += 4) {
      final value = yPlane[i];
      totalPixels++;
      if (value > 120 && value < 210) {
        brightPixels++;
      }
    }

    final ratio = totalPixels == 0 ? 0.0 : brightPixels / totalPixels;

    if (ratio > 0.16) {
      return 'Señal A';
    }
    if (ratio > 0.09) {
      return 'Señal B';
    }
    return null;
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Rimana Ayni'),
        backgroundColor: const Color(0xFF4F8A8B),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _cameraReady && _cameraController != null
                  ? ClipRRect(
                      child: CameraPreview(_cameraController!),
                    )
                  : const Center(
                      child: Text(
                        'Cámara esperando permisos o dispositivo',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF1F2D2E),
              child: Column(
                children: [
                  const Text(
                    'Señal detectada',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
