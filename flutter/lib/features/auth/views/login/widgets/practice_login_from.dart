import 'package:dermascan/features/auth/controller/login/practice_login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PracticeLoginForm extends StatelessWidget {
  PracticeLoginForm({super.key});

  final PracticeLoginController practiceLoginController =
      Get.find<PracticeLoginController>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 20),
          TextField(
            autocorrect: false,
            controller: practiceLoginController.emailController,
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
              obscureText: practiceLoginController.passwordIsObscure.value,
              autocorrect: false,
              controller: practiceLoginController.passwordController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  onPressed: practiceLoginController.changePasswordObscurity,
                  icon: Icon(
                    practiceLoginController.passwordIsObscure.value
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
                onPressed:
                    practiceLoginController.loginController.isLoading.value
                    ? null
                    : practiceLoginController.submitLoginData,
                child: const Text('Login'),
              );
            }),
          ),
        ],
      ),
    );
  }
}
