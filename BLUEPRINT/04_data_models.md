# 04. DATA MODELS

All entities and their properties for V1.

---

## USER

```dart
class User {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String? bio;
  final String? location;
  final String? phone;
  final String? gender;
  final DateTime? dateOfBirth;
  final List<String> interests;
  final UserStats stats;
  final DateTime createdAt;
  final bool isFollowing; // For other users only
}

class UserStats {
  final int followersCount;
  final int followingCount;
  final int eventsAttended;
}
```

**Field Types**:
- `id`: String (UUID)
- `name`: String, 1-100 chars
- `email`: String, validated email
- `avatar`: String? (URL)
- `bio`: String?, max 500 chars
- `location`: String? (city name)
- `phone`: String? (E.164 format)
- `gender`: String? (Laki-laki/Perempuan/Lainnya)
- `dateOfBirth`: DateTime?
- `interests`: List<String> (from predefined list)
- `isFollowing`: bool (only when viewing other user)

---

## EVENT

```dart
class Event {
  final String id;
  final String title;
  final String description;
  final String coverPhoto;
  final List<String> photos;
  final DateTime startDate;
  final DateTime endDate;
  final EventLocation location;
  final int priceMin;
  final int priceMax;
  final int attendeesCount;
  final EventHost host;
  final String category;
  final bool isFree;
  final List<TicketType> ticketTypes;
  final bool isRegistered; // For current user
  final List<String> tags;
  final DateTime createdAt;
}

class EventLocation {
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
}

class EventHost {
  final String id;
  final String name;
  final String? avatar;
  final bool isFollowing;
}

class TicketType {
  final String id;
  final String name;
  final int price;
  final bool available;
  final int maxPerOrder;
}
```

