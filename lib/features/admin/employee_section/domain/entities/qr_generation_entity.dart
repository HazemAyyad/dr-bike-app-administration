class QrGenerationEntity {
  final String codeText;
  final String qrImageUrl;
  final DateTime? createdAt;

  const QrGenerationEntity({
    required this.codeText,
    required this.qrImageUrl,
    this.createdAt,
  });
}
