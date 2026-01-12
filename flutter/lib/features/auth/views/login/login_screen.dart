import 'package:dermascan/app/enums.dart';
import 'package:dermascan/features/auth/controller/login/login_controller.dart';
import 'package:dermascan/features/auth/views/login/widgets/doctor_login_form.dart';
import 'package:dermascan/features/auth/views/login/widgets/practice_login_from.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final LoginController loginController = Get.find<LoginController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 40),
            Text(
              'Login',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<AuthOption>(
                    showSelectedIcon: false,
                    segments: const <ButtonSegment<AuthOption>>[
                      ButtonSegment<AuthOption>(
                        value: AuthOption.doctor,
                        label: Text('Doctor'),
                      ),
                      ButtonSegment<AuthOption>(
                        value: AuthOption.practice,
                        label: Text('Practice'),
                      ),
                    ],
                    selected: <AuthOption>{
                      loginController.currentSelectedAuthOption.value,
                    },
                    onSelectionChanged: (Set<AuthOption> newSelection) =>
                        loginController.changeCurrentSelectedAuthOption(
                          newAuthOption: newSelection.first,
                        ),
                    style: ButtonStyle(
                      textStyle: WidgetStateProperty.all(
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                if (loginController.currentSelectedAuthOption.value ==
                    AuthOption.doctor) {
                  return DoctorLoginForm();
                } else {
                  return PracticeLoginForm();
                }
              }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Obx(() {
            return TextButton(
              onPressed: loginController.isLoading.value
                  ? null
                  : loginController.navigateToRegister,
              child: const Text('No Account? Register!'),
            );
          }),
        ),
      ),
    );
  }
}
