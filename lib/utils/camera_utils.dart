import 'dart:io';

import 'package:camera/camera.dart';

class CameraUtils {
  /*
    get the camera controller ,with all its
    specified configuration.
   */

  Future<CameraController> getCameraController({
    ResolutionPreset resolutionPreset = ResolutionPreset.high,
    required CameraLensDirection specificLensDirection,
  }) async {
    //get all the cameras available in your device.
    final cameras = await availableCameras();

    //find the camera that has specified lensDirection or else return a default camera.
    final camera = cameras.firstWhere(
      (camera) => camera.lensDirection == specificLensDirection,
      orElse: () => cameras.first,
    );

    //create a cameraController and return the instance
    return CameraController(
      camera,
      resolutionPreset,
      imageFormatGroup:
          Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
    );
  }
}
