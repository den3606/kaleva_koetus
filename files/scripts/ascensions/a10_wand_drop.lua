local DepthProfile = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/a10_depth_profile.lua")
local DurabilityCalculator = dofile_once("mods/kaleva_koetus/files/scripts/calc_wand_durability.lua")

local DROP_BASE_CHANCE = 0.05
local DROP_STAGE_BONUS = 0.03
local DROP_MAX_CHANCE = 0.4
local DROP_SPREAD = 12

local WAND_ENTITIES = {
  "data/entities/items/wand_level_01.xml",
  "data/entities/items/wand_level_02.xml",
  "data/entities/items/wand_level_03.xml",
  "data/entities/items/wand_level_04.xml",
  "data/entities/items/wand_level_05.xml",
  "data/entities/items/wand_level_06.xml",
  "data/entities/items/wand_level_07.xml",
  "data/entities/items/wand_level_08.xml",
}

local function compute_drop_chance(stage)
  local chance = DROP_BASE_CHANCE + (stage * DROP_STAGE_BONUS)
  if chance > DROP_MAX_CHANCE then
    chance = DROP_MAX_CHANCE
  end
  if chance < 0 then
    chance = 0
  end
  return chance
end

local function pick_wand_entity(stage)
  local index = stage + 1
  if index > #WAND_ENTITIES then
    index = #WAND_ENTITIES
  elseif index < 1 then
    index = 1
  end
  return WAND_ENTITIES[index]
end

local function spawn_wand(x, y, stage)
  local wand_path = pick_wand_entity(stage)
  if not wand_path then
    return
  end

  local drop_x = x + ProceduralRandomf(x + stage * 173, y + stage * 97, -DROP_SPREAD, DROP_SPREAD)
  local drop_y = y - 4

  local wand_entity = EntityLoad(wand_path, drop_x, drop_y)
  if not wand_entity then
    return
  end

  EntityAddTag(wand_entity, "kaleva_a10_drop")

  local ability_component = EntityGetFirstComponentIncludingDisabled(wand_entity, "AbilityComponent")
  if ability_component then
    DurabilityCalculator.assign(wand_entity, ability_component)
  end
end

function death()
  local enemy_entity = GetUpdatedEntityID()
  if not enemy_entity then
    return
  end

  local x, y = EntityGetTransform(enemy_entity)
  if not x or not y then
    return
  end

  local stage = DepthProfile.compute_stage(y)
  local chance = compute_drop_chance(stage)
  if chance <= 0 then
    return
  end

  local roll = ProceduralRandomf(enemy_entity, GameGetFrameNum(), 0.0, 1.0)
  if roll > chance then
    return
  end

  spawn_wand(x, y, stage)
end
