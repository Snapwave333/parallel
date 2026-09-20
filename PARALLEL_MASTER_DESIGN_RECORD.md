# PARALLEL — Master Design Record

**Version:** 1.0  
**Platform:** Android + iOS  
**Product Type:** Neurodivergent-first dating and relationship app  
**Core Principle:** Dating without the unwritten rules.

---

## 1. Product Vision

Parallel is a cross-platform dating and relationship app designed first for autistic and neurodivergent adults.

The app reduces ambiguity, social guesswork, sensory friction, communication mismatches, and planning stress without infantilizing users or turning autism into a gimmick.

Parallel is not an "autism Tinder."

It is a structured communication and compatibility platform that supports the entire relationship lifecycle:

**Discover → Understand → Connect → Communicate → Meet → Sync → Reflect → Build a Relationship**

The app should continue being useful after two people begin dating.

The long-term product vision is:

> A communication protocol for relationships.

---

# 2. Brand Positioning

## Product Name

**Parallel**

## Primary Tagline

**Dating without the unwritten rules.**

## Secondary Brand Lines

- No games. No guessing. Just people.
- Find someone you can be yourself around.
- Understand each other before guessing.
- Connection without performance.

---

# 3. Design Philosophy

Parallel should feel mature, premium, quiet, structured, and predictable.

It must not use stereotypical autism branding.

Avoid:

- Puzzle-piece imagery
- Rainbow-heavy neurodivergent branding
- Childlike visuals
- Hyperactive animation
- Bright gamified dating UI
- Swipe-casino mechanics
- Manipulative notification patterns
- Artificial urgency

The visual identity should resemble:

- Editorial minimalism
- High-end audio equipment
- Industrial product design
- Premium architecture magazines
- Modern operating-system interfaces

---

# 4. Visual Design System

## Core Palette

Parallel uses strict grayscale.

### Background

- Near black: `#0A0A0A`

### Surface

- Primary surface: `#151515`
- Raised surface: `#202020`

### Borders

- Primary border: `#333333`
- Secondary border: `#242424`

### Text

- Primary text: `#F2F2F2`
- Maximum emphasis: `#FFFFFF`
- Secondary text: `#999999`
- Muted text: `#666666`

No permanent accent color.

Photography provides the majority of color in the interface.

## State Communication

Never communicate state through color alone.

Use combinations of:

- Shape
- Fill
- Border weight
- Icon
- Pattern
- Typography
- Animation
- Labels

Example:

- Selected = filled white
- Available = outlined
- Inactive = gray
- Unknown = dotted outline
- Warning = heavy border + `!`
- Critical = inverted white surface with black text

---

# 5. Typography

Use a highly readable sans-serif family.

Recommended:

- Inter
- Geist
- SF Pro fallback on iOS
- Roboto fallback on Android

Typography principles:

- Large readable body text
- Clear hierarchy
- Generous line spacing
- Minimal decorative type
- Avoid all-caps body copy
- Adjustable system scaling
- Respect OS accessibility font settings

---

# 6. Layout Language

Use:

- Large negative space
- Thin geometric dividers
- Clear modular sections
- 8–12 px corner radii
- Minimal shadows
- Strong alignment
- Predictable spacing

Avoid:

- Heavy glassmorphism
- Neon edges
- Multicolor gradients
- Excessive cards
- Giant drop shadows
- Floating visual clutter

---

# 7. Motion System

Motion should communicate function.

Examples:

**Acknowledge**
- Small compression or scale response

**Connection**
- Two visual elements converge

**Waiting**
- Slow breathing animation

**Together Mode**
- Synchronized organic movement

**Disconnect**
- Connected forms separate

**Reduced Motion Mode**
- All decorative motion disabled

No bouncing badges or attention-grabbing loops.

---

# 8. Logo Concept

Primary visual:

**Ⅱ PARALLEL**

Two parallel lines represent two individuals who remain distinct.

Alternative mark:

Two paths that briefly converge and continue independently.

The logo should remain monochrome.

---

# 9. Product Architecture

Primary app areas:

1. Me
2. Discover
3. Connections
4. Plan
5. Together
6. Reflect
7. Us
8. Safety
9. Settings

---

# 10. Onboarding

Onboarding must be progressive.

Do not present a giant intake form.

Initial setup should require only:

- Name
- Age
- Gender identity
- Dating interests
- Relationship goals
- General location
- Basic communication preference
- Profile photo
- Safety confirmation
- Age verification

Additional compatibility information is gathered gradually.

Example:

```text
PROFILE QUALITY

About You          ██████████
Dating Goals       ██████████
Communication      ██████░░░░
Sensory Profile    ██░░░░░░░░
Affection          ░░░░░░░░░░
Lifestyle          ░░░░░░░░░░

42%

You can start meeting people now.
```

The user should be asked one optional question at a time over time.

---

# 11. Personal Operating Manual

Each user builds a structured relationship profile.

Example categories:

## Communication

- Directness
- Message length preference
- Response frequency
- Phone call comfort
- Video call comfort
- Voice message preference
- Comfort with silence
- Texting during conflict
- Preferred clarification style

## Social Energy

