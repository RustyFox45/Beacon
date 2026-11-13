import 'package:flutter/material.dart';

class BeaconIcon extends StatelessWidget {
  final double size;

  const BeaconIcon({
    super.key,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/beacon_lantern_official.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
