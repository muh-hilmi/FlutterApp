# Codebase Source of Truth

## Active Navigation
- main.dart routes
- MainNavigationWrapper tabs
- FAB navigation

## Canonical Screens
- DiscoverScreen → lib/presentation/pages/discover/discover_screen.dart
- SwipeableEventsScreen → lib/presentation/pages/events/swipeable_events_screen.dart
- ModernFeedScreen → lib/presentation/pages/feed/modern_feed_screen.dart
- EventDetailScreen → lib/presentation/pages/event_detail/event_detail_screen.dart
- PaymentScreen → lib/presentation/pages/payment/payment_screen.dart

## Rules
- Files NOT reachable from the above are NOT authoritative
- Refactored / duplicate files are INVALID unless explicitly promoted
- AI must NEVER reference files outside the canonical list