- Crowd tolerance
- Group size preference
- Frequency of social activities
- Alone-time requirements
- Parallel-play preference
- Recovery time after events

## Sensory

- Noise sensitivity
- Lighting sensitivity
- Crowd sensitivity
- Smell sensitivity
- Touch sensitivity
- Temperature sensitivity

## Affection

- Public affection
- Physical touch
- Asking before touch
- Hug preferences
- Initiating affection
- Reassurance preferences

## Planning

- Advance notice required
- Spontaneity tolerance
- Schedule-change tolerance
- Reminder preference
- Lateness tolerance
- Calendar usage

## Lifestyle

- Sleep schedule
- Work schedule
- Alcohol use
- Smoking
- Cannabis
- Pets
- Children
- Transportation
- Travel
- Homebody/outgoing balance

---

# 12. Preference Importance

Every compatibility preference should include an importance level.

Example:

```text
Crowded places:
DISLIKE

Importance in partner:
●○○○○
Not important
```

and:

```text
Direct communication:
LOVE

Importance:
●●●●●
Extremely important
```

This improves matching quality dramatically.

---

# 13. Preference Types

Parallel distinguishes between:

## Preference

Something the user likes but does not require.

## Compatibility Requirement

A major condition that strongly affects relationship success.

## Dealbreaker

A non-negotiable condition.

Dealbreakers must filter matches before scoring.

They must not simply reduce compatibility percentage.

---

# 14. Relationship Vocabulary Helper

Any potentially ambiguous dating term should include a plain-language explanation.

Examples:

- Casual dating
- Exclusive
- Monogamous
- Polyamorous
- Friends with benefits
- Situationship
- Long-term relationship
- Dating but not exclusive

The user should never need to leave the app to decode dating terminology.

---

# 15. Compatibility Engine

Do not display a single compatibility percentage as the primary metric.

Use multidimensional compatibility.

Primary dimensions:

- Communication
- Sensory compatibility
- Social energy
- Routine
- Affection
- Planning
- Independence
- Interests
- Lifestyle
- Relationship goals
- Conflict style
- Executive-function compatibility

---

# 16. Compatibility Categories

Differences are not automatically negative.

Parallel classifies dimensions as:

- Aligned
- Complementary
- Potential friction
- Unknown

Example:

```text
YOU + MAYA

LIKELY EASY

✓ Direct communication
✓ Comfortable with silence
✓ Similar affection preferences
✓ Both plan ahead

TALK ABOUT

! Different texting frequency
! Different spontaneity preferences

PROBABLY IRRELEVANT

• Different music tastes
• Different sleep schedules
```

---

# 17. Conflict Compatibility

Include conflict-preference questions.

Example:

```text
WHEN WE DISAGREE

I prefer:

○ Talk immediately
● Cool down first
○ Text instead of talking
○ Structured conversation
○ I'm unsure
```

And:

```text
WHEN I'M UPSET

Helpful:
✓ Give me space
✓ Be direct
✓ Reassure me

Not helpful:
× Repeated questions
× Unexpected physical touch
```

---

# 18. Executive Function Compatibility

Track:

- Planning ahead
- Reminder preference
- Schedule reliability
- Lateness tolerance
- Calendar usage
- Forgotten-message tolerance
- Task division preference
- Response expectation
- Last-minute changes

This should be treated as a major compatibility axis.

---

# 19. Discover

Avoid infinite swiping.

Parallel should deliver a small number of meaningful introductions.

Suggested default:

**3–7 introductions per day**

Each card should explain why the person is being shown.

Example:

```text
MAYA

Strong communication alignment
3 shared interests
Similar social energy

VIEW CONNECTION →
```

---

# 20. Introduce Me

Replace "Like" with:

**Introduce Me**

Optional reason:

- Shared interest
- Personality
- Dating compatibility
- Something they wrote
- Attraction
- Other

The recipient sees:

**Maya would like an introduction.**

---

# 21. Why We Matched

Every recommendation must be explainable.

Example:

```text
WHY YOU MET

VERY STRONG
Communication preferences
Relationship expectations
Need for independence

STRONG
Sensory compatibility
Planning style

DIFFERENT
Sleep schedules
Social activity

UNKNOWN
Financial habits
Travel preferences
```

Users can adjust matching priorities.

---

# 22. Interest Trees

Users build structured interests.

Example:

```text
MUSIC
└ Electronic
   ├ CloZee
   ├ Liquid Stranger
   ├ Experimental bass
   └ Live visuals

GAMES
└ Open worlds
   ├ GTA
   ├ Fallout
   └ Minecraft

CREATIVE
├ Pixel art
├ Generative visuals
└ AI projects
```

Matching should use structured interest overlap rather than generic tags.

---

# 23. Slow Match

Optional mode.

Possible flow:

Day 1:
- Interests

Day 2:
- Communication style

Day 3:
- Lifestyle

Day 4:
- Voice introduction

Then:
- Photos

Both users must opt in.

---

# 24. Messaging

Messaging must reduce ambiguity while preserving authentic human communication.

Core features:

- Text
- Voice
- Images
- Reactions
- Message scheduling
- No-response-needed flag
- Optional read receipts
- Optional typing indicators
- Long-message support
- Transcription
- Text-to-speech

