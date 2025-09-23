local json = dofile_once("mods/kaleva_koetus/files/scripts/lib/jsonlua/json.lua")

local EventPublisher = {}

function EventPublisher:publish(source, event_type, ...)
  local params = { ... }

  local serialized_data = json.encode({ source, event_type, params })

  local retry = 5
  while retry > 0 do
    local counter = tonumber(GlobalsGetValue("kaleva_queue_counter", "0"))
    local version = tonumber(GlobalsGetValue("kaleva_queue_version", "0"))

    local new_counter = counter + 1
    local new_version = version + 1

    if tonumber(GlobalsGetValue("kaleva_queue_version", "0")) == version then
      GlobalsSetValue("kaleva_queue_item_" .. tostring(new_counter), serialized_data)
      GlobalsSetValue("kaleva_queue_counter", tostring(new_counter))
      GlobalsSetValue("kaleva_queue_version", tostring(new_version))

      return true
    end

    retry = retry - 1
  end

  error("[EventBroker] Failed to queue event after retries: " .. serialized_data)
  return false
end

return EventPublisher
