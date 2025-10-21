import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/camera/camera_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String camera = '/camera';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case camera:
        return MaterialPageRoute(builder: (_) => const CameraScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Ruta no encontrada: ${settings.name}')),
          ),
        );
    }
  }
}