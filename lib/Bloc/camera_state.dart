import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:short_film_app/enum/camera_enums.dart';

abstract class CameraState extends Equatable {
  @override
  List<Object> get props => [];
}

class CameraInitial extends CameraState {}

class CameraReady extends CameraState {
  final bool isRecordingVideo;
  final bool hasRecordingErr;
  final bool deactivateRecordBtn;

  CameraReady({
    required this.isRecordingVideo,
    this.hasRecordingErr = false,
    this.deactivateRecordBtn = false,
  });

  @override
  String toString() {
    return "isRecordingVideo :$isRecordingVideo , hasRecordingError : $hasRecordingErr ,decativateRecordButton: $deactivateRecordBtn";
  }

  @override
  List<Object> get props =>
      [isRecordingVideo, hasRecordingErr, deactivateRecordBtn];
}

class CameraRecordingSuccess extends CameraState {
  final File file;
  final String message;
  CameraRecordingSuccess({
    required this.file,
    required this.message,
  });

  @override
  List<Object> get props => [file];
}

class CameraErr extends CameraState {
  final CameraErrorType error;
  CameraErr({
    required this.error,
  });

  @override
  List<Object> get props => [error];
}
