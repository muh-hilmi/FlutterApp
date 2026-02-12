# Database Schema - Consolidated Migrations

## Overview

Struktur database ini telah diorganisir ulang menjadi **4 service-based schemas** yang lebih mudah dikelola, mengikuti arsitektur microservices:

1. **User Service** - Manajemen user dan social features
2. **Event Service** - Manajemen event dan review
3. **Post Service** - Social feed dan interaksi
4. **Ticket Service** - Ticketing dan payment

## Structure

```
migrations/consolidated/
├── 01_user_service.up.sql       # User service schema
├── 01_user_service.down.sql     # Rollback user service
├── 02_event_service.up.sql      # Event service schema
├── 02_event_service.down.sql    # Rollback event service
├── 03_post_service.up.sql       # Post service schema
├── 03_post_service.down.sql     # Rollback post service
├── 04_ticket_service.up.sql     # Ticket service schema
├── 04_ticket_service.down.sql   # Rollback ticket service
└── README.md                     # Documentation (this file)
```

## Service Breakdown

### 1. User Service (`01_user_service`)

**Tables:**
- `users` - Main user accounts with username support
- `user_settings` - User preferences (notifications, theme, etc.)
- `user_stats` - User statistics (followers, posts count, etc.)
- `user_privacy` - Privacy settings
- `follows` - Social follow relationships
- `invitations` - User invitation tracking

**Features:**
- UUID primary keys
- Automatic timestamp updates
- Username validation (3-50 chars, alphanumeric + underscore/hyphen)
- Auto-updating statistics via triggers
- Comprehensive indexing

### 2. Event Service (`02_event_service`)

**Tables:**
- `events` - Main event information
- `event_images` - Event photo gallery
- `event_attendees` - Event participants
- `reviews` - Event reviews and ratings (1-5 stars)
- `event_qna` - Event Q&A functionality

**Features:**
- PostGIS integration for location-based queries
- Automatic geolocation point generation
- Event status tracking (upcoming, ongoing, completed, cancelled)
- Event categories (coffee, food, gaming, sports, music, etc.)
- Review system with ratings
- Q&A for community engagement

### 3. Post Service (`03_post_service`)

**Tables:**
- `posts` - Main posts/feeds
- `post_images` - Post image attachments
- `comments` - Nested comment support
- `likes` - Universal like system for posts and comments
- `reposts` - Repost/quote functionality
- `bookmarks` - Saved posts
- `shares` - External sharing tracking

**Features:**
- Auto-updating counters via triggers (likes, comments, reposts, shares)
- Multiple post types (text, images, events, polls, reposts)
- Visibility controls (public, followers, private)
- Nested comments support
- Optimized indexes for feed queries

### 4. Ticket Service (`04_ticket_service`)

**Tables:**
- `tickets` - Event tickets with check-in tracking
- `ticket_transactions` - Payment transaction records

**Features:**
- Unique attendance codes for check-in
- Transaction status tracking (pending, success, failed, refunded)
- Support for refunds and cancellations
- Payment method tracking
- One ticket per user per event constraint

## Migration Order

⚠️ **IMPORTANT**: Migrations harus dijalankan sesuai urutan!

```bash
# Forward migration (setup)
1. 01_user_service.up.sql      # User service (foundation)
2. 02_event_service.up.sql     # Event service (depends on users)
3. 03_post_service.up.sql      # Post service (depends on users & events)
4. 04_ticket_service.up.sql    # Ticket service (depends on users & events)

# Rollback migration (teardown)
1. 04_ticket_service.down.sql  # Ticket service
2. 03_post_service.down.sql    # Post service
3. 02_event_service.down.sql   # Event service
4. 01_user_service.down.sql    # User service
```

## Cross-Service References

Beberapa tabel memiliki foreign key references ke service lain:

| Source Service | Table | References | Target Service |
|----------------|-------|------------|----------------|
| Event | events.host_id | users.id | User |
| Event | event_attendees.user_id | users.id | User |
| Event | reviews.reviewer_id | users.id | User |
| Event | event_qna.user_id | users.id | User |
| Post | posts.author_id | users.id | User |
| Post | posts.attached_event_id | events.id | Event |
| Post | comments.author_id | users.id | User |
| Post | likes.user_id | users.id | User |
| Ticket | tickets.user_id | users.id | User |
| Ticket | tickets.event_id | events.id | Event |
| User | invitations.event_id | events.id | Event |

**Note**: Untuk implementasi microservices penuh, foreign key constraints ini perlu dihapus dan diganti dengan logical validation di application layer.

## How to Use

### Option 1: Manual Migration (PostgreSQL)

```bash
# Connect to your database
psql -U your_user -d your_database

# Run migrations in order
\i migrations/consolidated/01_user_service.up.sql
\i migrations/consolidated/02_event_service.up.sql
\i migrations/consolidated/03_post_service.up.sql
\i migrations/consolidated/04_ticket_service.up.sql
```

### Option 2: Using golang-migrate

