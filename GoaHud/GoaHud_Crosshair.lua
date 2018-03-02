-- GoaHud_Crosshair made by GoaLitiuM
--
-- Crosshair with weapon specific settings and smooth transition animations
--

require "base/internal/ui/reflexcore"

local CROSSHAIR_MODE_NORMAL = 1
local CROSSHAIR_MODE_DAMAGE = 2
local CROSSHAIR_MODE_DAMAGETAKEN = 3

local CROSSHAIR_MODE_NAMES =
{
	"Normal",
	"Damage",
	"Damage Taken",
}

local CrosshairShape =
{
	enabled = true,

	type = 3,
	color = Color(255, 255, 255, 255),

	size = 13,
	strokeWidth = 4,
	holeSize = 9,
	dot = false,

	mode = CROSSHAIR_MODE_NORMAL,
	modeShowTime = 0,
	modeFadeTime = 0.5,

	useShadow = true,
	shadowColor = Color(0, 0, 0, 64),
	shadowSize = 1,
}

function initCrosshairShapes(count)
	local t = {}
	for i=1, count do
		local s = clone(CrosshairShape)
		if (i > 1) then	s.enabled = false end
		table.insert(t, s)
	end

	return t
end

local Crosshair =
{
	useDefault = true,
	shapes = initCrosshairShapes(4),
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

	lastHealth = 0,
	lastDamageDone = 0,
	lastDamageDoneIon = 0,
	lastDamageTime = -99,
	lastDamageTakenTime = -99,
	lastPlayer = -1,

	switching = false,

	crosshairs = {},
	crosshairCount = 0,

	options =
	{
		showAlways = true,

		smoothTransitions = true,
		showTime = 0.0,
		fadeTime = 0.0425,

		crosshairDefault = initCrosshairs(1),
		weaponCrosshairs = initCrosshairs(10),
	},

	optionsDisplayOrder =
	{
		"showAlways",
		"",
		"smoothTransitions", "showTime", "fadeTime", "preview", "crosshairDefault", "weaponCrosshairs",
	},
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

	-- migrate old crosshair shape settings to new system
	for i, c in pairs(self.options.weaponCrosshairs) do
		if (c.crosshair ~= nil) then
			c.shapes = initCrosshairShapes(2)
			c.shapes[1].type = c.crosshair

			if (c.crosshairColor ~= nil and not isEmpty(c.crosshairColor)) then c.shapes[1].color = c.crosshairColor end
			if (c.size ~= nil) then c.shapes[1].size = c.size end
			if (c.strokeWidth ~= nil) then c.shapes[1].strokeWidth = c.strokeWidth end
			if (c.holeSize ~= nil) then c.shapes[1].holeSize = c.holeSize end
			if (c.useShadow ~= nil) then c.shapes[1].useShadow = c.useShadow end
			if (c.shadowAlpha ~= nil) then c.shapes[1].shadowColor.a = c.shadowAlpha end
			if (c.shadowSize ~= nil) then c.shapes[1].shadowSize = c.shadowSize end

			c.crosshair = nil
			c.crosshairColor = nil
			c.size = nil
			c.strokeWidth = nil
			c.holeSize = nil
			c.useShadow = nil
			c.shadowAlpha = nil
			c.shadowSize = nil
		end

		if (c.dot ~= nil) then
			for j, s in pairs(c.shapes) do
				if (s.type == 3) then -- cross
					s.dot = c.dot
				end
			end
			c.dot = nil
		end
	end

	if (self.options.crosshairDefault.dot ~= nil) then
		for j, s in pairs(self.options.crosshairDefault.shapes) do
			if (s.type == 3) then -- cross
				s.dot = self.options.crosshairDefault.dot
			end
		end
		c.dot = nil
	end

	local player = getPlayer()
	if (player ~= nil) then
		self.lastHealth = player.health
		self.lastDamageDone = player.stats.totalDamageDone
		self.lastDamageDoneIon = player.weaponStats[7].damageDone
		self.lastPlayer = player.index
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
		optargs.indent = 1
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs)
	elseif (varname == "smoothTransitions") then
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs, "Enable Animations")
	end
	return nil
