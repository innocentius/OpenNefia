local Gui = require("api.Gui")
local Rand = require("api.Rand")

local Material = {}

function Material.random_material_id(level, rarity, choices)
   for i=1,500 do
      local entry = Rand.choice(data["elona.material"])
      if i % 10 == 0 then
         level = level - 1
         rarity = rarity - 1
      end
      if entry.level >= level then
         if entry.rarity >= rarity then
            if not choices or choices[entry._id] then
               if Rand.one_in(entry.rarity) then
                  return entry
               end
            end
         end
      end
   end

   return nil
end

function Material.obtain(chara, id, num, txt_type)
   num = math.max(num, 1)
   if chara.materials[id] then
      chara.materials[id] = chara.materials[id] + num
   else
      chara.materials[id] = num
   end
   Gui.play_sound("base.alert")
   Gui.mes("matgain", "Blue")
end

function Material.lose(chara, id, num)
   num = math.max(num, 1)
   chara.materials[id] = math.max((chara.materials[id] or 0) - num, 0)
   Gui.mes("matlose", "Blue")
end

return Material
