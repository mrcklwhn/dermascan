import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/core/widgets/custom_text_field.dart';
import 'package:dermascan/features/doctor/patients/controller/edit_lesion_controller.dart';
import 'package:dermascan/translations/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditLesionScreen extends GetView<EditLesionController> {
  const EditLesionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(TrKeys.lesion.editLesion.tr)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppTheme.scaffoldPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const CustomIcon(iconData: Icons.edit_note),
              const SizedBox(height: AppTheme.spaceLarge),
              Text(
                TrKeys.lesion.placement.tr,
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: AppTheme.spaceSmall),
              CustomTextField(
                textEditingController: controller.locationNameController,
                focusNode: controller.locationNameFocusNode,
                onSubmitted: (_) => controller.submittedLocationName(),
                labelText: TrKeys.common.location.tr,
                prefixIcon: Icons.place,
                textInputType: TextInputType.text,
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Text(
                TrKeys.lesion.classification.tr,
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: AppTheme.spaceSmall),
              Obx(
                () => Card(
                  child: CheckboxListTile(
                    title: Text(TrKeys.lesion.suspiciousLesion.tr),
                    subtitle: Text(TrKeys.lesion.markSuspicious.tr),
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
                    title: Text(TrKeys.lesion.excisedLesion.tr),
                    subtitle: Text(TrKeys.lesion.markExcised.tr),
                    value: controller.wasRemoved.value,
                    onChanged: (bool? value) =>
                        controller.wasRemoved.value = value ?? false,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Text(
                TrKeys.common.additionalInfo.tr,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              CustomTextField(
                textEditingController: controller.notesController,
                focusNode: controller.notesFocusNode,
                onSubmitted: (_) => controller.submittedNotes(),
                labelText: TrKeys.common.notes.tr,
                prefixIcon: Icons.description,
                textInputType: TextInputType.multiline,
              ),
              const SizedBox(height: AppTheme.spaceLarge),
              FilledButton.icon(
                  icon: const Icon(Icons.save),
                  onPressed: controller.updateLesion,
                  label: Text(TrKeys.common.save.tr),
                ),
              const SizedBox(height: AppTheme.spaceMedium),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete),
                onPressed: controller.showDeleteLesionDialog,
                label: Text(TrKeys.common.delete.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
