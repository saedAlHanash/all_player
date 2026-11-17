import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_partial_cache/video_partial_cache.dart';

import 'cache_manager_cubit.dart';
import 'cache_manager_labels.dart';
import 'cache_timeline_bar.dart';

const _mb = 1024 * 1024;
const _gb = 1024 * _mb;

/// Ready-made screen for the video cache: [AllPlayerCacheManager] in a
/// [Scaffold]. Open it with [AllPlayerCacheManagerPage.open].
class AllPlayerCacheManagerPage extends StatelessWidget {
  const AllPlayerCacheManagerPage({
    super.key,
    this.labels = const AllPlayerCacheLabels(),
    this.refreshInterval = const Duration(seconds: 5),
    this.sizeOptions = AllPlayerCacheManager.defaultSizeOptions,
    this.onVideoTap,
  });

  final AllPlayerCacheLabels labels;
  final Duration? refreshInterval;
  final List<int> sizeOptions;
  final void Function(CachedVideo video)? onVideoTap;

  static Future<void> open(
    BuildContext context, {
    AllPlayerCacheLabels labels = const AllPlayerCacheLabels(),
    Duration? refreshInterval = const Duration(seconds: 5),
    List<int> sizeOptions = AllPlayerCacheManager.defaultSizeOptions,
    void Function(CachedVideo video)? onVideoTap,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AllPlayerCacheManagerPage(
          labels: labels,
          refreshInterval: refreshInterval,
          sizeOptions: sizeOptions,
          onVideoTap: onVideoTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(labels.title)),
      body: AllPlayerCacheManager(
        labels: labels,
        refreshInterval: refreshInterval,
        sizeOptions: sizeOptions,
        onVideoTap: onVideoTap,
      ),
    );
  }
}

/// Shows and controls the video cache: used / free space, the limit and
/// eviction strategy, and every cached video with its thumbnail, size, cached
/// share and **where** on its timeline it is cached. Each video can be kept
/// (pinned) or deleted.
///
/// Embed it anywhere (it is a scrollable list); it uses only the colors and
/// text styles of the current [Theme].
class AllPlayerCacheManager extends StatefulWidget {
  const AllPlayerCacheManager({
    super.key,
    this.labels = const AllPlayerCacheLabels(),
    this.refreshInterval = const Duration(seconds: 5),
    this.sizeOptions = defaultSizeOptions,
    this.showSettings = true,
    this.onVideoTap,
    this.padding = const EdgeInsets.all(12),
  });

  static const defaultSizeOptions = [256 * _mb, 512 * _mb, _gb, 2 * _gb, 4 * _gb, 8 * _gb];

  final AllPlayerCacheLabels labels;

  /// How often the list refreshes itself (e.g. while a video downloads in
  /// the background). `null` refreshes only on pull-to-refresh and actions.
  final Duration? refreshInterval;

  /// Choices offered for the cache size limit, in bytes.
  final List<int> sizeOptions;

  final bool showSettings;
  final void Function(CachedVideo video)? onVideoTap;
  final EdgeInsetsGeometry padding;

  @override
  State<AllPlayerCacheManager> createState() => _AllPlayerCacheManagerState();
}

