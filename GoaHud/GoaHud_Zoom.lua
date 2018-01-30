-- GoaHud_Zoom made by GoaLitiuM
--
-- Smooth zoom widget
--

require "base/internal/ui/reflexcore"

SENSITIVITY_DISABLED = 1
SENSITIVITY_MONITOR_DISTANCE = 2
SENSITIVITY_VIEWSPEED = 3

local SENSITIVITY_NAMES =
{
	"Disabled (360 Distance)",
	"Monitor Distance",
	"Viewspeed",
}

GoaHud_Zoom =
{
	enabled = true,

	held = false,
	lastZoomState = 0,
	rebindTimer = 0.0,
	zoomTimer = 0.0,

	oldFov = -1,
	oldSensitivity = -1,
	oldWeaponOffsetZ = -1,
	oldCursorHook = "(none)",

	options =
	{
		lastBoundKey = "",
		zoomFov = 43,
		smoothZoom = true,
		zoomTime = 0.075,
		rescaleSensitivity = SENSITIVITY_MONITOR_DISTANCE,
		adjustViewmodel = true,
	},
	optionsDisplayOrder =
	{
		"bindZoom", "lastBoundKey",
		"",
		"zoomFov", "smoothZoom", "zoomTime", "rescaleSensitivity", "adjustViewmodel"
	},
};
GoaHud:registerWidget("GoaHud_Zoom", GOAHUD_MODULE);

function GoaHud_Zoom:init()
	-- convert old boolean value to combobox index value
	if (tostring(self.options.rescaleSensitivity) == "true") then
		self.options.rescaleSensitivity = SENSITIVITY_MONITOR_DISTANCE
		self:saveOptions()
	elseif (tostring(self.options.rescaleSensitivity) == "false") then
		self.options.rescaleSensitivity = SENSITIVITY_DISABLED
		self:saveOptions()
	end

	GoaHud:createConsoleVariable("zoom", "int", 0, true)

	self.oldFov = consoleGetVariable("r_fov")
	self.oldSensitivity = consoleGetVariable("m_speed")
	self.oldWeaponOffsetZ = consoleGetVariable("cl_weapon_offset_z")
	self.oldCursorHook = consoleGetVariable("showscorescursorhook")

	-- reset zoom fov when the value is out of bounds
	if (self.options.zoomFov < 10 or self.options.zoomFov > 178) then
		self.options.zoomFov = self.defaults.zoomFov
		self:saveOptions()

		if (GoaHud_Chat and GoaHud_Chat.onError) then GoaHud_Chat:onError(self.widgetName, "Invalid zoom FOV value detected, reseting back to default value") end
	end
end

function math.csc(x)
	return 1.0 / math.sin(x)
end

local deg2rad = function(deg)
	return (math.pi / 180.0) * deg
end

local getVerticalFov = function(f)
	local aspect = 3.0/4.0
	return 2.0 * math.atan(aspect * math.tan(deg2rad(f) / 2.0))
end

local comboBoxData1 = {}
function GoaHud_Zoom:drawOptionsVariable(varname, x, y, optargs)
	if (varname == "lastBoundKey") then return 0
	elseif (varname == "bindZoom") then
		self.rebindTimer = 0
		GoaLabel("Bind Zoom:", x, y, optargs)
		local key = GoaKeyBind("ui_goahud_zoom 2; +showscores", x + 200, y, 150, "game", optargs)
		if (key ~= nil) then
			self.options.lastBoundKey = key
		end
		if (self.options.lastBoundKey) then
			GoaLabel("Last bound key: " .. string.upper(self.options.lastBoundKey), x + 200 + 150 + 20, y, optargs)
		end

		optargs.optionalId = optargs.optionalId + 1
		return GOAHUD_SPACING
	elseif (varname == "zoomFov") then
		local optargs = clone(optargs)
		optargs.fov = true
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs, "Zoom FOV")
	elseif (varname == "zoomTime") then
		local optargs = clone(optargs)
		optargs.enabled = self.options.smoothZoom
		optargs.milliseconds = true
		optargs.min_value = 1
		optargs.max_value = 300
		optargs.indent = 1
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs)
	elseif (varname == "smoothZoom") then
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs, "Enable Animations")
	elseif (varname == "rescaleSensitivity") then
		GoaLabel("Rescale Sensitivity: ", x, y, optargs)
		self.options.rescaleSensitivity = GoaComboBoxIndex(SENSITIVITY_NAMES, self.options.rescaleSensitivity, x + 225, y, 250, comboBoxData1,
			table.merge(optargs, { enabled = self.options.showFraggedMessage }))

		return GOAHUD_SPACING
	end
	return nil
