import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/enums.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/core/widgets/custom_text_field.dart';
import 'package:dermascan/core/widgets/custom_toggle_card.dart';
import 'package:dermascan/features/doctor/patients/controller/edit_patient_controller.dart';
import 'package:dermascan/translations/tr_keys.dart';
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
      appBar: AppBar(title: Text(TrKeys.patient.editPatient.tr)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppTheme.scaffoldPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const CustomIcon(iconData: Icons.person_add),
              const SizedBox(height: AppTheme.spaceLarge),
              Text(
                TrKeys.common.generalInformation.tr,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              CustomTextField(
                textEditingController: controller.nameController,
                focusNode: controller.nameFocusNode,
                onSubmitted: (_) => controller.submittedName(),
                labelText: TrKeys.common.fullName.tr,
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
                        labelText: TrKeys.common.dateOfBirth.tr,
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
                        labelText: TrKeys.common.gender.tr,
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


          const SizedBox(height: AppTheme.spaceMedium),

          Text(
            TrKeys.patient.sunAndLifestyle.tr,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          ToggleCard(
            title: TrKeys.patient.sunscreenUse.tr,
            subtitle: TrKeys.patient.sunscreenQuestion.tr,
            value: controller.sunscreenUse,
          ),
          const SizedBox(height: AppTheme.spaceSmall),

          ToggleCard(
            title: TrKeys.patient.sunburnHistory.tr,
            subtitle: TrKeys.patient.sunburnQuestion.tr,
            value: controller.previousSunburns,
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          ToggleCard(
            title: TrKeys.patient.tanningBedUse.tr,
            subtitle: TrKeys.patient.tanningBedQuestion.tr,
            value: controller.tanningBedExposure,
          ),
          const SizedBox(height: AppTheme.spaceMedium),

          Text(
            TrKeys.patient.medicalHistory.tr,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spaceSmall),

          ToggleCard(
            title: TrKeys.patient.personalHistoryMelanoma.tr,
            value: controller.personalHistoryMelanoma,
            subtitle: TrKeys.patient.personalMelanomaDesc.tr,
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          ToggleCard(
            title: TrKeys.patient.familyHistoryMelanoma.tr,
            value: controller.familyHistoryMelanoma,
            subtitle: TrKeys.patient.familyMelanomaDesc.tr,
          ),

          const SizedBox(height: AppTheme.spaceSmall),
          ToggleCard(
            title: TrKeys.patient.skinSurgery.tr,
            subtitle: TrKeys.patient.skinSurgeriesQuestion.tr,
            value: controller.previousSkinSurgeries,
          ),

          Obx(() {
            if (controller.previousSkinSurgeries.value) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(height: AppTheme.spaceSmall),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceMedium,
                    ),
                    child: ToggleCard(
                      title: TrKeys.patient.malignantCancerous.tr,
                      subtitle: TrKeys.patient.cancerousRemovedQuestion.tr,
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
          Text(TrKeys.common.location.tr, style: Theme.of(context).textTheme.titleMedium),
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
                    labelText: TrKeys.common.country.tr,
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
                    labelText: TrKeys.common.birthCountry.tr,
                    prefixIcon: const Icon(Icons.public),
                  ),
                ),
              ),
            ],
          ),
              const SizedBox(height: AppTheme.spaceLarge),
              FilledButton.icon(
                  icon: const Icon(Icons.save),
                  onPressed: controller.submitPatientData,
                  label: Text(TrKeys.common.save.tr),
                ),

              const SizedBox(height: AppTheme.spaceMedium),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete),
                onPressed: controller.showDeletePatientDialog,
                label: Text(TrKeys.common.delete.tr),
              ),
            ],
          ),
      ),
      )
    );
  }

  String _genderTranslationKey(Gender gender) {
    switch (gender) {
      case Gender.male:
        return TrKeys.common.male;
      case Gender.female:
        return TrKeys.common.female;
      case Gender.divers:
        return TrKeys.common.divers;
      case Gender.undefined:
        return TrKeys.common.undefined;
    }
  }
}
