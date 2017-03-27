-- GoaHud_Messages made by GoaLitiuM
-- 
-- Displays current game mode, warmup and spectator information
--

require "base/internal/ui/reflexcore"

local FRAG_STYLE_NORMAL = 1
local FRAG_STYLE_Q3 = 2

local FRAG_STYLE_NAMES =
{
	"Normal",
	"Q3 Style",
}

local KILLER_STYLE_YOU = 1
local KILLER_STYLE_NAME_ALWAYS = 2
local KILLER_STYLE_NAME_SPECTATE = 3

local KILLER_STYLE_NAMES =
{
	"\"You\"",
	"Name",
	"Name (Spectate Only)",
}

GoaHud_Messages =
{
	canPosition = false,
	
	options =
	{
		fragStyle = FRAG_STYLE_Q3,
		killerNameStyle = KILLER_STYLE_NAME_SPECTATE,
		fragShowTime = 2.0,
		fragFadeTime = 0.15,
		
		showSpectatorControls = true,
		showFraggedMessage = true,
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
	optionsDisplayOrder = { "fragStyle", "killerNameStyle", "fragShowTime", "fragFadeTime", "", "showSpectatorControls", "showFraggedMessage", "showCountry", "", "gameModeShowTime", "gameModeFadeTime", "", "shadow" },
	
	lastReady = {},
	readyList = { { "nobody", true, 0} },
	fragInfo =
	{
		killer = "nobody",
		killed = { name = "nobody", country = "bot"},
		time = -99999,
		placement = 1,
		score = 13,
	},
	
	gameModeTimer = 0.0,
	
	bindTimer = 1.0,
	followText = "",
	followTextFreecam = "",
	lastSec = -1,
	timer = 0.0,
};
GoaHud:registerWidget("GoaHud_Messages");

function GoaHud_Messages:init()
	assert(self.options.fragShowTime ~= nil, "fragShowTime not found")
	assert(self.options.fragFadeTime ~= 1.5, "fragShowTime wrong value")
end

local preview_timer = 99.0
function GoaHud_Messages:drawPreview(x, y, intensity)
	nvgSave()
	
	local cycle_time = self.options.fragShowTime + self.options.fragFadeTime + 0.5
	preview_timer = preview_timer + deltaTimeRaw
	if (preview_timer >= cycle_time) then
		local killer_name = "nobody"
		local killer_country = "bot"
		local killer_index = -1
		local player = getLocalPlayer()
		if (player ~= nil) then
			killer_name = player.name
			killer_country = player.country
			killer_index = player.index
		end
		
		self.fragInfo =
		{
			killer = { name = killer_name, country = killer_country, index = killer_index },
			killed = { name = "Goa", country = "fi", killer_index + 9999},
			score = math.random(1, 50),
			placement = math.random(1, 4),
			time = self.timer,
		}
		preview_timer = 0.0
	end

	self:drawFragged(x + 100, y + 120, intensity)
	
	nvgRestore()
	return 180
end

local comboBoxData1 = {}
local comboBoxData2 = {}
function GoaHud_Messages:drawOptionsVariable(varname, x, y, optargs)
	if (varname == "fragStyle") then
		local offset_y = 0

		local frag_style = self.options.fragStyle
		frag_style = FRAG_STYLE_NAMES[frag_style]
		
		ui2Label("Frag Style: ", x, y + offset_y, optargs)
		frag_style = GoaComboBox(FRAG_STYLE_NAMES, frag_style, x + 175, y + offset_y, 250, comboBoxData1, optargs)
		offset_y = offset_y - 50
		optargs.optionalId = optargs.optionalId + 1

		for i, name in pairs(FRAG_STYLE_NAMES) do
			if (frag_style == name) then frag_style = i end
		end
		
		self.options.fragStyle = frag_style

		return 50
	elseif (varname == "killerNameStyle") then
		local offset_y = 0

		local killer_style = self.options.killerNameStyle
		killer_style = KILLER_STYLE_NAMES[killer_style]
		
		ui2Label("Killer Name: ", x, y + offset_y, optargs)
		killer_style = GoaComboBox(KILLER_STYLE_NAMES, killer_style, x + 175, y + offset_y, 250, comboBoxData2, optargs)
		offset_y = offset_y - 50
		optargs.optionalId = optargs.optionalId + 1

		for i, name in pairs(KILLER_STYLE_NAMES) do
			if (killer_style == name) then killer_style = i end
		end
		
		self.options.killerNameStyle = killer_style

		return 50
	elseif (varname == "fragFadeTime") then
		local optargs = clone(optargs)
		optargs.milliseconds = true
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs)
	end
	return nil
