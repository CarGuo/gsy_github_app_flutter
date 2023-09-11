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
    return LoopAnimationBuilder<int>(
      tween: ConstantTween(1),
      duration: Duration(seconds: 1),
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
  late Animatable<Movie> tween;
  late Duration startTime;
  final duration = 600.milliseconds;

  MoleParticle() {
    final random = Random();
    double x = (100 + 200) * random.nextDouble() * (random.nextBool() ? 1 : -1);
    double y = (100 + 200) * random.nextDouble() * (random.nextBool() ? 1 : -1);

    tween = MovieTween()
      ..tween(_MoleProps.x, Tween(begin: 0.0, end: x), duration: 2.seconds)
      ..tween(_MoleProps.y, Tween(begin: 0.0, end: y), duration: 2.seconds)
      ..tween(_MoleProps.scale, Tween(begin: 1.0, end: 0.0),
          duration: 2.seconds);

    startTime = DateTime.now().duration();
  }

  Widget buildWidget() {
    final Movie values = tween.transform(progress());
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
