
local mod = {
	id = "uiInspector",
	name = "Ui Inspector",
	version = "0.1.0",
	modApiVersion = "2.7.3dev",
	gameVersion = "1.2.83",
	isExtension = true,
	enabled = false,
}

function mod:init(options)
	local path = self.resourcePath

	local UiDebug = require(path.."UiDebug")
	local UiBrowser = require(path.."UiBrowser")
	local uiBrowser

	uiInspector = {
		highlightInspectedUi = true,
		inspectCustomTooltip = false,
		filterOutFunctions = true,
		filterOutTables = false,
		selectFocusedElement = false,
		highlightSelf = false,
	}

	uiBrowser = UiBrowser()
	uiInspector.browser = uiBrowser

	local function hasAncestor(self, ancestor)
		local parent = self

		while parent do
			if parent == ancestor then
				return true
			end
			parent = parent.parent
		end

		return false
	end

	local function getHoveredChild(self, root)
		if not hasAncestor(root.hoveredchild, uiBrowser) then
			return root.hoveredchild
		end
	end

	local function getDragHoveredChild(self, root)
		if not hasAncestor(root.draghoveredchild, uiBrowser) then
			return root.draghoveredchild
		end
	end

	local function getIndirectHoveredChild(self, root)
		local hoveredchild = root.hoveredchild
		if hasAncestor(hoveredchild, uiBrowser) then
			return hoveredchild.target
		end
	end

	modApi.events.onUiRootCreated:subscribe(function(screen, uiRoot)
		uiRoot.priorityUi:add(UiDebug(getHoveredChild, sdl.rgb(255, 100, 100)))
		uiRoot.priorityUi:add(UiDebug(getDragHoveredChild, sdl.rgb(255, 100, 100)))
		uiRoot.priorityUi:add(UiDebug(getIndirectHoveredChild, sdl.rgb(100, 255, 255)))
		uiRoot.priorityUi:add(uiBrowser)
		uiRoot.priorityUi:add(uiBrowser.clickDetector)
	end)
end

function mod:load(options, version)
	
end

return mod
