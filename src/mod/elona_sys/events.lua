local Event = require("api.Event")
local I18N = require("api.I18N")
local Gui = require("api.Gui")
local Map = require("api.Map")
local Rand = require("api.Rand")
local Quest = require("mod.elona_sys.api.Quest")
local Chara = require("api.Chara")
local Role = require("mod.elona_sys.api.Role")
local Log = require("api.Log")
local Feat = require("api.Feat")

--
--
-- turn sequence events
--
--

-- local function proc_effects_turn_start(chara, params, result)
--    for effect_id, _ in pairs(chara.effects) do
--       local effect = data["base.effect"]:ensure(effect_id)
--       if effect.on_turn_start then
--          result = effect.on_turn_start(chara, params, result) or result
--       end
--    end
--    return result
-- end
--
-- Event.register("base.on_turn_start", "Proc effect on_turn_start", proc_effects_turn_start)

local function proc_effects_turn_end(chara, params, result)
   for effect_id, _ in pairs(chara.effects) do
      local effect = data["base.effect"]:ensure(effect_id)
      if effect.on_turn_end then
         result = effect.on_turn_end(chara, params, result) or result
      end
   end
   for effect_id, _ in pairs(chara.effects) do
      chara:add_effect_turns(effect_id, -1)
   end
   return result
end

Event.register("base.on_chara_turn_end", "Proc effect on_turn_end", proc_effects_turn_end)

local function update_awake_hours()
   local s = save.elona_sys
   local map = Map.current()
   if map:calc("is_world_map") then
      if Rand.one_in(3) then
         s.awake_hours = s.awake_hours + 1
      end
      if Rand.one_in(15) then
         Gui.mes("move global map awake hours")
         s.awake_hours = math.max(0, s.awake_hours - 3)
      end
   end
   if map:calc("adds_awake_hours") then
      s.awake_hours = s.awake_hours + 1
   end
end

Event.register("base.on_hour_passed", "Update awake hours", update_awake_hours)

local function init_save()
   local s = save.elona_sys
   s.awake_hours = 0
   s.npc_memory = { killed = {}, generated = {} }
   s.quest = {
      clients = {},
      towns = {},
      quests = {}
   }
   s.sidequest = {}
end

Event.register("base.on_init_save", "Init save", init_save)

local function init_map(map)
   local fallbacks = {
      adds_awake_hours = true
   }
   map:mod_base_with(fallbacks, "merge")
end

Event.register("base.on_build_map", "Init map", init_map)

local function show_element_text_damage(target, source, tense, element)
end

local function show_element_text_death(target, source, tense, element)
end

local function show_text_death(target, source, tense)
   local death_type = Rand.rnd(4)

   if tense == "ally" then
      Gui.mes_continue_sentence()

      if death_type == 0 then
         Gui.mes_c("death_by.chara.transformed_into_meat.active", "Red", target, source)
      elseif death_type == 1 then
         Gui.mes_c("death_by.chara.destroyed.active", "Red", target, source)
      elseif death_type == 2 then
         Gui.mes_c("death_by.chara.minced.active", "Red", target, source)
      elseif death_type == 3 then
         Gui.mes_c("death_by.chara.killed.active", "Red", target, source)
      end
   elseif tense == "enemy" then
      if death_type == 0 then
         Gui.mes_c("death_by.chara.transformed_into_meat.passive", "Red", target, source)
      elseif death_type == 1 then
         Gui.mes_c("death_by.chara.destroyed.passive", "Red", target, source)
      elseif death_type == 2 then
         Gui.mes_c("death_by.chara.minced.passive", "Red", target, source)
      elseif death_type == 3 then
         Gui.mes_c("death_by.chara.killed.passive", "Red", target, source)
      end
   end
end

