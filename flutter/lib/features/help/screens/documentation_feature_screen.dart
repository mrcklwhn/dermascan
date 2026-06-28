import 'package:dermascan/features/help/controller/documentation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:get/get.dart';

class DocumentationFeatureScreen extends GetView<DocumentationController> {
  const DocumentationFeatureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DocumentationFeature feature = Get.arguments as DocumentationFeature;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Markdown(
          data: feature.content,
          onTapLink: controller.onTapLink,
          imageDirectory: 'assets/documentation/',
          imageBuilder: controller.buildMarkdownImage,
        ),
      ),
    );
  }
}
