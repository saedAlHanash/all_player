import 'package:all_player/all_player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayVideoFrom tests', () {
    test('creates youtube player video source correctly and extracts videoId', () {
      final from = PlayVideoFrom.youtubePlayer('https://youtu.be/dQw4w9WgXcQ');
      expect(from.playerType, AllPlayerType.youtube);
      expect(from.dataSource, 'dQw4w9WgXcQ');
    });

    test('creates youtube iframe video source correctly with raw ID or URL', () {
      final fromId = PlayVideoFrom.youtubeIframe('dQw4w9WgXcQ');
      expect(fromId.playerType, AllPlayerType.youtubeIframe);
      expect(fromId.dataSource, 'dQw4w9WgXcQ');

      final fromUrl = PlayVideoFrom.youtubeIframe('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
      expect(fromUrl.playerType, AllPlayerType.youtubeIframe);
      expect(fromUrl.dataSource, 'dQw4w9WgXcQ');
    });

    test('creates network video source correctly', () {
      final from = PlayVideoFrom.network('https://example.com/video.mp4');
      expect(from.playerType, AllPlayerType.network);
      expect(from.dataSource, 'https://example.com/video.mp4');
    });

    test('creates asset video source correctly', () {
      final from = PlayVideoFrom.asset('assets/video.mp4');
      expect(from.playerType, AllPlayerType.asset);
      expect(from.dataSource, 'assets/video.mp4');
    });

    test('creates vimeo video source correctly with ID, URL, and hash extraction', () {
      final fromId = PlayVideoFrom.vimeo('123456789');
      expect(fromId.playerType, AllPlayerType.vimeo);
      expect(fromId.dataSource, '123456789');

      final fromUrlWithHash = PlayVideoFrom.vimeo('https://vimeo.com/123456789/abcdef');
      expect(fromUrlWithHash.playerType, AllPlayerType.vimeo);
      expect(fromUrlWithHash.dataSource, '123456789');
      expect(fromUrlWithHash.hash, 'abcdef');
    });

    test('creates dailymotion video source correctly with raw ID or URL', () {
      final fromId = PlayVideoFrom.dailymotion('k2V1WuTvYVUQC4BT7IE');
      expect(fromId.playerType, AllPlayerType.dailymotion);
      expect(fromId.dataSource, 'k2V1WuTvYVUQC4BT7IE');

      final fromUrl = PlayVideoFrom.dailymotion('https://www.dailymotion.com/video/k2V1WuTvYVUQC4BT7IE');
      expect(fromUrl.playerType, AllPlayerType.dailymotion);
      expect(fromUrl.dataSource, 'k2V1WuTvYVUQC4BT7IE');
    });

    test('PlayVideoFrom.auto detects YouTube URL, extracts ID, and defaults to iframe', () {
      final from = PlayVideoFrom.auto('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
      expect(from.playerType, AllPlayerType.youtubeIframe);
      expect(from.dataSource, 'dQw4w9WgXcQ');
    });

    test('PlayVideoFrom.auto detects YouTube ID with preferred player mode', () {
      final from = PlayVideoFrom.auto(
        'dQw4w9WgXcQ',
        preferYoutubeMode: YoutubePlayMode.player,
      );
      expect(from.playerType, AllPlayerType.youtube);
      expect(from.dataSource, 'dQw4w9WgXcQ');
    });

    test('PlayVideoFrom.auto detects Vimeo numeric ID', () {
      final from = PlayVideoFrom.auto('123456789');
      expect(from.playerType, AllPlayerType.vimeo);
      expect(from.dataSource, '123456789');
    });

    test('PlayVideoFrom.auto detects Vimeo URL and extracts ID and hash', () {
      final from = PlayVideoFrom.auto('https://vimeo.com/123456789/abcdef');
      expect(from.playerType, AllPlayerType.vimeo);
      expect(from.dataSource, '123456789');
      expect(from.hash, 'abcdef');
    });

    test('PlayVideoFrom.auto detects Dailymotion ID', () {
      final from = PlayVideoFrom.auto('k2V1WuTvYVUQC4BT7IE');
      expect(from.playerType, AllPlayerType.dailymotion);
      expect(from.dataSource, 'k2V1WuTvYVUQC4BT7IE');
    });

    test('PlayVideoFrom.auto detects Dailymotion URL and extracts ID', () {
      final from = PlayVideoFrom.auto('https://www.dailymotion.com/video/k2V1WuTvYVUQC4BT7IE');
      expect(from.playerType, AllPlayerType.dailymotion);
      expect(from.dataSource, 'k2V1WuTvYVUQC4BT7IE');
    });

    test('PlayVideoFrom.auto detects direct MP4 network URL', () {
      final from = PlayVideoFrom.auto('https://example.com/stream.mp4');
      expect(from.playerType, AllPlayerType.network);
      expect(from.dataSource, 'https://example.com/stream.mp4');
    });
  });

  group('VideoPlatformDetector extension tests', () {
    test('detects platforms and properties correctly', () {
      expect('https://youtu.be/dQw4w9WgXcQ'.detectVideoPlatform.isYoutube, isTrue);
      expect('dQw4w9WgXcQ'.detectVideoPlatform.isYoutube, isTrue);
      expect('123456789'.detectVideoPlatform.isVimeo, isTrue);
      expect('https://vimeo.com/123456789'.detectVideoPlatform.isVimeo, isTrue);
      expect('k2V1WuTvYVUQC4BT7IE'.detectVideoPlatform.isDailymotion, isTrue);
      expect('https://example.com/video.mp4'.detectVideoPlatform.isNetwork, isTrue);
      expect(''.detectVideoPlatform.isUnknown, isTrue);
    });

    test('extracts YouTube videoId from all URL types and raw IDs', () {
      const expectedId = 'dQw4w9WgXcQ';
      expect('https://www.youtube.com/watch?v=dQw4w9WgXcQ'.youtubeVideoId, expectedId);
      expect('https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=120s'.youtubeVideoId, expectedId);
      expect('https://youtu.be/dQw4w9WgXcQ'.youtubeVideoId, expectedId);
      expect('https://youtu.be/dQw4w9WgXcQ?t=10'.youtubeVideoId, expectedId);
      expect('https://www.youtube.com/embed/dQw4w9WgXcQ'.youtubeVideoId, expectedId);
      expect('https://www.youtube.com/shorts/dQw4w9WgXcQ'.youtubeVideoId, expectedId);
      expect('https://www.youtube.com/live/dQw4w9WgXcQ'.youtubeVideoId, expectedId);
      expect('dQw4w9WgXcQ'.youtubeVideoId, expectedId);
      expect('https://www.youtube.com/watch?v=dQw4w9WgXcQ'.getVideoId, expectedId);
      expect('dQw4w9WgXcQ'.getVideoId, expectedId);
    });

    test('extracts Vimeo videoId and privacy hash from URLs and raw IDs', () {
      const expectedId = '123456789';
      expect('https://vimeo.com/123456789'.vimeoVideoId, expectedId);
      expect('https://vimeo.com/123456789/'.vimeoVideoId, expectedId);
      expect('https://vimeo.com/123456789?param=1'.vimeoVideoId, expectedId);
      expect('https://player.vimeo.com/video/123456789'.vimeoVideoId, expectedId);
      expect('https://vimeo.com/channels/staffpicks/123456789'.vimeoVideoId, expectedId);
      expect('123456789'.vimeoVideoId, expectedId);
      expect('https://vimeo.com/123456789'.getVideoId, expectedId);
      expect('123456789'.getVideoId, expectedId);

      // Hash extraction
      expect('https://vimeo.com/123456789/abcdef'.vimeoVideoId, expectedId);
      expect('https://vimeo.com/123456789/abcdef'.vimeoVideoHash, 'abcdef');
      expect('https://player.vimeo.com/video/123456789?h=abcdef'.vimeoVideoHash, 'abcdef');
    });

    test('extracts Dailymotion videoId from URLs and raw IDs', () {
      const expectedId = 'x7tgad0';
      expect('https://www.dailymotion.com/video/x7tgad0'.dailymotionVideoId, expectedId);
      expect('https://www.dailymotion.com/video/x7tgad0?playlist=abc'.dailymotionVideoId, expectedId);
      expect('https://dai.ly/x7tgad0'.dailymotionVideoId, expectedId);
      expect('https://www.dailymotion.com/embed/video/x7tgad0'.dailymotionVideoId, expectedId);
      expect('x7tgad0'.dailymotionVideoId, expectedId);
      expect('https://www.dailymotion.com/video/x7tgad0'.getVideoId, expectedId);
      expect('x7tgad0'.getVideoId, expectedId);
    });

    test('getVideoId leaves direct network URLs intact', () {
      const netUrl = 'https://example.com/video.mp4';
      expect(netUrl.getVideoId, netUrl);
    });

    test('correctly parses Dailymotion HLS M3U8 content with metadata and subtitles using extension', () {
      const m3u8 = '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=836280,CODECS="mp4a.40.2,avc1.64001f",RESOLUTION=848x480,NAME="480",SUBTITLES="subtitles"
https://vod3.cf.dmcdn.net/video/fmp4/480/manifest.m3u8#cell=cf3
#EXT-X-STREAM-INF:BANDWIDTH=460560,CODECS="mp4a.40.2,avc1.42001e",RESOLUTION=512x288,NAME="380",SUBTITLES="subtitles"
https://vod3.cf.dmcdn.net/video/fmp4/380/manifest.m3u8#cell=cf3
#EXT-X-STREAM-INF:BANDWIDTH=2149280,CODECS="mp4a.40.2,avc1.64001f",RESOLUTION=1280x720,NAME="720",SUBTITLES="subtitles"
https://vod3.cf.dmcdn.net/video/fmp4/720/manifest.m3u8#cell=cf3
#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID="subtitles",URI="https://www.dailymotion.com/subtitle.m3u8"
''';

      final result = m3u8.parseHlsMasterPlaylist();
      expect(result.length, 3);
      expect(result.any((e) => e.quality == 480 && e.url.contains('480')), isTrue);
      expect(result.any((e) => e.quality == 380 && e.url.contains('380')), isTrue);
      expect(result.any((e) => e.quality == 720 && e.url.contains('720')), isTrue);
    });
  });

  group('AllPlayerController Cubit tests', () {
    test('initializes with initial AllPlayerState', () {
      final controller = AllPlayerController(
        playVideoFrom: PlayVideoFrom.youtubeIframe('dQw4w9WgXcQ'),
      );

      expect(controller.state.playerStatus, AllPlayerStatus.loading);
      expect(controller.isIframe, isTrue);
      expect(controller.isVideoLooping, isFalse);
      expect(controller.isFullScreen, isFalse);
      expect(controller.isMute, isFalse);
      expect(controller.currentPlaybackSpeed, '1x');
    });

    test('updates volume and mute state correctly', () async {
      final controller = AllPlayerController(
        playVideoFrom: PlayVideoFrom.network('https://example.com/video.mp4'),
      );

      await controller.setVolume(0);
      expect(controller.state.volume, 0.0);
      expect(controller.state.isMute, isTrue);

      await controller.setVolume(0.8);
      expect(controller.state.volume, 0.8);
      expect(controller.state.isMute, isFalse);
      await controller.close();
    });

    test('updates playback speed and looping state correctly', () async {
      final controller = AllPlayerController(
        playVideoFrom: PlayVideoFrom.network('https://example.com/video.mp4'),
      );

      controller.setVideoPlayback('1.5x');
      expect(controller.state.playbackSpeed, '1.5x');

      await controller.setLooping(true);
      expect(controller.state.isLooping, isTrue);

      await controller.toggleLooping();
      expect(controller.state.isLooping, isFalse);
      await controller.close();
    });

    test('handles double tap forward and backward correctly', () async {
      final controller = AllPlayerController(
        playVideoFrom: PlayVideoFrom.network('https://example.com/video.mp4'),
      );

      controller.onRightDoubleTap(seconds: 10);
      expect(controller.state.isRightDbTapIconVisible, isTrue);
      expect(controller.state.rightDoubleTapDuration, 10);

      controller.onLeftDoubleTap(seconds: 10);
      expect(controller.state.isLeftDbTapIconVisible, isTrue);
      expect(controller.state.leftDoubleTapDuration, 10);
      await controller.close();
    });

    test('supports aliases and enums', () {
      expect(AllVideoState.values, AllPlayerStatus.values);
      expect(AllVideoPlayerType.values, AllPlayerType.values);
    });
  });
}
