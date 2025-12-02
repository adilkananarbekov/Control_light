import 'package:flutter/material.dart';

class LightBlock {
  final String id;
  final String name;
  final Color accent;
  final List<bool> lights;

  LightBlock({
    required this.id,
    required this.name,
    required this.accent,
    required this.lights,
  });

  LightBlock copyWith({List<bool>? lights}) {
    return LightBlock(
      id: id,
      name: name,
      accent: accent,
      lights: lights ?? this.lights,
    );
  }
}
