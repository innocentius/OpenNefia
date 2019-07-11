local UiTheme = require("api.gui.UiTheme")
local Draw = require("api.Draw")

-- Commonly used functions for UI rendering.
-- @module Ui
local Ui = {}

local tile_size = 48

function Ui.params_centered(width, height, in_game)
   local x = (Draw.get_width() - width) / 2

   local y
   if in_game then
      local tiled_height = Draw.get_height() / tile_size
      y = ((tiled_height + 1) * tile_size - height) / 2 + 8
   else
      y = (Draw.get_height() - height) / 2
   end

   return x, y, width, height
end

local t
function Ui.draw_topic(topic, x, y)
   t = t or UiTheme.load()
   Draw.set_font(12, "bold")
   Draw.set_color(255, 255, 255)
   t.tip_icons:draw_region(1, x, y + 7)
   Draw.set_color(0, 0, 0)
   Draw.text(topic, x + 26, y + 8) -- y + vfix + 8
   Draw.line(x + 22, y + 21, x + Draw.text_width(topic) + 36, y + 21)
   Draw.set_color(255, 255, 255)
end

function Ui.draw_note(text, x, y, width, height, x_offset)
   Draw.set_font(12, "bold") -- 12 + sizefix - en * 2
   Draw.text(text,
             x + width - Draw.text_width(text) - 140 - x_offset,
             y + height - 65 - height % 8,
             {0, 0, 0})
end

function Ui.random_cm_bg()
   return Draw.load_image(string.format("graphic/g%d.bmp", math.random(4)))
end

function Ui.unpack_font_desc(font)
   if type(font) == "number" then
      return font, nil
   else
      return font.size, font.style
   end
end

function Ui.display_weight(weight)
   return string.format("%d%d%s",
                        math.abs(math.floor(weight / 1000)),
                        math.abs(math.floor((weight % 1000) / 1000)),
                        "s")
end

return Ui
