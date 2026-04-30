# SOVEREIGN — Complete Implementation Prompt for Claude Code + Godot MCP

You are building **Sovereign**, a 2.5D isometric sandbox medieval MMO with a player-driven Solana (SOL) economy. This document is the SINGLE SOURCE OF TRUTH. It contains every design decision AND exact implementation instructions. Do not deviate without explicit permission. Build each step in order — each is a testable milestone.

---

# PART 1: CORE IDENTITY & DESIGN DECISIONS

## 1.1 Project Identity
- **Genre:** Sandbox MMO / Medieval Strategy / Survival / Player-Driven Economy
- **Perspective:** 2.5D isometric with 3D models (Albion Online style)
- **Engine:** Godot 4 (client, GDScript only) + custom authoritative game server (Rust)
- **Art Style:** Low-poly 3D models on isometric terrain. KayKit (itch.io) as primary asset source. Quaternius, Kenney, OpenGameArt supplementary.
- **Platform:** PC only. Custom launcher (Tauri) + Epic Games Store. NOT Steam (Steam bans crypto).
- **Theme:** Realistic medieval. NO fantasy, NO magic. Herbalism not spells, medicine not healing magic, siege engineering not fireballs.
- **Blockchain:** Solana (SOL) — zero-sum player-to-player economy. No custom token.
- **Server:** Single persistent server for MVP. Never wipes.
- **Inspiration:** Anvil Empires + EVE Online + RuneScape + Rust + Mount & Blade + Albion Online
- **Tagline:** "Build Kingdoms. Wage War. Own Your Economy."

## 1.2 Art Style Guide
- Low-poly 3D models with hand-painted or simple PBR textures
- 500-2000 triangles per character/animal model
- 200-1000 triangles per prop/furniture
- Terrain uses tiling textures with splatmap blending
- Color palette: muted earth tones (browns, greens, greys, warm stone). No high-saturation except kingdom heraldry
- Scale: 1 Godot unit = 1 meter
- All models imported at same scale, same skeleton/rig for characters
- Placeholder colored cubes acceptable for alpha

---

# PART 2: WORLD DESIGN

## 2.1 Map & Terrain
- **World type:** Continuous terrain, free-placement (NOT tile/grid-based). Terrain is STATIC for MVP — no terraforming.
- **World size:** Starts as 3x3 zone grid (~1.5km x 1.5km). Each zone ~500m x 500m. New zones procedurally generated at edges when average player density exceeds 15 players per zone for 24 hours. Expansion announced server-wide: "The frontier has expanded to the East! New lands await."
- **Biomes:** Temperate farmland, dense forests, mountain ranges, coastal regions, arid badlands, river valleys, swampland. Resources distributed unevenly across biomes to force trade and territorial conflict.
- **No safe zones.** PvP is always possible everywhere.
- **Persistent world.** 24/7 operation. Buildings remain, crops grow, animals graze while offline.
- **Full world map** visible (press M), but NO player tracking on map. No player dots.
- **Minimap** on HUD showing terrain only — no player dots.
- **Zone transitions:** Foxhole-style. When player approaches zone boundary (within 10m), UI prompt: "Press E to travel to [Zone Name]." Press E → 2-3 second fade transition → spawn at corresponding border position in new zone. Queue system if destination at capacity. For MVP single-server process, this is a simple scene transition.

## 2.2 Water & Swimming
- Rivers, lakes, and coastline exist as static terrain features.
- **Cannot swim in heavy armor** (must remove plate). Light armor/cloth = basic swimming, slow speed, stamina drains fast.
- Water is a genuine barrier — bridges and rowboats are critical infrastructure.
- **Bridges:** Player-built ONLY. No pre-existing bridges. Requires Carpentry + Masonry skill.
- **Rowboat** available for water crossing (no naval combat for MVP).

## 2.3 Roads
- **Player-buildable roads.** Grant +25% movement speed to anyone traveling on them.
- Requires Construction skill + stone/gravel resources.

