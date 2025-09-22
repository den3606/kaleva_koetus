local AscensionDispatcher = {}

function AscensionDispatcher.dispatch(event_type, event_args)
  local AscensionManager = dofile_once("mods/kaleva_koetus/files/scripts/ascension_manager.lua")

  -- Build handler method name: "on_" + event_type
  local handler_name = "on_" .. event_type

  -- Check if AscensionManager has this handler
  if AscensionManager[handler_name] then
    AscensionManager[handler_name](AscensionManager, event_args)
  else
  end

  -- Dispatch to all active ascensions that have this handler
  for i, ascension in ipairs(AscensionManager.active_ascensions) do
    if ascension[handler_name] then
      ascension[handler_name](ascension, event_args)
    end
  end
end

return AscensionDispatcher
