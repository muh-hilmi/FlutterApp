/**
 * TypeScript Type Definitions for Anigmaa API
 */

// ============================================================================
// Common Types
// ============================================================================

export type UUID = string;

export interface Timestamps {
  created_at: string;
  updated_at: string;
}

export interface PaginationParams {
  page?: number;
  limit?: number;
}

export interface PaginatedResponse<T> {
  data: T[];
  page: number;
  limit: number;
  total: number;
  total_pages: number;
}

// ============================================================================
// Enums
// ============================================================================

export enum EventStatus {
  UPCOMING = 'upcoming',
  ONGOING = 'ongoing',
  ENDED = 'ended',
  CANCELLED = 'cancelled',
}

export enum EventPrivacy {
  PUBLIC = 'public',
  PRIVATE = 'private',
  FRIENDS_ONLY = 'friends_only',
}

export enum EventCategory {
  MEETUP = 'meetup',
  SPORTS = 'sports',
  WORKSHOP = 'workshop',
  NETWORKING = 'networking',
  FOOD = 'food',
  CREATIVE = 'creative',
  OUTDOOR = 'outdoor',
  FITNESS = 'fitness',
  LEARNING = 'learning',
  SOCIAL = 'social',
}

export enum AttendeeStatus {
  PENDING = 'pending',
  CONFIRMED = 'confirmed',
  CANCELLED = 'cancelled',
}

export enum PostType {
  TEXT = 'text',
  IMAGE = 'image',
  EVENT = 'event',
  POLL = 'poll',
}

export enum TicketStatus {
  ACTIVE = 'active',
  USED = 'used',
  CANCELLED = 'cancelled',
  EXPIRED = 'expired',
}

// ============================================================================
// User Types
// ============================================================================

export interface User {
  id: UUID;
  email: string;
  name: string;
  username: string;
  bio?: string;
  avatar_url?: string;
  is_verified: boolean;
  is_email_verified: boolean;
  created_at: string;
  updated_at: string;
}

export interface UserStats {
  followers_count: number;
  following_count: number;
  posts_count: number;
  events_hosted: number;
  events_attended: number;
}

export interface UserSettings {
  notifications_enabled: boolean;
  email_notifications: boolean;
  push_notifications: boolean;
  privacy_level: 'public' | 'private' | 'friends';
}

// ============================================================================
// Auth Types
// ============================================================================

export interface RegisterRequest {
  email: string;
  password: string;
  name: string;
  username: string;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface AuthResponse {
  access_token: string;
  refresh_token: string;
  user: User;
}

export interface GoogleLoginRequest {
  token: string;
}

// ============================================================================
// Event Types
// ============================================================================

export interface Event {
  id: UUID;
  host_id: UUID;
  host?: User;
  title: string;
  description: string;
  category: EventCategory;
  start_time: string;
  end_time: string;
  location_name: string;
  location_address: string;
  location_lat: number;
  location_lng: number;
  max_attendees: number;
  attendees_count: number;
  price?: number;
  is_free: boolean;
  status: EventStatus;
  privacy: EventPrivacy;
  requirements?: string;
  ticketing_enabled: boolean;
  tickets_sold: number;
  images?: EventImage[];
  created_at: string;
  updated_at: string;
}

export interface EventImage {
  id: UUID;
  event_id: UUID;
  image_url: string;
  order_index: number;
}

export interface EventAttendee {
  id: UUID;
  event_id: UUID;
  user_id: UUID;
  user?: User;
  joined_at: string;
  status: AttendeeStatus;
}

export interface CreateEventRequest {
  title: string;
  description: string;
  category: EventCategory;
  start_time: string;
  end_time: string;
  location_name: string;
  location_address: string;
  location_lat: number;
  location_lng: number;
  max_attendees: number;
  price?: number;
  is_free: boolean;
  privacy?: EventPrivacy;
  requirements?: string;
  ticketing_enabled?: boolean;
  image_urls?: string[];
}

export interface UpdateEventRequest extends Partial<CreateEventRequest> {}

export interface NearbyEventsParams {
  lat: number;
  lng: number;
  radius?: number; // in meters, default 5000
  category?: EventCategory;
}

// ============================================================================
// Post Types
// ============================================================================

export interface Post {
  id: UUID;
  author_id: UUID;
  author?: User;
  content: string;
  type: PostType;
  event_id?: UUID;
  event?: Event;
  likes_count: number;
  comments_count: number;
  reposts_count: number;
  shares_count: number;
  images?: PostImage[];
  is_liked?: boolean;
  is_reposted?: boolean;
  created_at: string;
  updated_at: string;
}

export interface PostImage {
  id: UUID;
  post_id: UUID;
  image_url: string;
  order_index: number;
}

export interface CreatePostRequest {
  content: string;
  type?: PostType;
  event_id?: UUID;
  image_urls?: string[];
}

export interface UpdatePostRequest {
  content: string;
}

// ============================================================================
// Comment Types
// ============================================================================

export interface Comment {
  id: UUID;
  post_id: UUID;
  author_id: UUID;
  author?: User;
  parent_id?: UUID;
  content: string;
  likes_count: number;
  replies_count: number;
  is_liked?: boolean;
  created_at: string;
  updated_at: string;
}

export interface CreateCommentRequest {
  post_id: UUID;
  content: string;
  parent_id?: UUID;
}

export interface UpdateCommentRequest {
  content: string;
}

// ============================================================================
// Ticket Types
// ============================================================================

export interface Ticket {
  id: UUID;
  event_id: UUID;
  event?: Event;
  user_id: UUID;
  user?: User;
  ticket_code: string;
  price: number;
  status: TicketStatus;
  checked_in_at?: string;
  purchased_at: string;
}

export interface PurchaseTicketRequest {
  event_id: UUID;
  quantity: number;
}

export interface CheckInRequest {
  ticket_id: UUID;
}

// ============================================================================
// Profile Types
// ============================================================================

export interface Profile {
  user: User;
  stats: UserStats;
  is_following?: boolean;
  is_followed_by?: boolean;
}

// ============================================================================
// Analytics Types
// ============================================================================

export interface EventAnalytics {
  event_id: UUID;
  event: Event;
  total_attendees: number;
  total_revenue: number;
  tickets_sold: number;
  check_ins: number;
  attendance_rate: number;
  revenue_by_day: Array<{
    date: string;
    revenue: number;
    tickets_sold: number;
  }>;
}

export interface HostRevenueSummary {
  total_revenue: number;
  total_events: number;
  total_tickets_sold: number;
  upcoming_events: number;
  completed_events: number;
  revenue_by_month: Array<{
    month: string;
    revenue: number;
  }>;
}

// ============================================================================
// Error Types
// ============================================================================

export interface APIError {
  error: string;
  details?: string;
  code?: string;
}

// ============================================================================
// Utility Types
// ============================================================================

export interface APIResponse<T> {
  data: T;
  message?: string;
}

export interface Location {
  lat: number;
  lng: number;
}

export interface SearchParams {
  query?: string;
  category?: EventCategory;
  status?: EventStatus;
  sort?: 'start_time' | 'created_at' | 'attendees_count';
  order?: 'asc' | 'desc';
}
