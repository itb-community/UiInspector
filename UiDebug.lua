
-- header
local path = GetParentPath(...)
local DecoOutline = require(path.."DecoOutline")
local DecoTextPlaque = require(path.."DecoTextPlaque")

-- defs
local FONT = sdlext.font("fonts/NunitoSans_Bold.ttf", 18)
local COLOR_HOVER = sdl.rgba(196,196,196,32)


local DecoHighlight = Class.inherit(DecoSolid)
function DecoHighlight:new(...)
	DecoSolid.new(self, ...)
end

function DecoHighlight:draw(screen, widget)
	if uiInspector.highlightInspectedUi then
		DecoSolid.draw(self, screen, widget)
	end
end


local UiDebug = Class.inherit(Ui)
function UiDebug:new(getWatchedElement, color)
	Ui.new(self)

	self._debugName = "UiDebug"
	self.translucent = true
	self.getWatchedElement = getWatchedElement
	self.decoText = DecoTextPlaque{
		font = FONT,
		textset = deco.textset(color, nil, nil, true),
		alignH = "left",
		alignV = "top_outside",
		padding = 8,
	}

	self:decorate{
		DecoOutline(color, 4),
		DecoHighlight(COLOR_HOVER),
		DecoAlign(-4,-4),
		self.decoText,
	}
end

function UiDebug:getWatchedElement(root)
	return nil
end

function UiDebug:relayout()
	local root = self.root
	local watchedElement = self:getWatchedElement(root)

	self.visible = watchedElement ~= nil

	if not self.visible then
		return
	end

	local debugName = watchedElement._debugName or "Missing debugName"

	if type(debugName) ~= 'string' then
		debugName = "Malformed debugName"
	end

	debugName = debugName.." - "..tostring(watchedElement)

	self.decoText:setsurface(debugName)

	self.screenx = watchedElement.screenx
	self.screeny = watchedElement.screeny
	self.w = watchedElement.w
	self.h = watchedElement.h

	Ui.relayout(self)
end

-- Add debug names for all derivatives of class Ui
for name, class in pairs(_G) do
	if type(class) == 'table' then
		if Class.isSubclassOf(class, Ui) then
			if class.__index._debugName == nil then
				class.__index._debugName = name
			end
		end
	end
end

return UiDebug
