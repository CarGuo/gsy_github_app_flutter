import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/widget/GSYCardItem.dart';

/**
 * 详情issue列表头部，PreferredSizeWidget
 * Created by guoshuyu
 * Date: 2018-07-19
 */

typedef void SelectItemChanged<int>(int value);

class GSYSelectItemWidget extends StatefulWidget implements PreferredSizeWidget {
  final List<String> itemNames;

  final SelectItemChanged selectItemChanged;

  final double elevation;

  final double height;

  final EdgeInsets margin;

  GSYSelectItemWidget(
    this.itemNames,
    this.selectItemChanged, {
    this.elevation = 5.0,
    this.height = 70.0,
    this.margin = const EdgeInsets.all(10.0),
  });

  @override
  _GSYSelectItemWidgetState createState() => _GSYSelectItemWidgetState(selectItemChanged, itemNames, elevation, margin);

  @override
  Size get preferredSize {
    return new Size.fromHeight(height);
  }
}

class _GSYSelectItemWidgetState extends State<GSYSelectItemWidget> {
  int selectIndex = 0;

  final List<String> itemNames;

  final SelectItemChanged selectItemChanged;

  final double elevation;

  final EdgeInsets margin;

  _GSYSelectItemWidgetState(this.selectItemChanged, this.itemNames, this.elevation, this.margin);

  _renderItem(String name, int index) {
    var style = index == selectIndex ? GSYConstant.middleTextWhite : GSYConstant.middleSubText;
    return new Expanded(
      child: RawMaterialButton(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          constraints: const BoxConstraints(minWidth: 0.0, minHeight: 0.0),
          padding: EdgeInsets.all(10.0),
          child: new Text(
            name,
            style: style,
            textAlign: TextAlign.center,
          ),
          onPressed: () {
            if (selectItemChanged != null) {
              if (selectIndex != index) {
                selectItemChanged(index);
              }
            }
            setState(() {
              selectIndex = index;
            });
          }),
    );
  }

  _renderList() {
    List<Widget> list = new List();
    for (int i = 0; i < itemNames.length; i++) {
      if (i == itemNames.length - 1) {
        list.add(_renderItem(itemNames[i], i));
      } else {
        list.add(_renderItem(itemNames[i], i));
        list.add(new Container(width: 1.0, height: 25.0, color: Color(GSYColors.subLightTextColor)));
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return new GSYCardItem(
        elevation: elevation,
        margin: margin,
        color: Color(GSYColors.primaryValue),
        shape: new RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        ),
        child: new Row(
          children: _renderList(),
        ));
  }
}
