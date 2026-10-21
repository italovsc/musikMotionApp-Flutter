class AlbumDetails {
  final int masterId;
  final String title;
  final List<AlbumArtist> artists;
  final int? year;
  final List<String> genres;
  final List<String> styles;
  final String? imageUrl;
  final List<AlbumTrack> tracklist;
  final int? mainReleaseId;
  final AlbumRating? rating;

  AlbumDetails({
    required this.masterId,
    required this.title,
    required this.artists,
    this.year,
    required this.genres,
    required this.styles,
    this.imageUrl,
    required this.tracklist,
    this.mainReleaseId,
    this.rating,
  });

  factory AlbumDetails.fromJson(
    Map<String, dynamic> json, {
    AlbumRating? rating,
  }) {
    final id = _positiveInt(json['id']);
    if (id == null) throw const FormatException('Master sem ID válido');
    final images = _objects(json['images']);
    String? imageUrl;
    for (final image in images) {
      final uri = _nonEmptyString(image['uri']);
      if (uri == null) continue;
      imageUrl ??= uri;
      if (image['type'] == 'primary') {
        imageUrl = uri;
        break;
      }
    }
    return AlbumDetails(
      masterId: id,
      title: _nonEmptyString(json['title']) ?? 'Sem título',
      artists: _objects(json['artists']).map(AlbumArtist.fromJson).toList(),
      year: _positiveInt(json['year']),
      genres: _strings(json['genres']),
      styles: _strings(json['styles']),
      imageUrl: imageUrl,
      tracklist: _objects(json['tracklist']).map(AlbumTrack.fromJson).toList(),
      mainReleaseId: _positiveInt(json['main_release']),
      rating: rating,
    );
  }
}

class AlbumArtist {
  final String name;
  final String? join;

  AlbumArtist({required this.name, this.join});

  factory AlbumArtist.fromJson(Map<String, dynamic> json) => AlbumArtist(
    name: _nonEmptyString(json['name']) ?? '',
    join: _nonEmptyString(json['join']),
  );
}

class AlbumTrack {
  final String position;
  final String title;
  final String? duration;
  final String type;

  AlbumTrack({
    required this.position,
    required this.title,
    this.duration,
    required this.type,
  });

  factory AlbumTrack.fromJson(Map<String, dynamic> json) => AlbumTrack(
    position: _nonEmptyString(json['position']) ?? '',
    title: _nonEmptyString(json['title']) ?? '',
    duration: _nonEmptyString(json['duration']),
    type: _nonEmptyString(json['type_']) ?? '',
  );
}

class AlbumRating {
  final int releaseId;
  final double average;
  final int count;

  AlbumRating({
    required this.releaseId,
    required this.average,
    required this.count,
  });

  factory AlbumRating.fromJson(Map<String, dynamic> json) {
    final releaseId = _positiveInt(json['release_id']);
    final rating = json['rating'];
    final average = rating is Map ? rating['average'] : null;
    final count = rating is Map ? rating['count'] : null;
    if (releaseId == null ||
        average is! num ||
        !average.isFinite ||
        count is! int ||
        count < 0) {
      throw const FormatException('Avaliação inválida');
    }
    return AlbumRating(
      releaseId: releaseId,
      average: average.toDouble(),
      count: count,
    );
  }
}

int? _positiveInt(dynamic value) => value is int && value > 0 ? value : null;

String? _nonEmptyString(dynamic value) =>
    value is String && value.trim().isNotEmpty ? value : null;

List<String> _strings(dynamic value) =>
    value is List ? value.whereType<String>().toList() : [];

Iterable<Map<String, dynamic>> _objects(dynamic value) =>
    value is List ? value.whereType<Map<String, dynamic>>() : [];
