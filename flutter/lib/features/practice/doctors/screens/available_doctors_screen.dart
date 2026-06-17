import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/models/doctor.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/features/practice/doctors/controller/available_doctors_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AvailableDoctorsScreen extends GetView<AvailableDoctorsController> {
  const AvailableDoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Available Doctors'.tr)),
      body: SafeArea(
        child: Obx(() {
          if (controller.isInitializing.value) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (controller.doctors.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildDoctorList();
        }),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: AppTheme.scaffoldPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Spacer(),
          const CustomIcon(iconData: Icons.person_add),
          const SizedBox(height: AppTheme.spaceLarge),
          Text(
            'No Doctors Available',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            'No doctors available.\nPress refresh to check again.'.tr,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Obx(
            () => OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              onPressed: controller.isInitializing.value
                  ? null
                  : controller.reloadDoctors,
              label: Text('Refresh'.tr),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorList() {
    return Padding(
      padding: AppTheme.scaffoldPadding.copyWith(top: 0, bottom: 0),
      child: Column(
        children: <Widget>[
          SearchBar(
            hintText: 'Search ...',
            controller: controller.searchBarController,
            leading: const Icon(Icons.search),
            trailing: <Widget>[
              IconButton(
                onPressed: controller.clearSearchBar,
                icon: const Icon(Icons.clear),
              ),
            ],
            onChanged: (String value) => controller.filterDoctors(query: value),
            focusNode: controller.searchBarFocusNode,
            onTapOutside: (_) => controller.unfocusSearchBar(),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Obx(
            () => Expanded(
              child: ListView.builder(
                controller: controller.listScrollController,
                scrollDirection: Axis.vertical,
                itemCount: controller.visibleDoctors.length,
                itemBuilder: (BuildContext context, int index) {
                  final Doctor doctor = controller.visibleDoctors[index];
                  return Column(
                    children: <Widget>[
                      Card(
                        child: ListTile(
                          title: Text(doctor.name),
                          leading: const Icon(Icons.person),
                          trailing: const Icon(Icons.arrow_forward),
                          subtitle: Text(
                            'E-Mail: ${doctor.email}\nBorn on ${DateFormat('dd.MM.yyyy').format(doctor.dateOfBirth)}',
                          ),
                          onTap: controller.isInitializing.value
                              ? null
                              : () => controller.showDoctorProfile(
                                  doctorId: doctor.id,
                                ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceSmall),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
