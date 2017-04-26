-- GoaHud_Crosshair made by GoaLitiuM
--
-- Crosshair with weapon specific settings and smooth transition animations
--

require "base/internal/ui/reflexcore"

local Crosshair =
{
	useDefault = true,

	crosshair = 3,
	crosshairColor = Color(255, 255, 255, 255),

	size = 13,
	strokeWidth = 4,
	holeSize = 9,
	dot = false,

	useShadow = true,
	shadowAlpha = 64,
	shadowSize = 4,
}

function initCrosshairs(count)
	local count = count or 1
	if (count == 1) then return clone(Crosshair) end

	local t = {}
	for i=1, count do
		table.insert(t, clone(Crosshair))
	end

	return t
end

GoaHud_Crosshair =
{
	canPosition = false,

	timer = 0.0,
	lastAmmo = -1,
	lastWeapon = -1,
	oldWeapon = -1,
	state = AMMO_STATE_SWITCHING,

	switching = false,

	crosshairs = {},
	crosshairCount = 0,

	options =
	{
		smoothTransitions = true,
		showTime = 0.0,
		fadeTime = 0.050,

		crosshairDefault = initCrosshairs(1),
		weaponCrosshairs = initCrosshairs(10),
	},
	optionsDisplayOrder = { "smoothTransitions", "showTime", "fadeTime", "preview", "crosshairDefault", "weaponCrosshairs", },
};
GoaHud:registerWidget("GoaHud_Crosshair");

function GoaHud_Crosshair:init()
	self.crosshairs =
	{
		-- function/svg, offset_x, offset_y
		{ Crosshair.drawDot, 0, 0},
		{ Crosshair.drawCircle, 0, 0},
		{ Crosshair.drawCross, 0, 0},
		{ "internal/ui/crosshairs/crosshair6", 0, 0},
		{ "internal/ui/crosshairs/crosshair7", 0, -0.17},
		{ "internal/ui/crosshairs/crosshair8", 0, 0},
		{ "internal/ui/crosshairs/crosshair9", 0, 0},
		{ "internal/ui/crosshairs/crosshair10", 0, 0},
		{ "internal/ui/crosshairs/crosshair11", 0, 0},
		{ "internal/ui/crosshairs/crosshair12", 0, 0},
		{ "internal/ui/crosshairs/crosshair13", 0, 0},
		{ "internal/ui/crosshairs/crosshair14", 0, 0},
		{ "internal/ui/crosshairs/crosshair15", 0, 0},
		{ "internal/ui/crosshairs/crosshair16", 0, 0},
	}

	for i in pairs(self.crosshairs) do self.crosshairCount = self.crosshairCount + 1 end

	if (shouldShowHUD()) then
		self.lastWeapon = getPlayer().weaponIndexweaponChangingTo
		self.oldWeapon = self.lastWeapon
	end
end

local comboBoxData = {}
local selectedCrosshairIndex = 1
local weapons = { "Default", "Melee", "Burstgun", "Shotgun", "Grenade Launcher", "Plasma Rifle", "Rocket Launcher", "Ion Cannon", "Bolt Rifle", "Stake Launcher" }
function GoaHud_Crosshair:drawOptionsVariable(varname, x, y, optargs)
	if (varname == "weaponCrosshairs") then
		local offset_y = 0
		if (selectedCrosshairIndex == 1) then
			offset_y = offset_y + self:drawOptionsCrosshair(self.options.crosshairDefault, x, y + offset_y, optargs)
		else
			offset_y = offset_y + self:drawOptionsCrosshair(self.options.weaponCrosshairs[selectedCrosshairIndex - 1], x, y + offset_y, optargs)
		end

		selectedCrosshairIndex = GoaComboBoxIndex(weapons, selectedCrosshairIndex, x, y, 215, comboBoxData, optargs)

		return offset_y
	elseif (varname == "crosshairDefault") then
		return 0
	elseif (varname == "showTime" or varname == "fadeTime") then
		local optargs = clone(optargs)
		optargs.milliseconds = true
		optargs.enabled = self.options.smoothTransitions
		return GoaHud_DrawOptionsVariable(self.options, varname, x + GOAHUD_INDENTATION, y, optargs)
	elseif (varname == "smoothTransitions") then
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs, "Enable Animations")
	end
	return nil
end

