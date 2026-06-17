import 'dart:typed_data';

import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/models/body_lesion.dart';
import 'package:dermascan/core/models/country.dart';
import 'package:dermascan/core/models/diagnosis.dart';
import 'package:dermascan/core/models/patient.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PatientInfoBottomSheetController extends GetxController {
  final List<BodyLesion> lesions;
  final ScrollController listScrollController = ScrollController();

  PatientInfoBottomSheetController({required this.lesions});

  List<({Diagnosis diagnosis, String locationName, String position})>
  get latestDiagnoses {
    return lesions
        .expand(
          (BodyLesion lesion) => lesion.diagnoses.map(
            (Diagnosis diagnosis) => (
              diagnosis: diagnosis,
              locationName: lesion.locationName,
              position: lesion.position,
            ),
          ),
        )
        .toList()
      ..sort(
        (
          ({Diagnosis diagnosis, String locationName, String position}) a,
          ({Diagnosis diagnosis, String locationName, String position}) b,
        ) => b.diagnosis.date.compareTo(a.diagnosis.date),
      );
  }

  List<({Diagnosis diagnosis, String locationName, String position})>
  get top5Diagnoses => latestDiagnoses.take(5).toList();

  @override
  void onClose() {
    listScrollController.dispose();
    super.onClose();
  }
}

class PatientInfoBottomSheet extends StatelessWidget {
  final List<BodyLesion> lesions;
  final Patient patient;
  final VoidCallback openEditPatientPage;
  final Function({required String position, String? diagnosisId})
  openDiagnosisDialog;

  const PatientInfoBottomSheet({
    super.key,
    required this.lesions,
    required this.patient,
    required this.openEditPatientPage,
    required this.openDiagnosisDialog,
  });

  @override
  Widget build(BuildContext context) {
    final PatientInfoBottomSheetController controller = Get.put(
      PatientInfoBottomSheetController(lesions: lesions),
    );

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.7,
      padding: AppTheme.scaffoldPadding.copyWith(top: 0, bottom: 0),
      decoration: const BoxDecoration(
        color: AppTheme.highlightColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      child: Column(
        children: <Widget>[
          Container(
            margin: const EdgeInsets.symmetric(vertical: AppTheme.spaceMedium),
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.onSecondaryFixedVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView(
              controller: controller.listScrollController,
              children: <Widget>[
                Card(
                  color: AppTheme.scaffoldBg,
                  child: ListTile(
                    title: Text(
                      patient.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    leading: const Icon(Icons.person),
                    trailing: const Icon(Icons.arrow_forward),
                    subtitle: Text(
                      '${'Birthday'.tr}: ${DateFormat('dd.MM.yyyy').format(patient.dateOfBirth)}\n'
                      '${'Country'.tr}: ${allCountries.firstWhereOrNull((Country c) => c.isoCode == patient.birthCountry)?.name ?? 'Not available'.tr}\n'
                      '${'Gender'.tr}: ${patient.gender.name.capitalizeFirst}',
                    ),
                    onTap: () {
                      Get.back();
                      openEditPatientPage();
                    },
                  ),
                ),

                const SizedBox(height: AppTheme.spaceMedium),
                if (patient.previousSunburns ||
                    patient.previousSkinSurgeries ||
                    patient.tanningBedExposure ||
                    patient.sunscreenUse ||
                    patient.previousCancerSurgeries ||
                    patient.personalHistoryMelanoma ||
                    patient.familyHistoryMelanoma) ...<Widget>[
                  Text(
                    'Medical History'.tr,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTheme.spaceSmall),

                  Wrap(
                    spacing: AppTheme.spaceSmall,
                    children: <Widget>[
                      _buildHistoryChip(
                        'Sunburn History'.tr,
                        patient.previousSunburns,
                      ),
                      _buildHistoryChip(
                        'Skin Surgery'.tr,
                        patient.previousSkinSurgeries,
                      ),
                      _buildHistoryChip(
                        'Malignant Skin Surgery'.tr,
                        patient.previousCancerSurgeries,
                      ),
                      _buildHistoryChip(
                        'Tanning Bed Use'.tr,
                        patient.tanningBedExposure,
                      ),
                      _buildHistoryChip(
                        'Sunscreen Use'.tr,
                        patient.sunscreenUse,
                      ),
                      _buildHistoryChip(
                        'Personal Melanoma History'.tr,
                        patient.personalHistoryMelanoma,
                      ),
                      _buildHistoryChip(
                        'Family Melanoma History'.tr,
                        patient.familyHistoryMelanoma,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),
                ],
                Text(
                  'Timeline (Latest Diagnoses)'.tr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.spaceSmall),

                Obx(() {
                  final List<
                    ({
                      Diagnosis diagnosis,
                      String locationName,
                      String position,
                    })
                  >
                  diagnoses = controller.top5Diagnoses;
                  if (diagnoses.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppTheme.spaceMedium),
                      child: Center(child: Text('No Diagnosis available!'.tr)),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: diagnoses.length,
                    itemBuilder: (BuildContext context, int index) {
                      final ({
                        Diagnosis diagnosis,
                        String locationName,
                        String position,
                      })
                      item = diagnoses[index];

                      final Uint8List bytes =
                          item.diagnosis.analyzedImages!['original']!;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Card(
                            color: AppTheme.scaffoldBg,
                            child: ListTile(
                              title: Text('Diagnosis'.tr),
                              leading: AspectRatio(
                                aspectRatio: 1.0,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSmall,
                                  ),
                                  child: Image(
                                    image: MemoryImage(bytes),
                                    fit: BoxFit.cover,
                                    gaplessPlayback: true,
                                    errorBuilder:
                                        (
                                          BuildContext context,
                                          Object error,
                                          StackTrace? stackTrace,
                                        ) => const Icon(Icons.broken_image),
                                  ),
                                ),
                              ),
                              subtitle: Text(
                                '${'Location'.tr}: ${item.locationName}\n${'Date'.tr}: ${DateFormat('dd.MM.yyyy').format(item.diagnosis.date)}',
                              ),
                              onTap: () {
                                Get.back();
                                openDiagnosisDialog(
                                  position: item.position,
                                  diagnosisId: item.diagnosis.id,
                                );
                              },
                              trailing: const Icon(Icons.arrow_forward),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceSmall),
                        ],
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryChip(String title, bool visible) {
    if (!visible) return const Center();
    return Chip(
      label: Text(title),
      backgroundColor: AppTheme.scaffoldBg,
      side: BorderSide.none,
    );
  }
}
