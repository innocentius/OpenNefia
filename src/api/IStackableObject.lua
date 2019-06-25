local IOwned = require("api.IOwned")
local IMapObject = require("api.IMapObject")

local IStackableObject = interface("IStackableObject",
                                 {
                                    amount = "number",
                                    can_stack_with = "function",
                                 },
                                 {IOwned, IMapObject}
)

--- Separates some of this object from its stack. If `owned` is true,
--- also attempts to move the object into the original object's
--- location. If this fails, return nil. If unsuccessful, no state is
--- changed.
-- @tparam int amount
-- @tparam bool owned
-- @treturn IItem
-- @retval_ownership[owned=false] nil
-- @retval_ownership[owned=true] self.location
function IStackableObject:separate(amount, owned)
   amount = math.clamp(amount or 1, 0, self.amount)
   owned = owned or false

   if amount == 0 then
      return nil
   end

   if self.amount <= 1 or amount >= self.amount then
      return self
   end

   local separated = self:clone(owned)

   if separated == nil then
      return nil
   end

   separated.amount = amount
   self.amount = self.amount - amount
   assert(self.amount >= 1)

   return separated
end

--- Tries to move a given amount of this object to another location,
--- accounting for stacking. Returns the stacked object if successful,
--- nil otherwise. If unsuccessful, no state is changed.
-- @tparam int amount
-- @tparam ILocation where
-- @tparam[opt] int x
-- @tparam[opt] int y
-- @treturn[1] IItem
-- @treturn[2] nil
-- @retval_ownership self where
function IStackableObject:move_some(amount, where, x, y)
   local separated = self:separate(amount)

   if separated == nil then
      return nil
   end

   if not where:can_take_object(separated, x, y) then
      self.amount = self.amount + amount
      separated:remove_ownership()
      return nil
   end

   assert(where:take_object(separated, x, y))

   return separated
end

function IStackableObject:stack_with(other)
   assert(self._type == other._type)

   self.amount = self.amount + other.amount
   other.amount = 0
   other:remove_ownership()
end

function IStackableObject:can_stack_with(other)
   return self._type == other._type and self.uid ~= other.uid
end

--- Stacks this object with other objects in the same location that
--- can be stacked with. The logic to determine if one object can be
--- stacked with another is controlled by
--- IStackableObject:can_stack_with().
-- @treturn bool
function IStackableObject:stack()
   if not self.location then
      return false
   end

   local iter
   local did_stack = false

   -- HACK: really needs a uniform interface. type may need to be a
   -- required parameter.
   if self.location:is_positional() then
      iter = self.location:objects_at_pos(self._type, self.x, self.y)
   else
      iter = self.location:iter()
   end

   for _, other in iter:unwrap() do
      local can_stack, err = self:can_stack_with(other)
      if can_stack then
         self:stack_with(other)
         did_stack = true
      end
   end

   return did_stack
end

return IStackableObject