---

# 25. Conversation Contracts

Users establish lightweight expectations.

Example:

```text
OUR CHAT

✓ Double texting is fine
✓ Long messages are welcome
✓ Memes are welcome
✓ Questions can be direct
✓ Taking a day to respond is fine
✓ No expectation of constant conversation

ASK FIRST

○ Voice calls
○ Video calls
○ Sexual conversation
```

---

# 26. Intent Signals

Users may privately indicate:

- Interested romantically
- Interested but need more time
- Prefer friendship
- Unsure
- Want to meet
- Not compatible

Mutual signals may be revealed only when compatible.

Example:

Both choose:

**I'd like to meet.**

Parallel reveals:

**You both want to meet.**

---

# 27. Communication Temperature

User-controlled temporary status.

Example:

```text
TODAY I'M

● Chatty
○ Normal
○ Quiet
○ Low energy
○ Need some space
```

This reduces interpretation anxiety.

---

# 28. No Response Needed

Any outgoing message can include:

**No response needed**

Example:

> Hope work goes well today.

`NO RESPONSE NEEDED`

This should be highly visible but non-intrusive.

---

# 29. Conversation Assist

AI may assist with:

- Clarifying ambiguity
- Summarizing long messages
- Suggesting direct questions
- Identifying unanswered questions
- Rephrasing a message
- Explaining likely interpretations

AI must not claim certainty about another person's emotional state.

Never:

> They are definitely flirting.

Prefer:

> This could be playful or flirtatious, but the meaning is ambiguous.

---

# 30. Translate Me

The app may show:

**Original**

and:

**Suggested clearer version**

Example:

Original:

> I'm pissed because you changed everything again.

Suggested:

> Repeated plan changes overwhelmed me. I need more notice when possible.

The user must explicitly choose whether to send the edited version.

Never silently rewrite user messages.

---

# 31. Conversation Rescue

When conversation stalls:

```text
QUIET MOMENT

That's okay.

[ KEEP THE SILENCE ]
[ GIVE US A QUESTION ]
[ FIND A SHARED TOPIC ]
[ START AN ACTIVITY ]
```

Silence must not be treated as failure.

---

# 32. Infodump Mode

A user may explicitly start an infodump.

Example:

```text
Eli wants to tell you about:
LIVE CONCERT VISUALS

Estimated:
7 min read

[ I'M READY ]
[ SAVE FOR LATER ]
```

Features:

- Save position
- Bookmark sections
- Ask about this
- Listen via TTS
- Voice transcription
- Resume later
- Generate follow-up questions

---

# 33. Social Battery

Optional user-controlled status.

Example:

```text
SOCIAL BATTERY

████░░░░░░

Available for:
✓ Text
✓ Memes
✓ Parallel activity

Not today:
× Calls
× Going out
```

Exact percentage sharing should be optional.

Default partner view:

- Great
- Comfortable
- Getting tired
- Need a break

---

# 34. Date Builder

Both users separately configure date preferences.

Example dimensions:

- Noise
- Crowd
- Lighting
- Duration
- Cost
- Talking level
- Walking amount
- Indoor/outdoor
- Food
- Transportation
- Alcohol
- Seating

Parallel finds overlap.

---

# 35. Date Plan Structure

Example:

```text
SATURDAY
Museum
2:00 PM

EXPECTED

People      ████░░░░░░
Noise       ███░░░░░░░
Lighting    ██████░░░░
Walking     ███████░░░

PLAN

2:00 Meet entrance
2:10 Exhibit
3:00 Café
3:30 Optional continuation

Leaving early is okay.
```

---

# 36. Automatic Plan B

Every date should include fallback planning.

Example:

```text
PLAN A
Aquarium

PLAN B
Quiet café nearby

PLAN C
End date early
```

---

# 37. Arrival Coordination

Example:

```text
DATE STARTING

MAYA
Arrived ✓

ELI
2 min away

[ I'M HERE ]
[ CAN'T FIND YOU ]
[ NEED 5 MINUTES ]
[ I'M NERVOUS — GIVE ME A MINUTE ]
```

---

# 38. Sensory Venue Database

Users can rate venues by sensory factors.

Do not use a generic five-star rating as the main accessibility signal.

Example:

```text
NOISE       ████████░░
CROWD       ██████░░░░
LIGHT       ███████░░░
SMELL       ███░░░░░░░
SEATING     GOOD
ESCAPE      EASY
```

---

# 39. Venue Predictability

Venue pages can include:

```text
WHAT TO EXPECT

Parking → 5-minute walk
Entrance → Security screening
Ordering → Counter service
Seating → Choose your own
Bathrooms → Back left
Typical visit → 60–90 minutes
Busy period → 6–8 PM
```

---

# 40. Parallel Friendly Venues

Long-term venue partnership system.

Potential published data:

- Quiet hours
- Noise levels
- Lighting
- Crowd patterns
- Seating
- Accessible entrance
- Bathrooms
- Menu predictability
- Exit/reentry policy

---

# 41. Together Mode

When two matched users meet physically, their phones may temporarily synchronize.

Pairing options:

- Bluetooth
- QR code
- NFC
- Nearby-device framework

