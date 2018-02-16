-- GoaHud_Messages made by GoaLitiuM
--
-- Displays current game mode, warmup and spectator information
--

require "base/internal/ui/reflexcore"

GoaHud_Messages =
{
	canPosition = false,

	options =
	{
		font = { index = 5, face = "" },
		messageFontSize = 40,
		gameModeFontSize = 40,
		warmupFontSize = 24,
		countdownFontSize = 120,

		showSpectatorControls = true,
		showCountry = false,

		messageFadeInTime = 0.15,
		messageShowTime = 5.0,
		messageFadeOutTime = 0.5,

		gameModeShowTime = 10.0,
		gameModeFadeTime = 1.5,

		shadow =
		{
			shadowEnabled = true,
			shadowOffset = 2,
			shadowBlur = 3,
			shadowColor = Color(0,0,0,255),
			shadowStrength = 1,
		},

		movableMessages = Movable.new
		{
			name = "Messages",
			offset = { x = 0, y = -150 },
			anchor = { x = 0, y = 0 },
		},
		movableCountdown = Movable.new
		{
			name = "Countdown",
			offset = { x = 0, y = -260 },
			anchor = { x = 0, y = 0 },
		},
		movableGameMode = Movable.new
		{
			name = "GameMode",
			offset = { x = 0, y = 160 },
			anchor = { x = 0, y = -1 },
		},
		movableWarmup = Movable.new
		{
			name = "Warmup",
			offset = { x = 0, y = 190 },
			anchor = { x = 0, y = -1 },
		},
		movableFollowText = Movable.new
		{
			name = "FollowText",
			offset = { x = 0, y = -270 },
			anchor = { x = 0, y = 1 },
		},
		movableControlsText = Movable.new
		{
			name = "Controls",
			offset = { x = 0, y = -240 },
			anchor = { x = 0, y = 1 },
		},

	},
	optionsDisplayOrder =
	{
		"font", "messageFontSize", "gameModeFontSize", "warmupFontSize", "countdownFontSize",
		"showSpectatorControls", "showCountry",
		"",
		"messageFadeInTime", "messageShowTime", "messageFadeOutTime",
		"",
		"gameModeShowTime", "gameModeFadeTime",
		"",
		"shadow",
		"movableMessages", "movableCountdown", "movableGameMode", "movableWarmup", "movableFollowText", "movableControlsText",
	},

	lastReady = {},
	readyList = { { "nobody", true, 0} },

	gameMessages = {},
	gameMessagesPreview = {},

	gameModeTimer = 0.0,

	bindTimer = 1.0,
	followText = "",
	followTextFreecam = "",
	lastSec = -1,
	timer = 0.0,
};
GoaHud:registerWidget("GoaHud_Messages")

function GoaHud_Messages:init()
	self:addMovableElement(self.options.movableMessages, self.drawMessages)
	self:addMovableElement(self.options.movableCountdown, self.drawCountdown)
	self:addMovableElement(self.options.movableGameMode, self.drawGameModeText)
	self:addMovableElement(self.options.movableWarmup, self.drawWarmupText)
	self:addMovableElement(self.options.movableFollowText, self.drawFollowText)
	self:addMovableElement(self.options.movableControlsText, self.drawControls)

	table.insert(self.gameMessagesPreview,
	{
		text = "someone returned the flag",
		color = Color(0, 255, 0, 255),
		length = 9999999999999,
		time = self.timer,
	})
	table.insert(self.gameMessagesPreview,
	{
		text = "somebody captured the flag",
		color = Color(52, 125, 255, 255),
		length = 9999999999999,
		time = self.timer,
	})
end

function GoaHud_Messages:drawOptionsVariable(varname, x, y, optargs)
	if (varname == "messageFadeInTime") then
		GoaLabel("Game Messages:", x, y, optargs)
		return GOAHUD_SPACING + GoaHud_DrawOptionsVariable(self.options, varname, x, y + GOAHUD_SPACING, table.merge(optargs, { milliseconds = true, max_value = 1000, indent = 1 }), "Fade In Time")
	elseif (varname == "messageShowTime") then
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, table.merge(optargs, { max_value = 10.0, indent = 1 }), "Show Time")
	elseif (varname == "messageFadeOutTime") then
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, table.merge(optargs, { milliseconds = true, max_value = 1000, indent = 1 }), "Fade Out Time")
	elseif (varname == "gameModeShowTime") then
		GoaLabel("Game Mode Title:", x, y, optargs)
		return GOAHUD_SPACING + GoaHud_DrawOptionsVariable(self.options, varname, x, y + GOAHUD_SPACING, table.merge(optargs, { max_value = 30.0, indent = 1 }), "Show Time")
	elseif (varname == "gameModeFadeTime") then
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, table.merge(optargs, { indent = 1 }), "Fade Time")
	elseif (string.find(varname, "movable") ~= nil) then
		return 0
	end
	return nil
