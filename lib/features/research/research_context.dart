class ResearchContext {
  const ResearchContext({required this.label, this.excerpt, this.attachSource});

  final String label;
  final String? excerpt;
  final Future<bool> Function(String sourceId)? attachSource;
}
