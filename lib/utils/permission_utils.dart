import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  //check whether you got all camera and audio permission.
  Future<bool> commandCameraAndMicrophonePermissionStatus() async {
    //get the status of permission
    PermissionStatus cameraStatus = await Permission.camera.status;
    PermissionStatus microphoneStatus = await Permission.microphone.status;

    if (cameraStatus.isGranted && microphoneStatus.isGranted) {
      return true;
    }

    return false;
  }

  //ask for permission
  Future<bool> askForPermission() async {
    Map<Permission, PermissionStatus> status = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (status[Permission.camera]!.isGranted &&
        status[Permission.microphone]!.isGranted) {
      return true;
    }

    return false;
  }
}
