import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/widgets/human_body_selector.dart';
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
          return ListView(
            controller: controller.scrollController,
            scrollDirection: Axis.vertical,
            padding: AppTheme.scaffoldPadding.copyWith(top: 0, bottom: 0),
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
                    onPressed: controller.changeCurrentSelectedBodySide,
                    icon: const Icon(Icons.screen_rotation_alt),
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
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusLarge,
                            ),
                            color:
                                controller
                                    .selectedLesion
                                    .value!
                                    .isSuspicious
                                    .value
                                ? Colors.red.withValues(alpha: 0.3)
                                : AppTheme.highlightColor,
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
                                'Location: ${controller.selectedLesion.value!.location}',
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
                                  style: Theme.of(context).textTheme.bodySmall,
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
              Align(
                alignment: Alignment.topCenter,
                child: HumanBodySelector(
                  key: controller.bodySelectorKey,
                  map: controller.getBodyMap(
                    bodySide: controller.currentSelectedBodySide.value,
                    gender: controller.patient.gender,
                  ),
                  onTap: (BodyPart? bodyPart) {
                    if (bodyPart != null) {
                      controller.openDiagnosisDialog(bodyPartId: bodyPart.id);
                    }
                  },
                  multiSelect: false,
                  strokeColor: Colors.black,
                  selectedColor: Theme.of(context).primaryColor,
                  height: (MediaQuery.of(context).size.height / 2),
                  width: (MediaQuery.of(context).size.width / 2),
                  lesionMap: controller.lesionDiagnosisCountMap,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
