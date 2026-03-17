import 'package:dermascan/features/doctor/practice/controller/practice_details_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PracticeDetailsScreen extends StatelessWidget {
  PracticeDetailsScreen({super.key});

  final PracticeDetailsController practiceDetailsController =
      Get.find<PracticeDetailsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Obx(() {
          return Text(
            practiceDetailsController.isPracticeOfCurrentDoctor.value
                ? 'Doctor Profile'
                : 'Add Doctor',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          );
        }),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 24),

              // Profile Header (Avatar + Key Info)
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
                    Icons.person,
                    size: 60,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                practiceDetailsController.practice.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                practiceDetailsController.practice.email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Action Buttons area
              Obx(() {
                if (!practiceDetailsController
                    .isPracticeOfCurrentDoctor
                    .value) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: practiceDetailsController.isLoading.value
                            ? null
                            : () => practiceDetailsController
                                  .acceptPracticeInvitation(
                                    practiceId:
                                        practiceDetailsController.practice.id,
                                  ),
                        icon: const Icon(Icons.group_add_outlined),
                        label: const Text('Accept Invitation'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }
}
