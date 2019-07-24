local Rand = require("api.Rand")
local Resolver = require("api.Resolver")

local function calc_potential(skill, level, knows_skill)
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

local function calc_decayed_potential(base_potential, chara_level)
   if chara_level <= 1 then
      return base_potential
   end

   return math.floor(math.exp(math.log(0.9) * chara_level) * base_potential)
end

local init_skill = function(self, params)
   local my_skill = params.chara:calc("skills")[self.skill] or { level = self.level or 0, potential = 0 }

   local potential
   local level
   local sk = data["base.skill"]:ensure(self.skill)

   if sk.calc_initial_potential then
      potential = sk.calc_initial_potential(self.level, params.chara)
   else
      potential = calc_potential(sk, self.level, my_skill.level > 0)
   end
   if sk.calc_initial_level then
      level = sk.calc_initial_level(self.level, params.chara)
   else
      level = math.floor(potential * potential * params.chara.level / 45000 + my_skill.level + params.chara.level / 3)
   end

   potential = calc_decayed_potential(potential, params.chara.level)

   if sk.calc_final then
      local t = sk.calc_final(self.level, params.chara) or {}
      level = t.level or level
      potential = t.potential or potential
   end

   potential = math.max(1, potential)

   if my_skill.level + level > 2000 then
      level = 2000 - my_skill.level
   end

   level = math.clamp(level, 0, 2000)

   return {
      __method = "add",
      __value = {
         level = my_skill.level + level,
         potential = my_skill.potential + potential
      }
   }
end

data:add {
   _type = "base.resolver",
   _id = "skill",

   ordering = 300000,
   method = "add",
   invariants = { skill = "number", level = "number", },
   params     = { chara = "IChara", },
   resolve    = init_skill,
}


local init_skill_list = function(self, params)
   self.resolver = "elona.skill"

   local skills = {}

   for skill_id, level in pairs(self.skills) do
      skills[skill_id] = Resolver.run(self.resolver, { skill = skill_id, level = level }, { chara = params.chara })
   end

   return skills
end

data:add {
   _type = "base.resolver",
   _id = "skills",

   ordering = 300000,
   method = "add",
   invariants = { skills = "table", resolver = "string", },
   params     = { chara = "IChara", },
   resolve    = init_skill_list,
}

data:add {
   _type = "base.resolver",
   _id = "gender",

   ordering = 300000,
   method = "set",
   invariants = { male_ratio = "number" },
   params = { chara = "IChara" },

   resolve = function(self)
      return (Rand.percent_chance(self.male_ratio) and "male") or "female"
   end
}

data:add {
   _type = "base.resolver",
   _id = "by_gender",

   ordering = 310000,
   method = "set",
   invariants = { male = "any", female = "any" },
   params = { chara = "IChara" },

   resolve = function(self, params)
      return self[params.chara.gender or "female"]
   end
}

data:add {
   _type = "base.resolver",
   _id = "item_count",

   ordering = 300000,
   method = "set",
   invariants = { count = "number" },

   resolve = function(self)
      return self.count - Rand.rnd(self.count) + Rand.rnd(self.count)
   end
}

data:add {
   _type = "base.resolver",
   _id = "music_disc_id",

   ordering = 300000,
   method = "set",

   resolve = function()
      return 12
   end
}

local base_resolvers = {
   skills = "elona.skills",
}

data:add {
   _type = "base.resolver",
   _id = "race",

   ordering = 100000,
   method = "add",
   invariants = { race = "string" },
   params = { chara = "table" },

   resolve = function(self, params)
      local race = data["base.race"][self.race or params.chara.race or ""]
      if not race then
         return {}
      end
      local copy_to_chara = table.deepcopy(race.copy_to_chara)
      if race.base then
         for k, v in pairs(race.base) do
            local resolver = base_resolvers[k]
            if resolver then
               copy_to_chara[k] = Resolver.run(base_resolvers[k], race.base, params)
            end
         end
      end
      return Resolver.resolve(copy_to_chara, params)
   end
}

data:add {
   _type = "base.resolver",
   _id = "class",

   ordering = 200000,
   method = "add",
   invariants = { class = "string" },
   params = { chara = "table" },

   resolve = function(self, params)
      local class = data["base.class"][self.class or params.chara.class or ""]
      if not class then
         return {}
      end
      local copy_to_chara = table.deepcopy(class.copy_to_chara)
      if class.base then
         for k, v in pairs(class.base) do
            local resolver = base_resolvers[k]
            if resolver then
               copy_to_chara[k] = Resolver.run(base_resolvers[k], class.base, params)
            end
         end
      end
      return Resolver.resolve(copy_to_chara, params)
   end
}