end

local values_changed_last = -1
function GoaHud_Crosshair:drawOptionsCrosshair(weapon, x, y, optargs)
	local offset_y = 0
	local offset_x = GOAHUD_INDENTATION * 0.5
	local indent_offset = 0.5
	local optargs = clone(optargs)
	optargs.indent = 0

	local values_changed = 0
	if (weapon.useDefault) then values_changed = values_changed + 1 end

	offset_y = offset_y + GoaHud_DrawOptionsVariable(weapon, "useDefault", x + offset_x + 215, y + offset_y,
		table.merge(optargs, { enabled = weapon ~= self.options.crosshairDefault }))
	optargs.optionalId = optargs.optionalId + 1

	optargs.enabled = true
	if (weapon.useDefault and weapon ~= self.options.crosshairDefault) then
		optargs.enabled = false
	end

	for i, shape in ipairs(weapon.shapes) do
		local shape_enabled = shape.enabled and optargs.enabled

		if (shape.enabled) then values_changed = values_changed + 1 end
		if (shape.dot) then values_changed = values_changed + 1 end
		if (shape.useShadow) then values_changed = values_changed + 1 end
		if (shape.shadowSize) then values_changed = values_changed + 1 end
		values_changed = values_changed + shape.type
		values_changed = values_changed + shape.size
		values_changed = values_changed + shape.strokeWidth
		values_changed = values_changed + shape.modeShowTime
		values_changed = values_changed + shape.modeFadeTime
		values_changed = values_changed + shape.holeSize

		if (i == 1) then
			GoaLabel("Shape " .. i .. ":", x + offset_x, y + offset_y, table.merge(optargs, { enabled = shape_enabled }))
		else
			shape.enabled = GoaRowCheckbox(x + offset_x, y + offset_y, WIDGET_PROPERTIES_COL_INDENT, "Enable Shape " .. i, shape.enabled, optargs)
			optargs.optionalId = optargs.optionalId + 1
		end

		offset_y = offset_y + GOAHUD_SPACING
		if (shape_enabled) then
			optargs.indent = optargs.indent + indent_offset

			offset_y = offset_y + GoaHud_DrawOptionsVariable(shape, "type", x + offset_x, y + offset_y,
				table.merge(optargs, { enabled = shape_enabled, tick = 1, min_value = 1, max_value = self.crosshairCount, show_editbox = false }))
			optargs.optionalId = optargs.optionalId + 1
			offset_y = offset_y + GoaHud_DrawOptionsVariable(shape, "color", x + offset_x, y + offset_y,
				table.merge(optargs, { enabled = shape_enabled }))
			optargs.optionalId = optargs.optionalId + 1
			offset_y = offset_y + GoaHud_DrawOptionsVariable(shape, "size", x + offset_x, y + offset_y,
				table.merge(optargs, { enabled = shape_enabled, tick = 1, min_value = 1, max_value = 100 }))
			optargs.optionalId = optargs.optionalId + 1
			offset_y = offset_y + GoaHud_DrawOptionsVariable(shape, "strokeWidth", x + offset_x, y + offset_y,
				table.merge(optargs, { enabled = shape_enabled and (shape.type >= 2 and shape.type <= 3), tick = 1, min_value = 1, max_value = 50 }))
			optargs.optionalId = optargs.optionalId + 1
			offset_y = offset_y + GoaHud_DrawOptionsVariable(shape, "holeSize", x + offset_x, y + offset_y,
				table.merge(optargs, { enabled = shape_enabled and shape.type == 3, tick = 1, min_value = 0, max_value = 20}))
			optargs.optionalId = optargs.optionalId + 1
			offset_y = offset_y + GoaHud_DrawOptionsVariable(shape, "dot", x + offset_x, y + offset_y,
				table.merge(optargs, { enabled = shape_enabled and shape.type == 3 }))
			optargs.optionalId = optargs.optionalId + 1

			local mode_enabled = shape_enabled and i > 1
			shape.mode = GoaComboBoxIndex(CROSSHAIR_MODE_NAMES, shape.mode, x + offset_x, y + offset_y, 250, "crosshairmodenames" .. i,
				table.merge(optargs, { enabled = mode_enabled }))
			optargs.optionalId = optargs.optionalId + 1
			offset_y = offset_y + GOAHUD_SPACING

			optargs.indent = optargs.indent + indent_offset
			offset_y = offset_y + GoaHud_DrawOptionsVariable(shape, "modeShowTime", x + offset_x, y + offset_y,
				table.merge(optargs, { enabled = mode_enabled and shape.mode ~= CROSSHAIR_MODE_NORMAL, milliseconds = true, min_value = 0, max_value = 1000 }), "Show Time")
			optargs.optionalId = optargs.optionalId + 1
			offset_y = offset_y + GoaHud_DrawOptionsVariable(shape, "modeFadeTime", x + offset_x, y + offset_y,
				table.merge(optargs, { enabled = mode_enabled and shape.mode ~= CROSSHAIR_MODE_NORMAL, milliseconds = true, min_value = 0, max_value = 1000 }), "Fade Time")
			optargs.optionalId = optargs.optionalId + 1
			optargs.indent = optargs.indent - indent_offset

			offset_y = offset_y + GoaHud_DrawOptionsVariable(shape, "useShadow", x + offset_x, y + offset_y,
				table.merge(optargs, { enabled = shape_enabled }))
			optargs.optionalId = optargs.optionalId + 1

			optargs.indent = optargs.indent + indent_offset
			offset_y = offset_y + GoaHud_DrawOptionsVariable(shape, "shadowColor", x + offset_x, y + offset_y,
				table.merge(optargs, { enabled = shape_enabled and weapon.useShadow }), "Color")
			optargs.optionalId = optargs.optionalId + 1
			offset_y = offset_y + GoaHud_DrawOptionsVariable(shape, "shadowSize", x + offset_x, y + offset_y,
				table.merge(optargs, { enabled = shape_enabled and weapon.useShadow, tick = 1, min_value = 1, max_value = 50 }), "Size")
			optargs.optionalId = optargs.optionalId + 1
			optargs.indent = optargs.indent - indent_offset

			optargs.indent = optargs.indent - indent_offset

			if (shape_enabled) then
				offset_y = offset_y + 25
				self:drawPreview(x + offset_x, y + offset_y, 1.0)
				offset_y = offset_y + 100
			end
		end
	end

	if (values_changed ~= values_changed_last) then
		self.lastDamageTakenTime = epochTimeMs
		self.lastDamageTime = epochTimeMs
	end
	values_changed_last = values_changed

	return offset_y
