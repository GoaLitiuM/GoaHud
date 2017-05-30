-- GoaHud_Zoom made by GoaLitiuM
--
-- Smooth zoom widget
--

require "base/internal/ui/reflexcore"

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
		zoomFov = 43,
		smoothZoom = true,
		zoomTime = 0.075,
		rescaleSensitivity = true,
		adjustViewmodel = true,
	},
	optionsDisplayOrder = { "zoomFov", "smoothZoom",  "zoomTime",  "rescaleSensitivity",  "adjustViewmodel" },
};
GoaHud:registerWidget("GoaHud_Zoom", GOAHUD_MODULE);

function GoaHud_Zoom:init()
	GoaHud:createConsoleVariable("zoom", "int", 0)
	GoaHud:setConsoleVariable("zoom", 0)
end

function GoaHud_Zoom:drawOptionsVariable(varname, x, y, optargs)
	if (varname == "zoomFov") then
		local offset = GOAHUD_SPACING + 20
		local optargs = clone(optargs)
		optargs.fov = true
		GoaLabel("Usage:         bind <key> ui_goahud_zoom 1", x, y, optargs)
		return offset + GoaHud_DrawOptionsVariable(self.options, varname, x, y + offset, optargs, "Zoom FOV")
	elseif (varname == "zoomTime") then
		local optargs = clone(optargs)
		optargs.enabled = self.options.smoothZoom
		optargs.milliseconds = true
		optargs.min_value = 1
		optargs.max_value = 300
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs)
	elseif (varname == "smoothZoom") then
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs, "Enable Animations")
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
	if (isInMenu() and self.held) then
		self.lastZoomState = -1
		GoaHud:setConsoleVariable("zoom", 0)
		consolePerformCommand("-showscores")
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

		if (self.options.rescaleSensitivity) then
			local ratio = math.atan((4.0/3.0) * math.tan(newFov * math.pi/360.0)) / math.atan((4.0/3.0) * math.tan(self.oldFov * math.pi/360.0))
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