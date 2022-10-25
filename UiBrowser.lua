
local UiBrowser
local UiOutputBox, UiOutputField
local UiBackButtonBox
local UiNavButtonBox, UiNavButton

local framecolor = sdl.rgba(13, 15, 23, 128)
local bordercolor = sdl.rgb(73, 92, 121, 128)
local buttoncolor = sdl.rgb(24, 28, 41, 128)


local function getCheckboxSurfaces()
	return
		deco.surfaces.checkboxChecked,
		deco.surfaces.checkboxUnchecked,
		deco.surfaces.checkboxHoveredChecked,
		deco.surfaces.checkboxHoveredUnchecked
end

local function onclicked_highlightMode(self, button)
	if self.checked then
		uiInspector.highlightMode = "indirectHighlight"
	else
		uiInspector.highlightMode = "directHighlight"
	end

	return true
end

local function onclicked_highlightInspectedUi(self, button)
	uiInspector.highlightInspectedUi = self.checked

	return true
end

local function onclicked_inspectCustomTooltip(self, button)
	uiInspector.inspectCustomTooltip = self.checked

	return true
end

local function onclicked_filterOutFunctions(self, button)
	uiInspector.filterOutFunctions = self.checked

	if uiInspector.filterOutFunctions then
		uiInspector.browser.outputBox:filterOut("function")
	end

	return true
end

local function onclicked_filterOutTables(self, button)
	uiInspector.filterOutTables = self.checked

	if uiInspector.filterOutTables then
		uiInspector.browser.outputBox:filterOut("table")
	end

	return true
end

function updateWidth(self, decoIndex, additionalWidth)
	local decoText = self.decorations[decoIndex]
	if decoText and decoText.surface then
		self:widthpx(decoText.surface:w() + self.padl + self.padr + additionalWidth)
	end

	return self
end


-- //////////////////////////////////////////////
UiBackButtonBox = Class.inherit(UiFlowLayout)
function UiBackButtonBox:new()
	UiFlowLayout.new(self)

	self._debugName = "UiBackButtonBox"
end

function UiBackButtonBox:addButton(inspectedObject)
	UiNavButton(inspectedObject)
		:settooltip("Click to return to this ui element")
		:updateWidth(2, 12):heightpx(40)
		:addTo(self)
end

function UiBackButtonBox:clear()
	local children = self.children
	for i = #children, 1, -1 do
		children[i]:detach()
	end
end

