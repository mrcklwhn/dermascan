import 'package:dermascan/features/auth/controller/login/doctor_login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorLoginForm extends StatelessWidget {
  DoctorLoginForm({super.key});

  final DoctorLoginController doctorLoginController =
      Get.find<DoctorLoginController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 16),
        TextField(
          autocorrect: false,
          controller: doctorLoginController.emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'E-Mail',
            prefixIcon: Icon(Icons.email_outlined),
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
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                onPressed: doctorLoginController.changePasswordObscurity,
                icon: Icon(
                  doctorLoginController.passwordIsObscure.value
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: Obx(() {
            return FilledButton(
              onPressed: doctorLoginController.loginController.isLoading.value
                  ? null
                  : doctorLoginController.submitLoginData,
              child: const Text('Login'),
            );
          }),
        ),
      ],
    );
  }
}