Both users must explicitly confirm.

Together Mode is temporary.

---

# 42. Together Mode Permissions

Example:

```text
START TOGETHER MODE

Temporary connection
Expires automatically

Share:

✓ Silent signals
✓ Date plan
✓ Comfort status

○ Battery percentage
○ Precise location
○ Emergency information

ENDS IN:
3 HOURS
```

No continuous partner location tracking by default.

---

# 43. Silent Signals

Quick requests may include:

- A little quiet
- A break
- Food/water
- Less stimulation
- Change activity
- Reassurance
- Talk privately
- Leave soon
- Go home

Partner receives a discreet haptic and message.

---

# 44. Private Question

One partner may privately ask:

```text
Can I hold your hand?

[ YES ]
[ NOT RIGHT NOW ]
[ LET'S TALK ]
```

Potential uses:

- Affection
- Activity changes
- Boundaries
- Difficult subjects
- Plans
- Physical contact

---

# 45. Tap Language

Partners can configure simple haptic signals.

Example:

- One tap = Thinking about you
- Two taps = You okay?
- Long press = I need you
- Swipe down = Let's leave

---

# 46. Custom Haptic Language

Relationship Mode allows custom patterns.

Example:

```text
• •       You okay?
— —       Come here
• — •     Let's leave
♥         Thinking about you
```

Smartwatch support should be considered a major feature.

---

# 47. Sync Orb

Together Mode visual signature.

Two monochrome organic shapes merge when both phones connect.

The animation represents a shared temporary session.

State examples:

- Calm = slow movement
- Attention = gentle pulse
- Break = reduced movement
- Connected = synchronized motion

Reduced-motion mode disables animation.

---

# 48. Crowd Mode

Designed for:

- Concerts
- Festivals
- Conventions
- Museums
- Parties
- Large events

Example:

```text
CROWD MODE

We're together but may separate.

MEETING POINT
North entrance

CHECK-IN
Every 60 minutes

QUICK SIGNALS

✓ I'm good
☕ Need break
📍 Meet me
↗ Let's leave
```

---

# 49. Separate For A Bit

One user may communicate:

**I'm doing my own thing for a while.**

Options:

- Meet again at a selected time
- Message when ready
- Set meeting point
- No follow-up required

This reduces accidental interpretation of separation as rejection.

---

# 50. Shared Date Timeline

Example:

```text
OUR DATE

✓ 2:00 Meet
✓ 2:10 Museum

● 3:00 Café

○ 3:45 Walk
  OPTIONAL

○ 4:30 Continue?
  BOTH DECIDE
```

Optional continuation can use private voting.

If both choose yes:

**You both want to continue.**

If either chooses no:

**Time to wrap up.**

The app should not reveal which person selected no.

---

# 51. Sensory Check

Together Mode can offer:

```text
WHAT'S BOTHERING YOU?

Noise
Lighting
Crowd
Temperature
Smell
Too much conversation
General overload
Not sure
```

Then suggest:

- Quiet area
- Outside break
- Change activity
- Head home

---

# 52. Emergency Exit

Together Mode must include:

**END DATE**

The user can:

- Disconnect Together Mode
- Hide temporary shared data
- Launch transportation
- Open safety contacts
- Return to normal app mode

The other person should not receive private destination information.

---

# 53. Post-Date Debrief

Keep default debrief extremely small.

Primary question:

**Would you like to see this person again?**

Options:

- Yes
- Maybe
- Friends
- No

Optional:

**Tell Parallel more**

Avoid turning post-date reflection into homework.

---

# 54. Personal Date Learning

Over time the app may identify patterns.

Example:

```text
YOUR BEST DATES

Quiet environments        ★★★★★
1–2 hour dates            ★★★★★
Activity-based            ★★★★★
Restaurants               ★★★☆☆
Large events              ★★☆☆☆
Unstructured dates        ★★☆☆☆
```

This data should remain private unless explicitly shared.

---

# 55. Relationship Mode

Dating apps normally become irrelevant after a successful match.

Parallel should become more useful.

When users mutually establish a relationship, the app enters:

**Relationship Mode**

Discovery can be disabled.

---

# 56. Relationship Home

Example:

```text
ELI + MAYA

Together 4 months

TODAY

Maya
Quiet / comfortable

Eli
Chatty

SHARED

Saturday → Concert
Sunday → Recovery day

[ TOGETHER ]
[ PLAN ]
[ CHECK-IN ]
[ MEMORIES ]
```

---

# 57. Shared Relationship Manual

Individual Operating Manuals combine into a shared document.

Example:

```text
OUR MANUAL

COMMUNICATION

✓ Direct
✓ Silence is okay
✓ Text difficult conversations

OVERLOAD

Eli → wants space
Maya → wants reassurance

PLANNING

24h notice preferred

AFFECTION

Ask when either person seems overwhelmed
```

---

# 58. Repair Mode

Structured disagreement support.

Possible flow:

```text
REPAIR

What happened?

How are you feeling?

What did you understand the other
person to mean?

What do you need now?

○ Space
○ Reassurance
○ Clarification
○ Apology
○ Solution
○ Nothing yet
```

AI may structure communication but must never determine who is right.

