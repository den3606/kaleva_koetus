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

-- Export both EventTypes and EventArgs
return {
  Types = EventTypes,
  Args = EventArgs,
}