local Ui = require("api.Ui")
local I18N = require("api.I18N")

local Draw = require("api.Draw")
local Prompt = require("api.gui.Prompt")
local IUiLayer = require("api.gui.IUiLayer")
local IInput = require("api.gui.IInput")
local UiTheme = require("api.gui.UiTheme")
local InputHandler = require("api.gui.InputHandler")
local CharaMakeCaption = require("api.gui.menu.chara_make.CharaMakeCaption")

local DeathMenu = class.class("DeathMenu", IUiLayer)

DeathMenu:delegate("input", IInput)

function DeathMenu:init(data)
   self.data = data
   self.caption = CharaMakeCaption:new("misc.death.you_are_about_to_be_buried")
   self.prompt = Prompt:new({"misc.death.crawl_up", "misc.death.lie_on_your_back"}, 240)

   self.input = InputHandler:new()
   self.input:forward_to(self.prompt)
   self.input:bind_keys {
      shift = function() self.canceled = true end
   }
end

function DeathMenu:relayout(x, y, width, height)
   self.x = x or 0
   self.y = y or 0
   self.width = width or Draw.get_width()
   self.height = height or Draw.get_height()
   self.t = UiTheme.load(self)

   self.caption:relayout(self.x + 20, self.y + 30)
   self.prompt:relayout(nil, 100)
end

function DeathMenu:draw()
   self.t.void:draw(self.x, self.y, self.width, self.height, {255, 255, 255})

   local x = 135
   local y = 134
   Draw.set_font(14) -- 14 - en * 2
   local p = #self.data - 4
   if p >= 80 then
      p = 72
   elseif p < 0 then
      p = 0
   end

   Draw.set_color(138, 131, 100)
   for i = p+1, p + 8 do
      local p = i * 4
      y = y + 46

      local text
      if i == #self.data then
         text = "New!"
      else
         text = I18N.get("misc.score.rank", i + 1)
      end

      Draw.text(text, x - 80, y + 10, {10, 10, 10})

      local no_entry = i > #self.data
      if no_entry then
         Draw.text("no_entry", x, y, {10, 10, 10})
      else
         Draw.text(self.data[i].last_words, x, y, {10, 10, 10})

         Draw.text(self.data[i].death_cause, x, y + 20, {10, 10, 10})

         Draw.text(I18N.get("misc.score.score", 9999), x + 480, y + 20)

         self.data[i].image:draw(x - 22, y + 12, nil, nil, {255, 255, 255}, true)
      end
   end

   self.caption:draw()
   self.prompt:draw()
end

function DeathMenu:update()
   self.caption:update()

   local result, canceled = self.prompt:update()
   if result then
      return result, canceled
   end
end

return DeathMenu