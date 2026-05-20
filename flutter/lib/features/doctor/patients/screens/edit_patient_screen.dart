import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/app/enums.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/core/widgets/custom_text_field.dart';
import 'package:dermascan/features/doctor/patients/controller/edit_patient_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditPatientScreen extends GetView<EditPatientController> {
  const EditPatientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Patient')),
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
                    isExpanded: true,
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
                          overflow: TextOverflow.ellipsis,
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
            Obx(
              () => Card(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(AppTheme.radiusSmall),
                  ),
                ),
                child: CheckboxListTile(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  title: const Text('Sunburn History'),
                  subtitle: const Text('Has the patient ever had a sunburn?'),
                  value: controller.previousSunburns.value,
                  onChanged: (bool? value) {
                    if (!controller.isLoading.value) {
                      if (value != null) {
                        controller.previousSunburns.value = value;
                      }
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Obx(
              () => Card(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(AppTheme.radiusSmall),
                  ),
                ),
                child: CheckboxListTile(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  title: const Text('Skin Surgery'),
                  subtitle: const Text('Any previous skin-related surgeries?'),
                  value: controller.previousSkinSurgeries.value,
                  onChanged: (bool? value) {
                    if (!controller.isLoading.value) {
                      if (value != null) {
                        controller.previousSkinSurgeries.value = value;
                      }
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Obx(
              () => Card(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(AppTheme.radiusSmall),
                  ),
                ),
                child: CheckboxListTile(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  title: const Text('Tanning Bed Use'),
                  subtitle: const Text('Does the patient use tanning beds?'),
                  value: controller.tanningBedExposure.value,
                  onChanged: (bool? value) {
                    if (!controller.isLoading.value) {
                      if (value != null) {
                        controller.tanningBedExposure.value = value;
                      }
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spaceMedium),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: controller.currentCountryTextController,
                    readOnly: true,
                    onTap: () => controller.showCountryBottomSheet(
                      context: context,
                      isBirthCountry: false,
                    ),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Country',
                      prefixIcon: Icon(Icons.public),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                Expanded(
                  child: TextField(
                    controller: controller.birthCountryTextController,
                    readOnly: true,
                    onTap: () => controller.showCountryBottomSheet(
                      context: context,
                      isBirthCountry: true,
                    ),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Birth Country',
                      prefixIcon: Icon(Icons.public),
                    ),
                  ),
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
                label: const Text('Update'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
