import 'package:dermascan/app/enums.dart';
import 'package:dermascan/features/auth/controller/login/login_controller.dart';
import 'package:dermascan/features/auth/screens/login/widgets/doctor_login_form.dart';
import 'package:dermascan/features/auth/screens/login/widgets/practice_login_from.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final LoginController loginController = Get.find<LoginController>();

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
                  ).colorScheme.primary.withValues(alpha: .1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.login_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome Back',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Login to access your dashboard',
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
                      loginController.currentSelectedAuthOption.value,
                    },
                    onSelectionChanged: (Set<AuthOption> newSelection) =>
                        loginController.changeCurrentSelectedAuthOption(
                          newAuthOption: newSelection.first,
                        ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: loginController.scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Obx(() {
                  if (loginController.currentSelectedAuthOption.value ==
                      AuthOption.doctor) {
                    return DoctorLoginForm();
                  } else {
                    return PracticeLoginForm();
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
                onPressed: loginController.isLoading.value
                    ? null
                    : loginController.navigateToRegister,
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
                      const TextSpan(text: 'No Account? '),
                      TextSpan(
                        text: 'Register',
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
