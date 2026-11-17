import 'dart:async';
import 'dart:convert';

import 'package:m_cubit/caching_service/caching_service.dart';

import '../models/vimeo_models.dart';
import '../utils/logger.dart';

/// User choices that are shared by every video (quality, speed, volume).
class AllPlayerPrefs {
  final int? quality;
  final String? speed;
  final double? volume;

  const AllPlayerPrefs({this.quality, this.speed, this.volume});

  AllPlayerPrefs copyWith({int? quality, String? speed, double? volume}) {
    return AllPlayerPrefs(
      quality: quality ?? this.quality,
      speed: speed ?? this.speed,
      volume: volume ?? this.volume,
    );
  }

  Map<String, dynamic> toJson() => {'q': quality, 's': speed, 'v': volume};

  factory AllPlayerPrefs.fromJson(Map<String, dynamic> json) => AllPlayerPrefs(
        quality: json['q'] as int?,
        speed: json['s'] as String?,
        volume: (json['v'] as num?)?.toDouble(),
      );
}

/// Small metadata cache keyed by video id, stored through m_cubit's
/// [CachingService] (Hive). It keeps:
///
/// * stream/quality urls (until they expire),
/// * the thumbnail url,
/// * the last playback position (resume),
/// * global [AllPlayerPrefs].
///
/// Every call is failure-safe: if Hive was not initialised
/// (`CachingService.initial`) the cache silently acts as empty, so playback
/// never depends on it.
class AllPlayerCache {
  AllPlayerCache._();

  static const _bucket = 'all_player_cache';
  static const _prefsKey = '__prefs';

  /// Used when a stream url carries no expiry information.
  static const defaultStreamTtl = Duration(minutes: 30);

  /// A safety margin removed from the expiry encoded in the url.
  static const _expiryMargin = Duration(minutes: 10);

  /// Positions closer than this to the end count as "finished".
  static const _finishedThreshold = Duration(seconds: 5);

  // Serialises read-modify-write cycles so concurrent saves never clobber
  // each other.
  static Future<void> _queue = Future.value();

  //region Streams
  static Future<List<VideoQalityUrls>?> streams(String key) async {
    final map = await _read(key);
    final expiresAt = DateTime.tryParse(map?['exp'] as String? ?? '');
    if (expiresAt == null || !expiresAt.isAfter(DateTime.now())) return null;

    final raw = map?['streams'] as List?;
    if (raw == null || raw.isEmpty) return null;

    return raw
        .map((e) => VideoQalityUrls(quality: e['q'] as int, url: e['u'] as String))
        .toList();
  }

  static Future<void> saveStreams(
    String key,
    List<VideoQalityUrls> urls, {
    Duration ttl = defaultStreamTtl,
  }) {
    if (urls.isEmpty) return Future.value();
    final expiresAt = _expiryFromUrls(urls) ?? DateTime.now().add(ttl);
    return _update(key, (map) {
      map['streams'] = urls.map((e) => {'q': e.quality, 'u': e.url}).toList();
      map['exp'] = expiresAt.toIso8601String();
    });
  }

  /// Reads the `expire` / `exp` query parameter (unix seconds) that YouTube
  /// and several CDNs append to signed urls.
  static DateTime? _expiryFromUrls(List<VideoQalityUrls> urls) {
    DateTime? earliest;
    for (final item in urls) {
      final params = Uri.tryParse(item.url)?.queryParameters;
      final seconds = int.tryParse(params?['expire'] ?? params?['exp'] ?? '');
      if (seconds == null) return null; // unknown for at least one url
      final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000).subtract(_expiryMargin);
      if (earliest == null || date.isBefore(earliest)) earliest = date;
    }
    return earliest;
  }

  //endregion

  //region Thumbnail
  static Future<String?> thumbnail(String key) async {
    return (await _read(key))?['thumb'] as String?;
  }

  static Future<void> saveThumbnail(String key, String? url) {
    if (url == null || url.isEmpty) return Future.value();
    return _update(key, (map) => map['thumb'] = url);
  }

  //endregion

  //region Resume position
  /// Returns the saved position, or `null` when there is nothing worth
  /// resuming (never played / finished).
  static Future<Duration?> position(String key) async {
    final ms = (await _read(key))?['pos'] as int?;
    if (ms == null || ms <= 0) return null;
    return Duration(milliseconds: ms);
  }

  static Future<void> savePosition(String key, Duration position, Duration duration) {
    final finished = duration > Duration.zero && duration - position <= _finishedThreshold;
    return _update(key, (map) => map['pos'] = finished ? 0 : position.inMilliseconds);
  }

  //endregion

  //region Preferences
  static Future<AllPlayerPrefs> prefs() async {
    final map = await _read(_prefsKey);
    return map == null ? const AllPlayerPrefs() : AllPlayerPrefs.fromJson(map);
  }

  static Future<void> savePrefs(AllPlayerPrefs prefs) {
    return _update(_prefsKey, (map) {
      map
        ..clear()
        ..addAll(prefs.toJson());
    });
  }

  //endregion

  static Future<void> remove(String key) async {
    try {
      await CachingService.removeFromBucket(key: key, bucket: _bucket);
    } catch (e) {
      allPlayerLog('cache remove error: $e');
    }
  }

  static Future<void> clear() async {
    try {
      await CachingService.clearBucket(bucket: _bucket);
    } catch (e) {
      allPlayerLog('cache clear error: $e');
    }
  }

  //region Storage
  static Future<Map<String, dynamic>?> _read(String key) async {
    try {
      final raw = await CachingService.getFromBucket(bucket: _bucket, key: key);
      if (raw == null) return null;
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (e) {
      allPlayerLog('cache read error: $e');
      return null;
    }
  }

  static Future<void> _update(String key, void Function(Map<String, dynamic> map) mutate) {
    return _queue = _queue.then((_) async {
      try {
        final map = await _read(key) ?? <String, dynamic>{};
        mutate(map);
        await CachingService.addInBucket(bucket: _bucket, key: key, value: jsonEncode(map));
      } catch (e) {
        allPlayerLog('cache write error: $e');
      }
    });
  }

  //endregion
}
