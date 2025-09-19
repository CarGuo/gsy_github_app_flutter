// ignore_for_file: unnecessary_string_escapes

import 'package:flutter/material.dart';

class JsonViewerWidget extends StatefulWidget {
  final Map<String, dynamic> jsonObj;
  final bool notRoot;

  const JsonViewerWidget(this.jsonObj, {super.key, this.notRoot = false});

  @override
  JsonViewerWidgetState createState() => JsonViewerWidgetState();
}

class JsonViewerWidgetState extends State<JsonViewerWidget> {
  Map<String, bool> openFlag = {};

  @override
  Widget build(BuildContext context) {
    if (widget.notRoot) {
      return Container(
          padding: const .only(left: 14.0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _getList()));
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: _getList());
  }

  _getList() {
    return [
      for (MapEntry entry in widget.jsonObj.entries) ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            isExtensible(entry.value)
                ? ((openFlag[entry.key] ?? false)
                    ? Icon(Icons.arrow_drop_down,
                        size: 14, color: Colors.grey[700])
                    : Icon(Icons.arrow_right, size: 14, color: Colors.grey[700]))
                : const Icon(
                    Icons.arrow_right,
                    color: Color.fromARGB(0, 0, 0, 0),
                    size: 14,
                  ),
            (isExtensible(entry.value) && isInkWell(entry.value))
                ? InkWell(
                    child: Text(entry.key,
                        style: TextStyle(color: Colors.purple[900])),
                    onTap: () {
                      setState(() {
                        openFlag[entry.key] = !(openFlag[entry.key] ?? false);
                      });
                    })
                : Text(entry.key,
                    style: TextStyle(
                        color: entry.value == null
                            ? .grey
                            : Colors.purple[900])),
            const Text(
              ':',
              style: TextStyle(color: .grey),
            ),
            const SizedBox(width: 3),
            getValueWidget(entry)
          ],
        ),
        const SizedBox(height: 4),
        ...?(openFlag[entry.key] ?? false) ? [getContentWidget(entry.value)] : null,
      ]
    ];
  }

  static getContentWidget(dynamic content) {
    if (content is List) {
      return JsonArrayViewerWidget(content, notRoot: true);
    } else {
      return JsonViewerWidget(content, notRoot: true);
    }
  }

  static isInkWell(dynamic content) {
    if (content == null) {
      return false;
    } else if (content is int) {
      return false;
    } else if (content is String) {
      return false;
    } else if (content is bool) {
      return false;
    } else if (content is double) {
      return false;
    } else if (content is List) {
      if (content.isEmpty) {
        return false;
      } else {
        return true;
      }
    }
    return true;
  }

  getValueWidget(MapEntry entry) {
    if (entry.value == null) {
      return const Expanded(
          child: Text(
        'undefined',
        style: TextStyle(color: .grey),
      ));
    } else if (entry.value is int) {
      return Expanded(
          child: Text(
        entry.value.toString(),
        style: const TextStyle(color: .teal),
      ));
    } else if (entry.value is String) {
      return Expanded(
          child: Text(
        // ignore: prefer_interpolation_to_compose_strings
        '${'\"' + entry.value}\"',
        style: const TextStyle(color: .redAccent),
      ));
    } else if (entry.value is bool) {
      return Expanded(
          child: Text(
        entry.value.toString(),
        style: const TextStyle(color: .purple),
      ));
    } else if (entry.value is double) {
      return Expanded(
          child: Text(
        entry.value.toString(),
        style: const TextStyle(color: .teal),
      ));
    } else if (entry.value is List) {
      if (entry.value.isEmpty) {
        return const Text(
          'Array[0]',
          style: TextStyle(color: Colors.grey),
        );
      } else {
        return InkWell(
            child: Text(
              'Array<${getTypeName(entry.value[0])}>[${entry.value.length}]',
              style: const TextStyle(color: Colors.grey),
            ),
            onTap: () {
              setState(() {
                openFlag[entry.key] = !(openFlag[entry.key] ?? false);
              });
            });
      }
    }
    return InkWell(
        child: const Text(
          'Object',
          style: TextStyle(color: Colors.grey),
        ),
        onTap: () {
          setState(() {
            openFlag[entry.key] = !(openFlag[entry.key] ?? false);
          });
        });
  }

  static isExtensible(dynamic content) {
    if (content == null) {
      return false;
    } else if (content is int) {
      return false;
    } else if (content is String) {
      return false;
    } else if (content is bool) {
      return false;
    } else if (content is double) {
      return false;
    }
    return true;
  }

  static getTypeName(dynamic content) {
    if (content is int) {
      return 'int';
    } else if (content is String) {
      return 'String';
    } else if (content is bool) {
      return 'bool';
    } else if (content is double) {
      return 'double';
    } else if (content is List) {
      return 'List';
    }
    return 'Object';
  }
}

