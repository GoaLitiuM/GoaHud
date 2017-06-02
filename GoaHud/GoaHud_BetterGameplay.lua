GoaHud_BetterGameplay =
{
	enabled = false,
	options =
	{
		raceFastRespawn = true,
	},

	optionsDisplayOrder =
	{
		"race",
		"bindRespawn",
		"raceFastRespawn",
	},

	respawning = false,
	forfeitDetoured = false,
}
GoaHud:registerWidget("GoaHud_BetterGameplay", GOAHUD_MODULE_EXPERIMENTAL)

function GoaHud_BetterGameplay:init()
	GoaHud:createConsoleVariable("respawn", "int", 0)
	GoaHud:setConsoleVariable("respawn", 0)
end

function GoaHud_BetterGameplay:drawOptionsVariable(varname, x, y, optargs)
	if (varname == "race") then
		GoaLabel("Race:", x, y, optargs)
		return GOAHUD_SPACING
	elseif (varname == "bindRespawn") then
		local offset_x = GOAHUD_INDENTATION
		GoaLabel("Bind Respawn (Race):", x + offset_x, y, optargs)
		GoaKeyBind("ui_goahud_respawn 1", x + offset_x + 200, y, 150, "game", optargs)
		optargs.optionalId = optargs.optionalId + 1
		return GOAHUD_SPACING
	elseif (varname == "raceFastRespawn") then
		return GoaHud_DrawOptionsVariable(self.options, varname, x + GOAHUD_INDENTATION, y, optargs, "Fast Respawn")
	end
	return nil
end

function GoaHud_BetterGameplay:draw()
	local respawn = GoaHud:getConsoleVariable("respawn")
	if (respawn ~= 0) then
		GoaHud:setConsoleVariable("respawn", 0)

		if (isRaceOrTrainingMode()) then
			consolePerformCommand("suicide")
		end
	end

	if (self.respawning) then
		consolePerformCommand("-attack")
		self.respawning = false
	end

	if (world == nil) then return end

	if (isRaceOrTrainingMode()) then
		local local_player = getLocalPlayer()
		if (local_player ~= nil) then
			if (self.options.raceFastRespawn and local_player.isDead) then
				consolePerformCommand("+attack")
				self.respawning = true
			end
		end
	end
end