local function show_damage_text(chara, weapon, target, damage_level, was_killed,
                                tense, no_attack_text, element, extra_attacks)
   if not Map.is_in_fov(target.x, target.y) then
      return
   end

   if extra_attacks > 0 then
      Gui.mes("damage.furthermore")
      Gui.mes_continue_sentence()
   end

   local skill = "elona.martial_arts" -- TODO

   if weapon then
      skill = weapon:calc("skill")
   end

   local source = chara

   if tense == "ally" and chara then
      if not no_attack_text then
         if weapon then
            -- TODO
            if skill == "elona.throwing" then
               Gui.mes("damage.weapon.attacks_throwing", chara, "damage.weapon." .. skill .. ".verb_and", target, weapon:build_name())
            else
               Gui.mes("damage.weapon.attacks_and", chara, "damage.weapon." .. skill .. ".verb_and", target)
            end
         else
            local melee = I18N.get("damage.melee._" .. chara:calc("melee_attack_type") .. ".enemy")
            Gui.mes("damage.weapon.attacks_unarmed_and", chara, melee, target)
         end
      end

      Gui.mes_continue_sentence()

      if was_killed then
         if element then
            show_element_text_death(target, source, tense, element)
         else
            show_text_death(target, source, tense)
         end
      else
         if element then
            show_element_text_damage(target, source, tense, element)
         else
            if damage_level == -1 then
               Gui.mes("damage.levels.scratch", target, chara)
            elseif damage_level == 0 then
               Gui.mes_c("damage.levels.slightly", "Orange", target, chara)
            elseif damage_level == 1 then
               Gui.mes_c("damage.levels.moderately", "Gold", target, chara)
            elseif damage_level == 2 then
               Gui.mes_c("damage.levels.severely", "Gold", target, chara)
            elseif damage_level >= 3 then
               Gui.mes_c("damage.levels.critically", "Red", target, chara)
            end
         end
      end
   else
      if not no_attack_text then
         if tense == "enemy" and chara then
            if weapon then
               local weapon_name = I18N.get_optional("damage.weapon." .. skill .. ".name")
               if weapon_name then
                  Gui.mes("damage.weapon.attacks_with", chara, "damage.weapon." .. skill .. ".verb", target, weapon_name)
               end
            else
               local melee = I18N.get("damage.melee._" .. chara:calc("melee_attack_type") .. ".ally")
               Gui.mes("damage.weapon.attacks_unarmed", chara, melee, target)
            end
         end
      end

      if was_killed then
         if element then
            show_element_text_death(target, source, tense, element)
         else
            show_text_death(target, source, tense)
         end
      else
         if target:is_in_fov() then
            if damage_level == 1 then
               Gui.mes_c("damage.reactions.screams", "Gold", target)
            elseif damage_level == 2 then
               Gui.mes_c("damage.reactions.writes_in_pain", "Pink", target)
            elseif damage_level >= 3 then
               Gui.mes_c("damage.reactions.is_severely_hurt", "Red", target)
            elseif damage_level == -2 then
               Gui.mes_c("damage.is_healed", "Blue", target)
            end
         end
      end
   end
end
local function get_damage_level(base_damage, damage, chara)
   local damage_level
   if base_damage < 0 then
      damage_level = -2
   elseif damage <= 0 then
      damage_level = -1
   else
      damage_level = math.floor(damage * 6 / chara:calc("max_hp"))
   end
   return damage_level
end
Event.register("base.on_damage_chara", "Damage text", function(chara, params)
                  local damage_level = get_damage_level(params.base_damage, params.damage, chara)
                  show_damage_text(params.attacker, params.weapon, chara, damage_level, false,
                                   params.message_tense, params.no_attack_text, params.element, params.extra_attacks)

                  -- If an event causes character death, switch to
                  -- passive tense or messages like "kills it. kills
                  -- it. " will print.
                  params.message_tense = "passive"
end)
Event.register("base.on_kill_chara", "Damage text", function(chara, params)
                  local damage_level = get_damage_level(params.base_damage, params.damage, chara)
                  show_damage_text(params.attacker, params.weapon, chara, damage_level, true,
                                   params.message_tense, params.no_attack_text, params.element, params.extra_attacks)
end)

