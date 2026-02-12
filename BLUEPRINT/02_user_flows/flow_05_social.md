# FLOW 5: Social Features

**Journey**: Create post → Interact with posts

---

## CREATE POST (`/create-post`)

### Trigger

- Tap FAB on home → Select "Buat Postingan"

### Layout

```
┌─────────────────────────────────────┐
│ [✕] Buat Postingan          [POST] │
├─────────────────────────────────────┤
│   [+ ADD PHOTO/VIDEO]               │
│                                     │
├─────────────────────────────────────┤
│ Apa yang happening?                 │
│ [Text field - max 500 chars]        │
├─────────────────────────────────────┤
│ Tag event (optional)                │
│ [Search event dropdown]             │
├─────────────────────────────────────┤
│ Location: [Use current location]    │
└─────────────────────────────────────┘
```

### Actions

| Element | Action |
|---------|--------|
| [+] ADD PHOTO | Open image picker |
| Text field | Type text (count updates) |
| Tag event | Search & select event |
| Location | Auto-detect or manual |

### Post Button

- Disabled if: No text, no photo, no event
- Enabled if: Has content
- Tap → Show loading → Create post → Return to feed

### Success

- Snackbar: "Postingan berhasil!"
- New post appears at top of feed

### Cancel

- Tap [✕] with content
- Dialog: "Discard post?" [Keep Editing] [Discard]

**Test Keys**: `create_post_screen`, `post_button`, `add_photo_button`

---

## POST INTERACTIONS

### On Post Card

```
┌─────────────────────────────────────┐
│ [Avatar] [Name] • [Time]    [⋮]     │
├─────────────────────────────────────┤
│ [Post Content - text/photos]        │
│                                     │
│ If tagged event:                    │
│ 📍 [Event Name]                     │
├─────────────────────────────────────┤
│ [❤️ 12] [💬 5] [🔗 Share]           │
└─────────────────────────────────────┘
```

### Actions

| Element | Action |
|---------|--------|
| [❤️] Like | Toggle like, animate, update count (optimistic) |
| [💬] Comment | Open bottom sheet with comments |
| [🔗] Share | Open share dialog |
| [⋮] More | Bottom sheet: Save, Report, Hide (own), Delete (own) |

### Like Flow

1. Tap [❤️]
2. Toggle icon (filled/outline)
3. Update count immediately
4. Call API
5. If failed → Revert, show error

### Comment Flow

1. Tap [💬]
2. Open bottom sheet with comments
3. See all comments → `/post/:id/comments`

**Test Keys**: `post_card_{$id}`, `like_button`, `comment_button`

---

## COMMENTS SCREEN (`/post/:id/comments`)

### Layout

```
┌─────────────────────────────────────┐
│ [←] Comments                        │
├─────────────────────────────────────┤
│ SCROLLABLE COMMENTS:                │
│ ┌─────────────────────────────────┐ │
│ │ [Avatar] [Name]        [Time]   │ │
│ │ [Comment text]                 │ │
│ │ [❤️] [Reply]          [3]      │ │
│ └─────────────────────────────────┘ │
│ ...more comments...                  │
├─────────────────────────────────────┤
│ INPUT:                              │
│ [Add a comment...]        [SEND]    │
└─────────────────────────────────────┘
```

### Actions

- Type comment → [SEND] enables
- Tap [SEND] → Post → Add to list immediately
- Tap [❤️] → Like comment
- Tap [Reply] → Focus input with @username

### Empty State

"Belum ada komentar. Jadilah yang pertama!"

**Test Keys**: `comments_screen`, `comment_input`, `send_button`

---

## POST MENU (⋮)

### Bottom Sheet Options

| Option | Owner? | Action |
|--------|--------|--------|
| Save Post | No | Save to profile |
| Report Post | No | Report content |
| Hide Post | Yes | Hide from feed |
| Delete Post | Yes | Delete permanently |

---

## FLOW DIAGRAM

```
Home → FAB → Create Post
         ↓
      Add content (photo/text/event)
         ↓
      [POST] → API → Success → Back to feed
                              ↓
                           Post appears

Feed → Tap post → Like/Comment/Share
                ↓
             Comments → Add comment
```

---

## IMPLEMENTATION

**Files**:
- `lib/presentation/pages/post/create_post_screen.dart`
- `lib/presentation/pages/post/comments_screen.dart`
- `lib/presentation/widgets/posts/modern_post_card.dart`

**BLoCs**:
- `lib/presentation/bloc/post/post_bloc.dart`
- `lib/presentation/bloc/comment/comment_bloc.dart`
