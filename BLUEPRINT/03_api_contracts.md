# 03. API CONTRACTS

All API endpoints for V1.

**Base URL**: `http://localhost:8123` (dev)

**Headers**:
```
Authorization: Bearer {access_token}
Content-Type: application/json
```

---

## AUTH SERVICE

### Google Sign In

```
POST /api/v1/auth/google
```

**Request**:
```json
{
  "id_token": "google_id_token_from_client"
}
```

**Response (200)**:
```json
{
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbG...",
  "user": {
    "id": "user_123",
    "name": "John Doe",
    "email": "john@gmail.com",
    "avatar": "https://...",
    "created_at": "2025-01-28T10:00:00Z"
  }
}
```

**Errors**:
- 400: Invalid token
- 401: Authentication failed
- 500: Server error

---

### Refresh Token

```
POST /api/v1/auth/refresh
```

**Request**:
```json
{
  "refresh_token": "eyJhbGc..."
}
```

**Response (200)**:
```json
{
  "access_token": "new_access_token"
}
```

---

### Logout

```
POST /api/v1/auth/logout
```

**Request**: Auth header only

**Response (200)**: Empty body

---

## USER SERVICE

### Get Current User

```
GET /api/v1/users/me
```

**Response (200)**:
```json
{
  "id": "user_123",
  "name": "John Doe",
  "email": "john@gmail.com",
  "avatar": "https://...",
  "bio": "Event enthusiast",
  "location": "Jakarta",
  "phone": "08123456789",
  "gender": "Laki-laki",
  "date_of_birth": "1990-01-15",
  "interests": ["Music", "Sports"],
  "stats": {
    "followers_count": 120,
    "following_count": 80,
    "events_attended": 15
  },
  "created_at": "2025-01-01T10:00:00Z"
}
```

---

### Update Profile

```
PUT /api/v1/users/me
```

**Request**:
```json
{
  "bio": "New bio",
  "location": "Bandung",
  "phone": "08123456789",
  "gender": "Laki-laki",
  "date_of_birth": "1990-01-15",
  "interests": ["Music", "Sports", "Travel"]
}
```

**Response (200)**: Updated user object

---

### Get User by ID

```
GET /api/v1/users/{user_id}
```

**Response (200)**: User object (same as /me)

Includes:
- `is_following`: boolean

---

### Follow User

```
POST /api/v1/users/{user_id}/follow
```

**Response (200)**:
```json
{
  "following": true
}
```

---

### Unfollow User

```
DELETE /api/v1/users/{user_id}/follow
```

**Response (200)**:
```json
{
  "following": false
}
```

---

### Get Followers

```
GET /api/v1/users/{user_id}/followers?page=1&limit=20
```

**Response (200)**:
```json
{
  "data": [user_objects],
  "total": 120,
  "page": 1,
  "limit": 20
}
```

---

### Get Following

```
GET /api/v1/users/{user_id}/following?page=1&limit=20
```

**Response (200)**: Same structure as followers

---

## EVENT SERVICE

### List Events

```
GET /api/v1/events?page=1&limit=20
```

**Response (200)**:
```json
{
  "data": [
    {
      "id": "event_123",
      "state": "PUBLISHED",
      "title": "Music Festival 2025",
      "description": "Annual music fest",
      "cover_photo": "https://...",
      "start_date": "2025-02-15T19:00:00Z",
      "end_date": "2025-02-15T23:00:00Z",
      "location": {
        "name": "GBK Arena",
        "address": "Jakarta",
        "latitude": -6.2183,
        "longitude": 106.8022
      },
      "price_min": 150000,
      "price_max": 500000,
      "attendees_count": 1234,
      "host": {
        "id": "host_123",
        "name": "Event Organizer",
        "avatar": "https://..."
      },
      "category": "Music",
      "is_free": false
    }
  ],
  "total": 100,
  "page": 1,
  "limit": 20
}
```

---

### Get Event Details

```
GET /api/v1/events/{event_id}
```

**Response (200)**:
```json
{
  "id": "event_123",
  "state": "PUBLISHED",
  "title": "Music Festival 2025",
  "description": "Full description...",
  "cover_photo": "https://...",
  "photos": ["https://...", "https://..."],
  "start_date": "2025-02-15T19:00:00Z",
  "end_date": "2025-02-15T23:00:00Z",
  "location": {
    "name": "GBK Arena",
    "address": "Jl. Gatot Subroto, Jakarta"
  },
  "price_min": 150000,
  "price_max": 500000,
  "attendees_count": 1234,
  "host": {
    "id": "host_123",
    "name": "Event Organizer",
    "avatar": "https://...",
    "is_following": false
  },
  "category": "Music",
  "is_free": false,
  "ticket_types": [
    {
      "id": "ticket_123",
      "name": "Regular",
      "price": 150000,
      "available": true,
      "max_per_order": 10
    },
    {
      "id": "ticket_124",
      "name": "VIP",
      "price": 500000,
      "available": false,
      "max_per_order": 5
    }
  ],
  "is_registered": false,
  "tags": ["music", "festival", "outdoor"]
}
```