local function register_quest_town(map, _, _)
   Quest.update_in_map(map)
end

Event.register("base.on_map_loaded_from_entrance", "register town as quest endpoint", register_quest_town)

Event.register("base.on_chara_killed", "Refresh sidequests (when chara killed)",
               function(chara)
                  local map = chara:current_map()
                  if map then
                     map:emit("elona_sys.on_quest_check")
                  end
               end)

Event.register("base.on_chara_vanquished", "Refresh sidequests (when chara vanquished)",
               function(chara)
                  local map = chara:current_map()
                  if map then
                     map:emit("elona_sys.on_quest_check")
                  end
               end)

Event.register("base.on_map_enter", "Refresh sidequests (when map entered)",
               function(map)
                  map:emit("elona_sys.on_quest_check")
end)


-- The following events are necessary to run on every object each time
-- a map is loaded because event callbacks are not serialized.

Event.register("base.on_item_instantiated", "Connect item events",
               function(item)
                  -- The reason there are boolean flags indicating if
                  -- an action can be taken ("can_eat", "can_open") is
                  -- because it makes it easier to temporarily disable
                  -- the action. Without this the check relies on
                  -- whether or not the event handler is present, and
                  -- it is difficult to preserve the state of event
                  -- handlers across serialization.
                  local actions = {
                     "use",
                     "eat",
                     "drink",
                     "read",
                     "zap",
                     "open",
                     "dip_source",
                     "throw"
                  }

                  for _, action in ipairs(actions) do
                     if item.proto["on_" .. action] then
                        item:connect_self("elona_sys.on_item_" .. action,
                                          "Item prototype on_" .. action .. " handler",
                                          item.proto["on_" .. action])
                     end
                     if item:has_event_handler("elona_sys.on_item_" .. action) then
                        item["can_" .. action] = true
                     end
                  end
end)

Event.register("base.on_item_instantiated", "Permit item actions",
               function(item)
                  if item:has_category("elona.container") then
                     item.can_open = true
                  end

                  if item:has_category("elona.food")
                     or item:has_category("elona.cargo_food")
                  then
                     item.can_eat = true
                  end

                  if item:has_category("elona.drink") then
                     item.can_throw = true
                  end
end)

local IItem = require("api.item.IItem")
Event.register("base.on_hotload_object", "reload events for item", function(obj)
                  if class.is_an(IItem, obj) then
                     obj:instantiate()
                  end
end)

local function print_feat_description(feat)
   local desc = feat.proto.description
   if type(desc) == "function" then
      desc = desc(feat)
   end
   Gui.mes(desc)
end

Event.register("base.on_feat_instantiated", "Connect feat events",
               function(feat)
                  if feat.proto.on_bash then
                     feat:connect_self("elona_sys.on_bash",
                                       "Feat prototype on_bash handler",
                                       feat.proto.on_bash)
                  end
                  if feat.proto.on_activate then
                     feat:connect_self("elona_sys.on_feat_activate",
                                       "Feat prototype on_activate handler",
                                       feat.proto.on_activate)
                  end
                  if feat.proto.on_search then
                     feat:connect_self("elona_sys.on_feat_search",
                                       "Feat prototype on_search handler",
                                       feat.proto.on_search)
                  end
                  if feat.proto.on_open then
                     feat:connect_self("elona_sys.on_feat_open",
                                       "Feat prototype on_open handler",
                                       feat.proto.on_open)
                  end
                  if feat.proto.on_close then
                     feat:connect_self("elona_sys.on_feat_close",
                                       "Feat prototype on_close handler",
                                       feat.proto.on_close)
                  end
                  if feat.proto.on_descend then
                     feat:connect_self("elona_sys.on_feat_descend",
                                       "Feat prototype on_descend handler",
                                       feat.proto.on_descend)
                  end
                  if feat.proto.on_ascend then
                     feat:connect_self("elona_sys.on_feat_ascend",
                                       "Feat prototype on_ascend handler",
                                       feat.proto.on_ascend)
                  end
                  if feat.proto.on_bumped_into then
                     feat:connect_self("elona_sys.on_feat_bumped_into",
                                       "Feat prototype on_bumped_into handler",
                                       feat.proto.on_bumped_into)
                  end
                  if feat.proto.on_stepped_on then
                     feat:connect_self("elona_sys.on_feat_stepped_on",
                                       "Feat prototype on_stepped_on handler",
                                       feat.proto.on_stepped_on)
                  end

                  if feat.proto.description then
                     feat:connect_self("elona_sys.on_feat_stepped_on",
                                       "Print feat message",
                                       print_feat_description)
                  end
               end)

