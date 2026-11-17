import 'dart:io';
import 'dart:typed_data';

import 'package:all_player/all_player.dart';
import 'package:all_player/src/cache_manager/all_player_cache_manager.dart'
    show formatBytes, formatDuration;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const total = 10500;
final data = Uint8List.fromList(List.generate(total, (i) => i % 251));

/// Byte-range origin for a fake MP4.
final origin = MockClient.streaming((req, _) async {
  final m = RegExp(r'bytes=(\d+)-(\d+)?').firstMatch(req.headers['range'] ?? '');
  final s = m == null ? 0 : int.parse(m.group(1)!);
  final e = m?.group(2) == null ? total - 1 : int.parse(m!.group(2)!).clamp(0, total - 1);
  return http.StreamedResponse(
    Stream.value(data.sublist(s, e + 1)),
    m == null ? 200 : 206,
    contentLength: e - s + 1,
    headers: {
      'content-type': 'video/mp4',
      if (m != null) 'content-range': 'bytes $s-$e/$total',
    },
  );
});

Future<void> fetchRange(String url, String range) async {
  final c = HttpClient();
  try {
    final req = await c.getUrl(Uri.parse(url));
    req.headers.set('range', range);
    await (await req.close()).drain<void>();
  } finally {
    c.close(force: true);
  }
}

void main() {
  test('formatBytes / formatDuration', () {
    expect(formatBytes(0), '0 B');
    expect(formatBytes(1536), '1.5 KB');
    expect(formatBytes(1024 * 1024 * 1024), '1 GB');
    expect(formatBytes(320 * 1024 * 1024), '320 MB');
    expect(formatDuration(const Duration(minutes: 4, seconds: 7)), '4:07');
    expect(formatDuration(const Duration(hours: 1, minutes: 5, seconds: 9)), '1:05:09');
  });

  test('cache id helpers', () {
    expect(AllPlayerVideoCache.baseKeyOf('dailymotion:x8ab@720'), 'dailymotion:x8ab');
    expect(AllPlayerVideoCache.qualityOf('dailymotion:x8ab@720'), 720);
    expect(AllPlayerVideoCache.baseKeyOf('url:abc'), 'url:abc');
    expect(AllPlayerVideoCache.qualityOf('url:abc'), isNull);
  });

  testWidgets('shows a disabled message without AllPlayerVideoCache.init', (tester) async {
    AllPlayerVideoCache.debugInstance = null;
    await tester.pumpWidget(const MaterialApp(home: AllPlayerCacheManagerPage(refreshInterval: null)));
    await tester.pump();
    expect(find.textContaining('not enabled'), findsOneWidget);
  });

  group('with a cache', () {
    late Directory dir;
    late VideoPartialCache cache;

    setUp(() async {
      // Widget tests fake every HttpClient; the local proxy needs a real one.
      HttpOverrides.global = null;
      dir = await Directory.systemTemp.createTemp('all_player_cm');
      cache = VideoPartialCache(
        cacheDirectory: dir,
        httpClient: origin,
        chunkSizeBytes: 1000,
        maxCacheSizeBytes: 1024 * 1024,
      );
      await cache.init();
      AllPlayerVideoCache.debugInstance = cache;
    });

    tearDown(() async {
      AllPlayerVideoCache.debugInstance = null;
      await cache.dispose();
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    Future<void> cacheTwoQualities() async {
      final u720 = cache.getPlayableUrl('https://o.test/a.mp4', videoId: 'vimeo:42@720');
      final u360 = cache.getPlayableUrl('https://o.test/a.mp4', videoId: 'vimeo:42@360');
      await fetchRange(u720, 'bytes=0-1999');
      await fetchRange(u360, 'bytes=0-999');
      await cache.debugWaitForIdle();
    }

    Future<AllPlayerCacheState> loaded(AllPlayerCacheCubit cubit) async {
      await cubit.load();
      return cubit.state;
    }

    test('cubit groups qualities and controls the cache', () async {
      await cacheTwoQualities();
      final cubit = AllPlayerCacheCubit();
      var s = await loaded(cubit);
      expect(s.enabled, isTrue);
      expect(s.usedBytes, 3000);
      expect(s.freeBytes, 1024 * 1024 - 3000);
      final video = s.videos.single;
      expect(video.key, 'vimeo:42');
      expect(video.displayName, 'Vimeo · 42');
      expect(video.qualities.map((q) => q.quality), [720, 360]);
      expect(video.fraction, closeTo(2000 / total, 1e-9));

      await cubit.setPinned(video, true);
      expect(cubit.state.videos.single.pinned, isTrue);

      await cubit.deleteQuality(cubit.state.videos.single.qualities.last);
      expect(cubit.state.videos.single.qualities, hasLength(1));

      await cubit.setStrategy(EvictionStrategy.lfu);
      expect(cubit.state.stats!.strategy, EvictionStrategy.lfu);
      await cubit.setMaxBytes(2 * 1024 * 1024);
      expect(cubit.state.maxBytes, 2 * 1024 * 1024);

      await cubit.deleteVideo(cubit.state.videos.single);
      s = cubit.state;
      expect(s.videos, isEmpty);
      expect(s.usedBytes, 0);
      await cubit.close();
    });

    testWidgets('shows each cached video with size, share and timeline', (tester) async {
      await tester.runAsync(() async {
        await cacheTwoQualities();
        await tester.pumpWidget(const MaterialApp(home: AllPlayerCacheManagerPage(refreshInterval: null)));
        // The list is read from disk with real IO.
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pump();

      // One card for both qualities of vimeo:42.
      expect(find.text('Vimeo · 42'), findsOneWidget);
      expect(find.text('720p'), findsOneWidget);
      expect(find.text('360p'), findsOneWidget);
      expect(find.byType(CacheTimelineBar), findsNWidgets(2));
      expect(find.textContaining('2.9 KB · 19% cached'), findsOneWidget); // 3000 B, best 2000/10500
      expect(find.text('Videos (1)'), findsOneWidget);

      final bars = tester.widgetList<CacheTimelineBar>(find.byType(CacheTimelineBar)).toList();
      expect(bars.first.spans.single.start, 0);
      expect(bars.first.spans.single.end, closeTo(2000 / total, 1e-9));

      // The menu offers keeping and deleting.
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Keep (never remove automatically)'), findsOneWidget);
      expect(find.text('Delete'), findsWidgets);

      // Settings are shown.
      expect(find.text('Cache size limit'), findsOneWidget);
      expect(find.text('1 MB'), findsWidgets);

      await tester.runAsync(() async {
        await tester.pumpWidget(const SizedBox());
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
    });
  });
}