```bash
# Install golang-migrate
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

# Run all migrations
migrate -database "postgres://user:pass@localhost:5432/dbname?sslmode=disable" \
        -path migrations/consolidated up

# Rollback all migrations
migrate -database "postgres://user:pass@localhost:5432/dbname?sslmode=disable" \
        -path migrations/consolidated down
```

### Option 3: Using Docker

```bash
# Run migrations via docker
docker run -v $(pwd)/migrations/consolidated:/migrations \
           --network host \
           migrate/migrate \
           -path=/migrations \
           -database "postgres://user:pass@localhost:5432/dbname?sslmode=disable" up
```

## Advantages of This Structure

### ✅ Kelebihan

1. **Organized by Feature** - Setiap service memiliki schema yang self-contained
2. **Easier to Maintain** - Tidak perlu mencari-cari table di 16 file berbeda
3. **Microservices Ready** - Mudah di-split jadi database terpisah kalau mau scale
4. **Clear Dependencies** - Mudah lihat dependencies antar service
5. **Faster Development** - Developer bisa fokus ke service yang relevan
6. **Better Documentation** - Setiap file punya summary lengkap

### 🔄 Migration from Old Structure

Old structure (16 files) masih ada di `/migrations/*.sql`.

**Untuk fresh installation**: Gunakan structure baru ini (`consolidated/`)

**Untuk existing database**:
- Database yang sudah running dengan old migrations tetap bisa berjalan
- Tidak perlu re-migrate kalau sudah running dengan old structure
- New structure ini lebih cocok untuk fresh setup atau microservices migration

## Microservices Architecture Notes

Jika ingin mengimplementasikan **true microservices** dengan database terpisah:

### Separate Databases

```
anigmaa_user_db
├── users
├── user_settings
├── user_stats
├── user_privacy
├── follows
└── invitations

anigmaa_event_db
├── events
├── event_images
├── event_attendees
├── reviews
└── event_qna

anigmaa_post_db
├── posts
├── post_images
├── comments
├── likes
├── reposts
├── bookmarks
└── shares

anigmaa_ticket_db
├── tickets
└── ticket_transactions
```

### Required Changes for Microservices

1. **Remove Foreign Key Constraints** - Foreign keys ke table di service lain harus dihapus
2. **Add Application-Level Validation** - Validasi references dilakukan di code
3. **Implement Event-Driven Updates** - Gunakan message queue (e.g., RabbitMQ, Kafka) untuk sync data
4. **Add API Gateway** - Central entry point untuk semua services
5. **Implement Service Discovery** - Untuk communication antar services

### Example: Removing FK for Microservices

```sql
-- Instead of:
ALTER TABLE events ADD CONSTRAINT fk_host_id
    FOREIGN KEY (host_id) REFERENCES users(id);

-- Use application validation in code:
// In EventService
func CreateEvent(event Event) error {
    // Call UserService API to validate user exists
    user, err := userServiceClient.GetUserByID(event.HostID)
    if err != nil {
        return errors.New("invalid host_id")
    }

    // Proceed with event creation
    return eventRepo.Create(event)
}
```

## Performance Optimizations

All schemas sudah include optimizations:

1. **Indexes** - Proper indexing untuk queries yang sering digunakan
2. **Spatial Indexes** - GIST index untuk location-based queries (PostGIS)
3. **Auto-updating Counters** - Triggers untuk update denormalized counters
4. **Timestamp Triggers** - Automatic `updated_at` updates
5. **Constraints** - Data integrity via CHECK constraints

## Seeding Data

Untuk development/testing, gunakan seed files dari old migrations:

```bash
# Seed users and events
\i migrations/011_enhanced_seed_data.sql

# Seed interactions
\i migrations/016_seed_interactions_and_events.up.sql
```

## Troubleshooting

### Issue: Extension not found

```sql
ERROR: extension "uuid-ossp" is not available
```

**Solution:**
```sql
-- Install PostgreSQL contrib package
sudo apt-get install postgresql-contrib

-- Or using Homebrew (Mac)
brew install postgresql
```

### Issue: PostGIS extension error

```sql
ERROR: extension "postgis" is not available
```

**Solution:**
```bash
# Ubuntu/Debian
sudo apt-get install postgis postgresql-14-postgis-3

# Mac
brew install postgis

# Then create extension in database
CREATE EXTENSION postgis;
```

### Issue: Permission denied

```sql
ERROR: permission denied to create extension "uuid-ossp"
```

**Solution:**
```sql
-- Connect as superuser first
psql -U postgres

-- Grant permissions
ALTER DATABASE your_database OWNER TO your_user;
GRANT ALL PRIVILEGES ON DATABASE your_database TO your_user;
```

## Questions?

Hubungi team untuk pertanyaan lebih lanjut tentang:
- Migration strategy
- Microservices implementation
- Performance tuning
- Scaling considerations

---

**Last Updated**: 2025-01-10
**Version**: 1.0.0
**Migration Count**: 4 services (from 16 files)
