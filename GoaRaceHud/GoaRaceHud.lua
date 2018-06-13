-- GoaRaceHud made by GoaLitiuM and lolograde
--
-- Race hud inspired by the HUD used in DeFRaG World Cup 2017 movie.
--

require "base/internal/ui/reflexcore"

function clone(t)
    if type(t) ~= "table" then return t end
    local meta = getmetatable(t)
    local target = {}
    for k, v in pairs(t) do
		target[k] = clone(v)
    end
    setmetatable(target, meta)
    return target
end

function table.merge(t, y)
	local n = clone(t)
	for i, k in pairs(y) do
		n[i] = k
	end
	return n
end

local Movable_defaults =
{
	name = "Generic Movable",
	addonName = "GoaRaceHud",
	offset = { x = 0, y = 0, },
	anchor = { x = 0, y = 0, },
	scale = 1.0,
	zIndex = 0,
	visible = true,
	isMenu = false,
	canPosition = true,
	canHide = true,
}
local Movable = { }
function Movable.new(o)
	o = table.merge(Movable_defaults, o)
	return o
end

GoaRaceHud =
{
    canPosition = false,

    lastVelocity = 0,
    lastPosition = { x=0, y=0, z=0 },
    landedTimer = 0,
    myBest = 0,
    textOffset = 0,

    options =
    {
        font = { index = 1, face = "forgotten futurist bd" },
		fontSize = 90,
        letterSpacing = 0,
        textSkew = 0.14,

        showPlayerFlag = true,
        textColor = Color(255,255,255,255),
        enableTimerColors = false,
        timerColorDimmed = Color(255,255,255,128),
        timerColorSlow = Color(255,0,0,255),

        landingShakeTime = 0.35,
        landingShakeSize = 20,
        showBestTime = false,

        overridePlayerFlag = "",

        movableName = Movable.new
		{
			name = "Name",
			offset = { x = 15, y = -110 },
			anchor = { x = -1, y = 1 },
        },
        movableMapName = Movable.new
		{
			name = "MapName",
			offset = { x = 15, y = -35 },
			anchor = { x = -1, y = 1 },
        },
        movableSpeed = Movable.new
		{
			name = "Speed",
			offset = { x = -20, y = -110 },
			anchor = { x = 1, y = 1 },
        },
        movableTimer = Movable.new
		{
			name = "Timer",
			offset = { x = -20, y = -35 },
			anchor = { x = 1, y = 1 },
		},

        shadow =
        {
            shadowEnabled = true,
            shadowOffset = 2,
            shadowBlur = 4,
            shadowColor = Color(0,0,0,255),
            shadowStrength = 2,
        },
    },
    optionsDisplayOrder =
    {
        "font",
		"fontSize",
        "letterSpacing",
        "textSkew",
        "",
        "showPlayerFlag",
        "landingShakeTime",
        "landingShakeSize",
        "showBestTime",
        "",
        "textColor",
        "enableTimerColors",
        "timerColorDimmed",
        "timerColorSlow",
        "",
        "overridePlayerFlag",
        "",
        "movableName", "movableMapName", "movableSpeed", "movableTimer",
        "",
        "shadow",
    },
}
registerWidget("GoaRaceHud");

function GoaRaceHud:initialize()
    GoaHud:registerWidget("GoaRaceHud", GOAHUD_ADDON)

    local player = getPlayer()
    if (player) then
        self.lastVelocity = player.velocity.y
        self.lastPosition = clone(player.position)
    end

    self:addMovableElement(self.options.movableName, self.drawName)
	self:addMovableElement(self.options.movableMapName, self.drawMapName)
    self:addMovableElement(self.options.movableSpeed, self.drawSpeed)
    self:addMovableElement(self.options.movableTimer, self.drawTimer)
end

function GoaRaceHud:drawOptionsVariable(varname, x, y, optargs)
	if (varname == "letterSpacing") then
		local optargs = clone(optargs)
		optargs.min_value = -10
		optargs.max_value = 20
		optargs.tick = 1
		optargs.units = "px"
        return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs)
    elseif (varname == "textSkew") then
		local optargs = clone(optargs)
		optargs.min_value = -0.5
		optargs.max_value = 0.5
		optargs.tick = 1000
        return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs)
    elseif (varname == "landingShakeTime") then
		local optargs = clone(optargs)
		optargs.min_value = 0
		optargs.max_value = 2500
        optargs.milliseconds = true
        return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs)
    elseif (varname == "landingShakeSize") then
		local optargs = clone(optargs)
		optargs.min_value = -150
		optargs.max_value = 150
		optargs.tick = 1
        return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs)
    elseif (varname == "timerColorDimmed" or varname == "timerColorSlow") then
		local optargs = clone(optargs)
		optargs.enabled = self.options.enableTimerColors
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs)
	elseif (varname == "font") then
        return GoaHud_DrawOptionsVariable(self.options, varname, x, y, table.merge(optargs, { font = true }), "Font")
    end
end

function GoaRaceHud:updateBestScore(map, mode)
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

function GoaRaceHud:shouldShowRaceHud()
    local player = getPlayer()
    if (world == nil or player == nil) then return false end

    if (not shouldShowHUD()) then return false end
	if (not GoaHud.previewMode and not isRaceOrTrainingMode()) then
		self.lastMap = ""
		return false
    end
    return true
end

