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
        child: SingleChildScrollView(
          padding: AppTheme.scaffoldPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                prefixIcon: Icons.place,
                textInputType: TextInputType.text,
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
                    onChanged: (bool? value) =>
                        controller.isSuspicious.value = value ?? false,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Obx(
                () => Card(
                  child: CheckboxListTile(
                    title: Text('Excised Lesion'.tr),
                    subtitle: Text('Mark this lesion as excised.'.tr),
                    value: controller.wasRemoved.value,
                    onChanged: (bool? value) =>
                        controller.wasRemoved.value = value ?? false,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              CustomTextField(
                textEditingController: controller.testResultController,
                focusNode: controller.testResultFocusNode,
                onSubmitted: (_) => controller.submittedTestResult(),
                labelText: 'Test Result'.tr,
                prefixIcon: Icons.assignment,
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
              ),
              const SizedBox(height: AppTheme.spaceLarge),
              FilledButton.icon(
                  icon: const Icon(Icons.save),
                  onPressed: controller.updateLesion,
                  label: Text('Save'.tr),
                ),
              const SizedBox(height: AppTheme.spaceMedium),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete),
                onPressed: controller.showDeleteLesionDialog,
                label: Text('Delete'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
