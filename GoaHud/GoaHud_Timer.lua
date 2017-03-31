-- GoaHud_Timer made by GoaLitiuM
-- 
-- Game timer widget with optional frag lead counter
--

require "base/internal/ui/reflexcore"

GoaHud_Timer =
{
	offset = { x = 10, y = 0 },
	anchor = { x = 0, y = -1 },
	
	recalculateBounds = true,
	textOffsetX = 0,
	textOffsetY = 0,
	textWidth = 0,
	textHeight = 0,
	scoreOffsetX = 0,
	scoreWidth = 0,
	lastMins = -1,
	
	options = 
	{
		countdown = true,
		countdownRace = true,
		softBackground = true,
		showScoreDiff = true,
		shadow =
		{
			shadowEnabled = true,
			shadowOffset = 2,
			shadowBlur = 3,
			shadowColor = Color(0,0,0,255),
			shadowStrength = 1,
		},
	},
};
GoaHud:registerWidget("GoaHud_Timer");

function GoaHud_Timer:init()
end

function GoaHud_Timer:drawOptionsVariable(varname, x, y, optargs)
	if (varname == "showScoreDiff") then
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs, "Show Score Lead")
	end
	return nil
end

function GoaHud_Timer:setupText()
	nvgTextLetterSpacing(-1)

	nvgFontFace(GOAHUD_FONT2)
	nvgFontSize(80)
end

function GoaHud_Timer:drawText(x, y, color, value)
	x = round(x)
	y = round(y)
	GoaHud:drawTextShadow(x, y, self.options.shadow, value, color.a)
	nvgFillColor(color)
	nvgText(x, y, value)
end

function GoaHud_Timer:draw()
	if (not shouldShowHUD(optargs_deadspec)) then return end

	local player = getPlayer()
	local time_raw = 0
	local match_countdown = world.gameState == GAME_STATE_WARMUP and world.timerActive
	local race = gamemodes[world.gameModeIndex].shortName == "race"
	local countdown

	if (race) then
		countdown = self.options.countdownRace
	else
		countdown = self.options.countdown
	end
	
	if (match_countdown) then
		time_raw = world.gameTimeLimit - (math.floor(world.gameTime / 1000) * 1000)
	elseif (not world.timerActive) then
		time_raw = 0
	elseif (countdown) then
		time_raw = world.gameTimeLimit - world.gameTime
	else 
		time_raw = math.floor(world.gameTime / 1000) * 1000
	end

	local t = GoaHud:formatTime(time_raw)
	local display_str = string.format("%02d:%02d", t.mins, t.secs)
	
	if (t.mins ~= self.lastMins) then
		if (t.mins % 100 ~= self.lastMins % 100) then
			self.recalculateBounds = true
		end
	end
	
	if (self.recalculateBounds) then
		nvgSave()
		
		self:setupText()
		
		local bounds = nvgTextBounds(display_str)
		
		self.textOffsetX = -bounds.maxx
		self.textOffsetY = -bounds.maxy
		self.textWidth = bounds.maxx - bounds.minx
		self.textHeight = bounds.maxy - bounds.miny
		
		nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_TOP)
		bounds = nvgTextBounds("+99")
		
		self.scoreOffsetX = -bounds.maxx
		self.scoreWidth = bounds.maxx - bounds.minx
			
		nvgRestore()

		self.recalculateBounds = false
	end
	
	local margin = 12
	local margin_shadow_extra = 5
	local shadow_blur = 8
	local height_fix = 25
	local x = -self.textOffsetX - self.textWidth/2
	local y = self.textOffsetY + margin - 8
	
	-- background
	if (self.options.showBackground) then
		nvgBeginPath()
		if (self.options.softBackground) then
			nvgFillBoxGradient(x + self.textOffsetX - margin + margin_shadow_extra/2, y - self.textOffsetY - margin + margin_shadow_extra/2, self.textWidth + margin*2 - margin_shadow_extra, self.textHeight + margin*2 - height_fix - margin_shadow_extra, 0, shadow_blur, Color(0,0,0,64), Color(0,0,0,0))
		else
			nvgFillColor(Color(0, 0, 0, 64))
		end
		
		-- timer background
		nvgRect(x + self.textOffsetX - margin, y - self.textOffsetY - margin , self.textWidth + margin*2, self.textHeight + margin*2 - height_fix)
		nvgFill()
	end
	
	-- round time
	self:setupText()
	nvgTextAlign(NVG_ALIGN_RIGHT, NVG_ALIGN_TOP)
	
	self:drawText(x, y, Color(255,255,255,255), display_str)
	
	-- score difference
	if (self.options.showScoreDiff and not isRaceOrTrainingMode()) then
		local score_bg_color = Color(0,0,0,64)
		local game_mode = gamemodes[world.gameModeIndex]
		local current_score
		local other_score = 0
		local other_team = 0
		local other_player = -1
		
		local diff
		if (game_mode.hasTeams) then
			current_score = world.teams[player.team].score
			for i, t in pairs(world.teams) do
				if (i ~= player.team and t.score > other_score) then
					other_score = t.score
					other_team = i
				end
			end			
		else
			current_score = player.score
			for i, p in pairs(players) do
				if (p.state == PLAYER_STATE_INGAME) then
					if (p ~= player and p.score > other_score) then
						other_score = p.score
						other_player = i
					end
				end
			end
		end
		
		diff = current_score - other_score
		local sign = ""
		if (diff > 0) then sign = "+" end	
		local score_diff_str = string.format("%s%d", sign, diff)

		x = x - self.scoreOffsetX + margin*2 + 1
		
		-- score diff background
		if (self.options.showBackground) then
			nvgBeginPath()
			if (self.options.softBackground) then
				nvgFillBoxGradient(x - margin - self.scoreWidth/2 + margin_shadow_extra/2, y - self.textOffsetY - margin + margin_shadow_extra/2 , self.scoreWidth + margin*2 - margin_shadow_extra, self.textHeight + margin*2 - height_fix - margin_shadow_extra, 0, shadow_blur, score_bg_color, Color(0,0,0,0))
			else
				nvgFillColor(score_bg_color)
			end
			nvgRect(x - margin - self.scoreWidth/2, y - self.textOffsetY - margin , self.scoreWidth + margin*2, self.textHeight + margin*2 - height_fix)
			nvgFill()
		end
		
		-- stretch text to fit inside the rect
		if (math.abs(diff) >= 100) then
			nvgScale(0.7, 1.0)
			x = x / 0.7
		end
		
		-- score text
		nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_TOP)
		
		self:drawText(x, y, Color(255,255,255,255), score_diff_str)
	end
	
	self.lastMins = t.mins
end