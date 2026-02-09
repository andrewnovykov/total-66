State: DONE
Completed: 2026-02-06

# PRD-10: Mood Calendar for Challenge Daily Check-ins

## Summary
Add mood tracking to daily check-ins and display a mood calendar grid under the progress section.

## Mood Values
- "upset" — 😟 frowning face
- "neutral" — 😐 neutral face
- "good" — 😊 smiling face
- nil — no mood selected (grey circle)

## Implementation

### Database & Schema
- [x] Migration: `add_mood_to_daily_check_ins` — adds `:mood` string column
- [x] DailyCheckIn schema: `field :mood, :string` in optional fields
- [x] Validation: `validate_inclusion(:mood, ["upset", "neutral", "good"])`

### Backend
- [x] `create_daily_check_in/2` accepts mood param
- [x] `get_mood_history/1` returns `%{day_number => mood}` map for participant

### UI — Mood Selector (in Today's Check-in)
- [x] Three emoji buttons: 😟 Upset, 😐 Okay, 😊 Great
- [x] Toggle selection (click again to deselect)
- [x] Visual highlight on selected mood
- [x] Saved with daily check-in on "Finish Day"

### UI — Mood Calendar (under Progress section)
- [x] Grid of day tiles showing mood emoji per day
- [x] Color-coded: green=good, amber=neutral, red=upset, grey=no mood
- [x] Future days shown as dashed outline with day number
- [x] Legend row below the grid
- [x] Updates immediately after check-in

### UI — Feed Item
- [x] Mood emoji displayed in challenge feed entries
