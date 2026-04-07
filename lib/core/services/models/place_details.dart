class PlaceDetails {
  final String placeId;
  final String formattedAddress;
  final double lat;
  final double lng;

  const PlaceDetails({
    required this.placeId,
    required this.formattedAddress,
    required this.lat,
    required this.lng,
  });
}
