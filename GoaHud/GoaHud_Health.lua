-- GoaHud_Health made by GoaLitiuM
--
-- Displays animated health numbers
--

require "base/internal/ui/reflexcore"

GoaHud_Health =
{
	offset = { x = -10, y = -50 },
	anchor = { x = 0, y = 1 },

	tickTimer = 0.0,
	playerHealth = -1,
	fontSize = 120,

	deadTimer = 0.0,
	deadFadeTime = 1.0,

	options =
	{
		tickInterval = 0.01,
		hideInRace = true,

		healthColorNormal = Color(255,255,255,255),
		healthColorMega = Color(64,64,255,255),
		healthColorRocket = Color(255,255,0,255),
		healthColorRail = Color(255,0,0,255),

		shadow =
		{
			shadowEnabled = true,
			shadowOffset = 4,
			shadowBlur = 5,
			shadowColor = Color(0,0,0,255),
			shadowStrength = 1.5,
		},
	},
	optionsDisplayOrder = { "tickInterval", "hideInRace", "healthColorNormal", "healthColorMega", "healthColorRocket", "healthColorRail", "shadow", },
};
GoaHud:registerWidget("GoaHud_Health");

function GoaHud_Health:init()
end

function GoaHud_Health:drawOptionsVariable(varname, x, y, optargs)
	if (varname == "tickInterval") then
		local optargs = clone(optargs)
		optargs.milliseconds = true
		optargs.min_value = 0
		optargs.max_value = 75
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs, "Animation Speed")
	end
	return nil
end

function GoaHud_Health:getHealthColor(health, armor, protection, mega)
	if (health > 100) then
		local fade = math.min(20, health-100) / 20
		local color_target = GoaHud_Health:getHealthColor(100, armor, protection)
		local color = self.options.healthColorMega
		if (not mega) then color = self.options.healthColorNormal end
		color = Color(
			lerp(color_target.r, color.r, fade),
			lerp(color_target.g, color.g, fade),
			lerp(color_target.b, color.b, fade),
			lerp(color_target.a, color.a, fade))
		return color
	end

	local effective_health = GoaHud:getEffectiveHealth(health, armor, protection)
	if (effective_health <= 80) then return self.options.healthColorRail
	elseif (effective_health <= 100) then return self.options.healthColorRocket end

	return self.options.healthColorNormal
end

function GoaHud_Health:draw()
	if (not GoaHud.previewMode) then
		if (not shouldShowHUD(optargs_deadspec)) then return end
		if (self.options.hideInRace and isRaceMode()) then return end
	end

	local player = getPlayer()
	local health = math.max(0, player.health)
	local armor = player.armor

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

			if (health > self.playerHealth) then
				self.playerHealth = self.playerHealth + 1
			elseif (health < self.playerHealth) then
				self.playerHealth = self.playerHealth - 1
			end

			if (self.playerHealth < 0) then self.playerHealth = 0 end
		end

		-- catch up faster if difference is too large
		if (math.abs(health - self.playerHealth) >= 10) then self.tickTimer = self.tickTimer + (self.options.tickInterval * 3) end
	else
		self.playerHealth = health
	end

	local health_str, health_color
	if (not player.infoHidden) then
		health_str = tostring(self.playerHealth)
		health_color = clone(GoaHud_Health:getHealthColor(health, armor, player.armorProtection, player.hasMega))
	else
		health_str = "?"
		health_color = clone(self.options.healthColorNormal)
	end

	if (health <= 0 and not player.infoHidden) then
		health_color.a = self.deadTimer / self.deadFadeTime * health_color.a
	end

	nvgTextAlign(NVG_ALIGN_RIGHT, NVG_ALIGN_BASELINE)
	GoaHud:drawTextHA(0, 0, self.fontSize, health_color, self.options.shadow, health_str)
end