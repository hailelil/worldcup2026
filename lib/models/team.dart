/// A reference to a team as embedded in matches and standings.
///
/// All fields are nullable: knockout matches have TBD slots, and the bundled
/// seed uses placeholder names ("Group A winners") with a null [id].
class TeamRef {
  const TeamRef({this.id, this.name, this.shortName, this.tla, this.crest});

  final int? id;
  final String? name;
  final String? shortName;
  final String? tla;
  final String? crest;

  bool get isPlaceholder => id == null;

  /// Best available display name, or "TBD" for unresolved knockout slots.
  String get displayName => shortName ?? name ?? 'TBD';

  factory TeamRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TeamRef();
    return TeamRef(
      id: json['id'] as int?,
      name: json['name'] as String?,
      shortName: json['shortName'] as String?,
      tla: json['tla'] as String?,
      crest: json['crest'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'shortName': shortName,
        'tla': tla,
        'crest': crest,
      };
}
