## State: DONE
## Completed: 2026-02-07

# PRD-11: Friend Chat / Messaging

Messages to friend! Chat with friend, you can message only friends!

## Requirements
- [x] On page people/USERNAME add Message button
- [x] Button disabled when not friends, enabled only if friends
- [x] After removing from friends, button disabled, messages not allowed
- [x] New menu under "My Stuff" section: Messages
- [x] Real-time messaging via PubSub
- [x] Conversation list with unread counts
- [x] Chat view with message history

## Implementation
- Database: `conversations` and `messages` tables with indexes
- Schemas: `HeadsUp.Conversation`, `HeadsUp.Message`
- Context: `HeadsUp.Messaging` with friend-gated messaging
- LiveView: `MessagesLive.Index` (conversation list), `MessagesLive.Show` (chat)
- Routes: `/messages`, `/messages/:id` (authenticated)
- Navigation: "Messages" link in sidebar under "My Stuff"
- Profile: Message button on `/people/:username` (enabled for friends, disabled otherwise)
- Real-time: PubSub for instant message delivery
- JS Hooks: ScrollBottom (auto-scroll), AutoResize (textarea)

## Tests
- 18 unit tests for Messaging context
- 17 LiveView tests for Messages pages and profile button
- All 831 tests passing
