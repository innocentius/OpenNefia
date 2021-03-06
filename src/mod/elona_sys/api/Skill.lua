local Rand = require("api.Rand")
local Map = require("api.Map")
local Chara = require("api.Chara")
local Event = require("api.Event")
local I18N = require("api.I18N")
local Gui = require("api.Gui")

local Skill = {}

function Skill.iter_stats()
   return data["base.skill"]:iter():filter(function(s) return s.skill_type == "stat" end)
end

function Skill.random_stat()
   return Rand.choice(Skill.iter_stats())._id
end

function Skill.calc_initial_potential(skill, level, knows_skill)
   local p

   if skill.skill_type == "stat" then
      p = math.min(level * 20, 400)
   else
      p = level * 5
      if knows_skill then
         p = p + 50
      else
         p = p + 100
      end
   end

   return p
end

function Skill.calc_initial_decayed_potential(base_potential, chara_level)
   if chara_level <= 1 then
      return base_potential
   end

   return math.floor(math.exp(math.log(0.9) * chara_level) * base_potential)
end

function Skill.calc_initial_skill_level(skill, initial_level, original_level, chara_level, chara)
   local sk = data["base.skill"]:ensure(skill)

   -- if not chara:has_skill(skill) then
   --    chara:set_base_skill(skill, 0, 0, 0)
   -- end
   -- local my_skill = chara:calc("skills")[skill]

   local potential
   local level = original_level

   if sk.calc_initial_potential then
      potential = sk.calc_initial_potential(initial_level, chara)
   else
      potential = Skill.calc_initial_potential(sk, initial_level, original_level == 0)
   end
   if sk.calc_initial_level then
      level = sk.calc_initial_level(initial_level, chara)
   else
      level = math.floor(potential * potential * chara_level / 45000 + initial_level + chara_level / 3)
   end

   potential = Skill.calc_initial_decayed_potential(potential, chara_level)

   if sk.calc_final then
      local t = sk.calc_final(initial_level, chara) or {}
      level = t.level or level
      potential = t.potential or potential
   end

   potential = math.max(1, potential)

   level = math.clamp(level, 0, 2000)

   return {
      level = level,
      potential = potential
   }
end

function Skill.calc_related_stat_exp(exp, exp_divisor)
   return exp / (2 + exp_divisor)
end

function Skill.calc_skill_exp(base_exp, potential, skill_level, buff)
   buff = buff or 0
   local exp = base_exp * potential / (100 + skill_level * 15)
   if buff > 0 then
      exp = exp * (100 + buff) / 100
   end
   return exp
end

local function get_skill_buff(chara, skill)
   local buffs = chara:calc("growth_buffs") or {}
   local list = buffs["base.skill"] or {}
   return list[skill] or 0
end

function Skill.calc_chara_exp_from_skill_exp(required_exp, level, skill_exp, exp_divisor)
   return Rand.rnd(required_exp * skill_exp / 1000 / (level + exp_divisor) + 1) + Rand.rnd(2)
end

function Skill.modify_potential(potential, level_delta)
   if level_delta > 0 then
      for _=0,level_delta do
         potential = math.max(math.floor(potential * 0.9), 1)
      end
   elseif level_delta < 0 then
      for _=0,-level_delta do
         potential = math.min(math.floor(potential * 1.1) + 1, 400)
      end
   end
   return potential
end

local function skill_change_text(chara, skill_id, is_increase)
   local part
   if is_increase then
      part = "increase"
   else
      part = "decrease"
   end
   local text = I18N.get_optional("skill." .. part .. "." .. skill_id, chara)
   if text then
      return text
   end

   if is_increase then
      return I18N.get("skill.default.increase", chara, "ability." .. skill_id .. ".name")
   else
      return I18N.get("skill.default.decrease", chara, "ability." .. skill_id .. ".name")
   end
end

local function proc_leveling(chara, skill, new_exp, level, potential)
   if new_exp >= 1000 then
      local level_delta = math.floor(new_exp / 1000)
      new_exp = new_exp % 1000
      level = level + level_delta
      potential = Skill.modify_potential(potential, level_delta)
      chara:set_base_skill(skill, level, potential, new_exp)
      if Map.is_in_fov(chara.x, chara.y) then
         local color = "White"
         if chara:is_allied() then
            Gui.play_sound("base.ding3")
            Gui.mes_alert()
            color = "Green"
         end
         Gui.mes_c(skill_change_text(chara, skill, true), color)
      end
      chara:refresh()
   elseif new_exp < 0 then
      local level_delta = math.floor(-new_exp / 1000 + 1)
      new_exp = 1000 + new_exp % 1000
      if level - level_delta < 1 then
         level_delta = level - 1
         if level == 1 and level_delta == 0 then
            new_exp = 0
         end
      end

      level = level - level_delta
      potential = Skill.modify_potential(potential, -level_delta)
      chara:set_base_skill(skill, level, potential, new_exp)
      if Map.is_in_fov(chara.x, chara.y) and level_delta ~= 0 then
         Gui.mes_c(skill_change_text(chara, skill, false), "Red")
         Gui.mes_alert()
      end
      chara:refresh()
   end

   chara:set_base_skill(skill, level, potential, new_exp)
