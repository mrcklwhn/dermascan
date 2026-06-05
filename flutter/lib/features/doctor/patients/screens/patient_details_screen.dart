import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/models/body_lesion.dart';
import 'package:dermascan/core/widgets/human_body_3d_selector.dart';
import 'package:dermascan/features/doctor/patients/controller/patient_details_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PatientDetailsScreen extends GetView<PatientDetailsController> {
  const PatientDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Profile')),
      body: SafeArea(
        child: Obx(() {
          if (controller.isInitializing.value) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          return Padding(
            padding: AppTheme.scaffoldPadding,
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    IconButton(
                      padding: const EdgeInsets.all(AppTheme.spaceSmall),
                      constraints: BoxConstraints.tight(
                        const Size(
                          AppTheme.radiusLarge * 2,
                          AppTheme.radiusLarge * 2,
                        ),
                      ),
                      onPressed: controller.resetModelPosition,
                      icon: const Icon(Icons.gps_fixed),
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                          AppTheme.highlightColor,
                        ),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusLarge,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceMedium),
                    Expanded(
                      child: Obx(() {
                        if (controller.selectedLesion.value != null) {

                          final Color displayColor =
                          controller.selectedLesion.value!.wasRemoved.value
                              ? Colors.grey.withValues(alpha: 0.3)
                              : controller.selectedLesion.value!
                              .isSuspicious
                              .value
                              ? Colors.red.withValues(alpha: 0.3)
                              : AppTheme.highlightColor;

                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusLarge,
                              ),
                              color: displayColor,
                            ),
                            constraints: BoxConstraints.tight(
                              const Size(
                                AppTheme.radiusLarge * 2,
                                AppTheme.radiusLarge * 2,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  'Location: ${controller.selectedLesion.value!.locationName ?? 'Not specified'}',
                                  style: Theme.of(context).textTheme.titleSmall,
                                  textAlign: TextAlign.start,
                                ),
                                if (controller
                                    .selectedLesion
                                    .value!
                                    .diagnoses
                                    .isNotEmpty)
                                  Text(
                                    'Last Diagnosis: ${DateFormat('dd.MM.yyyy').format(controller.selectedLesion.value!.diagnoses.first.date)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                    textAlign: TextAlign.start,
                                  ),
                              ],
                            ),
                          );
                        } else {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusLarge,
                              ),
                              color: AppTheme.highlightColor,
                            ),
                            constraints: BoxConstraints.tight(
                              const Size(
                                AppTheme.radiusLarge * 2,
                                AppTheme.radiusLarge * 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'No Lesion selected',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          );
                        }
                      }),
                    ),

                    const SizedBox(width: AppTheme.spaceMedium),
                    IconButton(
                      padding: const EdgeInsets.all(AppTheme.spaceSmall),
                      constraints: BoxConstraints.tight(
                        const Size(
                          AppTheme.radiusLarge * 2,
                          AppTheme.radiusLarge * 2,
                        ),
                      ),
                      onPressed: controller.openPatientInfoDialog,
                      icon: const Icon(Icons.info),
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                          AppTheme.highlightColor,
                        ),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusLarge,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spaceLarge),
                Expanded(
                  child: HumanBody3DSelector(
                    key: controller.bodySelectorKey,
                    gender: controller.patient.gender,
                    lesions: controller.lesions,
                    onPointAdded: (BodyLesion lesion) {
                      controller.openDiagnosisDialog(lesion: lesion);
                    },
                    selectedPosition: controller.selectedPosition,
                    suspiciousColor: Colors.red,
                  ),
                ),

                const SizedBox(height: AppTheme.spaceLarge),
              ],
            ),
          );
        }),
      ),
    );
  }
}