---

# 59. Relationship Check-In

Keep it lightweight.

Example:

```text
Everything okay between you two?

♡ Great
✓ Good
~ Something small
! We should talk
```

If both indicate an issue:

**Want help starting the conversation?**

---

# 60. Memories

Optional shared memory space.

Possible content:

- Photos
- Dates
- Notes
- Milestones
- Favorite places
- Shared jokes
- Plans

No public follower system.

---

# 61. Pause Mode

Users may pause:

- Discovery
- New introductions
- Community activity
- Notifications

Durations:

- 24 hours
- 1 week
- 1 month
- Indefinitely

Existing conversations remain available.

No guilt notifications.

---

# 62. Notification Design

Support bundled notifications.

Example:

```text
PARALLEL

You have:

2 messages
1 introduction
3 community updates

OPEN WHEN READY
```

User control:

```text
MESSAGES             Immediate
INTRODUCTIONS        Evening digest
COMMUNITY            Off
DATE REMINDERS        On
TOGETHER SIGNALS      Always
```

---

# 63. Interface Intensity

Accessibility must not assume all users want minimal information.

Include:

```text
INTERFACE

QUIET ━━━━━●━━━━ DETAILED

Motion       Minimal
Density      Medium
Photos       Full
Hints        On
Numbers      Reduced
```

---

# 64. Comfort Controls

Persistent comfort settings:

- Animation
- Autoplay
- Sound
- Haptics
- Contrast
- Information density
- Notification batching
- Reduced ambiguity
- Font size
- Motion reduction
- Voice-message transcription
- TTS

---

# 65. Reduced Ambiguity Mode

Changes vague copy into literal language.

Instead of:

> Someone's thinking about you.

Use:

> Maya liked your profile.

This behavior should apply across the app.

---

# 66. Universal Help

Every major screen includes:

**I NEED HELP**

Contextual behavior:

Profile:
- Help me answer this

Conversation:
- Help me understand this

Date Planning:
- Help us choose

Arrival:
- Help me find them

Together:
- Help me communicate

Relationship:
- Help me explain something

---

# 67. Universal Escape

Every screen should support:

**NOT NOW**

Possible uses:

- Skip profile question
- Delay response
- Decline activity
- Hide recommendation
- Exit Together Mode
- Skip relationship check-in

The user must never feel trapped in interaction.

---

# 68. Safety Architecture

Safety is core product infrastructure.

Required areas:

- Age verification
- Optional identity verification
- Duplicate account detection
- Romance-scam detection
- Suspicious money-request warnings
- Explicit-image controls
- Blocking
- Reporting
- Moderation
- Device fingerprint risk signals
- Ban evasion detection
- Privacy-preserving approximate location

---

# 69. Location Privacy

Never expose exact home or work location.

Use distance buckets such as:

- Within 5 miles
- 5–15 miles
- 15–30 miles
- 30+ miles

Avoid exact measurements like:

**237 feet away**

---

# 70. Trusted Contact

Optional first-date safety system.

Example:

```text
DATE SAFETY

Share with Alex:

✓ Venue
✓ Start time
✓ Expected end time

○ Live location

AUTO CHECK-IN
9:30 PM
```

The date never gains access to trusted-contact data.

---

# 71. Privacy Controls

Profile-level controls:

- Hide surname
- Hide workplace
- Hide exact neighborhood
- Hide social accounts
- Watermark sensitive photos
- Disable screenshots where supported
- Hide activity status
- Disable read receipts
- Disable typing indicators

---

# 72. Community

Community should remain intentionally restrained.

Potential areas:

- Interest rooms
- Local activity groups
- Dating questions
- Events

Avoid:

- Follower counts
- Influencer mechanics
- Engagement leaderboards
- Popularity rankings
- Algorithmic outrage feeds

---

# 73. AI Principles

Parallel AI may act as:

- Interpreter
- Organizer
- Conversation scaffold
- Date planner
- Accessibility assistant
- Summarizer

It must not act as:

- Romantic partner
- Automated dater
- Relationship authority
- Emotional truth detector
- Personality impersonator

The user remains responsible for their communication.

---

# 74. Home Screen Evolution

The home interface should change with relationship stage.

Before matching:

**Discover**

After match:

**Connections**

Before date:

**Upcoming Date**

During date:

**Together**

Established relationship:

**Us**

---

# 75. No Dark Patterns

Never use:

- Fake scarcity
- Fake likes
- Artificial urgency
- Streaks
- Anxiety-driven boosts
- Hidden information sold through Premium
- Punishment for inactivity
- Manipulative push notifications

Product success should not depend on keeping users single.

---

# 76. Monetization

Potential model:

## Free

- Profile
- Matching
- Messaging
- Core accessibility
- Core Together Mode
- Safety
- Basic Date Builder

## Parallel Plus

Potential optional features:

- Advanced compatibility insights
- Extra profile filters
- Advanced Date Builder
- Expanded sensory venue tools
- Enhanced AI communication tools
- Relationship archive
- Custom Together haptics
- Advanced planning

Never paywall:

- Safety
- Blocking
- Basic messaging
- Essential accessibility
- Basic compatibility explanation

---

