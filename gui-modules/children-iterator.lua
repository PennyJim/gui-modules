---Combine arrays
local function combine(arr1, arr2)
	return table.pack(table.unpack(arr1, 1, arr1.n), table.unpack(arr2))
end

---@class ChildrenIteratorState
---@field currentIndex integer?
---@field currentParent GuiElemModuleDef
---@field currentParentIndex integer?
---@field nextParents GuiElemModuleDef[]
---

---Iterates over a recursive array
---@param s ChildrenIteratorState
---@return GuiElemModuleDef? parent
---@return integer? index in the parent
---@return GuiElemModuleDef? child
local function iterator(s)
	local child
	repeat
		s.currentIndex, child = next(s.currentParent.children or {}, s.currentIndex)
		if not s.currentIndex then
			-- Set the current parent to the next in the list
			repeat -- ignore "n" though
				s.currentParentIndex, s.currentParent = next(s.nextParents, s.currentParentIndex)
			until s.currentParentIndex ~= "n"

			if not s.currentParent then
				return nil
			end

			-- Add the next children to the list
			local children = s.currentParent.children
			if children and children[1] then
				s.nextParents = combine(s.nextParents, children)
			elseif children then
				local new_length = (s.nextParents.n or #s.nextParents)+1
				s.nextParents[new_length] = children
	---@diagnostic disable-next-line: inject-field
				s.nextParents.n = new_length
			end
		end
	until s.currentIndex
	-- Return the next parent, index, and child
	return s.currentParent, s.currentIndex, child
end

---Returns an iterator for each child of the given element
---@param element GuiElemModuleDef
---@return fun(s:ChildrenIteratorState):GuiElemModuleDef?,integer?,GuiElemModuleDef?
---@return ChildrenIteratorState
local function allChildren(element)
	return iterator, {
		currentParent = {},
		nextParents = {element, n=1}
	} --[[@as ChildrenIteratorState]]
end

return allChildren