# 🐛 Debug Guide: Tidak Bisa Upload Event & Post

## ✅ Backend Kode Sudah Benar

Setelah saya cek, **backend code sudah oke**:
- ✅ `POST /api/v1/events` → CreateEvent handler OK (line event_handler.go:43)
- ✅ `POST /api/v1/posts` → CreatePost handler OK (line post_handler.go:100)
- ✅ Routes registered correctly dengan auth middleware
- ✅ Validation rules sudah proper

## 🔍 Kemungkinan Masalah

### 1️⃣ **Authentication Issue (Paling Sering)**

#### Cek di Frontend:
```dart
// Apakah token terkirim dengan benar?
final headers = {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer YOUR_JWT_TOKEN', // ← Harus ada ini!
};
```

#### Symptom:
```json
{
  "success": false,
  "message": "User not authenticated",
  "error": {
    "code": "UNAUTHORIZED"
  }
}
```

#### Fix:
```dart
// Di Flutter, pastikan:
final token = await storage.read(key: 'jwt_token');
if (token == null || token.isEmpty) {
  // Token expired/tidak ada → redirect ke login
  Navigator.pushNamed(context, '/login');
  return;
}

final response = await http.post(
  Uri.parse('$baseUrl/api/v1/posts'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token', // Prefix "Bearer " wajib!
  },
  body: jsonEncode(postData),
);
```

---

### 2️⃣ **Validation Error**

#### Required Fields untuk **CreatePost**:
```json
{
  "content": "Text minimal 1 char, max 5000",  // WAJIB
  "type": "text",                              // WAJIB: "text", "text_with_images", "text_with_event", "poll", "repost"
  "visibility": "public",                       // WAJIB: "public", "followers", "private"
  "image_urls": ["url1", "url2"],              // OPSIONAL, max 4 images
  "attached_event_id": "uuid",                 // OPSIONAL (wajib kalau type = "text_with_event")
  "hashtags": ["tech", "coding"],              // OPSIONAL
  "mentions": ["@user1", "@user2"]             // OPSIONAL
}
```

#### Required Fields untuk **CreateEvent**:
```json
{
  "title": "Minimal 3 char, max 100",          // WAJIB
  "description": "Minimal 10 char",            // WAJIB
  "category": "meetup",                        // WAJIB: meetup, sports, workshop, networking, food, creative, outdoor, fitness, learning, social
  "start_time": "2025-11-20T18:00:00Z",       // WAJIB (format ISO 8601)
  "end_time": "2025-11-20T21:00:00Z",         // WAJIB (harus > start_time)
  "location_name": "Cafe ABC",                 // WAJIB
  "location_address": "Jl. Sudirman 123",     // WAJIB
  "location_lat": -6.2088,                     // WAJIB (-90 to 90)
  "location_lng": 106.8456,                    // WAJIB (-180 to 180)
  "max_attendees": 50,                         // WAJIB (3-100)
  "price": 50000.0,                            // OPSIONAL (null jika free)
  "is_free": true,                             // WAJIB (true/false)
  "privacy": "public",                         // WAJIB: "public", "private", "friends_only"
  "ticketing_enabled": false,                  // WAJIB (true/false)
  "requirements": "Bawa laptop",               // OPSIONAL
  "image_urls": ["url1", "url2"]              // OPSIONAL
}
```

#### Symptom:
```json
{
  "success": false,
  "message": "Validation failed",
  "error": {
    "code": "BAD_REQUEST",
    "details": "Key: 'CreatePostRequest.Content' Error:Field validation for 'Content' failed on the 'required' tag"
  }
}
```

#### Fix:
Pastikan semua field wajib terisi dan sesuai tipe data!

---

### 3️⃣ **Event Time Validation Error**

#### Rules:
- `start_time` harus **di masa depan** (tidak boleh sudah lewat)
- `end_time` harus **> start_time**

#### Symptom:
```json
{
  "success": false,
  "message": "Cannot create event in the past",
  "error": {
    "code": "BAD_REQUEST"
  }
}
```

atau

```json
{
  "success": false,
  "message": "End time must be after start time",
  "error": {
    "code": "BAD_REQUEST"
  }
}
```

#### Fix:
```dart
final now = DateTime.now();
final startTime = DateTime(2025, 11, 20, 18, 0); // Harus future
final endTime = startTime.add(Duration(hours: 3)); // Harus > start_time

// Format ke ISO 8601
final startTimeISO = startTime.toUtc().toIso8601String(); // "2025-11-20T18:00:00.000Z"
```

---

### 4️⃣ **CORS Issue (Kalau dari Browser)**

#### Symptom:
```
Access to fetch at 'http://localhost:8081/api/v1/posts' from origin 'http://localhost:3000'
has been blocked by CORS policy
```

#### Fix:
Backend sudah enable CORS (line main.go:142), tapi cek `.env`:
```env
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
```

Pastikan origin frontend kamu ada di list.

---

### 5️⃣ **Server Tidak Running**

#### Cek apakah server jalan:
```bash
# Method 1: Cek port 8081
curl http://localhost:8081/health

# Method 2: Cek Docker
docker compose ps

# Method 3: Cek process
ps aux | grep backend
```

