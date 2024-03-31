import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:short_film_app/Bloc/camera_bloc.dart';
import 'package:short_film_app/utils/camera_utils.dart';
import 'package:short_film_app/utils/permission_utils.dart';
import 'package:short_film_app/views/HomePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(elevation: 20),
      ),
      themeMode: ThemeMode.dark,
      home: const HomePage(),
    );
  }
}
