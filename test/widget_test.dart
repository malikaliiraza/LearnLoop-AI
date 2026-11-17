import 'package:flutter_test/flutter_test.dart';
import 'package:learnloop_ai/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('home shows the app title and the sample notes',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const LearnLoopApp());
    await tester.pumpAndSettle();

    expect(find.text('LearnLoop AI'), findsWidgets);
    expect(find.text('Sample: Photosynthesis'), findsOneWidget);
    expect(find.text('Sample: Flutter Widgets'), findsOneWidget);
    expect(find.text('Start quiz'), findsNWidgets(2));
  });
}
