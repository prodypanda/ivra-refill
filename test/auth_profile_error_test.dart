import 'package:flutter_test/flutter_test.dart';
import 'package:ivra_refill/src/features/auth/auth_validation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('isTransientProfileError', () {
    test('treats network failures as transient', () {
      expect(
        isTransientProfileError(
            Exception('SocketException: Failed host lookup')),
        isTrue,
      );
      expect(
        isTransientProfileError(
            Exception('ClientException: Connection closed')),
        isTrue,
      );
      expect(isTransientProfileError(Exception('Request timed out')), isTrue);
    });

    test('treats expired/invalid access tokens as transient', () {
      expect(isTransientProfileError(Exception('JWT expired')), isTrue);
      expect(
        isTransientProfileError(const AuthException('Invalid token')),
        isTrue,
      );
    });

    test('treats a deactivated account as a genuine (non-transient) error', () {
      expect(
        isTransientProfileError(
          StateError('This account has been deactivated.'),
        ),
        isFalse,
      );
    });

    test('treats a missing profile row as a genuine (non-transient) error', () {
      expect(
        isTransientProfileError(
          Exception('PGRST116: JSON object requested, multiple (or no) rows '
              'returned'),
        ),
        isFalse,
      );
    });

    test('defaults unknown errors to non-transient', () {
      expect(isTransientProfileError(Exception('totally unexpected')), isFalse);
    });
  });
}
