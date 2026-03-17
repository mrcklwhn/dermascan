import 'package:dermascan/app/enums.dart';
import 'package:dermascan/features/auth/controller/register/doctor_register_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorRegisterForm extends StatelessWidget {
  DoctorRegisterForm({super.key});

  final DoctorRegisterController doctorRegisterController =
      Get.find<DoctorRegisterController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 16),
        TextField(
          controller: doctorRegisterController.nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: doctorRegisterController.birthdayController,
                readOnly: true,
                onTap: () => doctorRegisterController.selectDate(context),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Date of Birth',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Obx(
                () => DropdownButtonFormField<Gender>(
                  initialValue: doctorRegisterController.selectedGender.value,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.wc_outlined),
                  ),
                  items: Gender.values.map((Gender g) {
                    return DropdownMenuItem<Gender>(
                      value: g,
                      child: Text(
                        g.name[0].toUpperCase() + g.name.substring(1),
                      ),
                    );
                  }).toList(),
                  onChanged: (Gender? newValue) {
                    doctorRegisterController.selectedGender.value = newValue;
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: doctorRegisterController.emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'E-Mail',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 16),
        Obx(
          () => TextField(
            obscureText: doctorRegisterController.passwordIsObscure.value,
            controller: doctorRegisterController.passwordController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: doctorRegisterController.changePasswordObscurity,
                icon: Icon(
                  doctorRegisterController.passwordIsObscure.value
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: <Widget>[
            _buildPasswordCriteriaRow(
              text: 'At least 8 characters',
              isValid: doctorRegisterController.hasMinLength,
            ),
            _buildPasswordCriteriaRow(
              text: 'Uppercase letter',
              isValid: doctorRegisterController.hasUppercase,
            ),
            _buildPasswordCriteriaRow(
              text: 'Lowercase letter',
              isValid: doctorRegisterController.hasLowercase,
            ),
            _buildPasswordCriteriaRow(
              text: 'Number',
              isValid: doctorRegisterController.hasDigits,
            ),
            _buildPasswordCriteriaRow(
              text: 'Special character',
              isValid: doctorRegisterController.hasSpecialCharacters,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(
          () => TextField(
            obscureText: doctorRegisterController.passwordIsObscure.value,
            controller: doctorRegisterController.confirmPasswordController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Confirm Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildPasswordCriteriaRow(
          text: 'Passwords match',
          isValid: doctorRegisterController.passwordsMatch,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: Obx(() {
            return FilledButton(
              onPressed:
                  doctorRegisterController.registerController.isLoading.value
                  ? null
                  : doctorRegisterController.submitRegisterData,
              child: const Text('Register Doctor'),
            );
          }),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildPasswordCriteriaRow({
    required String text,
    required Rx<bool> isValid,
  }) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Row(
          children: <Widget>[
            Icon(
              isValid.value
                  ? Icons.check_circle_outline
                  : Icons.cancel_outlined,
              color: isValid.value ? Colors.green : Colors.grey,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: isValid.value ? Colors.green : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
