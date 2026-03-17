import 'package:dermascan/app/enums.dart';
import 'package:dermascan/features/doctor/patients/controller/create_patient_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreatePatientScreen extends StatelessWidget {
  CreatePatientScreen({super.key});

  final CreatePatientController createPatientController =
      Get.find<CreatePatientController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Patient')),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 24),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_add_alt_1_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                controller: createPatientController.scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 16),
                    TextField(
                      controller: createPatientController.nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller:
                                createPatientController.birthdayController,
                            readOnly: true,
                            onTap: () =>
                                createPatientController.selectDate(context),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Date of Birth',
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Obx(
                            () => DropdownButtonFormField<Gender>(
                              initialValue:
                                  createPatientController.selectedGender.value,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Gender',
                                prefixIcon: Icon(Icons.wc_outlined),
                              ),
                              items: Gender.values.map((Gender g) {
                                return DropdownMenuItem<Gender>(
                                  value: g,
                                  child: Text(
                                    g.name[0].toUpperCase() +
                                        g.name.substring(1),
                                  ),
                                );
                              }).toList(),
                              onChanged: (Gender? newValue) {
                                createPatientController.selectedGender.value =
                                    newValue;
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: createPatientController.emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'E-Mail',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Obx(() {
                        return FilledButton(
                          onPressed: createPatientController.isLoading.value
                              ? null
                              : createPatientController.submitPatientData,
                          child: const Text('Create Patient'),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
