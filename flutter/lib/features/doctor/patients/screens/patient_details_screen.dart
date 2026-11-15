import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/models/body_lesion.dart';
import 'package:dermascan/core/widgets/human_body_3d_selector.dart';
import 'package:dermascan/features/doctor/patients/controller/patient_details_controller.dart';
import 'package:dermascan/translations/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PatientDetailsScreen extends GetView<PatientDetailsController> {
  const PatientDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(TrKeys.patient.patientProfile.tr)),
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          if (controller.isInitializing.value) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          return Stack(
            children: <Widget>[
              Positioned.fill(
                child: HumanBody3DSelector(
                  key: controller.bodySelectorKey,
                  gender: controller.patient.gender,
                  lesions: controller.lesions,
                  onPointAdded: (BodyLesion lesion) {
                    controller.openDiagnosisDialog(lesion: lesion);
                  },
                  selectedPosition: controller.selectedPosition,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                child: Row(
                  children: <Widget>[
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
                          Theme.of(context).colorScheme.surfaceContainerLow,
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
                    const SizedBox(width: AppTheme.spaceSmall),
                    Expanded(
                      child: Obx(() {
                        final BodyLesion? lesion = controller.selectedLesion.value;
                        if (lesion != null) {
                          final Color baseColor =
                              lesion.wasRemoved.value
                                  ? Colors.grey
                                  : lesion.isSuspicious.value
                                      ? Colors.red
                                      : Theme.of(context).colorScheme.secondary;

                          final Color displayColor = Color.lerp(
                            Theme.of(context).colorScheme.surfaceContainerLow,
                            baseColor,
                            0.5,
                          )!;

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
                                  '${TrKeys.common.location.tr}: ${lesion.locationName}',
                                  style: Theme.of(context).textTheme.titleSmall,
                                  textAlign: TextAlign.start,
                                ),
                                if (lesion.diagnoses.isNotEmpty)
                                  Text(
                                    '${TrKeys.diagnosis.lastDiagnosis.tr}: ${DateFormat('dd.MM.yyyy').format(lesion.diagnoses.first.date)}',
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
                              color: Theme.of(context).colorScheme.surfaceContainerLow,
                            ),
                            constraints: BoxConstraints.tight(
                              const Size(
                                AppTheme.radiusLarge * 2,
                                AppTheme.radiusLarge * 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                TrKeys.lesion.noLesionSelected.tr,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          );
                        }
                      }),
                    ),

                    const SizedBox(width: AppTheme.spaceSmall),
                    IconButton(
                      padding: const EdgeInsets.all(AppTheme.spaceSmall),
                      constraints: BoxConstraints.tight(
                        const Size(
                          AppTheme.radiusLarge * 2,
                          AppTheme.radiusLarge * 2,
                        ),
                      ),
                      onPressed: controller.openPdfExportLesionSelectionPage,
                      icon: const Icon(Icons.picture_as_pdf),
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                          Theme.of(context).colorScheme.surfaceContainerLow,
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
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