**Field Types**:
- `priceMin/Max`: Integer (in Rupiah)
- `category`: Enum (Music, Sports, Workshop, Food, Art, Other)
- `isFree`: Boolean
- `isRegistered`: Boolean (current user's registration status)

---

## POST

```dart
class Post {
  final String id;
  final User user;
  final String content;
  final List<String> photos;
  final TaggedEvent? taggedEvent;
  final String? location;
  final DateTime createdAt;
  final PostStats stats;
  final bool isLiked;
}

class TaggedEvent {
  final String id;
  final String title;
  final String? coverPhoto;
}

class PostStats {
  final int likesCount;
  final int commentsCount;
}
```

**Field Types**:
- `content`: String, max 500 chars
- `photos`: List<String> (URLs), max 10
- `isLiked`: Boolean (current user's like status)

---

## TICKET

```dart
class Ticket {
  final String id;
  final String qrCode; // QR data string
  final Event event;
  final String ticketType;
  final int quantity;
  final TicketState state; // ✅ State, not status
  final DateTime? usedAt; // ✅ Timestamp when state became USED
  final DateTime purchasedAt;

  // Computed properties (NOT stored in DB)
  bool get isUsed => state == TicketState.used;
  bool get canCheckIn => state == TicketState.active;
  bool get isExpired => state == TicketState.expired;
}

enum TicketState {
  reserved,
  active,
  used,
  expired,
}
```

**Note**: No `refunded` state in V1. All purchases are final (see `10_non_goals.md`).

**Field Types**:
- `qrCode`: String (data for QR code)
- `state`: Enum (TicketState)
- `usedAt`: DateTime? (null until state transitions to USED)
- `quantity`: Integer (number of tickets)

**State Rules**:
- `isUsed` is computed from `state == TicketState.used`
- `canCheckIn` is computed from `state == TicketState.active`
- No redundant boolean fields (single source of truth = state)

---

## COMMENT

```dart
class Comment {
  final String id;
  final User user;
  final String content;
  final DateTime createdAt;
  final int likesCount;
  final bool isLiked;
}
```

**Field Types**:
- `content`: String, max 500 chars

---

## AUTH RESPONSE

```dart
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final User user;
}
```

**Token Types**:
- `accessToken`: JWT, expires in 1 hour
- `refreshToken`: JWT, expires in 30 days

---

## FEED ITEM

```dart
class FeedItem {
  final String id;
  final FeedType type; // post or event
  final Post? post;
  final Event? event;
  final double rank; // Relevance score
}

enum FeedType {
  post,
  event,
}
```

**Note**: Feed can return mixed posts and events, sorted by `rank`.

---

## PAGINATION RESPONSE

```dart
class PaginatedResponse<T> {
  final List<T> data;
  final int total;
  final int page;
  final int limit;
}
```

**Calculation**:
- `hasNext = (page * limit) < total`
- `totalPages = (total / limit).ceil()`

---

## ERROR RESPONSE

```dart
class ErrorResponse {
  final Error error;
}

class Error {
  final String code;
  final String message;
  final Map<String, dynamic>? details;
}
```

**Error Codes**:
- `VALIDATION_ERROR`
- `UNAUTHORIZED`
- `FORBIDDEN`
- `NOT_FOUND`
- `CONFLICT`
- `RATE_LIMITED`
- `SERVER_ERROR`

---

## CREATE POST REQUEST

```dart
class CreatePostRequest {
  final String content;
  final String? eventId;
  final String? location;
  final List<File>? photos;
}
```

**Note**: Uses multipart/form-data for file upload.

---

## PURCHASE TICKET REQUEST

```dart
class PurchaseTicketRequest {
  final String eventId;
  final String ticketTypeId;
  final int quantity;
}
```

**Validation**:
- `quantity`: 1-10
- Must have valid `ticketTypeId` from event

---

## FILE LOCATIONS

### Domain Entities

```
lib/domain/entities/
├── user.dart
├── event.dart
├── post.dart
├── ticket.dart
└── comment.dart
```

### Data Models (API DTOs)

```
lib/data/models/
├── user_model.dart
├── event_model.dart
├── post_model.dart
├── ticket_model.dart
└── comment_model.dart
```

**Naming Convention**:
- Entity: `User`
- Model: `UserModel` (extends User with fromJson/toJson)

---

## MAPPING EXAMPLE

```dart
// Model extends Entity
class UserModel extends User {
  UserModel({
    required super.id,
    required super.name,
    // ... all fields
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      // ... map all fields
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      // ... map all fields
    };
  }

  // Convert Model to Entity
  User toEntity() {
    return User(
      id: id,
      name: name,
      // ... all fields
    );
  }
}
```

---

## NULLABILITY RULES

| Field | Nullable? | Reason |
|-------|-----------|--------|
| User.avatar | Yes | Can have default |
| User.bio | Yes | Optional |
| User.location | Yes | Optional but recommended (Jakarta default if denied) |
| User.phone | Yes | Optional |
| User.dateOfBirth | Yes | Optional but recommended |
| Event.photos | Yes | Can have only cover |
| Post.taggedEvent | Yes | Optional |
| Post.location | Yes | Optional |

---

## VALIDATION RULES

### User

| Field | Rule |
|-------|------|
| name | 1-100 chars |
| bio | Max 500 chars |
| location | Valid city name |
| phone | E.164 format (e.g., +628123456789) |
| interests | From predefined list only |

### Event

| Field | Rule |
|-------|------|
| title | 5-100 chars |
| description | Max 2000 chars |
| startDate | Must be in future (for creating) |
| endDate | Must be after startDate |
| priceMin | >= 0 |
| priceMax | >= priceMin |

### Post

| Field | Rule |
|-------|------|
| content | Max 500 chars |
| photos | Max 10 images |

---

## DATE FORMAT

All dates in **ISO 8601** format:
- `2025-01-28T10:00:00Z` (UTC)
- Always store and send as UTC
- Convert to local time for display only

---

## CURRENCY

All prices in **Indonesian Rupiah (IDR)**:
- Stored as integer (no decimals)
- Display as formatted: "Rp 150.000"
- No decimal places

---

## IMPLEMENTATION

**Domain Entities**: `lib/domain/entities/`
**Data Models**: `lib/data/models/`
**Mapping**: Use `json_serializable` or `freezed`

**Example Command**:
```bash
# Generate model with freezed
flutter pub run build_runner build --delete-conflicting-outputs
```