class _AllPlayerCacheManagerState extends State<AllPlayerCacheManager> {
  late final AllPlayerCacheCubit _cubit = AllPlayerCacheCubit(refreshInterval: widget.refreshInterval);

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<AllPlayerCacheCubit, AllPlayerCacheState>(
        builder: (context, state) {
          if (!state.enabled) return _Message(icon: Icons.cloud_off_outlined, text: labels.disabled);
          if (state.stats == null) {
            if (state.error != null) {
              return _Message(
                icon: Icons.error_outline,
                text: '${labels.error}\n${state.error}',
                action: TextButton(onPressed: _cubit.load, child: Text(labels.retry)),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }

          final header = <Widget>[
            _StorageCard(state: state, labels: labels),
            if (widget.showSettings) _SettingsCard(state: state, labels: labels, sizeOptions: widget.sizeOptions),
            _ListHeader(state: state, labels: labels),
            if (state.videos.isEmpty) _Message(icon: Icons.video_library_outlined, text: labels.empty, expand: false),
          ];

          return RefreshIndicator(
            onRefresh: _cubit.load,
            child: ListView.builder(
              padding: widget.padding,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: header.length + state.videos.length,
              itemBuilder: (context, i) {
                if (i < header.length) return header[i];
                final video = state.videos[i - header.length];
                return _VideoCard(
                  key: ValueKey(video.key),
                  video: video,
                  labels: labels,
                  onTap: widget.onVideoTap == null ? null : () => widget.onVideoTap!(video),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- storage --

class _StorageCard extends StatelessWidget {
  const _StorageCard({required this.state, required this.labels});

  final AllPlayerCacheState state;
  final AllPlayerCacheLabels labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hit = state.stats?.hitRatio;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: _Metric(label: labels.used, value: formatBytes(state.usedBytes))),
                Expanded(child: _Metric(label: labels.free, value: formatBytes(state.freeBytes))),
                Expanded(child: _Metric(label: labels.limit, value: formatBytes(state.maxBytes))),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: state.usedFraction, minHeight: 8),
            ),
            const SizedBox(height: 8),
            Text(
              [
                '${labels.videos}: ${state.videos.length}',
                if (hit != null) '${labels.hitRatio}: ${(hit * 100).round()}%',
              ].join('   ·   '),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// --------------------------------------------------------------- settings --

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.state, required this.labels, required this.sizeOptions});

  final AllPlayerCacheState state;
  final AllPlayerCacheLabels labels;
  final List<int> sizeOptions;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AllPlayerCacheCubit>();
    final scheme = Theme.of(context).colorScheme;
    final strategy = state.stats?.strategy ?? EvictionStrategy.lru;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.sd_storage_outlined),
            title: Text(labels.cacheLimit),
            subtitle: Text(formatBytes(state.maxBytes)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final options = {...sizeOptions, state.maxBytes}.toList()..sort();
              final picked = await _pick<int>(
                context,
                title: labels.cacheLimit,
                options: options,
                selected: state.maxBytes,
                nameOf: formatBytes,
              );
              if (picked == null || picked == state.maxBytes) return;
              final freed = await cubit.setMaxBytes(picked);
              if (freed > 0 && context.mounted) _snack(context, '${labels.freed} ${formatBytes(freed)}');
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_delete_outlined),
            title: Text(labels.strategy),
            subtitle: Text(labels.strategyName(strategy)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final picked = await _pick<EvictionStrategy>(
                context,
                title: labels.strategy,
                options: EvictionStrategy.values,
                selected: strategy,
                nameOf: labels.strategyName,
              );
              if (picked != null && picked != strategy) await cubit.setStrategy(picked);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history_toggle_off),
            title: Text(labels.clearOld),
            onTap: () async {
              final freed = await cubit.clearOlderThan(const Duration(days: 30));
              if (context.mounted) _snack(context, '${labels.freed} ${formatBytes(freed)}');
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_sweep_outlined, color: scheme.error),
            title: Text(labels.clearAll, style: TextStyle(color: scheme.error)),
            onTap: () async {
              if (await _confirm(context, labels, labels.clearAllConfirm)) await cubit.clearAll();
            },
          ),
        ],
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.state, required this.labels});