end

function GoaHud_Crosshair:drawPreview(x, y, intensity)
	if (self.lastDamageTakenTime < epochTime) then
		self.lastDamageTakenTime = epochTime
		self.lastDamageTime = epochTime
	end

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
	if (self.options.showAlways) then
		if (replayName == "menu" or isInMenu()) then return end
	elseif (not shouldShowHUD(optargs_deadspec)) then return end

	local player = getPlayer()
	local local_player = getLocalPlayer()

	if (player == nil or local_player == nil) then return end

	-- hide in free camera mode
	if (local_player.state == PLAYER_STATE_SPECTATOR and playerIndexLocalPlayer == playerIndexCameraAttachedTo) then return end

	local weapon = player.weaponIndexweaponChangingTo
	local ion_damage = player.weaponStats[7].damageDone

	-- can not track current weapon while spectating enemy team
	if (player.infoHidden) then weapon = self.lastWeapon end

	if (player.index == self.lastPlayer) then
		-- keep track of when player has taken or dealt damage last time
		if (player.health < self.lastHealth) then
			self.lastDamageTakenTime = epochTimeMs
		end
		if (player.stats.totalDamageDone > self.lastDamageDone) then
			self.lastDamageTime = epochTimeMs
		end

		-- when hitting with ion cannon, adjust the time so the hit indicator stays a little bit longer
		-- on screem to prevent fluctuations in transparency when most of the damage ticks are hitting
		if (ion_damage > self.lastDamageDoneIon) then
			self.lastDamageTime = epochTimeMs + weaponDefinitions[7].reloadTime * 2 / 1000
		end
	end

	self.lastHealth = player.health
	self.lastDamageDone = player.stats.totalDamageDone
	self.lastDamageDoneIon = ion_damage
	self.lastPlayer = player.index

	if (player.isDead) then return end

	local progress = 0.0
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

		progress = self.timer / self.options.fadeTime
	end

	if (self.state == AMMO_STATE_SHOWING) then progress = 1.0
	elseif (self.state == AMMO_STATE_HIDING) then progress = 1.0 - progress end

	if (weapon_show == -1) then return end

	self:drawCrosshair(weapon_show, 0, 0, progress)
