import 'package:dermascan/core/models/doctor.dart';
import 'package:dermascan/features/practice/profile/controller/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PracticeProfileScreen extends StatelessWidget {
  PracticeProfileScreen({super.key});

  final PracticeProfileController controller =
      Get.find<PracticeProfileController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background for contrast
      appBar: AppBar(title: const Text('Account Profile'), centerTitle: true),
      body: Obx(() {
        if (controller.isInitializing.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Column(
            children: <Widget>[
              // --- 1. Hero Header Section ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 30,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(
                        Icons.business,
                        size: 50,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.currentPractice.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Practice ID: ${controller.currentPractice.id}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // --- 2. Doctors Header ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text(
                          'Team Members',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${controller.assignedDoctors.length} Doctors',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- 3. Doctors List ---
                    if (controller.assignedDoctors.isEmpty)
                      _buildEmptyState()
                    else
                      ...controller.assignedDoctors.map(
                        (Doctor doctor) => _buildDoctorCard(doctor),
                      ),

                    const SizedBox(height: 40),

                    // --- 4. Logout (Bottom Action) ---
                    Center(
                      child: TextButton.icon(
                        onPressed: () => controller.authService.signOut(),
                        icon: const Icon(Icons.exit_to_app, color: Colors.red),
                        label: const Text(
                          'Log Out',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade100,
          child: const Icon(Icons.person, color: Colors.grey),
        ),
        title: Text(
          doctor.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('Assigned Specialist'),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: <Widget>[
            Icon(Icons.group_off, size: 50, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            const Text('No doctors assigned to this practice yet.'),
          ],
        ),
      ),
    );
  }
}