end

function GoaHud_Messages:onPlayerReady(player, ready)
end

function GoaHud_Messages:onLog(entry)
	-- CTF events
	if (entry.type == LOG_TYPE_CTFEVENT) then
		local team_color = teamColors[entry.ctfTeamIndex]

		local text = "???"
		if (entry.ctfPlayerName ~= "") then
			if (entry.ctfEvent == CTF_EVENT_CAPTURE) then
				text = entry.ctfPlayerName .. " captured the flag"
			elseif (entry.ctfEvent == CTF_EVENT_RETURN) then
				text = entry.ctfPlayerName .. " returned the flag"
			elseif (entry.ctfEvent == CTF_EVENT_PICKUP) then
				text = entry.ctfPlayerName .. " picked up the flag"
			elseif (entry.ctfEvent == CTF_EVENT_DROPPED) then
				text = entry.ctfPlayerName .. " dropped the flag"
			end
		else
			local team_name = world.teams[entry.ctfTeamIndex].name
			if (entry.ctfEvent == CTF_EVENT_RETURN) then
				text = team_name .. " flag was returned"
			end
		end

		self:newMessage(
		{
			text = text,
			color = team_color,
			length = self.options.messageShowTime,
		})
	end
end

function GoaHud_Messages:newMessage(message)
	message.time = self.timer
	table.insert(self.gameMessages, message)
end

function GoaHud_Messages:draw()
	if (world == nil) then return end

	self.timer = self.timer + deltaTimeRaw

	local match_countdown = (world.gameState == GAME_STATE_WARMUP or world.gameState == GAME_STATE_ROUNDPREPARE) and world.timerActive

	-- countdown ticking sound
	if (match_countdown) then
		local seconds = math.max(1, math.ceil((world.gameTimeLimit - world.gameTime) / 1000))
		if (seconds ~= self.lastSec) then
			self.lastSec = seconds
			playSound("internal/ui/match/match_countdown_tick")
		end
	end
end

local function shouldHide()
	local hide = false

	if (GoaHud.previewMode) then hide = false end

	if (not shouldShowHUD(optargs_deadspec)) then hide = true end
	if (not shouldShowStatus()) then hide = true end
	if (world == nil) then hide = true end

	return hide
end

function GoaHud_Messages:drawMessages()
	local message_font_size = self.options.messageFontSize
	local messages

	if (GoaHud.previewMode) then
		messages = clone(self.gameMessagesPreview)
	else
		messages = clone(self.gameMessages)
	end

	table.reverse(messages)

	nvgFontFace(GoaHud:getFont(self.options.font))
	nvgFontSize(message_font_size)

	for i, message in pairs(messages) do
		local message_start_time = message.time + self.options.messageFadeInTime
		local message_end_time = message_start_time + message.length + self.options.messageFadeOutTime

		if (self.timer < message_end_time) then
			local color = clone(message.color)
			local fade = 1.0
			if (self.timer < message_start_time) then
				fade = 1.0 - math.min(self.options.messageFadeInTime, message_start_time - self.timer) / self.options.messageFadeInTime
			elseif (self.options.messageFadeOutTime > 0.0) then
				fade = math.min(self.options.messageFadeOutTime, message_end_time - self.timer) / self.options.messageFadeOutTime
			end
			color.a = color.a * EaseIn(fade)

			nvgFillColor(color)

			local text_width = nvgTextWidthEmoji(message.text, { emojiSize = message_font_size })
			GoaHud:drawTextWithShadow(-text_width/2, 0 - ((i-1) * message_font_size), message.text, self.options.shadow, { alpha = color.a, emojiSize = message_font_size})
		end
		if (self.timer >= message_end_time) then
			table.remove(self.gameMessages, #messages - i)
		end
	end
end

function GoaHud_Messages:drawCountdown()
	if (shouldHide()) then return end
	local match_countdown = (world.gameState == GAME_STATE_WARMUP or world.gameState == GAME_STATE_ROUNDPREPARE) and world.timerActive
	local seconds = math.max(1, math.ceil((world.gameTimeLimit - world.gameTime) / 1000))

	if (GoaHud.previewMode) then
		match_countdown = true
		seconds = (seconds % 10) + 1
	end

	if (match_countdown) then
		nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_BASELINE)
		nvgFontFace(GoaHud:getFont(self.options.font))
		nvgFontSize(self.options.countdownFontSize)
		nvgFillColor(Color(255,255,255,255))

		GoaHud:drawTextWithShadow(0, 0,  tostring(seconds), self.options.shadow)
	end
end