end

function GoaHud_Zoom:onEnabled(enabled)
	self.held = false
	self.lastZoomState = 0
	self.rebindTimer = 0.0
	self.zoomTimer = 0.0
	GoaHud:setConsoleVariable("zoom", 0)
end

function GoaHud_Zoom:show()
	consolePerformCommand("ui_set_widget_zindex GoaHud_Zoom 10000")
end

function GoaHud_Zoom:draw()
	self.rebindTimer = self.rebindTimer + deltaTimeRaw
	if (self.rebindTimer >= 1.0) then
		-- bindReverseLookup is very slow so let's not call it too often
		rebindLookup("ui_goahud_zoom", 1, 2)
		self.rebindTimer = 0.0
	end

	-- reset zoom when menu is opened
	if ((isInMenu() and self.held) or world.gameState == GAME_STATE_GAMEOVER) then
		self.lastZoomState = -1
		GoaHud:setConsoleVariable("zoom", 0)
		if (world.gameState ~= GAME_STATE_GAMEOVER) then
			consolePerformCommand("-showscores")
		end
		self:onZoomReleased()
	end

	local zoom_state = GoaHud:getConsoleVariable("zoom")
	if (zoom_state >= 1 and self.lastZoomState == 0 and showScores) then
		self:onZoomPressed()
		GoaHud:setConsoleVariable("zoom", -1)
	elseif (zoom_state ~= 0 and (not showScores)) then
		self:onZoomReleased()
		GoaHud:setConsoleVariable("zoom", 0)
	end

	if (zoom_state ~= 0 and showScores) then
		showScores = false
	end

	self.held = zoom_state ~= 0

	local zooming = false
	local progress
	if (self.options.smoothZoom) then
		if (self.held and self.zoomTimer < self.options.zoomTime) then
			self.zoomTimer = self.zoomTimer + deltaTimeRaw
			if (self.zoomTimer > self.options.zoomTime) then self.zoomTimer = self.options.zoomTime end
			zooming = true
		elseif (not self.held and self.zoomTimer > 0.0) then
			self.zoomTimer = self.zoomTimer - deltaTimeRaw
			if (self.zoomTimer < 0.0) then self.zoomTimer = 0.0 end
			zooming = true
		end
		progress = self.zoomTimer / self.options.zoomTime
	elseif (self.lastZoomState ~= zoom_state) then
		zooming = true
		if (self.held) then	progress = 1.0 else progress = 0.0 end
	end

	if (zooming) then
		local newFov = lerp(self.oldFov, self.options.zoomFov, progress)
		consolePerformCommand("r_fov " .. tostring(newFov))

		if (self.options.rescaleSensitivity == SENSITIVITY_MONITOR_DISTANCE) then
			local ratio = math.atan((4.0/3.0) * math.tan(deg2rad(newFov)/2.0)) / math.atan((4.0/3.0) * math.tan(deg2rad(self.oldFov)/2.0))
			local newSensitivity = self.oldSensitivity * ratio
			consolePerformCommand("m_speed " .. tostring(newSensitivity))
		elseif (self.options.rescaleSensitivity == SENSITIVITY_VIEWSPEED) then
			local oldFovVertical = getVerticalFov(self.oldFov)
			local newFovVertical = getVerticalFov(newFov)
			local ratio = (math.csc(oldFovVertical/2.0)/math.sqrt(2.0)) / (math.csc(newFovVertical/2.0)/math.sqrt(2.0))
			local newSensitivity = self.oldSensitivity * ratio
			consolePerformCommand("m_speed " .. tostring(newSensitivity))
		end

		if (self.options.adjustViewmodel) then
			local targetOffset = self.oldWeaponOffsetZ - 27
			local newOffset = lerp(self.oldWeaponOffsetZ, targetOffset, progress)
			consolePerformCommand("cl_weapon_offset_z " .. tostring(newOffset))
		end
	end

	self.lastZoomState = zoom_state
end

function GoaHud_Zoom:onZoomPressed()
	-- reset fov
	if (self.zoomTimer == 0.0) then
		self.oldFov = consoleGetVariable("r_fov")
		self.oldSensitivity = consoleGetVariable("m_speed")
		self.oldWeaponOffsetZ = consoleGetVariable("cl_weapon_offset_z")
		self.oldCursorHook = consoleGetVariable("showscorescursorhook")
	end

	consolePerformCommand("r_fov " .. self.oldFov)
	consolePerformCommand("showscorescursorhook (none)")
end

function GoaHud_Zoom:onZoomReleased()
	consolePerformCommand("showscorescursorhook " .. self.oldCursorHook)
end