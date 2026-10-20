class Album {
  final String title;
  final String image;
  final List<String> genres;

  Album({required this.title, required this.image, required this.genres});

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      title: json['title'] ?? 'Sem título',
      image: json['cover_image'] ?? json['thumb'] ?? '',
      genres: List<String>.from(json['genre'] ?? []),
    );
  }
}
