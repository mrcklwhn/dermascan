import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/models/invitation.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/features/doctor/init/controller/invitations_controller.dart';
import 'package:dermascan/translations/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class InvitationsScreen extends GetView<InvitationsController> {
  const InvitationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(TrKeys.practice.pendingInvitations.tr)),
      body: SafeArea(
        child: Obx(() {
          if (controller.isInitializing.value) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (controller.pendingInvitations.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildInvitationList(context);
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
          const CustomIcon(iconData: Icons.mark_email_read),
          const SizedBox(height: AppTheme.spaceLarge),
          Text(
            TrKeys.practice.noPendingInvitations.tr,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            TrKeys.practice.noOpenInvitationsMsg.tr,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 2),
          Obx(
            () => FilledButton.icon(
              icon: const Icon(Icons.refresh),
              onPressed: controller.reloadInvitations,
              label: Text(TrKeys.common.refresh.tr),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationList(BuildContext context) {
    return Padding(
      padding: AppTheme.scaffoldPadding.copyWith(top: 0, bottom: 0),
      child: Column(
        children: <Widget>[
          SearchBar(
            hintText: TrKeys.common.search.tr,
            controller: controller.searchBarController,
            leading: const Icon(Icons.search),
            trailing: <Widget>[
              IconButton(
                onPressed: controller.clearSearchBar,
                icon: const Icon(Icons.clear),
              ),
            ],
            onChanged: (String value) =>
                controller.filterPractices(query: value),
            focusNode: controller.searchBarFocusNode,
            onTapOutside: (_) => controller.unfocusSearchBar(),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Expanded(
            child: ListView.builder(
              controller: controller.listScrollController,
              scrollDirection: Axis.vertical,
              itemCount: controller.visiblePendingInvitations.length,
              itemBuilder: (BuildContext context, int index) {
                final PracticeInvitation invitation =
                    controller.visiblePendingInvitations[index];
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Card(
                      child: ListTile(
                        title: Text(invitation.practice.name),
                        leading: const Icon(Icons.local_hospital),
                        trailing: const Icon(Icons.arrow_forward),
                        subtitle: Text(
                          '${TrKeys.practice.invitedOn.tr} ${DateFormat('dd.MM.yyyy').format(invitation.createdAt)}',
                        ),
                        onTap: () => controller.showPracticeJoinDialog(
                                practiceId: invitation.practice.id,
                              ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceSmall),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
