import 'package:dermascan/core/models/doctor.dart';
import 'package:dermascan/core/widgets/doctor_list_tile.dart';
import 'package:dermascan/features/practice/doctors/controller/pending_invitations_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PendingInvitationsScreen extends StatelessWidget {
  PendingInvitationsScreen({super.key});

  final PendingInvitationsController pendingInvitationsController =
      Get.find<PendingInvitationsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Pending Invitations',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Obx(() {
          if (pendingInvitationsController.isInitializing.value) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (pendingInvitationsController.pendingInvitations.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildListState(context);
        }),
      ),
    );
  }

  // Consistent empty state matching DoctorInitScreen style
  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Spacer(),

          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_read_outlined,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'No Pending Invitations',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'There are currently no open invitations.\nNew requests will appear here automatically.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(),
          // Optional: Add a refresh button here if needed by logic
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  // Clean list layout with consistent padding
  Widget _buildListState(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      itemCount: pendingInvitationsController.pendingInvitations.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 16),
      itemBuilder: (BuildContext context, int index) {
        final Doctor doctor =
            pendingInvitationsController.pendingInvitations[index];
        return DoctorListTile(
          doctor: doctor,
          onPressed: () => pendingInvitationsController.showDoctorProfile(
            doctorId: doctor.id,
          ),
        );
      },
    );
  }
}
