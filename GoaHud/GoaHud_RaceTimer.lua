-- GoaHud_RaceTimer made by GoaLitiuM
--
-- Race timer
--

require "base/internal/ui/reflexcore"

GoaHud_RaceTimer =
{
	offset = { x = 0, y = -220 },
	anchor = { x = 0, y = 1 },

	recalculateBounds = true,
	textOffsetX = 0,
	textOffsetY = 0,
	textWidth = 0,
	textHeight = 0,
	lastMins = -1,
	myBest = 0,
	lastMap = "",

	options =
	{
		shadow =
		{
			shadowEnabled = true,
			shadowOffset = 4,
			shadowBlur = 6,
			shadowColor = Color(0,0,0,255),
			shadowStrength = 1,
		},
	},
};
GoaHud:registerWidget("GoaHud_RaceTimer");

function GoaHud_RaceTimer:init()
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

function GoaHud_RaceTimer:setupText()
	nvgTextLetterSpacing(-2)
	nvgFontFace(GOAHUD_FONT2)
	nvgFontSize(120)
end

function GoaHud_RaceTimer:draw()
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
	local best = (self.myBest > player.score) and self.myBest or player.score
	local time_raw = player.raceActive and player.raceTimeCurrent or player.raceTimePrevious

	local t = self:formatTime(time_raw)
	local display_str = string.format("%02d:%02d.%03d", t.mins, t.secs, t.millis)

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

		nvgRestore()

		self.recalculateBounds = false
	end

	local margin = 12
	local x = -self.textOffsetX - self.textWidth/2
	local y = self.textOffsetY + margin

	-- race time
	self:setupText()
	nvgTextAlign(NVG_ALIGN_RIGHT, NVG_ALIGN_TOP)

	local color = Color(255,255,255,255)
	if (time_raw == 0) then
		color = Color(255,255,255,128)
	elseif (time_raw > best and best > 0) then
		color = Color(255,0,0,255)
	end

	GoaHud:drawTextShadow(x, y, display_str, self.options.shadow, { alpha = color.a })
	nvgFillColor(color)
	nvgText(x, y, display_str)

	self.lastMins = t.mins
end