import 'dart:convert';
import 'dart:developer';

import 'package:all_player/src/utils/dailymotion_response.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../models/vimeo_models.dart';
import 'enums.dart';

String allPlayerErrorString(String val) {
  return '*\n------error------\n\n$val\n\n------end------\n*';
}

class VideoApis {
  //region Vimeo
  static Future<Response> _makeRequestHash(String videoId, String? hash) {
    final cleanId = videoId.vimeoVideoId ?? videoId;
    final cleanHash = hash ?? videoId.vimeoVideoHash;
    final uri = cleanHash == null
        ? Uri.parse('https://player.vimeo.com/video/$cleanId/config')
        : Uri.parse('https://player.vimeo.com/video/$cleanId/config?h=$cleanHash');
    return http.get(uri);
  }

  static Future<List<VideoQalityUrls>?> getVimeoVideoQualityUrls(
    String videoId,
    String? hash, {
    void Function(String thumbnailUrl)? onThumbnail,
  }) async {
    final cleanId = videoId.vimeoVideoId ?? videoId;
    final cleanHash = hash ?? videoId.vimeoVideoHash;
    try {
      final response = await _makeRequestHash(cleanId, cleanHash);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final thumbnail = json.vimeoThumbnail;
      if (thumbnail != null) onThumbnail?.call(thumbnail);
      return json.parseVimeoStreams();
    } catch (error) {
      _handleApiError('Vimeo', error);
      rethrow;
    }
  }

  static Future<List<VideoQalityUrls>?> getVimeoPrivateVideoQualityUrls(
    String videoId,
    Map<String, String> httpHeader,
  ) async {
    final cleanId = videoId.vimeoVideoId ?? videoId;
    try {
      final response = await http.get(
        Uri.parse('https://api.vimeo.com/videos/$cleanId'),
        headers: httpHeader,
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json.parseVimeoPrivateStreams();
    } catch (error) {
      _handleApiError('Vimeo Private', error);
      rethrow;
    }
  }

  //endregion

  //region YouTube
  static Future<List<VideoQalityUrls>?> getYoutubeVideoQualityUrls(
    String youtubeIdOrUrl,
    bool live,
  ) async {
    final cleanId = youtubeIdOrUrl.youtubeVideoId ?? youtubeIdOrUrl;
    try {
      final yt = YoutubeExplode();
      final urls = <VideoQalityUrls>[];
      if (live) {
        final url = await yt.videos.streamsClient.getHttpLiveStreamUrl(
          VideoId(cleanId),
        );
        urls.add(VideoQalityUrls(quality: 360, url: url));
      } else {
        final manifest = await yt.videos.streamsClient.getManifest(cleanId);
        urls.addAll(
          manifest.muxed.map(
            (element) => VideoQalityUrls(
              quality: int.tryParse(element.qualityLabel.split('p').first) ?? 0,
              url: element.url.toString(),
            ),
          ),
        );
      }
      yt.close();
      return urls;
    } catch (error) {
      _handleApiError('YouTube', error);
      rethrow;
    }
  }

  //endregion

  //region Dailymotion
  static Future<List<VideoQalityUrls>?> getDailymotionVideoQualityUrls(
    String vId,
    String token,
  ) async {
    final cleanId = vId.dailymotionVideoId ?? vId;
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.dailymotion.com/video/$cleanId?fields=stream_h264_hd_url,stream_h264_hq_url,stream_h264_qhd_url,stream_h264_l2_url,stream_h264_l1_url,stream_h264_hd1080_url,stream_h264_url',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json.parseDailymotionStreams();
    } catch (error) {
      _handleApiError('Dailymotion', error);
      rethrow;
    }
  }

  static Future<List<VideoQalityUrls>?> getDailymotionVideoQualityM3U8Urls(
    String vId, {
    void Function(String thumbnailUrl)? onThumbnail,
  }) async {
    final cleanId = vId.dailymotionVideoId ?? vId;
    try {
      final response = await http.get(
        Uri.parse('https://www.dailymotion.com/player/metadata/video/$cleanId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      final model = DailymotionResponse.fromJson(jsonDecode(response.body));
      final thumbnail = model.thumbnails['480'] ?? model.thumbnails.values.firstOrNull;
      if (thumbnail != null) onThumbnail?.call(thumbnail);

      final autoList = model.qualities?.auto;
      final firstAutoUrl = autoList?.isNotEmpty == true ? autoList!.first.url : null;

      if (firstAutoUrl == null || firstAutoUrl.isEmpty) {
        return [];
      }

      final m3u8Response = await http.get(Uri.parse(firstAutoUrl));
      return m3u8Response.body.parseHlsMasterPlaylist();
    } catch (error) {
      _handleApiError('Dailymotion M3U8', error);
      rethrow;
    }
  }

  //endregion

  static void _handleApiError(String platform, Object error) {
    if (error.toString().contains('XMLHttpRequest')) {
      log(
        allPlayerErrorString(
          '(INFO) To play $platform video in WEB, please enable CORS in your browser.',
        ),
      );
    }
    debugPrint('===== $platform API ERROR: $error ==========');
  }
}

//region Extensions

/// Extensions on [String] for parsing HLS playlists.
extension HlsMasterPlaylistExtension on String {
  /// Parses an HLS master playlist (.m3u8) body and returns a list of quality URLs.
  List<VideoQalityUrls> parseHlsMasterPlaylist() {
    final lines = split(RegExp(r'\r?\n'));
    final Map<String, String> qualityToUrlMap = {};

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('#EXT-X-STREAM-INF:')) {
        String? streamUrl;
        for (int j = i + 1; j < lines.length; j++) {
          final nextLine = lines[j].trim();
          if (nextLine.isNotEmpty && !nextLine.startsWith('#')) {
            streamUrl = nextLine;
            break;
          }
        }

        if (streamUrl != null && streamUrl.startsWith('http')) {
          String? quality;
          final nameMatch = RegExp(r'NAME="?(\d+)"?').firstMatch(line);
          if (nameMatch != null) {
            quality = nameMatch.group(1);
          } else {
            final resMatch = RegExp(r'RESOLUTION=\d+x(\d+)', caseSensitive: false).firstMatch(line);
            if (resMatch != null) {
              quality = resMatch.group(1);
            }
          }

          if (quality != null && int.tryParse(quality) != null) {
            qualityToUrlMap[quality] = streamUrl;
          }
        }
      }
    }

    final urls = <VideoQalityUrls>[];
    qualityToUrlMap.forEach(
      (quality, url) {
        urls.add(
          VideoQalityUrls(
            quality: int.tryParse(quality) ?? 0,
            url: url,
          ),
        );
      },
    );
    return urls;
  }
}

