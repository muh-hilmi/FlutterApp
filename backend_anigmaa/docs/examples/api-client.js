/**
 * Anigmaa API Client - Vanilla JavaScript with Axios
 *
 * Installation:
 * npm install axios
 *
 * Usage:
 * import api from './api-client.js';
 * const user = await api.auth.loginWithGoogle(googleToken);
 *
 * Note: This app uses Google OAuth-only authentication.
 * Traditional email/password authentication has been removed.
 */

import axios from 'axios';

// Configuration
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8081/api/v1';
const TOKEN_KEY = 'anigmaa_token';
const REFRESH_TOKEN_KEY = 'anigmaa_refresh_token';

// Create axios instance
const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor - Add auth token
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem(TOKEN_KEY);
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor - Handle token refresh
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    // If 401 and not already retrying, try to refresh token
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;

      try {
        const refreshToken = localStorage.getItem(REFRESH_TOKEN_KEY);
        if (refreshToken) {
          const response = await axios.post(
            `${API_BASE_URL}/auth/refresh`,
            { refresh_token: refreshToken }
          );

          const { access_token } = response.data;
          localStorage.setItem(TOKEN_KEY, access_token);

          // Retry original request with new token
          originalRequest.headers.Authorization = `Bearer ${access_token}`;
          return apiClient(originalRequest);
        }
      } catch (refreshError) {
        // Refresh failed, logout user
        localStorage.removeItem(TOKEN_KEY);
        localStorage.removeItem(REFRESH_TOKEN_KEY);
        window.location.href = '/login';
        return Promise.reject(refreshError);
      }
    }

    return Promise.reject(error);
  }
);

// Helper to store tokens
const saveTokens = (accessToken, refreshToken) => {
  localStorage.setItem(TOKEN_KEY, accessToken);
  if (refreshToken) {
    localStorage.setItem(REFRESH_TOKEN_KEY, refreshToken);
  }
};

// Helper to clear tokens
const clearTokens = () => {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(REFRESH_TOKEN_KEY);
};

