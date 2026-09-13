import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../services/zego_call_service.dart';

class GroupVideoPreviewPage
    extends StatefulWidget {
  final List<ContactCallTarget>
  participants;

  const GroupVideoPreviewPage({
    super.key,
    required this.participants,
  });

  @override
  State<GroupVideoPreviewPage> createState() =>
      _GroupVideoPreviewPageState();
}

class _GroupVideoPreviewPageState
    extends State<GroupVideoPreviewPage> {
  CameraController? _cameraController;

  bool _loading = true;
  bool _starting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras =
      await availableCameras();

      if (cameras.isEmpty) {
        throw Exception(
          'No camera found.',
        );
      }

      CameraDescription camera =
          cameras.first;

      for (final item in cameras) {
        if (item.lensDirection ==
            CameraLensDirection.front) {
          camera = item;
          break;
        }
      }

      final controller =
      CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController =
            controller;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error =
        'Camera preview could not be started.';
        _loading = false;
      });
    }
  }

  Future<void> _startCall() async {
    if (_starting) return;

    setState(() {
      _starting = true;
    });

    final success =
    await ZegoCallService.instance
        .startGroupVideoCall(
      participants:
      widget.participants,
    );

    if (!mounted) return;

    if (!success) {
      setState(() {
        _starting = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Group video call could not be started.',
          ),
        ),
      );

      return;
    }

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Video call preview',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _loading
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                )
                    : _error != null
                    ? Padding(
                  padding:
                  const EdgeInsets.all(
                    24,
                  ),
                  child: Text(
                    _error!,
                    textAlign:
                    TextAlign.center,
                    style:
                    const TextStyle(
                      color:
                      Colors.white,
                    ),
                  ),
                )
                    : ClipRRect(
                  borderRadius:
                  BorderRadius
                      .circular(
                    20,
                  ),
                  child:
                  CameraPreview(
                    _cameraController!,
                  ),
                ),
              ),
            ),

            Padding(
              padding:
              const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '${widget.participants.length} people selected',
                    style:
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  SizedBox(
                    width:
                    double.infinity,
                    height: 54,
                    child:
                    FilledButton.icon(
                      onPressed:
                      _loading ||
                          _error !=
                              null ||
                          _starting
                          ? null
                          : _startCall,
                      icon:
                      _starting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                        CircularProgressIndicator(
                          strokeWidth:
                          2,
                          color:
                          Colors.white,
                        ),
                      )
                          : const Icon(
                        Icons
                            .videocam_rounded,
                      ),
                      label: Text(
                        _starting
                            ? 'Starting...'
                            : 'Start video call',
                      ),
                    ),
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