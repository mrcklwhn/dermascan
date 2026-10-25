import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/models/check_criteria.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomTextFieldController extends GetxController {
  final RxBool isObscure = true.obs;

  void togglePasswordObscurity() {
    isObscure.value = !isObscure.value;
  }
}

class CustomTextField extends StatelessWidget {
  final TextEditingController textEditingController;
  final IconData prefixIcon;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;
  final String labelText;
  final TextInputType textInputType;
  final List<CheckCriteria>? checkCriteria;
  final Color? backgroundColor;
  final int? maxLines;
  final int? minLines;

  const CustomTextField({
    super.key,
    required this.textEditingController,
    required this.focusNode,
    required this.onSubmitted,
    required this.labelText,
    required this.prefixIcon,
    required this.textInputType,
    this.checkCriteria,
    this.backgroundColor,
    this.maxLines = 1,
    this.minLines,
  });

  @override
  Widget build(BuildContext context) {
    final CustomTextFieldController controller = Get.put(
      CustomTextFieldController(),
      tag: textEditingController.hashCode.toString(),
    );

    final bool isPasswordField = textInputType == TextInputType.visiblePassword;

    final OutlineInputBorder noBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      borderSide: BorderSide.none,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Obx(() {
          final bool isCurrentlyObscure = controller.isObscure.value;

          return TextField(
            obscureText: isPasswordField && isCurrentlyObscure,
            autocorrect: false,
            controller: textEditingController,
            focusNode: focusNode,
            keyboardType: textInputType,
            maxLines: maxLines,
            minLines: minLines,
            onSubmitted: onSubmitted,
            onTapOutside: (_) => focusNode.unfocus(),
            decoration: InputDecoration(
              filled: true,
              fillColor: backgroundColor,
              border: noBorder,
              enabledBorder: noBorder,
              focusedBorder: noBorder,
              labelText: labelText,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(
                  left: AppTheme.spaceMedium,
                  right: AppTheme.spaceSmall + 4.0,
                ),
                child: Icon(prefixIcon),
              ),
              suffixIcon: isPasswordField
                  ? Padding(
                      padding: const EdgeInsets.only(
                        right: AppTheme.spaceSmall,
                      ),
                      child: IconButton(
                        onPressed: controller.togglePasswordObscurity,
                        icon: Icon(
                          isCurrentlyObscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    )
                  : null,
            ),
          );
        }),
        if (checkCriteria != null)
          ...checkCriteria?.map(
            (CheckCriteria criteria) => _buildCriteriaRow(context, criteria),
          ) ?? <Widget>[],
      ],
    );
  }

  Widget _buildCriteriaRow(BuildContext context, CheckCriteria checkCriteria) {
    return Obx(() {
      final bool isValid = checkCriteria.criteriaState.value;

      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceSmall,
          vertical: AppTheme.spaceSmall / 2,
        ),
        child: Row(
          children: <Widget>[
            Icon(
              isValid ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: isValid ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
              size: 16,
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            Expanded(child: Text(checkCriteria.criteriaName)),
          ],
        ),
      );
    });
  }
}
