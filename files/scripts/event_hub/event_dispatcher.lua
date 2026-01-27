local EventDispatcher = {}
EventDispatcher._listeners = {}

function EventDispatcher:add_listener(event_type, handler)
  local listeners_on_added = self._listeners[event_type]
  if not listeners_on_added then
    listeners_on_added = {}
    self._listeners[event_type] = listeners_on_added
  end
  for _, func in ipairs(listeners_on_added) do
    if func == handler then
      return nil
    end
  end
  table.insert(listeners_on_added, handler)
end

function EventDispatcher:dispatch(event_type, ...)
  local listeners = self._listeners[event_type]
  if listeners then
    for _, handler in ipairs(listeners) do
      -- for temporarily compatibility
      handler({...})
      -- handler(...)
    end
  end
end

return EventDispatcher
