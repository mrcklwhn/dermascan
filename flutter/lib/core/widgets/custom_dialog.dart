import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:dermascan/core/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomDialogHelper {
  static const String defaultRouteName = 'custom-dialog';

  static Future<T?> show<T>({
    required String title,
    required String subtitle,
    required String submitText,
    bool hasTextField = false,
    bool isDismissable = true,
    Future<void> Function(String text)? onSubmit,
    String routeName = defaultRouteName,
    String textFieldLabel = 'Input',
  }) async {
    final TextEditingController textController = TextEditingController();
    final FocusNode focusNode = FocusNode();

    bool isSubmitted = false;

    Future<void> submit() async {
      if (isSubmitted) return;

      final String enteredText = textController.text.trim();

      if (hasTextField && enteredText.isEmpty) {
        if (Get.isSnackbarOpen) {
          await Get.closeCurrentSnackbar();
        }
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: 'Missing Information',
              message: 'Please fill in all required fields.',
            ),
          );
        }
        return;
      }

      isSubmitted = true;

      if (Get.isSnackbarOpen) {
        await Get.closeCurrentSnackbar();
      }

      hide(routeName: routeName);
      await onSubmit?.call(enteredText);
    }

    final T? result = await Get.dialog<T>(
      PopScope(
        canPop: isDismissable,
        child: Dialog(
          backgroundColor: AppTheme.highlightColor,
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Center(
                  child: Text(
                    title,
                    style: Theme.of(Get.context!).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                Text(
                  subtitle,
                  style: Theme.of(Get.context!).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                if (hasTextField && Get.context != null) ...<Widget>[
                  const SizedBox(height: AppTheme.spaceMedium),
                  CustomTextField(
                    textEditingController: textController,
                    labelText: textFieldLabel,
                    focusNode: focusNode,
                    onSubmitted: (String _) async => submit(),
                    prefixIcon: Icons.edit_note,
                    textInputType: TextInputType.text,
                    backgroundColor: Theme.of(
                      Get.context!,
                    ).scaffoldBackgroundColor,
                  ),
                ],
                const SizedBox(height: AppTheme.spaceMedium),
                Row(
                  children: <Widget>[
                    if (isDismissable) ...<Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => hide(routeName: routeName),
                          child: const Text('Dismiss'),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceMedium),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async => submit(),
                        child: Text(submitText),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: isDismissable,
      routeSettings: RouteSettings(name: routeName),
    );
    textController.dispose();
    focusNode.dispose();

    return result;
  }

  static void hide({String routeName = defaultRouteName}) {
    final BuildContext? context = Get.context;
    if (context == null) return;

    Navigator.of(context).popUntil((Route<dynamic> route) {
      if (route.settings.name == routeName) {
        Navigator.of(context).pop();
        return true;
      }
      return true;
    });
  }
}
