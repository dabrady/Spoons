local key_logger = {}

function key_logger.make(key_handler)
  assert(type(key_handler) == "function")

  local self = {
    DOWN_KEYS = {},
    on_key_down = key_handler
  }
  return setmetatable(self, { __index = key_logger })
end


function key_logger:log(event)
  if not type(event) == "userdata" then
    return
  end

  local event_type = hs.eventtap.event.types[event:getType()]
  local keycode = event:getKeyCode()
  if event_type == "keyDown" then
    -- Ignore if it's already down (it must be a "key repeat", i.e. held down)
    if self.DOWN_KEYS[keycode] then
      return
    end

    -- Add it
    self.DOWN_KEYS[keycode] = true

    -- Tell our subscriber
    self.on_key_down(table.copy(self.DOWN_KEYS), event:getFlags())
  elseif event_type == "keyUp" then
    -- Remove it
    self.DOWN_KEYS[keycode] = nil
  end
end

return key_logger
