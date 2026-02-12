/**
 * Anigmaa API - Common Usage Examples
 *
 * This file demonstrates common use cases for the Anigmaa API
 */

import api from './api-client.js';

// ============================================================================
// Authentication Examples
// ============================================================================

/**
 * Example 1: User Registration
 */
async function registerUser() {
  try {
    const userData = {
      email: 'john@example.com',
      password: 'SecurePass123!',
      name: 'John Doe',
      username: 'johndoe',
    };

    const response = await api.auth.register(userData);
    console.log('Registration successful:', response.user);
    // Token is automatically stored in localStorage
  } catch (error) {
    console.error('Registration failed:', error.response?.data || error.message);
  }
}

/**
 * Example 2: User Login
 */
async function loginUser() {
  try {
    const response = await api.auth.login('john@example.com', 'SecurePass123!');
    console.log('Login successful:', response.user);
    return response.user;
  } catch (error) {
    console.error('Login failed:', error.response?.data || error.message);
    throw error;
  }
}

/**
 * Example 3: Google OAuth Login
 */
async function loginWithGoogle(googleToken) {
  try {
    const response = await api.auth.loginWithGoogle(googleToken);
    console.log('Google login successful:', response.user);
    return response.user;
  } catch (error) {
    console.error('Google login failed:', error.response?.data || error.message);
    throw error;
  }
}

/**
 * Example 4: Logout
 */
async function logout() {
  try {
    await api.auth.logout();
    console.log('Logged out successfully');
    window.location.href = '/login';
  } catch (error) {
    console.error('Logout failed:', error.response?.data || error.message);
  }
}

// ============================================================================
// User Profile Examples
// ============================================================================

/**
 * Example 5: Get Current User Profile
 */
async function getCurrentUser() {
  try {
    const user = await api.users.getMe();
    console.log('Current user:', user);
    return user;
  } catch (error) {
    console.error('Failed to get user:', error.response?.data || error.message);
    throw error;
  }
}

/**
 * Example 6: Update User Profile
 */
async function updateProfile() {
  try {
    const updates = {
      name: 'John Updated',
      bio: 'Coffee enthusiast | Event organizer 🎉',
      avatar_url: 'https://example.com/avatar.jpg',
    };

    const updatedUser = await api.users.updateMe(updates);
    console.log('Profile updated:', updatedUser);
    return updatedUser;
  } catch (error) {
    console.error('Profile update failed:', error.response?.data || error.message);
    throw error;
  }
}

/**
 * Example 7: Follow/Unfollow User
 */
async function followUser(userId) {
  try {
    await api.users.follow(userId);
    console.log(`Successfully followed user ${userId}`);
  } catch (error) {
    console.error('Follow failed:', error.response?.data || error.message);
  }
}

async function unfollowUser(userId) {
  try {
    await api.users.unfollow(userId);
    console.log(`Successfully unfollowed user ${userId}`);
  } catch (error) {
    console.error('Unfollow failed:', error.response?.data || error.message);
  }
}

// ============================================================================
// Event Examples
// ============================================================================

/**
 * Example 8: Create New Event
 */
async function createEvent() {
  try {
    const eventData = {
      title: 'Coffee Meetup at Central Park',
      description: 'Let\'s grab coffee and chat about tech, startups, and life!',
      category: 'coffee',
      start_time: new Date('2025-12-15T14:00:00Z').toISOString(),
      end_time: new Date('2025-12-15T16:00:00Z').toISOString(),
      location_name: 'Starbucks Central Park',
      location_address: 'Central Park Mall, Jakarta Barat',
      location_lat: -6.1751,
      location_lng: 106.8650,
      max_attendees: 10,
      is_free: true,
      privacy: 'public',
    };

    const event = await api.events.create(eventData);
    console.log('Event created:', event);
    return event;
  } catch (error) {
    console.error('Event creation failed:', error.response?.data || error.message);
    throw error;
  }
}

/**
 * Example 9: Get Nearby Events
 */
