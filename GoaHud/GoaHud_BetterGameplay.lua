GoaHud_BetterGameplay =
{
	enabled = false,
	options =
	{
		fastRaceRespawn = true,
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
	if (varname == "fastRaceRespawn") then
		local offset = 0

		ui2Label("Race-only suicide bind:   bind <key> ui_goahud_respawn 1", x, y + offset, optargs)
		offset = offset + 50

		return offset + GoaHud_DrawOptionsVariable(self.options, varname, x, y + offset, optargs, "Fast Respawn (Race)")
	end
	return nil
end

function GoaHud_BetterGameplay:tick()
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
			if (self.options.fastRaceRespawn and local_player.isDead) then
				consolePerformCommand("+attack")
				self.respawning = true
			end
		end
	end
end