function GoaRaceHud:setupText(anchor)
    nvgTranslate(0, self.textOffset)

    nvgFontFace(GoaHud:getFont(self.options.font))
    nvgFontSize(self.options.fontSize)

    -- apply skew and align based on the current anchor setting
    if (anchor.x < 0) then
        nvgSkewY(-self.options.textSkew)
        nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_BASELINE)
    else
        nvgSkewY(self.options.textSkew)
        nvgTextAlign(NVG_ALIGN_RIGHT, NVG_ALIGN_BASELINE)
    end

    nvgFillColor(self.options.textColor)
end

function GoaRaceHud:drawName()
    if (not self:shouldShowRaceHud()) then return end

    self:setupText(self.options.movableName.anchor)

    local player = getPlayer()
    local player_country = player.country
    if (string.len(self.options.overridePlayerFlag) > 0) then player_country = self.options.overridePlayerFlag end
    local flag_svg = getFlag(player_country)
    local flag_offset = -self.options.fontSize * 0.06
    local flag_size = self.options.fontSize * 0.45

    -- player flag
    if (self.options.showPlayerFlag and flag_svg) then
        nvgFillColor(Color(255,255,255,255))
        GoaHud:drawSvgWithShadow(flag_svg, flag_size, -flag_size/2 + flag_offset, flag_size, 0, self.options.shadow)
    end

    -- player name
    nvgFillColor(self.options.textColor)
    if (self.options.showPlayerFlag and flag_svg) then
        GoaHud:drawTextWithShadow(flag_size*2, 0, " " .. player.name, self.options.shadow)
    else
        GoaHud:drawTextWithShadow(0, 0, player.name, self.options.shadow)
    end
end

function GoaRaceHud:drawMapName()
    if (not self:shouldShowRaceHud()) then return end

    self:setupText(self.options.movableMapName.anchor)
    GoaHud:drawTextWithShadow(0, 0, world.mapTitle, self.options.shadow)
end

function GoaRaceHud:drawSpeed()
    if (not self:shouldShowRaceHud()) then return end

    self:setupText(self.options.movableSpeed.anchor)
    local player = getPlayer()
    GoaHud:drawTextWithShadow(0, 0, tostring(math.floor(player.speed)) .. " UPS", self.options.shadow, { ignoreEmojis = true})
end

function GoaRaceHud:drawTimer()
    if (not self:shouldShowRaceHud()) then return end

    self:setupText(self.options.movableTimer.anchor)

    local player = getPlayer()
    local best = self.myBest
	local time_raw = player.raceActive and player.raceTimeCurrent or player.raceTimePrevious

	local t = self:formatTime(time_raw)
    local display_str = string.format("%02d:%02d:%03d", t.mins, t.secs, t.millis)

    if (player.score < best) then best = player.score end
    if (not self.options.showBestTime) then best = 0 end

    local timer_color = self.options.textColor

    if (self.options.enableTimerColors) then
        if (time_raw == 0) then
            timer_color = self.options.timerColorDimmed
        elseif (time_raw > best and best > 0) then
            timer_color = self.options.timerColorSlow
        end
    end

    -- calculate the widest text letter width for proper monospaced rendering
    local separator_width = nvgTextWidth(":")
    local letter_width
    for i=0,9,1 do
        local b = nvgTextBounds(tostring(i))
        local w = round(b.maxx - b.minx)

        if (letter_width == nil or w > letter_width) then letter_width = w end
    end

    local offset_x = (letter_width*(string.len(display_str)-2)) + (separator_width*2)

    nvgFillColor(timer_color)
    nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_BASELINE)
    self:drawTimerText(-offset_x, 0, display_str, letter_width, separator_width)
end

function GoaRaceHud:draw()
    if (not self:shouldShowRaceHud()) then return end

    if (replayName == "" and world.mapName ~= self.lastMap) then
        local gameMode = gamemodes[world.gameModeIndex]
		if (self:updateBestScore(world.mapName, gameMode.shortName)) then
			self.lastMap = world.mapName
		end
    end

    -- landing shake effect
    local player = getPlayer()
    local velocity = player.velocity.y

    if (self.landedTimer > 0) then self.landedTimer = self.landedTimer - deltaTime
    elseif (self.landedTimer < 0) then self.landedTimer = 0 end

    local velocity_diff = velocity - self.lastVelocity
    if (velocity_diff > 150 and self.lastVelocity < -55) then
        self.landedTimer = self.options.landingShakeTime
    end

    local landing_progress = self.landedTimer/self.options.landingShakeTime
    self.textOffset = (EaseIn(math.pow(landing_progress, 2))) * self.options.landingShakeSize

    self.lastVelocity = velocity
    self.lastPosition = clone(player.position)
end

function GoaRaceHud:drawTimerText(x, y, str, number_width, separator_width)
	local offset_x = 0
	for i = 1, #str do
		local c = string.sub(str, i, i)
		local separator = c == ":"
		local number_offset = 0

		if (not separator) then number_offset = number_offset + (number_width - nvgTextWidth(c)) / 2 end

		GoaHud:drawTextWithShadow(x + offset_x + number_offset, y, c, self.options.shadow, { ignoreEmojis = true })
		if (separator) then offset_x = offset_x + separator_width
		else offset_x = offset_x + number_width end
		offset_x = offset_x + self.options.letterSpacing
	end
end

function GoaRaceHud:formatTime(elapsed)
	local seconds_total = math.floor(elapsed / 1000)
	return
	{
		secs = seconds_total % 60,
		mins = math.floor(seconds_total / 60),
		millis = elapsed % 1000,
	}
end