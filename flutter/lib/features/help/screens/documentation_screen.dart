import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/features/help/controller/documentation_controller.dart';
import 'package:dermascan/translations/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:get/get.dart';

class DocumentationScreen extends GetView<DocumentationController> {
  const DocumentationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(TrKeys.help.documentation.tr)),
      body: SafeArea(
        child: Obx(() {
          if (controller.isInitializing.value) {
            return const Center(child: CircularProgressIndicator.adaptive());
          } else {
            final bool hasIntro = controller.intro.isNotEmpty;
            final int itemCount = (hasIntro ? 1 : 0) + controller.features.length;

            return ListView.separated(
              padding: AppTheme.scaffoldPadding,
              itemCount: itemCount,
              separatorBuilder: (BuildContext context, int index) => const SizedBox(height: AppTheme.spaceSmall),
              itemBuilder: (BuildContext context, int index) {
                if (hasIntro && index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      MarkdownBody(
                        data: controller.intro,
                        imageDirectory: 'assets/documentation/',
                        imageBuilder: controller.buildMarkdownImage,),
                      const SizedBox(height: AppTheme.spaceMedium),
                    ],
                  );
                }

                final int featureIndex = hasIntro ? index - 1 : index;
                final DocumentationFeature feature = controller.features[featureIndex];

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.description),
                    title: Text(feature.title),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => controller.openFeatureDetail(feature: feature),
                  ),
                );
              },
            );
          }
        }),
      ),
    );
  }
}
