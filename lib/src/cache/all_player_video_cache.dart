import 'package:flutter/foundation.dart';
import 'package:video_partial_cache/video_partial_cache.dart';

import '../utils/logger.dart';

/// Optional on-disk cache for the video **bytes** (progressive MP4 / WebM),
/// built on `video_partial_cache`. Everything the player downloads is kept in
/// chunks, so replays and seeks into downloaded parts need no network.
///
/// Call [init] once at start-up. Without it the player works exactly as before.
///
/// Used automatically for `network`, `networkQualityUrls`, `youtube` (muxed),
/// `vimeo` and `dailymotion` sources, both for progressive files (HTTP byte
/// ranges) and for HLS (`.m3u8`: playlists and segments are cached, so a fully
/// played video also plays offline). It is skipped for DASH (`.mpd`), assets,
/// files, the web, live HLS streams, and videos with per-video `httpHeaders`
/// (they could not be forwarded to the origin through the proxy).
///
/// Android needs cleartext traffic to localhost and iOS needs
/// `NSAllowsLocalNetworking`; see the `video_partial_cache` README. If the
/// proxy cannot be reached the player falls back to the direct url.
class AllPlayerVideoCache {
  AllPlayerVideoCache._();

  static VideoPartialCache? _cache;

  /// The underlying cache for stats, pinning, trimming and clearing
  /// (`getStats`, `setPinned`, `clearVideo`, ...). `null` until [init].
  static VideoPartialCache? get instance => _cache;

  static bool get isEnabled => _cache?.isInitialized ?? false;

  static Future<void> init({
    int maxCacheSizeBytes = 500 * 1024 * 1024,
    int chunkSizeBytes = 256 * 1024,
    EvictionStrategy evictionStrategy = EvictionStrategy.lru,
    Map<String, String> upstreamHeaders = const {},
  }) async {
    if (kIsWeb || _cache != null) return;

    final cache = VideoPartialCache(
      maxCacheSizeBytes: maxCacheSizeBytes,
      chunkSizeBytes: chunkSizeBytes,
      evictionStrategy: evictionStrategy,
      upstreamHeaders: upstreamHeaders,
      onLog: allPlayerLog,
    );
    try {
      await cache.init();
      _cache = cache;
    } catch (e) {
      allPlayerLog('video cache init failed, playing without it: $e');
    }
  }

  /// Local proxy url for [url], or `null` when it cannot / should not be cached.
  ///
  /// Pass a stable [videoId] for signed urls that change on every request;
  /// when omitted the cache derives one from the url.
  static String? playableUrl(String url, {String? videoId}) {
    final cache = _cache;
    if (cache == null || !cache.isInitialized || !_isSupported(url)) return null;
    return cache.getPlayableUrl(url, videoId: videoId);
  }

  /// Whether [url] is an HLS playlist (one cache id covers all its qualities).
  static bool isHls(String url) => VideoPartialCache.isHlsUrl(url);

  static bool _isSupported(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.scheme.startsWith('http')) return false;
    return !uri.path.toLowerCase().contains('.mpd');
  }

  /// Stops the local proxy. The cache can be created again with [init].
  static Future<void> dispose() async {
    final cache = _cache;
    _cache = null;
    await cache?.dispose();
  }
}
