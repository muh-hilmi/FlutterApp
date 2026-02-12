-- ============================================================================
-- FULL RESET: Hapus SEMUA data (kecuali user mailhilmi@gmail.com)
-- ============================================================================

-- Hapus likes
DELETE FROM likes WHERE likeable_type = 'post' AND likeable_id IN (SELECT id FROM posts);
DELETE FROM likes WHERE likeable_type = 'comment' AND likeable_id IN (SELECT id FROM comments);

-- Hapus comments
DELETE FROM comments;

-- Hapus post images
DELETE FROM post_images;

-- Hapus posts
DELETE FROM posts;

-- Hapus reposts, shares, bookmarks
DELETE FROM reposts;
DELETE FROM shares;
DELETE FROM bookmarks;

-- Hapus event attendees
DELETE FROM event_attendees;

-- Hapus event interests
DELETE FROM event_interests;

-- Hapus event qna
DELETE FROM qna_upvotes;
DELETE FROM event_qna;

-- Hapus event images
DELETE FROM event_images;

-- Hapus events
DELETE FROM events;

-- Hapus reviews
DELETE FROM reviews;

-- Hapus notifications
DELETE FROM notifications;

-- Hapus tickets
DELETE FROM ticket_transactions;
DELETE FROM tickets;

-- Hapus communities & members
DELETE FROM community_members;
DELETE FROM communities;

-- Hapus invitations
DELETE FROM invitations;

-- Hapus follows
DELETE FROM follows;

-- Hapus auth tokens
DELETE FROM auth_tokens;

-- Hapus user related data
DELETE FROM user_privacy;
DELETE FROM user_stats;
DELETE FROM user_settings;

-- Hapus users (KECUALI mailhilmi@gmail.com)
DELETE FROM users WHERE email != 'mailhilmi@gmail.com';

SELECT 'Full reset complete!' AS status;
SELECT 'Remaining users:' as check_type, COUNT(*) FROM users;