function GoaHud_Messages:drawGameModeText()
	if (shouldHide()) then return end

	self.gameModeTimer = self.gameModeTimer + deltaTimeRaw

	local game_mode = gamemodes[world.gameModeIndex]
	local game_mode_alpha = 1.0

	if (world.gameState ~= GAME_STATE_WARMUP) then
		if (self.gameModeTimer >= self.options.gameModeShowTime) then
			game_mode_alpha = math.max(0.0, 1.0 - ((self.gameModeTimer - self.options.gameModeShowTime) / self.options.gameModeFadeTime))
		end
	end

	if (GoaHud.previewMode) then
		game_mode_alpha = 1.0
	end

	if (game_mode_alpha > 0.0) then
		local game_mode_text
		if (world.isMatchmakingLobby) then
			game_mode_text = "LOBBY"
		else
			-- use simple heuristics to detect the ruleset
			game_mode_text = game_mode.name
			local ruleset_text = world.ruleset
			if (world.ruleset ~= "competitive") then
				if (world.ruleset == "experimental_plus") then
					if (weaponDefinitions[2].reloadTime == 450) then
						ruleset_text = "RMC competitive"
					elseif (weaponDefinitions[1].reloadTime == 1000 and weaponDefinitions[1].damagePerPellet == 100) then
						ruleset_text = "sushi competitive"
					elseif (weaponDefinitions[1].reloadTime == 800 and weaponDefinitions[1].damagePerPellet == 80) then
						ruleset_text = "sushi 2v2 competitive"
					elseif (weaponDefinitions[2].reloadTime == 500 or (weaponDefinitions[1].reloadTime == 800 and weaponDefinitions[1].damagePerPellet == 90)) then
						if (weaponDefinitions[6].maxAmmo == 20) then
							ruleset_text = "CR2 competitive"
						else
							ruleset_text = "CR2 team competitive"
						end
					end
				end
			else
				-- HACK: detect actual values from RL ammo
				local rl_ammo = 0
				local player = getPlayer()
				if (player) then rl_ammo = player.weapons[6].ammo end

				ruleset_text = nil
				if (weaponDefinitions[1].reloadTime == 1000 or rl_ammo == 25) then
					ruleset_text = "Legacy competitive"
				end
			end
			if (ruleset_text ~= nil) then
				game_mode_text = string.format("%s (%s)", game_mode_text, string.upper(ruleset_text))
			end
		end

		nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_BASELINE)
		nvgFontFace(GoaHud:getFont(self.options.font))
		nvgFontSize(self.options.gameModeFontSize)
		nvgFillColor(Color(255,255,255,game_mode_alpha * 255))

		GoaHud:drawTextWithShadow(0, 0, game_mode_text, self.options.shadow, { alpha = game_mode_alpha * 255 })
	end
end

function GoaHud_Messages:drawWarmupText()
	if (shouldHide()) then return end

	local world = world

	if (GoaHud.previewMode) then
		world = clone(world)
		world.gameState = GAME_STATE_WARMUP
	end

	if (world.gameState ~= GAME_STATE_WARMUP) then return end

	local game_mode = gamemodes[world.gameModeIndex]
	local players_ready = 0
	local players_total = 0
	local players_required = game_mode.playersRequired
	for i, p in ipairs(players) do
		if (p.connected and p.state == PLAYER_STATE_INGAME) then
			if (p.ready) then players_ready = players_ready + 1 end
			players_total = players_total + 1

			if (self.lastReady[i] ~= p.ready) then
				self:onPlayerReady(p, p.ready)
				self.lastReady[i] = p.ready
			end
		end
	end

	-- warmup info
	local warmup_text = ""
	if (not world.isMatchmakingLobby) then
		local warmup_format = "Warmup, %d/%d players ready"
		local player_target = players_ready
		if (world.matchmakingPlayerCount > 0) then
			players_required = world.matchmakingPlayerCount
			warmup_format = "Matchmaking, %d/%d players connected"
			player_target = players_total
		elseif (players_total < game_mode.playersRequired) then
			warmup_format = "Warmup, %d/%d required players joined"
			player_target = players_total
		end
		warmup_text = string.format(warmup_format, player_target, players_required)
	end

	nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_BASELINE)
	nvgFontFace(GoaHud:getFont(self.options.font))
	nvgFontSize(self.options.warmupFontSize)
	nvgFillColor(Color(255,255,255,200))

	GoaHud:drawTextWithShadow(0, 0, warmup_text, self.options.shadow)
end

