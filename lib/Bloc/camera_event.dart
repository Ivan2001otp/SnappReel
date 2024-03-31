import 'package:equatable/equatable.dart';

abstract class CameraEvent extends Equatable {
  const CameraEvent();

  @override
  List<Object> get props => [];
}

class CameraInitialize extends CameraEvent {
  //duration in seconds...
  final int recordingLimit;
  const CameraInitialize({
    required this.recordingLimit,
  });
}

class CameraSwitch extends CameraEvent {}

class CameraRecordingStart extends CameraEvent {}

class CameraRecordingStop extends CameraEvent {}

class CameraReset extends CameraEvent {}

class CameraEnable extends CameraEvent {}

class CameraDisable extends CameraEvent {}
