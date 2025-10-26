local B1_KOLMI_REINFORCE_COUNT = 4

local _GameGetOrbCountThisRun = GameGetOrbCountThisRun
function GameGetOrbCountThisRun()
  local orb_count_this_run = _GameGetOrbCountThisRun()
  local reinforced_count = orb_count_this_run + B1_KOLMI_REINFORCE_COUNT
  -- log:debug("reinforced_count: %d", reinforced_count)
  if reinforced_count <= 33 + B1_KOLMI_REINFORCE_COUNT then
    -- log:debug("update kolmi")
    return reinforced_count
  else
    return orb_count_this_run
  end
end
