class ProofMediaType {
  static const none = 'none';
  static const image = 'image';
  static const video = 'video';
  static const both = 'both';

  static const values = [none, image, video, both];

  static String normalize(String? value, {bool required = false}) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (!required) return none;
    if (normalized == image || normalized == video || normalized == both) {
      return normalized;
    }
    return both;
  }

  static bool isRequired(String value) =>
      normalize(value, required: true) != none;
}
