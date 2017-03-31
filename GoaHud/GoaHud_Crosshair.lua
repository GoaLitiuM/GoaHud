-- GoaHud_Crosshair made by GoaLitiuM
-- 
-- Crosshair with weapon specific settings and smooth transition animations
--

require "base/internal/ui/reflexcore"

local defaultCrosshair =
{
	useDefault = true,
	
	crosshair = 3,
	crosshairColor = Color(255, 255, 255, 255),
	
	size = 13,
	strokeWidth = 4,
	holeSize = 9,
	
	useShadow = true,
	shadowAlpha = 64,
	shadowSize = 4,
}

function initCrosshairs(count)
	local count = count or 1
	if (count == 1) then return clone(defaultCrosshair) end
	
	local t = {}
	for i=1, count do
		table.insert(t, clone(defaultCrosshair))
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
	optionsDisplayOrder = { "smoothTransitions", "showTime", "fadeTime", "crosshairDefault", "weaponCrosshairs", },
};
GoaHud:registerWidget("GoaHud_Crosshair");

function GoaHud_Crosshair:init()
	self.crosshairs = 
	{
		{ drawDot, 0, 0},
		{ drawCircle, 0, 0},
		{ drawCross, 0, 0},
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
	
	for i, k in pairs(self.crosshairs) do self.crosshairCount = self.crosshairCount + 1 end

	if (shouldShowHUD()) then
		self.lastWeapon = getPlayer().weaponIndexweaponChangingTo
		self.oldWeapon = self.lastWeapon
	end
end

local comboBoxData = {}
local selectedCrosshairIndex = 1
function GoaHud_Crosshair:drawOptionsVariable(varname, x, y, optargs)
	if (varname == "weaponCrosshairs") then
		local offset_y = 40
		local weapons = { "Default", "Melee", "Burstgun", "Shotgun", "Grenade Launcher", "Plasma Rifle", "Rocket Launcher", "Ion Cannon", "Bolt Rifle", "Stake Launcher" }

		if (selectedCrosshairIndex == 1) then
			offset_y = offset_y + self:drawOptionsCrosshair(self.options.crosshairDefault, x, y + offset_y, optargs)
		else
			offset_y = offset_y + self:drawOptionsCrosshair(self.options.weaponCrosshairs[selectedCrosshairIndex - 1], x, y + offset_y, optargs)
		end
		
		local selection_name = GoaComboBox(weapons, weapons[selectedCrosshairIndex], x, y + 40, 215, comboBoxData, optargs)
		for i, weapon in ipairs(weapons) do
			if (weapon == selection_name) then
				selectedCrosshairIndex = i
				break
			end
		end
		
		return offset_y
	elseif (varname == "crosshairDefault") then
		return 0
	elseif (varname == "fadeTime") then
		local optargs = clone(optargs)
		optargs.milliseconds = true
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs)
	else
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs)
	end
	return nil
end

function GoaHud_Crosshair:drawOptionsCrosshair(weapon, x, y, optargs)
	local offset_y = 0
	local offset_x = 40
	local optargs = clone(optargs)
		
	offset_y = offset_y + GoaHud_DrawOptionsVariable(weapon, "useDefault", x + offset_x + 215, y + offset_y,
		table.merge(optargs, { enabled = weapon ~= self.options.crosshairDefault }))
	
	optargs.enabled = true
	if (weapon.useDefault and weapon ~= self.options.crosshairDefault) then
		optargs.enabled = false
	end

	offset_y = offset_y + GoaHud_DrawOptionsVariable(weapon, "crosshair", x + offset_x, y + offset_y,
		table.merge(optargs, { min_value = 1, max_value = self.crosshairCount, tick = 1, show_editbox = false }))
	offset_y = offset_y + GoaHud_DrawOptionsVariable(weapon, "crosshairColor", x + offset_x, y + offset_y, optargs)
	offset_y = offset_y + GoaHud_DrawOptionsVariable(weapon, "size", x + offset_x, y + offset_y,
		table.merge(optargs, { min_value = 1, max_value = 100 }))
	offset_y = offset_y + GoaHud_DrawOptionsVariable(weapon, "useShadow", x + offset_x, y + offset_y, optargs)
	offset_y = offset_y + GoaHud_DrawOptionsVariable(weapon, "shadowAlpha", x + offset_x + 40, y + offset_y,
		table.merge(optargs, { min_value = 0, max_value = 255, tick = 1, enabled = optargs.enabled and weapon.useShadow }), "Alpha")
	offset_y = offset_y + GoaHud_DrawOptionsVariable(weapon, "shadowSize", x + offset_x + 40, y + offset_y,
		table.merge(optargs, { min_value = 0, max_value = 50, enabled = optargs.enabled and weapon.useShadow }), "Size")
	offset_y = offset_y + GoaHud_DrawOptionsVariable(weapon, "strokeWidth", x + offset_x, y + offset_y,
		table.merge(optargs, { min_value = 0.1, max_value = 50, enabled = optargs.enabled and (weapon.crosshair >= 2 and weapon.crosshair <= 3) }))
	offset_y = offset_y + GoaHud_DrawOptionsVariable(weapon, "holeSize", x + offset_x, y + offset_y,
		table.merge(optargs, { min_value = 0, max_value = 20, enabled = optargs.enabled and weapon.crosshair == 3 }))
	
	return offset_y
