import 'dart:async';

import 'package:circle_flags/circle_flags.dart';
import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/models/country.dart';
import 'package:dermascan/translations/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CountrySelectorBottomSheetController extends GetxController {
  RxList<Country> filteredCountries = <Country>[].obs;
  final TextEditingController searchBarController = TextEditingController();
  final FocusNode searchBarFocusNode = FocusNode();

  final ScrollController listScrollController = ScrollController();

  @override
  void onInit() {
    unawaited(
      CircleFlag.preload(
        countries.map((Country country) => country.isoCode).toList(),
      ),
    );
    filteredCountries.assignAll(countries);
    super.onInit();
  }

  @override
  void onClose() {
    searchBarController.dispose();
    searchBarFocusNode.dispose();
    listScrollController.dispose();
    super.onClose();
  }

  void filterCountries({required String query}) {
    filteredCountries.assignAll(
      countries
          .where(
            (Country c) => c.name.toLowerCase().contains(query.toLowerCase()),
          )
          .toList(),
    );
  }

  void unfocusSearchBar() {
    searchBarFocusNode.unfocus();
  }

  void clearSearchBar() {
    searchBarController.clear();
    filterCountries(query: searchBarController.value.text);
  }
}

class CountrySelectorBottomSheet extends StatelessWidget {
  final Function(Country) onCountrySelected;

  const CountrySelectorBottomSheet({
    super.key,
    required this.onCountrySelected,
  });

  @override
  Widget build(BuildContext context) {
    final CountrySelectorBottomSheetController controller = Get.put(
      CountrySelectorBottomSheetController(),
    );

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.85,
      padding: AppTheme.scaffoldPadding.copyWith(top: 0, bottom: 0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      child: Column(
        children: <Widget>[
          Container(
            margin: const EdgeInsets.symmetric(vertical: AppTheme.spaceMedium),
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.onSecondaryFixedVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SearchBar(
            hintText: TrKeys.common.search.tr,
            controller: controller.searchBarController,
            leading: const Icon(Icons.search),
            backgroundColor: WidgetStateProperty.all(Theme.of(context).scaffoldBackgroundColor),
            trailing: <Widget>[
              IconButton(
                onPressed: controller.clearSearchBar,
                icon: const Icon(Icons.clear),
                style: IconButton.styleFrom(backgroundColor: Theme.of(context).scaffoldBackgroundColor),
              ),
            ],
            onChanged: (String value) =>
                controller.filterCountries(query: value),
            focusNode: controller.searchBarFocusNode,
            onTapOutside: (_) => controller.unfocusSearchBar(),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Obx(
            () => Expanded(
              child: ListView.builder(
                controller: controller.listScrollController,
                scrollDirection: Axis.vertical,
                itemCount: controller.filteredCountries.length,
                itemBuilder: (BuildContext context, int index) {
                  final Country country = controller.filteredCountries[index];
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Card(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: ListTile(
                          leading: CircleFlag(country.isoCode, size: 28),
                          title: Text(
                            country.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            onCountrySelected(country);
                            Get.back();
                          },
                        ),
                      ),

                      const SizedBox(height: AppTheme.spaceSmall),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