function GoaHud_Messages:drawFollowText()
	if (shouldHide()) then return end

	local local_player = getLocalPlayer()
	local player = getPlayer()
	local freecam = local_player.index == player.index
	local playerIndexCameraAttachedTo = playerIndexCameraAttachedTo

	if (GoaHud.previewMode) then
		local_player = clone(local_player)
		local_player.state = PLAYER_STATE_SPECTATOR
		playerIndexCameraAttachedTo = -222
		freecam = false
	end

	if (local_player.state == PLAYER_STATE_SPECTATOR or
		local_player.state == PLAYER_STATE_QUEUED or
		playerIndexCameraAttachedTo ~= playerIndexLocalPlayer) then

		local name_font_size = self.options.messageFontSize
		nvgFontFace(GoaHud:getFont(self.options.font))
		nvgFontSize(name_font_size)

		if (not freecam) then
			local name_width = nvgTextWidthEmoji(player.name, { emojiSize = name_font_size })
			local offset_x = -name_width / 2
			if (self.options.showCountry and isValidCountry(player.country)) then
				nvgSave()

				local flag_svg = "internal/ui/icons/flags/" .. player.country
				local flag_size = name_font_size * 0.5
				local flag_offset = 8
				offset_x = offset_x + flag_size + flag_offset/2

				if (self.options.shadow.shadowEnabled) then
					nvgFillColor(Color(0,0,0,255))
					nvgSvg(flag_svg, -name_width/2 - flag_offset/2 + self.options.shadow.shadowOffset, 0 - flag_size/2 + self.options.shadow.shadowOffset, flag_size, self.options.shadow.shadowBlur * 1.5)
				end

				nvgFillColor(Color(255,255,255,255))
				nvgSvg(flag_svg, -name_width/2 - flag_offset/2, 0 - flag_size/2, flag_size)

				nvgRestore()
			end

			nvgFillColor(Color(255,255,255,255))
			GoaHud:drawTextWithShadow(offset_x, 0, player.name, self.options.shadow)
		end
	end
end

function GoaHud_Messages:drawControls()
	if (shouldHide()) then return end

	local local_player = getLocalPlayer()
	local player = getPlayer()
	local freecam = local_player.index == player.index
	local playerIndexCameraAttachedTo = playerIndexCameraAttachedTo

	if (GoaHud.previewMode) then
		local_player = clone(local_player)
		local_player.state = PLAYER_STATE_SPECTATOR
		playerIndexCameraAttachedTo = -222
		freecam = false
	end

	if (local_player.state == PLAYER_STATE_SPECTATOR or
		local_player.state == PLAYER_STATE_QUEUED or
		playerIndexCameraAttachedTo ~= playerIndexLocalPlayer) then

		self.bindTimer = self.bindTimer + deltaTimeRaw
		if (self.bindTimer >= 1.0) then
			local camera_next_command = "cl_camera_next_player"
			local camera_prev_command = "cl_camera_prev_player"
			local camera_free_command = "cl_camera_freecam"
			if (GoaHud:isWidgetEnabled("GoaHud_BetterSpectator")) then
				camera_next_command = GoaHud_BetterSpectator:getHookedBind(camera_next_command) or camera_next_command
				camera_prev_command = GoaHud_BetterSpectator:getHookedBind(camera_prev_command) or camera_prev_command
				camera_free_command = GoaHud_BetterSpectator:getHookedBind(camera_free_command) or camera_free_command
			end

			local camera_next_key = bindReverseLookup(camera_next_command, "game")
			local camera_prev_key = bindReverseLookup(camera_prev_command, "game")
			local camera_free_key = bindReverseLookup(camera_free_command, "game")

			self.followText = string.format("[%s] Next, [%s] Previous, [%s] Freecam", string.upper(camera_next_key), string.upper(camera_prev_key), string.upper(camera_free_key))

			if (camera_next_command == "+attack") then
				self.followTextFreecam = string.format("[%s] or [%s] Follow Players", string.upper(camera_next_key), string.upper(camera_free_key))
			elseif (camera_prev_command == "+attack") then
				self.followTextFreecam = string.format("[%s] or [%s] Follow Players", string.upper(camera_prev_key), string.upper(camera_free_key))
			else
				self.followTextFreecam = string.format("[%s] Follow Players", string.upper(camera_free_key))
			end

			self.bindTimer = 0.0
		end

		if (self.options.showSpectatorControls) then
			nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_BASELINE)

			local follow_text
			if (not freecam) then
				follow_text = self.followText
			else
				follow_text = self.followTextFreecam
			end

			local controls_font_size = 24
			nvgFontSize(controls_font_size)
			nvgFontFace(GOAHUD_FONT4)

			nvgFillColor(Color(255,255,255,196))

			GoaHud:drawTextWithShadow(0, 0, follow_text, self.options.shadow, {})

			if (GoaHud:isWidgetEnabled("GoaHud_BetterSpectator")) then
				local mode = GoaHud_BetterSpectator:getAutoSpectatorModeName()
				GoaHud:drawTextWithShadow(0, controls_font_size, mode, self.options.shadow, {})
			end
		end
	end
end