## 2.4 Day/Night Cycle
- **2 real hours = 1 full in-game day/night cycle.**
- Night severely reduces visibility. Players need torches (handheld or placed) to see.
- Handheld torch occupies off-hand slot (can't use shield simultaneously).
- Placed torches illuminate a fixed area.
- Torches visible from far away — nighttime movement is a stealth/visibility tradeoff.

## 2.5 Seasons (MVP: 2 seasons)
- **Summer (1 real week):** Longer days, 120% crop yield. Peak farming. Normal movement.
- **Winter (1 real week):** -15% movement speed in snow. Hunger depletes 50% faster. 0% crop yield. Sieges are brutal.
- Full year = 2 real weeks. Spring/autumn added post-MVP.

## 2.6 Weather (MVP: Simplified)
- **Rain:** Reduces visibility, waters crops automatically. Random occurrence.
- **Clear:** Default. No gameplay effect.
- Full weather system (storms, fog, drought, floods) post-MVP.

## 2.7 PvE Wildlife
- Hostile creatures in **specific dangerous biomes only:**
  - **Deep forests:** Wolves, bears.
  - **Wilds/badlands:** Boars, wild dogs.
  - **Mountains/highlands:** Mountain lions.
- **NPC bandits** roam wilderness areas — hostile to all players.
- Wildlife provides hunting materials (meat, pelts, bone).

## 2.8 NPCs
- **Hostile:** Bandits in wilderness, creatures in dangerous biomes.
- **Friendly:** NPC market keepers at player-owned marketplace stalls (sell goods for owner when offline). NPC stable for horse purchase (MVP bootstrapping exception).
- **No NPC quest givers.** No NPC merchants selling goods (except stable). Every service is player-provided.

---

# PART 3: CHARACTER SYSTEM

## 3.1 New Player Experience
- Wake up on a randomized beach/wilderness with NOTHING. Fully naked, no starting equipment.
- Find everything yourself — gather sticks, flint, fiber from the ground.
- Optional tutorial area teaches basics before releasing into world.
- Characters under 4 hours playtime have visible "New" tag. Killing a "New" player = 3x karma penalty.
- New players spawn at randomized beach locations (not fixed point).

## 3.2 Character Creation
- **One character per server (one server for MVP).**
- Simple customization: Skin tone + hair style/color.
- Character name changeable later. Username (account name) permanent.
- Display name shows character name. Username visible on inspect.

## 3.3 Character Stats
- **Health:** 100 HP base. No natural regen. Must eat food or use bandages.
- **Stamina:** 100 SP base. Regens at 5 SP/sec when not acting. 0 SP = cannot attack, block, or sprint.
- **Hunger:** 100 HG base. Depletes at 1 HG/min (0.5 HG/min in summer, 1.5 HG/min in winter). Below 20 HG: stamina regen halved. At 0 HG: lose 1 HP/10sec.
- **Weight/Encumbrance:** Each item has weight. Max carry weight per character. Exceeding reduces movement speed proportionally. Cannot move at all above 150% capacity.
- **Move Speed:** 5 m/s walk. Sprint: 8 m/s (costs 10 SP/sec). Roads: +25% speed. Encumbrance reduces speed.
- **Horse Speed:** 12.5 m/s (2.5x walk). No mounted combat for MVP.

## 3.4 Logout & Offline
- Body stays in world for 15 minutes after logout, then vanishes.
- During those 15 minutes, body can be attacked and looted.
- Log out inside your claimed base for safety.

## 3.5 Death System
- **Full loot PvP.** On death, drop ALL equipped gear and inventory.
- **6 hit zones:** Head, torso, left arm, right arm, left leg, right leg. Each takes damage independently.
- **Injury system:**
  - Head: High damage multiplier. Severe = near-instant down/death.
  - Torso: Heavy bleeding. Determines bleedout speed.
  - Arms: Reduced swing damage (50% with broken arm). Can't use two-handed weapons.
  - Legs: Reduced movement speed (broken leg = limp only).
- **Downed state:** HP hits 0 → bleedout (15-60 seconds by injury severity). Allies revive with bandages. Enemies execute (3-5 second channel, interruptible).
- **Injuries persist through downed state but RESET on full death + respawn.**
- **Corpse loot:** Only killer can loot first 2 minutes, then anyone. Corpse lasts 10 minutes.
- **Death marker:** Visible only to you on map. Disappears when corpse despawns.

## 3.6 Respawn
- **Options:** Your bed, nearest friendly town, kingdom spawn point.
- **Timers:** Own settlement: 5 sec. Wilderness: 10 sec. Near enemy/battle: 30 sec. Repeated deaths increase timer.
- **5 seconds respawn invulnerability** (can move, can't attack). Spawn position randomized within 10m radius.
- **Skill XP penalty on death:** Lose small % of XP in highest skill.
- Respawn naked with nothing — re-equip from stored gear.

---

# PART 4: COMBAT SYSTEM

## 4.1 Combat Feel
- **Weighty and slow** (Mount & Blade / Dark Souls pace). Every swing is a commitment.
- **Server tick rate:** 20 Hz (50ms per tick).
- **Click-to-move controls:** Left click to move, left click on enemy to attack.

## 4.2 Attack System
- **3 attack tiers:** Light tap = quick jab (low damage, fast, low stamina). Full click = normal swing. Hold = heavy attack (high damage, high stamina, slow, must stop moving).
- **8 directional attacks:** Screen-space mouse position relative to character sprite. Divide screen around character into 8 equal 45° sectors. Whichever sector mouse falls in = attack direction.
- **Movement during attacks:** Walk speed for light/normal. Stationary for heavy.
- **Friendly fire ALWAYS ON.** All attacks damage anyone in hitbox, including allies. Full damage, no mitigation.

## 4.3 Defense (MVP: Block Only)
- **Directional blocking:** Hold block + direction. Block only works if facing within 90° of incoming attack. Attacks from behind always hit.
- **No parry/riposte for MVP.** Added post-MVP.
- **Dodge:** Short dash in movement direction. 0.3sec invulnerability. Costs 20 SP. 1sec cooldown.
- **Kick/Shove:** Costs stamina, breaks blocks and staggers. Counters shield turtling.

## 4.4 Combat State Machine
- **IDLE:** Default. Can move, attack, block, use items.
- **ATTACKING:** Locked into animation (0.4-0.8sec by weapon). Can't block. Walk speed for light/normal, stationary for heavy.
- **BLOCKING:** Holding block. Reduces incoming damage from blocked direction. 50% move speed. Costs stamina per hit absorbed.
- **STAGGERED:** Hit while attacking or stamina broken. Cannot act for 0.5sec.
- **DODGING:** Dash with 0.3sec invulnerability. 1sec cooldown.
- **DOWNED:** HP at 0. Bleedout timer. Can be revived or executed.
- **DEAD:** Dropped all equipment. Respawn timer, then respawn selection.

## 4.5 Weapons (MVP)

### Melee Weapons
| Weapon | Damage | Speed | Stam Cost | Range | Durability | Strong Vs |
|--------|--------|-------|-----------|-------|------------|-----------|
| Flint Knife | 8 | Fast | 5 SP | 1.0m | 30 | Unarmored |
| Bronze Sword | 18 | Medium | 12 SP | 1.5m | 80 | Leather |
| Iron Sword | 25 | Medium | 14 SP | 1.5m | 150 | Leather |
| Bronze Spear | 15 | Slow | 15 SP | 2.5m | 60 | Horses |
| Iron Spear | 22 | Slow | 17 SP | 2.5m | 120 | Horses |
| Bronze Mace | 20 | Slow | 18 SP | 1.2m | 100 | Plate/heavy armor |
| Iron Mace | 30 | Slow | 22 SP | 1.2m | 180 | Plate/heavy armor |

### Ranged Weapons (MVP: 2 types)
| Weapon | Damage | Fire Rate | Stam Cost | Range | Durability | Notes |
|--------|--------|-----------|-----------|-------|------------|-------|
| Short Bow | 12 | Medium | 8 SP | 30m | 50 | Fast, mobile |
| Crossbow | 28 | Very Slow | 10 SP | 45m | 70 | High damage, slow reload |

- Arrows are physics projectiles, not hitscan.
- Crossbows do NOT require Ranged Combat skill to be effective.

### Shield (MVP: 1 type)
| Shield | Block Stamina | Bash Damage | Durability |
|--------|---------------|-------------|------------|
| Kite Shield | 8 SP/block | 8 | 120 |

## 4.6 Armor

### Armor Slots (5 pieces)
Head, Chest, Legs, Hands, Feet. Full mixing allowed.

### Armor Types
| Armor Type | Slash Resist | Blunt Resist | Pierce Resist | Speed Penalty | Weight |
|------------|-------------|-------------|--------------|---------------|--------|
| None (cloth) | 0% | 0% | 0% | None | Light |
| Leather | 20% | 10% | 15% | -5% | Light |
| Bronze Plate | 40% | 20% | 35% | -15% | Heavy |
| Iron Plate | 55% | 30% | 50% | -20% | Heavy |

- **Damage formula:** `final_damage = base_damage × (1 - zone_resistance%) × weapon_type_multiplier`
- Maces = blunt. Swords = slash. Arrows/bolts = pierce.
- Heavy armor prevents swimming.

### Cosmetic Layer
- Tabards, cloaks, heraldry, kingdom colors over armor.
- Craftable by Tailoring skill.

## 4.7 Siege Warfare (MVP: Battering Ram Only)
- **Battering ram:** 4 players to push. Player-built, physically transported to siege site.
- **Destructible walls** with HP that degrade from ram damage.
- Trebuchets, siege towers, ladders added post-MVP.
- Sieges require active declared war (24-hour warning period).

## 4.8 Mounted Combat
- **Deferred to post-MVP.** Horses exist as mounts with speed bonus only. No combat from horseback.
- Horses can die permanently. Purchased from NPC stable.

---

# PART 5: SKILL SYSTEM

## 5.1 Overview
- **22 total skills,** each leveled 1-100.
- **Hard cap of 500 total skill points.** Can max exactly 5 skills to 100.
- **XP curve:** Exponential (RuneScape-style). Level 90-100 takes as long as 1-90.
- **Milestones every 25 levels** (25, 50, 75, 100) unlock recipes, abilities, bonuses.
- **Skill XP loss on death:** Small % loss in highest skill.
- **Respec:** Full reset allowed with heavy SOL cost (scales with total points) + 7 real-day cooldown. During cooldown all skills function at level 1.
- Skills gain XP from both PvP and PvE.

## 5.2 Complete Skill List

### Gathering Skills (6)
1. **Mining** — 25: Bronze ore. 50: Iron ore. 75: Gems. 100: Rare ore chance.
2. **Woodcutting** — 25: Softwood. 50: Hardwood. 75: Ancient trees. 100: Bonus planks.
3. **Farming** — 25: Basic crops. 50: Advanced crops. 75: Rare herbs. 100: Superior quality.
4. **Fishing** — 25: River fish. 50: Lake/coastal. 75: Rare catches. 100: Pearls.
5. **Herbalism** — 25: Common herbs. 50: Medicinal. 75: Rare herbs. 100: Poison ingredients.
6. **Quarrying** — 25: Raw stone. 50: Cut stone. 75: Marble. 100: Decorative stone.

### Crafting Skills (8)
7. **Smithing** — 25: Bronze. 50: Iron. 75: Superior chance. 100: Masterwork.
8. **Carpentry** — 25: Basic structures. 50: Advanced/carts. 75: Ships/bridges. 100: Structural bonus.
9. **Masonry** — 25: Stone walls. 50: Multi-story. 75: Keeps. 100: HP bonus.
10. **Leatherworking** — 25: Basic leather. 50: Reinforced. 75: Horse barding. 100: Superior leather.
11. **Cooking** — 25: Basic food. 50: Buff foods/ale. 75: Wine/mead. 100: Best buffs.
12. **Tailoring** — 25: Basic clothing. 50: Tabards. 75: Heraldry. 100: Masterworks.
13. **Alchemy/Medicine** — 25: Bandages. 50: Poultices/splints. 75: Antidotes. 100: Poisons.
14. **Fletching** — 25: Short bow. 50: Crossbow. 75: Fire arrows. 100: Superior ranged.

### Combat Skills (4)
15. **Melee Weapons** — 25: Basic combos. 50: Advanced techniques. 75: Damage bonus. 100: Unique moves.
16. **Ranged Weapons** — 25: Reduced spread. 50: Faster draw. 75: Improved damage. 100: Max accuracy.
17. **Defense/Armor** — 25: Reduced block cost. 50: +10% armor bonus. 75: +20%. 100: Master defender.
18. **Tactics** — 25: +5% party defense. 50: +10%. 75: Battle commands. 100: +15% all stats for party.

### Labor & Trade Skills (4)
19. **Animal Husbandry** — 25: Tame animals. 50: Breeding. 75: Rare breeds. 100: Exceptional offspring.
20. **Sailing/Navigation** — 25: Rowboat. 50: Sailing ship. 75: Warships. 100: Master navigator. (Post-MVP beyond rowboat)
21. **Construction** — 25: Faster build. 50: +10% structure HP. 75: +20%. 100: +30% HP.
22. **Trading** — 25: 2.5% fee. 50: 2%. 75: 1.5%. 100: 1% marketplace fee.

---

# PART 6: ECONOMY & SOLANA INTEGRATION

## 6.1 Zero-Sum Model
- SOL is the ONLY currency. No custom tokens, no in-game silver/gold.
- SOL enters when player deposits. SOL leaves when player withdraws. Game never creates/destroys SOL.
- Economy measured in **lamports** internally (1 SOL = 1,000,000,000 lamports).
- **All fractional lamport calculations round DOWN (deflationary).**
- Let the market decide all prices.

## 6.2 Trading Systems
- **Face-to-face trading:** Click nameplate → Trade. Both put items/SOL in window, both confirm. **0% fee.**
- **Local marketplaces ONLY.** No global auction house. Must physically visit town marketplace. Different towns = different prices.
- **NPC shopkeepers:** Set up automated seller at your marketplace stall. NPC sells while you're offline.
- **No remote price checking** — must travel to each market.

## 6.3 Fee Structure
| Action | Fee | Destination |
|--------|-----|-------------|
| Marketplace trade | 3% (reduced by Trading skill) | Operations treasury |
| Kingdom tax | Set by ruler (0-20%) | Kingdom (tracked, not pooled for MVP) |
| Face-to-face trade | 0% | N/A |
| SOL withdrawal | 1% + network fee | Operations treasury |
| SOL deposit | 0% (network fee only) | N/A |
| Kingdom charter | One-time SOL fee | Operations treasury |

## 6.4 Economic Sinks
- Marketplace fee (3%), withdrawal fee (1%), equipment degradation, building maintenance, siege destruction, death penalty (drop all gear), crafting failures, food spoilage.

## 6.5 Solana Architecture
- **Anchor smart contract** on Solana for deposit/withdrawal escrow.
- **Wallet bridge service** (Rust or Python) monitors escrow PDA for deposits, processes withdrawals.
- **Off-chain economy:** All in-game trades in PostgreSQL. On-chain only for deposit/withdrawal.
- **Daily Merkle root** of player balances published on-chain for auditability.
- **Wallet support:** Phantom, Solflare. Email/password also available (custodial wallet created).

## 6.6 Gambling
- Craftable dice, card tables. Place in taverns. Players wager SOL. Server-enforced fair RNG.

## 6.7 Anti-Exploitation
- Server-authoritative. Rate limiting on economic actions (max 10 listings/min, 5 trades/min, 1 withdrawal/hr).
- Anomaly detection for unusual trading patterns.
- Cooldown on new accounts before trading (anti-sybil).
- All transactions logged in sol_ledger table.

---

# PART 7: FARMING & FOOD SYSTEM

## 7.1 Crops
- **Growth times:** Berries 30-45 min, herbs 1-2 hr, wheat/grains 3-4 hr, industrial 3-4 hr.
- **Categories:** Grains (wheat, barley), Vegetables (cabbage, carrots, potatoes), Fruits (apples, berries), Industrial (cotton, flax, hops), Herbs (medicinal/culinary).
- **Crops indestructible EXCEPT during declared wars.**

## 7.2 Watering & Soil
- Manual bucket from well, buildable irrigation channels, rain waters automatically.
- Soil fertility depletes with same crop. Rotate crops or fertilize with manure.

## 7.3 Food & Cooking
- **Spoilage:** Raw 2-4 hr. Cooked 8-12 hr. Preserved (salt/smoke/dry) lasts days.
- **Buffs by type:** Meat = stamina regen. Bread = HP regen. Fish = skill XP bonus. Vegetables = hunger slowed. Fruit = quick hunger restore.
- **Alcohol:** Ale, wine, mead. Drunk effects: blurred vision, reduced pain, worse accuracy. No addiction system for MVP.

---

# PART 8: ANIMAL HUSBANDRY (MVP: Simplified)

## 8.1 MVP Animals: Chickens and Cows only
- Capture wild animals roaming the map.
- Requires pen/enclosure structures.
- No breeding genetics for MVP. Simple capture + pen + feed + collect.

## 8.2 Feeding
- Trough + grazing both work. Animals can die of starvation and old age.

## 8.3 Products
- Manual collection: eggs (chickens), milk (cows), meat (slaughter), manure (fertilizer).
- **Animal theft only during declared wars.**

---

# PART 9: CRAFTING SYSTEM

## 9.1 Basics
- Every item is player-crafted from player-gathered resources. No NPC vendors (except horse stable).
- Crafting at appropriate stations (forge, workbench, campfire, etc.).
- **Crafting failure:** Chance based on skill vs recipe difficulty. Failed = materials wasted.

## 9.2 Item Quality
- **2 tiers: Normal and Superior.** Superior = ~20% better stats.
- Superior chance scales with skill level. Level 100 = reasonable chance every craft.
- **Item naming:** Crafter's name auto-stamped + custom name option.

## 9.3 Repair
- Costs materials (less than new craft). Each repair lowers max durability.
- Higher Smithing = better repairs. Self-repair possible, skilled blacksmith much better.

---

# PART 10: BUILDING SYSTEM

## 10.1 Claim System
| Tier | Type | Claim Radius | Max Structures | Upgrade Requirements |
|------|------|-------------|----------------|---------------------|
| 1 | Homestead | 20m | 15 | Free (place Hearthstone) |
| 2 | Hamlet | 40m | 40 | 50 planks, 20 stone, 5+ residents |
| 3 | Village | 70m | 100 | 200 planks, 100 stone, 15+ residents |
| 4 | Town | 120m | 300 | 500 planks, 300 stone, 100 iron, 50+ residents |
| 5 | City | 200m | Unlimited | 2000 planks, 1000 stone, 500 iron, 200+ residents |

- Cannot place structures within another player's claim radius.
- **One hearthstone per player.** Min 50m between any two hearthstones.
- **New accounts: 2 hours playtime before placing hearthstone.**

## 10.2 Building Mechanics
- Blueprint system: select → place ghost → deliver resources → complete.
- No in-place upgrades. Demolish and rebuild (returns salvage, not full cost).
- Structural integrity: upper floors need wall support. Unsupported = collapse.
- Multi-story: up to 3 floors. Interior rooms with freely placeable furniture.
- Building decay: structures lose HP over time. Repair every 2-3 days. Full decay takes weeks.

## 10.3 Locks & Security
- Doors/chests lockable. Permissions: owner, kingdom, specific players.
- Locks breakable during declared wars only. Peacetime locks unbreakable.

## 10.4 Raidability Rules
- Structures damaged ONLY during active declared war (24-hour warning).
- **Non-kingdom homesteads immune UNTIL exceeding 20 structures.** Above 20 = raidable via personal war declaration (24-hour warning).
- **Soft player collision inside claimed territory:** players push through each other at 25% speed (prevents doorway blocking).

---

# PART 11: TRANSPORT & VEHICLES (MVP)

| Vehicle | Crew | Cargo | Speed | Requirements |
|---------|------|-------|-------|-------------|
| Pack Mule | 1 | 120 kg | 4 m/s | Animal Husbandry |
| Hand Cart | 1 | 250 kg | 3.5 m/s | Carpentry 20 |
| Horse Cart | 1 + horse | 500 kg | 8 m/s | Carpentry 40 |
| Rowboat | 1-2 | 200 kg | 4 m/s | Carpentry 30 |

- No warships, cargo barges, sailing ships, or naval combat for MVP.

---

# PART 12: KINGDOM & GOVERNANCE

## 12.1 Kingdom Formation
- Player controlling Town-tier (4+) settlement can declare Kingdom by placing Throne.
- Costs significant resources + SOL charter fee. Declaring player = Sovereign.

## 12.2 Roles
- Sovereign appoints: Marshal (military), Chancellor (diplomacy), Treasurer (economy), Steward (building).
- Game provides tools but does NOT enforce political system.
- **No shared kingdom treasury for MVP.** Taxes/rent tracked but not pooled in shared wallet.

## 12.3 Vassalage & Annexation
- Smaller settlements can swear fealty (consensual vassalage).
- **Forced annexation:** 48-hour warning to homestead owner. Owner can demolish (full salvage), pack items, relocate. After 48 hours, structures become kingdom property. Owner keeps items in storage.

## 12.4 Succession
- Sovereign inactive 30 days → Marshal inherits.

## 12.5 Diplomacy
- Treaties: alliance, non-aggression, trade agreement, vassalage, mutual defense. SOL collateral stakes.
- **War declaration:** 24-hour warning before buildings vulnerable.
- **Mercenary contracts:** SOL payment + terms, enforced by game.
- **War ending:** Both sides must agree. Winner sets terms (territory, SOL, vassalage).
- **Bounty boards:** Kingdoms post SOL bounties on enemy players.

---

# PART 13: KARMA & CRIME

- Murder outside declared war reduces karma. Red name = low karma, visible from far distance.
- Name text visible close (~15m). Karma color visible far.
- No mechanical penalties — purely visible reputation. Social punishment (refused trades, denied entry).
- Recovery through positive actions (trading, building, healing). NOT passive time.
- Bandit clans = valid gameplay.

---

# PART 14: SOCIAL SYSTEMS

## 14.1 Communication (MVP: Text Only)
- **Local text chat:** Nearby players.
- **Kingdom text chat:** All kingdom members.
- **Global trade chat:** Trade ads, server-wide.
- **Party chat:** Private to party.
- No voice chat for MVP.

## 14.2 Chat Safety
- Automated profanity/slur filter.
- Right-click mute function.
- Report sends chat log to admin queue.

## 14.3 Party System
- Formal party with shared map markers and HP bars.
- Tactics skill provides buffs in formation.

## 14.4 Friends List
- In-game with online status. See friends' current zone (not exact position).

## 14.5 Player Interaction
- Click nameplate: Trade, Inspect, Invite, Add Friend, Report.
- Inspect shows: name, kingdom, visible equipment, karma color.

## 14.6 Player-Created Content
- Writable books (craft, write text, place/trade).
- Placeable signs with custom text (within claim).
- Server chronicle auto-records major events.

---

# PART 15: UI & CONTROLS

## 15.1 Controls
- **Click-to-move** (left click move, left click enemy to attack, hold for heavy).
- Right click for block/interact.
- **Hotbar:** 10 slots, number keys.
- **Fully rebindable.** B=build, I=inventory, M=map, C=character/skills.

## 15.2 HUD
- HP bar + Stamina bar (always visible).
- Hunger bar (always visible).
- Minimap (corner, terrain only).
- Hotbar (bottom, 10 slots).
- Chat window (bottom-left, tabbed).
- Compass/heading.

## 15.3 Camera
- Fixed isometric perspective, zoomable with scroll wheel (min/max limits). Cannot rotate.

---

# PART 16: SERVER & TECHNICAL ARCHITECTURE

## 16.1 Technology Stack
| Component | Technology |
|-----------|-----------|
| Game Client | Godot 4 (GDScript only) |
| Game Server | Rust (custom authoritative) |
| Networking | ENet (UDP) via Godot + WebSocket fallback |
| World Database | PostgreSQL + PostGIS |
| Cache Layer | Redis (real-time state, sessions) |
| Blockchain | Solana (Anchor program for escrow) |
| Auth | Phantom/Solflare wallet connect + email/password (JWT) |
| Infrastructure | Docker on home server (MVP) |
| Monitoring | Prometheus + Grafana |
| CI/CD | GitHub Actions + Ansible |
| Balance Config | TOML/JSON hot-reloadable (no restart needed) |

## 16.2 Server Architecture
- **Server-authoritative.** Client sends inputs only. Server computes all state.
- **Single server process for MVP** with zone-based internal partitioning.
- **Tick rate:** 20 Hz (50ms per tick).
- **Client prediction:** Client predicts own movement. Reconciles on server state.
- **Entity interpolation:** Other players interpolated with 100ms buffer.
- **MVP target:** 100 concurrent players.

## 16.3 Performance Budgets

### Client
- Target 60 FPS (mid-range: GTX 1060). Minimum 30 FPS (integrated graphics).
- Max 200 entities rendered on screen.
- Entity culling: 100m. Structures: 200m.
- LOD: Full 0-30m. Reduced 30-60m. Minimal 60-100m. Hidden 100m+.
- Max 500 draw calls. 1GB VRAM for textures.

### Network
- Client upload: 5 KB/s. Download: 30 KB/s normal, 50 KB/s peak.
- Entity updates: 20 Hz nearby (30m), 5 Hz distant (30-100m), 1 Hz structures.
- Interest management: only send entities within 100m radius (200m structures).
- Server total: under 5 MB/s for 100 players.

## 16.4 Anti-Cheat (Server-Side)
- **Movement:** Server validates position each tick. Deviation beyond tolerance = snap back. Teleport (>2x max speed in one tick) = log + snap. 3 violations/60sec = auto-kick.
- **Combat:** All damage server-side. Validate range, state, weapon, stamina. Attack cooldown enforced by weapon speed.
- **Economy:** All inventory server-side. Trade double-checked at confirmation. Rate limits on all economic actions.

## 16.5 Account & Auth Flow
- **Email/password:** Register → bcrypt hash → UUID → custodial Solana wallet generated → JWT session (24hr expiry).
- **Wallet connect:** Phantom/Solflare signs challenge message → server validates → UUID → JWT session.
- Character creation after first login: display name, skin tone, hair.

## 16.6 Admin Tools

### In-Game Console (tilde key, admin flag required)
- `/kick [player] [reason]`
- `/ban [player] [duration: perm|1h|1d|7d|30d] [reason]` — SOL frozen pending review
- `/unban [player]`
- `/tp [player]` — teleport to player
- `/tphere [player]` — teleport player to admin
- `/spawn [item] [qty]` — testing only, logged
- `/god` — toggle invincibility, logged
- `/inspect [player]` — full state view
- `/announce [msg]` — server-wide broadcast
- `/weather [type]` — force weather
- `/time [hour]` — set game time

### Web Dashboard
- Player list with search, online status, karma, ban history.
- Report queue with context.
- Economy overview: total SOL, circulation, large transactions.
- Server metrics: player count, tick rate, memory, zone loads.

## 16.7 Telemetry
- Combat: weapon, damage, zone hit, armor, outcome → weapon win rates, armor effectiveness.
- Economy: items crafted/lost, marketplace volumes/prices, SOL flow.
- Skills: level distribution, time-to-level, most/least trained.
- Player lifecycle: session length, login frequency, churn point.

---

# PART 17: DATABASE SCHEMA

```sql
-- Players & Auth
CREATE TABLE players (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username VARCHAR(32) UNIQUE NOT NULL,
  display_name VARCHAR(32) NOT NULL,
  password_hash VARCHAR(255),
  wallet_address VARCHAR(64) UNIQUE,
  sol_balance BIGINT NOT NULL DEFAULT 0, -- lamports
  karma INT NOT NULL DEFAULT 100,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_login TIMESTAMPTZ,
  is_banned BOOLEAN DEFAULT FALSE,
  ban_reason TEXT,
  is_admin BOOLEAN DEFAULT FALSE,
  total_playtime_seconds INT DEFAULT 0
);

-- Characters (one per player for MVP single server)
CREATE TABLE player_characters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID REFERENCES players(id),
  name VARCHAR(32) NOT NULL,
  position_x FLOAT NOT NULL DEFAULT 0,
  position_y FLOAT NOT NULL DEFAULT 0,
  position_z FLOAT NOT NULL DEFAULT 0,
  zone_id INT NOT NULL DEFAULT 0,
  rotation_y FLOAT DEFAULT 0,
  health INT NOT NULL DEFAULT 100,
  max_health INT NOT NULL DEFAULT 100,
  stamina FLOAT NOT NULL DEFAULT 100.0,
  max_stamina FLOAT NOT NULL DEFAULT 100.0,
  hunger FLOAT NOT NULL DEFAULT 100.0,
  is_alive BOOLEAN DEFAULT TRUE,
  is_downed BOOLEAN DEFAULT FALSE,
  bleedout_timer FLOAT,
  respawn_x FLOAT,
  respawn_y FLOAT,
  respawn_z FLOAT,
  kingdom_id UUID REFERENCES kingdoms(id),
  logout_at TIMESTAMPTZ,
  body_despawn_at TIMESTAMPTZ,
  injury_head VARCHAR(20) DEFAULT 'none',
  injury_torso VARCHAR(20) DEFAULT 'none',
  injury_left_arm VARCHAR(20) DEFAULT 'none',
  injury_right_arm VARCHAR(20) DEFAULT 'none',
  injury_left_leg VARCHAR(20) DEFAULT 'none',
  injury_right_leg VARCHAR(20) DEFAULT 'none',
  carry_weight FLOAT DEFAULT 0,
  max_carry_weight FLOAT DEFAULT 100,
  skin_tone INT DEFAULT 0,
  hair_style INT DEFAULT 0,
  hair_color INT DEFAULT 0,
  UNIQUE(player_id)
);

-- Skills
CREATE TABLE character_skills (
  character_id UUID REFERENCES player_characters(id),
  skill_name VARCHAR(32) NOT NULL,
  level INT NOT NULL DEFAULT 1,
  xp BIGINT NOT NULL DEFAULT 0,
  PRIMARY KEY (character_id, skill_name)
);

-- Items
CREATE TABLE items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL,
  owner_type VARCHAR(20) NOT NULL, -- 'character','structure','ground','shop','vehicle'
  item_type VARCHAR(64) NOT NULL,
  quantity INT NOT NULL DEFAULT 1,
  durability INT,
  max_durability INT,
  quality VARCHAR(20) DEFAULT 'normal',
  crafter_name VARCHAR(32),
  custom_name VARCHAR(64),
  slot INT,
  equipped BOOLEAN DEFAULT FALSE,
  weight FLOAT NOT NULL DEFAULT 0,
  spoil_at TIMESTAMPTZ,
  position_x FLOAT,
  position_y FLOAT,
  position_z FLOAT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_items_owner ON items(owner_id, owner_type);

-- Structures
CREATE TABLE structures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES player_characters(id),
  kingdom_id UUID REFERENCES kingdoms(id),
  structure_type VARCHAR(64) NOT NULL,
  position_x FLOAT NOT NULL,
  position_y FLOAT NOT NULL,
  position_z FLOAT NOT NULL,
  rotation_y FLOAT DEFAULT 0,
  health INT NOT NULL,
  max_health INT NOT NULL,
  is_blueprint BOOLEAN DEFAULT TRUE,
  build_progress FLOAT DEFAULT 0,
  settlement_id UUID REFERENCES settlements(id),
  floor_level INT DEFAULT 0,
  locked BOOLEAN DEFAULT FALSE,
  lock_permission VARCHAR(20) DEFAULT 'owner',
  decay_rate FLOAT DEFAULT 0.1,
  last_repaired TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_structures_pos ON structures(position_x, position_y);

-- Settlements
CREATE TABLE settlements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(64) NOT NULL,
  founder_id UUID REFERENCES player_characters(id),
  kingdom_id UUID REFERENCES kingdoms(id),
  tier INT NOT NULL DEFAULT 1,
  hearthstone_x FLOAT NOT NULL,
  hearthstone_y FLOAT NOT NULL,
  hearthstone_z FLOAT NOT NULL,
  claim_radius FLOAT NOT NULL,
  population INT DEFAULT 1,
  structure_count INT DEFAULT 0,
  has_marketplace BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Kingdoms
CREATE TABLE kingdoms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(64) UNIQUE NOT NULL,
  sovereign_id UUID REFERENCES player_characters(id),
  marshal_id UUID REFERENCES player_characters(id),
  chancellor_id UUID REFERENCES player_characters(id),
  treasurer_id UUID REFERENCES player_characters(id),
  steward_id UUID REFERENCES player_characters(id),
  tax_rate FLOAT DEFAULT 0.05,
  rent_rate BIGINT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE kingdom_members (
  kingdom_id UUID REFERENCES kingdoms(id),
  character_id UUID REFERENCES player_characters(id),
  role VARCHAR(32) DEFAULT 'citizen',
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (kingdom_id, character_id)
);

-- Wars
CREATE TABLE wars (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  attacker_id UUID REFERENCES kingdoms(id),
  attacker_player_id UUID REFERENCES player_characters(id), -- for personal war declarations
  defender_id UUID REFERENCES kingdoms(id),
  defender_player_id UUID REFERENCES player_characters(id),
  declared_at TIMESTAMPTZ DEFAULT NOW(),
  active_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  status VARCHAR(20) DEFAULT 'preparing',
  terms JSONB,
  casus_belli TEXT
);

-- Mercenary Contracts
CREATE TABLE mercenary_contracts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kingdom_id UUID REFERENCES kingdoms(id),
  mercenary_id UUID REFERENCES player_characters(id),
  war_id UUID REFERENCES wars(id),
  payment_lamports BIGINT NOT NULL,
  terms TEXT,
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Treaties
CREATE TABLE treaties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kingdom_a UUID REFERENCES kingdoms(id),
  kingdom_b UUID REFERENCES kingdoms(id),
  treaty_type VARCHAR(32) NOT NULL,
  sol_stake BIGINT DEFAULT 0,
  terms JSONB,
  signed_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ
);

-- Economy
CREATE TABLE marketplace_listings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id UUID REFERENCES player_characters(id),
  settlement_id UUID REFERENCES settlements(id),
  item_id UUID REFERENCES items(id),
  price_lamports BIGINT NOT NULL,
  quantity INT NOT NULL,
  is_npc_shop BOOLEAN DEFAULT FALSE,
  listed_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ
);

CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id UUID REFERENCES player_characters(id),
  seller_id UUID REFERENCES player_characters(id),
  item_type VARCHAR(64) NOT NULL,
  quantity INT NOT NULL,
  total_lamports BIGINT NOT NULL,
  fee_lamports BIGINT NOT NULL,
  kingdom_tax BIGINT DEFAULT 0,
  settlement_id UUID REFERENCES settlements(id),
  trade_type VARCHAR(20) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE sol_ledger (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID REFERENCES players(id),
  action VARCHAR(20) NOT NULL,
  amount_lamports BIGINT NOT NULL,
  balance_after BIGINT NOT NULL,
  tx_signature VARCHAR(128),
  reference_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_ledger_player ON sol_ledger(player_id, created_at DESC);

-- Animals (MVP: simplified, no genetics)
CREATE TABLE animals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES player_characters(id),
  animal_type VARCHAR(32) NOT NULL,
  name VARCHAR(32),
  health INT NOT NULL DEFAULT 100,
  hunger FLOAT NOT NULL DEFAULT 100,
  position_x FLOAT,
  position_y FLOAT,
  position_z FLOAT,
  pen_structure_id UUID REFERENCES structures(id),
  is_alive BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Chronicle
CREATE TABLE chronicle_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type VARCHAR(64) NOT NULL,
  description TEXT NOT NULL,
  involved_kingdoms UUID[],
  involved_players UUID[],
  position_x FLOAT,
  position_y FLOAT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bounties
CREATE TABLE bounties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  poster_kingdom_id UUID REFERENCES kingdoms(id),
  target_character_id UUID REFERENCES player_characters(id),
  reward_lamports BIGINT NOT NULL,
  reason TEXT,
  claimed_by UUID REFERENCES player_characters(id),
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Friends
CREATE TABLE friends (
  player_a UUID REFERENCES players(id),
  player_b UUID REFERENCES players(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (player_a, player_b)
);

-- Parties
CREATE TABLE parties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  leader_id UUID REFERENCES player_characters(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE party_members (
  party_id UUID REFERENCES parties(id),
  character_id UUID REFERENCES player_characters(id),
  PRIMARY KEY (party_id, character_id)
);

-- Telemetry
CREATE TABLE combat_events (
  id BIGSERIAL PRIMARY KEY,
  attacker_id UUID,
  defender_id UUID,
  weapon_type VARCHAR(64),
  damage_dealt INT,
  hit_zone VARCHAR(20),
  attacker_armor VARCHAR(64),
  defender_armor VARCHAR(64),
  outcome VARCHAR(20),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE economy_events (
  id BIGSERIAL PRIMARY KEY,
  event_type VARCHAR(32),
  player_id UUID,
  item_type VARCHAR(64),
  quantity INT,
  lamports BIGINT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

# PART 18: NETWORKING PROTOCOL

## Client → Server
| Message | Channel | Payload |
|---------|---------|---------|
| CLICK_MOVE | Unreliable | tick_id, target_pos(x,y,z) |
| ATTACK_TARGET | Reliable | tick_id, target_id, attack_tier(jab/normal/heavy), direction(0-7) |
| BLOCK_START | Reliable | tick_id, direction(0-7) |
| BLOCK_END | Reliable | tick_id |
| DODGE | Reliable | tick_id, direction(x,y) |
| KICK | Reliable | tick_id |
| INTERACT | Reliable | target_id, action |
| BUILD_PLACE | Reliable | structure_type, pos(x,y,z), rotation |
| BUILD_CONTRIBUTE | Reliable | structure_id, item_ids[] |
| TRADE_OFFER | Reliable | target_player_id, offered_items, requested_lamports |
| MARKETPLACE_LIST | Reliable | item_id, price_lamports, quantity |
| MARKETPLACE_BUY | Reliable | listing_id, quantity |
| CHAT | Reliable | channel, message |
| CRAFT | Reliable | recipe_id, station_id |
| EQUIP | Reliable | item_id, slot |
| USE_ITEM | Reliable | item_id, target(optional) |
| GATHER | Reliable | resource_node_id |
| REVIVE | Reliable | target_character_id |
| EXECUTE | Reliable | target_character_id |
| ZONE_TRAVEL | Reliable | target_zone_id |

## Server → Client
| Message | Channel | Payload |
|---------|---------|---------|
| WORLD_STATE | Unreliable | tick_id, [{entity_id, pos, rot, anim_state, hp}] |
| DAMAGE_EVENT | Reliable | attacker_id, target_id, damage, zone_hit, injury_type, is_kill |
| ENTITY_SPAWN | Reliable | entity_id, type, position, initial_state |
| ENTITY_DESPAWN | Reliable | entity_id, reason |
| INVENTORY_UPDATE | Reliable | full inventory state |
| BALANCE_UPDATE | Reliable | sol_balance(lamports) |
| BUILD_UPDATE | Reliable | structure_id, progress, health |
| TRADE_REQUEST | Reliable | from_player_id, offered_items, requested_lamports |
| KINGDOM_EVENT | Reliable | event_type, data |
| RESPAWN_OPTIONS | Reliable | [{type, location, name}] |
| SKILL_UPDATE | Reliable | skill_name, new_level, new_xp |
| WEATHER_UPDATE | Reliable | weather_type, intensity |
| INJURY_UPDATE | Reliable | zone, injury_type, severity |
| CHRONICLE_EVENT | Reliable | description |
| ZONE_TRAVEL_READY | Reliable | zone_id, spawn_pos |
| AUTH_RESULT | Reliable | success, jwt_token, character_data |

---

# PART 19: IMPLEMENTATION STEPS — EXACT SPECIFICATIONS

Each step below is a testable milestone. Build them in order. Each includes exact folder structure, file names, class names, and function signatures.

---

## STEP 1: Godot Project Setup + Isometric Camera + Click-to-Move (Week 1-2)

### 1.1 Project Structure
Create the Godot 4 project with this exact folder structure:

```
sovereign/
├── project.godot
├── assets/
│   ├── models/
│   │   ├── characters/
│   │   ├── structures/
│   │   ├── props/
│   │   ├── terrain/
│   │   └── ui/
│   ├── textures/
│   │   ├── terrain/
│   │   ├── characters/
│   │   └── ui/
│   ├── audio/
│   │   ├── sfx/
│   │   └── ambient/
│   ├── fonts/
│   └── shaders/
├── scenes/
│   ├── main/
│   │   ├── main.tscn              # Root scene — loads world + UI
│   │   └── main.gd
│   ├── world/
│   │   ├── world.tscn             # World root — terrain, entities, lighting
│   │   ├── world.gd
│   │   ├── terrain.tscn           # Static terrain mesh
│   │   └── terrain.gd
│   ├── player/
│   │   ├── player.tscn            # Player character scene
│   │   ├── player.gd              # Player controller script
│   │   ├── player_model.tscn      # 3D model + animations
│   │   └── player_camera.gd       # Isometric camera script
│   ├── entities/
│   │   ├── npc.tscn
│   │   ├── npc.gd
│   │   ├── resource_node.tscn
│   │   └── resource_node.gd
│   ├── ui/
│   │   ├── hud/
│   │   │   ├── hud.tscn
│   │   │   ├── hud.gd
│   │   │   ├── health_bar.tscn
│   │   │   ├── stamina_bar.tscn
│   │   │   ├── hunger_bar.tscn
│   │   │   ├── hotbar.tscn
│   │   │   ├── hotbar.gd
│   │   │   ├── minimap.tscn
│   │   │   └── minimap.gd
│   │   ├── menus/
│   │   │   ├── main_menu.tscn
│   │   │   ├── main_menu.gd
│   │   │   ├── login_screen.tscn
│   │   │   ├── login_screen.gd
│   │   │   ├── character_create.tscn
│   │   │   ├── character_create.gd
│   │   │   ├── inventory_screen.tscn
│   │   │   ├── inventory_screen.gd
│   │   │   ├── skill_screen.tscn
│   │   │   ├── skill_screen.gd
│   │   │   ├── build_menu.tscn
│   │   │   ├── build_menu.gd
│   │   │   ├── map_screen.tscn
│   │   │   └── map_screen.gd
│   │   ├── chat/
│   │   │   ├── chat_window.tscn
│   │   │   └── chat_window.gd
│   │   └── trade/
│   │       ├── trade_window.tscn
│   │       ├── trade_window.gd
│   │       ├── marketplace.tscn
│   │       └── marketplace.gd
│   └── effects/
│       ├── damage_number.tscn
│       ├── damage_number.gd
│       ├── hit_effect.tscn
│       └── blood_splatter.tscn
├── scripts/
│   ├── autoload/
│   │   ├── game_manager.gd        # Global game state singleton
│   │   ├── network_manager.gd     # Networking singleton
│   │   ├── input_manager.gd       # Input remapping singleton
│   │   ├── audio_manager.gd       # Audio singleton
│   │   └── config.gd              # Client config/settings
│   ├── systems/
│   │   ├── combat/
│   │   │   ├── combat_state_machine.gd
│   │   │   ├── combat_states.gd
│   │   │   ├── damage_calculator.gd
│   │   │   ├── hit_zone_system.gd
│   │   │   └── injury_system.gd
│   │   ├── inventory/
│   │   │   ├── inventory.gd
│   │   │   ├── item_database.gd
│   │   │   └── equipment_manager.gd
│   │   ├── crafting/
│   │   │   ├── crafting_system.gd
│   │   │   └── recipe_database.gd
│   │   ├── building/
│   │   │   ├── building_system.gd
│   │   │   ├── blueprint_placer.gd
│   │   │   ├── claim_system.gd
│   │   │   └── structure_database.gd
│   │   ├── farming/
│   │   │   ├── farming_system.gd
│   │   │   ├── crop_database.gd
│   │   │   └── soil_system.gd
│   │   ├── skills/
│   │   │   ├── skill_system.gd
│   │   │   └── skill_database.gd
│   │   ├── economy/
│   │   │   ├── trade_system.gd
│   │   │   └── marketplace_system.gd
│   │   ├── kingdom/
│   │   │   ├── kingdom_system.gd
│   │   │   ├── war_system.gd
│   │   │   └── diplomacy_system.gd
│   │   └── world/
│   │       ├── day_night_cycle.gd
│   │       ├── weather_system.gd
│   │       ├── season_system.gd
│   │       └── zone_manager.gd
│   ├── components/
│   │   ├── health_component.gd
│   │   ├── stamina_component.gd
│   │   ├── hunger_component.gd
│   │   ├── movement_component.gd
│   │   └── interaction_component.gd
│   └── data/
│       ├── item_defs.gd            # Item type definitions
│       ├── recipe_defs.gd          # Crafting recipe definitions
│       ├── structure_defs.gd       # Building definitions
│       ├── skill_defs.gd           # Skill XP curves and milestones
│       └── weapon_defs.gd          # Weapon stat definitions
└── addons/
    └── (any Godot addons)
```

### 1.2 Project Settings (project.godot)
```
[application]
config/name="Sovereign"
run/main_scene="res://scenes/main/main.tscn"
config/icon="res://assets/textures/ui/icon.png"

[display]
window/size/viewport_width=1920
window/size/viewport_height=1080
window/stretch/mode="canvas_items"

[input]
move_click={mouse_button: 1}
attack={mouse_button: 1}
block={mouse_button: 2}
interact={key: E}
inventory={key: I}
build_menu={key: B}
map={key: M}
character_screen={key: C}
hotbar_1={key: 1}
hotbar_2={key: 2}
hotbar_3={key: 3}
hotbar_4={key: 4}
hotbar_5={key: 5}
hotbar_6={key: 6}
hotbar_7={key: 7}
hotbar_8={key: 8}
hotbar_9={key: 9}
hotbar_10={key: 0}
sprint={key: Shift}
dodge={key: Space}
chat_enter={key: Enter}
zone_travel={key: E}
admin_console={key: QuoteLeft}

[autoload]
GameManager="*res://scripts/autoload/game_manager.gd"
NetworkManager="*res://scripts/autoload/network_manager.gd"
InputManager="*res://scripts/autoload/input_manager.gd"
AudioManager="*res://scripts/autoload/audio_manager.gd"
Config="*res://scripts/autoload/config.gd"

[rendering]
renderer/rendering_method="forward_plus"
```

### 1.3 Isometric Camera (`scripts/autoload/config.gd` constants + `scenes/player/player_camera.gd`)

**`scripts/autoload/config.gd`:**
```gdscript
extends Node

# Camera
const CAMERA_ANGLE_X: float = -45.0    # Isometric tilt (degrees)
const CAMERA_ANGLE_Y: float = 45.0     # Isometric rotation (degrees)
const CAMERA_ZOOM_MIN: float = 5.0     # Closest zoom (orthographic size)
const CAMERA_ZOOM_MAX: float = 25.0    # Farthest zoom
const CAMERA_ZOOM_DEFAULT: float = 12.0
const CAMERA_ZOOM_SPEED: float = 2.0
const CAMERA_FOLLOW_SPEED: float = 8.0 # Lerp speed

# Movement
const WALK_SPEED: float = 5.0          # m/s
const SPRINT_SPEED: float = 8.0        # m/s
const SPRINT_STAMINA_COST: float = 10.0 # SP/sec
const ROAD_SPEED_BONUS: float = 0.25   # +25%
const PATH_ARRIVE_THRESHOLD: float = 0.3 # meters

# Server
const TICK_RATE: int = 20
const TICK_DELTA: float = 0.05         # 1/20
```

**`scenes/player/player_camera.gd`:**
```gdscript
class_name PlayerCamera
extends Camera3D

var target: Node3D = null
var current_zoom: float = Config.CAMERA_ZOOM_DEFAULT

func _ready() -> void:
    projection = Camera3D.PROJECTION_ORTHOGONAL
    size = current_zoom
    rotation_degrees = Vector3(Config.CAMERA_ANGLE_X, Config.CAMERA_ANGLE_Y, 0)

func _process(delta: float) -> void:
    if target:
        global_position = global_position.lerp(
            target.global_position + _get_camera_offset(),
            Config.CAMERA_FOLLOW_SPEED * delta
        )

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            current_zoom = max(Config.CAMERA_ZOOM_MIN, current_zoom - Config.CAMERA_ZOOM_SPEED)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            current_zoom = min(Config.CAMERA_ZOOM_MAX, current_zoom + Config.CAMERA_ZOOM_SPEED)
        size = current_zoom

func _get_camera_offset() -> Vector3:
    # Offset camera position so it looks down at the target from isometric angle
    var distance: float = 20.0
    var angle_x_rad: float = deg_to_rad(Config.CAMERA_ANGLE_X)
    var angle_y_rad: float = deg_to_rad(Config.CAMERA_ANGLE_Y)
    return Vector3(
        distance * cos(angle_x_rad) * sin(angle_y_rad),
        distance * sin(-angle_x_rad),
        distance * cos(angle_x_rad) * cos(angle_y_rad)
    )

func screen_to_ground(screen_pos: Vector2) -> Vector3:
    # Project screen position to ground plane (y=0)
    var from: Vector3 = project_ray_origin(screen_pos)
    var dir: Vector3 = project_ray_normal(screen_pos)
    if dir.y == 0:
        return Vector3.ZERO
    var t: float = -from.y / dir.y
    return from + dir * t
```

### 1.4 Click-to-Move Player Controller (`scenes/player/player.gd`)

```gdscript
class_name PlayerController
extends CharacterBody3D

@onready var camera: PlayerCamera = $PlayerCamera
@onready var model: Node3D = $PlayerModel
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var move_target: Vector3 = Vector3.ZERO
var is_moving: bool = false
var is_sprinting: bool = false
var current_speed: float = Config.WALK_SPEED

# Stats
var health: int = 100
var max_health: int = 100
var stamina: float = 100.0
var max_stamina: float = 100.0
var hunger: float = 100.0
var carry_weight: float = 0.0
var max_carry_weight: float = 100.0

func _ready() -> void:
    camera.target = self
    nav_agent.path_desired_distance = Config.PATH_ARRIVE_THRESHOLD
    nav_agent.target_desired_distance = Config.PATH_ARRIVE_THRESHOLD

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            _handle_left_click(event.position)

func _physics_process(delta: float) -> void:
    _update_stamina(delta)
    _update_hunger(delta)
    _process_movement(delta)

func _handle_left_click(screen_pos: Vector2) -> void:
    var ground_pos: Vector3 = camera.screen_to_ground(screen_pos)
    # TODO: Check if clicked on enemy (attack) or ground (move)
    # For Step 1, always move
    _set_move_target(ground_pos)

func _set_move_target(target: Vector3) -> void:
    move_target = target
    nav_agent.target_position = target
    is_moving = true

func _process_movement(delta: float) -> void:
    if not is_moving:
        return
    if nav_agent.is_navigation_finished():
        is_moving = false
        return

    var next_pos: Vector3 = nav_agent.get_next_path_position()
    var direction: Vector3 = (next_pos - global_position).normalized()
    direction.y = 0

    # Calculate speed with modifiers
    current_speed = Config.WALK_SPEED
    if is_sprinting and stamina > 0:
        current_speed = Config.SPRINT_SPEED
    current_speed *= _get_encumbrance_modifier()
    # TODO: road bonus check

    velocity = direction * current_speed
    move_and_slide()

    # Rotate model to face movement direction
    if direction.length() > 0.1:
        model.look_at(global_position + direction, Vector3.UP)

func _get_encumbrance_modifier() -> float:
    if carry_weight <= max_carry_weight:
        return 1.0
    var overweight_ratio: float = carry_weight / max_carry_weight
    if overweight_ratio >= 1.5:
        return 0.0  # Cannot move
    return 1.0 - ((overweight_ratio - 1.0) / 0.5)

func _update_stamina(delta: float) -> void:
    if is_sprinting and is_moving:
        stamina -= Config.SPRINT_STAMINA_COST * delta
        stamina = max(0, stamina)
        if stamina <= 0:
            is_sprinting = false
    else:
        stamina = min(max_stamina, stamina + 5.0 * delta)

func _update_hunger(delta: float) -> void:
    # 1 HG/min base, modified by season
    var hunger_rate: float = 1.0 / 60.0  # per second
    # TODO: Season modifier (0.5 summer, 1.5 winter)
    hunger -= hunger_rate * delta
    hunger = max(0, hunger)
    if hunger <= 0:
        # Lose 1 HP per 10 sec
        health -= delta / 10.0
```

### 1.5 Terrain Setup (`scenes/world/terrain.gd`)

```gdscript
class_name GameTerrain
extends Node3D

# For MVP, terrain is a flat MeshInstance3D with NavigationRegion3D
# Later: load heightmap-based terrain per zone

@onready var nav_region: NavigationRegion3D = $NavigationRegion3D

const ZONE_SIZE: float = 500.0  # meters per zone
const WORLD_ZONES: int = 3      # 3x3 starting grid

func _ready() -> void:
    _generate_flat_terrain()
    _bake_navigation()

func _generate_flat_terrain() -> void:
    var total_size: float = ZONE_SIZE * WORLD_ZONES  # 1500m
    var mesh := PlaneMesh.new()
    mesh.size = Vector2(total_size, total_size)
    mesh.subdivide_width = 100
    mesh.subdivide_depth = 100
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.mesh = mesh
    # Apply grass material
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.35, 0.55, 0.25)  # Placeholder grass
    mesh_instance.material_override = material
    add_child(mesh_instance)

func _bake_navigation() -> void:
    var nav_mesh := NavigationMesh.new()
    nav_mesh.agent_radius = 0.4
    nav_mesh.agent_height = 1.8
    nav_region.navigation_mesh = nav_mesh
    nav_region.bake_navigation_mesh()
```

### 1.6 Game Manager Singleton (`scripts/autoload/game_manager.gd`)

```gdscript
extends Node

enum GameState { MENU, PLAYING, PAUSED, DEAD, LOADING }

var current_state: GameState = GameState.MENU
var player: PlayerController = null
var current_zone_id: int = 0
var game_time: float = 0.0       # In-game hours (0-24)
var game_day: int = 1
var current_season: int = 0      # 0=summer, 1=winter
var is_admin: bool = false

signal state_changed(new_state: GameState)
signal time_updated(hours: float, day: int)
signal season_changed(season: int)

func _process(delta: float) -> void:
    if current_state == GameState.PLAYING:
        _update_game_time(delta)

func _update_game_time(delta: float) -> void:
    # 2 real hours = 1 game day (24 game hours)
    # So 1 real second = 24 / 7200 game hours = 0.00333 game hours
    game_time += delta * (24.0 / 7200.0)
    if game_time >= 24.0:
        game_time -= 24.0
        game_day += 1
        # Check season change (7 real days per season = 84 game days)
        # 7 days * 12 cycles/day = 84 game days per season
    time_updated.emit(game_time, game_day)

func is_night() -> bool:
    return game_time < 6.0 or game_time > 20.0

func change_state(new_state: GameState) -> void:
    current_state = new_state
    state_changed.emit(new_state)
```

### 1.7 Test Criteria for Step 1
- [ ] Godot project opens with correct folder structure
- [ ] Isometric camera renders at 45° angle with orthographic projection
- [ ] Scroll wheel zooms in/out between min/max
- [ ] Left click on ground → character pathfinds to clicked position
- [ ] Character rotates to face movement direction
- [ ] Flat terrain renders with placeholder green material
- [ ] Sprint (hold Shift) moves faster and drains stamina
- [ ] Stamina regens when not sprinting
- [ ] Camera smoothly follows player
- [ ] Day/night time advances (visible in debug output)

---

## STEP 2: Combat Prototype — Single Player (Week 3-5)

### 2.1 Combat State Machine (`scripts/systems/combat/combat_state_machine.gd`)

```gdscript
class_name CombatStateMachine
extends Node

enum State {
    IDLE,
    ATTACKING,
    BLOCKING,
    STAGGERED,
    DODGING,
    DOWNED,
    DEAD
}

var current_state: State = State.IDLE
var state_timer: float = 0.0
var owner_entity: CharacterBody3D = null

# Attack data
var current_attack_tier: int = 0  # 0=jab, 1=normal, 2=heavy
var attack_direction: int = 0     # 0-7 (8 directions)

# Block data
var block_direction: int = 0

# Dodge
var dodge_direction: Vector3 = Vector3.ZERO
const DODGE_DURATION: float = 0.3
const DODGE_SPEED: float = 15.0
const DODGE_STAMINA_COST: float = 20.0
const DODGE_COOLDOWN: float = 1.0
var dodge_cooldown_timer: float = 0.0

# Stagger
const STAGGER_DURATION: float = 0.5

# Downed
var bleedout_timer: float = 0.0

signal state_changed(old_state: State, new_state: State)
signal attack_executed(tier: int, direction: int)
signal block_hit(damage_blocked: float, stamina_cost: float)
signal entity_downed(bleedout_time: float)
signal entity_died()

func _ready() -> void:
    owner_entity = get_parent()

func _process(delta: float) -> void:
    state_timer -= delta
    dodge_cooldown_timer -= delta
    match current_state:
        State.ATTACKING:
            if state_timer <= 0:
                _transition_to(State.IDLE)
        State.STAGGERED:
            if state_timer <= 0:
                _transition_to(State.IDLE)
        State.DODGING:
            if state_timer <= 0:
                _transition_to(State.IDLE)
            else:
                _process_dodge(delta)
        State.DOWNED:
            bleedout_timer -= delta
            if bleedout_timer <= 0:
                _transition_to(State.DEAD)

func try_attack(tier: int, direction: int, weapon_speed: float, stamina_cost: float) -> bool:
    if current_state != State.IDLE:
        return false
    if owner_entity.stamina < stamina_cost:
        return false
    current_attack_tier = tier
    attack_direction = direction
    owner_entity.stamina -= stamina_cost
    var duration: float = weapon_speed  # 0.4-0.8 sec
    match tier:
        0: duration *= 0.6   # jab is faster
        1: duration *= 1.0   # normal
        2: duration *= 1.4   # heavy is slower
    state_timer = duration
    _transition_to(State.ATTACKING)
    attack_executed.emit(tier, direction)
    return true

func try_block(direction: int) -> bool:
    if current_state != State.IDLE:
        return false
    block_direction = direction
    _transition_to(State.BLOCKING)
    return true

func stop_block() -> void:
    if current_state == State.BLOCKING:
        _transition_to(State.IDLE)

func try_dodge(direction: Vector3, stamina: float) -> bool:
    if current_state != State.IDLE:
        return false
    if dodge_cooldown_timer > 0:
        return false
    if stamina < DODGE_STAMINA_COST:
        return false
    dodge_direction = direction.normalized()
    owner_entity.stamina -= DODGE_STAMINA_COST
    state_timer = DODGE_DURATION
    dodge_cooldown_timer = DODGE_COOLDOWN
    _transition_to(State.DODGING)
    return true

func try_kick(stamina_cost: float) -> bool:
    if current_state != State.IDLE:
        return false
    if owner_entity.stamina < stamina_cost:
        return false
    owner_entity.stamina -= stamina_cost
    return true

func apply_stagger() -> void:
    state_timer = STAGGER_DURATION
    _transition_to(State.STAGGERED)

func enter_downed(bleedout_time: float) -> void:
    bleedout_timer = bleedout_time
    _transition_to(State.DOWNED)
    entity_downed.emit(bleedout_time)

func can_be_hit() -> bool:
    if current_state == State.DODGING and state_timer > 0:
        return false  # i-frames during dodge
    if current_state == State.DEAD:
        return false
    return true

func is_blocking_direction(incoming_dir: int) -> bool:
    if current_state != State.BLOCKING:
        return false
    # Check if block faces within 90° of incoming attack
    var diff: int = abs(incoming_dir - block_direction)
    if diff > 4:
        diff = 8 - diff
    return diff <= 1  # Within 1 sector (90°)

func _process_dodge(delta: float) -> void:
    owner_entity.velocity = dodge_direction * DODGE_SPEED
    owner_entity.move_and_slide()

func _transition_to(new_state: State) -> void:
    var old: State = current_state
    current_state = new_state
    state_changed.emit(old, new_state)
```

### 2.2 Damage Calculator (`scripts/systems/combat/damage_calculator.gd`)

```gdscript
class_name DamageCalculator
extends RefCounted

static func calculate_damage(
    base_damage: int,
    attack_tier: int,       # 0=jab, 1=normal, 2=heavy
    weapon_type: String,    # "slash", "blunt", "pierce"
    hit_zone: String,       # "head", "torso", "left_arm", etc.
    armor_type: String,     # "none", "leather", "bronze_plate", "iron_plate"
    attacker_skill: int,    # melee/ranged weapon skill level
    is_blocked: bool,
    shield_type: String     # "none", "kite"
) -> Dictionary:
    var damage: float = float(base_damage)

    # Tier multiplier
    match attack_tier:
        0: damage *= 0.5   # jab
        1: damage *= 1.0   # normal
        2: damage *= 1.5   # heavy

    # Skill bonus (up to +30% at level 100)
    damage *= 1.0 + (attacker_skill * 0.003)

    # Zone multiplier
    var zone_mult: float = _get_zone_multiplier(hit_zone)
    damage *= zone_mult

    # Armor resistance
    var resistance: float = _get_armor_resistance(armor_type, weapon_type)
    damage *= (1.0 - resistance)

    # Block reduction
    var stamina_cost: float = 0.0
    if is_blocked:
        damage *= 0.2  # Block reduces 80% damage
        stamina_cost = _get_shield_block_cost(shield_type)

    # Determine injury
    var injury_type: String = _determine_injury(hit_zone, damage)

    return {
        "final_damage": int(damage),
        "hit_zone": hit_zone,
        "injury_type": injury_type,
        "blocked": is_blocked,
        "block_stamina_cost": stamina_cost
    }

static func _get_zone_multiplier(zone: String) -> float:
    match zone:
        "head": return 2.0
        "torso": return 1.0
        "left_arm", "right_arm": return 0.7
        "left_leg", "right_leg": return 0.8
    return 1.0

static func _get_armor_resistance(armor: String, damage_type: String) -> float:
    # Returns resistance as float 0-1
    var table: Dictionary = {
        "none":          {"slash": 0.0,  "blunt": 0.0,  "pierce": 0.0},
        "leather":       {"slash": 0.20, "blunt": 0.10, "pierce": 0.15},
        "bronze_plate":  {"slash": 0.40, "blunt": 0.20, "pierce": 0.35},
        "iron_plate":    {"slash": 0.55, "blunt": 0.30, "pierce": 0.50},
    }
    if armor in table and damage_type in table[armor]:
        return table[armor][damage_type]
    return 0.0

static func _get_shield_block_cost(shield: String) -> float:
    match shield:
        "kite": return 8.0
    return 0.0

static func _determine_injury(zone: String, damage: float) -> String:
    if damage < 15:
        return "none"
    elif damage < 30:
        return "minor"
    elif damage < 50:
        return "moderate"
    else:
        return "severe"

static func get_bleedout_time(injuries: Dictionary) -> float:
    # Based on worst injury severity
    var base_time: float = 60.0  # seconds
    if injuries.get("torso", "none") == "severe":
        base_time = 15.0
    elif injuries.get("head", "none") == "severe":
        base_time = 10.0
    elif injuries.get("torso", "none") == "moderate":
        base_time = 30.0
    return base_time
```

### 2.3 Hit Zone System (`scripts/systems/combat/hit_zone_system.gd`)

```gdscript
class_name HitZoneSystem
extends RefCounted

# Given attack direction (0-7) and relative height of hit,
# determine which body zone is struck

static func determine_hit_zone(
    attack_direction: int,
    attacker_pos: Vector3,
    defender_pos: Vector3,
    attack_height: float  # 0=low, 0.5=mid, 1.0=high
) -> String:
    # Height determines vertical zone
    if attack_height > 0.8:
        return "head"
    elif attack_height > 0.4:
        # Mid-height: direction determines left/right arm or torso
        var angle: float = _direction_to_angle(attack_direction)
        var relative: float = _get_relative_angle(attacker_pos, defender_pos, angle)
        if relative < -30:
            return "left_arm"
        elif relative > 30:
            return "right_arm"
        else:
            return "torso"
    else:
        # Low: legs
        var angle: float = _direction_to_angle(attack_direction)
        var relative: float = _get_relative_angle(attacker_pos, defender_pos, angle)
        if relative < 0:
            return "left_leg"
        else:
            return "right_leg"

static func _direction_to_angle(dir: int) -> float:
    return dir * 45.0  # 0=north, 1=NE, 2=east, etc.

static func _get_relative_angle(attacker: Vector3, defender: Vector3, attack_angle: float) -> float:
    var to_defender: Vector3 = (defender - attacker).normalized()
    var defender_facing: float = atan2(to_defender.x, to_defender.z)
    return rad_to_deg(defender_facing) - attack_angle
```

### 2.4 Weapon Definitions (`scripts/data/weapon_defs.gd`)

```gdscript
class_name WeaponDefs
extends RefCounted

const WEAPONS: Dictionary = {
    "flint_knife": {
        "display_name": "Flint Knife",
        "damage": 8, "speed": 0.4, "stamina_cost": 5,
        "range": 1.0, "durability": 30,
        "damage_type": "slash", "category": "melee",
        "skill": "melee_weapons"
    },
    "bronze_sword": {
        "display_name": "Bronze Sword",
        "damage": 18, "speed": 0.6, "stamina_cost": 12,
        "range": 1.5, "durability": 80,
        "damage_type": "slash", "category": "melee",
        "skill": "melee_weapons"
    },
    "iron_sword": {
        "display_name": "Iron Sword",
        "damage": 25, "speed": 0.6, "stamina_cost": 14,
        "range": 1.5, "durability": 150,
        "damage_type": "slash", "category": "melee",
        "skill": "melee_weapons"
    },
    "bronze_spear": {
        "display_name": "Bronze Spear",
        "damage": 15, "speed": 0.8, "stamina_cost": 15,
        "range": 2.5, "durability": 60,
        "damage_type": "pierce", "category": "melee",
        "skill": "melee_weapons"
    },
    "iron_spear": {
        "display_name": "Iron Spear",
        "damage": 22, "speed": 0.8, "stamina_cost": 17,
        "range": 2.5, "durability": 120,
        "damage_type": "pierce", "category": "melee",
        "skill": "melee_weapons"
    },
    "bronze_mace": {
        "display_name": "Bronze Mace",
        "damage": 20, "speed": 0.8, "stamina_cost": 18,
        "range": 1.2, "durability": 100,
        "damage_type": "blunt", "category": "melee",
        "skill": "melee_weapons"
    },
    "iron_mace": {
        "display_name": "Iron Mace",
        "damage": 30, "speed": 0.8, "stamina_cost": 22,
        "range": 1.2, "durability": 180,
        "damage_type": "blunt", "category": "melee",
        "skill": "melee_weapons"
    },
    "short_bow": {
        "display_name": "Short Bow",
        "damage": 12, "speed": 0.8, "stamina_cost": 8,
        "range": 30.0, "durability": 50,
        "damage_type": "pierce", "category": "ranged",
        "skill": "ranged_weapons", "projectile_speed": 25.0
    },
    "crossbow": {
        "display_name": "Crossbow",
        "damage": 28, "speed": 2.0, "stamina_cost": 10,
        "range": 45.0, "durability": 70,
        "damage_type": "pierce", "category": "ranged",
        "skill": "ranged_weapons", "projectile_speed": 35.0
    }
}
```

### 2.5 Attack Direction from Mouse (`scripts/systems/combat/` helper in player.gd)

Add to `player.gd`:
```gdscript
func _get_attack_direction_from_mouse() -> int:
    # Screen-space: mouse position relative to character's screen position
    var char_screen_pos: Vector2 = camera.unproject_position(global_position)
    var mouse_pos: Vector2 = get_viewport().get_mouse_position()
    var diff: Vector2 = mouse_pos - char_screen_pos
    var angle: float = atan2(diff.x, -diff.y)  # 0=up, clockwise
    if angle < 0:
        angle += TAU
    # Divide into 8 sectors of 45° each
    var sector: int = int(round(angle / (TAU / 8.0))) % 8
    return sector
```

### 2.6 Dummy AI Enemy (`scenes/entities/npc.gd`)

```gdscript
class_name NPCEntity
extends CharacterBody3D

@onready var combat_sm: CombatStateMachine = $CombatStateMachine
@onready var health_component: HealthComponent = $HealthComponent

var health: int = 100
var stamina: float = 100.0
var max_stamina: float = 100.0

var target: Node3D = null
var aggro_range: float = 10.0
var attack_range: float = 1.5
var patrol_center: Vector3 = Vector3.ZERO
var patrol_radius: float = 5.0

enum AIState { IDLE, PATROL, CHASE, ATTACK, FLEE }
var ai_state: AIState = AIState.PATROL

var equipped_weapon: String = "flint_knife"
var equipped_armor: String = "none"

# Injuries
var injuries: Dictionary = {
    "head": "none", "torso": "none",
    "left_arm": "none", "right_arm": "none",
    "left_leg": "none", "right_leg": "none"
}

func _ready() -> void:
    patrol_center = global_position

func _physics_process(delta: float) -> void:
    _update_ai(delta)

func _update_ai(delta: float) -> void:
    match ai_state:
        AIState.PATROL:
            _patrol(delta)
        AIState.CHASE:
            _chase(delta)
        AIState.ATTACK:
            _try_attack()

func _patrol(delta: float) -> void:
    # Simple wander near patrol_center
    # Check for player in aggro_range
    var player = GameManager.player
    if player and global_position.distance_to(player.global_position) < aggro_range:
        target = player
        ai_state = AIState.CHASE

func _chase(delta: float) -> void:
    if not target:
        ai_state = AIState.PATROL
        return
    var dist: float = global_position.distance_to(target.global_position)
    if dist > aggro_range * 1.5:
        target = null
        ai_state = AIState.PATROL
        return
    if dist <= attack_range:
        ai_state = AIState.ATTACK
        return
    var dir: Vector3 = (target.global_position - global_position).normalized()
    dir.y = 0
    velocity = dir * Config.WALK_SPEED * 0.8
    move_and_slide()

func _try_attack() -> void:
    if not target:
        ai_state = AIState.PATROL
        return
    var dist: float = global_position.distance_to(target.global_position)
    if dist > attack_range:
        ai_state = AIState.CHASE
        return
    var weapon_data: Dictionary = WeaponDefs.WEAPONS[equipped_weapon]
    combat_sm.try_attack(1, 0, weapon_data["speed"], weapon_data["stamina_cost"])

func take_damage(damage_result: Dictionary) -> void:
    health -= damage_result["final_damage"]
    var zone: String = damage_result["hit_zone"]
    var injury: String = damage_result["injury_type"]
    if injury != "none":
        injuries[zone] = injury
    if health <= 0:
        var bleedout: float = DamageCalculator.get_bleedout_time(injuries)
        combat_sm.enter_downed(bleedout)
```

### 2.7 Test Criteria for Step 2
- [ ] Combat state machine transitions correctly: idle → attacking → idle, idle → blocking → idle
- [ ] 3 attack tiers work (tap=jab, click=normal, hold=heavy) with different speeds
- [ ] 8-directional attacks aim based on mouse screen position
- [ ] Blocking in correct direction reduces damage
- [ ] Attacks from behind always hit (block fails)
- [ ] Dodge gives invulnerability frames, costs stamina, has cooldown
- [ ] Kick/shove breaks blocks
- [ ] 6 hit zones receive damage independently
- [ ] Injuries affect gameplay (broken arm = -50% damage, broken leg = limping)
- [ ] Downed state with bleedout timer works
- [ ] Execution mechanic (3-5 second channel on downed enemy)
- [ ] Dummy AI enemies patrol, aggro, chase, and attack
- [ ] All 7 melee weapons + 2 ranged weapons have distinct feel
- [ ] Kite shield blocks with stamina cost
- [ ] Stamina system: attacks cost stamina, 0 stamina = can't attack/block

---

## STEP 3: Resources, Inventory, Crafting (Week 6-8)

### 3.1 Key Files
- `scripts/systems/inventory/inventory.gd` — Weight-based inventory with slots
- `scripts/systems/inventory/item_database.gd` — All item type definitions
- `scripts/systems/inventory/equipment_manager.gd` — Equipped item slots (head, chest, legs, hands, feet, main_hand, off_hand)
- `scripts/systems/crafting/crafting_system.gd` — Station-based crafting with failure chance
- `scripts/systems/crafting/recipe_database.gd` — All crafting recipes
- `scenes/entities/resource_node.gd` — Gatherable resource (tree, stone, ore, bush)
- `scenes/ui/menus/inventory_screen.gd` — Inventory UI

### 3.2 Inventory System (`scripts/systems/inventory/inventory.gd`)

```gdscript
class_name Inventory
extends Node

var items: Array[Dictionary] = []  # Array of item instances
var max_weight: float = 100.0
var current_weight: float = 0.0
var max_slots: int = 40  # Inventory grid slots

signal item_added(item: Dictionary)
signal item_removed(item_id: String)
signal weight_changed(new_weight: float)
signal inventory_full()

func add_item(item_type: String, quantity: int = 1, quality: String = "normal") -> bool:
    var item_def: Dictionary = ItemDatabase.get_item(item_type)
    if not item_def:
        return false
    var total_weight: float = item_def["weight"] * quantity
    if current_weight + total_weight > max_weight * 1.5:  # Hard cap at 150%
        inventory_full.emit()
        return false
    # Check if stackable and existing stack
    if item_def.get("stackable", false):
        for existing in items:
            if existing["item_type"] == item_type and existing["quality"] == quality:
                existing["quantity"] += quantity
                current_weight += total_weight
                weight_changed.emit(current_weight)
                return true
    if items.size() >= max_slots:
        inventory_full.emit()
        return false
    var new_item: Dictionary = {
        "id": _generate_id(),
        "item_type": item_type,
        "quantity": quantity,
        "quality": quality,
        "durability": item_def.get("durability", -1),
        "max_durability": item_def.get("durability", -1),
        "weight": item_def["weight"] * quantity,
        "crafter_name": "",
        "custom_name": "",
        "spoil_at": -1.0,  # Unix timestamp, -1 = no spoilage
    }
    if item_def.get("spoil_hours", 0) > 0:
        new_item["spoil_at"] = Time.get_unix_time_from_system() + item_def["spoil_hours"] * 3600
    items.append(new_item)
    current_weight += total_weight
    weight_changed.emit(current_weight)
    item_added.emit(new_item)
    return true

func remove_item(item_id: String, quantity: int = 1) -> bool:
    for i in range(items.size()):
        if items[i]["id"] == item_id:
            if items[i]["quantity"] <= quantity:
                current_weight -= items[i]["weight"]
                items.remove_at(i)
            else:
                var item_def: Dictionary = ItemDatabase.get_item(items[i]["item_type"])
                var weight_per: float = item_def["weight"]
                items[i]["quantity"] -= quantity
                items[i]["weight"] -= weight_per * quantity
                current_weight -= weight_per * quantity
            weight_changed.emit(current_weight)
            item_removed.emit(item_id)
            return true
    return false

func has_item(item_type: String, quantity: int = 1) -> bool:
    var count: int = 0
    for item in items:
        if item["item_type"] == item_type:
            count += item["quantity"]
    return count >= quantity

func get_items_of_type(item_type: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for item in items:
        if item["item_type"] == item_type:
            result.append(item)
    return result

func _generate_id() -> String:
    return str(randi()) + str(Time.get_ticks_msec())
```

### 3.3 Crafting System (`scripts/systems/crafting/crafting_system.gd`)

```gdscript
class_name CraftingSystem
extends Node

signal craft_started(recipe_id: String, duration: float)
signal craft_completed(recipe_id: String, item: Dictionary)
signal craft_failed(recipe_id: String, reason: String)

var active_craft: Dictionary = {}  # Currently crafting
var craft_timer: float = 0.0

func attempt_craft(
    recipe_id: String,
    inventory: Inventory,
    station_type: String,
    skill_level: int
) -> bool:
    var recipe: Dictionary = RecipeDatabase.get_recipe(recipe_id)
    if not recipe:
        craft_failed.emit(recipe_id, "Unknown recipe")
        return false
    # Check station
    if recipe["station"] != station_type and recipe["station"] != "inventory":
        craft_failed.emit(recipe_id, "Wrong crafting station")
        return false
    # Check skill
    if skill_level < recipe["skill_req"]:
        craft_failed.emit(recipe_id, "Skill too low")
        return false
    # Check materials
    for mat in recipe["materials"]:
        if not inventory.has_item(mat["item_type"], mat["quantity"]):
            craft_failed.emit(recipe_id, "Missing materials: " + mat["item_type"])
            return false
    # Consume materials
    for mat in recipe["materials"]:
        var items_of_type: Array = inventory.get_items_of_type(mat["item_type"])
        var remaining: int = mat["quantity"]
        for item in items_of_type:
            if remaining <= 0:
                break
            var take: int = min(item["quantity"], remaining)
            inventory.remove_item(item["id"], take)
            remaining -= take
    # Start craft timer
    active_craft = recipe
    craft_timer = recipe["craft_time"]
    craft_started.emit(recipe_id, craft_timer)
    return true

func _process(delta: float) -> void:
    if active_craft.is_empty():
        return
    craft_timer -= delta
    if craft_timer <= 0:
        _complete_craft()

func _complete_craft() -> void:
    var recipe: Dictionary = active_craft
    active_craft = {}
    # Failure check
    var fail_chance: float = _calculate_failure_chance(recipe)
    if randf() < fail_chance:
        craft_failed.emit(recipe["id"], "Craft failed! Materials lost.")
        return
    # Quality check
    var quality: String = "normal"
    var superior_chance: float = _calculate_superior_chance(recipe)
    if randf() < superior_chance:
        quality = "superior"
    craft_completed.emit(recipe["id"], {
        "item_type": recipe["output"],
        "quantity": recipe.get("output_quantity", 1),
        "quality": quality
    })

func _calculate_failure_chance(recipe: Dictionary) -> float:
    # Higher skill relative to requirement = lower failure
    # At skill_req: 30% fail. At 2x skill_req: 5% fail. At 100: 1% fail.
    var skill: int = 50  # TODO: get from actual skill system
    var req: int = recipe["skill_req"]
    if req == 0:
        return 0.0
    var ratio: float = float(skill) / float(req)
    return max(0.01, 0.30 / ratio)

func _calculate_superior_chance(recipe: Dictionary) -> float:
    var skill: int = 50  # TODO: get from actual skill system
    # 0% at skill 50, ~5% at 75, ~20% at 100
    if skill < 50:
        return 0.0
    return (float(skill) - 50.0) / 250.0  # 20% at 100
```

### 3.4 Resource Node (`scenes/entities/resource_node.gd`)

```gdscript
class_name ResourceNode
extends StaticBody3D

@export var resource_type: String = "tree"  # tree, stone, ore_copper, ore_iron, berry_bush, flint, fiber
@export var max_health: int = 100
@export var yield_item: String = "wood_log"
@export var yield_quantity: int = 3
@export var required_tool: String = ""  # "" = hand gatherable, "axe", "pickaxe"
@export var required_skill: String = ""
@export var required_skill_level: int = 0
@export var gather_time: float = 3.0  # seconds per gather action
@export var respawn_time: float = 300.0  # seconds to respawn after depleted

var current_health: int = 0
var is_depleted: bool = false
var respawn_timer: float = 0.0

signal gather_started(node: ResourceNode, duration: float)
signal gather_completed(node: ResourceNode, item_type: String, quantity: int)
signal node_depleted(node: ResourceNode)
signal node_respawned(node: ResourceNode)

func _ready() -> void:
    current_health = max_health

func _process(delta: float) -> void:
    if is_depleted:
        respawn_timer -= delta
        if respawn_timer <= 0:
            _respawn()

func can_gather(tool_type: String, skill_name: String, skill_level: int) -> bool:
    if is_depleted:
        return false
    if required_tool != "" and tool_type != required_tool:
        return false
    if required_skill != "" and skill_level < required_skill_level:
        return false
    return true

func gather_hit(damage: int) -> Dictionary:
    current_health -= damage
    var result: Dictionary = {"yielded": false, "item_type": "", "quantity": 0}
    if current_health <= 0:
        result["yielded"] = true
        result["item_type"] = yield_item
        result["quantity"] = yield_quantity
        is_depleted = true
        respawn_timer = respawn_time
        node_depleted.emit(self)
        visible = false  # Hide depleted node
    return result

func _respawn() -> void:
    is_depleted = false
    current_health = max_health
    visible = true
    node_respawned.emit(self)
```

### 3.5 Test Criteria for Step 3
- [ ] Resource nodes (tree, stone, ore, bush, flint, fiber) placed in world and gatherable
- [ ] Gathering shows progress bar, yields items on completion
- [ ] Weight-based inventory: items have weight, encumbrance slows movement
- [ ] Cannot move at 150%+ carry weight
- [ ] Crafting at inventory level (flint tools) works without station
- [ ] Station-based crafting (workbench, forge) requires proximity to station
- [ ] Crafting failure chance based on skill level
- [ ] Item durability decreases with use, repair possible
- [ ] Full crafting chain: gather wood → craft axe → chop tree → get logs → craft planks
- [ ] Item spoilage timer on food items
- [ ] Equipment manager: equip/unequip to 5 armor slots + weapon + offhand

---

## STEP 4: Building System (Week 9-12)

### 4.1 Key Files
- `scripts/systems/building/building_system.gd` — Core building logic
- `scripts/systems/building/blueprint_placer.gd` — Ghost preview placement
- `scripts/systems/building/claim_system.gd` — Hearthstone claims, tier upgrades
- `scripts/systems/building/structure_database.gd` — All structure definitions
- `scripts/data/structure_defs.gd` — Structure stat definitions

### 4.2 Claim System (`scripts/systems/building/claim_system.gd`)

```gdscript
class_name ClaimSystem
extends Node

const TIER_DATA: Array[Dictionary] = [
    {"name": "Homestead", "radius": 20.0, "max_structures": 15, "min_population": 1},
    {"name": "Hamlet", "radius": 40.0, "max_structures": 40, "min_population": 5},
    {"name": "Village", "radius": 70.0, "max_structures": 100, "min_population": 15},
    {"name": "Town", "radius": 120.0, "max_structures": 300, "min_population": 50},
    {"name": "City", "radius": 200.0, "max_structures": 9999, "min_population": 200},
]

const MIN_HEARTHSTONE_DISTANCE: float = 50.0
const RAIDABLE_STRUCTURE_THRESHOLD: int = 20
const NEW_ACCOUNT_HEARTHSTONE_DELAY: float = 7200.0  # 2 hours playtime

func can_place_hearthstone(player: PlayerController, position: Vector3) -> Dictionary:
    # Check playtime requirement
    if player.total_playtime < NEW_ACCOUNT_HEARTHSTONE_DELAY:
        return {"allowed": false, "reason": "Need 2 hours playtime before claiming land"}
    # Check player doesn't already have a hearthstone
    # (handled by checking existing settlements owned by player)
    # Check minimum distance from other hearthstones
    # TODO: query all settlements and check distance
    return {"allowed": true, "reason": ""}

func get_claim_radius(tier: int) -> float:
    if tier < 0 or tier >= TIER_DATA.size():
        return 0.0
    return TIER_DATA[tier]["radius"]

func get_max_structures(tier: int) -> int:
    if tier < 0 or tier >= TIER_DATA.size():
        return 0
    return TIER_DATA[tier]["max_structures"]

func is_raidable(settlement_tier: int, structure_count: int, in_kingdom: bool) -> bool:
    if in_kingdom:
        return true  # Kingdom settlements always raidable via war
    return structure_count > RAIDABLE_STRUCTURE_THRESHOLD

func can_upgrade_tier(current_tier: int, population: int, materials: Dictionary) -> Dictionary:
    if current_tier >= TIER_DATA.size() - 1:
        return {"allowed": false, "reason": "Maximum tier reached"}
    var next: Dictionary = TIER_DATA[current_tier + 1]
    if population < next["min_population"]:
        return {"allowed": false, "reason": "Need %d residents" % next["min_population"]}
    # TODO: check material requirements
    return {"allowed": true, "reason": ""}
```

### 4.3 Blueprint Placer (`scripts/systems/building/blueprint_placer.gd`)

```gdscript
class_name BlueprintPlacer
extends Node3D

var active_blueprint: String = ""
var ghost_mesh: MeshInstance3D = null
var can_place: bool = false
var placement_position: Vector3 = Vector3.ZERO
var placement_rotation: float = 0.0

const ROTATION_STEP: float = 15.0  # degrees per scroll

signal blueprint_placed(structure_type: String, position: Vector3, rotation: float)
signal blueprint_cancelled()

func start_placement(structure_type: String) -> void:
    active_blueprint = structure_type
    var struct_def: Dictionary = StructureDatabase.get_structure(structure_type)
    # Create ghost mesh
    ghost_mesh = MeshInstance3D.new()
    # TODO: load actual structure mesh as ghost
    var box := BoxMesh.new()
    box.size = Vector3(struct_def["size_x"], struct_def["size_y"], struct_def["size_z"])
    ghost_mesh.mesh = box
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.2, 0.8, 0.2, 0.5)
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    ghost_mesh.material_override = mat
    add_child(ghost_mesh)

func _process(delta: float) -> void:
    if active_blueprint == "" or not ghost_mesh:
        return
    # Update ghost position to mouse ground position
    var camera: PlayerCamera = GameManager.player.camera
    var mouse_pos: Vector2 = get_viewport().get_mouse_position()
    placement_position = camera.screen_to_ground(mouse_pos)
    ghost_mesh.global_position = placement_position
    ghost_mesh.rotation_degrees.y = placement_rotation
    # Validate placement
    can_place = _validate_placement(placement_position)
    var mat: StandardMaterial3D = ghost_mesh.material_override
    mat.albedo_color = Color(0.2, 0.8, 0.2, 0.5) if can_place else Color(0.8, 0.2, 0.2, 0.5)

func _unhandled_input(event: InputEvent) -> void:
    if active_blueprint == "":
        return
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT and can_place:
            blueprint_placed.emit(active_blueprint, placement_position, placement_rotation)
            cancel_placement()
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            cancel_placement()
        elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
            placement_rotation += ROTATION_STEP
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            placement_rotation -= ROTATION_STEP

func cancel_placement() -> void:
    if ghost_mesh:
        ghost_mesh.queue_free()
        ghost_mesh = null
    active_blueprint = ""
    blueprint_cancelled.emit()

func _validate_placement(pos: Vector3) -> bool:
    # Check: within own claim radius, not overlapping existing structures,
    # not inside another player's claim, structural integrity
    # TODO: implement all checks
    return true
```

### 4.4 Test Criteria for Step 4
- [ ] Hearthstone placement creates claim radius (visible boundary)
- [ ] Cannot place structures outside own claim
- [ ] Blueprint ghost preview follows mouse with green/red validity indicator
- [ ] Scroll wheel rotates blueprint
- [ ] Deliver resources to blueprint to complete construction
- [ ] Structural integrity: second floor needs walls below
- [ ] Multi-story up to 3 floors
- [ ] Furniture freely placeable inside rooms
- [ ] Lockable doors/chests with permission system
- [ ] Building decay over time, repair with materials
- [ ] Settlement tier upgrade when requirements met
- [ ] Cannot place hearthstone within 50m of another
- [ ] New accounts: 2hr playtime before hearthstone

---

## STEP 5: Farming & Animals (Week 13-15)

### 5.1 Key Files
- `scripts/systems/farming/farming_system.gd` — Crop growth, watering, harvest
- `scripts/systems/farming/crop_database.gd` — Crop definitions
- `scripts/systems/farming/soil_system.gd` — Fertility, rotation
- `scenes/entities/farm_plot.tscn` / `.gd` — Individual farm plot
- `scenes/entities/animal.tscn` / `.gd` — Animal entity (chicken, cow)

### 5.2 Test Criteria for Step 5
- [ ] Farm plots plantable with seeds from inventory
- [ ] Crops grow in real-time (visible growth stages)
- [ ] Watering: manual bucket, irrigation channel, rain
- [ ] Soil fertility depletes, rotation/manure restores
- [ ] Harvest yields crops based on Farming skill
- [ ] Food spoilage timer works
- [ ] Cooking at campfire/cooking station produces buff foods
- [ ] Chickens: capture, pen, feed, collect eggs
- [ ] Cows: capture, pen, feed, collect milk, slaughter for meat/leather
- [ ] Animals die if starved
- [ ] Season affects crop yield (summer 120%, winter 0%)

---

## STEP 6: Skill System (Week 16-17)

### 6.1 Key Files
- `scripts/systems/skills/skill_system.gd` — XP tracking, leveling, cap enforcement
- `scripts/systems/skills/skill_database.gd` — XP curves, milestone definitions
- `scripts/data/skill_defs.gd` — All 22 skill definitions

### 6.2 XP Curve (`scripts/data/skill_defs.gd`)

```gdscript
class_name SkillDefs
extends RefCounted

# RuneScape-style exponential XP curve
# Level N requires: floor(N^2 * 100 + N * 50)  cumulative XP
# Level 100 total: ~1,005,000 XP
# Level 90 total: ~815,000 XP  (so 90-100 = ~190k, while 1-90 = ~815k)

const TOTAL_SKILL_CAP: int = 500
const MAX_SKILL_LEVEL: int = 100
const RESPEC_COOLDOWN_DAYS: int = 7

static func xp_for_level(level: int) -> int:
    var total: int = 0
    for i in range(1, level + 1):
        total += int(i * i * 100 + i * 50)
    return total

static func level_from_xp(xp: int) -> int:
    var level: int = 1
    var total: int = 0
    while level < MAX_SKILL_LEVEL:
        total += int((level + 1) * (level + 1) * 100 + (level + 1) * 50)
        if total > xp:
            break
        level += 1
    return level

const SKILLS: Dictionary = {
    "mining": {"category": "gathering", "display_name": "Mining"},
    "woodcutting": {"category": "gathering", "display_name": "Woodcutting"},
    "farming": {"category": "gathering", "display_name": "Farming"},
    "fishing": {"category": "gathering", "display_name": "Fishing"},
    "herbalism": {"category": "gathering", "display_name": "Herbalism"},
    "quarrying": {"category": "gathering", "display_name": "Quarrying"},
    "smithing": {"category": "crafting", "display_name": "Smithing"},
    "carpentry": {"category": "crafting", "display_name": "Carpentry"},
    "masonry": {"category": "crafting", "display_name": "Masonry"},
    "leatherworking": {"category": "crafting", "display_name": "Leatherworking"},
    "cooking": {"category": "crafting", "display_name": "Cooking"},
    "tailoring": {"category": "crafting", "display_name": "Tailoring"},
    "alchemy": {"category": "crafting", "display_name": "Alchemy/Medicine"},
    "fletching": {"category": "crafting", "display_name": "Fletching"},
    "melee_weapons": {"category": "combat", "display_name": "Melee Weapons"},
    "ranged_weapons": {"category": "combat", "display_name": "Ranged Weapons"},
    "defense": {"category": "combat", "display_name": "Defense/Armor"},
    "tactics": {"category": "combat", "display_name": "Tactics"},
    "animal_husbandry": {"category": "labor", "display_name": "Animal Husbandry"},
    "sailing": {"category": "labor", "display_name": "Sailing/Navigation"},
    "construction": {"category": "labor", "display_name": "Construction"},
    "trading": {"category": "labor", "display_name": "Trading"},
}
```

### 6.3 Test Criteria for Step 6
- [ ] All 22 skills tracked with XP
- [ ] Exponential XP curve: early levels fast, 90-100 takes as long as 1-90
- [ ] 500 total point cap enforced (XP stops if cap reached)
- [ ] Milestone unlocks at 25/50/75/100 per skill
- [ ] Skill effects work: mining speed, crafting quality chance, combat damage
- [ ] Death XP penalty applied to highest skill
- [ ] Respec option: heavy SOL cost + 7-day cooldown
- [ ] Skill UI panel shows all skills, XP bars, milestones

---

## STEP 7: Multiplayer & Rust Server (Week 18-24)

### 7.1 Rust Server Project Structure
```
sovereign-server/
├── Cargo.toml
├── src/
│   ├── main.rs
│   ├── config.rs              # Hot-reloadable TOML config
│   ├── server.rs              # Main game loop, tick rate
│   ├── network/
│   │   ├── mod.rs
│   │   ├── enet_server.rs     # ENet UDP server
│   │   ├── messages.rs        # Message types (client→server, server→client)
│   │   ├── serialization.rs   # Binary serialization
│   │   └── auth.rs            # JWT auth, wallet verification
│   ├── world/
│   │   ├── mod.rs
│   │   ├── zone.rs            # Zone management
│   │   ├── entity.rs          # Entity component system
│   │   ├── physics.rs         # Movement, collision
│   │   └── time.rs            # Day/night, seasons, weather
│   ├── systems/
│   │   ├── mod.rs
│   │   ├── combat.rs          # Server-authoritative combat
│   │   ├── inventory.rs       # Server-authoritative inventory
│   │   ├── crafting.rs        # Crafting validation
│   │   ├── building.rs        # Building placement, decay
│   │   ├── farming.rs         # Crop growth, animal simulation
│   │   ├── skills.rs          # XP tracking, level-ups
│   │   ├── economy.rs         # Trade, marketplace, SOL ledger
│   │   ├── kingdom.rs         # Kingdom management, war
│   │   └── karma.rs           # Karma tracking
│   ├── validation/
│   │   ├── mod.rs
│   │   ├── movement.rs        # Anti-cheat movement validation
│   │   ├── combat_val.rs      # Combat anti-cheat
│   │   └── economy_val.rs     # Economic anti-cheat, rate limiting
│   ├── database/
│   │   ├── mod.rs
│   │   ├── postgres.rs        # PostgreSQL connection pool
│   │   ├── queries.rs         # SQL queries
│   │   └── migrations.rs      # Schema migrations
│   ├── admin/
│   │   ├── mod.rs
│   │   ├── commands.rs        # Admin console commands
│   │   └── web_dashboard.rs   # Basic HTTP dashboard
│   └── telemetry/
│       ├── mod.rs
│       └── metrics.rs         # Combat/economy/skill telemetry
├── config/
│   ├── balance.toml           # All balance values (hot-reloadable)
│   ├── server.toml            # Server configuration
│   └── items.toml             # Item/recipe definitions
├── migrations/
│   └── 001_initial.sql        # Database schema
├── tests/
│   ├── combat_test.rs
│   ├── inventory_test.rs
│   ├── economy_test.rs
│   └── load_test.rs
├── Dockerfile
└── docker-compose.yml         # Server + PostgreSQL + Redis
```

### 7.2 Key Rust Structs

```rust
// src/network/messages.rs

#[derive(Serialize, Deserialize)]
pub enum ClientMessage {
    ClickMove { tick_id: u32, target: Vec3 },
    AttackTarget { tick_id: u32, target_id: u64, tier: AttackTier, direction: u8 },
    BlockStart { tick_id: u32, direction: u8 },
    BlockEnd { tick_id: u32 },
    Dodge { tick_id: u32, direction: Vec2 },
    Kick { tick_id: u32 },
    Interact { target_id: u64, action: String },
    BuildPlace { structure_type: String, position: Vec3, rotation: f32 },
    BuildContribute { structure_id: u64, item_ids: Vec<u64> },
    TradeOffer { target_player: u64, offered_items: Vec<u64>, requested_lamports: i64 },
    MarketplaceList { item_id: u64, price_lamports: i64, quantity: i32 },
    MarketplaceBuy { listing_id: u64, quantity: i32 },
    Chat { channel: ChatChannel, message: String },
    Craft { recipe_id: String, station_id: u64 },
    Equip { item_id: u64, slot: EquipSlot },
    UseItem { item_id: u64, target: Option<u64> },
    Gather { node_id: u64 },
    Revive { target_id: u64 },
    Execute { target_id: u64 },
    ZoneTravel { target_zone: i32 },
}

#[derive(Serialize, Deserialize)]
pub enum ServerMessage {
    WorldState { tick_id: u32, entities: Vec<EntityState> },
    DamageEvent { attacker: u64, target: u64, damage: i32, zone: HitZone, injury: InjuryType, is_kill: bool },
    EntitySpawn { entity_id: u64, entity_type: EntityType, position: Vec3, state: EntityInitState },
    EntityDespawn { entity_id: u64, reason: DespawnReason },
    InventoryUpdate { items: Vec<ItemState> },
    BalanceUpdate { lamports: i64 },
    BuildUpdate { structure_id: u64, progress: f32, health: i32 },
    TradeRequest { from_player: u64, offered: Vec<u64>, requested_lamports: i64 },
    RespawnOptions { options: Vec<RespawnOption> },
    SkillUpdate { skill: String, level: i32, xp: i64 },
    WeatherUpdate { weather: WeatherType, intensity: f32 },
    InjuryUpdate { zone: HitZone, injury: InjuryType, severity: f32 },
    AuthResult { success: bool, token: String, character: Option<CharacterData> },
    ChatMessage { channel: ChatChannel, sender: String, message: String },
    ChronicleEvent { description: String },
    ZoneTravelReady { zone_id: i32, spawn_pos: Vec3 },
    AdminResponse { message: String },
}
```

### 7.3 Docker Compose (`docker-compose.yml`)

```yaml
version: '3.8'
services:
  sovereign-server:
    build: .
    ports:
      - "7777:7777/udp"   # ENet game port
      - "7778:7778/tcp"   # WebSocket fallback
      - "8080:8080/tcp"   # Admin dashboard
    environment:
      - DATABASE_URL=postgres://sovereign:password@db:5432/sovereign
      - REDIS_URL=redis://redis:6379
      - RUST_LOG=info
    depends_on:
      - db
      - redis
    volumes:
      - ./config:/app/config

  db:
    image: postgis/postgis:16-3.4
    environment:
      POSTGRES_DB: sovereign
      POSTGRES_USER: sovereign
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml

  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"

volumes:
  pgdata:
```

### 7.4 Godot Network Manager Updates (`scripts/autoload/network_manager.gd`)

```gdscript
extends Node

var peer: ENetMultiplayerPeer = null
var jwt_token: String = ""
var is_connected: bool = false
var server_tick: int = 0

const SERVER_HOST: String = "127.0.0.1"  # MVP: localhost
const SERVER_PORT: int = 7777

signal connected_to_server()
signal disconnected_from_server()
signal auth_result(success: bool, character_data: Dictionary)

func connect_to_server() -> void:
    peer = ENetMultiplayerPeer.new()
    var err: int = peer.create_client(SERVER_HOST, SERVER_PORT)
    if err != OK:
        push_error("Failed to connect: %d" % err)
        return
    multiplayer.multiplayer_peer = peer
    multiplayer.connected_to_server.connect(_on_connected)
    multiplayer.server_disconnected.connect(_on_disconnected)

func _on_connected() -> void:
    is_connected = true
    connected_to_server.emit()

func _on_disconnected() -> void:
    is_connected = false
    disconnected_from_server.emit()

func send_reliable(message: Dictionary) -> void:
    if not is_connected:
        return
    var data: PackedByteArray = var_to_bytes(message)
    # TODO: proper binary serialization matching Rust server
    peer.get_peer(1).send(0, data, ENetPacketPeer.FLAG_RELIABLE)

func send_unreliable(message: Dictionary) -> void:
    if not is_connected:
        return
    var data: PackedByteArray = var_to_bytes(message)
    peer.get_peer(1).send(1, data, 0)

func send_move(target_pos: Vector3) -> void:
    send_unreliable({"type": "CLICK_MOVE", "tick": server_tick, "pos": [target_pos.x, target_pos.y, target_pos.z]})

func send_attack(target_id: int, tier: int, direction: int) -> void:
    send_reliable({"type": "ATTACK_TARGET", "tick": server_tick, "target": target_id, "tier": tier, "dir": direction})

func send_chat(channel: String, message: String) -> void:
    send_reliable({"type": "CHAT", "channel": channel, "msg": message})

func authenticate_email(email: String, password: String) -> void:
    send_reliable({"type": "AUTH_EMAIL", "email": email, "password": password})

func authenticate_wallet(wallet_address: String, signature: String, message: String) -> void:
    send_reliable({"type": "AUTH_WALLET", "wallet": wallet_address, "sig": signature, "msg": message})
```

### 7.5 Test Criteria for Step 7
- [ ] Rust server compiles and runs in Docker
- [ ] PostgreSQL schema deployed with all tables
- [ ] ENet networking: Godot client connects to Rust server
- [ ] Account creation works (email/password)
- [ ] JWT auth flow works
- [ ] Server-authoritative movement with client prediction
- [ ] Entity interpolation for other players (100ms buffer)
- [ ] 10+ players visible on screen, moving independently
- [ ] Combat works in multiplayer (both players see hits, damage, deaths)
- [ ] Inventory sync: server validates all item changes
- [ ] Building sync: both players see structures placed/built
- [ ] Chat system: local, kingdom, trade, party channels
- [ ] Anti-cheat: speed hack detection, teleport rejection
- [ ] Admin commands work (/kick, /ban, /tp, /spawn, /inspect)
- [ ] Web dashboard shows player count and basic metrics
- [ ] Server maintains 20Hz tick rate with 10+ players

---

## STEP 8: Economy & Solana (Week 25-28)

### 8.1 Key Files
- `sovereign-server/src/systems/economy.rs` — Trade, marketplace, fee calculation
- `sovereign-server/src/solana/` — New directory for blockchain integration
  - `anchor_program/` — Anchor escrow smart contract
  - `wallet_bridge.rs` — Deposit/withdrawal processing
  - `merkle.rs` — Daily balance Merkle root

### 8.2 Test Criteria for Step 8
- [ ] Solana devnet: Anchor escrow program deployed
- [ ] Phantom/Solflare wallet connect in game client
- [ ] Deposit flow: wallet → escrow PDA → in-game balance
- [ ] Withdrawal flow: in-game → escrow → wallet (1% fee)
- [ ] Face-to-face trade UI: both players offer items/SOL, confirm
- [ ] Marketplace: list item, browse listings, buy (3% fee)
- [ ] NPC shopkeeper sells goods when owner offline
- [ ] Trading skill reduces marketplace fee
- [ ] Lamport rounding: always floor (deflationary)
- [ ] Rate limiting: max 10 listings/min, 5 trades/min, 1 withdrawal/hr
- [ ] sol_ledger tracks all SOL movements

---

## STEP 9: Kingdoms, Governance, War (Week 29-32)

### 9.1 Key Files
- `sovereign-server/src/systems/kingdom.rs` — Kingdom CRUD, roles, taxes
- `sovereign-server/src/systems/war.rs` — War declaration, 24hr timer, building damage

### 9.2 Test Criteria for Step 9
- [ ] Kingdom creation at Town-tier with Throne placement
- [ ] Role assignment: sovereign, marshal, chancellor, treasurer, steward
- [ ] Tax rate setting (0-20%) applied to marketplace trades in territory
- [ ] War declaration with 24-hour countdown
- [ ] After 24 hours, enemy buildings become damageable
- [ ] Battering ram damages walls during active war
- [ ] Forced annexation: 48-hour warning, owner can demolish and relocate
- [ ] Solo homesteads above 20 structures become raidable
- [ ] Karma system: murders reduce karma, red name visible from far
- [ ] Karma recovery through trading, building, healing
- [ ] Bounty board: post and claim bounties
- [ ] Mercenary contracts: SOL terms enforced by server
- [ ] Peace negotiation: both sides agree, winner sets terms
- [ ] Server chronicle records kingdom events
- [ ] Marshal inherits after 30 days sovereign inactivity

---

## STEP 10: Polish & Alpha Launch (Week 33-35)

### 10.1 Key Tasks
- [ ] Weather system: rain (reduces visibility, waters crops) and clear
- [ ] Alchemy/medicine: bandages, tonics, poisons, antidotes
- [ ] Fishing system with variable difficulty
- [ ] Writable books, placeable signs
- [ ] Tabards/cloaks/heraldry cosmetics
- [ ] Tutorial area for new players
- [ ] Friends list and party system
- [ ] Day/night cycle with torch visibility mechanics
- [ ] Season cycle (summer/winter, 1 week each)
- [ ] Respawn invulnerability (5 sec, can move, can't attack)
- [ ] Soft collision inside claimed territory (push through at 25% speed)
- [ ] New player "New" tag, 3x karma penalty for killing
- [ ] Balance: all values in hot-reloadable TOML config
- [ ] Telemetry: combat events, economy events, skill tracking
- [ ] Grafana dashboards for balance monitoring
- [ ] Stress test: 100 concurrent players
- [ ] Custom Tauri launcher with wallet connect + auto-updater
- [ ] Switch Solana from devnet to mainnet
- [ ] **Launch closed alpha with real SOL**

---

# PART 20: QUICK REFERENCE — ALL DECISIONS

For fast lookup:

- **Client:** Godot 4, GDScript only
- **Server:** Rust, single server, 20Hz tick
- **Perspective:** 2.5D isometric, fixed angle, zoomable, click-to-move
- **World:** Static terrain (no terraforming), free-placement, 3x3 zones, no safe zones
- **Zone transitions:** Foxhole-style (press E, 2-3 sec load)
- **Day/Night:** 2hr real = 1 game day, torches required at night
- **Seasons (MVP):** Summer + winter only, 1 real week each
- **Weather (MVP):** Rain and clear only
- **Combat:** Weighty, 3-tier attacks, 8-direction (screen-space), block only (no parry), friendly fire always on
- **Hit Zones:** 6 (head, torso, L arm, R arm, L leg, R leg) with injuries
- **Death:** Full loot, killer loots first 2min, corpse 10min, XP loss in highest skill
- **Respawn:** 5sec invulnerability, randomized within 10m, context-dependent timer
- **Logout:** Body stays 15min
- **Skills:** 22 skills, level 1-100, 500 total cap, exponential XP, respec with SOL cost + 7-day cooldown
- **Economy:** SOL only, zero-sum, local markets, 3% fee, lamports round down
- **Kingdom treasury:** Deferred (no shared SOL pool for MVP)
- **Farming:** Variable growth, watering, soil depletion, food spoilage, buffs
- **Animals (MVP):** Chickens + cows only, no genetics, simple capture/feed/collect
- **Crafting:** 2 quality tiers, failure chance, named items, repair degrades max durability
- **Building:** Blueprint, 5-tier settlements, structural integrity, multi-story, decay
- **Solo immunity:** Raidable above 20 structures
- **Annexation:** 48-hour warning + pack-up option
- **Transport (MVP):** Hand cart, horse cart, pack mule, rowboat. No naval combat.
- **Siege (MVP):** Battering ram only. 24hr war warning.
- **Horses:** Speed mount only, no mounted combat, purchased from NPC stable
- **Karma:** Red name visible far, social penalty, recovery through good deeds
- **Chat:** Text only (local, kingdom, trade, party). No voice.
- **Anti-cheat:** Server-side validation (movement, combat, economy)
- **Auth:** Email/password + wallet connect, JWT sessions
- **Admin:** In-game console + web dashboard
- **Grief prevention:** Spawn invulnerability, soft collision in claims, claim limits, new player protection
- **Balance:** Hot-reloadable TOML config, telemetry dashboards, weekly reviews
- **Performance:** 60 FPS target, 200 entity cap, 100m culling, 30 KB/s per player
- **Assets:** KayKit primary, low-poly, 1 unit = 1 meter
- **CI/CD:** GitHub Actions, Docker, Ansible
- **Deferred:** Terraforming, voice chat, naval combat, underworld, alcohol addiction, kingdom treasury, parry/riposte
- **Timeline:** 30-35 weeks to alpha

---

END OF PROMPT. This is the single source of truth for Sovereign. Build it step by step. Each step's test criteria must pass before moving to the next.