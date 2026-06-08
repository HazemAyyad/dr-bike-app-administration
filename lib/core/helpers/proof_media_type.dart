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

  /// Translation key for a single subtask proof requirement line.
  static String subtaskRequiredHintKey(String? value) {
    switch (normalize(value, required: true)) {
      case image:
        return 'subtaskProofRequiredImage';
      case video:
        return 'subtaskProofRequiredVideo';
      case both:
        return 'subtaskProofRequired';
      default:
        return 'subtaskProofRequired';
    }
  }

  /// Translation key for main-task proof hint (photo / video / either).
  static String mainRequiredHintKey(String? value) {
    switch (normalize(value, required: true)) {
      case image:
        return 'proofRequiredHintImage';
      case video:
        return 'proofRequiredHintVideo';
      case both:
        return 'proofRequiredHintEither';
      default:
        return 'proofRequiredHint';
    }
  }
}
