import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Logical screen sizes every screen must survive.
const List<Size> kLayoutSizes = [
  Size(320, 568),
  Size(360, 640),
  Size(360, 800),
  Size(393, 852),
  Size(412, 915),
  Size(600, 960),
];

const List<double> kTextScales = [1.0, 1.5];

/// Typical Android insets: status bar on top, gesture bar at the bottom.
const EdgeInsets kSystemInsets = EdgeInsets.only(top: 24, bottom: 24);

/// Simulated soft-keyboard height for input screens.
const double kKeyboardHeight = 300;

/// Configures the test view to a logical [size] with system [insets] and
/// [textScale]. Resets automatically when the test ends.
void configureView(
  WidgetTester tester, {
  required Size size,
  double textScale = 1.0,
  EdgeInsets insets = kSystemInsets,
  double devicePixelRatio = 1.0,
  bool keyboard = false,
}) {
  final view = tester.view
    ..devicePixelRatio = devicePixelRatio
    ..physicalSize = size * devicePixelRatio
    ..padding = FakeViewPadding(
      top: insets.top * devicePixelRatio,
      bottom: insets.bottom * devicePixelRatio,
    )
    ..viewPadding = FakeViewPadding(
      top: insets.top * devicePixelRatio,
      bottom: insets.bottom * devicePixelRatio,
    )
    ..viewInsets = FakeViewPadding(
      bottom: keyboard ? kKeyboardHeight * devicePixelRatio : 0,
    );
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// Runs [body] once per size × text scale. Any exception (including a
/// RenderFlex overflow) fails the case. [keyboard] simulates an open soft
/// keyboard of [kKeyboardHeight].
void testLayoutMatrix(
  String description,
  Future<void> Function(WidgetTester tester) body, {
  List<Size> sizes = kLayoutSizes,
  List<double> textScales = kTextScales,
  EdgeInsets insets = kSystemInsets,
  bool keyboard = false,
}) {
  for (final size in sizes) {
    for (final scale in textScales) {
      final label =
          '${size.width.toInt()}x${size.height.toInt()} @${scale}x'
          '${keyboard ? ' +keyboard' : ''}';
      testWidgets('$description [$label]', (tester) async {
        configureView(
          tester,
          size: size,
          textScale: scale,
          insets: insets,
          keyboard: keyboard,
        );
        await body(tester);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