end

function GoaHud_Messages:onPlayerReady(player, ready)
end

local last_id = -1
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
	
	local local_player = getLocalPlayer()
	if (local_player == nil) then return end
	
	nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_BASELINE)
	
	if (match_countdown) then	
		local seconds = math.max(1, math.ceil((world.gameTimeLimit - world.gameTime) / 1000))
		
		local alpha = 1.0
		local pos = -viewport.height/2 * 0.6 + 100
		GoaHud:drawTextHA(0, pos, 120, Color(255,255,255,alpha * 255), self.options.shadow, tostring(seconds))
	end
	
	local game_mode = gamemodes[world.gameModeIndex]
	
	self.bindTimer = self.bindTimer + deltaTimeRaw
	if (self.bindTimer >= 1.0) then
		local camera_next_command = "cl_camera_next_player"
		local camera_prev_command = "cl_camera_prev_player"
		local camera_free_command = "cl_camera_freecam"
		if (GoaHud_BetterSpecControls ~= nil and GoaHud_BetterSpecControls.enabled) then
			camera_next_command = GoaHud_BetterSpecControls:getHookedBind(camera_next_command)
			camera_prev_command = GoaHud_BetterSpecControls:getHookedBind(camera_prev_command)
			camera_free_command = GoaHud_BetterSpecControls:getHookedBind(camera_free_command)
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
		
		GoaHud:drawTextHA(0, top_y+0, 40, Color(255,255,255,game_mode_alpha * 255), self.options.shadow, game_mode_text)
	end

	if (world.gameState == GAME_STATE_WARMUP) then
		local players_ready = 0
		local players_total = 0	
		for i, p in ipairs(players) do
			if (p.connected) then
				if (p.ready) then players_ready = players_ready + 1 end
				players_total = players_total + 1
				
				if (self.lastReady[i] ~= p.ready) then
					self:onPlayerReady(p, p.ready)
					self.lastReady[i] = p.ready
				end
			end
		end
		
		-- warmup info
		local warmup_text
		if (world.isMatchmakingLobby) then
			warmup_text = ""
		else
			
			if (world.matchmakingPlayerCount > 0) then
				warmup_text = string.format("Matchmaking, %d/%d players connected", players_total, world.matchmakingPlayerCount)
			elseif (players_total < game_mode.playersRequired) then
				warmup_text = string.format("Warmup, %d/%d required players joined", players_total, game_mode.playersRequired)
			else
				warmup_text = string.format("Warmup, %d/%d players ready", players_ready, players_total)
			end
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
			if (self.options.showCountry) then	
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
			
			GoaHud:drawTextShadow(0, spec_y, self.options.shadow, follow_text)

			nvgFillColor(Color(255,255,255,196))
			nvgText(0, spec_y, follow_text)
		end
	end
	
	-- fragged message
	if (self.options.showFraggedMessage) then
		if (log[1] ~= nil and log[1].id ~= last_id) then
			local player = getPlayer()
			for i=#log, 1, -1 do
				local entry = log[i]
				if (entry.id > last_id) then
					last_id = entry.id
					
					if (entry.type == LOG_TYPE_DEATHMESSAGE and entry.deathKiller == player.name and not entry.deathSuicide) then			
						local function sortByScore(a, b)
							return a.score > b.score
						end

						local players_sorted = {}
						for i, p in ipairs(players) do
							if (p.connected) then
								table.insert(players_sorted, p)
							end
						end
						table.sort(players_sorted, sortByScore)
						
						local placement = -1
						local killed = nil
						for i, p in ipairs(players_sorted) do
							if (p.name == player.name) then
								placement = i
							end
							if (p.name == entry.deathKilled) then killed = p end
						end
	
						self.fragInfo =
						{
							killer = player,
							killed = killed,
							score = player.score,
							placement = placement,
							time = self.timer,
						}
					end
				end
			end
		end
	end
	
	self:drawFragged(0, -viewport.height/2 * 0.6 + 100, 1.0)
end

