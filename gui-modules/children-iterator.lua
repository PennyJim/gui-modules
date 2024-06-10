---Puts every element of arr2 into arr1
---@param arr1 any[]
---@param arr2 any[]
local function combine(arr1, arr2)
	local n = arr1.n or #arr1
	for _, v in ipairs(arr2) do
		n = n + 1
		arr1[n] = v
	end
---@diagnostic disable-next-line: inject-field
	arr1.n = n
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
		repeat -- ignore non-array indexes
			s.currentIndex, child = next(s.currentChildren, s.currentIndex)
		until type(s.currentIndex) == "number" or type(s.currentIndex) == "nil"
		if not s.currentIndex then
			-- Set the current parent to the next in the list
			repeat -- ignore non-array indexes
				s.currentParentIndex, s.currentParent = next(s.nextParents, s.currentParentIndex)
			until type(s.currentParentIndex) == "number" or type(s.currentParentIndex) == "nil"

			if not s.currentParent then
				return nil -- If there's no more parents, then there's no more children either
			end

			-- Add the next children to the list
			s.currentChildren = getChildrenArray(s.currentParent)
			combine(s.nextParents, s.currentChildren)
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
	return iterator, {
---@diagnostic disable-next-line: missing-fields
		currentParent = {}, currentChildren = {},
		nextParents = {element, n=1}
	} --[[@as ChildrenIteratorState]]
end

return allChildren