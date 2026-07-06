import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WhatsAppCapture {
  const WhatsAppCapture({required this.path, required this.mediaKind});

  final String path;
  final String mediaKind;
}

class WhatsAppCameraScreen extends StatefulWidget {
  const WhatsAppCameraScreen({Key? key}) : super(key: key);

  @override
  State<WhatsAppCameraScreen> createState() => _WhatsAppCameraScreenState();
}

class _WhatsAppCameraScreenState extends State<WhatsAppCameraScreen> {
  List<CameraDescription> _cameras = const [];
  CameraController? _camera;
  bool _loading = true;
  bool _videoMode = false;
  bool _recording = false;
  int _cameraIndex = 0;
  FlashMode _flash = FlashMode.off;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadCameras();
  }

  Future<void> _loadCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw StateError('لا توجد كاميرا متاحة');
      final back = _cameras.indexWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back);
      _cameraIndex = back < 0 ? 0 : back;
      await _initialize(_cameraIndex);
    } catch (e) {
      _error = e;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _initialize(int index) async {
    final old = _camera;
    _camera = null;
    await old?.dispose();
    final camera = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: true,
    );
    await camera.initialize();
    await camera.setFlashMode(_flash);
    _camera = camera;
    if (mounted) setState(() {});
  }

  Future<void> _capture() async {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) return;
    try {
      if (!_videoMode) {
        final file = await camera.takePicture();
        Get.back(result: WhatsAppCapture(path: file.path, mediaKind: 'image'));
        return;
      }
      if (_recording) {
        final file = await camera.stopVideoRecording();
        _recording = false;
        Get.back(result: WhatsAppCapture(path: file.path, mediaKind: 'video'));
      } else {
        await camera.startVideoRecording();
        setState(() => _recording = true);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر استخدام الكاميرا: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_recording || _cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    setState(() => _loading = true);
    try {
      await _initialize(_cameraIndex);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFlash() async {
    final camera = _camera;
    if (camera == null || _recording) return;
    _flash = _flash == FlashMode.off ? FlashMode.auto : FlashMode.off;
    await camera.setFlashMode(_flash);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _preview(),
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton.filled(
                      onPressed: Get.back,
                      style:
                          IconButton.styleFrom(backgroundColor: Colors.black45),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    IconButton.filled(
                      onPressed: _toggleFlash,
                      style:
                          IconButton.styleFrom(backgroundColor: Colors.black45),
                      icon: Icon(
                        _flash == FlashMode.off
                            ? Icons.flash_off
                            : Icons.flash_auto,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Column(
                  children: [
                    if (!_recording)
                      SegmentedButton<bool>(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.selected)
                                  ? const Color(0xFF00A884)
                                  : Colors.black54),
                          foregroundColor:
                              const WidgetStatePropertyAll(Colors.white),
                        ),
                        segments: const [
                          ButtonSegment(value: false, label: Text('صورة')),
                          ButtonSegment(value: true, label: Text('فيديو')),
                        ],
                        selected: {_videoMode},
                        onSelectionChanged: (value) =>
                            setState(() => _videoMode = value.first),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(width: 48),
                        GestureDetector(
                          onTap: _capture,
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _recording ? Colors.red : Colors.white,
                              border: Border.all(color: Colors.white, width: 5),
                            ),
                            child: _recording
                                ? const Icon(Icons.stop,
                                    color: Colors.white, size: 34)
                                : _videoMode
                                    ? const Icon(Icons.videocam,
                                        color: Colors.red, size: 34)
                                    : null,
                          ),
                        ),
                        IconButton(
                          onPressed: _switchCamera,
                          icon: const Icon(Icons.cameraswitch,
                              color: Colors.white, size: 30),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _preview() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('تعذر فتح الكاميرا\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white)),
        ),
      );
    }
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return Center(
      child: CameraPreview(camera),
    );
  }
}
