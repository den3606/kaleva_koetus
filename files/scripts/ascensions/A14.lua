-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
-- local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
-- dofile_once("mods/kaleva_koetus/files/scripts/lib/utils/player.lua")

-- local ascension = setmetatable({}, { __index = AscensionBase })

-- local log = Logger:new("A14.lua")

-- local EFFECT_POOL = {
--   { effect = "MOVEMENT_FASTER", label = "加速" },
--   { effect = "MOVEMENT_SLOWER", label = "鈍足" },
--   { effect = "PROTECTION_FIRE", label = "耐火" },
--   { effect = "PROTECTION_ELECTRICITY", label = "絶縁" },
--   { effect = "STAINLESS_ARMOR", label = "ステンレス装甲" },
--   { effect = "BERSERK", label = "狂乱" },
--   { effect = "CHARM", label = "魅了" },
-- }

-- ascension.level = 14
-- ascension.name = "エリア効果矯正付与"
-- ascension.description = "各バイオームに必ず何らかの効果が付与される"
-- ascension.tag_name = "kaleva_a14_effect"

-- ascension._biome_effect_map = {}
-- ascension._current_biome = nil

-- local function clear_effects(player_entity_id)
--   local components = EntityGetComponentIncludingDisabled(player_entity_id, "GameEffectComponent")
--   if not components then
--     return
--   end

--   for _, component_id in ipairs(components) do
--     if ComponentHasTag(component_id, ascension.tag_name) then
--       EntityRemoveComponent(player_entity_id, component_id)
--     end
--   end
-- end

-- local function apply_effect(player_entity_id, biome_name, effect_def)
--   clear_effects(player_entity_id)

--   EntityAddComponent2(player_entity_id, "GameEffectComponent", {
--     effect = effect_def.effect,
--     frames = 0,
--     tags = ascension.tag_name,
--   })

--   GamePrintImportant("Biome Effect: " .. biome_name, string.format("%sの加護/災い", effect_def.label))
--   log:debug("Applied biome effect %s to %s", effect_def.effect, biome_name)
-- end

-- local function pick_effect_for_biome(biome_name)
--   local seed_base = GameGetFrameNum()
--   SetRandomSeed(seed_base + #biome_name, seed_base - #biome_name)
--   local index = Random(1, #EFFECT_POOL)
--   return EFFECT_POOL[index]
-- end

-- function ascension:on_activate()
--   log:info("Biome effects enforced")
-- end

-- function ascension:on_update()
--   local player_entity_id = GetPlayerEntity()
--   if not player_entity_id then
--     return
--   end

--   local x, y = EntityGetTransform(player_entity_id)
--   local biome_name = BiomeMapGetName(x, y) or "unknown"

--   if biome_name == self._current_biome then
--     return
--   end

--   self._current_biome = biome_name
--   if not self._biome_effect_map[biome_name] then
--     self._biome_effect_map[biome_name] = pick_effect_for_biome(biome_name)
--   end

--   apply_effect(player_entity_id, biome_name, self._biome_effect_map[biome_name])
-- end

-- return ascension
