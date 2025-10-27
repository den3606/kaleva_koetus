local _spawn_rewards = spawn_rewards
-- selene: allow(unused_variable)
function spawn_rewards(x, y)
  _spawn_rewards(x, y)
  local _ = EntityLoad("mods/kaleva_koetus/files/entities/animals/boss_centipede/rewards/reward_nightmare_a20.xml", x + 40, y - 50)
end
