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
		showSpectatorControls = true,
		showCountry = false,

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
	},
	optionsDisplayOrder = { "showSpectatorControls", "showCountry", "", "gameModeShowTime", "gameModeFadeTime", "", "shadow" },

	lastReady = {},
	readyList = { { "nobody", true, 0} },

	titleInfo =
	{
		text = "hello world",
		time = -99999,
		color = Color(255,255,255,255),
		length = 10,
	},

	gameModeTimer = 0.0,

	bindTimer = 1.0,
	followText = "",
	followTextFreecam = "",
	lastSec = -1,
	timer = 0.0,
};
GoaHud:registerWidget("GoaHud_Messages")

function GoaHud_Messages:init()
end

function GoaHud_Messages:drawOptionsVariable(varname, x, y, optargs)
	if (varname == "gameModeShowTime") then
		GoaLabel("Game Mode:", x, y, optargs)
		return GOAHUD_SPACING + GoaHud_DrawOptionsVariable(self.options, varname, x + GOAHUD_INDENTATION, y + GOAHUD_SPACING, optargs, "Show Time")
	elseif (varname == "gameModeFadeTime") then
		return GoaHud_DrawOptionsVariable(self.options, varname, x + GOAHUD_INDENTATION, y, optargs, "Fade Time")
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

		self.titleInfo =
		{
			text = text,
			time = self.timer,
			color = team_color,
			length = 4.0,
		}
	end
end

function GoaHud_Messages:draw()
	if (world == nil) then return end
	self.timer = self.timer + deltaTimeRaw

	local match_countdown = world.gameState == GAME_STATE_WARMUP and world.timerActive

	-- countdown ticking sound
	if (match_countdown) then
		local seconds = math.max(1, math.ceil((world.gameTimeLimit - world.gameTime) / 1000))
		if (seconds ~= self.lastSec) then
			self.lastSec = seconds
			playSound("internal/ui/match/match_countdown_tick")
		end
	end

	if (GoaHud_Zoom == nil or not GoaHud_Zoom.held) then
		if (not shouldShowHUD(optargs_deadspec)) then return end
	end

	local title_end_time = self.titleInfo.time + self.titleInfo.length + self.options.gameModeFadeTime
	if (self.timer < title_end_time) then
		local color = clone(self.titleInfo.color)
		if (self.options.gameModeFadeTime > 0.0) then
			color.a = color.a * math.min(self.options.gameModeFadeTime, title_end_time - self.timer) / self.options.gameModeFadeTime
		end

		local middle_y = -viewport.height/2 * 0.6 + 175

		nvgSave()
		GoaHud:drawTextStyle1(40)
		local text_width = nvgTextWidth(string.gsub(self.titleInfo.text, "%^[0-9]", ""))
		nvgRestore()

		GoaHud:drawText1(-text_width/2, middle_y, 40, color, self.options.shadow, self.titleInfo.text, true)
	end

	nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_BASELINE)

	if (match_countdown) then
		local seconds = math.max(1, math.ceil((world.gameTimeLimit - world.gameTime) / 1000))

		local alpha = 1.0
		local pos = -viewport.height/2 * 0.6 + 100
		GoaHud:drawText1(0, pos, 120, Color(255,255,255,alpha * 255), self.options.shadow, tostring(seconds))
	end

	local game_mode = gamemodes[world.gameModeIndex]

	self.bindTimer = self.bindTimer + deltaTimeRaw
	if (self.bindTimer >= 1.0) then
		local camera_next_command = "cl_camera_next_player"
		local camera_prev_command = "cl_camera_prev_player"
		local camera_free_command = "cl_camera_freecam"
		if (GoaHud_BetterSpecControls ~= nil and GoaHud_BetterSpecControls.enabled) then
			camera_next_command = GoaHud_BetterSpecControls:getHookedBind(camera_next_command) or camera_next_command
			camera_prev_command = GoaHud_BetterSpecControls:getHookedBind(camera_prev_command) or camera_prev_command
			camera_free_command = GoaHud_BetterSpecControls:getHookedBind(camera_free_command) or camera_free_command
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

	-- game mode information
	self.gameModeTimer = self.gameModeTimer + deltaTimeRaw
	local game_mode_alpha = 1.0
	if (world.gameState ~= GAME_STATE_WARMUP) then
		if (self.gameModeTimer >= self.options.gameModeShowTime) then
			game_mode_alpha = math.max(0.0, 1.0 - ((self.gameModeTimer - self.options.gameModeShowTime) / self.options.gameModeFadeTime))
		end
	end

	local top_y = -viewport.height/2 * 0.95 + 100
	if (game_mode_alpha > 0.0) then
		local game_mode_text
		if (world.isMatchmakingLobby) then
			game_mode_text = "LOBBY"
		else
			game_mode_text = game_mode.name
			if (world.ruleset ~= "competitive") then
				game_mode_text = string.format("%s (%s)", game_mode_text, string.upper(world.ruleset))
			end
		end

		GoaHud:drawText1(0, top_y, 40, Color(255,255,255,game_mode_alpha * 255), self.options.shadow, game_mode_text, true)
	end

	if (world.gameState == GAME_STATE_WARMUP) then
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

		GoaHud:drawTextHA(0, top_y+40, 24, Color(255,255,255,200), self.options.shadow, warmup_text)
	end

	-- spectator text
	local local_player = getLocalPlayer()
	local player = getPlayer()
	if (local_player.state == PLAYER_STATE_SPECTATOR or
		local_player.state == PLAYER_STATE_QUEUED or
		playerIndexCameraAttachedTo ~= playerIndexLocalPlayer) then

		local bottom_y = viewport.height/2 * 0.7 - 100
		local freecam = local_player.index == player.index
		local name_font_size = 40

		if (not freecam) then
			local offset_x = 0
			if (self.options.showCountry and isValidCountry(player.country)) then
				nvgSave()

				GoaHud:drawTextStyle1(name_font_size)
				local name_width = nvgTextWidth(player.name)

				local flag_svg = "internal/ui/icons/flags/" .. player.country
				local flag_size = name_font_size * 0.5
				local flag_offset = 8
				offset_x = offset_x + flag_size + flag_offset/2

				if (self.options.shadow.shadowEnabled) then
					nvgFillColor(Color(0,0,0,255))
					nvgSvg(flag_svg, -name_width/2 - flag_offset/2 + self.options.shadow.shadowOffset, bottom_y - flag_size/2 + self.options.shadow.shadowOffset, flag_size, self.options.shadow.shadowBlur * 1.5)
				end

				nvgFillColor(Color(255,255,255,255))
				nvgSvg(flag_svg, -name_width/2 - flag_offset/2, bottom_y - flag_size/2, flag_size)

				nvgRestore()
			end

			GoaHud:drawText1(offset_x, bottom_y, name_font_size, Color(255,255,255,255), self.options.shadow, player.name, true)
		end

		if (self.options.showSpectatorControls) then
			local spec_y = round(bottom_y)+25
			local follow_text
			if (not freecam) then
				follow_text = self.followText
			else
				follow_text = self.followTextFreecam
			end

			nvgFontSize(24)
			nvgFontFace(GOAHUD_FONT4)

			GoaHud:drawTextShadow(0, spec_y, follow_text, self.options.shadow)

			nvgFillColor(Color(255,255,255,196))
			nvgText(0, spec_y, follow_text)
		end
	end
end