---

### Nearby Events (Spatial)

```
GET /api/v1/events/nearby?lat=-6.2183&lng=106.8022&radius=10&page=1&limit=20
```

**Response (200)**: Same as list events

---

### Get My Hosted Events

```
GET /api/v1/users/me/events?status=upcoming
```

**Authentication**: Required (Bearer token)

**Query Parameters**:
- `status`: Filter by status (`upcoming`, `ongoing`, `ended`, `cancelled`) - optional

**Response (200)**:
```json
{
  "data": [
    {
      "id": "event_123",
      "title": "My Awesome Event",
      "description": "Event description...",
      "category": "meetup",
      "start_time": "2025-02-15T19:00:00Z",
      "end_time": "2025-02-15T23:00:00Z",
      "location": {
        "name": "Venue Name",
        "address": "Full Address",
        "latitude": -6.2183,
        "longitude": 106.8022
      },
      "attendees_count": 5,
      "max_attendees": 50,
      "status": "upcoming",
      "privacy": "public",
      "is_free": true,
      "price": null,
      "created_at": "2025-01-28T10:00:00Z",
      "can_edit": true,
      "can_delete": true
    }
  ],
  "total": 1
}
```

**Response Fields**:
- `can_edit`: `true` if attendees_count = 0 and status = upcoming
- `can_delete`: `true` if attendees_count = 0 and status = upcoming

---

### Update Event

```
PUT /api/v1/events/{event_id}
```

**Authentication**: Required (Bearer token)

