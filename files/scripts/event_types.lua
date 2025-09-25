-- Event Types Definition
-- Central definition of all event types used in the mod

local EventTypes = {
  -- Currently implemented events
  ENEMY_SPAWN = "enemy_spawn", -- enemy entity spawned
  SHOP_CARD_SPAWN = "shop_card_spawn", -- spell card spawned in temple shop
  SHOP_WAND_SPAWN = "shop_wand_spawn", -- wand spawned in temple shop
  VICTORY = "victory", -- victory condition met (sampo ending)
  NECROMANCER_SPAWN = "necromancer_spawn",
  POTION_GENERATED = "potion_generated",
}

-- Event argument definitions (for handlers)
-- Note: source and event_type are handled by EventBroker
local EventArgs = {
  [EventTypes.ENEMY_SPAWN] = {
    { name = "entity_id", type = "number" },
    { name = "x", type = "number" },
    { name = "y", type = "number" },
  },
  [EventTypes.SHOP_CARD_SPAWN] = {
    { name = "entity_ids", type = "table" },
    { name = "x", type = "number" },
    { name = "y", type = "number" },
  },
  [EventTypes.SHOP_WAND_SPAWN] = {
    { name = "entity_ids", type = "table" },
    { name = "x", type = "number" },
    { name = "y", type = "number" },
  },
  [EventTypes.NECROMANCER_SPAWN] = {
    { name = "x", type = "number" },
    { name = "y", type = "number" },
  }, -- No arguments needed for victory events
  [EventTypes.VICTORY] = {}, -- No arguments needed for victory events
  [EventTypes.POTION_GENERATED] = {
    { name = "entity_id", type = "number" },
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
