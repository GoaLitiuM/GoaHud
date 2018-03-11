-- GoaHud_TimerBigBig made by GoaLitiuM
--
-- Bigger, secondary timer for tracking pickup times
--

require "base/internal/ui/reflexcore"

GoaHud_TimerBig =
{
	offset = { x = 0, y = -220 },
	anchor = { x = 0, y = 1 },

	connectedTime = 0,

	options =
	{
		font = { index = 8, face = "" },
		fontSize = 120,
		letterSpacing = 0,
		textColor = Color(255,255,255,255),

		hideWhileSpectating = true,

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
		"hideWhileSpectating",
		"",
		"shadow",
	},
};
GoaHud:registerWidget("GoaHud_TimerBig", GOAHUD_UI_EXPERIMENTAL);

local last_font = nil
local font_number_width = nil
local font_separator_width = nil
local font_y_offset = nil

function GoaHud_TimerBig:init()
	self:onMatchChange()
end

function GoaHud_TimerBig:onMatchChange()
	self.connectedTime = epochTime
end

function GoaHud_TimerBig:drawOptionsVariable(varname, x, y, optargs)
	if (varname == "preview") then
		return self:drawPreview(x, y, 1.0)
	elseif (varname == "letterSpacing") then
		local optargs = clone(optargs)
		optargs.min_value = -10
		optargs.max_value = 20
		optargs.tick = 1
		optargs.units = "px"
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs)
	end
	return nil
end

function GoaHud_TimerBig:drawPreview(x, y, intensity)
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
	local offset_x = round((-self:calculateTextWidth(str) + width) / 2)
	local offset_y = 0

	nvgFillColor(self.options.textColor)

	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_TOP)
	self:drawText(offset_x + x, y + offset_y, str)

	nvgRestore()

	return height + 10
end

function GoaHud_TimerBig:setupText()
	nvgFontFace(GoaHud:getFont(self.options.font))
	nvgFontSize(self.options.fontSize)
end

function GoaHud_TimerBig:shouldShow()
	local show = shouldShowHUD(optargs_deadspec) and (GoaHud.previewMode or not isRaceOrTrainingMode())
	local local_player = getLocalPlayer()
	if (self.options.hideWhileSpectating and local_player ~= nil and local_player.state == PLAYER_STATE_SPECTATOR) then show = false end
	return show
end

function GoaHud_TimerBig:calculateFontMetrics()
	-- calculate dimensions of number glyphs
	local font = GoaHud:getFont(self.options.font)
	local font_size = self.options.fontSize
	local current_font = tostring(font) .. tostring(font_size)
	if (last_font ~= current_font) then
		last_font = current_font

		nvgSave()
		self:setupText()

		local maxh, maxy
		for i=0,9,1 do
			local b = nvgTextBounds(tostring(i))
			local w = round(b.maxx - b.minx)
			local h = b.maxy

			if (maxh == nil or w > maxh) then maxh = w end
			if (maxy == nil or h < maxy) then maxy = h end
		end

		font_number_width = maxh
		font_separator_width = nvgTextWidth(":")
		font_y_offset = maxy

		nvgRestore()
	end
end

function GoaHud_TimerBig:draw()
	self:calculateFontMetrics()

	if (not self:shouldShow()) then return end

	local timer_base = 60
	local time_raw = 0
	if (world.gameState == GAME_STATE_WARMUP) then
		time_raw = (epochTime - self.connectedTime) * 1000
	elseif (world.gameState == GAME_STATE_ROUNDPREPARE or world.gameState == GAME_STATE_ROUNDCOOLDOWN_SOMEONEWON or world.gameState == GAME_STATE_ROUNDCOOLDOWN_DRAW) then
		time_raw = 0
	else
		time_raw = math.floor(world.gameTime / 1000) * 1000
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
end

function GoaHud_TimerBig:calculateTextWidth(str)
	local width = -self.options.letterSpacing
	for i = 1, #str do
		local c = string.sub(str, i, i)
		if (c == ":") then width = width + font_separator_width
		else width = width + font_number_width end
		width = width + self.options.letterSpacing
	end
	return width
end

function GoaHud_TimerBig:drawText(x, y, str)
	local offset_x = 0
	for i = 1, #str do
		local c = string.sub(str, i, i)
		local separator = c == ":"
		local number_offset = 0

		if (not separator) then number_offset = number_offset + (font_number_width - nvgTextWidth(c)) / 2 end

		GoaHud:drawTextWithShadow(x + offset_x + number_offset, y, c, self.options.shadow)
		if (separator) then offset_x = offset_x + font_separator_width
		else offset_x = offset_x + font_number_width end
		offset_x = offset_x + self.options.letterSpacing
	end
end