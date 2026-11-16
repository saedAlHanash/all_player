import 'dart:developer';

import '../all_player.dart';

void allPlayerLog(String message) =>
    AllPlayer.enableLogs ? log(message, name: 'ALL_PLAYER') : null;