function GoaHud_Messages:drawFragged(x, y, intensity)
	local fragEndTime = self.fragInfo.time + self.options.fragShowTime + self.options.fragFadeTime
	if (self.timer <= fragEndTime) then
		local alpha
		if (self.options.fragFadeTime > 0.0) then
			alpha = math.min(self.options.fragFadeTime, fragEndTime - self.timer) / self.options.fragFadeTime
		else
			alpha = 1.0
		end
		
		alpha = alpha * intensity
		
		local title_font_size = 40
		local is_local_killer = true
		local killer = "You"
		local message = "fragged"
		local killed = self.fragInfo.killed.name
		
		if (self.options.killerNameStyle == KILLER_STYLE_NAME_ALWAYS) then
			killer = self.fragInfo.killer.name
			is_local_killer = false
		elseif (self.options.killerNameStyle == KILLER_STYLE_NAME_SPECTATE) then
			local local_player = getLocalPlayer()
			if (local_player.index ~= self.fragInfo.killer.index) then
				killer = self.fragInfo.killer.name
				is_local_killer = false
			end
		end

		nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_BASELINE)
		nvgSave()
		
		GoaHud:drawTextStyle1(title_font_size)
		local frag_width = nvgTextWidth(string.format("%s %s %s", killer, message, killed))
		local killer_width = nvgTextWidth(killer .. " ")
		local message_width = nvgTextWidth(message .. " ")
		
		nvgRestore()

		local flag_size = title_font_size * 0.5
		local flag_offset = 8
		
		local flag1_svg = "internal/ui/icons/flags/" .. self.fragInfo.killer.country
		local flag2_svg = "internal/ui/icons/flags/" .. self.fragInfo.killed.country
		
		local offset_x = -frag_width/2
		if (self.options.showCountry) then
			if (not is_local_killer) then
				offset_x = offset_x - (flag_size + flag_offset/2)*2
			else
				offset_x = offset_x - (flag_size + flag_offset/2)
			end
		end
		
		if (self.options.showCountry and not is_local_killer) then
			offset_x = offset_x + flag_size
			
			nvgSave()
			nvgGlobalAlpha(alpha)
			
			if (self.options.shadow.shadowEnabled) then
				nvgFillColor(Color(0,0,0,255))
				nvgSvg(flag1_svg, offset_x + x + self.options.shadow.shadowOffset, y - flag_size/2 + self.options.shadow.shadowOffset, flag_size, self.options.shadow.shadowBlur * 1.5)
			end
			
			nvgFillColor(Color(255,255,255,255))
			nvgSvg(flag1_svg, offset_x + x, y - flag_size/2, flag_size)
			
			nvgRestore()
			
			offset_x = offset_x + flag_size + flag_offset
		end

		GoaHud:drawText1(offset_x + x, y, title_font_size, Color(255,255,255,alpha * 255), self.options.shadow, killer, true)
		offset_x = offset_x + killer_width
		
		GoaHud:drawText1(offset_x + x, y, title_font_size, Color(255,255,255,alpha * 255), self.options.shadow, message, true)
		offset_x = offset_x + message_width
			
		if (self.options.showCountry) then
			offset_x = offset_x + flag_size
			
			nvgSave()
			nvgGlobalAlpha(alpha)
			
			if (self.options.shadow.shadowEnabled) then
				nvgFillColor(Color(0,0,0,255))
				nvgSvg(flag2_svg, offset_x + x + self.options.shadow.shadowOffset, y - flag_size/2 + self.options.shadow.shadowOffset, flag_size, self.options.shadow.shadowBlur * 1.5)
			end
			
			nvgFillColor(Color(255,255,255,255))
			nvgSvg(flag2_svg, offset_x + x, y - flag_size/2, flag_size)
			
			nvgRestore()
			
			offset_x = offset_x + flag_size + flag_offset
		end
		
		GoaHud:drawText1(offset_x + x, y, title_font_size, Color(255,255,255,alpha * 255), self.options.shadow, killed, true)

		nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_BASELINE)
		if (self.options.fragStyle == FRAG_STYLE_Q3) then
			local placement = tostring(self.fragInfo.placement)
			local placement_color = Color(255,255,255,alpha * 255)
			
			if (self.fragInfo.placement == 1) then placement = placement .. "st"; placement_color = Color(0,0,255,alpha * 255)
			elseif (self.fragInfo.placement == 2) then placement = placement .. "nd"; placement_color = Color(255,0,0,alpha * 255)
			elseif (self.fragInfo.placement == 3) then placement = placement .. "rd"; placement_color = Color(255,255,0,alpha * 255)
			else placement = placement .. "th" end

			local frag_extra_message = string.format(" place with %d", self.fragInfo.score)
			local frag_extra_full = placement .. frag_extra_message
			local size = 27
			GoaHud:drawTextStyle1(size)

			local offset_x = 0			
			local bounds_extra = nvgTextBounds(frag_extra_message)
			local bounds_placement = nvgTextBounds(placement)

			GoaHud:drawText1(x + offset_x + bounds_placement.maxx , y + size, size, Color(255,255,255,alpha * 255), self.options.shadow, frag_extra_message)
			GoaHud:drawText1(x + offset_x - bounds_extra.maxx, y + size, size, placement_color, self.options.shadow, placement)
		end
	end
end
