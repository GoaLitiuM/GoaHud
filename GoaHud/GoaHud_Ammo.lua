-- GoaHud_Ammo made by GoaLitiuM
--
-- Ammo display widget, shown on-demand
--

require "base/internal/ui/reflexcore"

GoaHud_Ammo =
{
	offset = { x = 0, y = 190 },

	timer = 0.0,
	lastAmmo = -1,
	lastWeapon = -1,
	state = AMMO_STATE_SWITCHING,
	fixShotgunAmmoWarning = false,

	progress = 0.0,

	options =
	{
		showTime = 1.5,
		fadeTime = 0.1,
		ammoColor = Color(255, 255, 255, 255),
		ammoColorWarning = Color(255, 0, 0, 255),

		shadow =
		{
			shadowEnabled = true,
			shadowOffset = 3,
			shadowBlur = 8,
			shadowColor = Color(0,0,0,255),
			shadowStrength = 1,
		},
	},

	optionsDisplayOrder = { "showTime", "fadeTime", "ammoColor", "ammoColorWarning", "shadow", },
}
GoaHud:registerWidget("GoaHud_Ammo");

function GoaHud_Ammo:init()
	self.fixShotgunAmmoWarning = true
end

function GoaHud_Ammo:drawOptionsVariable(varname, x, y, optargs)
	if (varname == "fadeTime") then
		local optargs = clone(optargs)
		optargs.milliseconds = true
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs)
	end
	return nil
end

local preview_timer = 0.0
function GoaHud_Ammo:drawPreview(x, y, intensity)
	y = y - GOAHUD_SPACING*1.5
	nvgSave()
	local width = 150
	local height = 60
	x = x + 225
	nvgBeginPath()
	nvgFillLinearGradient(x, y, x + width + 90, y + height, Color(0,0,0,0), Color(255,255,255,255))
	nvgRect(x, y, width, height)
	nvgFill()

	local cycle_time = self.options.showTime + self.options.fadeTime + 1.0
	preview_timer = preview_timer + deltaTimeRaw
	if (preview_timer >= cycle_time) then
		self.lastWeapon = -1
		preview_timer = 0.0
	end

	self:tick()

	nvgTranslate(x + 75, y + 40)
	self:drawAmmo(0, 0, 25, Color(255,255,255,255), self.progress)

	nvgRestore()
	return height + 20 - GOAHUD_SPACING*1.5
end

function GoaHud_Ammo:tick()
	local player = getPlayer()
	local weapon
	local ammo

	if (player ~= nil) then
		weapon = player.weaponIndexweaponChangingTo
		ammo = player.weapons[weapon].ammo
	else
		weapon = 2
		ammo = 25
	end

	if (ammo ~= self.lastAmmo or weapon ~= self.lastWeapon) then
		if (self.state == AMMO_STATE_SHOWING) then
			self.timer = 0.0
		else
			self.state = AMMO_STATE_SWITCHING
		end

		self.lastAmmo = ammo
		self.lastWeapon = weapon
	end

	if (self.state == AMMO_STATE_SWITCHING or self.state == AMMO_STATE_HIDING) then
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
		if (self.options.showTime > 0.0) then
			self.timer = self.timer + deltaTimeRaw

			if (self.timer >= self.options.showTime) then
				self.timer = 0.0
				self.state = AMMO_STATE_HIDING
			end
		end
	end

	self.progress = self.timer / self.options.fadeTime
	if (self.state == AMMO_STATE_SHOWING) then self.progress = 1.0
	elseif (self.state == AMMO_STATE_HIDING) then self.progress = 1.0 - self.progress end

	if (GoaHud.previewMode) then self.progress = 1.0 end
end

function GoaHud_Ammo:draw()
	if (not shouldShowHUD()) then return end

	local player = getPlayer()
	local weapon = player.weaponIndexweaponChangingTo
	local ammo = player.weapons[weapon].ammo
	local ammo_warning = player.weapons[weapon].lowAmmoWarning

	self:tick()

	local color = self.options.ammoColor
	local alpha = self.progress
	if (ammo <= ammo_warning) then
		alpha = math.max(0.3, alpha)
		color = self.options.ammoColorWarning
		self.progress = 1.0
	end

	if (ammo ~= 0) then color = Color(color.r, color.g, color.b, color.a * alpha) end

	if (weapon ~= 1 or GoaHud.previewMode) then
		self:drawAmmo(0, 0, ammo, color, self.progress)
	end
end

function GoaHud_Ammo:drawAmmo(x, y, ammo, color, scale)
	nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_BASELINE)
	nvgScale(scale, scale)
	GoaHud:drawTextHA(x, y, 50, color, self.options.shadow, tostring(ammo))
end