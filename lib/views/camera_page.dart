import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:short_film_app/Bloc/camera_event.dart';
import 'package:short_film_app/Bloc/camera_state.dart';
import 'package:short_film_app/enum/camera_enums.dart';
import 'package:short_film_app/views/video_player.dart';
import 'package:short_film_app/widgets/animated_bar.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../utils/screenshot_utils.dart';
import '../Bloc/camera_bloc.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  late CameraBloc cameraBloc;
  final GlobalKey screenshotKey = GlobalKey();
  Uint8List? screenshotBytes;
  bool isThisPageVisible = true;

  @override
  void initState() {
    // TODO: implement initState
    cameraBloc = BlocProvider.of<CameraBloc>(context);
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    cameraBloc.add(CameraReset());
    cameraBloc.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  //manage the events of app that are fired in the life cycle.

  void didChangeAppLifeCycleState(AppLifecycleState state) {
    if (cameraBloc.getController() == null) return;

    if (state == AppLifecycleState.inactive) {
      cameraBloc.add(CameraDisable());
    }

    if (state == AppLifecycleState.resumed) {
      if (!isThisPageVisible) {
        cameraBloc.add(CameraEnable());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 54, 53, 53),
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: VisibilityDetector(
        key: const Key('my_camera'),
        onVisibilityChanged: _handleVisibilityChanged,
        child: BlocConsumer<CameraBloc, CameraState>(
          builder: _cameraBlocBuilder,
          listener: _cameraBlocListener,
        ),
      ),
    );
  }

//bloc builder...
  Widget _cameraBlocBuilder(BuildContext context, CameraState state) {
    bool disableButtons = !(state is CameraReady && !state.isRecordingVideo);
    // if (state is CameraInitial) {
    //   return const Center(
    //     child: CircularProgressIndicator(
    //       color: Colors.red,
    //     ),
    //   );
    // }
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              RepaintBoundary(
                key: screenshotKey,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.linear,
                  // switchOutCurve: Curves.easeOut,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      alwaysIncludeSemantics: true,
                      child: child,
                    );
                  },
                  child: state is CameraReady
                      ? Builder(builder: (context) {
                          var controller = cameraBloc.getController();
                          return Transform.scale(
                            // scale:1/ controller!.value.aspectRatio * 1,
                            // MediaQuery.of(context).size.aspectRatio,
                            scale: controller!.value.aspectRatio * 1,
                            child: CameraPreview(controller),
                          );
                        })
                      : state is CameraInitial && screenshotBytes != null
                          ? Container(
                              constraints: const BoxConstraints.expand(),
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: MemoryImage(screenshotBytes!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                    sigmaX: 15.0, sigmaY: 15.0),
                                child: Container(
                                  child: Center(
                                    child: IconButton(
                                        onPressed: () {
                                          // Navigator.pushReplacement(
                                          //   context,
                                          //   MaterialPageRoute(
                                          //     builder: (context) =>
                                          //         const CameraPage(),
                                          //   ),
                                          // );
                                          Navigator.pop(context);
                                        },
                                        icon: const Icon(
                                          Icons.restart_alt,
                                          color: Colors.white,
                                          size: 40,
                                          weight: 10,
                                        )),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                ),
              ),
              if (state is CameraErr) errorWidget(state),
              Positioned(
                bottom: 30,
                child: SizedBox(
                  width: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      IgnorePointer(
                        ignoring:
                            state is! CameraReady || state.deactivateRecordBtn,
                        child: Opacity(
                          opacity:
                              state is! CameraReady || state.deactivateRecordBtn
                                  ? 0.4
                                  : 1,
                          child: animatedProgressButton(state),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                  right: 40,
                  bottom: 40,
                  child: Visibility(
                    visible: !disableButtons,
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.5),
                      radius: 30,
                      child: IconButton(
                        onPressed: () async {
                          try {
                            screenshotBytes = await captureScreenShotService(
                                key: screenshotKey);
                            if (context.mounted) cameraBloc.add(CameraSwitch());
                          } catch (e, stackTrace) {
                            print(
                              "screenshot stacktrace --> ${stackTrace.toString()}",
                            );

                            print(
                              "screenshot error --> ${e.toString()}",
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.cameraswitch,
                          color: Colors.black,
                          size: 28,
                        ),
                      ),
                    ),
                  )),
              Positioned(
                left: 40,
                bottom: 40,
                child: Visibility(
                  visible: !disableButtons,
                  child: StatefulBuilder(builder: (context, localSetState) {
                    return InkWell(
                      onTap: () {
                        final List<int> timer = [5, 10, 15, 30];
                        int currentIndx =
                            timer.indexOf(cameraBloc.recordingDurationLimit);
                        localSetState(() {
                          //kind of circular queue ,so that index does not go out of bound.
                          cameraBloc.setRecordingDurationLimit =
                              timer[(currentIndx + 1) % timer.length];
                        });
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.5),
                        radius: 30,
                        child: FittedBox(
                          child: Text(
                            "${cameraBloc.recordingDurationLimit}",
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  void startRecording() async {
    try {
      await captureScreenShotService(key: screenshotKey)
          .then((value) => screenshotBytes = value);
    } catch (e) {
      rethrow;
    }

    cameraBloc.add(CameraRecordingStart());
  }

  void stopRecording() async {
    cameraBloc.add(CameraRecordingStop());
  }

  Widget animatedProgressButton(CameraState state) {
    bool isRecording = state is CameraReady && state.isRecordingVideo;
    return GestureDetector(
      onTap: () async {
        if (isRecording) {
          stopRecording();
        } else {
          startRecording();
        }
      },
      onLongPress: () {
        startRecording();
      },
      onLongPressEnd: (_) {
        stopRecording();
      },
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 200,
        ),
        width: isRecording ? 90 : 80,
        height: isRecording ? 90 : 80,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(
                milliseconds: 200,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF978B8B).withOpacity(0.8),
              ),
            ),
            ValueListenableBuilder(
                valueListenable: cameraBloc.recordingValNotifier,
                builder: (context, val, child) {
                  return TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: isRecording ? 1 : 0,
                        end: isRecording ? val.toDouble() + 1 : 0,
                      ),
                      curve: Curves.easeIn,
                      duration: Duration(milliseconds: isRecording ? 1100 : 0),
                      builder: (context, value, _) {
                        return Center(
                          child: AnimatedContainer(
                            duration: const Duration(
                              milliseconds: 200,
                            ),
                            height: isRecording ? 90 : 80,
                            width: isRecording ? 90 : 80,
                            child: RecordingProgressIndicator(
                              value: value,
                              maxValue:
                                  cameraBloc.recordingDurationLimit.toDouble(),
                            ),
                          ),
                        );
                      });
                }),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.linear,
                    height: isRecording ? 25 : 64,
                    width: isRecording ? 25 : 64,
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 255, 255, 255),
                      borderRadius: isRecording
                          ? BorderRadius.circular(6)
                          : BorderRadius.circular(100),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

//error widget when CameraErr state is invoked
  Widget errorWidget(CameraState state) {
    bool isPermissionError =
        state is CameraErr && state.error == CameraErrorType.permission;

    return Container(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isPermissionError
                  ? "Please Grant access to your camera and microphone to proceed"
                  : "Something went wrong",
              style: const TextStyle(
                color: Color(0xFF959393),
                fontFamily: "Montserrat",
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(136, 76, 75, 75)
                            .withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: FittedBox(
                          child: Text(
                            "Open Setting",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontFamily: "Montserrat",
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    onPressed: () async {
                      openAppSettings(); //<--built in method
                      Navigator.maybePop(context);
                    },
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

//bloc listener...
  void _cameraBlocListener(BuildContext context, CameraState state) {
    if (state is CameraRecordingSuccess) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoPage(videoFile: state.file),
        ),
      );
    } else if (state is CameraReady && state.hasRecordingErr) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
          content: Text(
            'Please record at least 4 seconds',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    if (info.visibleFraction == 0.0) {
      //camera page is not visible ,disable the cam
      if (mounted) {
        cameraBloc.add(CameraDisable());
        isThisPageVisible = false;
      } else {
        isThisPageVisible = true;
        cameraBloc.add(CameraEnable());
      }
    }
  }
}