end

function GoaHud_Crosshair:drawCrosshair(weapon, x, y, intensity)
	local crosshair = self.options.crosshairDefault
	if (weapon > 0 and not self.options.weaponCrosshairs[weapon].useDefault) then
		crosshair = self.options.weaponCrosshairs[weapon]
	end

	for i, shape in ipairs(crosshair.shapes) do
		if (shape.enabled) then
			local shape_index = math.min(self.crosshairCount, shape.type)
			local shape_info = self.crosshairs[shape_index]
			local shape_scale = 1.0 - intensity
			local final_color = clone(shape.color)
			final_color.a = final_color.a * (1.0 - intensity)

			local lastTriggerTime = 0.0
			if (shape.mode == CROSSHAIR_MODE_DAMAGE) then
				lastTriggerTime = self.lastDamageTime
			elseif (shape.mode == CROSSHAIR_MODE_DAMAGETAKEN) then
				lastTriggerTime = self.lastDamageTakenTime
			end

			local triggerTimer = epochTimeMs - lastTriggerTime
			local mode_intensity = 1.0
			if (shape.mode == CROSSHAIR_MODE_DAMAGE or shape.mode == CROSSHAIR_MODE_DAMAGETAKEN) then
				if (shape.modeFadeTime <= 0.0) then
					if (triggerTimer >= shape.modeShowTime) then mode_intensity = 0.0 end
				else
					mode_intensity = 1.0 - math.max(math.min(math.max(triggerTimer - shape.modeShowTime, 0.0) / shape.modeFadeTime, 1.0), 0.0)
				end
			end

			final_color.a = final_color.a * EaseIn(mode_intensity)

			nvgSave()

			nvgScale(shape_scale, shape_scale)
			nvgTranslate(x + (shape.size * shape_info[2]), y + (shape.size * shape_info[3]))

			if (type(shape_info[1]) == "string") then
				Crosshair.drawSvg(crosshair, shape_info[1], shape, final_color)
			else
				shape_info[1](crosshair, shape, final_color)
			end

			nvgRestore()
		end
	end
end

function Crosshair:drawDot(shape, color)
	-- shadow
	if (shape.useShadow) then
		local shadow_color = clone(shape.shadowColor)
		shadow_color.a = (shadow_color.a / 255) * (color.a / 255) * 255

		nvgBeginPath()
		nvgFillRadialGradient(0, 0, shape.size/2, shape.size+shape.shadowSize, shadow_color, Color(0,0,0,0))
		nvgCircle(0, 0, shape.size+shape.shadowSize)
		nvgFill()
	end

	-- dot
	nvgBeginPath()
	nvgFillColor(color)
	nvgCircle(0, 0, shape.size)
	nvgFill()
end

