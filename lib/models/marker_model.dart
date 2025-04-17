class MarkerModel {
    final String name;
    final double latitude;
    final double longitude;
    final String detail;
    final String type;

    MarkerModel({
        required this.name,
        required this.latitude,
        required this.longitude,
        required this.detail,
        required this.type,
    });

    factory MarkerModel.fromJson(Map<String, dynamic> json) {
        return MarkerModel(
            name: json['name'],
            latitude: json['latitude'],
            longitude: json['longitude'],
            detail: json['detail'],
            type: json['type'],
        );
    }
}