end

function GoaHud_Crosshair:drawPreview(x, y, intensity)
	nvgSave()
	self:drawCrosshair(selectedCrosshairIndex - 1, x + 300, y + 40, 1.0 - intensity)
	nvgRestore()
	
	return 80
end

function GoaHud_Crosshair:draw()
	if (not shouldShowHUD(optargs_deadspec)) then return end
	
	local player = getPlayer()
	if (not player) then return end -- quick hack fix
	
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
	
	local func = self.drawSvg
	if (type(crosshair_template[1]) == "string") then
		drawSvg(crosshair_settings, crosshair_template, final_color)
	else
		crosshair_template[1](crosshair_settings, crosshair_template, final_color)
	end
end

function drawDot(self, crosshair, color)
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

function drawCircle(self, crosshair, color)
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

function drawCross(self, crosshair, color)
	local line_end = self.holeSize * self.strokeWidth/2
	local line_start = self.size + line_end
	
	if (self.useShadow) then
		-- TODO: kill me
		local shadow_end = line_end - self.shadowSize/2
		local shadow_start = line_start + self.shadowSize/2

		nvgStrokeWidth(self.strokeWidth + self.shadowSize)

		local hole_adjust = 0

		local a = line_start-line_end
		local b = line_start-line_end+(self.strokeWidth + self.shadowSize)*2
		local c = (self.strokeWidth+self.shadowSize) 
		
		local x = -line_start
		local y = 0

		nvgBeginPath()
		nvgStrokeBoxGradient(x, y, a-hole_adjust, 0, 0, c, Color(0,0,0,self.shadowAlpha), Color(0,0,0,0))
		nvgRoundedRect(x-c, y, b, 0, 0)
		nvgStroke()
		
		x = line_end
		nvgBeginPath()
		nvgStrokeBoxGradient(x+hole_adjust, y, a-hole_adjust, 0, 0, c, Color(0,0,0,self.shadowAlpha), Color(0,0,0,0))
		nvgRoundedRect(x-c, y, b, 0, 0)
		nvgStroke()
		
		y = -line_start
		x = 0
		
		nvgBeginPath()
		nvgStrokeBoxGradient(x, y, 0, a-hole_adjust, 0, c, Color(0,0,0,self.shadowAlpha), Color(0,0,0,0))
		nvgRoundedRect(x, y-c, 0, b, 0)
		nvgStroke()
		
		y = line_end
		
		nvgBeginPath()
		nvgStrokeBoxGradient(x, y+hole_adjust, 0, a-hole_adjust, 0, c, Color(0,0,0,self.shadowAlpha), Color(0,0,0,0))
		nvgRoundedRect(x, y-c, 0, b, 0)
		nvgStroke()
	end
	
	if (self.holeSize == 0) then
		nvgStrokeColor(color)
		nvgStrokeWidth(self.strokeWidth)
	
		nvgBeginPath()
		
		nvgMoveTo(-self.size, 0)
		nvgLineTo(self.size, 0)
		
		nvgMoveTo(0, -self.size)
		nvgLineTo(0, self.size)
		
		nvgStroke()
	else
		-- lines
		nvgStrokeColor(color)
		nvgStrokeWidth(self.strokeWidth)
		
		nvgBeginPath()

		nvgMoveTo(-line_start, 0)
		nvgLineTo(-line_end, 0)
		
		nvgMoveTo(line_start, 0)
		nvgLineTo(line_end, 0)
		
		nvgMoveTo(0, -line_start)
		nvgLineTo(0, -line_end)
		
		nvgMoveTo(0, line_start)
		nvgLineTo(0, line_end)
		
		nvgStroke()
	end
end

function drawSvg(self, crosshair, color)
	nvgFillColor(Color(0,0,0, self.shadowAlpha))
	nvgSvg(crosshair[1], 0, 0, self.size, self.shadowSize)
	
	nvgFillColor(color)
	nvgSvg(crosshair[1], 0, 0, self.size, 0)
end