function UiBackButtonBox:update()
	local navCurrent = uiInspector.browser.navCurrent

	if navCurrent == nil then
		self:clear()
		return
	end

	local parent = navCurrent
	local parents = {}

	-- Build list of all ancestors
	while parent do
		parents[#parents+1] = parent
		parent = parent.parent
	end

	parents = reverse_table(parents)

	-- Iterate ancestors to verify that
	-- our back buttons match them
	local children = self.children
	for i, parent in ipairs(parents) do
		local child = children[i]

		if true
			and child ~= nil
			and child.target ~= parent
		then
			-- Target mismatch -> detach tail
			for i = #children, i, -1 do
				children[i]:detach()
			end
		end

		if children[i] == nil then
			-- Build new back buttons for
			-- remaining ancestors
			for i = i, #parents do
				self:addButton(parents[i])
			end

			break
		end
	end

	-- Detach superrfluous back buttons
	for i = #children, #parents + 1, -1 do
		children[i]:detach()
	end
end


-- //////////////////////////////////////////////
UiNavButtonBox = Class.inherit(UiBoxLayout)
function UiNavButtonBox:new()
	UiBoxLayout.new(self)

	self._debugName = "UiNavButtonBox"
end

function UiNavButtonBox:clear(exceptions)
	local children = self.children

	for i = #children, 1, -1 do
		local child = children[i]
		local id = child.target

		if false
			or exceptions == nil
			or exceptions[id] == nil
		then
			child:detach()
		end
	end
end

function UiNavButtonBox:inspectObject(uiInstance)
	local exceptions = {}
	for _, child in ipairs(uiInstance.children) do
		exceptions[child] = true
	end

	local targets = {}
	for _, button in ipairs(self.children) do
		targets[button.target] = true
	end

	self:clear(exceptions)

	for _, child in ipairs(uiInstance.children) do
		if targets[child] == nil then
			UiNavButton(child)
				:settooltip("Click to inspect this ui element")
				:width(1):heightpx(40)
				:addTo(self)
		end
	end
end


-- //////////////////////////////////////////////
UiNavButton = Class.inherit(Ui)
function UiNavButton:new(target)
	Assert.True(target ~= nil)

	Ui.new(self)

	self._debugName = "UiOutputBox"
	self.target = target

	self:clip()
		:decorate{
			DecoButton(framecolor, bordercolor),
			DecoText(target._debugName)
		}

	self.updateWidth = updateWidth
end

function UiNavButton:onclicked(button)
	uiInspector.browser.navCurrent = self.target
	uiInspector.browser.backButtons:update()

	return true
end


-- //////////////////////////////////////////////
UiOutputBox = Class.inherit(UiBoxLayout)
function UiOutputBox:new()
	UiBoxLayout.new(self)

	self._debugName = "UiOutputBox"
	self.inspectedObject = nil
	self.inspectedFields = {}
end

function UiOutputBox:insertSort(key, value)
	local children = self.children
	local function getValue(i)
		local child = children[i]
		return child and child.key or tostring(INT_MAX)
	end

	local index = BinarySearch(key, 1, #children + 1, getValue, "up")
	local obj = UiOutputField(key, value)
		:width(1):heightpx(40)

	self:add(obj, index)
end

function UiOutputBox:remove(child)
	self.inspectedFields[child.key] = nil
	UiBoxLayout.remove(self, child)
end

function UiOutputBox:clear()
	local children = self.children

	for i = #children, 1, -1 do
		children[i]:detach()
	end

	self.inspectedObject = nil

	-- This table should be empty now
	Assert.True(next(self.inspectedFields) == nil)
end

function UiOutputBox:filterOut(filterType)
	local navCurrent = uiInspector.browser.navCurrent

	if navCurrent == nil then
		return
	end

	local children = self.children
	for i = #children, 1, -1 do
		local child = children[i]
		if type(navCurrent[child.key]) == filterType then
			child:detach()
		end
	end
end

function UiOutputBox:inspectObject(uiInstance)
	if uiInstance ~= self.inspectedObject then
		self:clear()
		self.inspectedObject = uiInstance
	end

	local filterOutFunctions = uiInspector.filterOutFunctions
	local filterOutTables = uiInspector.filterOutTables
	local fields = self.inspectedFields
	local newFields = {}

	while(uiInstance) do
		for _,instance in ipairs{uiInstance, uiInstance.__index} do
			if instance then
				for k,v in pairs(instance) do
					if true
						and fields[k] == nil
						and k:find("^__") == nil
						and (filterOutFunctions == false or type(v) ~= "function")
						and (filterOutTables == false or type(v) ~= "table")
					then
						fields[k] = v
						newFields[k] = v
					end
				end
			end
		end
		uiInstance = uiInstance.__super
	end

	for key, value in pairs(newFields) do
		self:insertSort(key, value)
	end
end

-- //////////////////////////////////////////////
UiOutputField = Class.inherit(UiInputField)
function UiOutputField:new(key, value)
	UiInputField.new(self)

	self._debugName = "UiInputField"
	self.key = key

	self:clip()
		:decorate{
			DecoFrame(framecolor),
			DecoText(key),
			DecoInputField{
				alignH = "right",
				alignV = "center",
				offsetX = -5,
			},
		}
end

local function getOutputTooltip(valueType)
	if false
		or valueType == "number"
		or valueType == "string"
		or valueType == "boolean"
	then
		return
			"Warning: editing "..valueType.."s may cause unexpected errors or crashes",
			"Click to edit "..valueType,
			true

	elseif false
		or valueType == "userdata"
		or valueType == "function"
		or valueType == "table"
	then
		return
			valueType.." values may not be edited",
			"Protected type",
			true
	else
		return
			"This value may not be edited",
			"Unknown type",
			true
	end
end

function UiOutputField:relayout()
	local value = uiInspector.browser.navCurrent[self.key]
	local valueType = type(value)
	local stringifiedValue = tostring(value)
	local editable = false
		or valueType == "number"
		or valueType == "string"
		or valueType == "boolean"

	if true
		and self.focused ~= true
		and self.textfield ~= stringifiedValue
	then
		self:setText(stringifiedValue)
			:setVar("editable", editable)
			:settooltip(getOutputTooltip(valueType))
	end

	UiInputField.relayout(self)
end

function UiOutputField:onEnter()
	local key = self.key
	local input = self.textfield
	local navCurrent = uiInspector.browser.navCurrent
	local currentValue = navCurrent[key]
	local currentValueType = type(currentValue)

	local inputAsNumber = tonumber(input)
	local inputAsString = tostring(input)
	local inputAsBoolean = tostring(input):lower()

	if currentValueType == "number" and type(inputAsNumber) == "number" then
		navCurrent[key] = inputAsNumber
	elseif currentValueType == "string" and type(inputAsString) == "string" then
		navCurrent[key] = inputAsString
	elseif currentValueType == "boolean" and inputAsBoolean == "true" or inputAsBoolean == "false" then
		navCurrent[key] = inputAsBoolean
	end

	UiInputField.onEnter(self)
end


-- //////////////////////////////////////////////
UiBrowser = Class.inherit(Ui)
function UiBrowser:new()
	Ui.new(self)

	self._debugName = "UiBrowser"
	self.navCurrent = nil
	self.header = Ui()
	self.navButtons = UiNavButtonBox()
	self.backButtons = UiBackButtonBox()
	self.outputBox = UiOutputBox()

	self
		:sizepx(500,500)
		:decorate{ DecoFrame(framecolor, nil, 5) }
		:registerDragResize(5, 500)
		:beginUi(UiWeightLayout)
			:size(1,1)
			:setVar("translucent", true)
			-- Draggable Header
			:beginUi(self.header)
				:width(1):heightpx(40)
				:padding(0)
				:setVar("translucent", true)
				:decorate{
					DecoSolid(buttoncolor),
					DecoText(
						"Ui Inspector",
						deco.uifont.title.font,
						deco.uifont.title.set
					)
				}
			:endUi()
			-- Back Buttons
			:beginUi(self.backButtons)
				:width(1):heightpx(0):clip()
				:dynamicResize(true)
				:orientation(modApi.constants.ORIENTATION_HORIZONTAL)
				:vgap(10):hgap(10)
				:padding(10)
			:endUi()
			:orientation(modApi.constants.ORIENTATION_VERTICAL)
			-- Main Window
			:beginUi(UiWeightLayout)
				:size(1,1)
				:orientation(modApi.constants.ORIENTATION_HORIZONTAL)
				-- Left scrollarea
				:beginUi(UiScrollArea)
					:size(0.2,1)
					-- navButtons
					:beginUi(self.navButtons)
						:size(1,1)
						:vgap(4)
					:endUi()
				:endUi()
				-- Right scrollarea
				:beginUi(UiScrollArea)
					:size(0.8,1)
					:beginUi(self.outputBox)
						:size(1,1)
						:vgap(4)
					:endUi()
				:endUi()
			:endUi()
			-- Bottom bar - Config buttons
			:beginUi(UiFlowLayout)
				:width(1):heightpx(0):clip()
				:dynamicResize(true)
				:hgap(20):vgap(20)
				:padding(10)
				:orientation(modApi.constants.ORIENTATION_HORIZONTAL)
				:beginUi(UiCheckbox)
					:heightpx(40)
					:setVar("onclicked", onclicked_highlightMode)
					:setVar("checked", uiInspector.highlightMode)
					:settooltip("Checked: Highlight the target of objects under the mouse cursor\nUnchecked: Highlight objects under the mouse cursor")
					:decorate{
						DecoButton(framecolor, bordercolor),
						DecoText("Hover Mode"),
						DecoAnchor("right"),
						DecoAlign(-40),
						DecoCheckbox(getCheckboxSurfaces()),
					}
					:format(updateWidth, 2, 52)
				:endUi()
				:beginUi(UiCheckbox)
					:heightpx(40)
					:setVar("onclicked", onclicked_highlightInspectedUi)
					:setVar("checked", uiInspector.highlightInspectedUi)
					:settooltip("Highlight hovered ui objects")
					:decorate{
						DecoButton(framecolor, bordercolor),
						DecoText("Highlight Inspected Ui"),
						DecoAnchor("right"),
						DecoAlign(-40),
						DecoCheckbox(getCheckboxSurfaces()),
					}
					:format(updateWidth, 2, 52)
				:endUi()
				:beginUi(UiCheckbox)
					:heightpx(40)
					:setVar("onclicked", onclicked_inspectCustomTooltip)
					:setVar("checked", uiInspector.inspectCustomTooltip)
					:settooltip("Automatically inspect last seen custom tooltip")
					:decorate{
						DecoButton(framecolor, bordercolor),
						DecoText("Inspect Custom Tooltip"),
						DecoAnchor("right"),
						DecoAlign(-40),
						DecoCheckbox(getCheckboxSurfaces()),
					}
					:format(updateWidth, 2, 52)
				:endUi()
				:beginUi(UiCheckbox)
					:heightpx(40)
					:setVar("onclicked", onclicked_filterOutFunctions)
					:setVar("checked", uiInspector.filterOutFunctions)
					:settooltip("Filter out functions from output")
					:decorate{
						DecoButton(framecolor, bordercolor),
						DecoText("Filter out functions"),
						DecoAnchor("right"),
						DecoAlign(-40),
						DecoCheckbox(getCheckboxSurfaces()),
					}
					:format(updateWidth, 2, 52)
				:endUi()
				:beginUi(UiCheckbox)
					:heightpx(40)
					:setVar("onclicked", onclicked_filterOutTables)
					:setVar("checked", uiInspector.filterOutTables)
					:settooltip("Filter out tables from output")
					:decorate{
						DecoButton(framecolor, bordercolor),
						DecoText("Filter out tables"),
						DecoAnchor("right"),
						DecoAlign(-40),
						DecoCheckbox(getCheckboxSurfaces()),
					}
					:format(updateWidth, 2, 52)
				:endUi()
			:endUi()
		:endUi()
end

function UiBrowser:updateState()
	local mx, my = sdl.mouse.x(), sdl.mouse.y()

	-- Make object both draggable and resizable
	if true
		and not self.dragResizing
		and not self.dragMoving
	then
		local isEdge = UiDraggable.isEdge(self, mx, my, self.__resizeHandle)

		if self.header.containsMouse then
			self:settooltip("Click and drag to move")
			self.dragMovable = true
			self.dragResizable = false
			self.canDragResize = false
		elseif isEdge then
			self:settooltip("Click and drag to resize")
			self.dragMovable = false
			self.dragResizable = true
			self.canDragResize = true
		else
			self:settooltip()
			self.dragMovable = false
			self.dragResizable = false
			self.canDragResize = false
		end
	end

	Ui.updateState(self)
end

function UiBrowser:inspectObject(inspectedObject)
	self.navCurrent = inspectedObject
	self.backButtons:update()
end

function UiBrowser:relayout()
	if uiInspector.inspectCustomTooltip then
		local tooltipManager = sdlext.getUiRoot().tooltipUi
		if tooltipManager.currentTooltip ~= tooltipManager.standardTooltip then
			self:inspectObject(tooltipManager.currentTooltip)
		end
	elseif false
		or self.navCurrent == nil
		or self.navCurrent.root == nil
	then
		self:inspectObject(sdlext.getUiRoot())
	end

	self.navButtons:inspectObject(self.navCurrent)
	self.outputBox:inspectObject(self.navCurrent)

	Ui.relayout(self)
end

return UiBrowser
