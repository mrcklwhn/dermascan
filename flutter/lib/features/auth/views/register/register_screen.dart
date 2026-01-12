import 'package:dermascan/app/enums.dart';
import 'package:dermascan/features/auth/controller/register/register_controller.dart';
import 'package:dermascan/features/auth/views/register/widgets/doctor_register_form.dart';
import 'package:dermascan/features/auth/views/register/widgets/practice_register_form.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});

  final RegisterController registerController = Get.find<RegisterController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 40),
            Text(
              'Register',
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
                      registerController.currentSelectedAuthOption.value,
                    },
                    onSelectionChanged: (Set<AuthOption> newSelection) =>
                        registerController.changeCurrentSelectedAuthOption(
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
                if (registerController.currentSelectedAuthOption.value ==
                    AuthOption.doctor) {
                  return DoctorRegisterForm();
                } else {
                  return PracticeRegisterForm();
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
            return SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: registerController.isLoading.value
                    ? null
                    : registerController.navigateBackToLogin,
                child: const Text('Already have an Account? Log in!'),
              ),
            );
          }),
        ),
      ),
    );
  }
}
