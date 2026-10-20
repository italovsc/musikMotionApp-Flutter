class Album {
  final String title;
  final String image;
  final List<String> genres;
  final int? masterId;

  Album({
    required this.title,
    required this.image,
    required this.genres,
    this.masterId,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final masterId = json['master_id'];
    return Album(
      title: json['title'] ?? 'Sem título',
      image: json['cover_image'] ?? json['thumb'] ?? '',
      genres: List<String>.from(json['genre'] ?? []),
      masterId:
          json['type'] == 'master' && id is int && id > 0
              ? id
              : masterId is int && masterId > 0
              ? masterId
              : null,
    );
  }
}
