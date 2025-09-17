class Album {
  final String title;
  final String thumb;

  Album({required this.title, required this.thumb});

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      title: json['title'],
      thumb: json['thumb'] ?? '',
    );
  }
}
