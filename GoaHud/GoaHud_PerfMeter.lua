-- GoaHud_PerfMeter made by GoaLitiuM
--
-- PerfMeter with different font and averaged frametime values.
--

require "base/internal/ui/reflexcore"

GoaHud_PerfMeter =
{
	anchor = { x = 1, y = 1 },

	deltaTimes = {},
	deltaCount = 100,
	deltaIndex = 1,
	displayInterval = 0.25,
	displayAccum = 0,
	avgFrametime = 0.0,
	avgFps = 0,
	displayStr = "",

	-- configurable
	options =
	{
		font = { index = 6, face = "" },
		fontSize = 22,
		fontColor = Color(255,255,255,255),

		showAlways = false,

		shadow =
		{
			shadowEnabled = true,
			shadowOffset = 2,
			shadowBlur = 18,
			shadowColor = Color(0,0,0,255),
			shadowStrength = 1,
		},
	},

	optionsDisplayOrder =
	{
		"font", "fontSize", "fontColor",
		"",
		"showAlways",
		"",
		"shadow",
	},
};
GoaHud:registerWidget("GoaHud_PerfMeter");

function GoaHud_PerfMeter:init()
	for i=1, self.deltaCount do table.insert(self.deltaTimes, 0.0) end
end

function GoaHud_PerfMeter:drawOptionsVariable(varname, x, y, optargs)
	if (varname == "font") then
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, table.merge(optargs, { font = true }), "Font")
	elseif (varname == "fontSize") then
		local optargs = clone(optargs)
		optargs.min_value = 10
		optargs.max_value = 170
		optargs.tick = 1
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs, "Font Size")
	end
	return nil
end

function GoaHud_PerfMeter:draw()
	if (not self.options.showAlways and consoleGetVariable("cl_show_hud") == 0) then return end

	-- collect the current deltaTime value
	self.deltaTimes[self.deltaIndex] = deltaTimeRaw * 1000.0
	self.deltaIndex = self.deltaIndex + 1

	if (self.deltaIndex > self.deltaCount) then
		self.deltaIndex = 1
	end

	self.displayAccum = self.displayAccum + deltaTimeRaw
	if (self.displayAccum >= self.displayInterval) then
		self.displayAccum = self.displayAccum - self.displayInterval

		self.avgFrametime = 0
		for i=1, self.deltaCount do
			self.avgFrametime = self.avgFrametime + self.deltaTimes[i]
		end
		self.avgFrametime = self.avgFrametime / self.deltaCount
		self.avgFps = round(1000.0 / self.avgFrametime)
		self.displayStr = string.format("%.2fms (%dfps)", self.avgFrametime, self.avgFps)
	end

	GoaHud:alignTextWithWidgetAnchor(self)
	nvgFontFace(GoaHud:getFont(self.options.font))
	nvgFontSize(self.options.fontSize)

	-- shadow
	GoaHud:drawTextShadow(0, 0, self.displayStr, self.options.shadow)

	-- actual text
	nvgFontBlur(0.0)
	nvgFillColor(self.options.fontColor)
	nvgText(0, 0, self.displayStr)
end