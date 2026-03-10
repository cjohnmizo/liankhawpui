import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liankhawpui/core/config/env_config.dart';
import 'package:liankhawpui/core/services/supabase_service.dart';
import 'package:liankhawpui/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const bool _runSignupFlow = bool.fromEnvironment(
  'TEST_SIGNUP_FLOW',
  defaultValue: false,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Signup repository smoke test', (tester) async {
    await dotenv.load(fileName: '.env');
    EnvConfig.validateRequired();
    await SupabaseService.initialize();

    final repository = AuthRepository();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final email = 'signupcheck+$stamp@liankhawpui.local';

    await repository.signUpWithEmail(
      email: email,
      password: 'TestPass123!',
      data: {
        'full_name': 'Signup Check',
        'phone_number': '9876543210',
        'dob': '1990-01-01T00:00:00.000',
        'address': 'Test Address',
        'role': 'guest',
      },
    );

    await Supabase.instance.client.auth.signOut();
    expect(true, isTrue);
  }, skip: !_runSignupFlow);
}