function Crosshair:drawCircle(shape, color)
	if (shape.useShadow) then
		local shadow_color = clone(shape.shadowColor)
		shadow_color.a = (shadow_color.a / 255) * (color.a / 255) * 255

		-- inner shadow
		nvgBeginPath()
		nvgFillRadialGradient(0, 0, shape.size-shape.shadowSize, shape.size*2, Color(0,0,0,0), shadow_color)
		nvgCircle(0, 0, shape.size)
		nvgFill()

		-- outer shadow
		nvgBeginPath()
		nvgFillRadialGradient(0, 0, shape.size/2, shape.size+shape.shadowSize, shadow_color, Color(0,0,0,0))
		nvgCircle(0, 0, shape.size+shape.shadowSize)
		nvgCircle(0, 0, shape.size)
		nvgPathWinding(NVG_HOLE)
		nvgFill()
	end

	-- circle
	nvgBeginPath()
	nvgStrokeColor(color)
	nvgStrokeWidth(shape.strokeWidth)
	nvgCircle(0, 0, shape.size)
	nvgStroke()
end

function Crosshair:drawCross(shape, color)
	local draw_dot = shape.dot and shape.holeSize > 0
	local function drawCrossLines(line_color, length, stroke_width, hole_size)
		nvgSave()
		local half_offset = 0
		if (math.floor(stroke_width) % 2 ~= 0) then half_offset = 0.5 end

		if (hole_size == nil) then
			nvgStrokeColor(line_color)
			nvgStrokeWidth(stroke_width)

			nvgBeginPath()

			nvgMoveTo(-length, half_offset)
			nvgLineTo(length + half_offset*2, half_offset)

			nvgMoveTo(half_offset, -length)
			nvgLineTo(half_offset, -stroke_width/2 + half_offset)

			nvgMoveTo(half_offset, stroke_width/2 + half_offset)
			nvgLineTo(half_offset, length + half_offset*2)

			nvgStroke()
		else
			local line_start = (stroke_width/2) + hole_size - 1
			local line_end = length + line_start

			-- lines
			nvgStrokeColor(line_color)
			nvgStrokeWidth(stroke_width)

			nvgBeginPath()

			nvgMoveTo(-math.floor(line_start), half_offset)
			nvgLineTo(-math.floor(line_end) - half_offset*2, half_offset)

			nvgMoveTo(math.ceil(line_start), half_offset)
			nvgLineTo(math.ceil(line_end) + half_offset*2, half_offset)

			nvgMoveTo(half_offset, -math.floor(line_start))
			nvgLineTo(half_offset, -math.floor(line_end) - half_offset*2)

			nvgMoveTo(half_offset, math.ceil(line_start))
			nvgLineTo(half_offset, math.ceil(line_end) + half_offset*2)

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

	if (shape.useShadow) then
		local shadow_color = clone(shape.shadowColor)
		shadow_color.a = (shadow_color.a / 255) * (color.a / 255) * 255

		local shadow_length = shape.size + shape.shadowSize
		local shadow_stroke = shape.strokeWidth + shape.shadowSize*2
		local shadow_hole = nil

		if (shape.holeSize ~= 0) then
			shadow_hole = shape.holeSize - shape.shadowSize * 2
			shadow_length = shadow_length + shape.shadowSize
		end

		drawCrossLines(shadow_color, shadow_length, shadow_stroke, shadow_hole)
	end

	local hole_size = nil
	if (shape.holeSize ~= 0) then hole_size = shape.holeSize end
	drawCrossLines(color, shape.size, shape.strokeWidth, hole_size)
end

function Crosshair:drawSvg(svg, shape, color)
	if (shape.useShadow) then
		local shadow_color = clone(shape.shadowColor)
		shadow_color.a = (shadow_color.a / 255) * (color.a / 255) * 255

		nvgFillColor(shadow_color)
		nvgSvg(svg, 0, 0, shape.size, shape.shadowSize)
	end

	nvgFillColor(color)
	nvgSvg(svg, 0, 0, shape.size, 0)
end