local IFeat = require("api.feat.IFeat")
Event.register("base.on_hotload_object", "reload events for feat", function(obj)
                  if class.is_an(IFeat, obj) then
                     obj:instantiate()
                  end
end)

local function feat_bumped_into_handler(chara, p, result)
   for _, feat in Feat.at(p.x, p.y, chara:current_map()) do
      if feat:calc("is_solid") then
         feat:emit("elona_sys.on_feat_bumped_into", {chara=chara})
         result.blocked = true
      end
   end

   return result
end
Event.register("base.before_chara_moved", "Feat bumped into behavior", feat_bumped_into_handler)

local function feat_stepped_on_handler(chara, p, result)
   for _, feat in Feat.at(p.x, p.y, chara:current_map()) do
      if feat.on_stepped_on then
         feat:emit("elona_sys.on_feat_stepped_on", {chara=chara})
      end
   end

   return result
end
Event.register("base.on_chara_moved", "Feat stepped on behavior", feat_stepped_on_handler)

local function play_map_music(map)
   local music_id = map:emit("elona_sys.calc_map_music", {}, map.music)
   if data["base.music"][music_id] then
      Gui.play_music(music_id)
   end
end

Event.register("base.on_map_enter", "Play map music", play_map_music)

local PlayerLightDrawable = require("api.gui.PlayerLightDrawable")
local function add_player_light(player, params)
   if params.previous_player then
      local remove = {}
      for i, d in ipairs(params.previous_player.drawables) do
         if class.is_an(PlayerLightDrawable, d.drawable) then
            remove[#remove+1] = i
         end
      end
      table.remove_indices(params.previous_player.drawables, remove)
   end

   for _, d in ipairs(player.drawables) do
      if class.is_an(PlayerLightDrawable, d.drawable) then
         return
      end
   end

   table.insert(player.drawables, { drawable = PlayerLightDrawable:new() })
end

Event.register("base.on_set_player", "Add player light", add_player_light)

local function warn_quest_abandonment(_, params)
   local quest = save.elona_sys.instanced_quest
   if quest and quest.state ~= "completed" then
      Gui.mes("action.leave.abandoning_quest")
   end
end
Event.register("elona_sys.before_player_map_leave", "Warn about abandoning instanced quest", warn_quest_abandonment)

require("mod.elona_sys.api.Command") -- HACK
local function proc_quest_abandonment(_, params)
   local quest = save.elona_sys.instanced_quest
   if quest then
      if quest.state ~= "completed" then
         Quest.fail(quest)
      end
   end
   save.elona_sys.instanced_quest = nil
end
Event.register("elona_sys.hook_travel_to_map", "Warn about abandoning instanced quest", proc_quest_abandonment)



local function complete_quest(_, params, result)
   local quest = Quest.for_client(params.talk.speaker)
   if quest and quest.state == "completed" then
      result.choice = "elona.quest_giver:finish"
   end
   return result
end
Event.register("elona_sys.on_step_dialog", "If speaker has finished quest, complete it", complete_quest)