/// A host stadium, loaded from the hand-authored assets/seed/venues.json
/// (the API's venue field is unreliable for WC 2026).
class Venue {
  const Venue({
    required this.name,
    required this.fifaName,
    required this.city,
    required this.country,
    required this.capacity,
  });

  final String name; // common name, e.g. "Estadio Azteca"
  final String fifaName; // FIFA's generic name, e.g. "Mexico City Stadium"
  final String city;
  final String country;
  final int capacity;

  factory Venue.fromJson(Map<String, dynamic> json) => Venue(
        name: json['name'] as String,
        fifaName: json['fifaName'] as String,
        city: json['city'] as String,
        country: json['country'] as String,
        capacity: json['capacity'] as int,
      );
}
