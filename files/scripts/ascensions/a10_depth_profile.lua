local DepthProfile = {}

DepthProfile.BASELINE = 256
DepthProfile.STEP = 512
DepthProfile.MULTIPLIERS = {
  0.9,
  1.0,
  1.05,
  1.15,
  1.25,
  1.4,
  1.55,
  1.7,
}

function DepthProfile.max_stage()
  return #DepthProfile.MULTIPLIERS - 1
end

function DepthProfile.compute_stage(y)
  if not y then
    return 0
  end

  local stage = math.floor((y - DepthProfile.BASELINE) / DepthProfile.STEP)
  if stage < 0 then
    stage = 0
  end

  local max_stage = DepthProfile.max_stage()
  if stage > max_stage then
    stage = max_stage
  end

  return stage
end

function DepthProfile.get_multiplier_for_stage(stage)
  local max_stage = DepthProfile.max_stage()
  if not stage or stage < 0 then
    stage = 0
  elseif stage > max_stage then
    stage = max_stage
  end

  return DepthProfile.MULTIPLIERS[stage + 1]
end

function DepthProfile.compute(y)
  local stage = DepthProfile.compute_stage(y)
  return stage, DepthProfile.get_multiplier_for_stage(stage)
end

return DepthProfile
