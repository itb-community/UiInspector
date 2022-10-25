
local mod = {
	id = "uiInspector",
	name = "Ui Inspector",
	version = "0.1.0",
}

function mod:init(options)
	local path = self.resourcePath

	local UiDebug = require(path.."UiDebug")
	local UiBrowser = require(path.."UiBrowser")
	local uiBrowser

	uiInspector = {
		highlightMode = "indirectHighlight",
		highlightInspectedUi = false,
		inspectCustomTooltip = false,
		filterOutFunctions = true,
		filterOutTables = false,
	}

	uiBrowser = UiBrowser()
	uiInspector.browser = uiBrowser

	local function getHoveredChild(self, root)
		if uiInspector.highlightMode == "directHighlight" then
			return root.hoveredchild
		end
	end

	local function getDragHoveredChild(self, root)
		if uiInspector.highlightMode == "directHighlight" then
			return root.draghoveredchild
		end
	end

	local function getIndirectHoveredChild(self, root)
		if uiInspector.highlightMode == "indirectHighlight" then
			local hoveredchild = root.hoveredchild
			if hoveredchild then
				return hoveredchild.target
			end
		end
	end

	modApi.events.onUiRootCreated:subscribe(function(screen, uiRoot)
		uiRoot.priorityUi:add(UiDebug(getHoveredChild, sdl.rgb(255, 100, 100)))
		uiRoot.priorityUi:add(UiDebug(getDragHoveredChild, sdl.rgb(255, 100, 100)))
		uiRoot.priorityUi:add(UiDebug(getIndirectHoveredChild, sdl.rgb(100, 255, 255)))
		uiRoot.priorityUi:add(uiBrowser)
	end)
end

function mod:load(options, version)
	
end

return mod
