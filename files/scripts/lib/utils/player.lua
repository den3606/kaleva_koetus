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
  if damagemodels ~= nil then
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
  if damagemodels ~= nil then
    for i, v in ipairs(damagemodels) do
      maxHealth = tonumber(ComponentGetValue(v, "max_hp"))

      break
    end
  end
  return maxHealth
end

function FindPolymorphedPlayer()
  local polymorphed_player = EntityGetWithTag("polymorphed_player")[1]
  if polymorphed_player then
    return polymorphed_player
  end

  return EntityGetWithTag("polymorphed_cessation")[1]
end

function FindSheepPlayer()
  local polymorphed_player = EntityGetWithTag("polymorphed_player")[1]
  if polymorphed_player then
    local entity_name = EntityGetName(polymorphed_player)
    if entity_name == "$animal_sheep_fly" or entity_name == "$animal_sheep_bat" or entity_name == "$animal_sheep" then
      return polymorphed_player
    end
  end
  return nil
end
