import 'package:dermascan/core/models/doctor.dart';
import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/features/doctor/profile/controller/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorProfileScreen extends StatelessWidget {
  DoctorProfileScreen({super.key});

  final DoctorProfileController controller =
      Get.find<DoctorProfileController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text('Medical Profile')),
      body: Obx(() {
        if (controller.isInitializing.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final Doctor doctor = controller.currentDoctor;
        final Practice practice = controller.currentPractice;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Column(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(
                        Icons.medical_services,
                        size: 50,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      doctor.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      doctor.email,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const _SectionHeader(title: 'Personal Details'),
              _buildInfoTile(
                icon: Icons.cake_outlined,
                label: 'Date of Birth',
                value:
                    "${doctor.dateOfBirth.day.toString().padLeft(2, '0')}.${doctor.dateOfBirth.month.toString().padLeft(2, '0')}.${doctor.dateOfBirth.year}",
              ),
              _buildInfoTile(
                icon: Icons.wc_outlined,
                label: 'Gender',
                value: doctor.gender.name.capitalizeFirst ?? 'Not specified',
              ),
              _buildInfoTile(
                icon: Icons.fingerprint,
                label: 'License / Doctor ID',
                value: doctor.id,
              ),

              const SizedBox(height: 25),

              // --- 3. Practice Details ---
              const _SectionHeader(title: 'My Practice'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.local_hospital, color: Colors.blue),
                  title: Text(practice.name),
                  subtitle: Text('Practice ID: ${practice.id}'),
                ),
              ),

              const SizedBox(height: 25),

              // --- 4. Colleagues List ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const _SectionHeader(title: 'Colleagues'),
                  Chip(
                    label: Text('${controller.colleagues.length}'),
                    backgroundColor: Colors.blue.shade50,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (controller.colleagues.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No colleagues found in this practice.'),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.colleagues.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Doctor colleague = controller.colleagues[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person, size: 20),
                        ),
                        title: Text(colleague.name),
                        subtitle: Text(colleague.email),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 40),

              // --- 5. Logout ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => controller.authService.signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    elevation: 0,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: Colors.blue.shade600),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  softWrap: true, // Allows the text to move to the next line
                  overflow: TextOverflow
                      .visible, // Or use TextOverflow.ellipsis to cut it off
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
