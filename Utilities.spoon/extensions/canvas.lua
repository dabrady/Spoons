local canvas_ext = {}

---- Rolling my own 'show and hide with fade-out': need to be able to cancel the animation.
canvas_ext.flashable = {}
function canvas_ext.flashable.new(canvas, options)
  options = options or {}
  local _fade -- Forward declaration for closure
  local fader = hs.timer.delayed.new(options.fadeSpeed or 0.07, function() _fade() end)
  local hider = hs.timer.delayed.new(options.showDuration or 1, hs.fnutils.partial(fader.start, fader))
  -- local done = options.done or function() end

  -- A sentinel representing the exit condition for our background 'fader'
  local cancelFade = false

  local function _abortFade()
    -- Set the exit condition for any ongoing fade
    cancelFade = true
    -- Cancel any ongoing fade timer
    fader:stop()
    -- Reset canvas to maximum visibility
    canvas:alpha(1.0)
  end

  _fade = function()
    local exit = cancelFade or (canvas:alpha() == 0)
    if exit then
      canvas:hide()
      _abortFade()
    else
      local lowerAlpha = canvas:alpha() - 0.1
      canvas:alpha(lowerAlpha)

      -- Go around again
      fader:start()
    end
  end

  local function _hideCanvas()
    cancelFade = false
    hider:start()
  end

  return {
    canvas = canvas,
    flash = function()
      -- Show the canvas if it's not already visible, then hide it according to configuration.
      _abortFade()
      canvas:show()
      _hideCanvas()
    end
  }
end

setmetatable(canvas_ext.flashable, {__call = function(_, ...) return canvas_ext.flashable.new(...) end})

-----

return canvas_ext
