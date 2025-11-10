-- Event Types Definition
-- Central definition of all event types used in the mod

local EventTypes = {
  -- Currently implemented events
  ENEMY_SPAWN = "enemy_spawn", -- enemy entity spawned
  ENEMY_POST_SPAWN = "enemy_post_spawn", -- called after the main enemy spawn event
  SHOP_CARD_SPAWN = "shop_card_spawn", -- spell card spawned in temple shop
  SHOP_WAND_SPAWN = "shop_wand_spawn", -- wand spawned in temple shop
  PLAYER_SPAWN = "player_spawn",
  VICTORY = "victory", -- victory condition met (sampo ending)
  NECROMANCER_SPAWN = "necromancer_spawn",
  POTION_GENERATED = "potion_generated",
  BOOK_GENERATED = "book_generated",
  GOLD_SPAWN = "gold_spawn",
  SPELL_GENERATED = "spell_generated",
  BOSS_DIED = "boss_died",
  NEW_GAME_PLUS_STARTED = "new_game_plus_started",
}

-- Event argument definitions (for handlers)
-- Note: source and event_type are handled by EventBroker
local EventArgs = {
  [EventTypes.ENEMY_SPAWN] = {
    { name = "entity_id", type = "number" },
    { name = "x", type = "number" },
    { name = "y", type = "number" },
    { name = "mark_as_processed", type = "function" },
  },
  [EventTypes.ENEMY_POST_SPAWN] = {
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
  },
  [EventTypes.VICTORY] = {},
  [EventTypes.POTION_GENERATED] = {
    { name = "entity_id", type = "number" },
  },
  [EventTypes.GOLD_SPAWN] = {
    { name = "entity_id", type = "number" },
  },
  [EventTypes.SPELL_GENERATED] = {
    { name = "entity_id", type = "number" },
  },
  [EventTypes.BOSS_DIED] = {},
  [EventTypes.NEW_GAME_PLUS_STARTED] = {},
}

local AscensionTags = {
  -- Prefixes for each ascension level
  A1 = "kk_a1_",
  A2 = "kk_a2_",
  A3 = "kk_a3_",
  A4 = "kk_a4_",
  A5 = "kk_a5_",
  A6 = "kk_a6_",
  A7 = "kk_a7_",
  A8 = "kk_a8_",
  A9 = "kk_a9_",
  A10 = "kk_a10_",
  A11 = "kk_a11_",
  A12 = "kk_a12_",
  A13 = "kk_a13_",
  A14 = "kk_a14_",
  A15 = "kk_a15_",
  A16 = "kk_a16_",
  A17 = "kk_a17_",
  A18 = "kk_a18_",
  A19 = "kk_a19_",
  A20 = "kk_a20_",
}

-- Export EventTypes, EventArgs, and AscensionTags
return {
  Types = EventTypes,
  Args = EventArgs,
  Tags = AscensionTags,
}
