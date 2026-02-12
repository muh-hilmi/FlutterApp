/**
 * React Component Examples for Anigmaa API
 */

import React, { useState, useEffect } from 'react';
import api from './api-client';

// ============================================================================
// Example 1: Login Form Component
// ============================================================================

export function LoginForm() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const response = await api.auth.login(email, password);
      console.log('Login successful:', response.user);
      // Redirect to dashboard
      window.location.href = '/dashboard';
    } catch (err) {
      setError(err.response?.data?.error || 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="login-form">
      <h2>Login</h2>

      {error && <div className="error">{error}</div>}

      <input
        type="email"
        placeholder="Email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        required
      />

      <input
        type="password"
        placeholder="Password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        required
      />

      <button type="submit" disabled={loading}>
        {loading ? 'Logging in...' : 'Login'}
      </button>
    </form>
  );
}

// ============================================================================
// Example 2: Events List Component
// ============================================================================

export function EventsList() {
  const [events, setEvents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchEvents();
  }, []);

  const fetchEvents = async () => {
    try {
      // Get user's location
      navigator.geolocation.getCurrentPosition(
        async (position) => {
          const { latitude, longitude } = position.coords;
          const data = await api.events.getNearby(latitude, longitude);
          setEvents(data);
          setLoading(false);
        },
        (err) => {
          console.error('Location error:', err);
          // Fallback to Jakarta coordinates
          api.events.getNearby(-6.1751, 106.8650).then((data) => {
            setEvents(data);
            setLoading(false);
          });
        }
      );
    } catch (err) {
      setError(err.response?.data?.error || 'Failed to load events');
      setLoading(false);
    }
  };

  const handleJoin = async (eventId) => {
    try {
      await api.events.join(eventId);
      // Refresh events list
      fetchEvents();
    } catch (err) {
      alert(err.response?.data?.error || 'Failed to join event');
    }
  };

  if (loading) return <div>Loading events...</div>;
  if (error) return <div>Error: {error}</div>;

  return (
    <div className="events-list">
      <h2>Nearby Events</h2>
      {events.length === 0 ? (
        <p>No events found nearby</p>
      ) : (
        events.map((event) => (
          <div key={event.id} className="event-card">
            <h3>{event.title}</h3>
            <p>{event.description}</p>
            <p>📍 {event.location_name}</p>
            <p>👥 {event.attendees_count}/{event.max_attendees}</p>
            <p>📅 {new Date(event.start_time).toLocaleString()}</p>
            <button onClick={() => handleJoin(event.id)}>
              Join Event
            </button>
          </div>
        ))
      )}
    </div>
  );
}

// ============================================================================
// Example 3: Create Event Form
// ============================================================================

export function CreateEventForm() {
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    category: 'coffee',
    start_time: '',
    end_time: '',
    location_name: '',
    location_address: '',
    location_lat: -6.1751,
    location_lng: 106.8650,
    max_attendees: 10,
    is_free: true,
  });
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData({
      ...formData,
      [name]: type === 'checkbox' ? checked : value,
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      const event = await api.events.create(formData);
      console.log('Event created:', event);
      setSuccess(true);
      // Reset form or redirect
      setTimeout(() => {
        window.location.href = `/events/${event.id}`;
      }, 1500);
    } catch (err) {
      alert(err.response?.data?.error || 'Failed to create event');
      setLoading(false);
    }
  };

  if (success) {
    return <div className="success">Event created successfully! Redirecting...</div>;
  }

  return (
    <form onSubmit={handleSubmit} className="create-event-form">
      <h2>Create New Event</h2>

      <input
        type="text"
        name="title"
        placeholder="Event Title"
        value={formData.title}
        onChange={handleChange}
        required
      />

      <textarea
        name="description"
        placeholder="Event Description"
        value={formData.description}
        onChange={handleChange}
        required
      />

      <select name="category" value={formData.category} onChange={handleChange}>
        <option value="coffee">Coffee</option>
        <option value="food">Food</option>
        <option value="gaming">Gaming</option>
        <option value="sports">Sports</option>
        <option value="music">Music</option>
        <option value="movies">Movies</option>
        <option value="study">Study</option>
        <option value="art">Art</option>
        <option value="other">Other</option>
      </select>

      <input
        type="datetime-local"
        name="start_time"
        value={formData.start_time}
        onChange={handleChange}
        required
      />

      <input
        type="datetime-local"
        name="end_time"
        value={formData.end_time}
        onChange={handleChange}
        required
      />

      <input
        type="text"
        name="location_name"
        placeholder="Location Name"
        value={formData.location_name}
        onChange={handleChange}
        required
      />

      <input
        type="text"
        name="location_address"
        placeholder="Location Address"
        value={formData.location_address}
        onChange={handleChange}
        required
      />

      <input
        type="number"
        name="max_attendees"
        placeholder="Max Attendees"
        value={formData.max_attendees}
        onChange={handleChange}
        required
        min="1"
      />

      <label>
        <input
          type="checkbox"
          name="is_free"
          checked={formData.is_free}
          onChange={handleChange}
        />
        Free Event
      </label>

      <button type="submit" disabled={loading}>
        {loading ? 'Creating...' : 'Create Event'}
      </button>
    </form>
  );
}

// ============================================================================
// Example 4: Feed Component
// ============================================================================