end

function Skill.gain_fixed_skill_exp(chara, skill, exp)
   data["base.skill"]:ensure(skill)

   local level = chara:skill_level(skill)
   local potential = chara:skill_potential(skill)
   local new_exp = chara:skill_experience(skill) + exp

   if potential == 0 then
      return
   end

   proc_leveling(chara, skill, new_exp, level, potential)
end

function Skill.gain_skill_exp(chara, skill, base_exp, exp_divisor_stat, exp_divisor_level)
   exp_divisor_stat = exp_divisor_stat or 0
   exp_divisor_level = exp_divisor_level or 0

   local skill_data = data["base.skill"]:ensure(skill)

   if not chara:has_skill(skill) then return end
   if base_exp == 0 then return end

   if skill_data.related_stat then
      local exp = Skill.calc_related_stat_exp(base_exp, exp_divisor_stat)
      Skill.gain_skill_exp(chara, skill_data.related_stat, exp)
   end

   local level = chara:skill_level(skill)
   local potential = chara:skill_potential(skill)
   if potential == 0 then return end

   local exp
   if base_exp > 0 then
      local buff = get_skill_buff(chara, skill)
      exp = Skill.calc_skill_exp(base_exp, potential, level, buff)
      if exp == 0 then
         if Rand.one_in(level / 10 + 1) then
            exp = 1
         else
            return
         end
      end
   else
      exp = base_exp
   end

   local map = chara:current_map()
   local exp_divisor = map:calc("exp_divisor")
   if exp_divisor then
      exp = exp / exp_divisor
   end

   if exp > 0 and skill_data.apply_exp_divisor and exp_divisor_level ~= 1000 then
      local lvl_exp = Skill.calc_chara_exp_from_skill_exp(chara:calc("required_experience"), chara:calc("level"), exp, exp_divisor_level)
      chara.experience = chara.experience + lvl_exp
      if chara:is_player() then
         chara.sleep_experience = chara.sleep_experience + lvl_exp
      end
   end

   local new_exp = exp + chara:skill_experience(skill)
   proc_leveling(chara, skill, new_exp, level, potential)
end

local function get_random_body_part()
   if Rand.one_in(7) then
      return "base.neck"
   end
   if Rand.one_in(9) then
      return "base.back"
   end
   if Rand.one_in(8) then
      return "base.hand"
   end
   if Rand.one_in(4) then
      return "base.ring"
   end
   if Rand.one_in(6) then
      return "base.arm"
   end
   if Rand.one_in(5) then
      return "base.waist"
   end
   if Rand.one_in(5) then
      return "base.leg"
   end

   return "base.head"
end

local function refresh_speed_correction(chara)
   local count = chara:iter_body_parts(true):length()

   if count > 13 then
      chara.speed_correction = (count - 13) + 5
   else
      chara.speed_correction = 0
   end
end

function Skill.gain_random_body_part(chara, show_message)
   -- NOTE: is different in vanilla, checks for openness of slot?

   local body_part = get_random_body_part();
   chara:add_body_part(body_part)

   if show_message then
      Gui.mes_c("chara_status.gain_new_body_part",
                "Green",
                chara,
                I18N.get("ui.body_part." .. body_part))
   end

   refresh_speed_correction(chara)
end

function Skill.refresh_speed(chara)
   chara.current_speed = math.floor(chara:skill_level("elona.stat_speed") + math.clamp(100 - chara:calc("speed_correction"), 0, 100) / 100)

   chara.current_speed = math.max(chara.current_speed, 10)

   chara.speed_percentage_in_next_turn = 0
   local spd_perc = 0

   if not chara:is_player() then
      return
   end

   local has_mount = false
   if not has_mount then
      local nutrition = math.floor(chara:calc("nutrition") / 1000 * 1000)
      if nutrition < 1000 then
         spd_perc = spd_perc - 30
      end
      if nutrition < 2000 then
         spd_perc = spd_perc - 10
      end
      if chara.stamina < 0 then
         spd_perc = spd_perc - 30
      end
      if chara.stamina < 25 then
         spd_perc = spd_perc - 20
      end
      if chara.stamina < 50 then
         spd_perc = spd_perc - 10
      end
   end
   if chara.inventory_weight_type >= 3 then
      spd_perc = spd_perc - 50
   end
   if chara.inventory_weight_type == 2 then
      spd_perc = spd_perc - 30
   end
   if chara.inventory_weight_type == 1 then
      spd_perc = spd_perc - 10
   end

   local map = chara:current_map()
   if map and map:has_type({"world_map", "field"}) then
      local cargo_weight = chara:calc("cargo_weight")
      local max_cargo_weight = chara:calc("max_cargo_weight")
      if cargo_weight > max_cargo_weight then
         spd_perc = spd_perc - 25 + 25 * cargo_weight / (max_cargo_weight + 1)
      end
   end

   chara.speed_percentage_in_next_turn = spd_perc
end

