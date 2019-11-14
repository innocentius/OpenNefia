local mod = require("internal.mod")
local fs = require("util.fs")

local i18n = {}
i18n.db = {}

local reify_one
reify_one = function(_db, item, key)
   if type(item) == "string" or type(item) == "function" then
      _db[key] = item
   elseif type(item) == "table" then
      for k, v in pairs(item) do
         local next_key
         if key == "" then
            next_key = k
         else
            next_key = key .. "." .. k
         end
         reify_one(_db, v, next_key)
      end
   else
      error("unknown type: " .. key)
   end
end

local load_translations
load_translations = function(path, merged)
   for _, file in fs.iter_directory_items(path) do
      local path = fs.join(path, file)
      if fs.is_file(path) and fs.extension_part(path) == "lua" then
         local chunk, err = loadfile(path)

         if chunk == nil then
            error("Error loading translations: " .. err)
         end

         setfenv(chunk, i18n.env)

         local ok, result = xpcall(chunk, function(err) return debug.traceback(err, 2) end)

         if not ok then
            error("Error loading translations: " .. result)
         end
         if type(result) ~= "table" then
            error("Error loading translations: returned type not a table (" .. path .. ")")
         end

         reify_one(merged, result, "")
      end
   end
end


function i18n.switch_language(lang, force)
   i18n.language = lang
   i18n.env = require("internal.i18n.env." .. lang)

   if i18n.db[lang] == nil or force then
      i18n.db[lang] = {}
   end

   for _, mod in mod.iter_loaded() do
      local path = fs.join(mod.root_path, "locale")

      if fs.is_directory(path) then
         local path = fs.join(path, lang)
         if fs.is_directory(path) then
            load_translations(path, i18n.db[lang])
         end
      end
   end
end

function i18n.get_language()
   return i18n.language
end

function i18n.get(key, ...)
   local entry = i18n.db[i18n.language][key]
   if not entry then
      return nil
   end

   if type(entry) == "string" then
      return entry
   elseif type(entry) == "function" then
      local success, result = pcall(entry, ...)
      if not success then
         return ("<error: %s [%s]>"):format(result, key)
      end
      return result
   end

   return nil
end

return i18n
