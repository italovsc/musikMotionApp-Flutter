/// Splits the display text only; the original model title stays unchanged.
({String? artist, String title}) albumPresentation(String fullTitle) {
  final separator = fullTitle.indexOf(' - ');
  if (separator < 0) return (artist: null, title: fullTitle);
  return (
    artist: fullTitle.substring(0, separator),
    title: fullTitle.substring(separator + 3),
  );
}
