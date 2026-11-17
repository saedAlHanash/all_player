import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_partial_cache/video_partial_cache.dart';

import '../cache/all_player_cache.dart';
import '../cache/all_player_video_cache.dart';

/// One cached quality (one cache entry) of a video.
class CachedVideoQuality {
  const CachedVideoQuality({required this.stats, required this.progress});

  final VideoCacheStats stats;
  final VideoCacheProgress progress;

  String get id => stats.videoId;
  int? get quality => AllPlayerVideoCache.qualityOf(id);
}

/// A video with all its cached qualities, plus its title and thumbnail.
class CachedVideo {
  const CachedVideo({
    required this.key,
    required this.qualities,
    this.title,
    this.thumbnail,
  });

  /// `cacheKey` of the video, e.g. `dailymotion:x8abc`.
  final String key;
  final String? title;
  final String? thumbnail;

  /// Sorted by cached bytes, largest first.
  final List<CachedVideoQuality> qualities;

  int get bytes => qualities.fold(0, (n, q) => n + q.stats.cachedBytes);
  bool get pinned => qualities.every((q) => q.stats.pinned);

  /// Best cached share among the qualities, or null if unknown.
  double? get fraction {
    double? best;
    for (final q in qualities) {
      final f = q.progress.fraction ?? q.stats.cachedFraction;
      if (f != null && (best == null || f > best)) best = f;
    }
    return best;
  }

  DateTime? get lastAccess {
    DateTime? last;
    for (final q in qualities) {
      final t = q.stats.lastAccess;
      if (t != null && (last == null || t.isAfter(last))) last = t;
    }
    return last;
  }

  Duration? get duration {
    for (final q in qualities) {
      if (q.progress.duration != null) return q.progress.duration;
    }
    return null;
  }

  /// `youtube`, `vimeo`, `dailymotion`, `url`, ... or null.
  String? get source {
    final i = key.indexOf(':');
    return i <= 0 ? null : key.substring(0, i);
  }

  /// [title], or a readable name made from the key.
  String get displayName {
    if (title != null && title!.isNotEmpty) return title!;
    final s = source;
    if (s == null) return key;
    final id = key.substring(s.length + 1);
    return '${s[0].toUpperCase()}${s.substring(1)} · $id';
  }
}

enum CachedVideoSort { size, recent, name }

class AllPlayerCacheState {
  const AllPlayerCacheState({
    this.loading = true,
    this.enabled = true,
    this.stats,
    this.videos = const [],
    this.sort = CachedVideoSort.size,
    this.error,
  });

  final bool loading;
  final bool enabled;
  final CacheStats? stats;
  final List<CachedVideo> videos;
  final CachedVideoSort sort;
  final Object? error;

  int get usedBytes => stats?.totalBytes ?? 0;
  int get maxBytes => stats?.maxBytes ?? 0;
  int get freeBytes => (maxBytes - usedBytes).clamp(0, maxBytes);
  double get usedFraction => maxBytes == 0 ? 0 : (usedBytes / maxBytes).clamp(0.0, 1.0);

  AllPlayerCacheState copyWith({
    bool? loading,
    bool? enabled,
    CacheStats? stats,
    List<CachedVideo>? videos,
    CachedVideoSort? sort,
    Object? error,
    bool clearError = false,
  }) {
    return AllPlayerCacheState(
      loading: loading ?? this.loading,
      enabled: enabled ?? this.enabled,
      stats: stats ?? this.stats,
      videos: videos ?? this.videos,
      sort: sort ?? this.sort,
      error: clearError ? null : error ?? this.error,
    );
  }
}

/// Reads and controls [AllPlayerVideoCache]. Used by [AllPlayerCacheManager],
/// but can drive a custom UI as well.
class AllPlayerCacheCubit extends Cubit<AllPlayerCacheState> {
  AllPlayerCacheCubit({Duration? refreshInterval}) : super(const AllPlayerCacheState()) {
    unawaited(load());
    if (refreshInterval != null) {
      _timer = Timer.periodic(refreshInterval, (_) => load(silent: true));
    }
  }

  Timer? _timer;
  Future<void>? _current;
  bool _again = false;

  VideoPartialCache? get _cache => AllPlayerVideoCache.isEnabled ? AllPlayerVideoCache.instance : null;

