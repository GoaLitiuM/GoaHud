-- GoaHud_Armor made by GoaLitiuM
--
-- Displays animated armor numbers
--

require "base/internal/ui/reflexcore"

GoaHud_Armor =
{
	offset = { x = 10, y = -50 },
	anchor = { x = 0, y = 1 },

	tickTimer = 0.0,
	playerHealth = -1,
	playerArmor = -1,

	deadTimer = 0.0,
	deadFadeTime = 1.0,

	options =
	{
		font = { index = 5, face = "" },
		fontSize = 120,

		tickInterval = 0.01,
		hideInRace = true,

		dimNoArmor = true,
		armorColorGreen = Color(0,255,0,255),
		armorColorYellow = Color(255,255,0,255),
		armorColorRed = Color(255,0,0,255),

		shadow =
		{
			shadowEnabled = true,
			shadowOffset = 4,
			shadowBlur = 5,
			shadowColor = Color(0,0,0,255),
			shadowStrength = 1.5,
		},
	},
	optionsDisplayOrder = {
		"font", "fontSize",
		"",
		"tickInterval",
		"hideInRace",
		"",
		"dimNoArmor",
		"armorColorGreen",
		"armorColorYellow",
		"armorColorRed",
		"shadow",
	},
};
GoaHud:registerWidget("GoaHud_Armor");

function GoaHud_Armor:init()
end

function GoaHud_Armor:drawOptionsVariable(varname, x, y, optargs)
	if (varname == "tickInterval") then
		local optargs = clone(optargs)
		optargs.milliseconds = true
		optargs.min_value = 0
		optargs.max_value = 75
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs, "Animation Speed")
	end
	return nil
end

function GoaHud_Armor:getArmorColor(health, armor, protection)
	if (protection == 0) then return self.options.armorColorGreen
	elseif (protection == 1) then return self.options.armorColorYellow
	else return self.options.armorColorRed end
end

function GoaHud_Armor:draw()
	if (not GoaHud.previewMode) then
		if (not shouldShowHUD(optargs_deadspec)) then return end
		if (self.options.hideInRace and isRaceMode()) then return end
	end

	local player = getPlayer()
	local health = 100
	local armor = 100
	local protection = 1
	local hidden = false

	if (player ~= nil) then
		health = player.health
		armor = player.armor
		protection = player.armorProtection
		hidden = player.infoHidden
	end

	if (self.playerHealth ~= health and health <= 0) then
		self.deadTimer = self.deadFadeTime
	end
	if (self.deadTimer > 0.0) then
		self.deadTimer = self.deadTimer - deltaTimeRaw
	end

	if (self.options.tickInterval > 0) then
		self.tickTimer = self.tickTimer + deltaTimeRaw
		while (self.tickTimer >= self.options.tickInterval) do
			self.tickTimer = self.tickTimer - self.options.tickInterval

			if (armor > self.playerArmor) then
				self.playerArmor = self.playerArmor + 1
			elseif (armor < self.playerArmor) then
				self.playerArmor = self.playerArmor - 1
			end

			if (self.playerArmor < 0) then self.playerArmor = 0 end
		end

		-- catch up faster if difference is too large
		if (math.abs(armor - self.playerArmor) >= 10) then self.tickTimer = self.tickTimer + (self.options.tickInterval * 3) end
	else
		self.playerArmor = armor
	end
	self.playerHealth = health

	local armor_str, armor_color
	if (not hidden) then
		armor_str = tostring(self.playerArmor)
		armor_color = clone(GoaHud_Armor:getArmorColor(health, armor, protection))
		if (self.options.dimNoArmor and self.playerArmor == 0) then armor_color.a = 64 end
	else
		armor_str = "?"
		armor_color = clone(self.options.armorColorYellow)
	end

	if (health <= 0 and not hidden) then
		armor_color.a = self.deadTimer / self.deadFadeTime * armor_color.a
	end

	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_BASELINE)
	nvgFontFace(GoaHud:getFont(self.options.font))
	nvgFontSize(self.options.fontSize)
	nvgFillColor(armor_color)

	GoaHud:drawTextWithShadow(0, 0, armor_str, self.options.shadow, { alpha = armor_color.a })
end
