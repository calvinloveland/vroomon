# Core Game Loop:

- Capture Vroomon
- Selectively breed Vroomon
- Race Vroomon

## Capture Vroomon

- Win races? (Racing for pinks!)
- Select best looking one in a race before running the race?
- Start with two have to breed the rest?

## Selective Breeding

- Gacha like?
  - Good Vroomon more likely to make better vroomon
- Breed with wild Vroomon?
- Limit on how many time a Vroomon can reproduce?
- Reproduction modifiers (more variation / less / size)
- Must complete a race to mature?
- Old Vroomon can race but not reproduce

## Racing

- Win races for money!
- Win races to move to new areas

## Areas

- Different types of terrain/surfaces to encourage diversity
- Blending between areas so Vroomon can evolve and expand
- Some children race in adjacent areas
- Evolution happens in the background? (Maybe most evolution is pre-baked per area?)

## Overworld

- exists

## Post game

- Infinite procedurally generated races

---

## Iterative Development Plan

1. Areas + Economy (MVP)

- Add area configs (friction, obstacle profile) consumed by `scripts/CarSimulation.gd`
- Expose `set_area_config(config: Dictionary)` to reconfigure terrain at runtime
- Define a few presets (Grassland, Sand, Hills)
- Introduce simple economy: award money per generation (e.g., best score scaled)
- Fix resource paths to use `res://scenes/` and `res://scripts/`

1. Breeding UI + Limits

- Breeding scene to select parents, show DNA, and adjust mutation sliders (bounded)
- Add reproduction_count/aging to `Car`; elders race-only
- Store/serialize garage and wallet

1. Capture System

- Wild subpopulations per area; stake-based "pinks" races to capture
- Storage limits; release/sell mechanics

1. Overworld

- Area map with unlocks and costs; `GameManager` routes to area runs
- Background evolution ticks for off-screen areas (fast sim)

1. Background Evolution & Live Events

- Periodic meta shifts in terrain seeds; daily/weekly seeds leaderboards

### Step 1 Acceptance Criteria

- Can switch area presets (code-driven) and see terrain/friction differences
- Economy counter updates after each generation
- No car-to-car collisions; consistent scoring; no resource path errors

