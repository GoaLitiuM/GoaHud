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
		showScoreDiff = true,
		useBase25 = false,
		shadow =
		{
			shadowEnabled = true,
			shadowOffset = 2,
			shadowBlur = 3,
			shadowColor = Color(0,0,0,255),
			shadowStrength = 1,
		},
	},

	optionsDisplayOrder =
	{
		"countdown", "countdownRace",
		"",
		"showScoreDiff",
		"",
		"useBase25",
		"",
		"shadow",
	},
};
GoaHud:registerWidget("GoaHud_Timer");

function GoaHud_Timer:init()
end

function GoaHud_Timer:drawOptionsVariable(varname, x, y, optargs)
	if (varname == "showScoreDiff") then
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs, "Show Score Lead")
	elseif (varname == "useBase25") then
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs, "Use Base-25 Time")
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
	GoaHud:drawTextShadow(x, y, value, self.options.shadow, { alpha = color.a })
	nvgFillColor(color)
	nvgText(x, y, value)
end

function GoaHud_Timer:draw()
	if (not shouldShowHUD(optargs_deadspec)) then return end

	local race = isRaceOrTrainingMode()
	local countdown
	if (race) then
		countdown = self.options.countdownRace
	else
		countdown = self.options.countdown
	end

	local round_intermission = world.gameState == GAME_STATE_ROUNDPREPARE or world.gameState == GAME_STATE_ROUNDCOOLDOWN_SOMEONEWON or world.gameState == GAME_STATE_ROUNDCOOLDOWN_DRAW
	local timer_base = 60
	local time_raw
	if (round_intermission) then
		if (countdown) then
			time_raw = world.timeLimitRound * 1000
		else
			time_raw = 0
		end
	elseif (not world.timerActive) then
		time_raw = 0
	else
		if (countdown) then
			time_raw = world.gameTimeLimit - world.gameTime
		else
			time_raw = math.floor(world.gameTime / 1000) * 1000
		end

		if (self.options.useBase25 and not race) then timer_base = 25 end
	end

	local t = GoaHud:formatTime(time_raw / 1000, timer_base)
	local display_str = string.format("%02d:%02d", t.mins_total, t.secs)

	if (t.mins_total ~= self.lastMins) then
		if (t.mins_total % 100 ~= self.lastMins % 100) then
			self.recalculateBounds = true
		end
	end
	self.lastMins = t.mins_total

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
	local x = -self.textOffsetX - self.textWidth/2
	local y = self.textOffsetY + margin - 8

	-- round time
	self:setupText()
	nvgTextAlign(NVG_ALIGN_RIGHT, NVG_ALIGN_TOP)

	self:drawText(x, y, Color(255,255,255,255), display_str)

	-- score difference
	local player = getPlayer()
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

		-- stretch text to fit inside the rect
		if (math.abs(diff) >= 100) then
			nvgScale(0.7, 1.0)
			x = x / 0.7
		end

		-- score text
		nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_TOP)

		self:drawText(x, y, Color(255,255,255,255), score_diff_str)
	end
end