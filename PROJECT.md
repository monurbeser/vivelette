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

## Wardrobe Interaction Architecture

The wardrobe uses four fixed category tabs: Hair, Dress, Shoes, and Bag.

The lower wardrobe shelf is one shared item carousel, not four permanent category-specific rows. Selecting a category updates the carousel contents for that category.

The carousel should show approximately four item slots at rest, align those slots with the decorative shelf compartments in `wardrobe_panel_bg.png`, and snap horizontally by page after touch scrolling.

Wardrobe items use the real production wearable textures as thumbnails. Thumbnail rendering may calculate and cache alpha-visible bounds to frame the visible artwork inside a UI preview slot, but this is only for UI thumbnails. It must never alter the source PNG, avatar texture, avatar coordinates, layer transforms, or equip behavior.

Wardrobe assets should be discovered automatically from the approved asset folders and naming conventions. Do not hardcode item counts or create per-item button nodes for production wardrobe content.

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

Sprint 4 is wardrobe thumbnail carousel and UX only. Do not implement saving, audio, animation beyond subtle carousel snapping, drag and drop, inventory, store, currency, unlocks, networking, or generated placeholder artwork during Sprint 4.
