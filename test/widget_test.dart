import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/main.dart';
import 'package:hotel_app/presentation/providers/auth/auth_provider.dart';

class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: false);
}

void main() {
  testWidgets('HotelApp smoke test — arranca sin errores',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => _FakeAuthNotifier()),
        ],
        child: const HotelApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(HotelApp), findsOneWidget);
  });
}