  /// Reloads stats and every video's progress. [silent] keeps the current
  /// list on screen (no loading indicator).
  Future<void> load({bool silent = false}) {
    final running = _current;
    if (running != null) {
      // A load is running; make sure the state after it is fresh too.
      _again = true;
      return running;
    }
    return _current = _load(silent).whenComplete(() => _current = null);
  }

  Future<void> _load(bool silent) async {
    final cache = _cache;
    if (cache == null) {
      _emit(state.copyWith(loading: false, enabled: false));
      return;
    }
    if (!silent) _emit(state.copyWith(loading: true, clearError: true));
    try {
      final stats = await cache.getStats();
      final groups = <String, List<CachedVideoQuality>>{};
      for (final v in stats.videos) {
        if (v.cachedBytes <= 0) continue;
        final progress = await cache.getCacheProgress(v.videoId);
        groups
            .putIfAbsent(AllPlayerVideoCache.baseKeyOf(v.videoId), () => [])
            .add(CachedVideoQuality(stats: v, progress: progress));
      }

      final videos = <CachedVideo>[];
      for (final e in groups.entries) {
        e.value.sort((a, b) => b.stats.cachedBytes.compareTo(a.stats.cachedBytes));
        final key = e.key;
        videos.add(CachedVideo(
          key: key,
          qualities: e.value,
          title: await AllPlayerCache.title(key) ??
              e.value.map((q) => q.stats.title).whereType<String>().firstOrNull,
          thumbnail: await AllPlayerCache.thumbnail(key) ?? _youtubeThumbnail(key),
        ));
      }
      _emit(state.copyWith(
        loading: false,
        enabled: true,
        stats: stats,
        videos: _sorted(videos, state.sort),
        clearError: true,
      ));
    } catch (e) {
      _emit(state.copyWith(loading: false, error: e));
    }
    if (_again && !isClosed) {
      _again = false;
      await _load(true);
    }
  }

  static String? _youtubeThumbnail(String key) =>
      key.startsWith('youtube:') ? 'https://img.youtube.com/vi/${key.substring(8)}/hqdefault.jpg' : null;

  void setSort(CachedVideoSort sort) {
    _emit(state.copyWith(sort: sort, videos: _sorted(state.videos, sort)));
  }

  static List<CachedVideo> _sorted(List<CachedVideo> videos, CachedVideoSort sort) {
    final list = List<CachedVideo>.from(videos);
    switch (sort) {
      case CachedVideoSort.size:
        list.sort((a, b) => b.bytes.compareTo(a.bytes));
      case CachedVideoSort.recent:
        final zero = DateTime.fromMillisecondsSinceEpoch(0);
        list.sort((a, b) => (b.lastAccess ?? zero).compareTo(a.lastAccess ?? zero));
      case CachedVideoSort.name:
        list.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    }
    return list;
  }

  /// Pinned videos are never removed automatically.
  Future<void> setPinned(CachedVideo video, bool pinned) => _run((c) async {
        for (final q in video.qualities) {
          await c.setPinned(q.id, pinned);
        }
      });

  /// Deletes every cached quality of [video].
  Future<void> deleteVideo(CachedVideo video) => _run((c) async {
        for (final q in video.qualities) {
          await c.clearVideo(q.id);
        }
      });

  /// Deletes one cached quality.
  Future<void> deleteQuality(CachedVideoQuality quality) => _run((c) => c.clearVideo(quality.id));

  Future<void> clearAll() => _run((c) => c.clearCache());

  /// Returns the bytes freed.
  Future<int> clearOlderThan(Duration age) async {
    var freed = 0;
    await _run((c) async => freed = await c.clearVideosOlderThan(age));
    return freed;
  }

  /// Applies now and is remembered for the next start. Returns bytes freed.
  Future<int> setMaxBytes(int bytes) async {
    var freed = 0;
    await _run((_) async => freed = await AllPlayerVideoCache.updateSettings(maxCacheSizeBytes: bytes));
    return freed;
  }

  Future<void> setStrategy(EvictionStrategy strategy) =>
      _run((_) => AllPlayerVideoCache.updateSettings(strategy: strategy));

  Future<void> _run(Future<void> Function(VideoPartialCache cache) action) async {
    final cache = _cache;
    if (cache == null) return;
    try {
      await action(cache);
    } catch (e) {
      _emit(state.copyWith(error: e));
    }
    await load(silent: true);
  }

  void _emit(AllPlayerCacheState s) {
    if (!isClosed) emit(s);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
