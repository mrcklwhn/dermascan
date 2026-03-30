import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/app/enums.dart';
import 'package:dermascan/core/models/check_criteria.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/core/widgets/custom_text_field.dart';
import 'package:dermascan/features/doctor/patients/controller/add_patient_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddPatientScreen extends GetView<AddPatientController> {
  const AddPatientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Patient')),
      body: SafeArea(
        child: ListView(
          controller: controller.scrollController,
          scrollDirection: Axis.vertical,
          padding: AppTheme.scaffoldPadding,
          children: <Widget>[
            const CustomIcon(iconData: Icons.person_add),
            const SizedBox(height: AppTheme.spaceLarge),
            CustomTextField(
              textEditingController: controller.nameController,
              focusNode: controller.nameFocusNode,
              onSubmitted: (_) => controller.submittedName(),
              labelText: 'Full Name',
              prefixIcon: Icons.person,
              textInputType: TextInputType.name,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: controller.birthdayController,
                    readOnly: true,
                    onTap: () => controller.selectDate(context),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Date of Birth',
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                Expanded(
                  child: DropdownButtonFormField<Gender>(
                    initialValue: controller.selectedGender,
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
                      controller.selectedGender = newValue;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            CustomTextField(
              textEditingController: controller.emailController,
              focusNode: controller.emailFocusNode,
              onSubmitted: controller.isLoading.value
                  ? (_) {}
                  : (_) => controller.submitPatientData(),
              labelText: 'E-Mail',
              prefixIcon: Icons.email,
              textInputType: TextInputType.emailAddress,
              checkCriteria: <CheckCriteria>[
                CheckCriteria(
                  criteriaName: 'Correctly formatted',
                  criteriaState: controller.isValidEmail,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            Obx(
              () => FilledButton.icon(
                icon: const Icon(Icons.app_registration),
                onPressed: controller.isLoading.value
                    ? null
                    : controller.submitPatientData,
                label: const Text('Register'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
