part of 'package:all_player/src/all_player.dart';

class _WebSettingsDropdown extends StatefulWidget {
  final String? tag;

  const _WebSettingsDropdown({
    this.tag,
  });

  @override
  State<_WebSettingsDropdown> createState() => _WebSettingsDropdownState();
}

class _WebSettingsDropdownState extends State<_WebSettingsDropdown> {
  @override
  Widget build(BuildContext context) {
    final playerCtr = context.read<AllPlayerController>();
    return Theme(
      data: Theme.of(context).copyWith(
        focusColor: Colors.white,
      ),
      child: BlocBuilder<AllPlayerController, AllPlayerState>(
        builder: (context, state) {
          return MaterialIconButton(
            toolTipMesg: playerCtr.playerLabels.settings,
            color: Colors.white,
            child: const Icon(Icons.settings),
            onPressed: () {},
            onTapDown: (details) async {
              final settingsMenu = await showMenu<String>(
                context: context,
                items: [
                  if (state.availableQualities.isNotEmpty)
                    PopupMenuItem(
                      value: 'QUALITY',
                      child: _bottomSheetTiles(
                        title: playerCtr.playerLabels.quality,
                        icon: Icons.video_settings_rounded,
                        subText: '${state.currentQuality ?? 0}p',
                      ),
                    ),
                  PopupMenuItem(
                    value: 'LOOP',
                    child: _bottomSheetTiles(
                      title: playerCtr.playerLabels.loopVideo,
                      icon: Icons.loop_rounded,
                      subText: state.isLooping
                          ? playerCtr.playerLabels.optionEnabled
                          : playerCtr.playerLabels.optionDisabled,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'SPEED',
                    child: _bottomSheetTiles(
                      title: playerCtr.playerLabels.playbackSpeed,
                      icon: Icons.slow_motion_video_rounded,
                      subText: state.playbackSpeed,
                    ),
                  ),
                ],
                position: RelativeRect.fromSize(
                  details.globalPosition & Size.zero,
                  MediaQuery.of(context).size,
                ),
              );
              if (!mounted) return;
              switch (settingsMenu) {
                case 'QUALITY':
                  await _onQualitySelect(details, playerCtr, state);
                case 'SPEED':
                  await _onPlaybackSpeedSelect(details, playerCtr);
                case 'LOOP':
                  await playerCtr.toggleLooping();
              }
            },
          );
        },
      ),
    );
  }

  Future<void> _onPlaybackSpeedSelect(
    TapDownDetails details,
    AllPlayerController playerCtr,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    await showMenu(
      context: context,
      items: AllPlayerController.videoPlaybackSpeeds
          .map(
            (e) => PopupMenuItem<dynamic>(
              child: ListTile(title: Text(e)),
              onTap: () => playerCtr.setVideoPlayback(e),
            ),
          )
          .toList(),
      position: RelativeRect.fromSize(
        details.globalPosition & Size.zero,
        MediaQuery.of(context).size,
      ),
    );
  }

  Future<void> _onQualitySelect(
    TapDownDetails details,
    AllPlayerController playerCtr,
    AllPlayerState state,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    await showMenu(
      context: context,
      items: state.availableQualities
          .map(
            (e) => PopupMenuItem<dynamic>(
              child: ListTile(title: Text('${e.quality}p')),
              onTap: () => playerCtr.changeVideoQuality(e.quality),
            ),
          )
          .toList(),
      position: RelativeRect.fromSize(
        details.globalPosition & Size.zero,
        MediaQuery.of(context).size,
      ),
    );
  }

  Widget _bottomSheetTiles({
    required String title,
    required IconData icon,
    String? subText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(width: 20),
            Text(title),
            if (subText != null) const SizedBox(width: 10),
            if (subText != null)
              const SizedBox(
                height: 4,
                width: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            if (subText != null) const SizedBox(width: 6),
            if (subText != null)
              Text(
                subText,
                style: const TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