/// Extensions for parsing Vimeo API responses.
extension VimeoResponseExtension on Map<String, dynamic> {
  /// Best available thumbnail of a public Vimeo config response.
  String? get vimeoThumbnail {
    final thumbs = (this['video'] as Map?)?['thumbs'] as Map?;
    if (thumbs == null) return null;
    return (thumbs['640'] ?? thumbs['960'] ?? thumbs['base'])?.toString();
  }

  /// Parses public Vimeo video stream configuration.
  List<VideoQalityUrls> parseVimeoStreams() {
    final request = this['request'] as Map<String, dynamic>?;
    final files = request?['files'] as Map<String, dynamic>?;
    if (files == null) return [];

    // 1. Progressive MP4 files (when the owner allows them): a real url per quality.
    final progressive = <VideoQalityUrls>[];
    for (final item in (files['progressive'] as List<dynamic>?) ?? const []) {
      final quality = int.tryParse('${item['quality']}'.split('p').first) ?? 0;
      final url = item['url'] as String?;
      if (quality > 0 && url != null && url.isNotEmpty) {
        progressive.add(VideoQalityUrls(quality: quality, url: url));
      }
    }
    if (progressive.isNotEmpty) return progressive;

    // 2. HLS: the master playlist already contains every quality (the player
    // switches adaptively), so it is exposed as a single entry.

    final dashData = files['dash'] as Map<String, dynamic>?;
    final hlsData = files['hls'] as Map<String, dynamic>?;
    final defaultCDN = hlsData?['default_cdn'] as String?;
    final cdns = hlsData?['cdns'] as Map<String, dynamic>?;
    final cdnVideoUrl = (cdns?[defaultCDN]?['url'] as String?) ?? '';
    final rawStreamUrls = (dashData?['streams'] as List<dynamic>?) ?? [];

    if (cdnVideoUrl.isEmpty) return [];

    // Label the entry with the best quality on offer (never below 360, the
    // lowest quality the controller keeps).
    var best = 0;
    for (final item in rawStreamUrls) {
      final quality = int.tryParse(((item['quality'] as String?) ?? '').split('p').first) ?? 0;
      if (quality > best) best = quality;
    }
    return [VideoQalityUrls(quality: best < 360 ? 720 : best, url: cdnVideoUrl)];
  }

  /// Parses private Vimeo video streams.
  List<VideoQalityUrls> parseVimeoPrivateStreams() {
    final files = (this['files'] as List<dynamic>?) ?? [];
    final List<VideoQalityUrls> list = [];

    for (final item in files) {
      final rendition = (item['rendition'] as String?)?.split('p').first ?? '0';
      final quality = int.tryParse(rendition);
      final link = item['link'] as String?;
      if (quality != null && quality > 0 && link != null) {
        list.add(VideoQalityUrls(quality: quality, url: link));
      }
    }
    return list;
  }
}

/// Extensions for parsing Dailymotion API responses.
extension DailymotionResponseExtension on Map<String, dynamic> {
  /// Maps stream fields from Dailymotion API to [VideoQalityUrls].
  List<VideoQalityUrls> parseDailymotionStreams() {
    final urls = <VideoQalityUrls>[];
    const qualityMap = {
      1080: 'stream_h264_hd1080_url',
      720: 'stream_h264_hd_url',
      480: 'stream_h264_hq_url',
      360: 'stream_h264_qhd_url',
      240: 'stream_h264_l2_url',
      144: 'stream_h264_url',
    };

    qualityMap.forEach((quality, fieldName) {
      final streamUrl = this[fieldName]?.toString();
      if (streamUrl != null && streamUrl.isNotEmpty) {
        urls.add(VideoQalityUrls(quality: quality, url: streamUrl));
      }
    });

    return urls;
  }
}
//endregion
