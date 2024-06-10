---Combine arrays
local function combine(arr1, arr2)
	return table.pack(table.unpack(arr1, 1, arr1.n), table.unpack(arr2))
end

---Returns the array of children, or an empty one if not found
---@param element GuiElemModuleDef
---@return GuiElemModuleDef[]
local function getChildrenArray(element)
	local children = element.children
	if children and children[1] then
		return children
	elseif children then
		return {children}
	else
		return element
	end
end

---@class ChildrenIteratorState
---@field currentIndex integer?
---@field currentChildren GuiElemModuleDef[]
---@field currentParent GuiElemModuleDef
---@field currentParentIndex integer?
---@field nextParents GuiElemModuleDef[]
---

---Iterates over GuiElemModuleDef, returning each child
---@param s ChildrenIteratorState
---@return GuiElemModuleDef[]? children the array the child is in
---@return integer? index where in that array the child is
---@return GuiElemModuleDef? child
local function iterator(s)
	local child
	repeat
		s.currentIndex, child = next(s.currentChildren, s.currentIndex)
		if not s.currentIndex then
			-- Set the current parent to the next in the list
			repeat -- ignore non-array indexes
				s.currentParentIndex, s.currentParent = next(s.nextParents, s.currentParentIndex)
			until type(s.currentParentIndex) == "number"

			if not s.currentParent then
				return nil -- If there's no more parents, then there's no more children either
			end

			-- Add the next children to the list
			s.currentChildren = getChildrenArray(s.currentParent)
			s.nextParents = combine(s.nextParents, s.currentChildren)
		end
	until s.currentIndex
	-- Return the next parent, index, and child
	return s.currentChildren, s.currentIndex, child
end

---Returns an iterator for each child of the given element.
---The iterator returns the `children` array the child was in,
---the `index` the child was at, and the `child` itself
---@param element GuiElemModuleDef|GuiElemModuleDef[]
---@return fun(s:ChildrenIteratorState):GuiElemModuleDef[]?,integer?,GuiElemModuleDef?
---@return ChildrenIteratorState
local function allChildren(element)
	local parents
	if element.type then
		parents = {element, n=1}
	else
		parents = {element, n=#element}
	end
	return iterator, {
---@diagnostic disable-next-line: missing-fields
		currentParent = {}, currentChildren = {},
		nextParents = {element, n=1}
	} --[[@as ChildrenIteratorState]]
end

return allChildren