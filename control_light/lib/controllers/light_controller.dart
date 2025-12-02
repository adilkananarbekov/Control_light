import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/light_block.dart';
import '../services/bluetooth_manager.dart';

class LightController extends ChangeNotifier {
  LightController(this.bluetooth) {
    _blocks = [
      LightBlock(
        id: 'block-1',
        name: 'Block A',
        accent: AppColors.accentCyan,
        lights: List<bool>.filled(4, false),
      ),
      LightBlock(
        id: 'block-2',
        name: 'Block B',
        accent: AppColors.accentPurple,
        lights: List<bool>.filled(4, false),
      ),
      LightBlock(
        id: 'block-3',
        name: 'Block C',
        accent: AppColors.accentGreen,
        lights: List<bool>.filled(4, false),
      ),
    ];
  }

  final BluetoothManager bluetooth;
  late List<LightBlock> _blocks;

  List<LightBlock> get blocks => List.unmodifiable(_blocks);

  void toggle(String blockId, int index, bool value) {
    final blockIndex = _blocks.indexWhere((b) => b.id == blockId);
    if (blockIndex == -1 || index < 0 || index > 3) return;
    final block = _blocks[blockIndex];
    final lights = List<bool>.from(block.lights);
    lights[index] = value;
    _blocks[blockIndex] = block.copyWith(lights: lights);
    bluetooth.sendLightCommand(blockId, index, value);
    notifyListeners();
  }

  void toggleWholeBlock(String blockId, bool value) {
    final blockIndex = _blocks.indexWhere((b) => b.id == blockId);
    if (blockIndex == -1) return;
    final block = _blocks[blockIndex];
    _blocks[blockIndex] = block.copyWith(lights: List<bool>.filled(4, value));
    for (int i = 0; i < 4; i++) {
      bluetooth.sendLightCommand(blockId, i, value);
    }
    notifyListeners();
  }

  void turnAll(bool value) {
    for (final block in _blocks) {
      toggleWholeBlock(block.id, value);
    }
  }
}
