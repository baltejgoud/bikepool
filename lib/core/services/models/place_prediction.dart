class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  const PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final structured = json['structuredFormatting'] as Map<String, dynamic>?;
    return PlacePrediction(
      placeId: json['place_id'] ?? json['placeId'] ?? '',
      description: json['description'] ?? '',
      mainText: structured?['mainText'] ??
          structured?['main_text'] ??
          json['description'] ??
          '',
      secondaryText: structured?['secondaryText'] ??
          structured?['secondary_text'] ??
          '',
    );
  }
}
