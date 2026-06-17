import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/core/widgets/custom_text_field.dart';
import 'package:dermascan/features/doctor/patients/controller/edit_lesion_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditLesionScreen extends GetView<EditLesionController> {
  const EditLesionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Lesion'.tr)),
      body: SafeArea(
        child: ListView(
          controller: controller.scrollController,
          scrollDirection: Axis.vertical,
          padding: AppTheme.scaffoldPadding,
          children: <Widget>[
            const CustomIcon(iconData: Icons.edit_note),
            const SizedBox(height: AppTheme.spaceLarge),
            Text(
              'Placement'.tr,
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: AppTheme.spaceSmall),
            CustomTextField(
              textEditingController: controller.locationNameController,
              focusNode: controller.locationNameFocusNode,
              onSubmitted: (_) => controller.submittedLocationName(),
              labelText: 'Location'.tr,
              prefixIcon: Icons.location_on,
              textInputType: TextInputType.name,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              'Classification'.tr,
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: AppTheme.spaceSmall),
            Obx(
              () => Card(
                child: CheckboxListTile(
                  title: Text('Suspicious Lesion'.tr),
                  subtitle: Text('Mark this lesion as suspicious.'.tr),
                  value: controller.isSuspicious.value,
                  onChanged: (bool? value) {
                    if (!controller.isLoading.value) {
                      if (value != null) {
                        controller.isSuspicious.value = value;
                      }
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Obx(
              () => Card(
                child: CheckboxListTile(
                  title: Text('Excised'.tr),
                  subtitle: Text('Mark this lesion as excised.'.tr),
                  value: controller.wasRemoved.value,
                  onChanged: (bool? value) {
                    if (!controller.isLoading.value) {
                      if (value != null) {
                        controller.wasRemoved.value = value;
                      }
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),

            CustomTextField(
              textEditingController: controller.testResultController,
              focusNode: controller.testResultFocusNode,
              onSubmitted: (_) => controller.submittedTestResult(),
              labelText: 'Test Result'.tr,
              prefixIcon: Icons.science,
              textInputType: TextInputType.text,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              'Additional Info'.tr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            CustomTextField(
              textEditingController: controller.notesController,
              focusNode: controller.notesFocusNode,
              onSubmitted: (_) => controller.submittedNotes(),
              labelText: 'Notes'.tr,
              prefixIcon: Icons.description,
              textInputType: TextInputType.multiline,
              minLines: 1,
              maxLines: 5,
            ),

            const SizedBox(height: AppTheme.spaceLarge),
            Obx(
              () => FilledButton.icon(
                icon: const Icon(Icons.app_registration),
                onPressed: controller.isLoading.value
                    ? null
                    : controller.updateLesion,
                label: Text('Update'.tr),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            OutlinedButton.icon(
              onPressed: controller.isLoading.value
                  ? null
                  : () => controller.showDeleteLesionDialog(),
              icon: const Icon(Icons.delete),
              label: Text('Delete'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
