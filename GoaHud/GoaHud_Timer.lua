-- GoaHud_Timer made by GoaLitiuM
--
-- Game timer widget with optional frag lead counter
--

require "base/internal/ui/reflexcore"

GoaHud_Timer =
{
	offset = { x = 0, y = 0 },
	anchor = { x = 0, y = -1 },

	options =
	{
		font = { index = 8, face = "" },
		fontSize = 80,
		letterSpacing = 0,
		textColor = Color(255,255,255,255),

		countdown = true,
		countdownRace = true,

		showScoreDiff = false,

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
		"preview",
		"font", "fontSize", "letterSpacing", "textColor",
		"",
		"countdown", "countdownRace",
		"",
		"showScoreDiff",
		"",
		"shadow",
	},
};
GoaHud:registerWidget("GoaHud_Timer");

local last_font = nil
local font_number_width = nil
local font_separator_width = nil
local font_y_offset = nil

function GoaHud_Timer:init()
end

function GoaHud_Timer:drawOptionsVariable(varname, x, y, optargs)
	if (varname == "preview") then
		return self:drawPreview(x, y, 1.0)
	elseif (varname == "letterSpacing") then
		local optargs = clone(optargs)
		optargs.min_value = -10
		optargs.max_value = 20
		optargs.tick = 1
		optargs.units = "px"
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs)
	elseif (varname == "showScoreDiff") then
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs, "Show Score Lead")
	end
	return nil
end

function GoaHud_Timer:drawPreview(x, y, intensity)
	self:calculateFontMetrics()
	local height = 120

	nvgSave()

	nvgSave()
	local width = 550
	nvgBeginPath()
	nvgFillLinearGradient(x, y, x + width, y + height, Color(0,0,0,0), Color(255,255,255,255))
	nvgRect(x, y, width, height)
	nvgFill()
	nvgRestore()

	self:setupText()

	local str = "01:38"
	local str_width = self:calculateTextWidth(str)
	local offset_x = round((-str_width + width) / 2)
	local offset_y = 0

	nvgFillColor(self.options.textColor)

	-- timer
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_TOP)
	self:drawText(offset_x + x, y + offset_y, str)

	-- score
	if (self.options.showScoreDiff) then
		offset_x = offset_x + str_width + font_separator_width

		nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_TOP)
		GoaHud:drawTextWithShadow(x + offset_x, y + offset_y, "+12", self.options.shadow)
	end
	nvgRestore()

	return height + 10
end

function GoaHud_Timer:setupText()
	nvgFontFace(GoaHud:getFont(self.options.font))
	nvgFontSize(self.options.fontSize)
end

function GoaHud_Timer:calculateFontMetrics()
	-- calculate dimensions of number glyphs
	local font = GoaHud:getFont(self.options.font)
	local font_size = self.options.fontSize
	local current_font = tostring(font) .. tostring(font_size)
	if (last_font ~= current_font) then
		last_font = current_font

		nvgSave()
		self:setupText()

		local maxw, maxy
		for i=0,9,1 do
			local b = nvgTextBounds(tostring(i))
			local w = round(b.maxx - b.minx)
			local h = b.maxy

			if (maxw == nil or w > maxw) then maxw = w end
			if (maxy == nil or h < maxy) then maxy = h end
		end

		font_number_width = maxw
		font_separator_width = nvgTextWidth(":")
		font_y_offset = maxy

		nvgRestore()
	end
end

function GoaHud_Timer:draw()
	self:calculateFontMetrics()

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
	end

	local t = GoaHud:formatTime(time_raw / 1000, timer_base)
	local display_str = string.format("%02d:%02d", t.mins_total, t.secs)

	-- round time
	self:setupText()

	nvgFillColor(self.options.textColor)

	local margin = 3
	local x = round(-self:calculateTextWidth(display_str) / 2)
	local y = -font_y_offset + margin

	-- draw the characters separately
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_TOP)
	self:drawText(x, y, display_str)

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

		x = -x + font_separator_width

		-- score text
		nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_TOP)
		GoaHud:drawTextWithShadow(x, y, score_diff_str, self.options.shadow)
	end
end

function GoaHud_Timer:calculateTextWidth(str)
	local width = -self.options.letterSpacing
	for i = 1, #str do
		local c = string.sub(str, i, i)
		if (c == ":") then width = width + font_separator_width
		else width = width + font_number_width end
		width = width + self.options.letterSpacing
	end
	return width
end

function GoaHud_Timer:drawText(x, y, str)
	local offset_x = 0
	for i = 1, #str do
		local c = string.sub(str, i, i)
		local separator = c == ":"
		local number_offset = 0

		if (not separator) then number_offset = number_offset + (font_number_width - nvgTextWidth(c)) / 2 end

		GoaHud:drawTextWithShadow(x + offset_x + number_offset, y, c, self.options.shadow, { ignoreEmojis = true })
		if (separator) then offset_x = offset_x + font_separator_width
		else offset_x = offset_x + font_number_width end
		offset_x = offset_x + self.options.letterSpacing
	end
end