import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:na_posters_app/pages/welcome_page.dart';
import 'package:na_posters_app/firebase_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/firebase_core'),
          (MethodCall methodCall) async {
          if (methodCall.method == 'Firebase#initializeCore') {
            return [
              {
                'name': '[DEFAULT]',
                'options': {
                  'apiKey': '123',
                  'appId': '123',
                  'messagingSenderId': '123',
                  'projectId': '123',
                },
                'pluginConstants': {},
              }
            ];
          }
          return null;
        },
        );
  });

  testWidgets('WelcomePage shows welcome message', (WidgetTester tester) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await tester.pumpWidget(const MaterialApp(
      home: WelcomePage(),
    ));

    expect(find.text('Bem-vindo ao App de Cartazes de NA'), findsOneWidget);
  });
}