async function getNearbyEvents(userLat, userLng) {
  try {
    const events = await api.events.getNearby(userLat, userLng, 5000); // 5km radius
    console.log(`Found ${events.length} nearby events`);
    return events;
  } catch (error) {
    console.error('Failed to get nearby events:', error.response?.data || error.message);
    throw error;
  }
}

/**
 * Example 10: Join Event
 */
async function joinEvent(eventId) {
  try {
    await api.events.join(eventId);
    console.log(`Successfully joined event ${eventId}`);
  } catch (error) {
    console.error('Failed to join event:', error.response?.data || error.message);
    throw error;
  }
}

/**
 * Example 11: Get User's Events
 */
async function getMyEvents() {
  try {
    const hostedEvents = await api.events.getMyEvents();
    const joinedEvents = await api.events.getJoinedEvents();

    console.log('Hosted events:', hostedEvents);
    console.log('Joined events:', joinedEvents);

    return { hostedEvents, joinedEvents };
  } catch (error) {
    console.error('Failed to get events:', error.response?.data || error.message);
    throw error;
  }
}

// ============================================================================
// Post/Feed Examples
// ============================================================================

/**
 * Example 12: Get Feed
 */
async function getFeed(page = 1) {
  try {
    const feed = await api.posts.getFeed(page, 20);
    console.log(`Loaded ${feed.data.length} posts`);
    return feed;
  } catch (error) {
    console.error('Failed to get feed:', error.response?.data || error.message);
    throw error;
  }
}

/**
 * Example 13: Create Post
 */
async function createPost(content, eventId = null) {
  try {
    const postData = {
      content,
      type: eventId ? 'event' : 'text',
      event_id: eventId,
    };

    const post = await api.posts.create(postData);
    console.log('Post created:', post);
    return post;
  } catch (error) {
    console.error('Failed to create post:', error.response?.data || error.message);
    throw error;
  }
}

/**
 * Example 14: Like/Unlike Post
 */
async function togglePostLike(postId, isLiked) {
  try {
    if (isLiked) {
      await api.posts.unlike(postId);
      console.log(`Unliked post ${postId}`);
    } else {
      await api.posts.like(postId);
      console.log(`Liked post ${postId}`);
    }
  } catch (error) {
    console.error('Failed to toggle like:', error.response?.data || error.message);
    throw error;
  }
}

/**
 * Example 15: Add Comment to Post
 */
async function addComment(postId, content, parentCommentId = null) {
  try {
    const comment = await api.posts.addComment(postId, content, parentCommentId);
    console.log('Comment added:', comment);
    return comment;
  } catch (error) {
    console.error('Failed to add comment:', error.response?.data || error.message);
    throw error;
  }
}

/**
 * Example 16: Repost
 */
async function repostPost(postId) {
  try {
    const repost = await api.posts.repost(postId);
    console.log('Post reposted:', repost);
    return repost;
  } catch (error) {
    console.error('Failed to repost:', error.response?.data || error.message);
    throw error;
  }
}

// ============================================================================
// Ticket Examples
// ============================================================================

/**
 * Example 17: Purchase Ticket
 */
async function purchaseTicket(eventId, quantity = 1) {
  try {
    const ticket = await api.tickets.purchase(eventId, quantity);
    console.log('Ticket purchased:', ticket);
    return ticket;
  } catch (error) {
    console.error('Failed to purchase ticket:', error.response?.data || error.message);
    throw error;
  }
}

/**
 * Example 18: Get My Tickets
 */
async function getMyTickets() {
  try {
    const tickets = await api.tickets.getMyTickets();
    console.log(`You have ${tickets.length} tickets`);
    return tickets;
  } catch (error) {
    console.error('Failed to get tickets:', error.response?.data || error.message);
    throw error;
  }
}

// ============================================================================
// Profile Examples
// ============================================================================

/**
 * Example 19: View User Profile
 */
async function viewProfile(username) {
  try {
    const profile = await api.profile.getByUsername(username);
    const posts = await api.profile.getPosts(username);
    const events = await api.profile.getEvents(username);

    console.log('Profile:', profile);
    console.log('User posts:', posts);
    console.log('User events:', events);

    return { profile, posts, events };
  } catch (error) {
    console.error('Failed to load profile:', error.response?.data || error.message);
    throw error;
  }
}

