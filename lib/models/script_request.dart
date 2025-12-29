class ScriptRequest {
  final String story;
  final String styleId;
  final List<String> nuances;

  ScriptRequest({
    required this.story,
    this.styleId = 'modern_clean',
    this.nuances = const ['adventure'],
  });

  Map<String, dynamic> toJson() {
    return {
      'story': story,
      'style_id': styleId,
      'nuances': nuances,
    };
  }
}
