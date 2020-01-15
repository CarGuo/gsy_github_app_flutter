import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:simple_animations/simple_animations/animation_progress.dart';
import 'package:simple_animations/simple_animations/multi_track_tween.dart';
import 'package:simple_animations/simple_animations/rendering.dart';

class Mole extends StatefulWidget {
  @override
  _MoleState createState() => _MoleState();
}

class _MoleState extends State<Mole> {
  final List<MoleParticle> particles = [];

  @override
  void initState() {
    _restartMole();
    _hitMole(Duration(milliseconds: 1000));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      child: _buildMole(),
    );
  }

  Rendering _buildMole() {
    return Rendering(
      onTick: (time) => _manageParticleLifecycle(time),
      builder: (context, time) {
        return Stack(
          overflow: Overflow.visible,
          children: [...particles.map((it) => it.buildWidget(time))],
        );
      },
    );
  }

  _hitMole(Duration time) {
    Iterable.generate(50).forEach((i) => particles.add(MoleParticle(time)));
  }

  void _restartMole() async {
    var respawnTime = Duration(milliseconds: 2000 + Random().nextInt(8000));
    await Future.delayed(respawnTime);

    var timeVisible = Duration(milliseconds: 500 + Random().nextInt(1500));
    await Future.delayed(timeVisible);

    if (mounted) {
      _restartMole();
    }
  }

  _manageParticleLifecycle(Duration time) {
    particles.removeWhere((particle) {
      return particle.progress.progress(time) == 1;
    });
  }
}

class MoleParticle {
  Animatable tween;
  AnimationProgress progress;

  MoleParticle(Duration time) {
    final random = Random();
    final x = (100 + 200) * random.nextDouble() * (random.nextBool() ? 1 : -1);
    final y = (100 + 200) * random.nextDouble() * (random.nextBool() ? 1 : -1);

    tween = MultiTrackTween([
      Track("x").add(Duration(seconds: 1), Tween(begin: 0.0, end: x)),
      Track("y").add(Duration(seconds: 1), Tween(begin: 0.0, end: y)),
      Track("scale").add(Duration(seconds: 1), Tween(begin: 1.0, end: 0.0))
    ]);
    progress = AnimationProgress(
        startTime: time, duration: Duration(milliseconds: 600));
  }

  buildWidget(Duration time) {
    final animation = tween.transform(progress.progress(time));
    var alpha = (255 * progress.progress(time)).toInt();
    return Positioned(
      left: animation["x"],
      top: animation["y"],
      child: Transform.scale(
        scale: animation["scale"],
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
              color: GSYColors.primaryValue
                  .withAlpha(alpha),
              borderRadius: BorderRadius.circular(50)),
        ),
      ),
    );
  }
}
