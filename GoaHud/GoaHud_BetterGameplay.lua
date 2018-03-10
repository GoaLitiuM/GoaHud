-- GoaHud_BetterGameplay made by GoaLitiuM
--
-- Brings various improvements and miscellaneous stuff to Reflex.
--

GLOBAL_COLORS_DISABLED = 1
GLOBAL_COLORS_ENABLED = 2
GLOBAL_COLORS_STRIP = 3

GLOBAL_COLORS_NAMES =
{
	"Disabled (Untouched)",
	"Enabled",
	"Strip Colors"
}

GoaHud_BetterGameplay =
{
	enabled = false,
	options =
	{
		hideCasualTimers = false,

		raceFastRespawn = true,
		globalColors = GLOBAL_COLORS_DISABLED,
	},

	optionsDisplayOrder =
	{
		"duel",
			"hideCasualTimers",

		"race",
			"bindRespawn",
			"raceFastRespawn",

		"",
		"bindReadyToggle",
		"",

--		"ui",
		"globalColors",
	},

	respawning = false,
	forfeitDetoured = false,
}
GoaHud:registerWidget("GoaHud_BetterGameplay", GOAHUD_MODULE_EXPERIMENTAL)

local nvgText_real = nil
local nvgTextWidth_real = nil
local nvgTextBounds_real = nil
function GoaHud_BetterGameplay:init()
	nvgText_real = nvgText
	nvgTextWidth_real = nvgTextWidth
	nvgTextBounds_real = nvgTextBounds

	if (self.options ~= nil) then
		-- migrate old checkbox setting
		if (self.options.enableGlobalColors ~= nil) then
			if (self.options.enableGlobalColors) then
				self.options.globalColors = GLOBAL_COLORS_ENABLED
			else
				self.options.globalColors = GLOBAL_COLORS_DISABLED
			end

			self.options.enableGlobalColors = nil
			self:saveOptions()
			self:loadOptions()
		end
	end

	GoaHud:createConsoleVariable("respawn", "int", 0)
	GoaHud:setConsoleVariable("respawn", 0)

	GoaHud:createConsoleVariable("toggleready", "int", 0)
	GoaHud:setConsoleVariable("toggleready", 0)
end

local comboBoxData1 = {}
function GoaHud_BetterGameplay:drawOptionsVariable(varname, x, y, optargs)
	if (varname == "race") then
		GoaLabel("Race:", x, y, optargs)
		return GOAHUD_SPACING
	elseif (varname == "duel") then
		GoaLabel("Duel:", x, y, optargs)
		return GOAHUD_SPACING
	--elseif (varname == "ui") then
	--	GoaLabel("UI:", x, y, optargs)
	--	return GOAHUD_SPACING

	elseif (varname == "bindRespawn") then
		local offset_x = GOAHUD_INDENTATION
		GoaLabel("Bind Respawn (Race):", x + offset_x, y, optargs)
		GoaKeyBind("ui_goahud_respawn 1", x + offset_x + 200, y, 150, "game", optargs)
		optargs.optionalId = optargs.optionalId + 1
		return GOAHUD_SPACING
	elseif (varname == "bindReadyToggle") then
		local offset_x = GOAHUD_INDENTATION
		GoaLabel("Bind Toggle Ready:", x + offset_x, y, optargs)
		GoaKeyBind("ui_goahud_toggleready 1", x + offset_x + 200, y, 150, "game", optargs)
		optargs.optionalId = optargs.optionalId + 1
		return GOAHUD_SPACING
	elseif (varname == "raceFastRespawn") then
		local optargs = clone(optargs)
		optargs.indent = 1
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs, "Fast Respawn")
	elseif (varname == "hideCasualTimers") then
		return GoaHud_DrawOptionsVariable(self.options, varname, x + GOAHUD_INDENTATION, y, optargs, "Hide Casual Item Timers")
	elseif (varname == "globalColors") then
		GoaLabel("Enable Color Codes In All Addons (Experimental): ", x, y, optargs)
		GoaLabel("Color Codes: ", x + GOAHUD_INDENTATION, y + GOAHUD_SPACING, optargs)
		self.options.globalColors = GoaComboBoxIndex(GLOBAL_COLORS_NAMES, self.options.globalColors, x + GOAHUD_INDENTATION + 200, y + GOAHUD_SPACING, 250, comboBoxData1, optargs)
		return GOAHUD_SPACING*2
	end
	return nil
end

local PickupTimers_draw = nil
local lastGameState = nil
local readyChanges = 0
local readySpamEnd = 0
local readyLastPress = 0
function GoaHud_BetterGameplay:draw()
	local local_player = getLocalPlayer()

	if (self.options.globalColors ~= GLOBAL_COLORS_DISABLED) then
		if (self.options.globalColors == GLOBAL_COLORS_ENABLED) then
			nvgText = nvgTextEmoji
			nvgTextWidth = nvgTextWidthEmoji
			nvgTextBounds = nvgTextBoundsEmoji
		elseif (self.options.globalColors == GLOBAL_COLORS_STRIP) then
			nvgText = nvgTextStrip
			nvgTextWidth = nvgTextWidthStrip
			nvgTextBounds = nvgTextBoundsStrip
		end
	else
		nvgText = nvgText_real
		nvgTextWidth = nvgTextWidth_real
		nvgTextBounds = nvgTextBounds_real
	end

	local respawn = GoaHud:getConsoleVariable("respawn")
	if (respawn ~= 0) then
		GoaHud:setConsoleVariable("respawn", 0)

		if (isRaceOrTrainingMode()) then
			consolePerformCommand("suicide")
		end
	end

	local toggle_ready = GoaHud:getConsoleVariable("toggleready")
	if (toggle_ready ~= 0) then
		GoaHud:setConsoleVariable("toggleready", 0)
		-- prevent user spamming the key too often, also throttles the changes when key is being held
		if (readyChanges < 4 and epochTimeMs-readyLastPress > 0.2) then
			if (local_player and local_player.ready) then
				consolePerformCommand("notready")
			else
				consolePerformCommand("ready")
			end
		end
		readyLastPress = epochTimeMs
		readySpamEnd = epochTimeMs + 1.1
		readyChanges = readyChanges + 1
	end
	if (epochTime >= readySpamEnd) then
		readyChanges = 0
	end

	if (self.respawning) then
		consolePerformCommand("-attack")
		self.respawning = false
	end

	if (world == nil) then return end

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