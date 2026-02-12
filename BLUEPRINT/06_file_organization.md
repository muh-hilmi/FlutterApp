# 06. FILE ORGANIZATION

File structure and naming conventions.

---

## PROJECT STRUCTURE

```
anigmaa/
├── lib/
│   ├── core/                   # Shared utilities
│   │   ├── config/            # App configuration
│   │   ├── constants/         # App constants
│   │   ├── errors/            # Custom exceptions
│   │   ├── services/          # DI, storage, API client
│   │   ├── theme/             # App theme (colors, fonts)
│   │   └── utils/             # Helper functions
│   │
│   ├── data/                  # Data layer
│   │   ├── datasources/       # API, local storage
│   │   │   ├── remote/        # Remote API clients
│   │   │   └── local/         # Local storage
│   │   ├── models/            # DTOs (json_serializable)
│   │   └── repositories/      # Repository implementations
│   │
│   ├── domain/                # Business logic (pure Dart)
│   │   ├── entities/          # Core business objects
│   │   ├── repositories/      # Repository interfaces
│   │   └── usecases/          # Business operations
│   │
│   └── presentation/          # UI layer
│       ├── bloc/              # BLoC state management
│       │   ├── auth/
│       │   ├── user/
│       │   ├── event/
│       │   ├── post/
│       │   └── ticket/
│       ├── pages/             # Full screens
│       │   ├── splash/
│       │   ├── auth/
│       │   ├── home/
│       │   ├── event/
│       │   ├── profile/
│       │   ├── settings/
│       │   └── server_unavailable/
│       ├── widgets/           # Reusable components
│       │   ├── common/         # Buttons, cards, inputs
│       │   ├── posts/          # Post-related widgets
│       │   └── profile/        # Profile-related widgets
│       └── routes/            # Navigation config
│
├── test/                      # Unit & widget tests
│   ├── unit/                  # Unit tests
│   ├── widget/                # Widget tests
│   └── mocks/                 # Mock classes
│
└── test_driver/               # E2E tests
    ├── appium_setup.dart
    ├── tests/
    │   ├── auth_test.dart
    │   ├── event_test.dart
    │   └── feed_test.dart
    └── helpers/
        └── test_helpers.dart
```

---

## FILE NAMING CONVENTIONS

### Screens

**Pattern**: `{feature}_screen.dart`

```
lib/presentation/pages/
├── splash/splash_screen.dart
├── auth/login_screen.dart
├── auth/onboarding_screen.dart
├── auth/complete_profile_screen.dart
├── home/home_screen.dart
├── discover/discover_screen.dart
├── event/event_detail_screen.dart
├── profile/profile_screen.dart
├── profile/edit_profile_screen.dart
└── settings/settings_screen.dart
```

### BLoCs

**Pattern**: `{feature}_bloc.dart`

```
lib/presentation/bloc/
├── auth/
│   ├── auth_bloc.dart
│   ├── auth_event.dart
│   └── auth_state.dart
├── user/
│   ├── user_bloc.dart
│   ├── user_event.dart
│   └── user_state.dart
└── feed/
    ├── feed_bloc.dart
    ├── feed_event.dart
    └── feed_state.dart
```

### Use Cases

**Pattern**: `{use_case}.dart`

```
lib/domain/usecases/
├── auth/
│   ├── google_sign_in.dart
│   ├── logout.dart
│   └── refresh_token.dart
├── user/
│   ├── get_current_user.dart
│   ├── update_profile.dart
│   └── follow_user.dart
└── event/
    ├── get_events.dart
    ├── get_event_detail.dart
    └── purchase_ticket.dart
```

### Repositories

**Domain** (interfaces):
```
lib/domain/repositories/
├── auth_repository.dart
├── user_repository.dart
├── event_repository.dart
└── post_repository.dart
```

**Data** (implementations):
```
lib/data/repositories/
├── auth_repository_impl.dart
├── user_repository_impl.dart
├── event_repository_impl.dart
└── post_repository_impl.dart
```

### Models

**Pattern**: `{entity}_model.dart`

```
lib/data/models/
├── auth_model.dart
├── user_model.dart
├── event_model.dart
├── post_model.dart
└── ticket_model.dart
```

---

## IMPORT ORDER

**Standard order**:

```dart
// 1. Dart core
import 'dart:async';
import 'dart:convert';

// 2. Flutter
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// 3. Packages
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';

// 4. Project (absolute)
import '../../../core/services/auth_service.dart';
import '../../../domain/entities/user.dart';
import '../../../injection_container.dart' as di;

// 5. Relative (same folder)
import 'user_state.dart';
import 'user_event.dart';
```

---

## EXPORT CONVENTIONS

### Barrel Files (index.dart)

**Create for each major folder**:

