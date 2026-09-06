# Vivellette Dress Up

## Product Scope

Vivellette Dress Up is a polished 2D, iPad-first children's fashion doll dress-up game. The visual direction is colorful, glossy, playful, fashionable, and premium-looking.

The game may be inspired by the broad appeal of modern fashion dolls, but it must not reproduce or use copyrighted Rainbow High characters, names, logos, clothing, or artwork.

## MVP Scope

The target MVP will eventually contain:

- 1 fixed fashion doll character
- 3 hairstyles
- 5 dresses
- 4 pairs of shoes
- 3 bags
- 1 background
- Looping background music
- Dress-up sound effect
- Music mute/unmute
- Reset outfit
- Minimal local save

## Technology

- Godot 4.7.x
- GDScript only
- 2D only
- iPad/iOS first
- Android later
- Web potentially later
- Landscape orientation
- Offline-first
- No backend

## Artwork Pipeline

All body and wearable avatar artwork must be authored against one fixed master canvas:

```text
1254 x 1254 pixels
```

Examples include:

- `body_base.png`
- `hair_001_back.png`
- `hair_001_front.png`
- `dress_001.png`
- `shoes_001.png`
- `bag_001_back.png`
- `bag_001_front.png`

All avatar artwork must eventually render using identical transforms. Runtime code must not dynamically fit clothing to the character.

Never introduce:

- Per-item x/y offsets
- Per-item scale corrections
- Automatic clothing fitting
- Bone deformation
- Physics clothing
- Procedural fitting

Artwork alignment is an art pipeline responsibility, not a runtime responsibility.

## UI Direction

The project is iPad-first and landscape-oriented. Use a logical reference viewport of `1366 x 1024`.

Build responsive UI with Godot `Control` nodes and containers wherever possible. Avoid absolute UI positioning unless there is a narrow, explicit reason.

## Scope Exclusions

Do not add these unless a future sprint explicitly requests them:

- Backend
- Authentication
- Networking
- Analytics
- Ads
- Database
- Store
- Currencies
- Multiple characters
- Wardrobe logic
- Save system
- Audio system
- Animations
- Shaders
- Plugins
- Dependency injection
- Automated tests unless genuinely necessary
- Placeholder AI-generated artwork

## Current Phase

Sprint 2 is the first interactive wardrobe only. Do not implement saving, audio, animation, drag and drop, inventory, store, currency, unlocks, networking, or generated placeholder artwork during Sprint 2.