// API Methods
const api = {
  // Auth (Google OAuth only)
  auth: {
    loginWithGoogle: async (googleToken) => {
      const response = await apiClient.post('/auth/google', { token: googleToken });
      const { access_token, refresh_token } = response.data;
      saveTokens(access_token, refresh_token);
      return response.data;
    },

    logout: async () => {
      try {
        await apiClient.post('/auth/logout');
      } finally {
        clearTokens();
      }
    },

    refreshToken: async () => {
      const refreshToken = localStorage.getItem(REFRESH_TOKEN_KEY);
      const response = await apiClient.post('/auth/refresh', { refresh_token: refreshToken });
      const { access_token } = response.data;
      localStorage.setItem(TOKEN_KEY, access_token);
      return response.data;
    },

    verifyEmail: async (token) => {
      const response = await apiClient.post('/auth/verify-email', { token });
      return response.data;
    },

    resendVerificationEmail: async () => {
      const response = await apiClient.post('/auth/resend-verification');
      return response.data;
    },
  },

  // Users
  users: {
    getMe: async () => {
      const response = await apiClient.get('/users/me');
      return response.data;
    },

    updateMe: async (userData) => {
      const response = await apiClient.put('/users/me', userData);
      return response.data;
    },

    updateSettings: async (settings) => {
      const response = await apiClient.put('/users/me/settings', settings);
      return response.data;
    },

    getUserById: async (userId) => {
      const response = await apiClient.get(`/users/${userId}`);
      return response.data;
    },

    getFollowers: async (userId, page = 1, limit = 20) => {
      const response = await apiClient.get(`/users/${userId}/followers`, {
        params: { page, limit },
      });
      return response.data;
    },

    getFollowing: async (userId, page = 1, limit = 20) => {
      const response = await apiClient.get(`/users/${userId}/following`, {
        params: { page, limit },
      });
      return response.data;
    },

    follow: async (userId) => {
      const response = await apiClient.post(`/users/${userId}/follow`);
      return response.data;
    },

    unfollow: async (userId) => {
      const response = await apiClient.delete(`/users/${userId}/follow`);
      return response.data;
    },

    getStats: async (userId) => {
      const response = await apiClient.get(`/users/${userId}/stats`);
      return response.data;
    },
  },

  // Events
  events: {
    getAll: async (params = {}) => {
      const response = await apiClient.get('/events', { params });
      return response.data;
    },

    getNearby: async (lat, lng, radius = 5000) => {
      const response = await apiClient.get('/events/nearby', {
        params: { lat, lng, radius },
      });
      return response.data;
    },

    getById: async (eventId) => {
      const response = await apiClient.get(`/events/${eventId}`);
      return response.data;
    },

    create: async (eventData) => {
      const response = await apiClient.post('/events', eventData);
      return response.data;
    },

    update: async (eventId, eventData) => {
      const response = await apiClient.put(`/events/${eventId}`, eventData);
      return response.data;
    },

    delete: async (eventId) => {
      const response = await apiClient.delete(`/events/${eventId}`);
      return response.data;
    },

    join: async (eventId) => {
      const response = await apiClient.post(`/events/${eventId}/join`);
      return response.data;
    },

    leave: async (eventId) => {
      const response = await apiClient.delete(`/events/${eventId}/join`);
      return response.data;
    },

    getMyEvents: async () => {
      const response = await apiClient.get('/events/my-events');
      return response.data;
    },

    getJoinedEvents: async () => {
      const response = await apiClient.get('/events/joined');
      return response.data;
    },

    getAttendees: async (eventId) => {
      const response = await apiClient.get(`/events/${eventId}/attendees`);
      return response.data;
    },
  },

  // Posts
  posts: {
    getFeed: async (page = 1, limit = 20) => {
      const response = await apiClient.get('/posts/feed', {
        params: { page, limit },
      });
      return response.data;
    },

    getById: async (postId) => {
      const response = await apiClient.get(`/posts/${postId}`);
      return response.data;
    },

    create: async (postData) => {
      const response = await apiClient.post('/posts', postData);
      return response.data;
    },

    update: async (postId, postData) => {
      const response = await apiClient.put(`/posts/${postId}`, postData);
      return response.data;
    },

    delete: async (postId) => {
      const response = await apiClient.delete(`/posts/${postId}`);
      return response.data;
    },

    like: async (postId) => {
      const response = await apiClient.post(`/posts/${postId}/like`);
      return response.data;
    },

    unlike: async (postId) => {
      const response = await apiClient.post(`/posts/${postId}/unlike`);
      return response.data;
    },

    repost: async (postId) => {
      const response = await apiClient.post('/posts/repost', { post_id: postId });
      return response.data;
    },

    undoRepost: async (postId) => {
      const response = await apiClient.post(`/posts/${postId}/undo-repost`);
      return response.data;
    },

    getComments: async (postId, page = 1, limit = 20) => {
      const response = await apiClient.get(`/posts/${postId}/comments`, {
        params: { page, limit },
      });
      return response.data;
    },

    addComment: async (postId, content, parentId = null) => {
      const response = await apiClient.post('/posts/comments', {
        post_id: postId,
        content,
        parent_id: parentId,
      });
      return response.data;
    },

    updateComment: async (commentId, content) => {
      const response = await apiClient.put(`/posts/comments/${commentId}`, { content });
      return response.data;
    },

    deleteComment: async (commentId) => {
      const response = await apiClient.delete(`/posts/comments/${commentId}`);
      return response.data;
    },
  },

  // Tickets
  tickets: {
    purchase: async (eventId, quantity = 1) => {
      const response = await apiClient.post('/tickets/purchase', {
        event_id: eventId,
        quantity,
      });
      return response.data;
    },

    getMyTickets: async () => {
      const response = await apiClient.get('/tickets/my-tickets');
      return response.data;
    },

    getById: async (ticketId) => {
      const response = await apiClient.get(`/tickets/${ticketId}`);
      return response.data;
    },

    checkIn: async (ticketId) => {
      const response = await apiClient.post('/tickets/check-in', {
        ticket_id: ticketId,
      });
      return response.data;
    },

    cancel: async (ticketId) => {
      const response = await apiClient.post(`/tickets/${ticketId}/cancel`);
      return response.data;
    },
  },

  // Profile (DEPRECATED - username lookup removed)
  // These endpoints will always return 404 since usernames no longer exist
  // Use api.users.getUserById(userId) instead
  profile: {
    getByUsername: async (username) => {
      console.warn('DEPRECATED: profile.getByUsername() - usernames no longer exist. Use users.getUserById() instead.');
      const response = await apiClient.get(`/profile/${username}`);
      return response.data;
    },

    getPosts: async (username, page = 1, limit = 20) => {
      console.warn('DEPRECATED: profile.getPosts() - usernames no longer exist.');
      const response = await apiClient.get(`/profile/${username}/posts`, {
        params: { page, limit },
      });
      return response.data;
    },

    getEvents: async (username) => {
      console.warn('DEPRECATED: profile.getEvents() - usernames no longer exist.');
      const response = await apiClient.get(`/profile/${username}/events`);
      return response.data;
    },
  },

  // Analytics
  analytics: {
    getEventAnalytics: async (eventId) => {
      const response = await apiClient.get(`/analytics/events/${eventId}`);
      return response.data;
    },

    getEventTransactions: async (eventId) => {
      const response = await apiClient.get(`/analytics/events/${eventId}/transactions`);
      return response.data;
    },

    getHostRevenue: async () => {
      const response = await apiClient.get('/analytics/host/revenue');
      return response.data;
    },

    getHostEvents: async () => {
      const response = await apiClient.get('/analytics/host/events');
      return response.data;
    },
  },
};

export default api;
