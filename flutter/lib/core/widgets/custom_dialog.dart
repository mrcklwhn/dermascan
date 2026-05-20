import 'package:dermascan/app/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomDialogHelper {
  static const String defaultRouteName = 'custom-dialog';

  static Future<T?> show<T>({
    required String title,
    required String subtitle,
    required String submitText,
    bool isDismissable = true,
    Future<void> Function()? onSubmit,
    String routeName = defaultRouteName,
  }) async {
    return await Get.dialog<T>(
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
                        onPressed: () async {
                          if (Get.isSnackbarOpen) {
                            await Get.closeCurrentSnackbar();
                          }

                          hide(routeName: routeName);

                          await onSubmit?.call();
                        },
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
  }

  static void hide({String routeName = defaultRouteName}) {
    final BuildContext? context = Get.context;

    if (context == null) {
      return;
    }

    Navigator.of(context).popUntil((Route<dynamic> route) {
      if (route.settings.name == routeName) {
        Navigator.of(context).pop();
        return true;
      }

      return true;
    });
  }
}
