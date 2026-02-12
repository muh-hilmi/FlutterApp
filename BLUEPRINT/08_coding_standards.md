# 08. CODING STANDARDS

Mandatory patterns and conventions.

---

## BLoC PATTERN (MANDATORY)

### Always Use BLoC for State Management

```dart
// ❌ NEVER
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  int _counter = 0;
  void _increment() => setState(() => _counter++);
}

// ✅ ALWAYS
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MyBloc()..add(LoadData()),
      child: BlocBuilder<MyBloc, MyState>(
        builder: (context, state) {
          if (state is Loading) {
            return LoadingWidget();
          }
          if (state is Loaded) {
            return ContentWidget(data: state.data);
          }
          return ErrorWidget();
        },
      ),
    );
  }
}
```

### BLoC Structure

```dart
// 1. Events
abstract class MyEvent extends Equatable {
  const MyEvent();

  @override
  List<Object> get props => [];
}

class LoadData extends MyEvent {}
class RefreshData extends MyEvent {}

// 2. States
abstract class MyState extends Equatable {
  const MyState();

  @override
  List<Object> get props => [];
}

class MyInitial extends MyState {}
class MyLoading extends MyState {}
class MyLoaded extends MyState {
  final Data data;
  const MyLoaded(this.data);

  @override
  List<Object> get props => [data];
}
class MyError extends MyState {
  final String message;
  const MyError(this.message);

  @override
  List<Object> get props => [message];
}

// 3. BLoC
class MyBloc extends Bloc<MyEvent, MyState> {
  final GetDataUseCase useCase;

  MyBloc({required this.useCase}) : super(MyInitial()) {
    on<LoadData>(_onLoadData);
    on<RefreshData>(_onRefreshData);
  }

  Future<void> _onLoadData(LoadData event, Emitter emit) async {
    emit(MyLoading());
    final result = await useCase();
    result.fold(
      (error) => emit(MyError(error.message)),
      (data) => emit(MyLoaded(data)),
    );
  }
}
```

### BlocProvider Pattern

```dart
// In main.dart or route
BlocProvider(
  create: (context) => MyBloc(useCase: sl()),
  child: MyScreen(),
)

// In screen
context.read<MyBloc>().add(LoadData());
```

---

## NAVIGATION (go_router ONLY)

### Use go_router for ALL Navigation

```dart
// ❌ NEVER
Navigator.push(context, MaterialPageRoute(...));
Navigator.pop(context);

// ✅ ALWAYS
context.go('/event/123');
context.push('/event/123');
context.pop();
```

### Route Definition

```dart
// router.dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      redirect: (_) => SplashPage(),
    ),
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/event/:id',
      builder: (context, state) => EventDetailScreen(
        eventId: state.pathParameters['id']!,
      ),
    ),
  ],
);
```

### Navigation Helpers

```dart
// lib/core/utils/navigation_utils.dart
class Nav {
  static void goHome(BuildContext context) {
    context.go('/home');
  }

  static void goToEvent(BuildContext context, String eventId) {
    context.push('/event/$eventId');
  }

  static void goBack(BuildContext context) {
    context.pop();
  }
}
```

---

## DEPENDENCY INJECTION (get_it)

### Service Locator Pattern

```dart
// injection_container.dart
final sl = GetIt.instance;

void initDependencies() {
  // Services
  sl.registerLazySingleton<AuthService>(() => AuthService());
  sl.registerLazySingleton<ApiService>(() => ApiService());

  // Repositories (domain interfaces)
  sl.registerLazySingleton<UserRepository>(() => UserRepositoryImpl());

  // Use cases
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));

  // BLoCs
  sl.registerFactory(() => AuthBloc(sl()));
}
```

### Usage

```dart
// Get service
final authService = sl<AuthService>();

// Or in BLoC
class MyBloc extends Bloc<MyEvent, MyState> {
  final MyUseCase useCase;

  MyBloc({required this.useCase}) : super(MyInitial());
}
```

---

## API CALLS (DIO)

### Error Handling

```dart
// ❌ BAD
try {
  response = await dio.get(url);
} catch (e) {
  print(e); // Silent failure
}

// ✅ GOOD
try {
  response = await dio.get(url);
  return Right(response.data);
} on DioException catch (e) {
  if (e.response?.statusCode == 401) {
    return Left(UnauthorizedException());
  }
  return Left(ServerException(e.message));
} catch (e) {
  return Left(UnknownException());
}
```

### Either Type (fpdart)

```dart
import 'package:fpdart/fpdart.dart';

// Repository returns Either<Failure, Type>
Future<Either<Failure, User>> getUser(String id) async {
  try {
    final response = await remoteDataSource.getUser(id);
    return Right(response);
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
```

---

## ERROR HANDLING

### Never Use print()

```dart
// ❌ BAD
print('Error: $e');
debugPrint('Error: $e');

// ✅ GOOD
logger.e('Failed to load user', error: e);
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Gagal memuat data')),
);
```

### User-Facing Error Messages

