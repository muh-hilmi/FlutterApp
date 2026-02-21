import 'package:mocktail/mocktail.dart';
import 'package:anigmaa/core/services/auth_service.dart';
import 'package:anigmaa/core/services/google_auth_service.dart';
import 'package:anigmaa/data/datasources/auth_remote_datasource.dart';
import 'package:anigmaa/data/models/user_model.dart';
import 'package:anigmaa/domain/entities/user.dart';

// ─── Mock Classes ────────────────────────────────────────────────────────────

class MockAuthService extends Mock implements AuthService {}

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockGoogleAuthService extends Mock implements GoogleAuthService {}

// ─── Fake Data Factories ─────────────────────────────────────────────────────

/// Minimal valid UserModel untuk dipakai di test
UserModel fakeUser({
  String id = 'user-123',
  String name = 'Test User',
  String email = 'test@example.com',
  String? dateOfBirth,
  String? location,
}) {
  return UserModel(
    id: id,
    name: name,
    email: email,
    createdAt: DateTime(2025, 1, 1),
    settings: const UserSettings(),
    stats: const UserStats(),
    privacy: const UserPrivacy(),
    dateOfBirth: dateOfBirth != null ? DateTime.parse(dateOfBirth) : null,
    location: location,
  );
}

/// User yang sudah complete profile (punya DOB + location)
UserModel fakeCompleteUser() => fakeUser(
  dateOfBirth: '1995-06-15',
  location: 'Jakarta, Indonesia',
);

/// User yang belum complete profile (tidak ada DOB)
UserModel fakeIncompleteUser() => fakeUser();
