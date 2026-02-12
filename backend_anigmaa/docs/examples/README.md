# Anigmaa API - Frontend Examples

This directory contains example code and documentation to help frontend developers integrate with the Anigmaa backend API.

## 📁 Files

### Core Files
- **`api-client.js`** - Complete API client implementation with Axios (JavaScript)
- **`types.ts`** - TypeScript type definitions for all API responses
- **`usage-examples.js`** - Common usage examples for various API operations

### Component Examples
- **`react-examples.jsx`** - React component examples
- **`next-example.js`** - Next.js specific examples

## 🚀 Quick Start

### 1. Install Dependencies

```bash
npm install axios
# or
yarn add axios
```

### 2. Copy API Client

Copy `api-client.js` to your project:
```bash
cp docs/examples/api-client.js src/services/api.js
```

### 3. Import and Use

```javascript
import api from './services/api';

// Login
const user = await api.auth.login('user@example.com', 'password');

// Get events
const events = await api.events.getNearby(-6.1751, 106.8650);

// Create post
const post = await api.posts.create({
  content: 'Hello world!',
  type: 'text'
});
```

## 📚 TypeScript Support

For TypeScript projects, use the type definitions:

```typescript
import type { User, Event, Post } from './types';

const user: User = await api.users.getMe();
const events: Event[] = await api.events.getNearby(lat, lng);
```

## 🔐 Authentication

The API client automatically handles authentication:

1. **Login/Register** - Tokens are automatically stored in localStorage
2. **Subsequent requests** - Authorization header is added automatically
3. **Token refresh** - Expired tokens are automatically refreshed
4. **Logout** - Tokens are automatically cleared

### Manual Token Management

If you need to manually manage tokens:

```javascript
// Get token
const token = localStorage.getItem('anigmaa_token');

// Set token manually
localStorage.setItem('anigmaa_token', 'your-token-here');

// Clear token
localStorage.removeItem('anigmaa_token');
localStorage.removeItem('anigmaa_refresh_token');
```

## 🎣 React Hooks

See `usage-examples.js` for custom hooks:

```javascript
import { useAuth, useEvents } from './services/hooks';

function MyComponent() {
  const { user, login, logout } = useAuth();
  const { events, loading, fetchEvents } = useEvents();

  // Use in your component...
}
```

## 🌍 Environment Variables

Set your API URL in environment variables:

```bash
# .env
REACT_APP_API_URL=http://localhost:8081/api/v1

# .env.production
REACT_APP_API_URL=https://api.anigmaa.com/api/v1
```

Or in your code:

```javascript
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8081/api/v1';
```

## 🔄 CORS

The backend allows requests from:
- `http://localhost:3000` (React default)
- `http://localhost:5173` (Vite default)
- `http://localhost:8081` (Backend port)

## ⚠️ Error Handling

All API methods throw errors that you should catch:

```javascript
try {
  const user = await api.auth.login(email, password);
} catch (error) {
  if (error.response) {
    // Server responded with error
    console.error(error.response.data.error);
    console.error('Status:', error.response.status);
  } else if (error.request) {
    // Request made but no response
    console.error('No response from server');
  } else {
    // Other error
    console.error('Error:', error.message);
  }
}
```

## 📖 Common Patterns

### Loading State
```javascript
const [loading, setLoading] = useState(false);
const [data, setData] = useState(null);
const [error, setError] = useState(null);

const fetchData = async () => {
  setLoading(true);
  setError(null);
  try {
    const result = await api.events.getAll();
    setData(result);
  } catch (err) {
    setError(err.response?.data?.error || 'An error occurred');
  } finally {
    setLoading(false);
  }
};
```

### Optimistic Updates
```javascript
const handleLike = async (postId) => {
  // Update UI immediately
  setPosts(posts.map(p =>
    p.id === postId
      ? { ...p, is_liked: true, likes_count: p.likes_count + 1 }
      : p
  ));

  try {
    await api.posts.like(postId);
  } catch (error) {
    // Revert on error
    setPosts(posts.map(p =>
      p.id === postId
        ? { ...p, is_liked: false, likes_count: p.likes_count - 1 }
        : p
    ));
    console.error('Failed to like post:', error);
  }
};
```

### Pagination
```javascript
const [page, setPage] = useState(1);
const [posts, setPosts] = useState([]);

const loadMore = async () => {
  const newPosts = await api.posts.getFeed(page + 1, 20);
  setPosts([...posts, ...newPosts.data]);
  setPage(page + 1);
};
```

## 🧪 Testing

Example with Jest and React Testing Library:

```javascript
import { renderHook, waitFor } from '@testing-library/react';
import { useAuth } from './hooks';

jest.mock('./api-client');

test('login updates user state', async () => {
  const { result } = renderHook(() => useAuth());

  await act(async () => {
    await result.current.login('test@example.com', 'password');
  });

  await waitFor(() => {
    expect(result.current.user).toBeTruthy();
    expect(result.current.isAuthenticated).toBe(true);
  });
});
```

## 📝 Examples

Check `usage-examples.js` for:
- ✅ User registration and login
- ✅ Profile management
- ✅ Event creation and joining
- ✅ Feed and posts
- ✅ Comments and likes
- ✅ Ticket purchasing
- ✅ Complete user flow

## 🔗 Additional Resources

- **API Documentation**: `http://localhost:8081/swagger/index.html`
- **Main Guide**: `../FRONTEND_API_GUIDE.md`
- **Backend README**: `../../README.md`

## 💡 Tips

1. **Use TypeScript** for better type safety and autocomplete
2. **Create custom hooks** for reusable API logic
3. **Handle loading and error states** consistently
4. **Implement optimistic updates** for better UX
5. **Cache API responses** when appropriate
6. **Use React Query or SWR** for advanced data fetching needs

## 🆘 Need Help?

1. Check the Swagger documentation
2. Look at the usage examples
3. Check backend logs for detailed errors
4. Review the type definitions
5. Ask the backend team!

## 📦 Recommended Packages

For better API integration, consider:
- **React Query** / **SWR** - Data fetching and caching
- **Axios** - HTTP client (already included)
- **Zod** - Runtime type validation
- **React Hook Form** - Form handling
- **React Router** - Navigation with auth guards
