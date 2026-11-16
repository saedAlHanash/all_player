enum AllPlayerStatus {
  loading,
  playing,
  paused,
  error,
}

typedef AllVideoState = AllPlayerStatus;

const videoThumpBuketName = 'vimeoImages';

enum AllPlayerType {
  network,
  networkQualityUrls,
  file,
  asset,
  vimeo,
  youtube,
  youtubeIframe,
  dailymotion,
  vimeoPrivateVideos,
}

typedef AllVideoPlayerType = AllPlayerType;

enum VideoPlatform {
  youtube,
  dailymotion,
  vimeo,
  network,
  unknown,
  ;

  bool get isYoutube => this == youtube;

  bool get isDailymotion => this == dailymotion;

  bool get isVimeo => this == vimeo;

  bool get isNetwork => this == network;

  bool get isUnknown => this == unknown;
}

enum YoutubePlayMode {
  player,
  iframe,
  ;

  bool get isPlayer => this == player;

  bool get isIframe => this == iframe;
}

extension VideoPlatformDetector on String {
  /// Extracts the 11-character YouTube video ID from a URL or raw ID.
  String? get youtubeVideoId {
    final trimmed = trim();
    if (trimmed.isEmpty) return null;

    // 1. Direct 11-character video ID
    if (RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(trimmed)) {
      return trimmed;
    }

    // 2. Query param ?v= or &v=
    try {
      final uri = Uri.tryParse(trimmed);
      if (uri != null && uri.queryParameters.containsKey('v')) {
        final v = uri.queryParameters['v'];
        if (v != null && RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(v)) {
          return v;
        }
      }
    } catch (_) {}

    // 3. Match patterns like youtu.be/<id>, embed/<id>, shorts/<id>, live/<id>, watch?v=<id>
    final match = RegExp(
      r'(?:youtu\.be\/|youtube(?:-nocookie)?\.com\/(?:watch\?.*&?v=|embed\/|shorts\/|live\/|v\/))([A-Za-z0-9_-]{11})',
      caseSensitive: false,
    ).firstMatch(trimmed);

    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }

    // 4. Fallback search for any 11-char sequence if it looks like a YouTube URL
    if (trimmed.contains('youtube') || trimmed.contains('youtu.be')) {
      final fallback = RegExp(r'([A-Za-z0-9_-]{11})').firstMatch(trimmed);
      if (fallback != null) return fallback.group(1);
    }

    return trimmed;
  }

  /// Extracts the numeric Vimeo video ID from a URL or raw ID.
  String? get vimeoVideoId {
    final trimmed = trim();
    if (trimmed.isEmpty) return null;

    // 1. Pure numeric ID
    if (RegExp(r'^\d+$').hasMatch(trimmed)) {
      return trimmed;
    }

    // 2. Parse URI path segments for numeric segment
    try {
      final uri = Uri.tryParse(trimmed);
      if (uri != null) {
        final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
        for (final seg in segments) {
          if (RegExp(r'^\d+$').hasMatch(seg)) {
            return seg;
          }
        }
      }
    } catch (_) {}

    // 3. Regex matching
    final match = RegExp(r'vimeo(?:\.com)?\/(?:.*\/)?(\d+)', caseSensitive: false).firstMatch(trimmed);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }

    return trimmed;
  }

  /// Extracts privacy hash from a Vimeo URL if available (e.g. vimeo.com/12345/abcdef or ?h=abcdef).
  String? get vimeoVideoHash {
    final trimmed = trim();
    if (trimmed.isEmpty) return null;

    try {
      final uri = Uri.tryParse(trimmed);
      if (uri != null) {
        if (uri.queryParameters.containsKey('h')) {
          return uri.queryParameters['h'];
        }
        final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
        final idIndex = segments.indexWhere((s) => RegExp(r'^\d+$').hasMatch(s));
        if (idIndex != -1 && idIndex + 1 < segments.length) {
          final nextSeg = segments[idIndex + 1];
          if (RegExp(r'^[a-zA-Z0-9]+$').hasMatch(nextSeg)) {
            return nextSeg;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Extracts Dailymotion video ID from a URL or raw ID.
  String? get dailymotionVideoId {
    final trimmed = trim();
    if (trimmed.isEmpty) return null;

    // 1. Pure ID (alphanumeric, no slashes or query)
    if (RegExp(r'^[a-zA-Z0-9]{5,20}$').hasMatch(trimmed) && !trimmed.contains('/')) {
      return trimmed;
    }

    // 2. Parse URI
    try {
      final uri = Uri.tryParse(trimmed);
      if (uri != null) {
        final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
        if (uri.host.contains('dai.ly') && segments.isNotEmpty) {
          return segments.first;
        }
        final videoIndex = segments.indexOf('video');
        if (videoIndex != -1 && videoIndex + 1 < segments.length) {
          return segments[videoIndex + 1];
        }
        if (segments.isNotEmpty && RegExp(r'^[a-zA-Z0-9]{5,20}$').hasMatch(segments.last)) {
          return segments.last;
        }
      }
    } catch (_) {}

    // 3. Regex matching
    final match = RegExp(
      r'(?:dailymotion\.com\/(?:video|embed\/video|hub)\/|dai\.ly\/)([a-zA-Z0-9]+)',
      caseSensitive: false,
    ).firstMatch(trimmed);

    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }

    return trimmed;
  }

  /// Automatically detects the platform and safely extracts the video ID.
  /// If unknown or direct network URL, returns the original string.
  String? get getVideoId {
    final platform = detectVideoPlatform;
    switch (platform) {
      case VideoPlatform.youtube:
        return youtubeVideoId;
      case VideoPlatform.vimeo:
        return vimeoVideoId;
      case VideoPlatform.dailymotion:
        return dailymotionVideoId;
      case VideoPlatform.network:
      case VideoPlatform.unknown:
        return this;
    }
  }

  VideoPlatform get detectVideoPlatform {
    final trimmed = trim();
    if (trimmed.isEmpty) return VideoPlatform.unknown;

    final lower = trimmed.toLowerCase();

    // 1. Domain names matching
    if (lower.contains('youtube.com') || lower.contains('youtu.be') || lower.contains('youtube-nocookie.com')) {
      return VideoPlatform.youtube;
    }
    if (lower.contains('vimeo.com')) {
      return VideoPlatform.vimeo;
    }
    if (lower.contains('dailymotion.com') || lower.contains('dai.ly')) {
      return VideoPlatform.dailymotion;
    }

    // 2. Direct video file extensions
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      if (lower.contains('.mp4') ||
          lower.contains('.m3u8') ||
          lower.contains('.mpd') ||
          lower.contains('.webm') ||
          lower.contains('.mov')) {
        return VideoPlatform.network;
      }
    }

    // 3. ID Patterns
    // Vimeo IDs are numeric
    if (int.tryParse(trimmed) != null) {
      return VideoPlatform.vimeo;
    }

    // YouTube 11-character video ID
    const youtubePattern = r'^[A-Za-z0-9_-]{11}$';
    if (RegExp(youtubePattern).hasMatch(trimmed)) {
      return VideoPlatform.youtube;
    }

    // Dailymotion alphanumeric video ID
    const dailymotionPattern = r'^[A-Za-z0-9]{6,20}$';
    if (RegExp(dailymotionPattern).hasMatch(trimmed)) {
      return VideoPlatform.dailymotion;
    }

    // Any other URL defaults to direct network
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return VideoPlatform.network;
    }

    return VideoPlatform.unknown;
  }
}
