import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ivra_refill/src/data/offline/network_error_classifier.dart';

void main() {
  group('NetworkErrorClassifier', () {
    group('isOffline', () {
      test('returns true for SocketException', () {
        expect(NetworkErrorClassifier.isOffline(const SocketException('test')), isTrue);
      });

      test('returns true for TimeoutException', () {
        expect(NetworkErrorClassifier.isOffline(TimeoutException('test')), isTrue);
      });

      test('returns true for HttpException', () {
        expect(NetworkErrorClassifier.isOffline(const HttpException('test')), isTrue);
      });

      test('returns true for ClientException', () {
        expect(NetworkErrorClassifier.isOffline(ClientException('test')), isTrue);
      });

      test('returns true for PostgrestException without code', () {
        expect(NetworkErrorClassifier.isOffline(const PostgrestException(message: 'test')), isTrue);
      });

      test('returns false for PostgrestException with code', () {
        expect(NetworkErrorClassifier.isOffline(const PostgrestException(message: 'test', code: 'PGRST301')), isFalse);
      });

      test('returns false for other exceptions', () {
        expect(NetworkErrorClassifier.isOffline(Exception('test')), isFalse);
      });
    });

    group('isRetriable', () {
      test('returns true for offline errors', () {
        expect(NetworkErrorClassifier.isRetriable(const SocketException('test')), isTrue);
      });

      test('returns true for AuthException', () {
        expect(NetworkErrorClassifier.isRetriable(const AuthException('test')), isTrue);
      });

      test('returns true for PostgrestException with PGRST301 code (JWT expired)', () {
        expect(NetworkErrorClassifier.isRetriable(const PostgrestException(message: 'test', code: 'PGRST301')), isTrue);
      });

      test('returns false for PostgrestException with other codes', () {
        expect(NetworkErrorClassifier.isRetriable(const PostgrestException(message: 'test', code: 'PGRST116')), isFalse);
      });

      test('returns false for other exceptions', () {
        expect(NetworkErrorClassifier.isRetriable(Exception('test')), isFalse);
      });
    });

    group('isPermanent', () {
      test('returns true for non-retriable errors', () {
        expect(NetworkErrorClassifier.isPermanent(Exception('test')), isTrue);
        expect(NetworkErrorClassifier.isPermanent(const PostgrestException(message: 'test', code: 'PGRST116')), isTrue);
      });

      test('returns false for retriable errors', () {
        expect(NetworkErrorClassifier.isPermanent(const SocketException('test')), isFalse);
        expect(NetworkErrorClassifier.isPermanent(const AuthException('test')), isFalse);
        expect(NetworkErrorClassifier.isPermanent(const PostgrestException(message: 'test', code: 'PGRST301')), isFalse);
      });
    });
  });
}
