local B1_KOLMI_REINFORCE_COUNT = 4

local _GameGetOrbCountThisRun = GameGetOrbCountThisRun
function GameGetOrbCountThisRun()
  local orb_count_this_run = _GameGetOrbCountThisRun()
  local reinforced_count = orb_count_this_run + B1_KOLMI_REINFORCE_COUNT

  if orb_count_this_run >= 33 then
    return orb_count_this_run
  elseif reinforced_count >= 33 then
    return 33
  else
    return reinforced_count
  end
end
