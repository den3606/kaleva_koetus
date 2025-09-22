-- Event Types Definition
-- Central definition of all event types used in the mod

local EventTypes = {
  -- Currently implemented events
  ENEMY_SPAWN = "enemy_spawn",           -- enemy entity spawned
  PLAYER_SPAWN = "player_spawn",         -- player entity spawned
  ITEM_PICKUP = "item_pickup",           -- item picked up (placeholder)
}

-- Event argument definitions (for handlers)
-- Note: source and event_type are handled by EventObserver, not passed to handlers
local EventArgs = {
  [EventTypes.ENEMY_SPAWN] = {
    {name = "entity_id", type = "number"},
    {name = "x", type = "number"},
    {name = "y", type = "number"},
  },
  [EventTypes.PLAYER_SPAWN] = {
    {name = "entity_id", type = "number"},
  },
  [EventTypes.ITEM_PICKUP] = {
    {name = "item_entity_id", type = "number"},
    {name = "picker_entity_id", type = "number"},
  },
}

local AscensionTags = {
  -- Prefixes for each ascension level
  A1 = "kaleva_a1_",
  A2 = "kaleva_a2_",
  A3 = "kaleva_a3_",
  A4 = "kaleva_a4_",
  A5 = "kaleva_a5_",
  A6 = "kaleva_a6_",
  A7 = "kaleva_a7_",
  A8 = "kaleva_a8_",
  A9 = "kaleva_a9_",
  A10 = "kaleva_a10_",
  A11 = "kaleva_a11_",
  A12 = "kaleva_a12_",
  A13 = "kaleva_a13_",
  A14 = "kaleva_a14_",
  A15 = "kaleva_a15_",
  A16 = "kaleva_a16_",
  A17 = "kaleva_a17_",
  A18 = "kaleva_a18_",
  A19 = "kaleva_a19_",
  A20 = "kaleva_a20_",
}

-- Export EventTypes, EventArgs, and AscensionTags
return {
  Types = EventTypes,
  Args = EventArgs,
  Tags = AscensionTags,
}