export function Feed() {
  const [posts, setPosts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);

  useEffect(() => {
    loadFeed();
  }, []);

  const loadFeed = async () => {
    try {
      const response = await api.posts.getFeed(1, 20);
      setPosts(response.data);
      setHasMore(response.page < response.total_pages);
      setLoading(false);
    } catch (err) {
      console.error('Failed to load feed:', err);
      setLoading(false);
    }
  };

  const loadMore = async () => {
    const nextPage = page + 1;
    const response = await api.posts.getFeed(nextPage, 20);
    setPosts([...posts, ...response.data]);
    setPage(nextPage);
    setHasMore(response.page < response.total_pages);
  };

  const handleLike = async (postId, isLiked) => {
    // Optimistic update
    setPosts(posts.map((p) =>
      p.id === postId
        ? {
            ...p,
            is_liked: !isLiked,
            likes_count: p.likes_count + (isLiked ? -1 : 1),
          }
        : p
    ));

    try {
      if (isLiked) {
        await api.posts.unlike(postId);
      } else {
        await api.posts.like(postId);
      }
    } catch (err) {
      // Revert on error
      setPosts(posts.map((p) =>
        p.id === postId
          ? {
              ...p,
              is_liked: isLiked,
              likes_count: p.likes_count + (isLiked ? 1 : -1),
            }
          : p
      ));
      console.error('Failed to like post:', err);
    }
  };

  if (loading) return <div>Loading feed...</div>;

  return (
    <div className="feed">
      <h2>Feed</h2>

      {posts.map((post) => (
        <div key={post.id} className="post-card">
          <div className="post-header">
            <img src={post.author?.avatar_url} alt={post.author?.name} />
            <div>
              <h4>{post.author?.name}</h4>
              <span>@{post.author?.username}</span>
            </div>
          </div>

          <p className="post-content">{post.content}</p>

          {post.event && (
            <div className="post-event">
              <h5>📅 {post.event.title}</h5>
              <p>{post.event.location_name}</p>
            </div>
          )}

          <div className="post-actions">
            <button
              onClick={() => handleLike(post.id, post.is_liked)}
              className={post.is_liked ? 'liked' : ''}
            >
              ❤️ {post.likes_count}
            </button>
            <button>💬 {post.comments_count}</button>
            <button>🔄 {post.reposts_count}</button>
          </div>
        </div>
      ))}

      {hasMore && (
        <button onClick={loadMore} className="load-more">
          Load More
        </button>
      )}
    </div>
  );
}

// ============================================================================
// Example 5: User Profile Component
// ============================================================================

export function UserProfile({ username }) {
  const [profile, setProfile] = useState(null);
  const [posts, setPosts] = useState([]);
  const [events, setEvents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('posts');

  useEffect(() => {
    loadProfile();
  }, [username]);

  const loadProfile = async () => {
    try {
      const [profileData, postsData, eventsData] = await Promise.all([
        api.profile.getByUsername(username),
        api.profile.getPosts(username),
        api.profile.getEvents(username),
      ]);

      setProfile(profileData);
      setPosts(postsData.data || postsData);
      setEvents(eventsData);
      setLoading(false);
    } catch (err) {
      console.error('Failed to load profile:', err);
      setLoading(false);
    }
  };

  const handleFollow = async () => {
    try {
      if (profile.is_following) {
        await api.users.unfollow(profile.user.id);
      } else {
        await api.users.follow(profile.user.id);
      }
      // Refresh profile
      loadProfile();
    } catch (err) {
      console.error('Failed to follow/unfollow:', err);
    }
  };

  if (loading) return <div>Loading profile...</div>;
  if (!profile) return <div>Profile not found</div>;

  return (
    <div className="profile">
      <div className="profile-header">
        <img src={profile.user.avatar_url} alt={profile.user.name} />
        <h2>{profile.user.name}</h2>
        <p>@{profile.user.username}</p>
        <p>{profile.user.bio}</p>

        <div className="profile-stats">
          <div>
            <strong>{profile.stats.followers_count}</strong>
            <span>Followers</span>
          </div>
          <div>
            <strong>{profile.stats.following_count}</strong>
            <span>Following</span>
          </div>
          <div>
            <strong>{profile.stats.posts_count}</strong>
            <span>Posts</span>
          </div>
        </div>

        <button onClick={handleFollow}>
          {profile.is_following ? 'Unfollow' : 'Follow'}
        </button>
      </div>

      <div className="profile-tabs">
        <button
          onClick={() => setActiveTab('posts')}
          className={activeTab === 'posts' ? 'active' : ''}
        >
          Posts
        </button>
        <button
          onClick={() => setActiveTab('events')}
          className={activeTab === 'events' ? 'active' : ''}
        >
          Events
        </button>
      </div>

      <div className="profile-content">
        {activeTab === 'posts' ? (
          <div className="posts-grid">
            {posts.map((post) => (
              <div key={post.id} className="post-card">
                <p>{post.content}</p>
                <small>{new Date(post.created_at).toLocaleDateString()}</small>
              </div>
            ))}
          </div>
        ) : (
          <div className="events-grid">
            {events.map((event) => (
              <div key={event.id} className="event-card">
                <h4>{event.title}</h4>
                <p>{event.location_name}</p>
                <small>{new Date(event.start_time).toLocaleDateString()}</small>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

// ============================================================================
// Example 6: Protected Route Wrapper
// ============================================================================

export function ProtectedRoute({ children }) {
  const [isAuthenticated, setIsAuthenticated] = useState(null);

  useEffect(() => {
    checkAuth();
  }, []);

  const checkAuth = async () => {
    try {
      await api.users.getMe();
      setIsAuthenticated(true);
    } catch (err) {
      setIsAuthenticated(false);
      window.location.href = '/login';
    }
  };

  if (isAuthenticated === null) {
    return <div>Loading...</div>;
  }

  return isAuthenticated ? children : null;
}
