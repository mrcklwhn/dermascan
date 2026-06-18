import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/app/enums.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/core/widgets/custom_text_field.dart';
import 'package:dermascan/core/widgets/custom_toggle_card.dart';
import 'package:dermascan/features/doctor/patients/controller/edit_patient_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditPatientScreen extends GetView<EditPatientController> {
  const EditPatientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final OutlineInputBorder noBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      borderSide: BorderSide.none,
    );

    return Scaffold(
      appBar: AppBar(title: Text('Edit Patient'.tr)),
      body: SafeArea(
        child: ListView(
          controller: controller.scrollController,
          scrollDirection: Axis.vertical,
          padding: AppTheme.scaffoldPadding,
          children: <Widget>[
            const CustomIcon(iconData: Icons.person_add),
            const SizedBox(height: AppTheme.spaceLarge),
            Text(
              'General Information'.tr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            CustomTextField(
              textEditingController: controller.nameController,
              focusNode: controller.nameFocusNode,
              onSubmitted: (_) => controller.submittedName(),
              labelText: 'Full Name'.tr,
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
                    decoration: InputDecoration(
                      border: noBorder,
                      enabledBorder: noBorder,
                      focusedBorder: noBorder,
                      labelText: 'Date of Birth'.tr,
                      prefixIcon: const Icon(Icons.calendar_month),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                Expanded(
                  child: DropdownButtonFormField<Gender>(
                    isExpanded: true,
                    initialValue: controller.selectedGender,
                    decoration: InputDecoration(
                      border: noBorder,
                      enabledBorder: noBorder,
                      focusedBorder: noBorder,
                      labelText: 'Gender'.tr,
                      prefixIcon: const Icon(Icons.wc_outlined),
                    ),
                    items: Gender.values.map((Gender g) {
                      return DropdownMenuItem<Gender>(
                        value: g,
                        child: Text(
                          _genderTranslationKey(g).tr,
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

            const SizedBox(height: AppTheme.spaceSmall),
            const SizedBox(height: AppTheme.spaceMedium),

            Text(
              'Sun & Lifestyle'.tr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            ToggleCard(
              title: 'Sunscreen Use'.tr,
              subtitle: 'Does the patient regularly use sunscreen?'.tr,
              value: controller.sunscreenUse,
            ),
            const SizedBox(height: AppTheme.spaceMedium),

            ToggleCard(
              title: 'Sunburn History'.tr,
              subtitle: 'Has the patient ever had a sunburn?'.tr,
              value: controller.previousSunburns,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            ToggleCard(
              title: 'Tanning Bed Use'.tr,
              subtitle: 'Does the patient use tanning beds?'.tr,
              value: controller.tanningBedExposure,
            ),
            const SizedBox(height: AppTheme.spaceMedium),

            Text(
              'Medical History'.tr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spaceSmall),

            ToggleCard(
              title: 'Personal History of Melanoma'.tr,
              value: controller.personalHistoryMelanoma,
              subtitle: 'Previous personal melanoma diagnosis.'.tr,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            ToggleCard(
              title: 'Family History of Melanoma'.tr,
              value: controller.familyHistoryMelanoma,
              subtitle: 'Melanoma cases in close relatives.'.tr,
            ),

            const SizedBox(height: AppTheme.spaceMedium),
            ToggleCard(
              title: 'Skin Surgery'.tr,
              subtitle: 'Any previous skin-related surgeries?'.tr,
              value: controller.previousSkinSurgeries,
            ),

            Obx(() {
              if (controller.previousSkinSurgeries.value) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(height: AppTheme.spaceMedium),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceMedium,
                      ),
                      child: ToggleCard(
                        title: 'Malignant / Cancerous'.tr,
                        subtitle: 'Was a cancerous lesion removed?'.tr,
                        value: controller.previousCancerSurgeries,
                      ),
                    ),
                  ],
                );
              } else {
                return const Center();
              }
            }),

            const SizedBox(height: AppTheme.spaceMedium),
            Text('Location'.tr, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.spaceSmall),
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
                    decoration: InputDecoration(
                      border: noBorder,
                      enabledBorder: noBorder,
                      focusedBorder: noBorder,
                      labelText: 'Country'.tr,
                      prefixIcon: const Icon(Icons.public),
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
                    decoration: InputDecoration(
                      border: noBorder,
                      enabledBorder: noBorder,
                      focusedBorder: noBorder,
                      labelText: 'Birth Country'.tr,
                      prefixIcon: const Icon(Icons.public),
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
                label: Text('Update'.tr),
              ),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
          ],
        ),
      ),
    );
  }

  String _genderTranslationKey(Gender gender) {
    switch (gender) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.divers:
        return 'Divers';
      case Gender.undefined:
        return 'Undefined';
    }
  }
}