# 77. Recommended Cross-Platform Technology Stack

## Mobile Framework

**Flutter**

Primary recommendation.

Reasons:

- Excellent Android + iOS parity
- Strong custom UI rendering
- Smooth animation
- Strong accessibility support
- Single primary codebase
- Good performance
- Strong native-plugin ecosystem
- Excellent control over grayscale visual system

Alternative:

**React Native + Expo**

Use only if the development team has stronger TypeScript/React expertise.

Flutter is preferred for Parallel because Together Mode, custom interaction states, haptics, animations, and consistent rendering are central to the product.

---

# 78. Core Mobile Stack

Recommended:

- Flutter
- Dart
- Riverpod
- GoRouter
- Freezed
- Dio
- Drift or Isar for local persistence
- flutter_secure_storage
- WebSocket client
- Firebase Messaging or native APNs/FCM abstraction
- Sentry
- OpenTelemetry where practical

---

# 79. Native Platform Integrations

Use native bridges where required.

Android:

- Kotlin
- Nearby Connections API
- Bluetooth LE
- NFC
- Wear OS
- Android Keystore
- Credential Manager
- BiometricPrompt

iOS:

- Swift
- MultipeerConnectivity
- CoreBluetooth
- CoreNFC
- WatchConnectivity
- Keychain
- LocalAuthentication

---

# 80. Backend Architecture

Recommended backend:

**Rust**

Suggested framework:

- Axum
- Tokio
- Serde
- SQLx
- PostgreSQL
- Redis
- NATS or Kafka if scale requires event streaming
- WebSockets
- OpenTelemetry

Rust provides:

- Strong safety
- High concurrency
- Predictable performance
- Excellent long-term backend reliability

---

# 81. Backend Services

Initial modular monolith:

```text
API Gateway
│
├ Auth
├ Profiles
├ Compatibility
├ Discovery
├ Messaging
├ Date Planning
├ Together Sessions
├ Venue Data
├ Safety
├ Notifications
├ Relationship Mode
└ AI Gateway
```

Start as a modular monolith.

Do not prematurely split into microservices.

---

# 82. Database

Primary:

**PostgreSQL**

Secondary:

**Redis**

Use Redis for:

- Session caching
- Presence
- Rate limits
- Temporary Together state
- Queue coordination
- Notification batching

---

# 83. Media Storage

Use S3-compatible object storage.

Examples:

- AWS S3
- Cloudflare R2
- Backblaze B2

Store:

- Profile images
- Voice messages
- Shared images
- Moderation copies where legally appropriate

Use signed URLs.

---

# 84. Authentication

Supported options:

- Email + password
- Email magic link
- Apple Sign In
- Google Sign In
- Passkeys

Require verified age.

Optional identity verification should remain separate from public identity display.

---

# 85. Core Data Entities

```text
User
Profile
ProfilePhoto
Preference
PreferenceImportance
Dealbreaker
Interest
InterestTree
CompatibilityProfile
MatchCandidate
Introduction
Connection
Conversation
Message
ConversationContract
IntentSignal
SocialStatus
DatePlan
Venue
VenueSensoryProfile
TogetherSession
TogetherSignal
SafetyContact
Relationship
RelationshipManual
CheckIn
Memory
Report
Block
Verification
NotificationPreference
AccessibilityPreference
```

---

# 86. Compatibility Storage Model

Do not hard-code compatibility into profile rows.

Use a flexible feature model.

Example:

```text
compatibility_feature

id
user_id
feature_key
value
importance
classification
visibility
updated_at
```

Classification:

- preference
- requirement
- dealbreaker

This allows new compatibility dimensions without destructive schema redesign.

---

# 87. Matching Pipeline

Suggested flow:

```text
Candidate Pool
      ↓
Hard Safety Filters
      ↓
Dealbreaker Filters
      ↓
Location / Age / Intent Filters
      ↓
Compatibility Feature Scoring
      ↓
Diversity / Repetition Controls
      ↓
Explainability Generator
      ↓
Daily Introductions
```

Do not optimize solely for engagement.

---

# 88. Compatibility Score Internals

Internally, scores may exist.

User-facing UI should emphasize dimension-level interpretation.

Conceptual weighting:

```text
score(feature) =
compatibility
× user_importance
× mutual_relevance
× confidence
```

Unknown values should reduce confidence, not automatically reduce compatibility.

---

# 89. Messaging Architecture

Use:

- WebSockets for live delivery
- Durable database persistence
- Device push notifications
- Offline queue
- Message retry
- Idempotency keys

Message states:

- Queued
- Sent
- Delivered
- Read

Read state should remain optional.

---

# 90. Together Mode Technical Architecture

Together Mode should use two layers.

## Local Layer

Preferred when users are physically close.

Android:

- Nearby Connections
- Bluetooth LE
- NFC pairing

iOS:

- MultipeerConnectivity
- Bluetooth
- NFC-assisted pairing where supported

## Cloud Relay

Fallback when local connectivity fails.

Use encrypted WebSocket relay with a short-lived session token.

---

# 91. Together Session Security

Each session should use:

- Temporary session ID
- Expiration
- Ephemeral keys
- Explicit permission scope
- Revocation
- No permanent location storage
- Short-lived local identifiers

