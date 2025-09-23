-- Ascension Level Template
-- Each ascension level should implement these functions

local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")

local ascension = setmetatable({}, { __index = AscensionBase })

-- Metadata
ascension.level = 7 -- Change this to the actual ascension level (1-20)
ascension.name = "Ascension 7" -- Display name
ascension.description = "Description of what this ascension level does"

-- Called when this ascension level is activated
function ascension:on_activate()
  print("A7 activated")
  -- Implement ascension-specific modifications here
  -- Examples:
  -- - Modify enemy stats
  -- - Change drop rates
  -- - Add new mechanics
  -- - Alter world generation
end

-- Called every frame while this ascension is active (optional)
function ascension:on_update()
  -- Implement per-frame updates if needed
end

-- Called when player spawns with this ascension active
function ascension:on_player_spawn()
  -- Implement player-specific modifications
  -- Examples:
  -- - Modify starting HP
  -- - Change starting perks
  -- - Adjust player stats
end

-- Called when an enemy spawns (optional)
function ascension:on_enemy_spawn()
  -- Implement enemy spawn modifications
end

-- Called to check if the next ascension level should be unlocked
function ascension:should_unlock_next()
  -- Return true if player has met conditions to unlock next level
  return false
end

-- Get difficulty multipliers (optional)
function ascension:get_modifiers()
  return {
    enemy_hp_mult = 1.0,
    enemy_damage_mult = 1.0,
    shop_price_mult = 1.0,
    healing_mult = 1.0,
    -- Add more multipliers as needed
  }
end

return ascension
