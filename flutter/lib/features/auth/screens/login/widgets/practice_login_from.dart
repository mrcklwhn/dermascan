import 'package:dermascan/features/auth/controller/login/practice_login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PracticeLoginForm extends StatelessWidget {
  PracticeLoginForm({super.key});

  final PracticeLoginController practiceLoginController =
      Get.find<PracticeLoginController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 16),
        TextField(
          autocorrect: false,
          controller: practiceLoginController.emailController,
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
            obscureText: practiceLoginController.passwordIsObscure.value,
            autocorrect: false,
            controller: practiceLoginController.passwordController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                onPressed: practiceLoginController.changePasswordObscurity,
                icon: Icon(
                  practiceLoginController.passwordIsObscure.value
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
              onPressed: practiceLoginController.loginController.isLoading.value
                  ? null
                  : practiceLoginController.submitLoginData,
              child: const Text('Login'),
            );
          }),
        ),
      ],
    );
  }
}