// ============================================================================
// Complete User Flow Example
// ============================================================================

/**
 * Example 20: Complete User Flow
 * This demonstrates a typical user journey through the app
 */
async function completeUserFlow() {
  try {
    console.log('=== Starting Complete User Flow ===\n');

    // 1. Register/Login
    console.log('Step 1: Login...');
    const user = await loginUser();
    console.log(`✓ Logged in as ${user.username}\n`);

    // 2. Get current user profile
    console.log('Step 2: Getting profile...');
    const currentUser = await getCurrentUser();
    console.log(`✓ Profile loaded\n`);

    // 3. Get nearby events
    console.log('Step 3: Finding nearby events...');
    const nearbyEvents = await getNearbyEvents(-6.1751, 106.8650);
    console.log(`✓ Found ${nearbyEvents.length} events\n`);

    // 4. Join an event
    if (nearbyEvents.length > 0) {
      console.log('Step 4: Joining first event...');
      await joinEvent(nearbyEvents[0].id);
      console.log(`✓ Joined event: ${nearbyEvents[0].title}\n`);
    }

    // 5. Create a post
    console.log('Step 5: Creating a post...');
    const post = await createPost('Just joined an awesome coffee meetup! ☕');
    console.log(`✓ Post created with ID: ${post.id}\n`);

    // 6. Get feed
    console.log('Step 6: Loading feed...');
    const feed = await getFeed();
    console.log(`✓ Loaded ${feed.data.length} posts in feed\n`);

    // 7. Like the first post in feed
    if (feed.data.length > 0) {
      console.log('Step 7: Liking first post...');
      await togglePostLike(feed.data[0].id, false);
      console.log(`✓ Liked post\n`);
    }

    console.log('=== User Flow Completed Successfully ===');
  } catch (error) {
    console.error('User flow failed:', error);
  }
}

// ============================================================================
// React Hook Examples
// ============================================================================

/**
 * Example 21: Custom React Hook for Events
 */
export function useEvents() {
  const [events, setEvents] = React.useState([]);
  const [loading, setLoading] = React.useState(false);
  const [error, setError] = React.useState(null);

  const fetchEvents = async (lat, lng) => {
    setLoading(true);
    setError(null);
    try {
      const data = await api.events.getNearby(lat, lng);
      setEvents(data);
    } catch (err) {
      setError(err.response?.data?.error || 'Failed to fetch events');
    } finally {
      setLoading(false);
    }
  };

  const joinEvent = async (eventId) => {
    try {
      await api.events.join(eventId);
      // Refresh events after joining
      fetchEvents();
    } catch (err) {
      throw err;
    }
  };

  return { events, loading, error, fetchEvents, joinEvent };
}

/**
 * Example 22: Custom React Hook for Auth
 */
export function useAuth() {
  const [user, setUser] = React.useState(null);
  const [loading, setLoading] = React.useState(true);

  React.useEffect(() => {
    // Check if user is already logged in
    const checkAuth = async () => {
      try {
        const currentUser = await api.users.getMe();
        setUser(currentUser);
      } catch (error) {
        setUser(null);
      } finally {
        setLoading(false);
      }
    };

    checkAuth();
  }, []);

  const login = async (email, password) => {
    const response = await api.auth.login(email, password);
    setUser(response.user);
    return response.user;
  };

  const logout = async () => {
    await api.auth.logout();
    setUser(null);
  };

  return { user, loading, login, logout, isAuthenticated: !!user };
}

// Export all examples
export {
  registerUser,
  loginUser,
  loginWithGoogle,
  logout,
  getCurrentUser,
  updateProfile,
  followUser,
  unfollowUser,
  createEvent,
  getNearbyEvents,
  joinEvent,
  getMyEvents,
  getFeed,
  createPost,
  togglePostLike,
  addComment,
  repostPost,
  purchaseTicket,
  getMyTickets,
  viewProfile,
  completeUserFlow,
};
