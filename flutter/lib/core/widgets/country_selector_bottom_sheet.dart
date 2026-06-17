import 'dart:async';

import 'package:circle_flags/circle_flags.dart';
import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/models/country.dart';
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
        allCountries.map((Country country) => country.isoCode).toList(),
      ),
    );
    filteredCountries.assignAll(allCountries);
    super.onInit();
  }

  @override
  void onClose() {
    searchBarController.dispose();
    super.onClose();
  }

  void filterCountries({required String query}) {
    filteredCountries.assignAll(
      allCountries
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
      decoration: const BoxDecoration(
        color: AppTheme.highlightColor,
        borderRadius: BorderRadius.vertical(
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
            hintText: 'Search ...',
            controller: controller.searchBarController,
            leading: const Icon(Icons.search),
            backgroundColor: WidgetStateProperty.all(AppTheme.scaffoldBg),
            trailing: <Widget>[
              IconButton(
                onPressed: controller.clearSearchBar,
                icon: const Icon(Icons.clear),
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
                        color: AppTheme.scaffoldBg,
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
