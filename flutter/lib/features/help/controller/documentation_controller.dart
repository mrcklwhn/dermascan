import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';

class DocumentationFeature {
  final String title;
  final String content;

  DocumentationFeature({required this.title, required this.content});
}

class DocumentationController extends GetxController {
  final RxList<DocumentationFeature> features = <DocumentationFeature>[].obs;
  String intro = '';
  RxBool isInitializing = true.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_initializeData());
  }

  Future<void> _initializeData() async {
    try {
      await loadMarkdownFile();
    } catch (e) {
      debugPrint('Error while loading markdown data: $e');
    } finally {
      isInitializing.value = false;
    }
  }

  Future<void> loadMarkdownFile() async {
    final String languageCode = Get.locale?.languageCode ?? 'en';
    String fileName = 'features_en.md';
    
    if (languageCode == 'de') {
      fileName = 'features_de.md';
    } else if (languageCode == 'ro') {
      fileName = 'features_ro.md';
    }

    try {
      final String fullMarkdown = await rootBundle.loadString('assets/documentation/$fileName');
      _parseMarkdown(fullMarkdown);
    } catch (e) {
      debugPrint('Error loading markdown file $fileName, falling back to English: $e');
      final String fallbackMarkdown = await rootBundle.loadString('assets/documentation/features_en.md');
      _parseMarkdown(fallbackMarkdown);
    }
  }

  void _parseMarkdown(String fullMarkdown) {
    features.clear();
    final List<String> sections = fullMarkdown.split(RegExp(r'\n(?=## )'));

    if (sections.isNotEmpty) {
      intro = sections[0].trim();

      for (int i = 1; i < sections.length; i++) {
        final String section = sections[i].trim();
        if (section.isEmpty) continue;

        final List<String> lines = section.split('\n');
        if (lines.isNotEmpty) {
          final String title = lines[0].replaceFirst('## ', '').trim();
          String content = lines.join('\n').trim();

          // Promote headers by removing one '#' (### -> ##, etc.)
          content = content.replaceAllMapped(RegExp('^(#+)', multiLine: true), (Match match) {
            final String hashes = match.group(1)!;
            return hashes.length > 1 ? hashes.substring(1) : hashes;
          });

          features.add(DocumentationFeature(title: title, content: content));
        }
      }
    }
  }

  void onTapLink(String text, String? href, String title) {
    debugPrint('Clicked Link: $href');
  }

  void openFeatureDetail(DocumentationFeature feature) {
    Get.toNamed('/help/documentation/detail', arguments: feature);
  }

  Widget buildMarkdownImage(Uri uri, String? title, String? alt) {
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return Image.network(uri.toString());
    }

    if (uri.scheme == 'resource') {
      return Image.asset(uri.path);
    }

    // Relative markdown image paths should resolve to bundled assets.
    final String relativePath = uri.toString();
    final String assetPath = relativePath.startsWith('assets/')
        ? relativePath
        : 'assets/documentation/$relativePath';

    return Image.asset(assetPath);
  }
}
