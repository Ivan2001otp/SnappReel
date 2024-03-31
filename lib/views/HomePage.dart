import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:short_film_app/Bloc/camera_bloc.dart';
import 'package:short_film_app/Bloc/camera_event.dart';
import 'package:short_film_app/Bloc/camera_state.dart';
import 'package:short_film_app/enum/camera_enums.dart';
import 'package:short_film_app/utils/camera_utils.dart';
import 'package:short_film_app/utils/permission_utils.dart';
import 'package:short_film_app/views/camera_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BlocProvider(
                    child: const CameraPage(),
                    create: (context) {
                      return CameraBloc(
                        cameraUtils: CameraUtils(),
                        permissionUtils: PermissionUtils(),
                      )..add(const CameraInitialize(recordingLimit: 15));
                    }),
              ),
            );
          },
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              "Camera 📷",
              style: TextStyle(fontSize: 25),
            ),
          ),
        ),
      ),
    );
  }
}
