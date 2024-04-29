import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DemoTextFieldPage extends StatefulWidget {
  @override
  _DemoTextFieldPageState createState() => _DemoTextFieldPageState();
}

class _DemoTextFieldPageState extends State<DemoTextFieldPage> {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("DemoTextFieldPage"),
      ),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: TextField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          focusNode: focusNode,
          decoration: const InputDecoration(
            hintText: "请输入密码",
            icon: Icon(Icons.keyboard),
            prefix: Icon(Icons.person),
            suffix: Icon(Icons.remove_red_eye),
            labelText: "labelText",
            helperText: "helperText",
            counterText: "counterText",
            enabledBorder: OutlineInputBorder(
              /*边角*/
              borderRadius: BorderRadius.all(
                Radius.circular(10), //边角为30
              ),
              borderSide: BorderSide(
                color: Colors.blue, //边线颜色为黄色
                width: 2, //边线宽度为2
              ),
            ),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
              color: Colors.black,
              width: 5,
            )),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.text = "";
          FocusScope.of(context).requestFocus(FocusNode());
        },
      ),
    );
  }
}
