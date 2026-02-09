References
- TRD: project_doc/docs/requirements/04-features/08-social-graph.md
- TRD: project_doc/docs/design/pages/14-connections.md
- TRD IDs: REQ-08, DESIGN-14

Status
- State: DONE
- Completed Date: 2025-02-05

Next Step
- Next PRD: project/sprint-1/PRD-5.md (if applicable)

---

# PRD-4: Connections Manager Page

## Overview
Implement a central Connections Manager page (`/connections`) where users can view and manage all their social relationships including followers, following, friends, and friend requests.

---

## Features Implemented

### 4.1 Connections Page Structure
- [x] Create `/connections` route with LiveView
- [x] Implement tabbed interface (Following, Followers, Friends, Requests)
- [x] Add stats summary bar showing counts for each relationship type
- [x] Mobile-responsive layout

### 4.2 Following Tab
- [x] List all users the current user follows
- [x] Display user card with avatar, name, username, bio
- [x] "View Profile" button linking to `/people/:username`
- [x] "Unfollow" button with immediate action
- [x] Empty state: "You're not following anyone yet"

### 4.3 Followers Tab
- [x] List all users following the current user
- [x] Display user card with avatar, name, username, bio
- [x] "View Profile" button linking to `/people/:username`
- [x] "Remove" button to remove follower
- [x] Empty state: "No followers yet"

### 4.4 Friends Tab
- [x] List all accepted mutual friendships
- [x] Display user card with avatar, name, username, bio
- [x] "View Profile" button linking to `/people/:username`
- [x] "Remove Friend" button (currently unlabeled or implicit)
- [x] Empty state: "No friends yet / Send friend requests to build your network"

### 4.5 Requests Tab
- [x] **Incoming Friend Requests Section**
  - [x] List pending friend requests received
  - [x] "Accept" and "Decline" action buttons
  - [x] Empty state: "No pending friend requests / Friend requests will appear here"
- [x] **Sent Friend Requests Section**
  - [x] List friend requests sent by current user
  - [x] Show "Pending approval" status indicator
  - [x] "Cancel Request" button
  - [x] Empty state for no sent requests

---

## Technical Implementation

### Context Functions Used
- `Accounts.list_following/1` - Get users the current user follows
- `Accounts.list_followers/1` - Get users following current user
- `Accounts.list_friends/1` - Get accepted friends
- `Accounts.list_friend_requests/1` - Get incoming friend requests
- `Accounts.list_sent_friend_requests/1` - Get outgoing friend requests
- `Accounts.follow_user/2` - Create follow relationship
- `Accounts.unfollow_user/2` - Remove follow relationship
- `Accounts.remove_follower/2` - Block follower
- `Accounts.send_friend_request/2` - Create friend request
- `Accounts.accept_friend_request/2` - Accept friend request
- `Accounts.decline_friend_request/2` - Decline friend request
- `Accounts.cancel_friend_request/2` - Cancel sent request
- `Accounts.remove_friend/2` - Remove friendship

### LiveView Events
- `unfollow` - Unfollow a user
- `remove_follower` - Remove a follower
- `remove_friend` - Remove a friend
- `accept_friend_request` - Accept incoming request
- `decline_friend_request` - Decline incoming request
- `cancel_friend_request` - Cancel sent request

---

## UI Components

### User Card
- Avatar image (rounded, medium size)
- Display name (bold)
- Username with @ prefix
- Short bio (truncated to 1-2 lines)
- Action buttons (contextual based on tab)

### Stats Summary
- Horizontal bar with 4 sections
- Each shows: count + label
- Clickable to switch tabs
- Active tab highlighted

---

## Testing

### Unit Tests
- Context function tests for all relationship operations
- Privacy enforcement tests

### LiveView Tests
- Tab switching behavior
- Action button functionality
- Empty state rendering
- Count updates after actions

---

## Related Files
- `lib/heads_up_web/live/connections_live.ex` - Main LiveView
- `lib/heads_up/accounts.ex` - Context functions for relationships
- `lib/heads_up/accounts/user_follow.ex` - Follow schema
- `lib/heads_up/accounts/friendship.ex` - Friendship schema
