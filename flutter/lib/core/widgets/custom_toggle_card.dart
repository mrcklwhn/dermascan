import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ToggleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final RxBool value;
  const ToggleCard({
    super.key, 
    required this.title, 
    required this.subtitle, 
    required this.value});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Card(
        child: CheckboxListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          value: value.value,
          onChanged: (bool? val) => value.value = val ?? false,
        ),
      ),
    );
  }
}
