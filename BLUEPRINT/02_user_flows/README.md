# 02. USER FLOWS

Complete user flows for every screen in V1.

---

## FLOW INDEX

| # | Flow | File | Key Screens |
|---|------|------|-------------|
| 1 | First Time User | [`flow_01_new_user.md`](./flow_01_new_user.md) | Splash → Onboarding → Login → Complete Profile → Home |
| 2 | Main App Experience | [`flow_02_home.md`](./flow_02_home.md) | Home (Feed/Events), Discover |
| 3 | Event Interaction | [`flow_03_event.md`](./flow_03_event.md) | Event Detail → Buy Ticket → QR Ticket |
| 4 | Profile & Settings | [`flow_04_profile.md`](./flow_04_profile.md) | Profile, Edit Profile, Settings, Logout |
| 5 | Social Features | [`flow_05_social.md`](./flow_05_social.md) | Create Post, Comments, Likes, Share |
| 6 | Host Event Management | [`flow_07_host_management.md`](./flow_07_host_management.md) | My Events → Edit/Delete Event → Check-in Attendees |
| 7 | Edge Cases | [`flow_06_edge_cases.md`](./flow_06_edge_cases.md) | Server Unavailable, Permissions, Session Expired |

---

## NAVIGATION GRAPH

```
                    ┌─────────────┐
                    │   SPLASH    │
                    └──────┬──────┘
                           │
                ┌──────────┴──────────┐
                │                     │
           No token?            Has token?
                │                     │
                ▼                     ▼
        ┌───────────┐         ┌──────────┐
        │ ONBOARDING│         │   HOME   │
        └─────┬─────┘         └──────────┘
              │
              ▼
        ┌───────────┐
        │   LOGIN   │
        └─────┬─────┘
              │
       ┌──────┴──────┐
       │             │
  New user?    Existing user
       │             │
       ▼             ▼
┌──────────────┐  ┌──────────┐
│ COMPLETE     │  │   HOME   │
│  PROFILE     │  └────┬─────┘
└──────┬───────┘       │
       │               │
       └───────┬───────┘
               │
       ┌───────┴───────────┬─────────────┬───────────┐
       │                   │             │           │
  ┌─────────┐      ┌─────────┐   ┌─────────┐  ┌─────────┐
  │  EVENT  │      │PROFILE  │   │ CREATE  │  │ MY      │
  │  :id    │      │ :userId │   │  POST   │  │ TICKETS │
  └────┬────┘      └─────────┘   └─────────┘  └────┬────┘
       │                                              │
       ▼                                              ▼
  ┌─────────┐                                   ┌─────────┐
  │  BUY    │                                   │   QR    │
  │ TICKET  │                                   │CHECK-IN │
  └─────────┘                                   └─────────┘
```

---

## PAGE SUMMARY (V1)

| # | Page | Route | Auth | Key Elements | Test Keys Required |
|---|------|-------|------|--------------|-------------------|
| 1 | Splash | `/splash` | No | Loading, routing | `splash_screen` |
| 2 | Onboarding | `/onboarding` | No | "Gas Mulai!" | `onboarding_screen`, `start_button` |
| 3 | Login | `/login` | No | Google Sign In | `login_screen`, `google_sign_in_button` |
| 4 | Complete Profile | `/complete-profile` | Yes | DOB, Location, Gender | `complete_profile_screen`, `dob_field`, `submit_button` |
| 5 | Home | `/home` | Yes | Feed/Events tabs, FAB | `home_screen`, `feed_tab`, `fab_button` |
| 6 | Discover | `/discover` | Yes | Search, filters, swipe | `discover_screen`, `search_bar` |
| 7 | Event Detail | `/event/:id` | Yes | Info, Q&A, buy button | `event_detail_screen`, `buy_button` |
| 8 | Ticket Selection | `/event/:id/tickets` | Yes | Ticket types, quantity | `ticket_selection_screen` |
| 9 | My Tickets | `/my-tickets` | Yes | Upcoming/Past tabs, QR | `my_tickets_screen` |
| 10 | Check-in QR | `/ticket/:id/qr` | Yes | Full screen QR | `qr_checkin_screen` |
| 11 | Profile (Own) | `/profile` | Yes | Edit, stats, posts | `profile_screen`, `edit_button` |
| 12 | Profile (Other) | `/profile/:id` | Yes | Follow/unfollow | `profile_screen`, `follow_button` |
| 13 | Edit Profile | `/edit-profile` | Yes | All fields, interests | `edit_profile_screen`, `save_button` |
| 14 | Settings | `/settings` | Yes | Preferences, logout | `settings_screen`, `logout_button` |
| 15 | Create Post | `/create-post` | Yes | Photo, text, tag event | `create_post_screen`, `post_button` |
| 16 | Comments | `/post/:id/comments` | Yes | Comment list, input | `comments_screen`, `send_button` |
| 17 | Followers/Following | `/profile/:id/followers` | Yes | User list | `followers_screen` |
| 18 | Server Unavailable | `/server_unavailable` | No | Retry, offline, logout | `server_unavailable_screen` |

---

## READING GUIDE

- **Implementing a screen?** → Read the specific flow file
- **Adding navigation?** → Check the flow files for transition logic
- **Writing tests?** → Use "Test Keys Required" column
- **Debugging navigation?** → Check the navigation graph

---

**Remember**: Section 2 in main CLAUDE.md has detailed flow diagrams. This is just the index.
