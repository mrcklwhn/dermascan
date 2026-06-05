import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/app/enums.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/core/widgets/custom_text_field.dart';
import 'package:dermascan/features/doctor/patients/controller/add_patient_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddPatientScreen extends GetView<AddPatientController> {
  const AddPatientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final OutlineInputBorder noBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      borderSide: BorderSide.none,
    );

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
            Text(
              'General Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spaceSmall),
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
                    decoration: InputDecoration(
                      border: noBorder,
                      enabledBorder: noBorder,
                      focusedBorder: noBorder,
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
                    decoration: InputDecoration(
                      border: noBorder,
                      enabledBorder: noBorder,
                      focusedBorder: noBorder,
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

            const SizedBox(height: AppTheme.spaceSmall),
            const SizedBox(height: AppTheme.spaceMedium),

            Text(
              'Sun & Lifestyle',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            _buildToggleCard(
              title: 'Sunscreen Use',
              subtitle: 'Does the patient regularly use sunscreen?',
              value: controller.sunscreenUse,
            ),
            const SizedBox(height: AppTheme.spaceMedium),

            _buildToggleCard(
              title: 'Sunburn History',
              subtitle: 'Has the patient ever had a sunburn?',
              value: controller.previousSunburns,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            _buildToggleCard(
              title: 'Tanning Bed Use',
              subtitle: 'Does the patient use tanning beds?',
              value: controller.tanningBedExposure,
            ),
            const SizedBox(height: AppTheme.spaceMedium),

            Text(
              'Medical History',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spaceSmall),

            _buildToggleCard(
              title: 'Personal History of Melanoma',
              value: controller.personalHistoryMelanoma,
              subtitle: 'Previous personal melanoma diagnosis.',
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            _buildToggleCard(
              title: 'Family History of Melanoma',
              value: controller.familyHistoryMelanoma,
              subtitle: 'Melanoma cases in close relatives.',
            ),

            const SizedBox(height: AppTheme.spaceMedium),
            _buildToggleCard(
              title: 'Skin Surgery',
              subtitle: 'Any previous skin-related surgeries?',
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
                      child: _buildToggleCard(
                        title: 'Malignant / Cancerous',
                        subtitle: 'Was a cancerous lesion removed?',
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
            Text('Location', style: Theme.of(context).textTheme.titleMedium),
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
                    decoration: InputDecoration(
                      border: noBorder,
                      enabledBorder: noBorder,
                      focusedBorder: noBorder,
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
            const SizedBox(height: AppTheme.spaceLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required RxBool value,
  }) {
    return Obx(
      () => Card(
        child: CheckboxListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          value: value.value,
          onChanged: (bool? val) => value.value = val ?? false,
        ),
      ),
    );
  }
}
