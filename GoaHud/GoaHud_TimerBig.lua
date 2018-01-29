-- GoaHud_TimerBigBig made by GoaLitiuM
--
-- Bigger, secondary timer for tracking pickup times
--

require "base/internal/ui/reflexcore"

GoaHud_TimerBig =
{
	offset = { x = 0, y = -220 },
	anchor = { x = 0, y = 1 },

	recalculateBounds = true,
	textOffsetX = 0,
	textOffsetY = 0,
	textWidth = 0,
	textHeight = 0,
	lastMins = -1,
	connectedTime = 0,

	options =
	{
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
		"hideWhileSpectating",
		"",
		"shadow",
	},
};
GoaHud:registerWidget("GoaHud_TimerBig", GOAHUD_UI_EXPERIMENTAL);

function GoaHud_TimerBig:init()
	self.connectedTime = epochTime
end

function GoaHud_TimerBig:drawOptionsVariable(varname, x, y, optargs)
	return nil
end

function GoaHud_TimerBig:setupText()
	nvgTextLetterSpacing(-1)

	nvgFontFace(GOAHUD_FONT2)
	nvgFontSize(120)
end

function GoaHud_TimerBig:drawText(x, y, color, value)
	x = round(x)
	y = round(y)
	GoaHud:drawTextShadow(x, y, value, self.options.shadow, { alpha = color.a })
	nvgFillColor(color)
	nvgText(x, y, value)
end

function GoaHud_TimerBig:shouldShow()
	local show = shouldShowHUD(optargs_deadspec) and (GoaHud.previewMode or not isRaceOrTrainingMode())
	local local_player = getLocalPlayer()
	if (self.options.hideWhileSpectating and local_player ~= nil and local_player.state == PLAYER_STATE_SPECTATOR) then show = false end
	return show
end

function GoaHud_TimerBig:draw()
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

		nvgRestore()

		self.recalculateBounds = false
	end

	local margin = 12
	local x = -self.textOffsetX - self.textWidth/2
	local y = self.textOffsetY + margin

	-- round time
	self:setupText()
	nvgTextAlign(NVG_ALIGN_RIGHT, NVG_ALIGN_TOP)

	self:drawText(x, y, Color(255,255,255,255), display_str)
end