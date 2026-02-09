# Feature 8: Social Graph (Follow + Friends)

## User Story
"As a user, I want to follow people and add friends so I can see updates and access friends-only goals."

---

## Follow System

### One-way Relationship
- User A can follow User B without User B's approval
- Following creates a one-way connection
- Follower sees followed user's public content in their feed

### Follow Actions
- **Follow User**: Creates follow relationship
- **Unfollow User**: Removes follow relationship
- **Remove Follower**: Prevents a user from following you

### Follow Privacy Rules
- Can follow public users directly
- Cannot follow private users
- Friends-only users require friendship to follow

---

## Friends System

### Two-way Relationship
- Requires mutual acceptance
- Both users must agree to friendship
- Unlocks friends-only content visibility

### Friend Request Flow
1. User A sends friend request to User B
2. User B receives notification/sees pending request
3. User B accepts or declines
4. If accepted, mutual friendship is created

### Friend Actions
- **Send Friend Request**: Initiates friendship
- **Accept Friend Request**: Confirms mutual friendship
- **Decline Friend Request**: Rejects request
- **Cancel Friend Request**: Withdraws sent request
- **Remove Friend**: Ends friendship (both directions)

---

## Connections Manager Page

### Route
`/connections`

### Stats Summary
Display counts for:
- Following (users you follow)
- Followers (users who follow you)
- Friends (mutual friendships)
- Requests (pending friend requests)

### Tabs

#### Following Tab
- Lists all users you follow
- Actions: View Profile, Unfollow

#### Followers Tab
- Lists all users following you
- Actions: View Profile, Remove Follower

#### Friends Tab
- Lists all mutual friends
- Actions: View Profile, Remove Friend

#### Requests Tab
- **Incoming Requests**: Friend requests you received
  - Actions: Accept, Decline
- **Sent Requests**: Friend requests you sent
  - Shows "Pending approval" status
  - Actions: Cancel Request

---

## Database Schema

### user_follows Table
```
user_follows
├── id (primary key)
├── follower_id (references users)
├── following_id (references users)
├── created_at (timestamp)
└── unique constraint: [follower_id, following_id]
```

### friendships Table
```
friendships
├── id (primary key)
├── user_id (references users - sender)
├── friend_id (references users - receiver)
├── status (enum: pending, accepted, declined, blocked)
├── created_at (timestamp)
├── accepted_at (timestamp, nullable)
└── unique constraint: [user_id, friend_id]
```

---

## API Endpoints

### Follow Endpoints
- `POST /api/users/:id/follow` - Follow a user
- `DELETE /api/users/:id/follow` - Unfollow a user

### Friend Endpoints
- `POST /api/users/:id/friend-request` - Send friend request
- `POST /api/friend-requests/:id/accept` - Accept request
- `POST /api/friend-requests/:id/decline` - Decline request
- `DELETE /api/friend-requests/:id` - Cancel sent request
- `DELETE /api/friends/:id` - Remove friend

### List Endpoints
- `GET /api/users/:id/following` - Get users someone follows
- `GET /api/users/:id/followers` - Get someone's followers
- `GET /api/friends` - Get current user's friends
- `GET /api/friend-requests` - Get pending requests

---

## Privacy Integration

### Profile Visibility Settings
Users can set their profile to:
- **Public**: Anyone can view profile and follow
- **Friends Only**: Only friends can view full profile
- **Private**: Only friends can view, no following allowed

### Content Visibility
- **Public goals**: Visible to everyone
- **Friends-only goals**: Visible to accepted friends
- **Private goals**: Visible only to owner

---

## Real-time Features

### Notifications
- New follower notification
- Friend request received notification
- Friend request accepted notification

### Live Updates
- Connection counts update in real-time
- Friend request list updates when new request arrives
- Use Phoenix PubSub for live updates

---

## Implementation Status

### Completed ✅
- Follow/unfollow functionality
- Friend request send/accept/decline/cancel
- Connections manager page (/connections)
- Following tab with unfollow action
- Followers tab with remove action
- Friends tab with remove friend action
- Requests tab with incoming/sent sections
- Stats summary bar with counts
- Privacy-based follow restrictions

### Pending
- Real-time notifications for social events
- Follower suggestions based on activity
- Mutual friends indicator
- Block user functionality