function Skill.apply_speed_percentage(chara, next_turn)
   if next_turn then
      chara.speed_percentage = chara.speed_percentage_in_next_turn
   end

   local spd = math.floor(chara.current_speed * (100 + chara.speed_percentage) / 100)
   spd = math.max(spd, 10)

   return spd
end

function Skill.gain_level(chara, show_message)
   chara.experience = math.max(chara.experience - chara.required_experience, 0)
   chara.level = chara.level + 1

   if show_message then
      if chara:is_player() then
         Gui.mes_c("chara.gain_level.self", "Green", chara, chara.level)
      else
         Gui.mes_c("chara.gain_level.other", "Green", chara)
      end
   end

   local skill_bonus = 5 + (100 + chara:base_skill_level("elona.stat_learning") + 10) / (300 + chara.level * 15) + 1

   if chara:is_player() then
      if chara.level % 5 == 0 then
         if chara.max_level < chara.level and chara.level <= 50 then
            chara.aquirable_feat_count = chara.aquirable_feat_count + 1
         end
      end

      skill_bonus = skill_bonus + chara:trait_level("elona.extra_bonus_points")
   end

   chara.skill_bonus = chara.skill_bonus + skill_bonus
   chara.total_skill_bonus = chara.total_skill_bonus + skill_bonus

   if chara:has_trait("elona.extra_body_parts") then
      if chara.level < 37 and chara.level % 3 == 0 and chara.max_level < chara.level then
         Skill.gain_random_body_part(chara, true)
      end
   end

   if chara.max_level < chara.level then
      chara.max_level = chara.level
   end

   if not chara:is_allied() then
      Skill.grow_primary_skills(chara, show_message)
   end

   chara.required_experience = Skill.calc_required_experience(chara)
   chara:refresh()
end

function Skill.grow_primary_skills(chara)
   local function grow(skill)
      chara:mod_base_skill_level(skill, Rand.rnd(3), "add")
   end

   for _, stat in Skill.iter_stats() do
      grow(stat._id)
   end

   -- Grow some skills available on all characters (by default: evasion, martial arts, bow)
   local main_skills = data["base.skill"]:iter():filter(function(s) return s.is_main_skill end)

   for _, skill in main_skills:unwrap() do
      grow(skill._id)
   end
end

function Skill.calc_required_experience(chara)
   local lv = math.clamp(chara.level, 1, 200)
   return math.clamp(lv * (lv + 1) * (lv + 2) * (lv + 3) + 3000, 0, 100000000)
end

function Skill.impression_level(impression)
   if     impression < 10  then return 0
   elseif impression < 25  then return 1
   elseif impression < 40  then return 2
   elseif impression < 75  then return 3
   elseif impression < 100 then return 4
   elseif impression < 150 then return 5
   elseif impression < 200 then return 6
   elseif impression < 300 then return 7
   else                         return 8
   end
end

function Skill.modify_impression(chara, delta)
   delta = math.floor(delta)
   local level = Skill.impression_level(chara.impression)
   if delta >= 0 then
      delta = delta * 100 / (50 + level * level * level)
      if delta == 0 and level < Rand.rnd(10) then
         delta = 1
      end
   end

   chara.impression = chara.impression + delta
   local new_level = Skill.impression_level(chara.impression)
   if level > new_level then
      Gui.mes_c("chara.impression.lose", "Purple", chara, "ui.impression._" .. new_level)
   elseif new_level > level and chara:reaction_towards(Chara.player()) > 0 then
      Gui.mes_c("chara.impression.gain", "Green", chara, "ui.impression._" .. new_level)
   end
end

--
--
-- Events
--
--

local function refresh_max_inventory_weight(chara)
   local weight = chara:calc("inventory_weight")
   local mod = math.floor(weight * (100 - chara:trait_level("elona.weight_lifting") * 10 +
                                       chara:trait_level("elona.weight_lifting_2") * 20) / 100)
   chara:mod("inventory_weight", mod)

   chara:mod("max_inventory_weight",
             chara:skill_level("elona.stat_strength") * 500 +
                chara:skill_level("elona.stat_constitution") * 250 +
                chara:skill_level("elona.weight_lifting") * 2000 +
                45000)
end

Event.register("base.on_refresh_weight", "refresh max inventory weight", refresh_max_inventory_weight)

local function refresh_weight(chara)
   local weight = chara:calc("inventory_weight")
   local max_weight = chara:calc("max_inventory_weight")

   if weight > max_weight * 2 then
      chara.inventory_weight_type = 4 -- very overweight
   elseif weight > max_weight then
      chara.inventory_weight_type = 3 -- overweight
   elseif weight > max_weight / 4 * 3  then
      chara.inventory_weight_type = 2 -- very burdened
   elseif weight > max_weight / 2 then
      chara.inventory_weight_type = 1 -- burdened
   else
      chara.inventory_weight_type = 0 -- normal
   end

   Skill.refresh_speed(chara)
end

Event.register("base.on_refresh_weight", "apply weight type", refresh_weight)

local function calc_speed(chara)
   return Skill.apply_speed_percentage(chara, true)
end

Event.register("base.on_calc_speed", "calc speed", calc_speed)

return Skill
