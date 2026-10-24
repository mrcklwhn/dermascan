class Country {
  final String name;
  final String isoCode;

  Country({required this.name, required this.isoCode});
}

final List<Country> countries = <Country>[
  // Tier 1: Priority corridor (DACH, Western Europe, transit to Romania, key demographics)
  Country(name: 'Germany', isoCode: 'DE'),
  Country(name: 'Austria', isoCode: 'AT'),
  Country(name: 'Switzerland', isoCode: 'CH'),
  Country(name: 'Romania', isoCode: 'RO'),
  Country(name: 'France', isoCode: 'FR'),
  Country(name: 'Netherlands', isoCode: 'NL'),
  Country(name: 'Belgium', isoCode: 'BE'),
  Country(name: 'Luxembourg', isoCode: 'LU'),
  Country(name: 'Hungary', isoCode: 'HU'),
  Country(name: 'Poland', isoCode: 'PL'),
  Country(name: 'Czechia', isoCode: 'CZ'),
  Country(name: 'Slovakia', isoCode: 'SK'),
  Country(name: 'Italy', isoCode: 'IT'),
  Country(name: 'Spain', isoCode: 'ES'),
  Country(name: 'Portugal', isoCode: 'PT'),
  Country(name: 'United Kingdom', isoCode: 'GB'),
  Country(name: 'Türkiye', isoCode: 'TR'),
  Country(name: 'Ukraine', isoCode: 'UA'),

  // Tier 2: Remaining European countries (alphabetical)
  Country(name: 'Albania', isoCode: 'AL'),
  Country(name: 'Andorra', isoCode: 'AD'),
  Country(name: 'Belarus', isoCode: 'BY'),
  Country(name: 'Bosnia and Herzegovina', isoCode: 'BA'),
  Country(name: 'Bulgaria', isoCode: 'BG'),
  Country(name: 'Croatia', isoCode: 'HR'),
  Country(name: 'Cyprus', isoCode: 'CY'),
  Country(name: 'Denmark', isoCode: 'DK'),
  Country(name: 'Estonia', isoCode: 'EE'),
  Country(name: 'Finland', isoCode: 'FI'),
  Country(name: 'Greece', isoCode: 'GR'),
  Country(name: 'Holy See', isoCode: 'VA'),
  Country(name: 'Iceland', isoCode: 'IS'),
  Country(name: 'Ireland', isoCode: 'IE'),
  Country(name: 'Kosovo', isoCode: 'XK'),
  Country(name: 'Latvia', isoCode: 'LV'),
  Country(name: 'Liechtenstein', isoCode: 'LI'),
  Country(name: 'Lithuania', isoCode: 'LT'),
  Country(name: 'Malta', isoCode: 'MT'),
  Country(name: 'Moldova', isoCode: 'MD'),
  Country(name: 'Monaco', isoCode: 'MC'),
  Country(name: 'Montenegro', isoCode: 'ME'),
  Country(name: 'North Macedonia', isoCode: 'MK'),
  Country(name: 'Norway', isoCode: 'NO'),
  Country(name: 'San Marino', isoCode: 'SM'),
  Country(name: 'Serbia', isoCode: 'RS'),
  Country(name: 'Slovenia', isoCode: 'SI'),
  Country(name: 'Sweden', isoCode: 'SE'),

  // Tier 3: Aggregated non-European regions (using ISO 3166-1 private-use 'X*' codes)
  Country(name: 'North America (US, CA)', isoCode: 'XN'),
  Country(name: 'Central & South America', isoCode: 'XL'),
  Country(name: 'Middle East & North Africa', isoCode: 'XM'),
  Country(name: 'Sub-Saharan Africa', isoCode: 'XA'),
  Country(name: 'Asia & Pacific', isoCode: 'XS'),
  Country(name: 'Australia & Oceania', isoCode: 'XO'),
  Country(name: 'Other / Non-European', isoCode: 'XX'),
];
