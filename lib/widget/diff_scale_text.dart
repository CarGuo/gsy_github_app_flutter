import 'dart:math' as Math;

import 'package:flutter/material.dart';

class DiffScaleText extends StatefulWidget {
  final String? text;
  final TextStyle? textStyle;

  const DiffScaleText({super.key, required this.text, this.textStyle})
      : assert(text != null);

  @override
  _DiffScaleTextState createState() => _DiffScaleTextState();
}

class _DiffScaleTextState extends State<DiffScaleText>
    with TickerProviderStateMixin<DiffScaleText> {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _animationController.addStatusListener((status) {});
  }

  @override
  void didUpdateWidget(DiffScaleText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      if (!_animationController.isAnimating) {
        _animationController.value = 0;
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle? textStyle = widget.textStyle ?? const TextStyle(
            fontSize: 20,
            color: Colors.white,
          );
    return AnimatedBuilder(
      animation: _animationController,
      builder: (BuildContext context, Widget? child) {
        return RepaintBoundary(
            child: CustomPaint(
          foregroundPainter: _DiffText(
              text: widget.text ?? "",
              textStyle: textStyle,
              progress: _animationController.value),
          child: Text(widget.text ?? "",
              style: textStyle.merge(const TextStyle(color: Color(0x00000000))),
              maxLines: 1,
              textDirection: TextDirection.ltr),
        ));
      },
    );
  }
}

class _DiffText extends CustomPainter {
  final String? text;
  final TextStyle? textStyle;
  final double progress;
  String? _oldText;
  List<_TextLayoutInfo> _textLayoutInfo = [];
  List<_TextLayoutInfo> _oldTextLayoutInfo = [];

  _DiffText({required this.text, required this.textStyle, this.progress = 1})
      : assert(text != null),
        assert(textStyle != null);

  @override
  void paint(Canvas canvas, Size size) {
    double percent = Math.max(0, Math.min(1, progress));
    if (_textLayoutInfo.isEmpty) {
      calculateLayoutInfo(text ?? "", _textLayoutInfo);
    }
    canvas.save();
    if (_oldTextLayoutInfo.isNotEmpty) {
      for (_TextLayoutInfo oldTextLayoutInfo in _oldTextLayoutInfo) {
        if (oldTextLayoutInfo.needMove) {
          double p = percent * 2;
          p = p > 1 ? 1 : p;
          drawText(
              canvas,
              oldTextLayoutInfo.text,
              1,
              1,
              Offset(
                  oldTextLayoutInfo.offsetX! -
                      (oldTextLayoutInfo.offsetX! - oldTextLayoutInfo.toX!) *
                          p,
                  oldTextLayoutInfo.offsetY),
              oldTextLayoutInfo);
        } else {
          drawText(
              canvas,
              oldTextLayoutInfo.text,
              1 - percent,
              percent,
              Offset(oldTextLayoutInfo.offsetX!, oldTextLayoutInfo.offsetY),
              oldTextLayoutInfo);
        }
      }
    } else {
      //no oldText
      percent = 1;
    }
    for (_TextLayoutInfo textLayoutInfo in _textLayoutInfo) {
      if (!textLayoutInfo.needMove) {
        drawText(
            canvas,
            textLayoutInfo.text,
            percent,
            percent,
            Offset(textLayoutInfo.offsetX!, textLayoutInfo.offsetY),
            textLayoutInfo);
      }
    }
    canvas.restore();
  }

  void drawText(Canvas canvas, String? text, double textScaleFactor,
      double alphaFactor, Offset offset, _TextLayoutInfo textLayoutInfo) {
    var textPaint = Paint();
    if (alphaFactor == 1) {
      textPaint.color = textStyle!.color!;
    } else {
      textPaint.color = textStyle!.color!
          .withAlpha((textStyle!.color!.alpha * alphaFactor).floor());
    }
    var textPainter = TextPainter(
        text: TextSpan(
            text: text,
            style: textStyle?.merge(TextStyle(
                color: null,
                foreground: textPaint,
                textBaseline: TextBaseline.ideographic))),
        textDirection: TextDirection.ltr);
    textPainter.textAlign = TextAlign.center;
    textPainter.textScaler = TextScaler.linear(textScaleFactor);
    textPainter.textDirection = TextDirection.ltr;
    textPainter.layout();
    textPainter.paint(
        canvas,
        Offset(offset.dx,
            offset.dy + (textLayoutInfo.height - textPainter.height) / 2));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is _DiffText) {
      String oldFrameText = oldDelegate.text ?? "";
      if (oldFrameText == text) {
        _oldText = oldDelegate._oldText;
        _oldTextLayoutInfo = oldDelegate._oldTextLayoutInfo;
        _textLayoutInfo = oldDelegate._textLayoutInfo;
        if (progress == oldDelegate.progress) {
          return false;
        }
      } else {
        _oldText = oldDelegate.text;
        calculateLayoutInfo(text ?? "", _textLayoutInfo);
        calculateLayoutInfo(_oldText!, _oldTextLayoutInfo);
        calculateMove();
      }
    }
    return true;
  }

  void calculateLayoutInfo(String text, List<_TextLayoutInfo> list) {
    list.clear();

    TextPainter textPainter = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1);
    textPainter.layout();
    for (int i = 0; i < text.length; i++) {
      var forCaret =
          textPainter.getOffsetForCaret(TextPosition(offset: i), Rect.zero);
      var offsetX = forCaret.dx;
      if (i > 0 && offsetX == 0) {
        break;
      }
      var textLayoutInfo = _TextLayoutInfo();
      textLayoutInfo.text = text.substring(i, i + 1);
      textLayoutInfo.offsetX = offsetX;
      textLayoutInfo.offsetY = forCaret.dy;
      textLayoutInfo.width = 0;
      textLayoutInfo.height = textPainter.height;
      textLayoutInfo.baseline =
          textPainter.computeDistanceToActualBaseline(TextBaseline.ideographic);
      list.add(textLayoutInfo);
    }
  }

  void calculateMove() {
    if (_oldTextLayoutInfo.isEmpty) {
      return;
    }
    if (_textLayoutInfo.isEmpty) {
      return;
    }

    for (_TextLayoutInfo oldText in _oldTextLayoutInfo) {
      for (_TextLayoutInfo text in _textLayoutInfo) {
        if (!text.needMove && !oldText.needMove && text.text == oldText.text) {
          text.fromX = oldText.offsetX;
          oldText.toX = text.offsetX;
          text.needMove = true;
          oldText.needMove = true;
        }
      }
    }
  }
}

class _TextLayoutInfo {
  String? text;
  double? offsetX;
  late double offsetY;
  double? baseline;
  double? width;
  late double height;
  double? fromX = 0;
  double? toX = 0;
  bool needMove = false;
}
