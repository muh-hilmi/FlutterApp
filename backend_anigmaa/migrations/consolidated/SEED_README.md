# Seed Data Documentation

Seed data untuk Anigmaa app. Semua file ada di folder `migrations/consolidated/`.

---

## File Overview

| File | Deskripsi | Jumlah Data | Run Order |
|------|-----------|-------------|-----------|
| `seed_01_users.sql` | Users + settings + follows | 25 users | 1st |
| `seed_02_events.sql` | Events + images | 10 events | 2nd |
| `seed_03_posts.sql` | Posts + images | 20 posts | 3rd |
| `seed_04_attendees.sql` | Event attendees | ~120 attendees | 4th |

---

## Cara Pakai

### Step 1: Run di PostgreSQL

```bash
# Masuk ke container docker
docker exec -it anigmaa_postgres psql -U postgres -d anigmaa

# Atau dari host
cd /path/to/backend_anigmaa
docker exec anigmaa_postgres psql -U postgres -d anigmaa -f migrations/consolidated/seed_01_users.sql
docker exec anigmaa_postgres psql -U postgres -d anigmaa -f migrations/consolidated/seed_02_events.sql
docker exec anigmaa_postgres psql -U postgres -d anigmaa -f migrations/consolidated/seed_03_posts.sql
docker exec anigmaa_postgres psql -U postgres -d anigmaa -f migrations/consolidated/seed_04_attendees.sql
```

### Step 2: Atau dari backend

```bash
cd backend_anigmaa
psql -h localhost -U postgres -d anigmaa -f migrations/consolidated/seed_01_users.sql
```

---

## Data Structure

### Users (25 users)

Semua user ID menggunakan pattern: `11111111-1111-1111-1111-111111111111`

**Groups:**
- Coffee & Food: Rudi, Siti, Rizki
- Gaming & Tech: Budi, Doni, Tina
- Creative: Maya, Rina, Irfan
- Sports: Andi, Linda, Ferry, Eko
- Music: Agus, Dimas
- dll.

### Events (10 events)

Semua event ID menggunakan prefix: `seed0001-...`

| Event | Host | Category | Date |
|-------|------|----------|------|
| Weekend Coffee Meetup | Rudi | coffee | 25 Jan 2026 |
| Mobile Legends Workshop | Budi | other | 26 Jan 2026 |
| Street Food Hunting | Siti | food | 27 Jan 2026 |
| React 19 Workshop | Doni | study | 1 Feb 2026 |
| Sunday Morning Run | Andi | sports | 2 Feb 2026 |
| Photography Kota Tua | Rina | other | 8 Feb 2026 |
| Indie Music Night | Agus | creative | 9 Feb 2026 |
| K-BBB Night | Hadi | food | 15 Feb 2026 |
| Yoga Morning | Linda | other | 16 Feb 2026 |
| Basketball 3x3 | Eko | sports | 22 Feb 2026 |

### Posts (20 posts)

- Semua posts punya `attached_event_id` (required)
- 5 posts punya images
- Post ID prefix: `seed0001-0001-...`

### Attendees

- Setiap event: 6-20 attendees
- Status: `confirmed` atau `pending`

---

## Reset Data

Untuk hapus semua seed data:

```sql
-- Hapus attendees
DELETE FROM event_attendees WHERE event_id LIKE 'seed%';

-- Hapus posts
DELETE FROM likes WHERE likeable_type = 'post' AND likeable_id LIKE 'seed%';
DELETE FROM comments WHERE post_id LIKE 'seed%';
DELETE FROM post_images WHERE post_id LIKE 'seed%';
DELETE FROM posts WHERE id LIKE 'seed%';

-- Hapus events
DELETE FROM event_qna WHERE event_id LIKE 'seed%';
DELETE FROM event_images WHERE event_id LIKE 'seed%';
DELETE FROM events WHERE id LIKE 'seed%';

-- Hapus users (optional - hati-hati!)
-- DELETE FROM follows WHERE follower_id LIKE '11111111%' OR following_id LIKE '11111111%';
-- DELETE FROM user_stats WHERE user_id LIKE '11111111%';
-- DELETE FROM user_settings WHERE user_id LIKE '11111111%';
-- DELETE FROM user_privacy WHERE user_id LIKE '11111111%';
-- DELETE FROM users WHERE id LIKE '11111111%';
```

---

## Login untuk Testing

| Email | Password (use your backend) | Role |
|-------|----------------------------|------|
| rudi@anigmaa.com | - | Coffee lover |
| siti@anigmaa.com | - | Foodie |
| budi@anigmaa.com | - | Gamer |
| doni@anigmaa.com | - | Developer |
| maya@anigmaa.com | - | Artist |

---

## Notes

- Semua data menggunakan prefix `seed` untuk ID agar tidak bentrok dengan data lain
- Tanggal events: Jan-Feb 2026 (future dates)
- Semua images dari Unsplash
- Password users: sesuai config backend (default atau dari seeder khusus)

---

## Troubleshooting

**Error: relation does not exist**
→ Pastikan tabel sudah dibuat via migrations dulu

**Error: duplicate key value violates unique constraint**
→ Data sudah ada. Hapus dulu atau uncomment DELETE di awal file

**Error: foreign key violation**
→ Run seed files dalam urutan yang benar (1 → 2 → 3 → 4)

---

Made with ❤️ for Anigmaa
