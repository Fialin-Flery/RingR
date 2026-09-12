import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/contact_model.dart';
import '../../services/zego_call_service.dart';

class VideoCallPreviewPage
    extends StatefulWidget {
  final ContactModel contact;

  const VideoCallPreviewPage({
    super.key,
    required this.contact,
  });

  @override
  State<VideoCallPreviewPage>
  createState() =>
      _VideoCallPreviewPageState();
}

class _VideoCallPreviewPageState
    extends State<
        VideoCallPreviewPage> {
  CameraController? _controller;

  bool _loading = true;

  bool _startingCall = false;

  String? _error;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations(
      const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ],
    );

    _initializeCamera();
  }

  // ============================================================
  // CAMERA
  // ============================================================

  Future<void>
  _initializeCamera() async {
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

      for (final availableCamera
      in cameras) {
        if (availableCamera
            .lensDirection ==
            CameraLensDirection
                .front) {
          camera =
              availableCamera;
          break;
        }
      }

      final controller =
      CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: true,
      );

      await controller.initialize();

      // Keep preview/capture in portrait.
      try {
        await controller
            .lockCaptureOrientation(
          DeviceOrientation.portraitUp,
        );
      } catch (e) {
        debugPrint(
          'Could not lock camera orientation: $e',
        );
      }

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller =
            controller;
        _loading = false;
      });
    } catch (e) {
      debugPrint(
        'Camera preview error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error =
        'Unable to open the camera.';
      });
    }
  }

  // ============================================================
  // START VIDEO CALL
  // ============================================================

  Future<void>
  _startVideoCall() async {
    if (_startingCall) {
      return;
    }

    final targetUid =
        widget.contact.uid;

    if (targetUid == null ||
        targetUid.isEmpty) {
      _showError(
        'This contact cannot be called.',
      );
      return;
    }

    setState(() {
      _startingCall = true;
    });

    try {
      // --------------------------------------------------------
      // Release Flutter's preview camera.
      // --------------------------------------------------------

      final controller =
          _controller;

      _controller = null;

      if (controller != null) {
        await controller.dispose();
      }

      // --------------------------------------------------------
      // Close preview first.
      // --------------------------------------------------------

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      // --------------------------------------------------------
      // Give Android time to release camera resources.
      // --------------------------------------------------------

      await Future.delayed(
        const Duration(
          milliseconds: 400,
        ),
      );

      // --------------------------------------------------------
      // Zego now takes control of the camera.
      // --------------------------------------------------------

      await ZegoCallService.instance
          .startVideoCall(
        uid: targetUid,
        name: widget.contact.name,
      );
    } catch (e) {
      debugPrint(
        'Start video call error: $e',
      );
    }
  }

  // ============================================================
  // SWITCH CAMERA
  // ============================================================

  Future<void>
  _switchCamera() async {
    final controller =
        _controller;

    if (controller == null ||
        !controller
            .value
            .isInitialized) {
      return;
    }

    final cameras =
    await availableCameras();

    if (cameras.length < 2) {
      return;
    }

    final currentDirection =
        controller
            .description
            .lensDirection;

    final newCamera =
    cameras.firstWhere(
          (camera) =>
      camera.lensDirection !=
          currentDirection,
      orElse: () =>
      cameras.first,
    );

    await controller.dispose();

    final newController =
    CameraController(
      newCamera,
      ResolutionPreset.high,
      enableAudio: true,
    );

    await newController.initialize();

    try {
      await newController
          .lockCaptureOrientation(
        DeviceOrientation.portraitUp,
      );
    } catch (_) {}

    if (!mounted) {
      await newController.dispose();
      return;
    }

    setState(() {
      _controller =
          newController;
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _controller?.dispose();

    // Return normal orientation behavior
    // when leaving the preview.
    SystemChrome.setPreferredOrientations(
      const [],
    );

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final controller =
        _controller;

    return Scaffold(
      backgroundColor:
      Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ==================================================
            // PORTRAIT CAMERA PREVIEW
            // ==================================================

            if (_loading)
              const Center(
                child:
                CircularProgressIndicator(
                  color: Colors.white,
                ),
              )
            else if (_error != null)
              _buildError()
            else if (controller !=
                  null &&
                  controller.value
                      .isInitialized)
                Center(
                  child:
                  AspectRatio(
                    aspectRatio:
                    9 / 16,
                    child:
                    ClipRRect(
                      borderRadius:
                      BorderRadius.circular(
                        24,
                      ),
                      child:
                      _buildPortraitPreview(
                        controller,
                      ),
                    ),
                  ),
                ),

            // ==================================================
            // TOP BAR
            // ==================================================

            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  _roundButton(
                    icon:
                    Icons.close_rounded,
                    onPressed:
                    _startingCall
                        ? null
                        : () =>
                        Navigator.of(
                          context,
                        ).pop(),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Container(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration:
                      BoxDecoration(
                        color: Colors.black
                            .withOpacity(
                          0.45,
                        ),
                        borderRadius:
                        BorderRadius
                            .circular(
                          18,
                        ),
                      ),
                      child: Text(
                        widget.contact.name,
                        maxLines: 1,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style:
                        const TextStyle(
                          color:
                          Colors.white,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  _roundButton(
                    icon: Icons
                        .flip_camera_ios_rounded,
                    onPressed:
                    _loading ||
                        _startingCall
                        ? null
                        : _switchCamera,
                  ),
                ],
              ),
            ),

            // ==================================================
            // BOTTOM CONTROLS
            // ==================================================

            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                children: [
                  Container(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration:
                    BoxDecoration(
                      color: Colors.black
                          .withOpacity(
                        0.45,
                      ),
                      borderRadius:
                      BorderRadius
                          .circular(
                        18,
                      ),
                    ),
                    child:
                    const Text(
                      'Check your camera before starting the video call.',
                      textAlign:
                      TextAlign.center,
                      style:
                      TextStyle(
                        color:
                        Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  SizedBox(
                    width:
                    double.infinity,
                    height: 56,
                    child:
                    ElevatedButton.icon(
                      onPressed:
                      _loading ||
                          _error !=
                              null ||
                          _startingCall
                          ? null
                          : _startVideoCall,
                      icon:
                      _startingCall
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
                      label:
                      Text(
                        _startingCall
                            ? 'Starting video call...'
                            : 'Start video call',
                      ),
                      style:
                      ElevatedButton
                          .styleFrom(
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            18,
                          ),
                        ),
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

  // ============================================================
  // PORTRAIT PREVIEW
  // ============================================================

  Widget _buildPortraitPreview(
      CameraController controller,
      ) {
    final previewSize =
        controller
            .value
            .previewSize;

    if (previewSize == null) {
      return CameraPreview(
        controller,
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width:
        previewSize.height,
        height:
        previewSize.width,
        child:
        CameraPreview(
          controller,
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(
          30,
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            const Icon(
              Icons
                  .camera_alt_outlined,
              color: Colors.white,
              size: 48,
            ),

            const SizedBox(
              height: 16,
            ),

            Text(
              _error ??
                  'Camera unavailable.',
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                color:
                Colors.white,
                fontSize: 16,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            ElevatedButton(
              onPressed:
              _initializeCamera,
              child:
              const Text(
                'Try again',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUTTON
  // ============================================================

  Widget _roundButton({
    required IconData icon,
    required VoidCallback?
    onPressed,
  }) {
    return Material(
      color:
      Colors.black.withOpacity(
        0.45,
      ),
      shape:
      const CircleBorder(),
      child: IconButton(
        onPressed:
        onPressed,
        icon: Icon(
          icon,
          color:
          Colors.white,
        ),
      ),
    );
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showError(
      String message,
      ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
        Text(message),
      ),
    );
  }
}