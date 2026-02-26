-- Database Integrity Check

SELECT 'Posts with invalid author' as check_type, COUNT(*) FROM posts p WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.id = p.author_id);

SELECT 'Posts with invalid event' as check_type, COUNT(*) FROM posts p WHERE p.attached_event_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM events e WHERE e.id = p.attached_event_id);

SELECT 'Events with invalid host' as check_type, COUNT(*) FROM events e WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.id = e.host_id);

SELECT 'Attendees with invalid event' as check_type, COUNT(*) FROM event_attendees ea WHERE NOT EXISTS (SELECT 1 FROM events e WHERE e.id = ea.event_id);

SELECT 'Attendees with invalid user' as check_type, COUNT(*) FROM event_attendees ea WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.id = ea.user_id);

SELECT 'Total Users' as check_type, COUNT(*) FROM users;
SELECT 'Total Events' as check_type, COUNT(*) FROM events;
SELECT 'Total Posts' as check_type, COUNT(*) FROM posts;
SELECT 'Total Attendees' as check_type, COUNT(*) FROM event_attendees;
SELECT 'Total Event Images' as check_type, COUNT(*) FROM event_images;
SELECT 'Total Post Images' as check_type, COUNT(*) FROM post_images;
