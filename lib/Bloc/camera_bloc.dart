import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:short_film_app/Bloc/camera_event.dart';
import 'package:short_film_app/Bloc/camera_state.dart';
import 'package:short_film_app/enum/camera_enums.dart';
import 'package:short_film_app/utils/camera_utils.dart';
import 'package:short_film_app/utils/permission_utils.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  final CameraUtils cameraUtils;

  final PermissionUtils permissionUtils;

  int recordingDurationLimit = 15;
  CameraController? _cameraController;
  CameraLensDirection currentLensDirection = CameraLensDirection.back;
  Timer? recordingTimer;
  ValueNotifier<int> recordingValNotifier = ValueNotifier(0);

  //getters
  CameraController? getController() => _cameraController;

  bool isInitialized() => _cameraController?.value.isInitialized ?? false;
  bool isRecording() => _cameraController?.value.isRecordingVideo ?? false;
  bool isCapturingPic() => _cameraController?.value.isTakingPicture ?? false;

  set setRecordingDurationLimit(int val) {
    recordingDurationLimit = val;
  }

  CameraBloc({
    required this.cameraUtils,
    required this.permissionUtils,
  }) : super(CameraInitial()) {
    //process the requests from UI to bloc.
    on<CameraInitialize>(_onCameraInitialize);
    on<CameraSwitch>(_onCameraSwitch);
    on<CameraRecordingStart>(_onCameraRecordingStart);
    on<CameraRecordingStop>(_onCameraRecordingStop);
    on<CameraReset>(_onCameraReset);
    on<CameraEnable>(_onCameraEnable);
    on<CameraDisable>(_onCameraDisable);
  }
  //---------------------Disable Camera-----------------------------
  void _onCameraDisable(CameraDisable event, Emitter<CameraState> emit) async {
    if (isInitialized() && isRecording()) {
      add(CameraRecordingStop());
      await Future.delayed(const Duration(seconds: 2));
    }

    await _disposeCamera();
    emit(CameraInitial());
  }

  //---------------------Enable Camera-----------------------------
  void _onCameraEnable(CameraEnable event, Emitter<CameraState> emit) async {
    if (!isInitialized() && _cameraController != null) {
      if (await permissionUtils.commandCameraAndMicrophonePermissionStatus()) {
        await _initializeCamera();
        emit(CameraReady(isRecordingVideo: false));
      } else {
        emit(CameraErr(error: CameraErrorType.permission));
      }
    }
  }

  //-------------------------------Resetting the camera--------------------------
  void _onCameraReset(CameraReset event, Emitter<CameraState> emit) async {
    await _disposeCamera();
    _resetCameraBloc();
    emit(CameraInitial());
  }

  void _resetCameraBloc() async {
    _cameraController = null;
    currentLensDirection = CameraLensDirection.front;
    _stopTimerAndResetDuration();
  }

//------------------onCameraRecordingStop--------------------------

  void _onCameraRecordingStop(
      CameraRecordingStop event, Emitter<CameraState> emit) async {
    if (isRecording()) {
      bool hasRecordingLimitError =
          recordingValNotifier.value < 2 ? true : false;

      emit(
        CameraReady(
            isRecordingVideo: false,
            hasRecordingErr: hasRecordingLimitError,
            deactivateRecordBtn: true),
      );

      File? videoFile;

      try {
        videoFile = await _stopRecording();
        //debounce

        if (hasRecordingLimitError) {
          await Future.delayed(const Duration(milliseconds: 1500), () {});
          emit(CameraReady(
              isRecordingVideo: false,
              hasRecordingErr: false,
              deactivateRecordBtn: false));
        } else {
          emit(
            CameraRecordingSuccess(
                file: videoFile, message: 'Successfully captured..'),
          );
        }
      } catch (e) {
        await _reInitialize();
        emit(CameraReady(isRecordingVideo: false));
      }
    }
  }

  Future<File> _stopRecording() async {
    try {
      XFile video = await _cameraController!.stopVideoRecording();
      _stopTimerAndResetDuration();
      return File(video.path);
    } catch (e) {
      return Future.error(e);
    }
  }

//---------------------onCameraRecordingStart--------------------....
  void _onCameraRecordingStart(
      CameraRecordingStart event, Emitter<CameraState> emit) async {
    //execute this only if not being recorded.
    if (!isRecording()) {
      try {
        emit(
          CameraReady(isRecordingVideo: true),
        );
        await _startRecording();
      } catch (e) {
        await _reInitialize();
        emit(CameraReady(isRecordingVideo: false));
      }
    }
  }

  Future<void> _reInitialize() async {
    await _disposeCamera(); //dispose the resources....
    await _initializeCamera();
  }

  Future<void> _disposeCamera() async {
    _cameraController?.removeListener(() {});
    _cameraController?.dispose();
    _stopTimerAndResetDuration();

    _cameraController = await cameraUtils.getCameraController(
        specificLensDirection: currentLensDirection);
  }

  void _stopTimerAndResetDuration() async {
    recordingTimer?.cancel();
    recordingValNotifier.value = 0;
  }

  Future<void> _startRecording() async {
    try {
      await _cameraController!.startVideoRecording();
    } catch (e) {
      return Future.error(e);
    }
  }

//-------------------onCameraSwitch - logic-------------
  void _onCameraSwitch(CameraSwitch event, Emitter<CameraState> emit) async {
    emit(
        CameraInitial()); //check whether u have permission to camera..and set config

    await _switchCameraService();
    emit(CameraReady(isRecordingVideo: false));
  }

  Future<void> _switchCameraService() async {
    currentLensDirection = ((currentLensDirection == CameraLensDirection.back)
        ? CameraLensDirection.front
        : CameraLensDirection.back);

    await _reInitialize();
  }

//-------------onCamera Initialize...--------------------
  void _onCameraInitialize(
      CameraInitialize event, Emitter<CameraState> emit) async {
    recordingDurationLimit = event.recordingLimit;

    try {
      await _checkPermissionAndInitializeCamera();
      emit(CameraReady(isRecordingVideo: false));
    } catch (e) {
      emit(
        CameraErr(
            error: e == CameraErrorType.permission
                ? CameraErrorType.permission
                : CameraErrorType.other),
      );
    }
  }

  Future<void> _checkPermissionAndInitializeCamera() async {
    if (await permissionUtils.commandCameraAndMicrophonePermissionStatus()) {
      await _initializeCamera();
    } else {
      if (await permissionUtils.askForPermission()) {
        await _initializeCamera();
      } else {
        return Future.error(CameraErrorType.permission);
      }
    }
  }

  Future<void> _initializeCamera() async {
    _cameraController = await cameraUtils.getCameraController(
      specificLensDirection: currentLensDirection,
    );

    try {
      await _cameraController?.initialize();
      _cameraController?.addListener(() {
        if (_cameraController!.value.isRecordingVideo) {
          _startTimer();
        }
      });
    } on CameraException catch (error) {
      Future.error(error);
    } catch (e) {
      Future.error(e);
    }
  }

  void _startTimer() async {
    recordingTimer = Timer.periodic(const Duration(seconds: 1), (timerInst) {
      recordingValNotifier.value++;
      if (recordingValNotifier.value == recordingDurationLimit) {
        //stop recording..
        //dispatch the cameraStop-event.
        add(CameraRecordingStop());
      }
    });
  }
}