Session example:

```text
TogetherSession

session_id
user_a
user_b
created_at
expires_at
permission_scope
ephemeral_public_keys
state
```

---

# 92. Haptic Synchronization

Create a canonical haptic-event abstraction.

Example:

```text
HapticSignal {
  type
  pattern
  intensity
  duration
  sender
  timestamp
}
```

Map abstract patterns to platform-native haptics.

Android:

- VibrationEffect
- Wear OS haptics

iOS:

- Core Haptics
- WatchKit haptics

---

# 93. Watch Support

## Apple Watch

Priority capabilities:

- Together Mode
- Quick signals
- Haptic language
- Social status
- Date timeline
- Check-in

## Wear OS

Same feature parity where practical.

Watch interfaces should remain extremely minimal.

---

# 94. AI Architecture

All AI requests must pass through a controlled backend gateway.

Do not directly expose model API keys to mobile clients.

AI Gateway responsibilities:

- Prompt templates
- Safety policy
- Redaction
- Rate limiting
- Model routing
- Logging
- User-consent boundaries

---

# 95. AI Privacy

Before sending text to an AI model:

- Minimize unnecessary context
- Redact hidden profile information
- Avoid transmitting precise location
- Avoid sending full private conversation history unless required
- Clearly indicate when AI is processing content

Allow:

**Disable AI features completely**

---

# 96. Safety Moderation

Moderation pipeline should inspect:

- Scam behavior
- Coercion
- Money requests
- Threats
- Harassment
- Unsolicited explicit media
- Ban evasion
- Suspicious account creation

Use a combination of:

- Automated risk scoring
- Rate limits
- Human moderation
- User reports
- Device/account signals

---

# 97. Accessibility Requirements

Target:

**WCAG 2.2 AA**

Additional requirements:

- Dynamic type
- Screen readers
- TalkBack
- VoiceOver
- Reduced motion
- High contrast
- Large touch targets
- Captions
- Voice-message transcription
- Text-to-speech
- Haptic alternatives
- No color-only state
- Plain-language mode
- Reduced ambiguity mode

---

# 98. Offline Behavior

Support degraded offline mode for:

- Viewing cached conversations
- Drafting messages
- Viewing date plan
- Viewing Together emergency options
- Accessing trusted contact
- Viewing shared relationship manual

Queue writes until connectivity returns.

---

# 99. Privacy Architecture

Principles:

- Data minimization
- Encryption in transit
- Encryption at rest
- Limited retention
- Permission scoping
- User deletion controls
- Export controls
- Clear visibility settings

Sensitive categories should default to private.

---

# 100. Analytics

Do not optimize primarily for time-in-app.

Better success metrics:

- Meaningful introductions
- Mutual introductions
- Conversation quality
- Dates planned
- Dates completed
- User-reported comfort
- Relationship formation
- Reduced blocking/reporting incidents
- Successful transition into Relationship Mode

---

# 101. MVP

Version 1 should include:

- Account system
- Profiles
- Progressive onboarding
- Communication preferences
- Sensory preferences
- Dealbreakers
- Interest trees
- Explainable compatibility
- Limited daily introductions
- Messaging
- Conversation contracts
- Intent signals
- Social battery
- Date Builder
- Simple venue sensory data
- Basic Together Mode
- Silent signals
- Post-date mutual continuation
- Safety tools
- Accessibility settings

---

# 102. V1.5

Add:

- Smartwatch support
- Infodump Mode
- Conversation Assist
- Arrival coordination
- Crowd Mode
- Venue predictability
- Notification batching
- Trusted contacts
- AI translation assistance

---

# 103. V2

Add:

- Relationship Mode
- Shared relationship manual
- Repair Mode
- Memories
- Custom haptic language
- Advanced sensory venue system
- Parallel Friendly venue partnerships
- Expanded AI date planning

---

# 104. V3

Potential expansion:

- Friendship Mode
- Activity Partner Mode
- Community
- Local neurodivergent-friendly events
- Venue certification
- Travel planning
- Couple planning
- Relationship widgets
- CarPlay / Android Auto limited safety interactions

---

# 105. Navigation

Suggested bottom navigation before relationship:

```text
Discover
Connections
Plan
Me
```

During an active Together session:

```text
Together
```

becomes dominant.

Relationship Mode:

```text
Us
Messages
Plan
Me
```

---

# 106. Performance Targets

Target:

- Cold start under 2.5 seconds on supported devices
- 60 FPS minimum UI
- 120 Hz support where available
- Message send feedback under 150 ms perceived latency
- Together local signal under 300 ms where possible
- Graceful degraded mode on weak networks

---

# 107. Supported OS Targets

Recommended initial minimums:

Android:
- Android 11+

iOS:
- iOS 17+

Reassess at implementation time based on active-device distribution.

---

# 108. Testing Strategy

Required:

## Unit Tests

- Matching calculations
- Dealbreaker filtering
- Permission logic
- Data validation
- AI transformation boundaries

## Widget/UI Tests

- Accessibility
- Large font layouts
- Reduced motion
- High contrast
- Screen-reader labels

## Integration Tests

