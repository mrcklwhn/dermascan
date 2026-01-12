import 'package:dermascan/features/auth/controller/login/doctor_login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorLoginForm extends StatelessWidget {
  DoctorLoginForm({super.key});

  final DoctorLoginController doctorLoginController =
      Get.find<DoctorLoginController>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 20),
          TextField(
            autocorrect: false,
            controller: doctorLoginController.emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'E-Mail',
              prefixIcon: Icon(Icons.email),
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => TextField(
              obscureText: doctorLoginController.passwordIsObscure.value,
              autocorrect: false,
              controller: doctorLoginController.passwordController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  onPressed: doctorLoginController.changePasswordObscurity,
                  icon: Icon(
                    doctorLoginController.passwordIsObscure.value
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: Obx(() {
              return ElevatedButton(
                onPressed: doctorLoginController.loginController.isLoading.value
                    ? null
                    : doctorLoginController.submitLoginData,
                child: const Text('Login'),
              );
            }),
          ),
        ],
      ),
    );
  }
}