```dart
// lib/presentation/pages/auth/auth_index.dart
export 'login_screen.dart';
export 'onboarding_screen.dart';
export 'complete_profile_screen.dart';
```

**Usage**:
```dart
import '../../../presentation/pages/auth/auth_index.dart';
```

---

## FEATURE FOLDER STRUCTURE

When adding a new feature:

```
lib/
├── domain/
│   └── {feature}/
│       ├── entities/
│       ├── repositories/
│       └── usecases/
├── data/
│   └── {feature}/
│       ├── datasources/
│       ├── models/
│       └── repositories/
└── presentation/
    └── {feature}/
        ├── bloc/
        ├── pages/
        └── widgets/
```

---

## CODE ORGANIZATION RULES

### Rule 1: Clean Architecture Layers

```
presentation → domain → data
     ↑           ↓        ↑
     └───────────────────┘
```

**NEVER**:
- Import from data → presentation (bypass domain)
- Import from presentation → data

### Rule 2: Dependency Direction

```
outer → inner
├── presentation (outer)
├── domain (middle)
└── data (inner)
```

**Allowed imports**:
- presentation → domain ✓
- domain → data ✓
- data → domain ✗
- data → presentation ✗

### Rule 3: Platform Interface

**Keep platform-specific code in `core/utils/`**:

```
lib/core/utils/
├── location_utils.dart      # Geolocator wrapper
├── image_picker_utils.dart  # Image picker wrapper
└── permission_utils.dart    # Permission wrapper
```

---

## WIDGET ORGANIZATION

### Widget Categories

```
lib/presentation/widgets/
├── common/              # Generic widgets
│   ├── buttons/
│   │   ├── primary_button.dart
│   │   └── secondary_button.dart
│   ├── inputs/
│   │   ├── text_field.dart
│   │   └── dropdown_field.dart
│   └── loading/
│       ├── loading_spinner.dart
│       └── error_display.dart
├── posts/               # Post-specific
│   ├── post_card.dart
│   └── post_actions.dart
└── profile/             # Profile-specific
    ├── profile_header.dart
    └── profile_stats.dart
```

### Widget Naming

- **Screen widgets**: `{Name}Screen`
- **Full page widgets**: `{Name}Page`
- **Reusable components**: `{Name}Widget` or `{Name}Card`
- **Stateless**: `const` when possible

---

## CONSTANTS ORGANIZATION

```
lib/core/constants/
├── app_constants.dart     # App-wide constants
├── api_constants.dart     # API endpoints
├── storage_constants.dart # Local storage keys
└── ui_constants.dart      # UI dimensions, times
```

### Example

```dart
// app_constants.dart
class AppConstants {
  static const String appName = 'Anigmaa';
  static const String appVersion = '1.0.0';
  static const Duration apiTimeout = Duration(seconds: 10);
}

// api_constants.dart
class ApiConstants {
  static const String baseUrl = 'http://localhost:8123';
  static const String apiVersion = 'v1';
  static const String usersEndpoint = '/users';
}

// storage_constants.dart
class StorageConstants {
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String onboardingSeenKey = 'onboarding_seen';
}
```

---

## CONFIG ORGANIZATION

```
lib/core/config/
├── env_config.dart         # Environment config
├── route_config.dart        # Route definitions
└── theme_config.dart        # App theme
```

### Environment Config

```dart
enum Environment { dev, staging, prod }

class EnvConfig {
  static Environment currentEnvironment = Environment.dev;

  static String get baseUrl {
    switch (currentEnvironment) {
      case Environment.dev:
        return 'http://localhost:8123';
      case Environment.staging:
        return 'https://api-staging.anigmaa.com';
      case Environment.prod:
        return 'https://api.anigmaa.com';
    }
  }
}
```

---

## TESTING STRUCTURE

```
test/
├── unit/                   # Unit tests
│   ├── domain/
│   │   ├── usecases/
│   │   └── repositories/
│   └── data/
│       └── models/
├── widget/                 # Widget tests
│   ├── pages/
│   └── widgets/
├── mocks/                  # Mock classes
│   └── mock_repositories.dart
└── test_helpers.dart       # Test utilities
```

---

## IMPLEMENTATION CHECKLIST

When adding a new feature:

- [ ] Create entity in `domain/entities/`
- [ ] Create repository interface in `domain/repositories/`
- [ ] Create use case in `domain/usecases/`
- [ ] Create model in `data/models/`
- [ ] Create data source in `data/datasources/`
- [ ] Create repository impl in `data/repositories/`
- [ ] Create BLoC in `presentation/bloc/`
- [ ] Create screen in `presentation/pages/`
- [ ] Create widgets in `presentation/widgets/`
- [ ] Register in DI container
- [ ] Add route in `routes/`
- [ ] Write unit tests
- [ ] Write widget tests
- [ ] Add test keys

---

**Remember**: File organization = Code discoverability = Agent efficiency
