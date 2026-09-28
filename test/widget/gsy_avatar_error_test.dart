import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/widget/gsy_user_icon_widget.dart';

void main() {
  testWidgets(
    'failed avatar stays in its declared frame without a Flutter error',
    (tester) async {
      // flutter_test rejects HTTP images (400); this verifies the failure branch,
      // not successful loading or real authenticated business data.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                GSYUserIconWidget(
                  image: 'https://example.invalid/avatar.png',
                  width: 80,
                  height: 80,
                  padding: EdgeInsets.zero,
                  onPressed: () {},
                ),
                const Expanded(child: Text('Account identity')),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(GSYUserIconWidget)),
        const Size(80, 80),
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName == GSYICons.DEFAULT_USER_ICON,
        ),
        findsWidgets,
      );
      expect(find.text('Account identity'), findsOneWidget);
    },
  );
}
