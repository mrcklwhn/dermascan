import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/core/widgets/custom_text_field.dart';
import 'package:dermascan/features/auth/controller/login/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppTheme.scaffoldPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const CustomIcon(iconData: Icons.login),
              const SizedBox(height: AppTheme.spaceLarge),
              Text(
                'Welcome Back!'.tr,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spaceLarge),
              CustomTextField(
                textEditingController: controller.emailController,
                focusNode: controller.emailFocusNode,
                onSubmitted: (_) => controller.submittedEmail(),
                labelText: 'E-Mail'.tr,
                prefixIcon: Icons.email,
                textInputType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              CustomTextField(
                textEditingController: controller.passwordController,
                focusNode: controller.passwordFocusNode,
                onSubmitted: (_) => controller.submitLoginData(),
                labelText: 'Password'.tr,
                prefixIcon: Icons.password,
                textInputType: TextInputType.visiblePassword,
              ),
              const SizedBox(height: AppTheme.spaceLarge),
              FilledButton.icon(
                icon: const Icon(Icons.login),
                onPressed: controller.submitLoginData,
                label: Text('Login'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
