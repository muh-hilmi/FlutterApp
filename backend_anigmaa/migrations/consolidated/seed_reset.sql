-- ============================================================================
-- SEED RESET: Hapus semua data seed lama
-- ============================================================================
-- Run ini dulu SEBELUM seed_01_users.sql
-- ============================================================================

-- Hapus semua data anigmaa (users dengan email anigmaa.com dan terkait)
-- First delete all follows for seed users
DELETE FROM follows WHERE follower_id IN (
    SELECT id FROM users WHERE email LIKE '%anigmaa.com'
) OR following_id IN (
    SELECT id FROM users WHERE email LIKE '%anigmaa.com'
);

-- Hapus user related data
DELETE FROM user_privacy WHERE user_id IN (SELECT id FROM users WHERE email LIKE '%anigmaa.com');
DELETE FROM user_stats WHERE user_id IN (SELECT id FROM users WHERE email LIKE '%anigmaa.com');
DELETE FROM user_settings WHERE user_id IN (SELECT id FROM users WHERE email LIKE '%anigmaa.com');

-- Hapus likes untuk posts seed
DELETE FROM likes WHERE likeable_type = 'post' AND likeable_id IN (
    SELECT id FROM posts WHERE author_id IN (SELECT id FROM users WHERE email LIKE '%anigmaa.com')
);

-- Hapus comments
DELETE FROM comments WHERE author_id IN (SELECT id FROM users WHERE email LIKE '%anigmaa.com');

-- Hapus posts dan images
DELETE FROM post_images WHERE post_id IN (
    SELECT id FROM posts WHERE author_id IN (SELECT id FROM users WHERE email LIKE '%anigmaa.com')
);
DELETE FROM posts WHERE author_id IN (SELECT id FROM users WHERE email LIKE '%anigmaa.com');

-- Hapus event attendees
DELETE FROM event_attendees WHERE event_id IN (
    SELECT id FROM events WHERE host_id IN (SELECT id FROM users WHERE email LIKE '%anigmaa.com')
);

-- Hapus event qna
DELETE FROM event_qna WHERE event_id IN (
    SELECT id FROM events WHERE host_id IN (SELECT id FROM users WHERE email LIKE '%anigmaa.com')
);

-- Hapus event images
DELETE FROM event_images WHERE event_id IN (
    SELECT id FROM events WHERE host_id IN (SELECT id FROM users WHERE email LIKE '%anigmaa.com')
);

-- Hapus events
DELETE FROM events WHERE host_id IN (SELECT id FROM users WHERE email LIKE '%anigmaa.com');

-- Terakhir, hapus users
DELETE FROM users WHERE email LIKE '%anigmaa.com';

-- Selesai! Database siap untuk seed baru
SELECT 'Seed reset complete! Ready for new data.' AS status;