```dart
// lib/core/errors/failures.dart
class Failure {
  final String message;
  final int? code;

  Failure(this.message, {this.code});

  String toUserMessage() {
    // Convert technical error to user-friendly
    switch (code) {
      case 401: return 'Sesi habis. Silakan login lagi';
      case 404: return 'Data tidak ditemukan';
      case 500: return 'Terjadi kesalahan. Coba lagi';
      default: return message;
    }
  }
}
```

---

## WIDGET PATTERNS

### Stateless over Stateful

```dart
// ✅ Prefer Stateless
class MyWidget extends StatelessWidget {
  final String title;

  const MyWidget({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title);
  }
}

// ❌ Only use Stateful when needed
class MyWidget extends StatefulWidget {
  // Only for: Animation, TextEditingController, etc.
}
```

### Const Constructors

```dart
// ✅ Make widgets const when possible
const MyWidget({super.key});

// ✅ Use const for literals
const SizedBox(height: 16);
```

---

## ASYNC/AWAIT PATTERNS

### Show Loading During Async

```dart
Future<void> _handleSubmit() async {
  setState(() => _isLoading = true);

  try {
    await useCase.execute();
    if (mounted) showSuccess();
  } catch (e) {
    if (mounted) showError();
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

### Check Mounted

```dart
if (mounted) {
  setState(() {});
  Navigator.pop(context);
}
```

---

## FORMATTING

### Dart Format

```bash
# Format all files
dart format .

# Format single file
dart format lib/main.dart

# Dry run (check only)
dart format --output=none --set-exit-if-changed .
```

### Line Length

- Max: 100 characters (enforced by linter)
- Break long chains

### Naming Conventions

| Type | Convention | Example |
|------|------------|--------|
| Classes | PascalCase | `UserRepository` |
| Functions | camelCase | `getUserData()` |
| Variables | camelCase | `userName` |
| Constants | camelCase | `maxItems` |
| Private | _prefix | `_privateMethod` |
| Files | snake_case | `user_repository.dart` |
| Directories | snake_case | `user_repository/` |

---

## COMMENTS

### When to Comment

```dart
// ❌ BAD - Obvious
// Set name to John
name = 'John';

// ✅ GOOD - Why, not what
// Using Jakarta as default since location is optional
final defaultLocation = 'Jakarta';

// ✅ GOOD - Complex logic
// Calculate relevance score based on:
// - Distance (40% weight)
// - Interest match (30%)
// - Social proof (30%)
double _calculateRelevance(Event event) {
  // ...complex calculation
}
```

### Doc Comments

```dart
/// Fetches user profile by ID.
///
/// Returns [Right] with [User] if successful.
/// Returns [Left] with [Failure] if error occurs.
///
/// Example:
/// ```dart
/// final result = await getUser('user_123');
/// result.fold(
///   (error) => print(error),
///   (user) => print(user.name),
/// );
/// ```
Future<Either<Failure, User>> getUser(String id) async {
  // ...
}
```

---

## LINTING

### Required Lints

```yaml
# analysis_options.yaml
linter:
  rules:
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - avoid_print
    - avoid_unnecessary_containers
    - prefer_single_quotes
    - sort_child_properties_last
```

### Run Linter

```bash
flutter analyze
```

---

## IMPORTS

### Barrel Exports

```dart
// lib/presentation/widgets/common/common.dart
export 'buttons/primary_button.dart';
export 'inputs/text_field.dart';
export 'loading/loading_spinner.dart';

// Usage
import '../../../presentation/widgets/common/common.dart';
```

### Relative vs Absolute

```dart
// ✅ Relative (preferred within lib/)
import '../../domain/entities/user.dart';

// ✅ Absolute (required when leaving lib/)
import 'package:anigmaa/domain/entities/user.dart';
```

---

## MAGIC NUMBERS

### Use Constants

```dart
// ❌ BAD
SizedBox(height: 16);
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12),
  ),
)

// ✅ GOOD
class UIConstants {
  static const double spacingSmall = 8;
  static const double spacingMedium = 16;
  static const double borderRadius = 12;
  static const double borderRadiusLarge = 16;
}

SizedBox(height: UIConstants.spacingMedium);
```

---

## NULL SAFETY

### Never Use !

```dart
// ❌ BAD
user!.name;

// ✅ GOOD
user?.name ?? 'Unknown';

// ❌ BAD
list!.first;

// ✅ GOOD
list.firstOrNull ?? defaultValue;
```

---

## PERFORMANCE

### Const Widgets

```dart
// ✅ Good for repeated widgets
const _loadingIndicator = CircularProgressIndicator();

// ❌ Bad (rebuilds every time)
@override
Widget build(BuildContext context) {
  return CircularProgressIndicator();
}
```

### ListView.builder

```dart
// ✅ For long lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)

// ❌ For long lists (>100 items)
ListView(
  children: items.map((e) => ItemWidget(e)).toList(),
)
```

---

## IMPLEMENTATION

**Linting**:
```bash
flutter analyze
dart format .
```

**Before committing**:
```bash
flutter test
flutter analyze
dart format --set-exit-if-changed .
```

---

**Remember**: Consistent code = Maintainable code = Happy agents
