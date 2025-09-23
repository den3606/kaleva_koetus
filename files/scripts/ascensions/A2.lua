local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")

local ascension = setmetatable({}, { __index = AscensionBase })

ascension.level = 2
ascension.name = "Ascension 2"
ascension.description = "Description of what this ascension level does"

function ascension:on_activate()
  print("A2 activated")
end

function ascension:on_update() end

function ascension:on_player_spawn() end

function ascension:on_enemy_spawn() end

function ascension:should_unlock_next()
  return false
end

function ascension:get_modifiers() end

return ascension
