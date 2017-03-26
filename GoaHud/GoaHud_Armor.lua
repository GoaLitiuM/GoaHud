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
	playerArmor = 0,
	fontSize = 120,
	
	options = 
	{
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
	optionsDisplayOrder = { "tickInterval", "hideInRace", "dimNoArmor", "armorColorGreen", "armorColorYellow", "armorColorRed", "shadow", },
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
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs)
	end
	return nil
end

function GoaHud_Armor:getEffectiveHealth(health, armor, protection)
	local multi = 0.5
	if protection == 1 then multi = 0.666666666666666
	elseif protection == 2 then multi = 0.75 end
	
	return math.min(armor, health * (protection + 1)) + health
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
	local health = player.health
	local armor = player.armor

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
	
	local armor_str, armor_color
	if (not player.infoHidden) then
		armor_str = tostring(self.playerArmor)
		armor_color = clone(GoaHud_Armor:getArmorColor(health, armor, player.armorProtection))
		if (self.options.dimNoArmor and self.playerArmor == 0) then armor_color.a = 64 end
	else
		armor_str = "?"
		armor_color = self.options.armorColorYellow
	end

	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_BASELINE)
	GoaHud:drawTextHA(0, 0, self.fontSize, armor_color, self.options.shadow, armor_str)
end
