class DailymotionResponse {
  DailymotionResponse({
    required this.thumbnails,
    required this.qualities,
  });

  final Map<String, String> thumbnails;
  final Qualities? qualities;

  factory DailymotionResponse.fromJson(Map<String, dynamic> json){
    return DailymotionResponse(
      thumbnails: Map.from(json["thumbnails"]).map((k, v) => MapEntry<String, String>(k, v)),
      qualities: json["qualities"] == null ? null : Qualities.fromJson(json["qualities"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "thumbnails": Map.from(thumbnails).map((k, v) => MapEntry<String, dynamic>(k, v)),
    "qualities": qualities?.toJson(),
  };

}

class Qualities {
  Qualities({
    required this.auto,
  });

  final List<Auto> auto;

  factory Qualities.fromJson(Map<String, dynamic> json){
    return Qualities(
      auto: json["auto"] == null ? [] : List<Auto>.from(json["auto"]!.map((x) => Auto.fromJson(x))),
    );
  }

  Map<String, dynamic> toJson() => {
    "auto": auto.map((x) => x.toJson()).toList(),
  };

}

class Auto {
  Auto({
    required this.type,
    required this.url,
  });

  final String type;
  final String url;

  factory Auto.fromJson(Map<String, dynamic> json){
    return Auto(
      type: json["type"] ?? "",
      url: json["url"] ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
    "type": type,
    "url": url,
  };

}
