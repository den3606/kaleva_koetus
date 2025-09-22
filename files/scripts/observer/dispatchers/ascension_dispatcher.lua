-- Ascension Dispatcher
-- Handles dispatching events directly to active ascensions

local AscensionDispatcher = {}

function AscensionDispatcher.dispatch(event_type, event_args)
  local AscensionManager = dofile_once("mods/kaleva_koetus/files/scripts/ascension_manager.lua")

  -- Build handler method name: "on_" + event_type
  local handler_name = "on_" .. event_type

  -- Dispatch to all active ascensions that have this handler
  for _, ascension in ipairs(AscensionManager.active_ascensions) do
    if ascension[handler_name] then
      -- Call the handler with the event arguments
      ascension[handler_name](ascension, event_args)
    end
  end
end

return AscensionDispatcher