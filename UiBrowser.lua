
local framecolor = sdl.rgba(13, 15, 23, 128)
local bordercolor = sdl.rgb(73, 92, 121, 128)
local buildNavButton

local function onclicked_debugMode(self, button)
	if self.checked then
		uiInspector.highlightMode = "indirectHighlight"
	else
		uiInspector.highlightMode = "directHighlight"
	end

	return true
end

local function onclicked_selectNode(self, button)
	local backButtons = uiInspector.browser.backButtons

	if self.parent == backButtons then
		for i = #backButtons.children, 1, -1 do
			local child = backButtons.children[i]
			child:detach()

			if child == self then
				break
			end
		end
	else
		backButtons
			:beginUi(buildNavButton(uiInspector.browser.navCurrent))
				:sizepx(100, 40)
			:endUi()
	end

	uiInspector.browser.navCurrent = self.target

	return true
end

function buildNavButton(target)
	return Ui()
		:clip()
		:setVar("target", target)
		:setVar("onclicked", onclicked_selectNode)
		:decorate{
			DecoButton(framecolor, bordercolor),
			DecoText(target._debugName)
		}
end

local function inputOnEnter(self)
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

local function relayoutOutputField(self)
	local currentValue = tostring(uiInspector.browser.navCurrent[self.key])

	if true
		and self.focused ~= true
		and self.textfield ~= currentValue
	then
		self:setText(currentValue)
	end

	UiInputField.relayout(self)
end

local UiBrowser = Class.inherit(Ui)
function UiBrowser:new()
	Ui.new(self)

	self._debugName = "UiBrowser"
	self.navCurrent = nil
	self.navButtons = UiBoxLayout()
	self.backButtons = UiFlowLayout()
	self.outputFields = UiBoxLayout()

	function self.outputFields:insertSort(key, obj)
		local function getValue(i)
			return self.children[i].key
		end

		local index = BinarySearch(key, 1, #self.children, getValue, "up")
		self:add(obj, index)
	end

	self
		:sizepx(500,500)
		:decorate{ DecoFrame(framecolor) }
		:padding(5)
		:registerDragResize(10, 100)
		:beginUi(UiWeightLayout)
			:size(1,1)
			-- Header
			:beginUi()
				:width(1):heightpx(120)
				:beginUi(self.backButtons)
					:size(1,1)
					:orientation(modApi.constants.ORIENTATION_HORIZONTAL)
					:vgap(10):hgap(10)
					:padding(10)
				:endUi()
			:endUi()
			:orientation(modApi.constants.ORIENTATION_VERTICAL)
			-- Main Window
			:beginUi(UiWeightLayout)
				:size(1,1)
				:orientation(modApi.constants.ORIENTATION_HORIZONTAL)
				-- Left scrollarea
				:beginUi(UiScrollArea)
					:size(0.5,1)
					-- navButtons
					:beginUi(self.navButtons)
						:size(1,1)
						:vgap(4)
					:endUi()
				:endUi()
				-- Right scrollarea
				:beginUi(UiScrollArea)
					:size(0.5,1)
					:beginUi(self.outputFields)
						:size(1,1)
						:vgap(4)
						:setVar("items", {})
					:endUi()
				:endUi()
			:endUi()
			-- Bottom bar
			:beginUi()
				:width(1):heightpx(120)
				-- Config buttons
				:beginUi(UiFlowLayout)
					:size(1,1)
					:hgap(20):vgap(20)
					:padding(10)
					:orientation(modApi.constants.ORIENTATION_HORIZONTAL)
					:beginUi(UiCheckbox)
						:sizepx(160,40)
						:setVar("onclicked", onclicked_debugMode)
						:setVar("checked", true)
						:decorate{
							DecoButton(framecolor, bordercolor),
							DecoText("Hover Mode"),
							DecoAnchor("right"),
							DecoAlign(-40),
							DecoCheckbox(
								deco.surfaces.checkboxChecked,
								deco.surfaces.checkboxUnchecked,
								deco.surfaces.checkboxHoveredChecked,
								deco.surfaces.checkboxHoveredUnchecked
							),
						}
					:endUi()
				:endUi()
			:endUi()
		:endUi()

	self:update()
end

function UiBrowser:detachButtons(exceptions)
	local buttons = self.navButtons.children

	if exceptions == nil then
		exceptions = {}
	end

	for i = #buttons, 1, -1 do
		local button = buttons[i]
		local id = button.target

		if not exceptions[id] then
			button:detach()
		end
	end
end

function UiBrowser:detachOutput()
	local fields = self.outputFields.children

	for i = #fields, 1, -1 do
		fields[i]:detach()
	end

	clear_table(self.outputFields.items)
end

function UiBrowser:updateLeft()
	local childList = self.navCurrent.children
	local exceptions = {}
	for i, child in ipairs(childList) do
		exceptions[child] = i
	end

	local buttonList = self.navButtons.children
	local buttons = {}
	for i, button in ipairs(buttonList) do
		buttons[button.target] = i
	end

	self:detachButtons(exceptions)

	for i, child in ipairs(childList) do
		if not buttons[child] then
			self.navButtons
				:beginUi(buildNavButton(child))
					:width(1):heightpx(40)
				:endUi()
		end
	end
end

function UiBrowser:updateRight()
	local instance = self.navCurrent
	local fields = {}
	local output = self.outputFields.items

	while(instance) do
		for k,v in pairs(instance) do
			if true
				and fields[k] == nil
				and output[k] == nil
				and k:find("^__") == nil
			then
				fields[k] = v
			end
		end
		for k,v in pairs(instance.__index) do
			if true
				and fields[k] == nil
				and output[k] == nil
				and k:find("^__") == nil
			then
				fields[k] = v
			end
		end
		instance = instance.__super
	end

	for key, value in pairs(fields) do
		output[key] = true
		self.outputFields:insertSort(key,
			UiInputField()
				:width(1):heightpx(40)
				:clip()
				:setText(tostring(value))
				:setVar("key", key)
				:setVar("relayout", relayoutOutputField)
				:setVar("onEnter", inputOnEnter)
				:decorate{
					DecoFrame(framecolor),
					DecoText(key),
					DecoInputField{
						alignH = "right",
						alignV = "center",
						offsetX = -5,
					},
				}
		)
	end
end

function UiBrowser:update()
	if false
		or self.navCurrent == nil
		or self.navCurrent ~= self.navPrev
	then
		self:detachButtons()
		self:detachOutput()
		self.navPrev = self.navCurrent
		return
	end

	self:updateLeft()
	self:updateRight()
end

function UiBrowser:relayout()
	self:update()
	Ui.relayout(self)
end

return UiBrowser
