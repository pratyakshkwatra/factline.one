class GameQuery {
  final String country;

  GameQuery({
    required this.country,
  });

  Map<String, dynamic> toJson() {
    return {
      'country': country,
    };
  }

  factory GameQuery.fromJson(Map<String, dynamic> json) {
    return GameQuery(
      country: json['country'],
    );
  }
}

class GameArticle {
  final String title;
  final String body;
  final bool isFake;
  final String sourceUrl;

  GameArticle({
    required this.title,
    required this.body,
    required this.isFake,
    required this.sourceUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'is_fake': isFake,
      'source_url': sourceUrl,
    };
  }

  factory GameArticle.fromJson(Map<String, dynamic> json) {
    return GameArticle(
      title: json['title'],
      body: json['body'],
      isFake: json['is_fake'],
      sourceUrl: json['source_url'],
    );
  }
}
