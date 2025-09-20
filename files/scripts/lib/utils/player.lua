-- プレイヤーのEntity_idを取ってくる
function GetPlayerEntity()
  local players = EntityGetWithTag("player_unit")
  if #players == 0 then
    return FindPolymorphedPlayer()
  end

  return players[1]
end

-- 呼ぶとプレイヤーが死ぬ
-- messageは死亡時の詳細テキスト(他のComponent経由でもメッセージを追加できる場合があるが、そのときはこのメッセージの前に設置されるよう)
function KillPlayer(message)
  EntityInflictDamage(GetPlayerEntity(), 999, "DAMAGE_SLICE", message, "BLOOD_EXPLOSION", 0, 0)
end

function GetPlayerHealth()
  local damagemodels = EntityGetComponent(GetPlayerEntity(), "DamageModelComponent")
  local health = 0
  if (damagemodels ~= nil) then
    for i, v in ipairs(damagemodels) do
      health = tonumber(ComponentGetValue(v, "hp"))
      break
    end
  end
  return health
end

-- function to return player max health
function GetPlayerMaxHealth()
  local damagemodels = EntityGetComponent(GetPlayerEntity(), "DamageModelComponent")
  local maxHealth = 0
  if (damagemodels ~= nil) then
    for i, v in ipairs(damagemodels) do

      maxHealth = tonumber(ComponentGetValue(v, "max_hp"))

      break
    end
  end
  return maxHealth
end

function FindPolymorphedPlayer()
  local nearby_polymorph = EntityGetWithTag("polymorphed") or {}
  local polymorphed_players = {}
  for _, entity in pairs(nearby_polymorph) do
    local game_stats = EntityGetFirstComponent(entity, "GameStatsComponent")
    if game_stats ~= nil then
      if ComponentGetValue2(game_stats, "is_player") == true then
        table.insert(polymorphed_players, entity)
      end
    end
  end

  for _, player_id in ipairs(polymorphed_players) do
    if EntityGetFirstComponent(player_id, "AnimalAIComponent") == nil and EntityGetFirstComponent(player_id, "PhysicsAIComponent") == nil and EntityGetFirstComponent(player_id, "WormAIComponent") ==
      nil and EntityGetFirstComponent(player_id, "AdvancedFishAIComponent") == nil then
      return player_id
    end
  end
  return nil
end

function FindSheepPlayer()
  local nearby_polymorph = EntityGetWithTag("polymorphed") or {}
  local polymorphed_players = {}
  for _, entity in pairs(nearby_polymorph) do
    local game_stats = EntityGetFirstComponent(entity, "GameStatsComponent")
    if game_stats ~= nil then
      if ComponentGetValue2(game_stats, "is_player") == true then
        table.insert(polymorphed_players, entity)
      end
    end
  end

  for _, player_id in ipairs(polymorphed_players) do
    if EntityGetFirstComponent(player_id, "AnimalAIComponent") == nil and EntityGetFirstComponent(player_id, "PhysicsAIComponent") == nil and EntityGetFirstComponent(player_id, "WormAIComponent") ==
      nil and EntityGetFirstComponent(player_id, "AdvancedFishAIComponent") == nil then
      local entity_name = EntityGetName(player_id)
      if entity_name == "$animal_sheep_fly" or entity_name == "$animal_sheep_bat" or entity_name == "$animal_sheep" then
        return player_id
      end
    end
  end
  return nil
end