#### Expected Response:
```json
{
  "status": "ok",
  "service": "anigmaa-backend",
  "version": "1.0.0"
}
```

#### Fix:
```bash
# Start server
docker compose up -d
# atau
go run cmd/server/main.go
```

---

### 6️⃣ **Database Connection Issue**

#### Symptom:
```json
{
  "success": false,
  "message": "Failed to create post",
  "error": {
    "code": "INTERNAL_ERROR",
    "details": "dial tcp [::1]:5432: connect: connection refused"
  }
}
```

#### Fix:
```bash
# Cek DB running
docker compose ps postgres

# Start DB
docker compose up -d postgres

# Test connection
psql -h localhost -U anigmaa_user -d anigmaa_db -c "SELECT 1;"
```

---

## 🧪 Test Manual dengan cURL

### Test Create Post:
```bash
# 1. Login dulu untuk dapat token
curl -X POST http://localhost:8081/api/v1/auth/google \
  -H "Content-Type: application/json" \
  -d '{
    "id_token": "YOUR_GOOGLE_ID_TOKEN"
  }'

# Response akan kasih JWT token:
# {"success":true,"data":{"token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."}}

# 2. Create post dengan token
curl -X POST http://localhost:8081/api/v1/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE" \
  -d '{
    "content": "Testing create post from cURL",
    "type": "text",
    "visibility": "public"
  }'
```

### Test Create Event:
```bash
curl -X POST http://localhost:8081/api/v1/events \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE" \
  -d '{
    "title": "Test Event",
    "description": "This is a test event description",
    "category": "meetup",
    "start_time": "2025-12-01T18:00:00Z",
    "end_time": "2025-12-01T21:00:00Z",
    "location_name": "Test Venue",
    "location_address": "Jl. Test 123",
    "location_lat": -6.2088,
    "location_lng": 106.8456,
    "max_attendees": 50,
    "is_free": true,
    "privacy": "public",
    "ticketing_enabled": false
  }'
```

---

## 🔧 Frontend Debugging Checklist

### Flutter Example - Create Post:
```dart
Future<void> createPost(String content) async {
  try {
    // 1. Get token
    final token = await storage.read(key: 'jwt_token');
    if (token == null) {
      print('❌ Token not found - redirect to login');
      return;
    }

    // 2. Prepare data
    final postData = {
      'content': content,
      'type': 'text',
      'visibility': 'public',
    };

    print('📤 Sending POST request...');
    print('URL: $baseUrl/api/v1/posts');
    print('Headers: Authorization: Bearer ${token.substring(0, 20)}...');
    print('Body: ${jsonEncode(postData)}');

    // 3. Send request
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/posts'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(postData),
    );

    // 4. Check response
    print('📥 Response Status: ${response.statusCode}');
    print('📥 Response Body: ${response.body}');

    if (response.statusCode == 201) {
      print('✅ Post created successfully!');
      final data = jsonDecode(response.body);
      print('Post ID: ${data['data']['id']}');
    } else {
      print('❌ Error: ${response.body}');
      // Parse error
      final error = jsonDecode(response.body);
      showError(error['message']);
    }

  } catch (e, stackTrace) {
    print('❌ Exception: $e');
    print('Stack trace: $stackTrace');
  }
}
```

---

## 🚨 Common Errors & Solutions

| Error Message | Cause | Fix |
|---------------|-------|-----|
| "User not authenticated" | Token tidak ada/salah | Cek Authorization header |
| "Invalid user ID" | Token corrupted | Re-login untuk dapat token baru |
| "Validation failed" | Required field kosong | Cek semua field wajib terisi |
| "Cannot create event in the past" | start_time sudah lewat | Gunakan waktu di masa depan |
| "End time must be after start time" | end_time ≤ start_time | end_time harus > start_time |
| "Attached event not found" | Event ID tidak valid | Cek event ID exist di DB |
| "Invalid request body" | JSON format salah | Cek JSON syntax |
| "Failed to create post" (500) | Server/DB error | Cek server logs |

---

## 📊 Enable Detailed Logging

Tambahkan di frontend untuk debug:
```dart
// Di interceptor/wrapper HTTP client
class LoggingInterceptor {
  Future<http.Response> post(Uri url, {Map<String, String>? headers, dynamic body}) async {
    print('═══════════════════════════════════════');
    print('🚀 POST REQUEST');
    print('URL: $url');
    print('Headers: $headers');
    print('Body: $body');
    print('═══════════════════════════════════════');

    final response = await http.post(url, headers: headers, body: body);

    print('═══════════════════════════════════════');
    print('📥 RESPONSE');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
    print('═══════════════════════════════════════');

    return response;
  }
}
```

---

## 🎯 Next Steps

1. **Cek server running**: `curl http://localhost:8081/health`
2. **Test dengan cURL** (manual) untuk isolasi masalah
3. **Enable logging** di frontend untuk lihat request detail
4. **Cek JWT token** masih valid (decode di jwt.io)
5. **Share error message** ke sini untuk diagnosis lebih lanjut

**Need more help? Share:**
- ❌ Error message dari frontend
- 📱 Screenshot error
- 📝 Request payload yang dikirim
- 🔑 Apakah sudah login dan dapat token?