function GoaHud_Crosshair:drawOptionsCrosshair(weapon, x, y, optargs)
	local offset_y = 0
	local offset_x = GOAHUD_INDENTATION
	local optargs = clone(optargs)

	offset_y = offset_y + GoaHud_DrawOptionsVariable(weapon, "useDefault", x + offset_x + 215, y + offset_y,
		table.merge(optargs, { enabled = weapon ~= self.options.crosshairDefault }))

	optargs.enabled = true
	if (weapon.useDefault and weapon ~= self.options.crosshairDefault) then
		optargs.enabled = false
	end

	offset_y = offset_y + GoaHud_DrawOptionsVariable(weapon, "crosshair", x + offset_x, y + offset_y,
		table.merge(optargs, { tick = 1, min_value = 1, max_value = self.crosshairCount, show_editbox = false }))
	offset_y = offset_y + GoaHud_DrawOptionsVariable(weapon, "crosshairColor", x + offset_x, y + offset_y, optargs)
	offset_y = offset_y + GoaHud_DrawOptionsVariable(weapon, "size", x + offset_x, y + offset_y,
		table.merge(optargs, { tick = 1, min_value = 1, max_value = 100 }))
	offset_y = offset_y + GoaHud_DrawOptionsVariable(weapon, "strokeWidth", x + offset_x, y + offset_y,
		table.merge(optargs, { tick = 1, min_value = 1, max_value = 50, enabled = optargs.enabled and (weapon.crosshair >= 2 and weapon.crosshair <= 3) }))
	offset_y = offset_y + GoaHud_DrawOptionsVariable(weapon, "holeSize", x + offset_x, y + offset_y,
		table.merge(optargs, { tick = 1, min_value = 0, max_value = 20, enabled = optargs.enabled and weapon.crosshair == 3 }))
	offset_y = offset_y + GoaHud_DrawOptionsVariable(weapon, "dot", x + offset_x, y + offset_y,
		table.merge(optargs, { enabled = optargs.enabled and weapon.crosshair == 3 }))
	offset_y = offset_y + GoaHud_DrawOptionsVariable(weapon, "useShadow", x + offset_x, y + offset_y, optargs)
	offset_y = offset_y + GoaHud_DrawOptionsVariable(weapon, "shadowAlpha", x + offset_x + 40, y + offset_y,
		table.merge(optargs, { tick = 1, min_value = 1, max_value = 255, enabled = optargs.enabled and weapon.useShadow }), "Transparency")
	offset_y = offset_y + GoaHud_DrawOptionsVariable(weapon, "shadowSize", x + offset_x + 40, y + offset_y,
		table.merge(optargs, { tick = 1, min_value = 1, max_value = 50, enabled = optargs.enabled and weapon.useShadow }), "Size")

	return offset_y
end

function GoaHud_Crosshair:drawPreview(x, y, intensity)
	nvgSave()

	nvgSave()
	local width = 125
	local height = 75
	nvgBeginPath()
	nvgFillLinearGradient(x, y, x + width, y + height, Color(0,0,0,0), Color(255,255,255,255))
	nvgRect(x, y, width, height)
	nvgFill()
	nvgRestore()

	self:drawCrosshair(selectedCrosshairIndex - 1, x + round(width/2), y + round(height/2), 1.0 - intensity)
	nvgRestore()

	return height + 10
end

function GoaHud_Crosshair:draw()
	if (not shouldShowHUD(optargs_deadspec)) then return end

	local local_player = getLocalPlayer()
	if (local_player.state == PLAYER_STATE_SPECTATOR and playerIndexLocalPlayer == playerIndexCameraAttachedTo) then return end

	local player = getPlayer()
	local weapon = player.weaponIndexweaponChangingTo
	if (player.infoHidden) then weapon = self.lastWeapon end
	if (player.isDead) then return end

	local weapon_show = weapon

	if (self.options.smoothTransitions and self.options.fadeTime > 0.0) then
		if (weapon ~= self.lastWeapon) then
			if (self.state == AMMO_STATE_SHOWING) then
				self.timer = 0.0
			else
				self.state = AMMO_STATE_SWITCHING
			end

			self.oldWeapon = self.lastWeapon
			self.lastWeapon = weapon
		end

		if (self.state == AMMO_STATE_SWITCHING or self.state == AMMO_STATE_HIDING) then
			if (self.state == AMMO_STATE_SWITCHING) then
				weapon_show = self.oldWeapon
			end

			self.timer = self.timer + deltaTimeRaw
			if (self.timer >= self.options.fadeTime) then
				self.timer = 0.0
				if (self.state == AMMO_STATE_SWITCHING) then
					self.state = AMMO_STATE_SHOWING
				else
					self.state = AMMO_STATE_HIDDEN
				end
			end
		elseif (self.state == AMMO_STATE_SHOWING) then
			self.timer = self.timer + deltaTimeRaw
			if (self.timer >= self.options.showTime) then
				self.timer = 0.0
				self.state = AMMO_STATE_HIDING
			end
		end
	end

	local progress = self.timer / self.options.fadeTime
	if (self.state == AMMO_STATE_SHOWING) then progress = 1.0
	elseif (self.state == AMMO_STATE_HIDING) then progress = 1.0 - progress end

	if (weapon_show == -1) then return end

	self:drawCrosshair(weapon_show, 0, 0, progress)
end