- Messaging
- Notifications
- Together pairing
- Session expiration
- Block/report behavior

## Device Tests

- Bluetooth
- NFC
- Watch
- Background state
- Battery saver
- Poor network

---

# 109. Together Mode Failure Recovery

If local sync fails:

1. Retry local connection
2. Switch transport
3. Attempt cloud relay
4. Preserve local date plan
5. Keep safety controls functional
6. Show literal status

Example:

**Together connection lost. Your date plan and safety tools still work.**

---

# 110. Quality-of-Life Requirements

Global features:

- Save drafts automatically
- Undo destructive actions
- Batch notifications
- Long-press help
- One-tap mute
- Per-chat notification control
- Message scheduling
- Offline drafts
- Search conversations
- Search interests
- Bookmark messages
- Pin important relationship notes
- TTS for messages
- Transcribe audio
- Quiet hours
- Calendar integration
- Map handoff
- Ride-share handoff
- Battery-aware Together Mode

---

# 111. Calendar Integration

Optional user-authorized integrations:

- Native Android calendar
- Apple Calendar
- Google Calendar

Allow:

- Add date
- Add reminders
- Mark recovery time
- Add travel buffer

Example:

```text
Saturday

2:00–4:00
Museum date

4:00–6:00
Recovery time
```

---

# 112. Recovery Time

This should be a first-class planning concept.

After events, users may reserve:

**Recovery Time**

Date Builder should consider it during scheduling.

---

# 113. Profile Visibility

Visibility levels:

- Public to eligible matches
- Mutual introductions only
- Connections only
- Relationship partner only
- Private

Each Operating Manual field should support individual visibility.

---

# 114. Data Portability

Users should be able to:

- Download profile data
- Export shared relationship manual
- Export memories
- Delete account
- Delete media
- Remove AI-derived insights

---

# 115. App Store Positioning

Primary category:

**Dating**

Secondary positioning:

- Accessibility
- Neurodivergent communication
- Relationship tools

Do not describe the app as medical treatment.

---

# 116. Product Principle Checklist

Every feature should answer:

1. Does this reduce ambiguity?
2. Does this reduce unwanted social pressure?
3. Does this improve compatibility understanding?
4. Does this improve communication?
5. Does this preserve autonomy?
6. Does this respect sensory needs?
7. Is this understandable without hidden rules?
8. Does this avoid addictive engagement patterns?

If not, reconsider the feature.

---

# 117. Final Product Identity

Parallel is not defined by autism iconography.

It is defined by:

- Clarity
- Predictability
- Communication
- Consent
- Comfort
- Compatibility
- Autonomy
- Mutual understanding

The final experience should feel like:

**Two people, clearly understood, without unnecessary guessing.**

---

# 118. Final Product Summary

```text
PARALLEL

Dating without the unwritten rules.

DISCOVER
Understand compatibility before matching.

CONNECT
Communicate without decoding hidden rules.

PLAN
Build predictable, sensory-compatible dates.

TOGETHER
Sync phones and watches for private real-world communication.

REFLECT
Learn what works without turning dating into homework.

US
Keep Parallel useful after the relationship begins.

SAFETY
Protect privacy, autonomy, and personal information.

ACCESSIBILITY
Let each person control how much stimulation,
information, motion, and ambiguity they experience.
```

---

# 119. Recommended First Engineering Milestone

Build a vertical slice containing:

1. Flutter app shell
2. Authentication
3. Grayscale design system
4. Profile
5. Progressive compatibility questions
6. Compatibility explanation
7. Daily introduction
8. Messaging
9. Conversation contract
10. Date Builder
11. Basic Together Mode using QR pairing + cloud WebSocket relay
12. Silent Together signals
13. Safety block/report
14. Accessibility controls

Do not begin with every feature.

Prove the core experience:

**Profile → meaningful introduction → communication → planned date → Together Mode**

Once that loop feels excellent, expand outward.

---

# 120. Recommended Repository Layout

```text
parallel/
│
├ apps/
│  └ mobile/
│     ├ lib/
│     │  ├ core/
│     │  ├ design/
│     │  ├ features/
│     │  │  ├ auth/
│     │  │  ├ profile/
│     │  │  ├ compatibility/
│     │  │  ├ discover/
│     │  │  ├ messaging/
│     │  │  ├ dates/
│     │  │  ├ together/
│     │  │  ├ relationship/
│     │  │  ├ safety/
│     │  │  └ settings/
│     │  └ main.dart
│     ├ android/
│     └ ios/
│
├ backend/
│  ├ src/
│  │  ├ auth/
│  │  ├ profile/
│  │  ├ compatibility/
│  │  ├ discovery/
│  │  ├ messaging/
│  │  ├ dates/
│  │  ├ together/
│  │  ├ safety/
│  │  ├ relationships/
│  │  └ ai/
│  └ migrations/
│
├ packages/
│  ├ api_contract/
│  └ shared_schemas/
│
├ infrastructure/
│
├ docs/
│  ├ MASTER_DESIGN_RECORD.md
│  ├ API.md
│  ├ SAFETY.md
│  ├ ACCESSIBILITY.md
│  └ ARCHITECTURE.md
│
└ README.md
```

---

**End of Master Design Record**
