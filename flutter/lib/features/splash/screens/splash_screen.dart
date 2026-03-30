import 'package:dermascan/features/splash/controller/splash_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatelessWidget {
  final SplashController splashController = Get.find<SplashController>();

  SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(child: CircularProgressIndicator.adaptive()),
      ),
    );
  }
}
