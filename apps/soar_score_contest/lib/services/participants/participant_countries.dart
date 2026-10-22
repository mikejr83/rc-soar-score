/// Suggestions for the Country field. The field still accepts any text; the
/// list's spelling is used when the typed text matches it.
const List<String> participantCountries = [
  'Argentina',
  'Australia',
  'Austria',
  'Belgium',
  'Brazil',
  'Canada',
  'Czech Republic',
  'Denmark',
  'Finland',
  'France',
  'Germany',
  'Italy',
  'Japan',
  'Mexico',
  'Netherlands',
  'New Zealand',
  'Norway',
  'Poland',
  'Slovakia',
  'Slovenia',
  'South Africa',
  'Spain',
  'Sweden',
  'Switzerland',
  'Ukraine',
  'United Kingdom',
  'United States',
];

/// [text] in the list's spelling when it matches an entry ignoring case,
/// otherwise [text] unchanged.
String normalizeCountry(String text) {
  final trimmed = text.trim();
  for (final country in participantCountries) {
    if (country.toLowerCase() == trimmed.toLowerCase()) {
      return country;
    }
  }
  return trimmed;
}