  final AllPlayerCacheState state;
  final AllPlayerCacheLabels labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<AllPlayerCacheCubit>();
    String name(CachedVideoSort s) => switch (s) {
          CachedVideoSort.size => labels.sortSize,
          CachedVideoSort.recent => labels.sortRecent,
          CachedVideoSort.name => labels.sortName,
        };

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 12, 0, 4),
      child: Row(
        children: [
          Expanded(child: Text('${labels.videos} (${state.videos.length})', style: theme.textTheme.titleSmall)),
          PopupMenuButton<CachedVideoSort>(
            tooltip: labels.sortBy,
            initialValue: state.sort,
            onSelected: cubit.setSort,
            itemBuilder: (_) => [
              for (final s in CachedVideoSort.values) PopupMenuItem(value: s, child: Text(name(s))),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sort),
                  const SizedBox(width: 4),
                  Text(name(state.sort), style: theme.textTheme.labelLarge),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ video --

enum _VideoAction { pin, unpin, delete }

class _VideoCard extends StatelessWidget {
  const _VideoCard({super.key, required this.video, required this.labels, this.onTap});

  final CachedVideo video;
  final AllPlayerCacheLabels labels;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cubit = context.read<AllPlayerCacheCubit>();
    final subtle = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final showQualityNames = video.qualities.length > 1;
    final duration = video.duration;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Thumbnail(url: video.thumbnail, fraction: video.fraction),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatBytes(video.bytes)} · ${_percentText(video.fraction, labels)}',
                          style: subtle,
                        ),
                        if (video.pinned) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.push_pin, size: 14, color: scheme.primary),
                              const SizedBox(width: 4),
                              Text(labels.pinned, style: subtle?.copyWith(color: scheme.primary)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<_VideoAction>(
                    onSelected: (a) async {
                      switch (a) {
                        case _VideoAction.pin:
                          await cubit.setPinned(video, true);
                        case _VideoAction.unpin:
                          await cubit.setPinned(video, false);
                        case _VideoAction.delete:
                          if (await _confirm(context, labels, labels.deleteVideoConfirm)) {
                            await cubit.deleteVideo(video);
                          }
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: video.pinned ? _VideoAction.unpin : _VideoAction.pin,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(video.pinned ? Icons.push_pin_outlined : Icons.push_pin),
                          title: Text(video.pinned ? labels.unpin : labels.pin),
                        ),
                      ),
                      PopupMenuItem(
                        value: _VideoAction.delete,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.delete_outline, color: scheme.error),
                          title: Text(labels.deleteVideo, style: TextStyle(color: scheme.error)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final q in video.qualities) ...[
                if (showQualityNames)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(q.quality == null ? '—' : '${q.quality}p', style: theme.textTheme.labelMedium),
                        const Spacer(),
                        Text(
                          '${formatBytes(q.stats.cachedBytes)} · '
                          '${_percentText(q.progress.fraction ?? q.stats.cachedFraction, labels)}',
                          style: subtle,
                        ),
                        if (video.qualities.length > 1)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: labels.deleteVideo,
                            icon: const Icon(Icons.close),
                            onPressed: () => cubit.deleteQuality(q),
                          ),
                      ],
                    ),
                  ),
                CacheTimelineBar(spans: q.progress.spans),
                const SizedBox(height: 6),
              ],
              if (duration != null)
                Row(
                  children: [
                    Text('0:00', style: subtle),
                    const Spacer(),
                    Text(formatDuration(duration), style: subtle),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url, required this.fraction});

  final String? url;
  final double? fraction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final placeholder = Center(child: Icon(Icons.movie_outlined, color: scheme.onSurfaceVariant));
    final f = fraction;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 112,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: ColoredBox(
            color: scheme.surfaceContainerHighest,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (url == null)
                  placeholder
                else
                  Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder),
                if (f != null)
                  PositionedDirectional(
                    end: 4,
                    bottom: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        child: Text(
                          '${(f * 100).round()}%',
                          style: theme.textTheme.labelSmall?.copyWith(color: scheme.onPrimaryContainer),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- helpers --

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action, this.expand = true});

  final IconData icon;
  final String text;
  final Widget? action;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          if (action != null) ...[const SizedBox(height: 8), action!],
        ],
      ),
    );
    return expand ? Center(child: child) : child;
  }
}

String _percentText(double? fraction, AllPlayerCacheLabels labels) =>
    fraction == null ? labels.unknownProgress : '${(fraction * 100).round()}% ${labels.cached}';

void _snack(BuildContext context, String text) {
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(text)));
}

Future<bool> _confirm(BuildContext context, AllPlayerCacheLabels labels, String message) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(labels.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(labels.confirm)),
      ],
    ),
  );
  return ok ?? false;
}

Future<T?> _pick<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required T selected,
  required String Function(T) nameOf,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(title),
      children: [
        for (final o in options)
          ListTile(
            title: Text(nameOf(o)),
            trailing: o == selected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
            onTap: () => Navigator.pop(context, o),
          ),
      ],
    ),
  );
}

/// `1.5 GB`, `320 MB`, ...
String formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var i = 0;
  while (value >= 1024 && i < units.length - 1) {
    value /= 1024;
    i++;
  }
  final text = value >= 100 || i == 0 ? value.round().toString() : value.toStringAsFixed(1);
  return '${text.endsWith('.0') ? text.substring(0, text.length - 2) : text} ${units[i]}';
}

/// `1:05:09`, `4:07`.
String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(h > 0 ? 2 : 1, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}
