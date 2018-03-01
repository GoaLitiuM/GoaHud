-- GoaHud_RaceTimer made by GoaLitiuM
--
-- Race timer
--

require "base/internal/ui/reflexcore"

GoaHud_RaceTimer =
{
	offset = { x = 0, y = -220 },
	anchor = { x = 0, y = 1 },

	myBest = 0,
	lastMap = "",

	options =
	{
		font = { index = 8, face = "" },
		fontSize = 120,
		letterSpacing = 0,
		textColor = Color(255,255,255,255),

		enableTimerColors = true,
        timerColorDimmed = Color(255,255,255,128),
        timerColorSlow = Color(255,0,0,255),

		shadow =
		{
			shadowEnabled = true,
			shadowOffset = 4,
			shadowBlur = 6,
			shadowColor = Color(0,0,0,255),
			shadowStrength = 1,
		},
	},

	optionsDisplayOrder =
	{
		"font", "fontSize", "letterSpacing", "textColor",
		"",
		"enableTimerColors", "timerColorDimmed", "timerColorSlow",
		"",
		"shadow",
	},
};
GoaHud:registerWidget("GoaHud_RaceTimer");

function GoaHud_RaceTimer:init()
end

function GoaHud_RaceTimer:drawOptionsVariable(varname, x, y, optargs)
	if (varname == "letterSpacing") then
		local optargs = clone(optargs)
		optargs.min_value = -10
		optargs.max_value = 20
		optargs.tick = 1
		optargs.units = "px"
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs)
	elseif (varname == "timerColorDimmed" or varname == "timerColorSlow") then
		local optargs = clone(optargs)
		optargs.enabled = self.options.enableTimerColors
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs)
	end
	return nil
end

function GoaHud_RaceTimer:updateBestScore(map, mode)
	self.myBest = 0

	local leaderboard = QuerySelfLeaderboard(map, mode)
	if (leaderboard ~= nil) then
		for entrySteamId, entry in pairs(leaderboard.friendsEntries) do
			if (entrySteamId == steamId) then
				self.myBest = entry.timeMillis
			end
		end
		return true
	end

	return false
end

function isRaceOrTrainingMode()
	if (world == nil) then return false end
	local gameMode = gamemodes[world.gameModeIndex]
	if (gameMode == nil) then return false end
	return gameMode.shortName == "race" or gameMode.shortName == "training"
end

function GoaHud_RaceTimer:formatTime(elapsed)
	local seconds_total = math.floor(elapsed / 1000)
	return
	{
		secs = seconds_total % 60,
		mins = math.floor(seconds_total / 60),
		millis = elapsed % 1000,
	}
end

local last_font = nil
local font_number_width = nil
local font_separator_width = nil
local font_y_offset = nil

function GoaHud_RaceTimer:calculateFontMetrics()
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

function GoaHud_RaceTimer:setupText()
	nvgFontFace(GoaHud:getFont(self.options.font))
	nvgFontSize(self.options.fontSize)
end

function GoaHud_RaceTimer:draw()
	self:calculateFontMetrics()

	if (not shouldShowHUD()) then return end
	if (not GoaHud.previewMode and not isRaceOrTrainingMode()) then
		self.lastMap = ""
		return
	end

	local gameMode = gamemodes[world.gameModeIndex]
	if (gameMode == nil) then return end

	if (world.mapName ~= self.lastMap) then
		if (self:updateBestScore(world.mapName, gameMode.shortName)) then
			self.lastMap = world.mapName
		end
	end

	local player = getPlayer()
	local best = self.myBest
	local time_raw = player.raceActive and player.raceTimeCurrent or player.raceTimePrevious

	local t = self:formatTime(time_raw)
	local display_str = string.format("%02d:%02d:%03d", t.mins, t.secs, t.millis)

	if (player.score < best) then best = player.score end

	-- race time
	local timer_color = self.options.textColor
	if (self.options.enableTimerColors) then
        if (time_raw == 0 or time_raw == best) then
            timer_color = self.options.timerColorDimmed
        elseif (time_raw > best and best > 0) then
            timer_color = self.options.timerColorSlow
        end
	end

	local margin = 3
	local x = round(-self:calculateTextWidth(display_str) / 2)
	local y = -font_y_offset + margin

	-- draw the characters separately
	self:setupText()
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_TOP)
	nvgFillColor(timer_color)
	self:drawText(x, y, display_str)
end

function GoaHud_RaceTimer:calculateTextWidth(str)
	local width = -self.options.letterSpacing
	for i = 1, #str do
		local c = string.sub(str, i, i)
		if (c == ":") then width = width + font_separator_width
		else width = width + font_number_width end
		width = width + self.options.letterSpacing
	end
	return width
end

function GoaHud_RaceTimer:drawText(x, y, str)
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