**Preconditions**:
- `user.id == event.host_id` (only host can update)
- `event.attendees_count == 0` (no attendees yet)
- `event.status == "upcoming"` (event hasn't started)

**Request Body**: Same as Create Event request

**Response (200)**:
```json
{
  "data": {
    "id": "event_123",
    "title": "Updated Event Title",
    "description": "Updated description...",
    ...
  }
}
```

**Error Responses**:
- `400 VALIDATION_ERROR`: Invalid input data
- `403 FORBIDDEN`: Not the host
- `400 BUSINESS_RULE_ERROR`: Event has attendees or already started

---

### Delete Event

```
DELETE /api/v1/events/{event_id}
```

**Authentication**: Required (Bearer token)

**Preconditions**:
- `user.id == event.host_id` (only host can delete)
- `event.attendees_count == 0` (no attendees yet)
- `event.status == "upcoming"` (event hasn't started)

**Response (200)**:
```json
{
  "success": true,
  "message": "Event deleted successfully"
}
```

**Error Responses**:
- `403 FORBIDDEN`: Not the host
- `400 BUSINESS_RULE_ERROR`: Event has attendees or already started

---

### Get Event Attendees

```
GET /api/v1/events/{event_id}/attendees?status=confirmed
```

**Authentication**: Required (Bearer token)

**Preconditions**:
- `user.id == event.host_id` (only host can view)

**Query Parameters**:
- `status`: Filter by check-in status (`confirmed`, `pending`) - optional
- `search`: Search by name - optional

**Response (200)**:
```json
{
  "data": [
    {
      "id": "user_123",
      "name": "Budi Santoso",
      "avatar": "https://...",
      "ticket_type": "Regular",
      "checked_in": true,
      "checked_in_at": "2025-02-15T19:15:00Z",
      "purchased_at": "2025-01-28T10:00:00Z"
    }
  ],
  "total": 5,
  "checked_in_count": 3
}
```

---

### Check-in Attendee

```
POST /api/v1/events/{event_id}/check-in
```

**Authentication**: Required (Bearer token)

**Preconditions**:
- `user.id == event.host_id` (only host can check-in)
- `now >= event.start_time` (check-in window open)
- `now <= event.end_time` (event not ended)

**Request Body**:
```json
{
  "user_id": "user_123",
  "ticket_id": "ticket_123"
}
```

**Response (200)**:
```json
{
  "success": true,
  "message": "Check-in successful",
  "data": {
    "user_id": "user_123",
    "checked_in_at": "2025-02-15T19:15:00Z"
  }
}
```

**Error Responses**:
- `400 ALREADY_CHECKED_IN`: User already checked in
- `404 NOT_FOUND`: Ticket not found for this event
- `400 INVALID_TICKET`: Ticket not valid for this event

---

## TICKET SERVICE

### Purchase Ticket

```
POST /api/v1/tickets/purchase
```

**Preconditions**:
- `user.state == AUTHENTICATED` (user must be logged in)
- `event.state == PUBLISHED` (event must be published)
- `now < event.startDate` (registration must be open)
- `event.attendeesCount < event.capacity` (event must not be full)

**Postconditions**:
- Creates order with `order.state = PENDING`
- On payment success: `order.state = SUCCESS` → Creates tickets with `ticket.state = RESERVED`
- On payment confirmation: `ticket.state transitions from RESERVED → ACTIVE`

**Request**:
```json
{
  "event_id": "event_123",
  "ticket_type_id": "ticket_123",
  "quantity": 2
}
```

**Response (200)**:
```json
{
  "order_id": "order_123",
  "payment_url": "https://app.midtrans.com/...",
  "amount": 300000,
  "expires_at": "2025-01-28T10:15:00Z"
}
```

---

### Get My Tickets

```
GET /api/v1/tickets/me
```

**Response (200)**:
```json
{
  "upcoming": [
    {
      "id": "ticket_123",
      "qr_code": "QR_DATA_STRING",
      "event": {
        "id": "event_123",
        "title": "Music Festival 2025",
        "cover_photo": "https://...",
        "start_date": "2025-02-15T19:00:00Z",
        "location": {
          "name": "GBK Arena"
        }
      },
      "ticket_type": "Regular",
      "quantity": 2,
      "state": "ACTIVE",
      "purchased_at": "2025-01-28T10:00:00Z"
    }
  ],
  "past": []
}
```

---

### Check-in

```
POST /api/v1/tickets/{ticket_id}/checkin
```

**Preconditions**:
- `ticket.state == ACTIVE` (ticket must be paid)
- `ticket.state != USED` (must not be checked in yet)
- `event.state == STARTED` (event must be running)
- `now >= event.startDate` (check-in window open)
- `now <= event.endDate` (check-in window not closed)

**Postconditions**:
- `ticket.state transitions from ACTIVE → USED` (terminal state)
- Sets `ticket.usedAt = now`
- Returns error if state transition not allowed

**State Transition**: `ACTIVE → USED` (terminal, no undo possible)

**Request**:
```json
{
  "qr_data": "QR_DATA_STRING"
}
```

**Response (200)**:
```json
{
  "success": true,
  "usedAt": "2025-02-15T19:30:00Z"
}
```

**Errors**:
- 400: Invalid QR
- 404: Ticket not found
- 409: Already checked in
- 410: Ticket expired

---

## POST SERVICE

### Get Feed

```
GET /api/v1/feed?page=1&limit=20
```

**Response (200)**:
```json
{
  "data": [
    {
      "id": "post_123",
      "user": {
        "id": "user_123",
        "name": "John Doe",
        "avatar": "https://..."
      },
      "content": "Looking forward to this!",
      "photos": ["https://...", "https://..."],
      "tagged_event": {
        "id": "event_123",
        "title": "Music Festival 2025"
      },
      "location": "Jakarta",
      "created_at": "2025-01-28T10:00:00Z",
      "stats": {
        "likes_count": 12,
        "comments_count": 5
      },
      "is_liked": false
    }
  ],
  "total": 100,
  "page": 1,
  "limit": 20
}
```

---

### Create Post

```
POST /api/v1/posts
```

**Request (multipart)**:
```
content: "Post text here"
event_id: "event_123" (optional)
location: "Jakarta" (optional)
photos[]: [file1, file2] (optional)
```

**Response (201)**: Created post object

---

### Like Post

```
POST /api/v1/posts/{post_id}/like
```

**Response (200)**:
```json
{
  "liked": true,
  "likes_count": 13
}
```

---

### Unlike Post

```
DELETE /api/v1/posts/{post_id}/like
```

**Response (200)**:
```json
{
  "liked": false,
  "likes_count": 12
}
```

---

### Get Comments

```
GET /api/v1/posts/{post_id}/comments?page=1&limit=20
```

**Response (200)**:
```json
{
  "data": [
    {
      "id": "comment_123",
      "user": {
        "id": "user_456",
        "name": "Jane Doe",
        "avatar": "https://..."
      },
      "content": "Can't wait!",
      "created_at": "2025-01-28T11:00:00Z",
      "likes_count": 2,
      "is_liked": false
    }
  ],
  "total": 5,
  "page": 1,
  "limit": 20
}
```

---

### Create Comment

```
POST /api/v1/posts/{post_id}/comments
```

**Request**:
```json
{
  "content": "Great event!"
}
```

**Response (201)**: Created comment object

---

## ERROR RESPONSES

All errors follow this format:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Human readable message",
    "details": {}
  }
}
```

**Common Error Codes**:

| Code | HTTP | Description |
|------|------|-------------|
| VALIDATION_ERROR | 400 | Invalid input |
| UNAUTHORIZED | 401 | Not authenticated |
| FORBIDDEN | 403 | No permission |
| NOT_FOUND | 404 | Resource not found |
| CONFLICT | 409 | Resource conflict |
| RATE_LIMITED | 429 | Too many requests |
| SERVER_ERROR | 500 | Internal error |

---

## PAGINATION

All list endpoints support:

- `page`: Page number (default: 1)
- `limit`: Items per page (default: 20, max: 100)

Response includes:
- `data`: Array of items
- `total`: Total items
- `page`: Current page
- `limit`: Items per page
