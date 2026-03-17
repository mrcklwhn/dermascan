import 'package:dermascan/app/enums.dart';
import 'package:dermascan/features/auth/controller/register/register_controller.dart';
import 'package:dermascan/features/auth/screens/register/widgets/doctor_register_form.dart';
import 'package:dermascan/features/auth/screens/register/widgets/practice_register_form.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});

  final RegisterController registerController = Get.find<RegisterController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 24),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_add_alt_1_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Join Dermascan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select your role to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<AuthOption>(
                    showSelectedIcon: false,
                    style: ButtonStyle(
                      visualDensity: VisualDensity.comfortable,
                      side: WidgetStateProperty.all(
                        BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    segments: const <ButtonSegment<AuthOption>>[
                      ButtonSegment<AuthOption>(
                        value: AuthOption.doctor,
                        label: Text('Doctor'),
                        icon: Icon(Icons.medical_services_outlined),
                      ),
                      ButtonSegment<AuthOption>(
                        value: AuthOption.practice,
                        label: Text('Practice'),
                        icon: Icon(Icons.business_outlined),
                      ),
                    ],
                    selected: <AuthOption>{
                      registerController.currentSelectedAuthOption.value,
                    },
                    onSelectionChanged: (Set<AuthOption> newSelection) =>
                        registerController.changeCurrentSelectedAuthOption(
                          newAuthOption: newSelection.first,
                        ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: registerController.scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Obx(() {
                  if (registerController.currentSelectedAuthOption.value ==
                      AuthOption.doctor) {
                    return DoctorRegisterForm();
                  } else {
                    return PracticeRegisterForm();
                  }
                }),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
            top: 8,
          ),
          child: Obx(() {
            return SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: registerController.isLoading.value
                    ? null
                    : registerController.navigateBackToLogin,
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant,
                ),
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    children: <InlineSpan>[
                      const TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Log in',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
