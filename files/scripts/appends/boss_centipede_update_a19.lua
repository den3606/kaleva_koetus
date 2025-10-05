local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local log = Logger:new("boss_centipede_update.lua")
local A19_KOLMI_REINFORCE_COUNT = 5

local _GameGetOrbCountThisRun = GameGetOrbCountThisRun
function GameGetOrbCountThisRun()
  local orb_count_this_run = _GameGetOrbCountThisRun()
  local reinforced_count = orb_count_this_run + A19_KOLMI_REINFORCE_COUNT
  log:debug("reinforced_count: %d", reinforced_count)
  if reinforced_count <= 33 + 7 then
    log:debug("update kolmi")
    return reinforced_count
  else
    return orb_count_this_run
  end
end
