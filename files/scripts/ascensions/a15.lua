-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/difficulty_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")
local ImageEditor = dofile_once("mods/kaleva_koetus/files/scripts/image_editor.lua")
local RandomUtils = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/a15_random_utils.lua")

local AscensionTags = EventDefs.AscensionTags
local EventTypes = EventDefs.Types
-- local log = Logger:new("a15.lua")

local ascension = setmetatable({}, { __index = AscensionBase })
local UNCOMPLETED_MULTIPLIER = RandomUtils.UNCOMPLETED_MULTIPLIER

ascension.level = 15
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level
ascension.tag_name = AscensionTags.A15 .. EventTypes.SPELL_GENERATED

function ascension:on_activate()
  -- log:info("Broken spells")
end

function ascension:on_mod_post_init()
  RandomUtils.init_root_seed()
  local actions_seed = RandomUtils.derive_seed("gun_actions")
  math.randomseed(actions_seed)

  local _ = dofile_once("data/scripts/gun/gun_actions.lua")
  -- selene: allow(undefined_variable)
  local actions = actions

  local target_indexes = RandomUtils.random_unique_integers(1, #actions, math.floor(#actions * UNCOMPLETED_MULTIPLIER))
  for _, index in ipairs(target_indexes) do
    if actions[index].id ~= "MANA_REDUCE" then
      local id, x, y = ModImageMakeEditable(actions[index].sprite, 0, 0)

      for i = 0, x, 1 do
        for j = 0, y, 1 do
          local color = ModImageGetPixel(id, i, j)
          local inverted = ImageEditor:invert_hue_abgr(color)
          ModImageSetPixel(id, i, j, inverted)
        end
      end
    end
  end

  ModLuaFileAppend("data/scripts/gun/gun_actions.lua", "mods/kaleva_koetus/files/scripts/appends/gun_actions.lua")
end

local function rename_spell(spell_entity_id)
  local _ = dofile_once("data/scripts/gun/gun_actions.lua")
  -- selene: allow(undefined_variable)
  local actions = actions
  local item_action_component_id = EntityGetFirstComponentIncludingDisabled(spell_entity_id, "ItemActionComponent")
  local action_id = ComponentGetValue2(item_action_component_id, "action_id")

  local ability_component_id = EntityGetFirstComponentIncludingDisabled(spell_entity_id, "AbilityComponent")

  if ability_component_id and action_id then
    for _, action in ipairs(actions) do
      if action.id == action_id then
        local action_name = GameTextGetTranslatedOrNot("$kaleva_koetus_broken_spell") .. GameTextGetTranslatedOrNot(action.name)
        ComponentSetValue2(ability_component_id, "ui_name", action_name)
      end
    end
  end
end

function ascension:on_spell_generated(payload)
  local spell_entity_id = tonumber(payload[1])

  if not spell_entity_id or spell_entity_id == 0 or EntityHasTag(spell_entity_id, ascension.tag_name) then
    return
  end

  rename_spell(spell_entity_id)
end

return ascension
