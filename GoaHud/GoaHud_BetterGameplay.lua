-- GoaHud_BetterGameplay made by GoaLitiuM
--
-- Brings various improvements and miscellaneous stuff to Reflex.
--

GoaHud_BetterGameplay =
{
	enabled = false,
	options =
	{
		hideCasualTimers = false,
		raceFastRespawn = true,
		enableGlobalColors = false,
	},

	optionsDisplayOrder =
	{
		"duel",
		"hideCasualTimers",

		"race",
		"bindRespawn",
		"raceFastRespawn",
		
		"ui",
		"enableGlobalColors",
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
	elseif (varname == "duel") then
		GoaLabel("Duel:", x, y, optargs)
		return GOAHUD_SPACING
	elseif (varname == "ui") then
		GoaLabel("UI:", x, y, optargs)
		return GOAHUD_SPACING
	elseif (varname == "bindRespawn") then
		local offset_x = GOAHUD_INDENTATION
		GoaLabel("Bind Respawn (Race):", x + offset_x, y, optargs)
		GoaKeyBind("ui_goahud_respawn 1", x + offset_x + 200, y, 150, "game", optargs)
		optargs.optionalId = optargs.optionalId + 1
		return GOAHUD_SPACING
	elseif (varname == "raceFastRespawn") then
		return GoaHud_DrawOptionsVariable(self.options, varname, x + GOAHUD_INDENTATION, y, optargs, "Fast Respawn")
	elseif (varname == "hideCasualTimers") then
		return GoaHud_DrawOptionsVariable(self.options, varname, x + GOAHUD_INDENTATION, y, optargs, "Hide Casual Item Timers")
	elseif (varname == "enableGlobalColors") then
		return GoaHud_DrawOptionsVariable(self.options, varname, x + GOAHUD_INDENTATION, y, optargs, "Enable Color Codes Globally (Experimental)")
	end
	return nil
end

local PickupTimers_draw = nil
local nvgText_real = nil
local nvgTextWidth_real = nil
local nvgTextBounds_real = nil
function GoaHud_BetterGameplay:draw()
	if (self.options.enableGlobalColors) then
		if (nvgText_real == nil) then
			nvgText_real = nvgText
			nvgText = nvgTextEmoji
		end
		if (nvgTextWidth_real == nil) then
			nvgTextWidth_real = nvgTextWidth
			nvgTextWidth = nvgTextWidthEmoji
		end
		if (nvgTextBounds_real == nil) then
			nvgTextBounds_real = nvgTextBounds
			nvgTextBounds = nvgTextBoundsEmoji
		end
	else
		if (nvgText_real ~= nil) then nvgText = nvgText_real end
		if (nvgTextWidth_real ~= nil) then nvgTextWidth = nvgTextWidth_real end
		if (nvgTextBounds_real ~= nil) then nvgTextBounds = nvgTextBounds_real end
		nvgText_real = nil
		nvgTextWidth_real = nil
		nvgTextBounds_real = nil
	end
	
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

	local local_player = getLocalPlayer()
	if (isRaceOrTrainingMode()) then
		if (local_player ~= nil) then
			if (self.options.raceFastRespawn and local_player.isDead) then
				consolePerformCommand("+attack")
				self.respawning = true
			end
		end
	elseif (isDuel()) then
		local spectating = local_player.state == PLAYER_STATE_SPECTATOR
		if (not spectating and world.ruleset == "casual" and self.options.hideCasualTimers) then
			if (PickupTimers ~= nil and PickupTimers_draw == nil) then
				PickupTimers_draw = PickupTimers.draw
				PickupTimers.draw = function() end
			end
		else
			if (PickupTimers_draw ~= nil) then
				PickupTimers.draw = PickupTimers_draw
				PickupTimers_draw = nil
			end
		end
	end
end

function isDuel()
	if world == nil then return false end;
	local gameMode = gamemodes[world.gameModeIndex];
	if gameMode == nil then return false end;
	return gameMode.shortName == "1v1";
end