function GoaHud_Crosshair:drawCrosshair(weapon, x, y, intensity)
	local crosshair_settings
	if (weapon <= 0) then crosshair_settings = self.options.crosshairDefault
	else crosshair_settings = self.options.weaponCrosshairs[weapon] end

	if (crosshair_settings.useDefault) then crosshair_settings = self.options.crosshairDefault end

	local crosshair_index = math.min(self.crosshairCount, crosshair_settings.crosshair)
	local crosshair_template = self.crosshairs[crosshair_index]
	local crosshair_scale = 1.0 - intensity
	local final_color = clone(crosshair_settings.crosshairColor)
	final_color.a = final_color.a * (1.0 - intensity)

	nvgScale(crosshair_scale, crosshair_scale)
	nvgTranslate(x + (crosshair_settings.size * crosshair_template[2]), y + (crosshair_settings.size * crosshair_template[3]))

	if (type(crosshair_template[1]) == "string") then
		Crosshair.drawSvg(crosshair_settings, crosshair_template[1], final_color)
	else
		crosshair_template[1](crosshair_settings, nil, final_color)
	end
end

function Crosshair:drawDot(svg, color)
	-- shadow
	if (self.useShadow) then
		nvgBeginPath()
		nvgFillRadialGradient(0, 0, self.size/2, self.size+self.shadowSize, Color(0,0,0, self.shadowAlpha), Color(0,0,0,0))
		nvgCircle(0, 0, self.size+self.shadowSize)
		nvgFill()
	end

	-- dot
	nvgBeginPath()
	nvgFillColor(color)
	nvgCircle(0, 0, self.size)
	nvgFill()
end

function Crosshair:drawCircle(svg, color)
	if (self.useShadow) then
		-- inner shadow
		nvgBeginPath()
		nvgFillRadialGradient(0, 0, self.size-self.shadowSize, self.size*2, Color(0,0,0,0), Color(0,0,0,self.shadowAlpha))
		nvgCircle(0, 0, self.size)
		nvgFill()

		-- outer shadow
		nvgBeginPath()
		nvgFillRadialGradient(0, 0, self.size/2, self.size+self.shadowSize, Color(0,0,0,self.shadowAlpha), Color(0,0,0,0))
		nvgCircle(0, 0, self.size+self.shadowSize)
		nvgCircle(0, 0, self.size)
		nvgPathWinding(NVG_HOLE)
		nvgFill()
	end

	-- circle
	nvgBeginPath()
	nvgStrokeColor(color)
	nvgStrokeWidth(self.strokeWidth)
	nvgCircle(0, 0, self.size)
	nvgStroke()
end

function Crosshair:drawCross(svg, color)
	local draw_dot = self.dot and self.holeSize > 0
	local function drawCrossLines(color, length, stroke_width, hole_size)
		nvgSave()
		local half_offset = 0
		if (math.floor(stroke_width) % 2 ~= 0) then half_offset = 0.5 end

		if (hole_size == nil) then
			nvgStrokeColor(color)
			nvgStrokeWidth(stroke_width)

			nvgBeginPath()

			nvgMoveTo(-length, half_offset)
			nvgLineTo(length, half_offset)

			nvgMoveTo(half_offset, -length)
			nvgLineTo(half_offset, -stroke_width/2 + half_offset)

			nvgMoveTo(half_offset, stroke_width/2 + half_offset)
			nvgLineTo(half_offset, length)

			nvgStroke()
		else
			local line_start = (stroke_width/2) + hole_size - 1
			local line_end = length + line_start

			-- lines
			nvgStrokeColor(color)
			nvgStrokeWidth(stroke_width)

			nvgBeginPath()

			nvgMoveTo(-math.floor(line_start), half_offset)
			nvgLineTo(-math.floor(line_end) - half_offset*2, half_offset)

			nvgMoveTo(math.ceil(line_start), half_offset)
			nvgLineTo(math.ceil(line_end), half_offset)

			nvgMoveTo(half_offset, -math.floor(line_start))
			nvgLineTo(half_offset, -math.floor(line_end) - half_offset*2)

			nvgMoveTo(half_offset, math.ceil(line_start))
			nvgLineTo(half_offset, math.ceil(line_end))

			nvgStroke()
		end

		if (draw_dot) then
			nvgStrokeWidth(stroke_width)
			nvgBeginPath()
			nvgMoveTo(-math.floor(stroke_width/2), half_offset)
			nvgLineTo(math.floor(stroke_width/2)+half_offset*2, half_offset)
			nvgStroke()
		end

		nvgRestore()
	end

	if (self.useShadow) then
		local shadow_length = self.size + self.shadowSize
		local shadow_stroke = self.strokeWidth + self.shadowSize*2
		local shadow_hole = nil

		if (self.holeSize ~= 0) then
			shadow_hole = self.holeSize - self.shadowSize * 2
			shadow_length = shadow_length + self.shadowSize
		end

		drawCrossLines(Color(0,0,0,self.shadowAlpha), shadow_length, shadow_stroke, shadow_hole)
	end

	local hole_size = nil
	if (self.holeSize ~= 0) then hole_size = self.holeSize end
	drawCrossLines(color, self.size, self.strokeWidth, hole_size)
end

function Crosshair:drawSvg(svg, color)
	if (self.useShadow) then
		nvgFillColor(Color(0,0,0, self.shadowAlpha))
		nvgSvg(svg, 0, 0, self.size, self.shadowSize)
	end

	nvgFillColor(color)
	nvgSvg(svg, 0, 0, self.size, 0)
end