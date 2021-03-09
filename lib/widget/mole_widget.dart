import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:supercharged/supercharged.dart';

class Mole extends StatefulWidget {
  @override
  _MoleState createState() => _MoleState();
}

class _MoleState extends State<Mole> {
  final List<MoleParticle> particles = [];
  bool _moleIsVisible = false;

  @override
  void initState() {
    _restartMole();
    Future.delayed(1200.milliseconds, () {
      _hitMole();
    });
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

  Widget _buildMole() {
    _manageParticleLifecycle();
    return LoopAnimation<int>(
      tween: ConstantTween(1),
      builder: (context, child, value) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (_moleIsVisible)
              GestureDetector(onTap: () => _hitMole(), child: _mole()),
            ...particles.map((it) => it.buildWidget())
          ],
        );
      },
    );
  }

  Widget _mole() {
    return Container(
      decoration: BoxDecoration(
          color: GSYColors.primaryValue,
          borderRadius: BorderRadius.circular(50)),
    );
  }

  _hitMole() {
    Iterable.generate(50).forEach((i) => particles.add(MoleParticle()));
  }

  void _restartMole() async {
    var respawnTime = (2000 + Random().nextInt(8000)).milliseconds;
    await Future.delayed(respawnTime);
    _setMoleVisible(true);

    var timeVisible = (500 + Random().nextInt(1500)).milliseconds;
    await Future.delayed(timeVisible);
    _setMoleVisible(false);

    _restartMole();
  }

  _manageParticleLifecycle() {
    particles.removeWhere((particle) {
      return particle.progress() == 1;
    });
  }

  void _setMoleVisible(bool visible) {
    setState(() {
      _moleIsVisible = visible;
    });
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }
}

enum _MoleProps { x, y, scale }

class MoleParticle {
  Animatable<MultiTweenValues<_MoleProps>> tween;
  Duration startTime;
  final duration = 600.milliseconds;

  MoleParticle() {
    final random = Random();
    final x = (100 + 200) * random.nextDouble() * (random.nextBool() ? 1 : -1);
    final y = (100 + 200) * random.nextDouble() * (random.nextBool() ? 1 : -1);

    tween = MultiTween<_MoleProps>()
      ..add(_MoleProps.x, 0.0.tweenTo(x))
      ..add(_MoleProps.y, 0.0.tweenTo(y))
      ..add(_MoleProps.scale, 1.0.tweenTo(0.0));

    startTime = DateTime.now().duration();
  }

  Widget buildWidget() {
    final MultiTweenValues<_MoleProps> values = tween.transform(progress());
    var alpha = (255 * progress()).toInt();
    return Positioned(
      left: values.get(_MoleProps.x),
      top: values.get(_MoleProps.y),
      child: Transform.scale(
        scale: values.get(_MoleProps.scale),
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
              color: GSYColors.primaryValue.withAlpha(alpha),
              borderRadius: BorderRadius.circular(50)),
        ),
      ),
    );
  }

  double progress() {
    return ((DateTime.now().duration() - startTime) / duration)
        .clamp(0.0, 1.0)
        .toDouble();
  }
}