class JsonArrayViewerWidget extends StatefulWidget {
  final List<dynamic> jsonArray;

  final bool? notRoot;

  const JsonArrayViewerWidget(this.jsonArray, {super.key, this.notRoot = false});

  @override
  _JsonArrayViewerWidgetState createState() =>
      _JsonArrayViewerWidgetState();
}

class _JsonArrayViewerWidgetState extends State<JsonArrayViewerWidget> {
  List<bool>? openFlag;

  @override
  Widget build(BuildContext context) {
    if (widget.notRoot ?? false) {
      return Container(
          padding: const .only(left: 14.0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _getList()));
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: _getList());
  }

  @override
  void initState() {
    super.initState();
    openFlag = List.filled(widget.jsonArray.length, false);
  }

  _getList() {
    List<Widget> list = [];
    int i = 0;
    for (dynamic content in widget.jsonArray) {
      bool ex = JsonViewerWidgetState.isExtensible(content);
      bool ink = JsonViewerWidgetState.isInkWell(content);
      list.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ex
              ? ((openFlag?[i] ?? false)
                  ? Icon(Icons.arrow_drop_down,
                      size: 14, color: Colors.grey[700])
                  : Icon(Icons.arrow_right, size: 14, color: Colors.grey[700]))
              : const Icon(
                  Icons.arrow_right,
                  color: Color.fromARGB(0, 0, 0, 0),
                  size: 14,
                ),
          (ex && ink)
              ? getInkWell(i)
              : Text('[$i]',
                  style: TextStyle(
                      color:
                          content == null ? .grey : Colors.purple[900])),
          const Text(
            ':',
            style: TextStyle(color: .grey),
          ),
          const SizedBox(width: 3),
          getValueWidget(content, i)
        ],
      ));
      list.add(const SizedBox(height: 4));
      if (openFlag?[i] ?? false) {
        list.add(JsonViewerWidgetState.getContentWidget(content));
      }
      i++;
    }
    return list;
  }

  getInkWell(int index) {
    return InkWell(
        child: Text('[$index]', style: TextStyle(color: Colors.purple[900])),
        onTap: () {
          setState(() {
            openFlag?[index] = !(openFlag?[index] ?? false);
          });
        });
  }

  getValueWidget(dynamic content, int index) {
    if (content == null) {
      return const Expanded(
          child: Text(
        'undefined',
        style: TextStyle(color: .grey),
      ));
    } else if (content is int) {
      return Expanded(
          child: Text(
        content.toString(),
        style: const TextStyle(color: .teal),
      ));
    } else if (content is String) {
      return Expanded(
          child: Text(
        '\"$content\"',
        style: const TextStyle(color: .redAccent),
      ));
    } else if (content is bool) {
      return Expanded(
          child: Text(
        content.toString(),
        style: const TextStyle(color: .purple),
      ));
    } else if (content is double) {
      return Expanded(
          child: Text(
        content.toString(),
        style: const TextStyle(color: .teal),
      ));
    } else if (content is List) {
      if (content.isEmpty) {
        return const Text(
          'Array[0]',
          style: TextStyle(color: Colors.grey),
        );
      } else {
        return InkWell(
            child: Text(
              'Array<${JsonViewerWidgetState.getTypeName(content)}>[${content.length}]',
              style: const TextStyle(color: Colors.grey),
            ),
            onTap: () {
              setState(() {
                openFlag?[index] = !(openFlag?[index] ?? false);
              });
            });
      }
    }
    return InkWell(
        child: const Text(
          'Object',
          style: TextStyle(color: Colors.grey),
        ),
        onTap: () {
          setState(() {
            openFlag?[index] = !(openFlag?[index] ?? false);
          });
        });
  }
}
