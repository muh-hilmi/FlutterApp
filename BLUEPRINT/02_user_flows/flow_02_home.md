# FLOW 2: Home & Discover

**Journey**: Main app experience

---

## HOME SCREEN (`/home`)

### Layout

```
┌─────────────────────────────────────┐
│ HEADER: "Anigmaa" logo              │
├─────────────────────────────────────┤
│ TABS: [Feed] [Events]              │
├─────────────────────────────────────┤
│                                     │
│  CONTENT (scrollable)               │
│  - Feed: Social posts               │
│  - Events: Event cards grid        │
│                                     │
├─────────────────────────────────────┤
│ BOTTOM NAV: [Home] [Discover] [...] │
└─────────────────────────────────────┘
```

### Feed Tab (Default)

**Content**: Posts from nearby users, sorted by relevance

**Post Card**:
- Avatar, Name, Time
- Text/Photo content
- Tagged event (if any)
- Actions: [❤️ Like] [💬 Comment] [🔗 Share] [⋮ More]

**Interactions**:
- Pull to refresh → Fetch new data
- Infinite scroll → Load more at bottom
- Tap post → View details
- Tap user → Go to profile

**Empty State**: "Belum ada postingan. Jadilah yang pertama!"
**Error State**: "Gagal memuat. Tap untuk retry"

### Events Tab

**Content**: Event cards near user location, 2-column grid

**Event Card**:
- Event photo
- Title, date, price
- Tap → `/event/:id`

**Interactions**:
- Pull to refresh
- Infinite scroll
- Empty state handling

### Bottom Navigation

| Icon | Label | Route |
|------|-------|-------|
| Home | Home | `/home` |
| Discover | Discover | `/discover` |
| Events | Events | `/home` (events tab) |
| Profile | Profil | `/profile` |

### FAB Button

Tap → Bottom sheet: [Buat Event] [Buat Postingan] [Kalender]

**Test Keys**: `home_screen`, `feed_tab`, `events_tab`, `fab_button`

---

## DISCOVER SCREEN (`/discover`)

### Layout

```
┌─────────────────────────────────────┐
│ SEARCH: "Cari event, tempat..."     │
├─────────────────────────────────────┤
│ FILTERS: [Semua] [Musik] [Sport]    │
├─────────────────────────────────────┤
│                                     │
│  SWIPEABLE EVENT CARDS              │
│  ← Swipe left: Skip                 │
│  → Swipe right: Interested          │
│  ↓ Tap: View event detail           │
│                                     │
└─────────────────────────────────────┘
```

### Search

- Type → Debounce 500ms → Show results
- Results: Event cards matching query

### Filters

Categories: [Semua] [Musik] [Workshop] [Sport] [Food] [Art]

### Empty State

"Gak ada event yang cocok. Coba filter lain?"

**Test Keys**: `discover_screen`, `search_bar`, `filter_chip`

---

## NAVIGATION

**From Home**:
- Tap event card → `/event/:id`
- Tap user avatar → `/profile/:id`
- Tap FAB → Show bottom sheet

**From Discover**:
- Tap event card → `/event/:id`
- Tap filter → Apply filter, refresh cards

---

## STATE HANDLING

### Pull to Refresh

1. User pulls down
2. Show loading indicator
3. Fetch new data
4. Update UI with new items on top

### Infinite Scroll

1. Scroll near bottom
2. Show loading spinner
3. Fetch next page
4. Append items
5. Stop when no more data

### Error Handling

| Error | UX |
|-------|-----|
| Network error | "Gagal memuat. Tap untuk retry" |
| Empty data | Empty state message |
| Location denied | "Izinkan lokasi untuk discover" |

---

## IMPLEMENTATION

**Files**:
- `lib/presentation/pages/home/home_screen.dart`
- `lib/presentation/pages/discover/discover_screen.dart`

**BLoCs**:
- `lib/presentation/bloc/feed/feed_bloc.dart`
- `lib/presentation/bloc/event/event_bloc.dart`

**Keys to Add**:
- Home: `home_screen`, `feed_tab`, `events_tab`, `fab_button`
- Discover: `discover_screen`, `search_bar`, `filter_chip_{$category}`
