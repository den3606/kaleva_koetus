local _ = dofile_once("mods/kaleva_koetus/files/scripts/lib/utilities.lua")

---@type Beyond
local beyond = dofile("mods/kaleva_koetus/files/scripts/beyonds/base_beyond.lua")
beyond.level = 10
beyond.description = "$kaleva_koetus_description_b" .. beyond.level
beyond.specification = "$kaleva_koetus_specification_b" .. beyond.level

local WAIT_FRAME = 60 * 60 * 5
local EFFECT_FRAME = 60 * 10

---@type fun(player_entity_id:number, pos_x:number, pos_y:number)
local custom_fungal_shift

function beyond:on_world_initialized()
  local _ = dofile_once("data/scripts/magic/fungal_shift.lua")

  local is_valid = true

  -- selene: allow(undefined_variable)
  local materials_from = materials_from
  -- selene: allow(undefined_variable)
  local materials_to = materials_to

  if type(materials_from) ~= "table" or type(materials_to) ~= "table" then
    is_valid = false
  end
  if is_valid == true then
    for _, item in ipairs(materials_from) do
      if type(item.probability) ~= "number" or type(item.materials) ~= "table" then
        is_valid = false
        break
      end
      for _, material in ipairs(item.materials) do
        if type(material) ~= "string" then
          is_valid = false
          break
        end
      end
    end
  end
  if is_valid == true then
    for _, item in ipairs(materials_to) do
      if type(item.probability) ~= "number" or type(item.material) ~= "string" then
        is_valid = false
        break
      end
    end
  end

  if is_valid == true then
    -- selene: allow(undefined_variable)
    local log_messages = log_messages
      or {
        "$log_reality_mutation_00",
        "$log_reality_mutation_01",
        "$log_reality_mutation_02",
        "$log_reality_mutation_03",
        "$log_reality_mutation_04",
        "$log_reality_mutation_05",
      }

    local extend_materials = {}

    local _ = dofile_once("data/scripts/items/potion.lua")
    _ = dofile_once("data/scripts/items/powder_stash.lua")

    -- selene: allow(undefined_variable)
    local materials_standard_potion = materials_standard
    if materials_standard_potion ~= nil then
      for _, item in ipairs(materials_standard_potion) do
        local material = item.material
        if material ~= nil and extend_materials[material] == nil then
          extend_materials[material] = {
            prob_from = 0.25,
            prob_to = 0.5,
          }
        end
      end
    end

    -- selene: allow(undefined_variable)
    local materials_standard_powder_stash = materials_standard
    if materials_standard_powder_stash ~= nil then
      for _, item in ipairs(materials_standard_powder_stash) do
        local material = item.material
        if material ~= nil and extend_materials[material] == nil then
          extend_materials[material] = {
            prob_from = 0.15,
            prob_to = 0.3,
          }
        end
      end
    end

    -- selene: allow(undefined_variable)
    local materials_magic_potion = materials_magic
    if materials_magic_potion ~= nil then
      for _, item in ipairs(materials_magic_potion) do
        local material = item.material
        if material ~= nil and extend_materials[material] == nil then
          extend_materials[material] = {
            prob_from = 0.15,
            prob_to = 0.3,
          }
        end
      end
    end

    -- selene: allow(undefined_variable)
    local materials_magic_powder_stash = materials_magic
    if materials_magic_powder_stash ~= nil then
      for _, item in ipairs(materials_magic_powder_stash) do
        local material = item.material
        if material ~= nil and extend_materials[material] == nil then
          extend_materials[material] = {
            prob_from = 0.1,
            prob_to = 0.2,
          }
        end
      end
    end

    _ = dofile_once("data/scripts/items/potion_secret.lua")
    -- selene: allow(undefined_variable)
    local potions_potion_secret = potions
    if potions_potion_secret ~= nil then
      for _, item in ipairs(potions_potion_secret) do
        local material = item.material
        if material ~= nil and extend_materials[material] == nil then
          extend_materials[material] = {
            prob_from = 0.025,
            prob_to = 0.05,
          }
        end
      end
    end

    extend_materials["magic_liquid_teleportation"] = nil
    extend_materials["gold"] = nil

    custom_fungal_shift = function(player_entity_id, pos_x, pos_y)
      local world_state_entity_id = GameGetWorldStateEntity()
      local world_state_component_id = EntityGetFirstComponent(world_state_entity_id, "WorldStateComponent")
      if world_state_component_id == nil then
        return
      end

      local shift_count = tonumber(GlobalsGetValue("kaleva_koetus_fungal_shift_count")) or 0
      GlobalsSetValue("kaleva_koetus_fungal_shift_count", tostring(shift_count + 1))

      SetRandomSeed(0xB10 + shift_count * 1000, 0x10B)

      local material_current_type = {}

      local prob_from = {}
      local prob_to = {}

      for _, item in ipairs(materials_from) do
        local material_count = #item.materials
        for i = 1, material_count do
          local material = item.materials[i]
          local type = CellFactory_GetType(material)
          material_current_type[type] = type

          prob_from[type] = (prob_from[type] or 0) + item.probability / material_count
        end
      end
      for _, item in ipairs(materials_to) do
        local type = CellFactory_GetType(item.material)
        material_current_type[type] = type

        prob_to[type] = (prob_to[type] or 0) + item.probability
      end

      for material, probs in pairs(extend_materials) do
        local type = CellFactory_GetType(material)
        material_current_type[type] = type

        prob_from[type] = (prob_from[type] or 0) + probs.prob_from
        prob_to[type] = (prob_to[type] or 0) + probs.prob_to
      end

      local changed_materials = ComponentGetValue2(world_state_component_id, "changed_materials")
      for idx = 1, #changed_materials, 2 do
        local from_name = changed_materials[idx]
        local to_name = changed_materials[idx + 1]

        local from_type = CellFactory_GetType(from_name)
        local to_type = CellFactory_GetType(to_name)

        material_current_type[from_type] = material_current_type[from_type] or from_type
        material_current_type[to_type] = material_current_type[to_type] or to_type

        material_current_type[from_type] = material_current_type[to_type]

        prob_from[from_type] = prob_from[from_type] or 0.5
        prob_to[to_type] = prob_to[to_type] or 1.0
      end

      local material_no_shift = {}
      for material, _ in pairs(material_current_type) do
        if CellFactory_HasTag(material, "[NO_FUNGAL_SHIFT]") then
          prob_to[material] = nil
          material_no_shift[material] = true -- provide no degree
        end
      end

      local max_reset_times = 8
      local max_shift_times = 15

      local rem_a = max_reset_times
      local rem_b = max_shift_times

      local is_converted = {}
      local converted_materials = {}

      ---@param from_mat number
      ---@param to_mat number
      local function apply_convert(from_mat, to_mat)
        ConvertMaterialEverywhere(from_mat, to_mat)
        material_current_type[from_mat] = material_current_type[to_mat]
      end

      ---@return table<number, number[]> state state[target] = {source1, source2...})
      local function get_state_info()
        local state = {}
        for src, current in pairs(material_current_type) do
          if material_no_shift[src] ~= true then
            state[current] = state[current] or {}
            table.insert(state[current], src)
          end
        end
        return state
      end

      ---@param state_info table<number, number[]>
      ---@param ex1 number?
      ---@param ex2 number?
      ---@return number?
      ---@return number?
      local function get_buffer(state_info, ex1, ex2)
        for _, sources in pairs(state_info) do
          if #sources >= 2 then
            local J, K
            for _, src in ipairs(sources) do
              if src ~= ex1 and src ~= ex2 then
                if J == nil then
                  J = src
                elseif K == nil then
                  K = src
                  break
                end
              end
            end
            if J ~= nil and K ~= nil then
              return J, K
            end
          end
        end
        return nil, nil
      end

      ---@class WeightedItem
      ---@field weight number
      ---@field [any] any

      ---@generic T : WeightedItem
      ---@param options T[]
      ---@return T?
      local function pick_random_weighted(options)
        if #options == 0 then
          return nil
        end

        local total_weight = 0
        for _, opt in ipairs(options) do
          total_weight = total_weight + opt.weight
        end
        if total_weight <= 0 then
          return options[1]
        end

        local r = Random() * total_weight
        local accum = 0
        for _, opt in ipairs(options) do
          accum = accum + opt.weight
          if r <= accum then
            return opt
          end
        end
        return options[#options]
      end

      -- Reset (a)
      while rem_a > 0 do
        local state_info = get_state_info()
        local M_candidates = {}

        for M, p_M in pairs(prob_from) do
          if is_converted[M] ~= true then
            local f_M = material_current_type[M]
            if f_M ~= M then
              local X_list = state_info[M]
              if X_list ~= nil and #X_list > 0 then
                local in_degree = state_info[f_M] and #state_info[f_M] or 0
                local options = {}

                if in_degree > 1 then
                  table.insert(options, { type = "A0", X = X_list[1], weight = 1.0, cost_a = 1, cost_b = 0 })
                else
                  if in_degree > 0 and rem_b >= 1 then
                    for A, p_A in pairs(prob_from) do
                      if A ~= M and (#X_list > 1 or material_current_type[A] ~= M) and is_converted[A] ~= true then
                        local A_list = state_info[material_current_type[A]]
                        if A_list ~= nil and #A_list > 1 then
                          table.insert(options, { type = "A1", X = X_list[1], A = A, weight = p_A, cost_a = 1, cost_b = 1 })
                        end
                      end
                    end

                    if #X_list == 1 then
                      local X = X_list[1]
                      if prob_from[X] ~= nil and is_converted[X] ~= true then
                        local J, K = get_buffer(state_info, M, X)
                        if J ~= nil and K ~= nil then
                          table.insert(options, { type = "A2", X = X, J = J, K = K, weight = prob_from[X], cost_a = 1, cost_b = 1 })
                        end
                      end
                    end
                  end
                  -- Lossy
                  table.insert(options, { type = "A0", X = X_list[1], weight = 0.0, extra_weight = 0.1, cost_a = 1, cost_b = 0 })
                end

                local chosen_opt = pick_random_weighted(options)
                if chosen_opt ~= nil then
                  chosen_opt.M = M
                  table.insert(M_candidates, { opt = chosen_opt, weight = p_M * (chosen_opt.extra_weight or 1.0) })
                end
              end
            end
          end
        end

        local final_choice = pick_random_weighted(M_candidates)
        if final_choice == nil then
          break
        end

        local opt = final_choice.opt
        if opt.type == "A0" then
          apply_convert(opt.M, opt.X)
          is_converted[opt.M] = true
          table.insert(converted_materials, opt.M)
          table.insert(converted_materials, opt.X)
        elseif opt.type == "A1" then
          apply_convert(opt.A, opt.M)
          apply_convert(opt.M, opt.X)
          is_converted[opt.A] = true
          is_converted[opt.M] = true
          table.insert(converted_materials, opt.A)
          table.insert(converted_materials, opt.M)
          table.insert(converted_materials, opt.X)
        elseif opt.type == "A2" then
          apply_convert(opt.J, opt.X)
          apply_convert(opt.X, opt.M)
          apply_convert(opt.M, opt.J)
          apply_convert(opt.J, opt.K)
          is_converted[opt.X] = true
          is_converted[opt.M] = true
          table.insert(converted_materials, opt.X)
          table.insert(converted_materials, opt.M)
        end

        rem_a = rem_a - opt.cost_a
        rem_b = rem_b - opt.cost_b
      end

      -- Shift (b)
      while rem_b > 0 do
        local state_info = get_state_info()
        local S_candidates = {}

        for S, p_S in pairs(prob_from) do
          if is_converted[S] ~= true then
            local f_S = material_current_type[S]
            local in_degree = state_info[f_S] and #state_info[f_S] or 0

            local T_options = {}
            for T, p_T in pairs(prob_to) do
              local f_T = material_current_type[T]
              if f_T ~= f_S and f_T ~= S then
                local macro_options = {}

                if in_degree > 1 then
                  table.insert(macro_options, { type = "B0", T = T, weight = 1.0, cost_b = 1 })
                else
                  if in_degree > 0 and rem_b >= 2 then
                    for A, p_A in pairs(prob_from) do
                      if A ~= S and A ~= T and is_converted[A] ~= true then
                        local A_list = state_info[material_current_type[A]]
                        if A_list ~= nil and #A_list > 1 then
                          table.insert(macro_options, { type = "B1", T = T, A = A, weight = p_A, cost_b = 2 })
                        end
                      end
                    end

                    if prob_from[T] ~= nil and is_converted[T] ~= true then
                      local J, K = get_buffer(state_info, S, T)
                      if J ~= nil and K ~= nil then
                        table.insert(macro_options, { type = "B2", T = T, J = J, K = K, weight = prob_from[T], cost_b = 2 })
                      end
                    end
                  end
                  -- Lossy
                  table.insert(macro_options, { type = "B0", T = T, weight = 0.0, extra_weight = 0.1, cost_b = 1 })
                end

                local best_macro = pick_random_weighted(macro_options)
                if best_macro ~= nil then
                  table.insert(
                    T_options,
                    { opt = best_macro, weight = p_T * (best_macro.extra_weight or 1.0), extra_weight = best_macro.extra_weight }
                  )
                end
              end
            end

            local chosen_T_opt = pick_random_weighted(T_options)
            if chosen_T_opt ~= nil then
              chosen_T_opt.opt.S = S
              table.insert(S_candidates, { opt = chosen_T_opt.opt, weight = p_S * (chosen_T_opt.extra_weight or 1.0) })
            end
          end
        end

        local final_choice = pick_random_weighted(S_candidates)
        if final_choice == nil then
          break
        end

        local opt = final_choice.opt
        if opt.type == "B0" then
          apply_convert(opt.S, opt.T)
          is_converted[opt.S] = true
          table.insert(converted_materials, opt.S)
          table.insert(converted_materials, opt.T)
        elseif opt.type == "B1" then
          apply_convert(opt.A, opt.S)
          apply_convert(opt.S, opt.T)
          is_converted[opt.A] = true
          is_converted[opt.S] = true
          table.insert(converted_materials, opt.A)
          table.insert(converted_materials, opt.S)
          table.insert(converted_materials, opt.T)
        elseif opt.type == "B2" then
          apply_convert(opt.J, opt.S)
          apply_convert(opt.S, opt.T)
          apply_convert(opt.T, opt.J)
          apply_convert(opt.J, opt.K)
          is_converted[opt.S] = true
          is_converted[opt.T] = true
          table.insert(converted_materials, opt.S)
          table.insert(converted_materials, opt.T)
        end

        rem_b = rem_b - opt.cost_b
      end

      -- using converted_materials...
      if #converted_materials == 0 then
        return
      end

      local function random_unique_integers(min, max, count)
        min = min - 1
        local total = max - min
        local numbers = {}
        for i = 1, total do
          numbers[i] = i + min
        end

        for i = 1, count do
          local j = Random(i, total)
          numbers[i], numbers[j] = numbers[j], numbers[i]
        end

        local result = {}
        for i = 1, count do
          result[i] = numbers[i]
        end

        return result
      end

      local material_indexes = random_unique_integers(1, #converted_materials, math.floor(#converted_materials * 0.5))
      for _, index in ipairs(material_indexes) do
        local x = pos_x + Randomf(-20, 20)
        local y = pos_y + Randomf(-20, 20)
        local material = converted_materials[index]
        GameCreateParticle(CellFactory_GetName(material), x - 10, y - 10, 20, Randomf(-200, 200), Randomf(-200, -60), true, true)
        GameCreateParticle(CellFactory_GetName(material), x + 10, y - 10, 20, Randomf(-200, 200), Randomf(-200, -60), true, true)
      end

      GameTriggerMusicFadeOutAndDequeueAll(5.0)

      for _ = 1, 5 do
        local x = pos_x + Randomf(-10, 10)
        local y = pos_y + Randomf(-10, 10)
        GameTriggerMusicEvent("music/oneshot/tripping_balls_01", false, x, y)
        local eye = EntityLoad("data/entities/particles/treble_eye.xml", x, y - 10)
        EntityAddChild(player_entity_id, eye)
      end

      ---@param str string
      ---@return string[]
      local function split_by_space(str)
        local result = {}
        for word in string.gmatch(str, "%S+") do
          table.insert(result, word)
        end
        return result
      end
      ---@param str string
      ---@param sep string?
      ---@return string[]
      local function split_by_string(str, sep)
        local result = {}
        if sep == nil or sep == "" then
          return { str }
        end

        local start_idx = 1
        while true do
          local pos_start, pos_end = string.find(str, sep, start_idx, true)
          if not pos_start then
            break
          end
          table.insert(result, string.sub(str, start_idx, pos_start - 1))
          start_idx = pos_end + 1
        end

        if #str >= start_idx then
          table.insert(result, string.sub(str, start_idx))
        end
        return result
      end
      ---@param str string
      ---@return string[]
      local function split_by_utf8(str)
        local result = {}
        for char in string.gmatch(str, "[%z\1-\127\192-\255][\128-\191]*") do
          table.insert(result, char)
        end
        return result
      end

      local title_key = log_messages[Random(1, #log_messages)]
      local title = GameTextGetTranslatedOrNot(title_key)
      local words = split_by_space(title)
      local word_based = #words >= 3
      local processed_words = {}
      local first_word = true
      for _, word in ipairs(words) do
        local times = 1
        if word_based == true then
          if Random() < 0.4 then
            times = Random(1, 2)
          end
        end

        for _ = 1, times do
          if first_word == true then
            first_word = false
          else
            if word_based == true then
              if Random() < 0.6 then
                table.insert(processed_words, " ")
              end
            else
              if Random() < 0.8 then
                table.insert(processed_words, " ")
              end
            end
          end

          local chars = split_by_utf8(word)
          local processed_chars = {}
          for _, char in ipairs(chars) do
            if word_based == true then
              if Random() < 0.2 then
                table.insert(processed_chars, char:rep(Random(1, 3)))
              else
                table.insert(processed_chars, char)
              end
            else
              if Random() < 0.7 then
                table.insert(processed_chars, char:rep(Random(1, 6)))
              else
                table.insert(processed_chars, char)
              end
            end
          end
          table.insert(processed_words, table.concat(processed_chars))
        end
      end
      local processed_title = table.concat(processed_words)

      local description = GameTextGet("$logdesc_reality_mutation", "#kaleva_koetus#empty#")
      local description_parts = split_by_string(description, "#kaleva_koetus#empty#")
      local processed_description
      if #description_parts <= 1 then
        local material = converted_materials[Random(1, #converted_materials)]
        local material_name = GameTextGetTranslatedOrNot(CellFactory_GetUIName(material)):upper()
        processed_description = GameTextGet("$logdesc_reality_mutation", material_name)
      else
        words = split_by_space(description_parts[Random(1, #description_parts)])
        -- word_based = #words >= 3
        processed_words = {}

        for i, word in ipairs(words) do
          local times = 1
          if word_based == true then
            if Random() < 0.4 then
              times = Random(1, 2)
            end
          end

          for _ = 1, times do
            local chars = split_by_utf8(word)
            local processed_chars = {}
            for _, char in ipairs(chars) do
              if word_based == true then
                if Random() < 0.2 then
                  table.insert(processed_chars, char:rep(Random(1, 3)))
                else
                  table.insert(processed_chars, char)
                end
              else
                if Random() < 0.7 then
                  table.insert(processed_chars, char:rep(Random(1, 6)))
                else
                  table.insert(processed_chars, char)
                end
              end
            end

            if word_based == true then
              table.insert(processed_words, table.concat(processed_chars))
            else
              if i > 1 then
                if Random() < 0.7 then
                  table.insert(processed_words, " ")
                end
              end
              for _, processed_char in ipairs(processed_chars) do
                table.insert(processed_words, processed_char)
              end
            end
          end
        end

        local processed_word_count = #processed_words

        material_indexes = random_unique_integers(1, #converted_materials, math.floor(#converted_materials * 0.5))
        for _, index in ipairs(material_indexes) do
          local material = converted_materials[index]
          local material_name = GameTextGetTranslatedOrNot(CellFactory_GetUIName(material)):upper()
          local material_name_parts = {}
          if Random() < 0.4 then
            if word_based == true then
              local material_name_words = split_by_space(material_name)
              for _, material_name_word in ipairs(material_name_words) do
                table.insert(material_name_parts, material_name_word)
              end
            else
              local chars = split_by_utf8(material_name)
              local split_pos = random_unique_integers(1, #chars - 1, Random(1, math.ceil(#chars / 3)))
              table.sort(split_pos)
              local last_pos = 1
              for _, pos in ipairs(split_pos) do
                table.insert(material_name_parts, table.concat(chars, "", last_pos, pos))
                last_pos = pos + 1
              end
              table.insert(material_name_parts, table.concat(chars, "", last_pos, #chars))
            end
          else
            table.insert(material_name_parts, material_name)
          end

          for _, material_name_part in ipairs(material_name_parts) do
            local times = 1
            if word_based == true then
              if Random() < 0.4 then
                times = Random(1, 3)
              end
            else
              if Random() < 0.7 then
                times = Random(1, 6)
              end
            end

            for _ = 1, times do
              table.insert(processed_words, Random(1, processed_word_count), material_name_part)
              processed_word_count = processed_word_count + 1
            end
          end
        end

        if word_based == true then
          local word_and_spaces = {}
          for i = 1, processed_word_count do
            if i > 1 then
              if Random() < 0.6 then
                table.insert(word_and_spaces, " ")
              end
            end
            table.insert(word_and_spaces, processed_words[i])
          end
          processed_description = table.concat(word_and_spaces)
        else
          processed_description = table.concat(processed_words)
        end
      end

      GamePrintImportant(processed_title, processed_description, "data/ui_gfx/decorations/3piece_fungal_shift.png")

      local add_icon = true
      local child_entities = EntityGetAllChildren(player_entity_id)
      if child_entities ~= nil then
        for _, child_entity_id in ipairs(child_entities) do
          if EntityGetName(child_entity_id) == "fungal_shift_ui_icon" then
            add_icon = false
            break
          end
        end
      end

      if add_icon == true then
        local icon_entity = EntityCreateNew("fungal_shift_ui_icon")
        local _ = EntityAddComponent(icon_entity, "UIIconComponent", {
          name = "$status_reality_mutation",
          description = "$statusdesc_reality_mutation",
          icon_sprite_file = "data/ui_gfx/status_indicators/fungal_shift.png",
        })
        EntityAddChild(player_entity_id, icon_entity)
      end
    end
  end

  if custom_fungal_shift == nil then
    local fungal_shift = fungal_shift
    if type(fungal_shift) == "function" then
      custom_fungal_shift = function(player_entity_id, pos_x, pos_y)
        local iter_str = GlobalsGetValue("fungal_shift_iteration", "0") --[[@as string]]
        local last_frame_str = GlobalsGetValue("fungal_shift_last_frame", "-1000000") --[[@as string]]

        local shift_count = tonumber(GlobalsGetValue("kaleva_koetus_fungal_shift_count")) or 0
        GlobalsSetValue("kaleva_koetus_fungal_shift_count", tostring(shift_count + 1))

        for i = 1, 5 do
          GlobalsSetValue("fungal_shift_iteration", tostring(0xB10 + shift_count * 10 + i))
          GlobalsSetValue("fungal_shift_last_frame", "-1000000")

          fungal_shift(player_entity_id, pos_x, pos_y, true)
        end

        GlobalsSetValue("fungal_shift_iteration", iter_str)
        GlobalsSetValue("fungal_shift_last_frame", last_frame_str)
      end
    end
  end

  custom_fungal_shift = custom_fungal_shift or function() end
end

local fungal_effect_tag = "kaleva_koetus_fungal_effect"

local function start_fungal_shift(player_entity_id)
  local fungal_effect_entities = EntityGetAllChildren(player_entity_id, fungal_effect_tag)
  if fungal_effect_entities == nil or #fungal_effect_entities == 0 then
    local x, y = EntityGetTransform(player_entity_id)
    local effect_entity_id = EntityLoad("data/entities/misc/effect_trip_00.xml", x, y)
    EntityAddTag(effect_entity_id, fungal_effect_tag)
    EntityAddChild(player_entity_id, effect_entity_id)
    effect_entity_id = EntityLoad("data/entities/misc/effect_trip_01.xml", x, y)
    EntityAddTag(effect_entity_id, fungal_effect_tag)
    EntityAddChild(player_entity_id, effect_entity_id)
    effect_entity_id = EntityLoad("data/entities/misc/effect_trip_02.xml", x, y)
    EntityAddTag(effect_entity_id, fungal_effect_tag)
    EntityAddChild(player_entity_id, effect_entity_id)
    effect_entity_id = EntityLoad("mods/kaleva_koetus/files/entities/misc/effect_trip_03_fake.xml", x, y)
    EntityAddTag(effect_entity_id, fungal_effect_tag)
    EntityAddChild(player_entity_id, effect_entity_id)
  end
end

local function clear_fungal_effects(player_entity_id)
  local fungal_effect_entities = EntityGetAllChildren(player_entity_id, fungal_effect_tag)
  if fungal_effect_entities ~= nil then
    for _, fungal_effect_id in ipairs(fungal_effect_entities) do
      EntityKill(fungal_effect_id)
    end
  end
end

local function perform_fungal_shift(player_entity_id)
  -- mostly from data/scripts/status_effects/effect_trip_03.lua
  local pos_x, pos_y = EntityGetTransform(player_entity_id)
  SetRandomSeed(pos_x + GameGetFrameNum(), pos_y)
  if Random() > 0.5 then
    local function spawn(x, y)
      local _ = EntityLoad("data/entities/particles/treble_eye.xml", x, y)
    end

    local x, y = pos_x + Randomf(-100, 100), pos_y + Randomf(-80, 80)
    local rad = Randomf(0, 30)

    spawn(x, y)
    spawn(x + 40 + rad, y + 30 + rad)
    spawn(x - 40 - rad, y + 30 + rad)
  end

  custom_fungal_shift(player_entity_id, pos_x, pos_y)
end

local fungal_curse_tag = "kaleva_koetus_fungal_curse"
local function add_fungal_curse(player_entity_id, clean_old)
  local fungal_curse_entities = EntityGetAllChildren(player_entity_id, fungal_curse_tag)
  if fungal_curse_entities ~= nil then
    if clean_old == true then
      for _, fungal_curse_entity_id in ipairs(fungal_curse_entities) do
        EntityKill(fungal_curse_entity_id)
      end
    elseif #fungal_curse_entities > 0 then
      return
    end
  end
  local curse_effect_id = EntityCreateNew()
  local x, y = EntityGetTransform(player_entity_id)
  EntitySetTransform(curse_effect_id, x, y)
  AddNewInternalVariable(curse_effect_id, "added_frame", "value_int", GameGetFrameNum())
  EntityLoadToEntity("mods/kaleva_koetus/files/entities/misc/effect_fungal_shift_curse.xml", curse_effect_id)
  EntityAddTag(curse_effect_id, fungal_curse_tag)
  EntityAddChild(player_entity_id, curse_effect_id)
end

function beyond:on_world_pre_update()
  local player_entity_id = GetPlayerEntity()
  if player_entity_id == nil or EntityGetIsAlive(player_entity_id) == false then
    return
  end

  local refresh_fungal_curse = false
  local next_start_frame = tonumber(GlobalsGetValue("kaleva_koetus_next_fungal_shift_start_frame")) or 0
  local next_perform_frame = tonumber(GlobalsGetValue("kaleva_koetus_next_fungal_shift_perform_frame")) or -1
  local next_perform_determined = GlobalsGetValue("kaleva_koetus_next_fungal_shift_perform_determined", "0")
  local now_frame = GameGetFrameNum()
  if now_frame >= next_start_frame then
    if next_perform_determined == "0" then
      GlobalsSetValue("kaleva_koetus_next_fungal_shift_perform_frame", tostring(now_frame + EFFECT_FRAME))
      GlobalsSetValue("kaleva_koetus_next_fungal_shift_perform_determined", "1")
      refresh_fungal_curse = true
      start_fungal_shift(player_entity_id)
    else
      if now_frame >= next_perform_frame then
        perform_fungal_shift(player_entity_id)
        next_start_frame = next_start_frame + WAIT_FRAME
        GlobalsSetValue("kaleva_koetus_next_fungal_shift_start_frame", tostring(next_start_frame))
        GlobalsSetValue("kaleva_koetus_next_fungal_shift_perform_frame", tostring(next_start_frame + EFFECT_FRAME))
        GlobalsSetValue("kaleva_koetus_next_fungal_shift_perform_determined", "0")
        refresh_fungal_curse = true
        GamePrintImportant("$kaleva_koetus_fungal_shift_curse_again", "$kaleva_koetus_fungal_shift_curse_again_description")
        return
      else
        start_fungal_shift(player_entity_id)
      end
    end
  else
    clear_fungal_effects(player_entity_id)
  end

  if next_start_frame > 0 and EntityHasTag(player_entity_id, "player_unit") then
    add_fungal_curse(player_entity_id, refresh_fungal_curse)
  end
end

--[[
local material_current_type = {}
local material_no_shift = {}

local ever_changed = {}
local changed_count = 0

local world_state_entity_id = GameGetWorldStateEntity()
local world_state_component_id = EntityGetFirstComponent(world_state_entity_id, "WorldStateComponent")

local changed_materials = ComponentGetValue2(world_state_component_id, "changed_materials")
for idx = 1, #changed_materials, 2 do
  local from_name = changed_materials[idx]
  local to_name = changed_materials[idx + 1]

  local from_type = CellFactory_GetType(from_name)
  local to_type = CellFactory_GetType(to_name)

  if ever_changed[from_type] ~= true then
    ever_changed[from_type] = true
    changed_count = changed_count + 1
  end

  material_current_type[from_type] = material_current_type[from_type] or from_type
  material_current_type[to_type] = material_current_type[to_type] or to_type

  material_current_type[from_type] = material_current_type[to_type]
end

local function get_state_info()
  local state = {}
  for src, current in pairs(material_current_type) do
    if material_no_shift[src] ~= true then
      state[current] = state[current] or {}
      table.insert(state[current], src)
    end
  end
  return state
end

local state = get_state_info()

local loss_count = 0
local self_count = 0
local total_count = 0
for material, current in pairs(material_current_type) do
  if state[material] == nil then
    print(CellFactory_GetName(material))
    loss_count = loss_count + 1
  end
  if material == current and ever_changed[material] == true then
    self_count = self_count + 1
  end
  total_count = total_count + 1
end

print("loss: " .. loss_count)
print("self: " .. self_count)
print("changed: " .. changed_count)
print("total: " .. total_count)
]]

return beyond
