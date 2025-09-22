local AscensionDispatcher = {}

function AscensionDispatcher.dispatch(event_type, event_args)
  print("[AscensionDispatcher] Dispatching event: " .. event_type)
  local AscensionManager = dofile_once("mods/kaleva_koetus/files/scripts/ascension_manager.lua")

  -- Build handler method name: "on_" + event_type
  local handler_name = "on_" .. event_type
  print("[AscensionDispatcher] Looking for handler: " .. handler_name)

  -- Check if AscensionManager has this handler
  if AscensionManager[handler_name] then
    print("[AscensionDispatcher] Found handler in AscensionManager: " .. handler_name)
    AscensionManager[handler_name](AscensionManager, event_args)
  else
    print("[AscensionDispatcher] No handler found in AscensionManager for: " .. handler_name)
  end

  -- Dispatch to all active ascensions that have this handler
  print("[AscensionDispatcher] Active ascensions count: " .. #AscensionManager.active_ascensions)
  for i, ascension in ipairs(AscensionManager.active_ascensions) do
    if ascension[handler_name] then
      print("[AscensionDispatcher] Calling handler on ascension " .. i .. ": " .. handler_name)
      ascension[handler_name](ascension, event_args)
    end
  end
  print("[AscensionDispatcher] Dispatch completed for: " .. event_type)
end

return AscensionDispatcher
