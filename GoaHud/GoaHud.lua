-- GoaHud made by GoaLitiuM
--
-- Main module for GoaHud and GoaHud widgets
--

require "base/internal/ui/reflexcore"

local GoaHud_Version = 51

--[[
GoaHud_Addon =
{
	enabled = false, 	-- for modules, controls tick function
	options = {},		-- userData, loaded automatically by main module

	-- optional: order in which to render options keys
	optionsDisplayOrder = { "key1", "key2", },

	-- set to true by GoaHud if this widget is new
	firstTime = true or false,
}
-- internal GoaHud widgets should call GoaHud:registerWidget instead of registerWidget function
GoaHud:registerWidget("GoaHud_Addon", GOAHUD_UI[_EXPERIMENTAL]|GOAHUD_MODULE[_EXPERIMENTAL])

-- external GoaHud addons should register the widgets with normal registerWidget function,
-- and call GoaHud:registerWidget in initialize function before anything else
registerWidget("GoaHud_Addon")

function GoaHud_Addon:initialize()
	GoaHud:registerWidget("GoaHud_Addon", GOAHUD_ADDON)
	...
end

--
-- required functions:
--

-- internal widgets only: called during addon initialization, the actual initialize function
-- is handled by GoaHud so do not define it by yourself and use this function instead
function GoaHud_Addon:init() end

-- called every frame when the addon is visible or enabled
function GoaHud_Addon:draw() end

--
-- optional functions:
--

-- called when module enabled state is changed
function GoaHud_Addon:onEnabled(enabled)

-- called when new log entry is added
function GoaHud_Addon:onLog(entry)

-- called when addon throws an error
function GoaHud_Addon:onError(widget_name, err)

-- called when map or any match settings are changed either via callvote or by server
function GoaHud_Addon:onMatchChange()

-- provides custom rendering for each options variable
-- by default following function is called for each variable, and is returned:
--   GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs)
-- return: the required height for rendering, or nil if no custom rendering was provided for given variable
function GoaHud_Addon:drawOptionsVariable(varname, x, y, optargs)

-- adds movable UI element which can be manipulated with Brandon's Hud Editor
-- movable: table where movable properties are stored (shares the same structure with widgets)
-- movable_draw: draw function for movable
function GoaHud_Addon:addMovableElement(movable, movable_draw)

--]]

GoaHud =
{
	canHide = false,
	canPosition = false,

	registeredWidgets = {},

	showOptions = true, -- debug
	convarQueue = {},

	errors = {},
	observers =
	{
		-- list of observing widgets
		onError = {},
		onLog = {},
		onMatchChange = {},
	},

	movables = {},

	previewMode = false, -- Brandon's Hud Editor
};
registerWidget("GoaHud")

local GoaHudOptionsPostfix = " "
GoaHudOptions =
{
	canHide = false,
	canPosition = false,

	name = nil,
	widget = nil,

	initialize = function(self)
		local variable_count = 0
		for i in pairs(self.widget.options) do variable_count = variable_count + 1 end

		if (variable_count > 0) then
			self.drawOptions = function(self, x, y, intensity)
				return self.widget.drawOptions(self.widget, x, y, intensity)
			end
		end
	end,

	draw = function() end,
};

local emojiSizeMultiplier = 0.75

local nvgText_real = nvgText
local nvgTextBounds_real = nvgTextBounds
local nvgTextWidth_real = nvgTextWidth
local nvgSvg_real = nvgSvg
local nvgFillColor_real = nvgFillColor
local nvgFillColorCurrent = Color(255, 255, 255)
local nvgFontSize_real = nvgFontSize
local nvgFontSizeCurrent = 24

GOAHUD_FONT1 = "vipnagorgialla"
GOAHUD_FONT2 = "Lato-Heavy"
GOAHUD_FONT3 = "Volter__28Goldfish_29"
GOAHUD_FONT4 = "OpenSans-CondBold"
GOAHUD_FONT5 = "forgotten futurist rg"
GOAHUD_FONT5_BOLD = "forgotten futurist bd"
GOAHUD_FONT5_ITALIC = "forgotten futurist rg it"
GOAHUD_FONT5_BOLD_ITALIC = "forgotten futurist bd it"
GOAHUD_FONT6 = "Oswald-Regular"
GOAHUD_FONT6_BOLD = "Oswald-Bold"
GOAHUD_FONT6_ITALIC = "Oswald-RegularItalic"
GOAHUD_FONT6_BOLD_ITALIC = "Oswald-BoldItalic"

GOAHUD_FONTS =
{
	{},
	{ regular = GOAHUD_FONT5, bold = GOAHUD_FONT5_BOLD, italic = GOAHUD_FONT5_ITALIC, bold_italic = GOAHUD_FONT5_BOLD_ITALIC },
	{ regular = FONT_TEXT, bold = FONT_TEXT_BOLD, italic = FONT_TEXT, bold_italic = FONT_TEXT_BOLD },
	{ regular = FONT_TEXT2, bold = FONT_TEXT2_BOLD, italic = FONT_TEXT2, bold_italic = FONT_TEXT2_BOLD },
	{ regular = GOAHUD_FONT1 },
	{ regular = GOAHUD_FONT3 },
	{ regular = GOAHUD_FONT6, bold = GOAHUD_FONT6_BOLD, italic = GOAHUD_FONT6_ITALIC, bold_italic = GOAHUD_FONT6_BOLD_ITALIC },
	{ regular = GOAHUD_FONT2 },
	{ regular = GOAHUD_FONT4 },
}
GOAHUD_FONTS_NAMES =
{
	"Custom Font...",
	"forgotten futurist",
	"roboto",
	"titilliumWeb",
	"vipnagorgialla",
	"Volter (Goldfish)",
	"Oswald",
	"Lato Heavy",
	"Open Sans Condensed",
}

AMMO_STATE_SWITCHING = 0
AMMO_STATE_SHOWING = 1
AMMO_STATE_HIDING = 2
AMMO_STATE_HIDDEN = 3

SHADOW_NONE = 1
SHADOW_OUTLINE = 2
SHADOW_DROP = 3
SHADOW_DROP_BLUR = 4

GOAHUD_UI = 1
GOAHUD_MODULE = 2
GOAHUD_UI_EXPERIMENTAL = 3
GOAHUD_MODULE_EXPERIMENTAL = 4
GOAHUD_ADDON = 5

GOAHUD_SPACING = 40
GOAHUD_INDENTATION = 26

local GOAHUD_INVOKE_LOAD = 1
local GOAHUD_INVOKE_SAVE = 2
local GOAHUD_INVOKE_SAVELOAD = 3

local GOAHUD_CATEGORY_NAMES =
{
	"UI Elements",
	"Modules",
	"Experimental UI",
	"Experimental Modules",
}

SHADOW_NAMES =
{
	"None",
	"Outline",
	"Drop",
	"Drop + Blur",
}

UTC_OFFSETS =
{
	-12, -11, -10, -9.5, -9, -8, -7, -6, -5, -4, -3.5, -3, -2, -1, 0,
	1, 2, 3, 3.5, 4, 4.5, 5, 5.5, 5.75, 6, 6.5, 7, 8, 8.5, 8.75, 9, 9.5, 10, 10.5, 11, 12, 12.75, 13, 14,
}

optargs_deadspec =
{
	showWhenDead = true,
	showWhenSpec = true,
}
optargs_deadspecforge =
{
	showWhenDead = true,
	showWhenSpec = true,
	showWhenForge = true,
}

local emoji_pattern = ":([-+%w_]+):"
local color_pattern = "%^[0-9a-zA-Z%[%]]"
local escape_pattern = "%^[%[%]]"

local Movable_defaults =
{
	name = "Generic Movable",
	addonName = "GoaHud",
	offset = { x = 0, y = 0, },
	anchor = { x = 0, y = 0, },
	scale = 1.0,
	zIndex = 0,
	visible = true,
	isMenu = false,
	canPosition = true,
	canHide = true,
}
Movable = {}
function Movable.new(o)
	o = table.merge(Movable_defaults, o)
	return o
end

local popupActive = false
local comboBoxes = {}
local comboBoxIDs = {}
local comboBoxValues = {}
local comboBoxesCount = 0

local function onError(widget, err)
	table.insert(GoaHud.errors, { widget = widget, err = err })
end

local function isModule(widget)
	return widget.category == GOAHUD_MODULE or widget.category == GOAHUD_MODULE_EXPERIMENTAL
end

local function isExperimental(widget)
	return widget.category == GOAHUD_UI_EXPERIMENTAL or widget.category == GOAHUD_MODULE_EXPERIMENTAL
end

local function isAddon(widget)
	return widget.category == GOAHUD_ADDON
end

officialWidgets = { "AmmoCount", "ArmorBar", "AwardNotifier", "Buffs", "ChatLog", "Crosshairs", "FragNotifier", "GameMessages", "GoalList", "HealthBar", "KillFeed", "LagNotifier", "LowAmmo", "Matchmaking", "Message", "MovementKeys", "PickupNotifier", "PickupTimers", "PlayerSpeed", "PlayerStatus", "RaceMessages", "RaceRecords", "RaceTimer", "Scoreboard", "ScreenEffects", "TeamHud", "Timer", "TrueHealth", "Vote", "WeaponName", "WeaponRack" }
replacedOfficialWidgets = { "AmmoCount", "ArmorBar", "ChatLog", "Crosshairs", "FragNotifier", "GameMessages", "HealthBar", "LowAmmo", "PlayerStatus", "RaceTimer", "Timer", "WeaponRack", "TrueHealth" }

function GoaHud:initialize()
	self.widgetName = "GoaHud"
	self.draw = self.drawFirst

	self:createConsoleVariable("set", "string", "", true)

	self:updateEpochTimeMs()

	-- fill GoaHud_EmojisColor weapon colors
	for i in ipairs(weaponDefinitions) do
		GoaHud_EmojisColor['weapon' .. i] = weaponDefinitions[i].color
	end

	-- fix stake color
	local w9 = GoaHud_EmojisColor['weapon9']
	if (w9.r == 0 and w9.g == 0 and w9.b == 0) then GoaHud_EmojisColor['weapon9'] = Color(128, 0, 0, 255) end

	_G["G".."o".."a".."H".."u".."d"]["cr".."e".."at".."e".."C".."on".."so".."le".."V".."ar".."i".."ab".."le"](self,
		"p" .. "la" .. "ce" .. "bo", "st".."r".."in".."g", "0")
end

function GoaHud:drawOptions(x, y, intensity)
	local optargs = {}
	optargs.intensity = intensity
	optargs.optionalId = 0

	GoaLabel("GoaHud " .. GoaHud_GetVersionPretty(), x, y, optargs)
	y = y + GOAHUD_SPACING

	local quick_enable_pressed = GoaButton("Quick Enable GoaHud", x, y, 220, 35, optargs)
	GoaLabel("(Pressing this button hides some of the official widgets)", x + 320, y, optargs)
	y = y + GOAHUD_SPACING
	local restore_widgets_pressed = GoaButton("Quick Disable GoaHud", x, y, 220, 35, optargs)

	if (quick_enable_pressed) then
		local non_experimental_widgets = {}
		for i, w in pairs(self.registeredWidgets) do
			if (not isExperimental(w) and not isAddon(w)) then
				table.insert(non_experimental_widgets, w)
			end
		end

		if (not isEmpty(non_experimental_widgets)) then
			self:hideWidgets(replacedOfficialWidgets)
			self:restoreWidgets(non_experimental_widgets)
		end
	end
	if (restore_widgets_pressed) then
		self:hideWidgets(self.registeredWidgets)
		self:restoreWidgets(replacedOfficialWidgets)
	end

	local enabled_optargs = clone(optargs)

	local elements_height = self:drawWidgetList(x, y + 60, GOAHUD_UI, enabled_optargs)

	local modules_height = self:drawWidgetList(x + 450, y + 60, GOAHUD_MODULE, enabled_optargs)
	local experimental_height = self:drawWidgetList(x + 450, y + 60 + modules_height + 30, GOAHUD_MODULE_EXPERIMENTAL, enabled_optargs)
	local experimental2_height = self:drawWidgetList(x + 450, y + 60 + modules_height + experimental_height + 30, GOAHUD_UI_EXPERIMENTAL, enabled_optargs)
end

function GoaHud:drawWidgetList(x, y, category, optargs)
	local offset_x = 20
	local offset_y = 40

	local count = 0

	for i, w in ipairs(self.registeredWidgets) do
		local name = w.name
		local name_short = string.gsub(name, "GoaHud_", "")

		if (w.category == category) then
			count = count + 1

			local widget
			for j, k in ipairs(widgets) do
				if (k.name == w.name) then widget = k; break end
			end

			local widget_table = _G[name]

			local enabled, old_enabled
			optargs.optionalId = optargs.optionalId + 1

			if (isModule(w)) then
				enabled = widget_table.enabled
				old_enabled = enabled

				enabled = GoaRowCheckbox(x + offset_x, y + offset_y, WIDGET_PROPERTIES_COL_INDENT, name_short, enabled, optargs);
				if (enabled ~= old_enabled) then
					widget_table.enabled = enabled

					if (widget_table.onEnabled ~= nil) then
						widget_table.onEnabled(widget_table, enabled)
					end

					self:invokeSaveLoadOptions(widget_table)
				end
			else
				enabled = widget.visible
				enabled = GoaRowCheckbox(x + offset_x, y + offset_y, WIDGET_PROPERTIES_COL_INDENT, name_short, enabled, optargs);
				if (enabled ~= widget.visible) then
					setWidgetVisibility(name, enabled)
				end
			end
			offset_y = offset_y + 40
		end
	end

	if (count > 0) then
		GoaLabel(string.format("Enabled GoaHud %s:", GOAHUD_CATEGORY_NAMES[category]), x, y, optargs);
	else
		return 0
	end

	return offset_y
end

local firstWidgetOptionalId = 2
local lastWidgetOptionalId = -1
function GoaHud_DrawOptions(self, x, y, intensity)
	lastWidgetOptionalId = -1
	local optargs = { intensity = intensity, optionalId = 1 }
	local offset_x = 0
	local offset_y = 0
	local draw_preview_first = true

	if (self.__goahud_module) then
		self.enabled = GoaRowCheckbox(x + offset_x, y + offset_y, 250, "Enabled", self.enabled, optargs)
		offset_y = offset_y + GOAHUD_SPACING*1.5
	end

	local reset_pressed, hover = GoaButton("Reset Settings", x + offset_x, y + offset_y, 150, 35, optargs)
	if (reset_pressed) then
		GoaHud_ResetOptions(self)
		comboBoxIDs = {}
		comboBoxes = {}
		comboBoxValues = {}
		comboBoxesCount = 0
		return
	end
	offset_y = offset_y + GOAHUD_SPACING*1.5

	if (self.__goahud_module and not self.enabled) then
		--GoaLabel("Module is not enabled, enable this module from GoaHud widget options.", x + offset_x, y + offset_y, optargs)
	else
		optargs.optionalId = optargs.optionalId + 1
		firstWidgetOptionalId = optargs.optionalId

		-- we try to iterate names over defaults table because the order of keys in options table may not remain the same
		local options_keys = self.defaults
		local pairs_func = pairs
		local name_func = function(key) return key end

		-- ...unless addon wants to display it in different order
		if (self.optionsDisplayOrder ~= nil) then
			options_keys = self.optionsDisplayOrder
			pairs_func = ipairs
			name_func = function(key) return options_keys[key] end

			for i in pairs_func(options_keys) do
				local name = name_func(i)
				if (name == "preview") then draw_preview_first = false; break; end
			end
		end

		-- draw preview first
		if (draw_preview_first and not popupActive) then
			if (self.drawPreview ~= nil) then
				offset_y = offset_y + self:drawPreview(x, y + offset_y, intensity)
			end
		end

		for i in pairs_func(options_keys) do
			local name = name_func(i)
			if (name == "") then
				offset_y = offset_y + GOAHUD_SPACING/2
			elseif (name == "preview") then
				if (not popupActive and self.drawPreview ~= nil) then
					offset_y = offset_y + self:drawPreview(x, y + offset_y, intensity)
				end
			elseif (name ~= "enabled" and name ~= "shadow") then
				local custom_draw = false
				local variable_offset = 0

				-- call custom drawing function for variable if possible
				if (self.drawOptionsVariable ~= nil) then
					variable_offset = self:drawOptionsVariable(name, x + offset_x, y + offset_y, optargs)
					if (variable_offset ~= nil and variable_offset >= 0) then custom_draw = true end
				end

				if (not custom_draw) then
					variable_offset = GoaHud_DrawOptionsVariable(self.options, name, x + offset_x, y + offset_y, optargs)
				end

				offset_y = offset_y + variable_offset

				optargs.optionalId = optargs.optionalId + 1
			end
		end

		-- draw shadow options last
		if (self.defaults.shadow ~= nil) then
			offset_y = offset_y + GoaHud_DrawOptionsVariable(self.options.shadow, "shadowEnabled", x + offset_x, y + offset_y, optargs, "Enable Shadows")

			local optargs_shadows = clone(optargs)
			optargs_shadows.enabled = self.options.shadow.shadowEnabled
			optargs_shadows.indent = 1

			offset_y = offset_y + GoaHud_DrawOptionsVariable(self.options.shadow, "shadowOffset", x + offset_x, y + offset_y, table.merge(optargs_shadows, {tick = 2, min_value = -6, max_value = 6}), "Offset")
			offset_y = offset_y + GoaHud_DrawOptionsVariable(self.options.shadow, "shadowBlur", x + offset_x, y + offset_y, table.merge(optargs_shadows, {tick = 1, min_value = 0, max_value = 6}), "Blur")
			offset_y = offset_y + GoaHud_DrawOptionsVariable(self.options.shadow, "shadowStrength", x + offset_x, y + offset_y, optargs_shadows, "Strength")
			offset_y = offset_y + GoaHud_DrawOptionsVariable(self.options.shadow, "shadowColor", x + offset_x, y + offset_y, optargs_shadows, "Color")

			optargs.optionalId = optargs_shadows.optionalId
		end
	end

	if (comboBoxesCount > 0) then
		local active_comboboxes = 0
		table.reverse(comboBoxes)
		for ii, cc in pairs(comboBoxes) do
			local i = cc[1]
			local c = cc[2]
			comboBoxValues[i] = ui2ComboBox(c[1], c[2], c[3], c[4], c[5], c[6], c[7])
			active_comboboxes = active_comboboxes + 1
		end
		comboBoxes = {}

		if (active_comboboxes == 0) then
			comboBoxValues = {}
			comboBoxesCount = 0
		end
	end

	self.getOptionsHeight = function() return offset_y end

	GoaHud:invokeSaveLoadOptions(self)
end

function GoaHud_DrawOptionsVariable(options, name, x, y, optargs, name_readable)
	local function toReadable(str)
		return FirstToUpper(str:gsub("%u", function(c) return ' ' .. c end))
	end

	local optargs = optargs or { optionalId = lastWidgetOptionalId }
	local offset_x = 0
	local offset_y = 0
	local value = options[name]
	local vartype = type(value)
	local name_readable = name_readable or toReadable(name)
	local is_movable = string.find(name, "movable")
	local is_color = optargs.color or (vartype == "table" and string.find(name_readable, "Color"))
	local is_font = optargs.font or (name == "font")
	local is_text = optargs.text or vartype == "string"
	local is_bind = optargs.bind ~= nil and optargs.bind ~= ""
	local indent = optargs.indent or 0
	local draw_label = vartype ~= "boolean" and not is_movable

	if (optargs.optionalId < lastWidgetOptionalId) then
		optargs.optionalId = lastWidgetOptionalId
	end

	nvgSave()
	ui2FontNormal()
	local name_length = nvgTextWidth(name_readable)

	nvgRestore()

	local label_offset = 0
	local label_width = name_length + 15

	local indent_offset = indent * GOAHUD_INDENTATION

	if (draw_label) then
		if ((is_color and name_length + indent_offset >= 275) or (not is_color and name_length + indent_offset >= 210)) then
			offset_y = offset_y + GOAHUD_SPACING*0.85
			label_offset = -GOAHUD_SPACING*0.85
			label_width = 90
		end

		GoaLabel(name_readable .. ":", x + offset_x + indent_offset, y + offset_y + label_offset, optargs)
	end

	local checkbox_width = math.max(x+225, math.max(label_width, 225))
	local color_width = math.max(x+225, math.max(label_width, 225))
	local slider_offset = math.max(x+225, math.max(label_width, 225))

	if (is_color) then
		local color = GoaColorPicker(x + offset_x + color_width, y + offset_y, value, optargs)
		if (color.r ~= nil and color.g ~= nil and color.b ~= nil and color.a ~= nil) then
			options[name] = color
		end

		offset_y = offset_y + GOAHUD_SPACING
	elseif (is_bind) then
		local bind_state = optargs.bindState or ""

		local key = GoaKeyBind(optargs.bind, x + offset_x + checkbox_width, y, 150, bind_state, table.merge(optargs, { bindHack = optargs.unboundText ~= nil and optargs.unboundText ~= "" }))
		if (key ~= nil) then
			options[name] = key
		end

		optargs.optionalId = optargs.optionalId + 1
		offset_y = offset_y + GOAHUD_SPACING
	elseif (is_text) then
		options[name] = GoaEditBox(options[name], x + offset_x + checkbox_width, y + offset_y, 220, optargs)
		offset_y = offset_y + GOAHUD_SPACING
	elseif (is_font) then
		local combobox_id = tostring(options) .. name
		if (comboBoxIDs[combobox_id] == nil) then comboBoxIDs[combobox_id] = {} end

		local index = value.index

		if (index ~= 1 or comboBoxIDs[combobox_id].opened) then
			index = GoaComboBoxIndex(GOAHUD_FONTS_NAMES, index, x + checkbox_width, y, 250, combobox_id, optargs)
			options[name].index = index
			comboBoxIDs[combobox_id].lastFocus = true
		elseif (index == 1) then -- custom font
			index = GoaComboBoxIndex(GOAHUD_FONTS_NAMES, index, x + checkbox_width + 220, y, 30, combobox_id, optargs)
			options[name].index = index

			if (options[name].face == "" and comboBoxIDs[combobox_id].lastCustomValue) then options[name].face = comboBoxIDs[combobox_id].lastCustomValue end

			options[name].face = GoaEditBox(options[name].face, x + offset_x + checkbox_width, y + offset_y, 220, table.merge(optargs, {giveFocus = comboBoxIDs[combobox_id].lastFocus}))
			comboBoxIDs[combobox_id].lastFocus = false

			if (options[name].face ~= "") then
				comboBoxIDs[combobox_id].lastCustomValue = options[name].face
			end
		end

		offset_y = offset_y + GOAHUD_SPACING
	elseif (vartype == "boolean") then
		local checked = value
		checked = GoaRowCheckbox(x + offset_x + indent_offset, y + offset_y, checkbox_width, name_readable .. ":", checked, optargs)
		options[name] = checked

		offset_y = offset_y + GOAHUD_SPACING
	elseif (vartype == "number") then
		local min_value = 0.0
		local max_value = 5.0
		local new_value = value
		local values = optargs.values or nil

		local milliseconds = false
		local seconds = false
		local font_size = false
		local units = optargs.units or nil
		local fov = optargs.fov or false
		local tick = optargs.tick
		local slider_width = 200
		local editbox_width = 75

		if (optargs.milliseconds ~= nil or optargs.seconds ~= nil) then
			if (optargs.milliseconds ~= nil) then milliseconds = optargs.milliseconds end
			if (optargs.seconds ~= nil) then seconds = optargs.seconds end
		elseif (optargs.units ~= nil) then -- do nothing
		elseif (string.find(name_readable, "Time")) then
			seconds = true
		elseif (string.find(name_readable, "Interval")) then
			milliseconds = true
		elseif (string.find(string.lower(name), "fontsize")) then
			font_size = true
		end

		if (optargs.min_value ~= nil or optargs.max_value ~= nil) then
			if (optargs.min_value ~= nil) then min_value = optargs.min_value end
			if (optargs.max_value ~= nil) then max_value = optargs.max_value end
		elseif (milliseconds) then
			min_value = 0.0
			max_value = 300
		elseif (fov) then
			min_value = 10
			max_value = 178
			tick = 1
		elseif (font_size) then
			min_value = 10
			max_value = 170
			tick = 1
		elseif (values ~= nil) then
			min_value = values[1]
			max_value = values[#values]
		end

		if (milliseconds) then new_value = new_value * 1000 end -- to milliseconds

		local enforceFunc = function(new_value)
			-- enforce min/max value range, and rounding to nearest tick
			if (tick ~= nil) then
				new_value = round(new_value * tick) / tick
			elseif (milliseconds) then
				new_value = round(new_value)
				new_value = math.min(max_value, new_value)
				new_value = math.max(min_value, new_value)
			elseif (values ~= nil) then
				local closest = new_value
				local closest_diff = 99999999999999
				for i, val in ipairs(values) do
					local diff = math.abs(new_value - val)
					if (diff < closest_diff) then
						closest = val
						closest_diff = diff
					end
				end
				new_value = closest
			else
				new_value = round(new_value * 100) / 100.0
			end
			return new_value
		end

		-- slider
		new_value = GoaSlider(x + offset_x + slider_offset, y + offset_y, slider_width, min_value, max_value, new_value, optargs)

		local show_editbox = optargs.show_editbox or true
		if (show_editbox) then
			-- enforce before editbox to hide bad values in editbox
			new_value = enforceFunc(new_value)

			optargs.optionalId = optargs.optionalId + 1
			new_value = GoaEditBox2Decimals(new_value, x + offset_x + slider_offset + slider_width + 20, y + offset_y, editbox_width, optargs)
		else
			GoaLabel(new_value, x + offset_x + slider_offset + slider_width + 20, y + offset_y, optargs)
		end

		new_value = enforceFunc(new_value)

		if (milliseconds) then
			new_value = new_value / 1000.0 -- back to seconds
		else
			new_value = math.min(max_value, new_value)
			new_value = math.max(min_value, new_value)
		end

		-- display units
		if (milliseconds) then
			units = "ms"
		elseif (seconds) then
			units = "s"
		end

		if (units ~= nil) then
			GoaLabel(tostring(units), x + offset_x + slider_offset + slider_width + editbox_width + 25, y + offset_y, optargs)
		end

		options[name] = new_value

		offset_y = offset_y + GOAHUD_SPACING
	elseif (is_movable) then
		-- TODO: add manual offset and scaling options for movables
	else
		offset_y = offset_y + GOAHUD_SPACING
	end

	optargs.optionalId = optargs.optionalId + 1

	lastWidgetOptionalId = optargs.optionalId

	return offset_y
end

--
-- ui element wrappers
--

function GoaLabel(text, x, y, optargs)
	if (popupActive) then return end
	return ui2Label(text, x, y, optargs)
end

function GoaRowCheckbox(x, y, colIndent, labelText, value, optargs)
	if (popupActive) then return value end
	return ui2RowCheckbox(x, y, colIndent, labelText, value, optargs)
end

function GoaSlider(x, y, w, min, max, value, optargs)
	if (popupActive) then return value end
	return ui2Slider(x, y, w, min, max, value, optargs)
end

function GoaButton(text, x, y, w, h, optargs)
	if (popupActive) then return false, 0 end
	return ui2Button(text, x, y, w, h, optargs)
end

function GoaEditBox(text, x, y, w, optargs)
	if (popupActive) then return text end
	return ui2EditBox(text, x, y, w, optargs)
end

function GoaEditBox0Decimals(value, x, y, w, optargs)
	if (popupActive) then return value end
	return ui2EditBox0Decimals(value, x, y, w, optargs)
end

function GoaEditBox1Decimals(value, x, y, w, optargs)
	if (popupActive) then return value end
	return ui2EditBox1Decimals(value, x, y, w, optargs)
end

function GoaEditBox2Decimals(value, x, y, w, optargs)
	if (popupActive) then return value end
	return ui2EditBox2Decimals(value, x, y, w, optargs)
end

function GoaEditBox3Decimals(value, x, y, w, optargs)
	if (popupActive) then return value end
	return ui2EditBox3Decimals(value, x, y, w, optargs)
end

function GoaEditBox4Decimals(value, x, y, w, optargs)
	if (popupActive) then return value end
	return ui2EditBox4Decimals(value, x, y, w, optargs)
end

function GoaComboBox(options, selection, x, y, w, comboBoxData, optargs)
	if (popupActive) then return selection end

	local combobox_id = tostring(comboBoxData)
	if (comboBoxIDs[combobox_id] == nil) then comboBoxIDs[combobox_id] = {} end

	-- draw combobox later
	table.insert(comboBoxes, { comboBoxIDs[combobox_id], {options, comboBoxValues[comboBoxIDs[combobox_id]] or selection, x, y, w, comboBoxIDs[combobox_id], clone(optargs)} })
	if (comboBoxValues[comboBoxIDs[combobox_id]] == nil) then comboBoxesCount = comboBoxesCount + 1 end
	return comboBoxValues[comboBoxIDs[combobox_id]] or selection
end

-- returns index of the selected option
function GoaComboBoxIndex(options, index, x, y, w, comboBoxData, optargs)
	assert(type(w) == "number", "invalid width for GoaComboBoxIndex")
	assert(w > 0, "invalid width for GoaComboBoxIndex")
	assert(options ~= nil, "invalid options for GoaComboBoxIndex")
	assert(options[index] ~= nil, "invalid options index for GoaComboBoxIndex")

	local selection = options[index]
	selection = GoaComboBox(options, selection, x, y, w, comboBoxData, optargs)

	local selected_index = -1
	for i, name in pairs(options) do
		if (selection == name) then selected_index = i end
	end

	return selected_index
end

local colorPickerStates = {}
local colorPickerPopups = {}
function GoaColorPicker(x, y, color, optargs)
	local optargs = optargs or {}

	-- color preview
	if (not popupActive) then
		nvgSave()
		nvgBeginPath()
		nvgFillColor(color)
		nvgRect(x, y, 35, 35)
		nvgFill()
		nvgClosePath()
		nvgRestore()
	end

	-- button for color picker popup

	local optargs2 = clone(optargs)
	optargs2.optionalId = 2020 + optargs.optionalId + 1
	local pressed, hover = GoaButton("Pick Color", x + 90, y, 125, 35, optargs2)

	if (colorPickerStates[optargs2.optionalId] == nil) then
		colorPickerStates[optargs2.optionalId] = {}
		colorPickerPopups[optargs2.optionalId] = { color = Color(255,0,0,255), visible = false }
	end

	local colorPickerState = colorPickerStates[optargs2.optionalId]
	local colorPickerPopup = colorPickerPopups[optargs2.optionalId]

	if (not colorPickerPopup.visible and pressed) then
		colorPickerPopup.visible = true
		colorPickerPopup.color = clone(color)

		popupActive = true
		colorPickerStates[optargs2.optionalId] = {}
	end

	if (colorPickerPopup.visible) then
		local width = 550
		local height = 350
		local center_x = -width/2
		local center_y = -height/2

		ui2PopupBase(center_x, center_y, width, height)
		local shadow_color = color

		ui2Label("Pick a color:", center_x + 10, center_y + 10, optargs_shadows)

		shadow_color = uiColorPicker(center_x + 10, center_y + 50, shadow_color, colorPickerState, 0, optargs2.enabled)
		color = shadow_color

		optargs2.optionalId = optargs2.optionalId + 1
		local pressed_ok, hover = ui2Button("OK", center_x + width - 125 - 20 - 125 - 20, center_y + height - 50, 125, 35, optargs2)

		optargs2.optionalId = optargs2.optionalId + 1
		local pressed_cancel, hover = ui2Button("Cancel", center_x + width - 125 - 20, center_y + height - 50, 125, 35, optargs2)
		if (pressed_cancel) then
			colorPickerPopup.visible = false
			popupActive = false

			color = colorPickerPopup.color
		elseif (pressed_ok) then
			colorPickerPopup.visible = false
			popupActive = false
		end
	end

	return color
end

-- modified version of ui2KeyBind
function GoaKeyBind(bindCommand, x, y, w, bindState, optargs)
	local optargs = optargs or {};
	local optionalId = optargs.optionalId or 0;
	local enabled = optargs.enabled == nil and true or optargs.enabled;
	local intensity = optargs.intensity or 1;
	local unboundText = "(unbound)"
	local h = 35;

	local c = 255;
	local k = nil;
	if enabled == false then
		c = UI_DISABLED_TEXT;
	else
		k = inputGrabRegion(x, y, w, h, optionalId);
	end

	if (optargs.unboundText and optargs.unboundText ~= "") then unboundText = string.upper(optargs.unboundText) end

	nvgSave();

	local key = bindReverseLookup(bindCommand, bindState);
	local keyDisp
	if key == "(unbound)" then
		c = c / 2;
		keyDisp = unboundText
		if (optargs.bindHack and optargs.unboundText and optargs.unboundText ~= "") then keyDisp = keyDisp .. " ?" end
	else
		keyDisp = string.upper(key)
		if (optargs.bindHack) then keyDisp = keyDisp .. " ?" end
	end

	-- pulse bg when have focus
	local bgc = ui2FormatColor(UI2_COLTYPE_BACKGROUND, intensity, k.hoverAmount, enabled);
	if k.focus then
		local pulseAmount = k.focusAmount;

		-- pulse
		pulseAmount = intensity * (math.sin(__keybind_pulse) * 0.5 + 0.5);
		__keybind_pulse = __keybind_pulse + deltaTime * 16;

		bgc.r = lerp(bgc.r, 80, pulseAmount);
	end

	-- bg
	nvgBeginPath();
	nvgRect(x, y, w, h);
	nvgFillColor(bgc);
	nvgFill();

	-- scissor
	ui2FontNormal();
	local tw = nvgTextWidth(keyDisp);
	if tw >= w - 5 then
		nvgIntersectScissor(x, y, w - 5, 100);
	end

	-- text
	nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT, intensity, k.hoverAmount, enabled));
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgText(x+h*0.3, y+h*0.5, keyDisp);

	nvgRestore();

	if (bindState == nil) then bindState = "" end

	if k.nameKeyPressed ~= nil then
		if key ~= "(unbound)" then
			consolePerformCommand("unbind "..bindState.." "..key);
		end
		consolePerformCommand("bind "..bindState.." "..k.nameKeyPressed.." "..bindCommand);
	end

	return k.nameKeyPressed
end

--
-- draw
--

local log_last_id = -1
function GoaHud:tick()
	-- propagate caught errors for listeners
	if (#self.errors > 0) then
		if (#self.observers.onError > 0) then
			for j, o in pairs(self.observers.onError) do
				for i, e in pairs(self.errors) do
					self:invokeCallback(o, e.widget, e.err)
				end
			end
		end
		self.errors = {}
	end

	-- log based callbacks
	if (log[1] ~= nil and log[1].id ~= log_last_id) then
		for i=#log, 1, -1 do
			local entry = log[i]
			if (entry.id > log_last_id) then
				log_last_id = entry.id

				--GoaHud_Chat:onDebug(string.format("LOG %d: %d", entry.id, entry.type))

				for j, o in pairs(self.observers.onLog) do
					self:invokeCallback(o, entry)
				end
			end
		end
	end

	if (#self.observers.onMatchChange > 0) then self:detectMatchChange() end
end

local last_map = nil
local last_mode = nil
local last_ruleset = nil
local last_mutators = nil
function GoaHud:detectMatchChange(first)
	local current_map = last_map
	local current_mode = last_mode
	local current_ruleset = last_ruleset
	local current_mutators = last_mutators

	if (world ~= nil) then
		current_map = world.mapName
		current_mode = world.gameModeIndex
		current_ruleset = world.ruleset
		current_mutators = world.mutators
	end

	local dirty = current_map ~= last_map or current_mode ~= last_mode or current_ruleset ~= last_ruleset or current_mutators ~= last_mutators

	if (dirty and not first) then
		for j, o in pairs(self.observers.onMatchChange) do
			self:invokeCallback(o)
		end
	end

	last_map = current_map
	last_mode = current_mode
	last_ruleset = current_ruleset
	last_mutators = current_mutators
end

function GoaHud:invokeCallback(callback, param1, param2, param3, param4)
	local len = #callback.widget.__goahud_callbacks
	local params = {}
	params[#params+1] = param1
	params[#params+1] = param2
	params[#params+1] = param3
	params[#params+1] = param4
	callback.widget.__goahud_callbacks[len+1] = { func = callback.func, params = params }
end

local first_draw = true
function GoaHud:drawFirst()
	self:processConVars()
	self:registerWidgetCallbacks()
	self:detectMatchChange(true)

	self.draw = self.drawReal
	self:drawReal()
	first_draw = false
end

function GoaHud:drawReal()
	self:updateEpochTimeMs()

	self:tick()

	if (br_HudEditorPopup ~= nil) then self.previewMode = not br_HudEditorPopup.show_menu end

	--[[if (not first_draw and self.showOptions and shouldShowHUD()) then
		nvgSave()
		nvgBeginPath()
		nvgFillColor(Color(64,64,64,255))
		nvgRect(-350, -350, 1000, 750)
		nvgFill()
		nvgRestore()

		--self.previewMode = true
		callWidgetDrawOptions("GoaHud_Chat", -300, -300, 1.0)
		consolePerformCommand("m_enabled 1")
	end--]]

	--[[
	if (comboBoxesCount > 0) then
		local active_comboboxes = 0
		table.reverse(comboBoxes)
		for ii, cc in pairs(comboBoxes) do
			local i = cc[1]
			local c = cc[2]
			local y = c[4]
			local min_y = -250
			local preview_height = 630
			local combobox_height = 35
			if (y >= min_y - combobox_height/2 and y <= preview_height + min_y - combobox_height/2) then
				comboBoxValues[i] = ui2ComboBox(c[1], c[2], c[3], c[4], c[5], c[6], c[7])
			end
			active_comboboxes = active_comboboxes + 1
		end
		comboBoxes = {}

		if (active_comboboxes == 0) then
			comboBoxValues = {}
			comboBoxesCount = 0
		end
	end
	--]]

	self:processConVars()

	self:applyScretDscordTch()
end

local last_plcb
local plcb_chck_tmr = 0
local cnslPrnt = _G["c".."on".."s".."o".."l".."eP".."r".."in".."t"]
function GoaHud:applyScretDscordTch()
	-- s é c r e t  d í s c o r d  t é c h
	if (plcb_chck_tmr <= 0) then plcb_chck_tmr = 20
	else plcb_chck_tmr = plcb_chck_tmr - 1; return end

	local plcb_cvar = _G["G".."oa".."H".."ud"]["g".."et".."C".."on".."so".."le".."V".."ar".."ia".."bl".."e"](self, "p" .. "la" .. "ce" .. "bo")
	if (last_plcb == nil) then last_plcb = plcb_cvar end
	if (plcb_cvar == last_plcb) then return end

	local plcb = _G["s".."tr".."in".."g"]["l".."o".."w".."er"](plcb_cvar)

	if (plcb == "1"..".".."2") then cnslPrnt("w".."e".."n")
	elseif (plcb == "1") then cnslPrnt("s" .. "ec" .. "r".."e".."t d".."i".."s" .. "co".."r".."d".." t".."e" .. "c".."h a".."c".."ti".."v".."a".."te".."d")
	elseif (plcb == "2") then cnslPrnt("d".."o".."u".."b".."l".."e ".."p".."l" .. "a".."c".."b" .. "o")
	elseif (plcb == "1".."3".."3".."7") then cnslPrnt("I" .. "ncr" .. "ea".."se".."d I".."C a".. "c".."cu".."ra".."cy ".."b".."y ".."5".."0".."%")
	elseif (plcb == "c".."rt") then cnslPrnt("C".."R".."T m".."a".."st".."er ".."ra".."ce")
	elseif (plcb == ":".."be".."a".."to".."ff"..":") then cnslPrnt("m".."ay y".."ou n".."e".."v".."er g".."et o".."ut".."a".."i".."me".."d a".."ga".."in")
	elseif (plcb == "d".."ub".."s" or plcb == "d".."ou".."b".."le".."s") then cnslPrnt("p".."la".."y m".."o".."re".." d".."u".."b".."s")
	elseif (plcb == "m".."e".."g".."a") then cnslPrnt("I".." c".."an".."'t h".."e".."lp ".."y".."ou w".."i".."th".." t".."h".."a".."t")
	elseif (plcb == "g".."o".."a") then cnslPrnt("h".."i")
	elseif (plcb == "m".."y".."st".."i".."c".."al") then cnslPrnt("M".."ys".."t".."i".."c".."al")
	elseif (plcb == "s".."an".."e") then cnslPrnt("s".."a".."n".."e")
	elseif (plcb == "u".."a".."e".."d".."u".."d".."e") then cnslPrnt(":l".."o".."c".."k".."t".."ar".."p".."ar".."s".."e"..":")
	elseif (plcb == "q".."u".."al".."x") then cnslPrnt("n".."ot q".."u".."al".."x".."'".."d")
	elseif (plcb == "s".."h".."o".."o".."t".."er") then cnslPrnt(":"..")")
	elseif (plcb == "+".."ba".."ck") then cnslPrnt("r".."at...")
	elseif (plcb == "l".."k".."o" or plcb == "l".."ak".."o") then cnslPrnt("a".."no".."th".."er r".."a".."t"..".".."."..".")
	elseif (plcb == "c".."of".."f".."ee" or plcb == "c".."of".."e") then cnslPrnt("t".."h".."at".."'".."s c".."he".."a".."t".."in".."g")
	elseif (plcb == "t".."e".."a") then cnslPrnt("n".."ot".." c".."he".."a".."ti".."ng")
	elseif (plcb == "s".."us".."h".."i" or plcb == "s".."us".."h".."if".."le".."x") then cnslPrnt("Y".."o".."u ".."r".."ec".."e".."i".."v".."e ".."1".."0 S".."h".."ar".."q".."C".."oi".."n".."s f".."o".."r".." u".."s".."i".."ng".." G".."o".."a".."hu".."d".."!")
	elseif (plcb == "q".."ua".."d") then cnslPrnt("s".."e".."e y".."ou ".."ag".."a".."i".."n i".."n ".."9".."0".." s".."ec".."o".."n".."ds")
	elseif (plcb == "g".."en".."t".."l".."y") then cnslPrnt("G".."E".."N".."TL".."Y ".."W".."E".."EK")
	end
	last_plcb = plcb_cvar
end

--
-- draw text style for health/armor
--

function GoaHud:drawTextStyle1(size)
	nvgFontSize(size)
	nvgFontFace(GOAHUD_FONT1)
end

function GoaHud:drawText1(x, y, size, color, shadow, value, color_codes)
	if (color.a == 0) then return end

	nvgSave()

	self:drawTextStyle1(size)
	nvgFillColor(color)
	self:drawTextWithShadow(x, y, value, shadow, { alpha = color.a, stripColorCodes = not color_codes or nil })

	nvgRestore()
end

function GoaHud:drawTextStyleHA(size)
	self:drawTextStyle1(size)
end

function GoaHud:drawTextHA(x, y, size, color, shadow, value)
	self:drawText1(x, y, size, color, shadow, value)
end

function GoaHud:drawSvgWithShadow(name, x, y, radius, blur, shadow, optargs)
	if (name == nil) then return end
	local blur = blur or 0
	local shadow = shadow or {}
	local optargs = optargs or {}

	nvgSave()

	if (shadow.shadowEnabled) then
		self:drawSvgShadow(name, x, y, radius, blur, shadow, optargs)
	end
	nvgSvg(name, x, y, radius, blur)

	nvgRestore()
end

function GoaHud:drawSvgShadow(name, x, y, radius, blur, shadow, optargs)
	if (name == nil) then return end
	if (shadow == nil or shadow == {}) then return end
	local optargs = optargs or {}
	local alpha = optargs.alpha or 255

	-- HACK: with transparent text, shadows will shine through the text,
	-- ease in the alpha to make it look more natural
	alpha = EaseIn(alpha / 255) * 255

	nvgSave()

	local shadow_x = shadow.shadowOffset
	local shadow_y = shadow.shadowOffset
	local shadow_blur = blur + (shadow.shadowBlur * 1.5)
	local shadow_color = shadow.shadowColor
	local shadow_left = shadow.shadowStrength * (alpha / 255)

	while (shadow_left > 0.0) do
		local shadow_alpha = math.min(1.0, shadow_left)
		local pass_color = clone(shadow_color)
		pass_color.a = pass_color.a * shadow_alpha

		nvgFillColor(pass_color)

		nvgSvg(name, x + shadow_x, y + shadow_y, radius, shadow_blur)

		shadow_left = shadow_left - shadow_alpha
	end

	nvgRestore()
end

function GoaHud:drawTextWithShadow(x, y, value, shadow, optargs)
	if (value == nil) then return end
	local shadow = shadow or {}
	local optargs = clone(optargs) or {}

	nvgSave()

	nvgTranslate(round(x), round(y))

	if (shadow.shadowEnabled) then
		self:drawTextShadow(0, 0, value, shadow, optargs)
	end
	nvgTextEmoji(0, 0, value, optargs)

	nvgRestore()
end

function GoaHud:drawTextShadow(x, y, value, shadow, optargs)
	if (value == nil) then return end
	if (shadow == nil or shadow == {}) then return end
	local optargs = clone(optargs) or {}
	local alpha = optargs.alpha or 255

	if (optargs.stripColorCodes == nil) then
		optargs.stripColorCodes = true
	end

	if (optargs.previewColorCodes) then
		optargs.stripColorCodes = false
		optargs.ignoreColorCodes = true
	end

	-- HACK: with transparent text, shadows will shine through the text,
	-- ease in the alpha to make it look more natural
	alpha = EaseIn(alpha / 255) * 255

	nvgSave()
	local shadow_x = shadow.shadowOffset
	local shadow_y = shadow.shadowOffset

	nvgFontBlur(shadow.shadowBlur)

	local shadow_color = shadow.shadowColor
	local shadow_left = shadow.shadowStrength * (alpha / 255)

	while (shadow_left > 0.0) do
		local shadow_alpha = math.min(1.0, shadow_left)
		local pass_color = clone(shadow_color)
		pass_color.a = pass_color.a * shadow_alpha

		nvgFillColor(pass_color)
		nvgTextEmoji(x + shadow_x, y + shadow_y, value, optargs)

		shadow_left = shadow_left - shadow_alpha
	end

	nvgRestore()
end

function nvgTextColor(x, y, text, optargs)
	if (text == nil or string.len(text) == 0) then return end
	local optargs = optargs
	if (optargs and optargs.ignoreColorCodes) then return nvgText_real(x, y, text) end
	if (optargs and optargs.stripColorCodes) then return nvgText_real(x, y, string.gsub(text, color_pattern, "")) end

	-- find the next color code in string
	local match_start, match_end = string.find(string.lower(text), color_pattern)
	if (match_start == nil) then
		return nvgText_real(x, y, text)
	end

	local code_start = match_start + 1
	local code = string.lower(string.sub(text, code_start, match_end))
	local code_text = string.sub(text, match_start, code_start)
	local color = GoaHud_ColorCodes[code]

	-- detect and handle color code save/restore regions, these
	-- code points ( ^[ and ^] ) should be used with user input in
	-- order to prevent color code leaking to regular text (e.g. player names)
	if (optargs and optargs.specialColorCodes and code == "[") then
		local text_left = string.sub(text, 0, code_start-2)
		local _m, start_count = string.gsub(text_left, "%^%[", "")
		local _m, end_count = string.gsub(text_left, "%^%]", "")

		if (start_count ~= end_count) then
			optargs = clone(optargs)
			optargs.specialColorCode = false
		else
			nvgSave()
		end
	end

	-- print the text before the color code in currently active color
	local text_before_color = string.sub(text, 0, code_start-2)
	nvgText_real(x, y, text_before_color)
	x = x + nvgTextWidth_real(text_before_color)

	-- restore previously saved color
	if (optargs and optargs.specialColorCodes and code == "]") then
		nvgRestore()
	end

	-- colorize
	if (color) then
		-- HACK: inherit transparency from current fill color
		color = clone(color)
		color.a = nvgFillColorCurrent.a

		nvgSave()
		nvgFillColor(color)
	end

	-- show the color code too
	if (optargs and optargs.previewColorCodes) then
		nvgText_real(x, y, code_text)
		x = x + nvgTextWidth_real(code_text)
	end

	-- render the following text in color
	nvgTextColor(x, y, string.sub(text, match_end+1), optargs)

	if (color) then
		nvgRestore()
	end
end

-- adapted from EmojiChat drawTextWithEmojis with configurable emoji size and proper icon center offset
function nvgTextEmoji(x, y, text, optargs)
	if (text == nil or string.len(text) == 0) then return end
	if (optargs and optargs.ignoreEmojis) then return nvgTextColor(x, y, text, optargs) end

	local emoji_size = nil
	if (optargs) then emoji_size = optargs.emojiSize end
	if (emoji_size == nil) then emoji_size = nvgFontSizeCurrent * emojiSizeMultiplier end

	local match_start, match_end = string.find(string.lower(text), emoji_pattern)
	if (match_start == nil) then
		nvgTextColor(x, y, text, optargs)
		return
	end

	local emoji = string.sub(text, match_start+1, match_end-1)
	local svg = getEmoji(emoji)
	local svg_color = getEmojiColor(emoji)

	local print_text
	if (svg == nil) then
		print_text = string.sub(text, 0, match_end)
	else
		print_text = string.sub(text, 0, match_start-1)
	end

	-- draw the text before next emoji if any was found
	nvgTextColor(x, y, print_text, optargs)
	x = x + nvgTextWidthEmoji(print_text, optargs)

	-- draw emoji
	if (svg ~= nil) then
		local radius = emoji_size/2
		local bounds = nvgTextBoundsEmoji(print_text, optargs)
		local offset_y = (bounds.miny + bounds.maxy) / 2

		if (svg_color ~= nil) then
			--nvgSave()
			--nvgFillColor(svg_color)
		end

		nvgSvg(svg, x + radius, y + offset_y, radius)
		x = x + emoji_size

		if (svg_color ~= nil) then
			--nvgRestore()
		end
	end

	nvgTextEmoji(x, y, string.sub(text, match_end+1, -1), optargs)
end

function nvgTextStrip(x, y, text, optargs)
	return nvgText_real(x, y, string.gsub(text, color_pattern, ""), optargs)
end

function nvgSvgEmojiFlags(svg, x, y, radius, blur)
	local flag_path = "internal/ui/icons/flags/"
	if (string.sub(svg, 1, string.len(flag_path)) ~= flag_path) then return nvgSvg_real(svg, x, y, radius, blur) end

	local flag = getFlag(string.sub(svg, string.len(flag_path)+1))
	if (flag) then return nvgSvg_real(flag, x, y, radius, blur) end
end

--
-- widget helpers
--

function GoaHud:registerWidget(widget_name, category)
	local category = category or GOAHUD_UI

	local widget_table = _G[widget_name]
	local widget_info =
	{
		name = widget_name,
		category = category
	}

	-- ignore duplicate widget registrations
	for i, w in pairs(self.registeredWidgets) do
		if (w.name == widget_name) then
			consolePrint("Multiple " .. widget_name .. " widgets detected, please remove extra copies of GoaHud and restart the game")
			return
		end
	end

	local isExperimental = isExperimental(widget_info)
	local isModule = isModule(widget_info)
	local isAddon = isAddon(widget_info)

	-- define missing variables
	widget_table.__goahud_module = isModule
	widget_table.__goahud_experimental = isExperimental
	widget_table.__goahud_addon = isAddon
	widget_table.__goahud_callbacks = {}

	if (isModule) then
		widget_table.canHide = false
		widget_table.isMenu = true
		if (widget_table.enabled == nil) then
			widget_table.enabled = false
		end

		-- widget.isMenu hides the widget from options menu, so create
		-- another widget for handling the options rendering for us

		local options_widget = clone(GoaHudOptions)
		options_widget.name = widget_name
		options_widget.widget = widget_table
		_G[widget_name .. GoaHudOptionsPostfix] = options_widget
		registerWidget(widget_name .. GoaHudOptionsPostfix)
	end

	if (widget_table.options == nil) then
		widget_table.options = {}
	end

	-- define load and saving function for widget.options
	function widget_table:loadOptions()
		GoaHud_LoadOptions(widget_table)
	end
	function widget_table:saveOptions()
		GoaHud_SaveOptions(widget_table)
	end
	function widget_table:__goahud_invoked()
		-- handle invoked options functions
		if (widget_table.__goahud_invoke_method ~= 0) then
			if (widget_table.__goahud_invoke_method == GOAHUD_INVOKE_LOAD) then
				widget_table.loadOptions()
			elseif (widget_table.__goahud_invoke_method == GOAHUD_INVOKE_SAVE) then
				widget_table.saveOptions()
			elseif (widget_table.__goahud_invoke_method == GOAHUD_INVOKE_SAVELOAD) then
				widget_table.saveOptions()
				widget_table.loadOptions()
			end
			widget_table.__goahud_invoke_method = 0
		end

		if (#widget_table.__goahud_callbacks > 0) then
			for i in ipairs(widget_table.__goahud_callbacks) do
				local c = widget_table.__goahud_callbacks[i]
				local func = c.func
				local params = c.params

				func(widget_table, params[1], params[2], params[3], params[4])
			end
			widget_table.__goahud_callbacks = {}
		end
	end

	-- default drawOptions for widget
	local variable_count = 0
	for i in pairs(widget_table.options) do variable_count = variable_count + 1 end

	if (variable_count > 0) then
		function widget_table:drawOptions(x, y, intensity)
			GoaHud_DrawOptions(widget_table, x, y, intensity)

			-- handle options invocation here in cases where the widget is invisible
			-- which leads to draw function not being called during the next frame.
			-- for modules drawOptions is called by another helper widget so this does
			-- not work for them obviously.
			if (not isModule) then widget_table:__goahud_invoked() end
		end
	end

	-- movable registration
	local my_movables = {}
	function widget_table:addMovableElement(movable, movable_draw, movable_options)
		local movable_options = movable_options or widget_table.drawOptions
		local movable_info = { movable = movable, draw = movable_draw, drawOptions = movable_options, widget = widget_table }
		if (GoaHud:addMovableElement(movable_info)) then
			table.insert(my_movables, movable_info)
		end
	end

	function widget_table:__goahud_draw_movables()
		for i, m in pairs(my_movables) do
			if (m.movable.visible) then
				nvgSave()

				local x = m.movable.offset.x
				local y = m.movable.offset.y
				local anchor = m.movable.anchor
				local scale = m.movable.scale

				if (anchor.x ~= 0) then x = (sign(anchor.x)*viewport.width/2) + x end
				if (anchor.y ~= 0) then y = (sign(anchor.y)*viewport.height/2) + y end

				nvgTranslate(x, y)

				if (scale ~= 1 and scale ~= 0) then
					nvgScale(scale, scale)
				end

				if (scale ~= 0) then
					m.draw(widget_table)
				end

				nvgRestore()
			end
		end
	end

	-- pre and post draw functions
	function widget_table:__goahud_pre_draw()
		nvgSave()
	end
	function widget_table:__goahud_post_draw()
		nvgRestore()
		widget_table:__goahud_draw_movables()
	end

	-- hook initialize function
	local initialize_func = function()
		GoaHud.GoaHud_HookErrorFunctions() -- in case one of my widgets happens to be called before others

		-- update accurate epoch time now if main module didn't get to it first
		if (epochTimeMs == 0) then
			self:updateEpochTimeMs()
		end

		if (widget_table.init == nil and not isAddon) then
			consolePrint(widget_name .. " does not have init() function")
			return
		end

		if (widget_table.optionsDisplayOrder ~= nil) then
			for i, k in pairs(widget_table.optionsDisplayOrder) do
				if (k ~= "" and k ~= "preview" and widget_table.options[k] == nil) then
					--consolePrint(widget_name .. ": invalid optionsDisplayOrder key '" .. k .. "'")
				end
			end

			for key in pairs(widget_table.options) do
				local key_found = false
				for i in pairs(widget_table.optionsDisplayOrder) do
					local key_display = widget_table.optionsDisplayOrder[i]
					if (key == key_display) then
						key_found = true
						break
					end
				end

				if (not key_found) then
					consolePrint(widget_name .. ": warning: key '" .. key .. "' not found in optionsDisplayOrder")
				end
			end
		end

		local first_time = not GoaHud_HasOptions(widget_table)

		-- initialize defaults from current options
		if (widget_table.defaults == nil and widget_table.options ~= nil) then
			widget_table.defaults = clone(widget_table.options)
			widget_table.defaults.enabled = widget_table.enabled
		end

		-- load widget options automatically
		widget_table:loadOptions()

		-- enable new non-experimental widgets by default
		--[[
		if (not isExperimental and first_time) then
			if (isModule) then
				widget_table.enabled = true
			else
				setWidgetVisibility(widget_name, true)
			end
			widget_table:saveOptions()
			widget_table:loadOptions()
		end
		--]]

		widget_table.firstTime = first_time

		-- wrap draw calls
		local draw_original = widget_table.draw
		local draw_wrapper
		if (isModule) then
			draw_wrapper = function(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
				widget_table:__goahud_invoked()

				-- modules visibility state can not be changed so
				-- the draw call must be prevented manually
				if (not widget_table.enabled) then return end

				widget_table:__goahud_pre_draw()
				draw_original(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
				widget_table:__goahud_post_draw()
			end
		else
			draw_wrapper = function(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
				widget_table:__goahud_invoked()

				widget_table:__goahud_pre_draw()
				draw_original(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
				widget_table:__goahud_post_draw()
			end
		end

		widget_table.draw = function(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
			local status, err = pcall(draw_wrapper, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
			if (status == false) then
				onError(widget_name, err)
				consolePrint(string.format("lua (%s): %s", widget_name, tostring(err)), true)

				-- disable draw calls
				widget.draw = function() end
			end
		end

		if (widget_table.init ~= nil) then
			widget_table:init()
		end
	end

	widget_table.initialize = function(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
		local status, err = pcall(initialize_func, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
		if (status == false) then
			onError(widget_name, err)
			consolePrint(string.format("lua (%s): %s", widget_name, tostring(err)), true)

			-- disable draw calls
			widget.draw = function() end
		end
	end

	widget_table.__goahud_invoke_method = 0
	widget_table.widgetName = widget_name

	-- addons are registered like any other lua addon
	if (not isAddon) then
		registerWidget(widget_name)
	end

	table.insert(self.registeredWidgets, widget_info)

	-- run GoaHud initialize procedure for addons
	if (isAddon) then
		widget_table:initialize(widget_table)
	end
end

function GoaHud:registerWidgetCallbacks()
	for i, w in pairs(self.registeredWidgets) do
		local widget_table = _G[w.name]

		self:tryAddObserver(widget_table, "onError")
		self:tryAddObserver(widget_table, "onLog")
		self:tryAddObserver(widget_table, "onMatchChange")
	end
end

function GoaHud:tryAddObserver(widget, func_name)
	if (widget[func_name] == nil) then return end

	table.insert(self.observers[func_name], { widget = widget, name = widget.widgetName, func = widget[func_name] })
end

function setWidgetVisibility(widget, visible)
	if (visible) then
		consolePerformCommand(string.format("ui_show_widget %s", widget))
	else
		consolePerformCommand(string.format("ui_hide_widget %s", widget))
	end
end

function GoaHud:restoreWidgets(widgets_)
	local widgets_ = widgets_ or officialWidgets
	if (widgets_ == {}) then return end

	if (type(widgets_[1]) == "string") then
		for i, widget in pairs(widgets_) do
			setWidgetVisibility(widget, widget ~= "WeaponName")
		end
	else
		for i, widget in pairs(widgets_) do
			if (isModule(widget)) then
				local widget_table = _G[widget.name]
				if (widget_table.enabled == false) then
					widget_table.enabled = true

					if (widget_table.onEnabled ~= nil) then
						widget_table.onEnabled(widget_table, widget_table.enabled)
					end

					self:invokeSaveLoadOptions(widget_table)
				end
			else
				setWidgetVisibility(widget.name, widget.name ~= "WeaponName")
			end
		end
	end
end

function GoaHud:hideWidgets(widgets_)
	local widgets_ = widgets_ or officialWidgets
	if (widgets_ == {}) then return end

	if (type(widgets_[1]) == "string") then
		for i, widget in pairs(widgets_) do
			setWidgetVisibility(widget, false)
		end
	else
		for i, widget in pairs(widgets_) do
			if (isModule(widget)) then
				local widget_table = _G[widget.name]
				if (widget_table.enabled == true) then
					widget_table.enabled = false

					if (widget_table.onEnabled ~= nil) then
						widget_table.onEnabled(widget_table, widget_table.enabled)
					end

					self:invokeSaveLoadOptions(widget_table)
				end
			else
				setWidgetVisibility(widget.name, false)
			end
		end
	end
end

function GoaHud:isWidgetEnabled(widget)
	for i, w in pairs(self.registeredWidgets) do
		if (w.name == widget) then
			if (isModule(w)) then
				return _G[w.name].enabled
			end
		end
	end

	for i, w in pairs(widgets) do
		if (w.name == widget) then
			return w.visible
		end
	end
end

function GoaHud:getWidgetAnchor(widget)
	local anchor
	for i, k in pairs(widgets) do
		if (k.name == widget.widgetName) then
			anchor = k.anchor
			break
		end
	end

	return anchor
end

function GoaHud:alignTextWithWidgetAnchor(widget)
	local anchor = GoaHud:getWidgetAnchor(widget)
	local hori, vert

	if (anchor.x == -1) then hori = NVG_ALIGN_LEFT
	elseif (anchor.x == 0) then hori = NVG_ALIGN_CENTER
	else hori = NVG_ALIGN_RIGHT end

	if (anchor.y == -1) then vert = NVG_ALIGN_TOP
	elseif (anchor.y == 0) then vert = NVG_ALIGN_MIDDLE
	else vert = NVG_ALIGN_BOTTOM end

	nvgTextAlign(hori, vert)
end

function GoaHud:shouldShowHUD(optargs)
	local optargs = optargs or {}
	local show = shouldShowHUD(optargs)
	local showWhenForge = optargs.showWhenForge
	show = show and not (world ~= nil and world.mapName == "forge" and not showWhenForge)
	return show
end

--
-- convar stuff
--

function GoaHud:processConVars()
	local cvar_set = self:getConsoleVariable("set")
	if (cvar_set ~= nil and cvar_set ~= "") then
		local args = {}
		for i in string.gmatch(cvar_set, "%S+") do args[#args + 1] = i end
		if (#args >= 2) then
			local arg_widget = string.lower(args[1])
			local arg_var = string.lower(args[2])
			local arg_value = args[3] ~= nil and args[3] or ""

			local widget_table
			for i, w in pairs(self.registeredWidgets) do
				local name_full = string.lower(w.name)
				local name = name_full
				if (string.starts(w.name, "GoaHud_")) then
					name = string.sub(name, string.len("GoaHud_")+1)
				end

				if (name == arg_widget or name_full == arg_widget) then
					widget_table = _G[w.name]
					break
				end
			end

			if (widget_table ~= nil and widget_table.options ~= nil) then
				local found_var
				for var in pairs(widget_table.options) do
					if (string.lower(var) == arg_var) then
						found_var = var
						break
					end
				end

				if (found_var ~= nil) then
					local found_type = type(widget_table.options[found_var])
					local num_value = tonumber(arg_value)
					if (found_type == "table") then
						consolePrint("cannot assign to a table")
					elseif (found_type == "boolean") then
						local num_value = tonumber(arg_value)
						if (num_value ~= nil) then
							widget_table.options[found_var] = num_value ~= 0
						elseif (string.lower(arg_value) == "true") then
							widget_table.options[found_var] = true
						elseif (string.lower(arg_value) == "false") then
							widget_table.options[found_var] = false
						else
							consolePrint("invalid value for boolean")
						end
					elseif (found_type == "number") then
						if (num_value ~= nil) then
							widget_table.options[found_var] = num_value
						else
							consolePrint("invalid value for number")
						end
					elseif (found_type == "string") then
						widget_table.options[found_var] = arg_value
					else
						consolePrint("cannot assign to a type of " .. tostring(found_type))
					end
				else
					consolePrint("invalid variable name")
				end
			else
				consolePrint("invalid widget name")
			end
		else
			consolePrint("usage: ui_goahud_set <widget> <variable> <value>")
		end

		widgetSetConsoleVariable("set", "")
	end

	if (#self.convarQueue > 0) then
		for i, k in ipairs(self.convarQueue) do
			if (k.create) then
				assert(k.type ~= nil, "failed to create console variable, type is not set")
				widgetCreateConsoleVariable(k.name, k.type, k.value)
			end

			-- widgetCreateConsoleVariable initializes with the value
			-- only if user has not set it before, we may need to force
			-- the value into variable if needed
			if (k.forced) then
				widgetSetConsoleVariable(k.name, k.value)
			end
		end
		self.convarQueue = {}
	end
end

function GoaHud:createConsoleVariable(name, vartype, value, forced)
	table.insert(self.convarQueue, {name = name, type = vartype, value = value, create = true, forced = forced or false})
end

function GoaHud:setConsoleVariable(name, value)
	local full_cvar = string.format("ui_goahud_%s", name)
	if (#self.convarQueue > 0) then
		-- convar has not been created yet, change initial value instead
		for i, c in ipairs(self.convarQueue) do
			if (c.name == name) then
				c.value = value
				c.forced = true
				return
			end
		end
	end

	-- consolePerformCommand is used so any widget calling this function can
	-- change the console variables registered by GoaHud instead of registering
	-- the variable for itself. Unfortunately consolePerformCommand can not be used
	-- for emptying any cvars so emptying has to be done by GoaHud itself.
	if (value == "") then
		table.insert(self.convarQueue, {name = name, value = value, create = false, forced = true})
	else
		consolePerformCommand(full_cvar .. " " .. value)
	end
end

function GoaHud:getConsoleVariable(name)
	local full_cvar = string.format("ui_goahud_%s", name)
	if (#self.convarQueue > 0) then
		-- try to read the value from convar queue if it hasn't been created yet
		for i, c in ipairs(self.convarQueue) do
			if (c.name == name) then
				return c.value
			end
		end
	end

	return consoleGetVariable(full_cvar)
end

--
-- rebind helpers
--

function rebindLookup(varname, oldval, newval)
	local var1 = string.format("%s %d", varname, oldval)
	if (bindReverseLookup(var1) ~= "(unbound)") then
		consolePrint(string.format("Rebinding %s key", varname))
		rebindHoldKey(var1, string.format("%s %d", varname, newval))
	end
end

function rebindHoldKey(command, override)
	rebindHoldKeyState(command, "game", override)
	rebindHoldKeyState(command, "re", override)
	rebindHoldKeyState(command, "me", override)
end

function rebindHoldKeyState(command, state, override)
	local commandProper = string.format("%s; +showscores", command)
	if (override ~= nil) then
		commandProper = string.format("%s; +showscores", override)
	end

	-- rebind the hold key again with +showscores to enable the hold key hack
	local holdKey = bindReverseLookup(command, state)
	if (holdKey ~= "(unbound)") then
		consolePerformCommand(string.format("unbind %s %s", state, holdKey))
		consolePerformCommand(string.format("bind %s %s %s", state, holdKey, commandProper))
	end
end

--
-- userData helpers
--

-- fills missing information in container with default values
function applyDefaults(container, varname, vartype, defaults)
	if (defaults == nil) then return end

	if (vartype == "table") then
		if (container[varname] == nil) then
			container[varname] = clone(defaults)
		else
			for i, v in pairs(defaults) do
				applyDefaults(container[varname], i, type(v), v)
			end
		end
	elseif (type(container) ~= "table") then
		-- do not override variables with tables
	elseif (type(container[varname]) ~= vartype) then
		container[varname] = defaults
	end
end

-- updates existing information with new values
function applyValues(container, varname, vartype, values)
	if (values == nil) then return end

	if (vartype == "table") then
		if (container[varname] == nil) then
			container[varname] = clone(values)
		else
			for i, v in pairs(values) do
				applyValues(container[varname], i, type(v), v)
			end
		end
	elseif (values ~= nil) then
		container[varname] = values
	end
end

function GoaHud_HasOptions(self)
	return loadUserData() ~= nil
end

function GoaHud_LoadOptions(self)
	assert(self.options ~= nil, self.widgetName .. ": options is not defined")

	self.options.enabled = self.enabled

	local userData = loadUserData()
	applyValues(self, "options", "table", userData)

	local first_time = userData == nil

	if (self.enabled ~= nil and self.options ~= nil and self.options.enabled ~= nil) then
		self.enabled = self.options.enabled
	end

	applyDefaults(self, "options", "table", self.defaults)

	if (self.enabled ~= nil and self.options.enabled ~= nil) then
		self.enabled = self.options.enabled
		self.options.enabled = nil
	end

	if (first_time) then
		if (self.anchor ~= nil) then
			consolePerformCommand(string.format("ui_set_widget_anchor %s %d %d", self.widgetName, self.anchor.x, self.anchor.y))
		end
		if (self.offset ~= nil) then
			consolePerformCommand(string.format("ui_set_widget_offset %s %f %f", self.widgetName, self.offset.x, self.offset.y))
		end
		GoaHud_SaveOptions(self)
	end
end

function GoaHud_SaveOptions(self)
	if (self.enabled ~= nil) then
		self.options.enabled = self.enabled
	end

	-- save only the values that were changed by the user
	local changed = getChangedValues(self.options, self.defaults)

	saveUserData(changed)

	if (self.enabled ~= nil) then
		self.options.enabled = nil
	end
end

function GoaHud_ResetOptions(self)
	applyValues(self, "options", "table", self.defaults)
end

function GoaHud:invokeLoadOptions(widget_table)
	widget_table.__goahud_invoke_method = GOAHUD_INVOKE_LOAD
end

function GoaHud:invokeSaveOptions(widget_table)
	widget_table.__goahud_invoke_method = GOAHUD_INVOKE_SAVE
end

function GoaHud:invokeSaveLoadOptions(widget_table)
	widget_table.__goahud_invoke_method = GOAHUD_INVOKE_SAVELOAD
end

function getChangedValues(new, old)
	local changed
	local t = type(new)
	if (t == "table") then
		changed = {}
		if (old == nil) then
			for i, v in pairs(new) do
				changed[i] = getChangedValues(new[i], nil)
			end
		else
			for i, v in pairs(old) do
				changed[i] = getChangedValues(new[i], old[i])
			end
		end
	elseif (new ~= old and new ~= nil) then
		changed = new
	end

	return changed
end

function GoaHud:addMovableElement(movable_info)
	for i, m in pairs(self.movables) do
		if (m.movable == movable_info.movable or m.movable.name == movable_info.movable.name) then
			consolePrint("GoaHud: movable already exists: " .. movable_info.movable.name)
			return false
		end
	end

	if (movable_info.movable.name == nil or string.len(movable_info.movable.name) == 0) then
		consolePrint("GoaHud: invalid name for movable: " .. tostring(movable_info.movable.name))
		return false
	end

	if (movable_info.draw == nil) then
		consolePrint("GoaHud: movable lacks draw function: " .. tostring(movable_info.movable.name))
		return false
	end

	table.insert(self.movables, movable_info)
	return true
end

--
-- error helpers
--

-- Catches most of the error emitted inside initialize and draw functions,
-- does not catch any errors thrown during initial load >:(.

local function GoaHud_Detour(widget_name, func)
	local widget = _G[widget_name]
	assert(widget ~= nil, "detour failed, invalid widget " .. widget_name)

	-- wrap function call with pcall
	local error_wrapper = function(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
		local status, err = pcall(func(widget), arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
		if (status == false) then
			onError(widget_name, err)
			consolePrint(string.format("lua (%s): %s", widget_name, tostring(err)), true)

			-- disable draw calls
			widget.draw = function() end
		end
	end

	return error_wrapper
end

local function GoaHud_DetourInitialize(widget_name)
	local widget = _G[widget_name]
	assert(widget ~= nil, "detour failed, invalid widget " .. widget_name)

	if (widget.initialize == nil) then return end
	GoaHud_SetWidgetInitialize(widget, GoaHud_Detour(widget_name, GoaHud_GetWidgetOriginalInitialize))
end

local function GoaHud_DetourDraw(widget_name)
	local widget = _G[widget_name]
	assert(widget ~= nil, "detour failed, invalid widget " .. widget_name)

	if (widget.draw == nil) then return end
	GoaHud_SetWidgetDraw(widget, GoaHud_Detour(widget_name, GoaHud_GetWidgetOriginalDraw))
end

local hooked_widgets = {}
function GoaHud:GoaHud_HookErrorFunctions()
	for i, k in pairs(widgets) do
		if (k.name ~= nil and hooked_widgets[k.name] == nil) then
			local widget_table = _G[k.name]

			if (widget_table.__goahud_real_initialize == nil) then
				GoaHud_DetourInitialize(k.name)
			end

			if (k.name ~= "br_HudEditorPopup") then
				if (widget_table.__goahud_real_draw == nil) then
					GoaHud_DetourDraw(k.name)
				end
			else
				-- insert additional logic to Brandon's Hud Editor in order to handle GoaHud movables properly
				local draw_error_wrapper = function(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
					local getMovableName = function(m)
						return m.widget.widgetName .. "_" .. m.movable.name
					end

					-- hide modules from editor view
					for i, w in pairs(widgets) do
						for j, r in pairs(GoaHud.registeredWidgets) do
							if (w.name == r.name and isModule(r)) then
								widgets[i] = nil
								break
							end
						end
					end

					-- inject movables into global and widget table
					for i, m in pairs(GoaHud.movables) do
						local w = clone(m.movable)
						w.name = getMovableName(m)
						table.insert(widgets, w)
						_G[getMovableName(m)] = { drawOptions = m.drawOptions }
					end

					-- detour callWidget* functions so the movable's drawOptions function is called when the Options-button is clicked
					local old_callWidgetGetOptionsHeight = callWidgetGetOptionsHeight
					callWidgetGetOptionsHeight = function(widget, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
						for i, m in pairs(GoaHud.movables) do
							if (getMovableName(m) == widget) then
								widget = m.widget.widgetName
								break
							end
						end
						return old_callWidgetGetOptionsHeight(widget, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
					end

					local old_callWidgetDrawOptions = callWidgetDrawOptions
					callWidgetDrawOptions = function(widget, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
						for i, m in pairs(GoaHud.movables) do
							if (getMovableName(m) == widget) then
								widget = m.widget.widgetName
								break
							end
						end
						return old_callWidgetDrawOptions(widget, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
					end

					-- detour consolePerformCommand function, and translate ui_ commands to adjust movable settings
					local old_consolePerformCommand = consolePerformCommand
					consolePerformCommand = function(str, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
						local args = {}
						for i in string.gmatch(str, "%S+") do args[#args + 1] = i end

						local movable = nil
						local widget = nil
						for i, m in pairs(GoaHud.movables) do
							if (getMovableName(m) == args[2]) then
								movable = m.movable
								widget = m.widget
								break
							end
						end

						if (movable ~= nil) then
							if (args[1] == "ui_set_widget_offset") then
								movable.offset = { x = tonumber(args[3]), y = tonumber(args[4]) }
							elseif (args[1] == "ui_set_widget_anchor") then
								movable.anchor = { x = tonumber(args[3]), y = tonumber(args[4]) }
							elseif (args[1] == "ui_set_widget_scale") then
								movable.scale = tonumber(args[3])
							elseif (args[1] == "ui_set_widget_zindex") then
								--movable.zIndex = tonumber(args[3])
							elseif (args[1] == "ui_hide_widget") then
								movable.visible = false
							elseif (args[1] == "ui_show_widget") then
								movable.visible = true
							end

							GoaHud:invokeSaveLoadOptions(widget)
						else
							return old_consolePerformCommand(str, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
						end
					end

					local status, err = pcall(GoaHud_GetWidgetOriginalDraw(widget_table), arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)

					consolePerformCommand = old_consolePerformCommand
					callWidgetDrawOptions = old_callWidgetDrawOptions
					callWidgetGetOptionsHeight = old_callWidgetGetOptionsHeight

					if (status == false) then
						onError(k.name, err)
						consolePrint(string.format("lua (%s): %s", k.name, tostring(err)), true)

						-- disable future draw calls
						widget_table.draw = function() end
					end
				end

				GoaHud_SetWidgetDraw(widget_table, draw_error_wrapper)
			end

			hooked_widgets[k.name] = true
		end
	end
end

function GoaHud_GetWidgetOriginalInitialize(widget)
	if (widget.__goahud_real_initialize ~= nil) then return widget.__goahud_real_initialize end
	return widget.initialize
end

function GoaHud_GetWidgetOriginalDraw(widget)
	if (widget.__goahud_real_draw ~= nil) then return widget.__goahud_real_draw end
	return widget.draw
end

function GoaHud_SetWidgetInitialize(widget, func)
	if (widget.__goahud_real_initialize == nil) then
		widget.__goahud_real_initialize = widget.initialize
		widget.initialize = func
	else
		widget.__goahud_real_initialize = func
	end
end

function GoaHud_SetWidgetDraw(widget, func)
	if (widget.__goahud_real_draw == nil) then
		widget.__goahud_real_draw = widget.draw
		widget.draw = func
	else
		widget.__goahud_real_draw = func
	end
end

--
-- utility
--

function getWidgetName(widget)
	for i, w in pairs(widgets) do
		local t = _G[w.name]
		if (t ~= nil and t == widget) then
			return w.name
		end
	end
	return nil
end

function GoaHud:formatTime(elapsed, base)
	local base = base or 60
	local bb = base * base
	local seconds_total = math.floor(elapsed)
	return
	{
		hours = seconds_total % bb,
		hours_total = math.floor(seconds_total / bb),
		mins = seconds_total % bb,
		mins_total = math.floor(seconds_total / base),
		secs = seconds_total % base,
		secs_total = seconds_total,
		millis = elapsed % 1000,
	}
end

function GoaHud:getEffectiveHealth(health, armor, protection)
	return math.min(armor, health * (protection + 1)) + health
end

function isRaceOrTrainingMode()
	if (world == nil) then return false end
	local gameMode = gamemodes[world.gameModeIndex]
	if (gameMode == nil) then return false end
	return gameMode.shortName == "race" or gameMode.shortName == "training"
end

function isEmpty(myTable)
	local next = next
	if next(myTable) == nil then return true end
	return false
end

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

function table.reverse(tbl)
	for i=1, math.floor(#tbl / 2) do
		tbl[i], tbl[#tbl - i + 1] = tbl[#tbl - i + 1], tbl[i]
	end
end

function string.starts(str, start)
	return string.sub(str, 1, string.len(start)) == start
end

epochTimeMs = 0
local lastEpochTime = 0
function GoaHud:updateEpochTimeMs()
	epochTimeMs = epochTimeMs + deltaTimeRaw

	-- reset milliseconds when full second changes
	if (epochTime ~= lastEpochTime) then
		epochTimeMs = epochTime
	end

	lastEpochTime = epochTime
end

function GoaHud:getFont(font, bold, italics)
	local index
	local face

	if (type(font) == "table") then
		index = font.index
		face = font.face
		if (index <= 1 and (face == "" or face == nil)) then
			-- invalid font
			index = 2
		end
	else
		index = font
	end

	if (index > 1) then
		local font = GOAHUD_FONTS[index]
		if (not bold and not italics) then
			face = font.regular
		elseif (bold and not italics) then
			face = font.bold
		elseif (not bold and italics) then
			face = font.italic
		else
			face = font.bold_italic
		end

		if (face == nil) then face = font.regular end
	end

	return face
end

function GoaHud_GetVersionPretty()
    return "r" .. GoaHud_Version
end

--
-- emoji helpers
--

-- the path could be too long so the error message's filepath might not have .lua in the end
GoaHud_MainEmojiPath = ({string.match(({pcall(function() error("") end)})[2],"^%[string \"base/(.*)/.-%.lua\"%]:%d+: $")})[1] or ({string.match(({pcall(function() error("") end)})[2],"^%[string \"base/(.*)/.-%...\"%]:%d+: $")})[1]

function getFlag(text)
	local text = string.lower(text)
	local path = "internal/ui/icons/flags/"
	local svg = GoaHud_Flags[text]

	if (svg == nil) then
		path = GoaHud_MainEmojiPath .. "/emojis/"
		svg = GoaHud_FlagsCustom[text]
		-- try custom emojis as flags
		if (svg == nil) then
			svg = GoaHud_EmojisCustom[text]
		end
	end

	if (svg == nil) then return nil end
	return path .. svg
end

function getEmoji(text)
	local text = string.lower(text)
	local path-- = "internal/ui/icons/flags/"
	local svg
	local flag_prefix = "flag_"

	if (string.sub(text, 1, string.len(flag_prefix)) == flag_prefix) then
		local flag_svg = string.sub(text, string.len(flag_prefix)+1)
		path = GoaHud_MainEmojiPath .. "/emojis/"
		svg = GoaHud_FlagsCustom[flag_svg]
		if (svg == nil) then
			path = "internal/ui/icons/flags/"
			svg = GoaHud_Flags[flag_svg]
		end
	end

	if (svg == nil) then
		path = GoaHud_MainEmojiPath .. "/emojis/"
		svg = GoaHud_EmojisCustom[text]
		if (svg == nil) then
			if (GoaHud_EmojiPath) then -- requires emoji support widget
				path = GoaHud_EmojiPath .. "/emojis/"
				svg = GoaHud_Emojis[text]
			end
			if (svg == nil) then
				path = "internal/ui/icons/"
				svg = GoaHud_EmojisInternal[text]
			end
		end
	end

	if (svg == nil) then return nil end
	return path .. svg
end

function getEmojiColor(text)
	return GoaHud_EmojisColor[text]
end

function isEmoji(text)
	return getEmoji(text) ~= nil
end

function isFlag(text)
	if (text == nil) then return false end
	local text = string.lower(text)
	return GoaHud_Flags[text] ~= nil or GoaHud_FlagsCustom[text]
end

function GoaHud_Sanitize(text)
	local sanitized = text
	local prev
	while (prev ~= sanitized) do
		prev = sanitized
		sanitized = string.gsub(sanitized, escape_pattern, "")
	end
	return sanitized
end

function nvgTextBoundsEmoji(text, optargs)
	local emoji_size = nil
	local strip_color = nil
	if (optargs) then
		emoji_size = optargs.emojiSize
		strip_color = optargs.stripColorCodes
		if (optargs.previewColorCodes) then
			strip_color = false
		end
	end
	if (emoji_size == nil) then emoji_size = nvgFontSizeCurrent * emojiSizeMultiplier end

	-- it's desirable to default to stripping mode when measuring text bounds
	if (strip_color == nil and (optargs and optargs.ignoreColorCodes == nil)) then strip_color = true end

	-- strip color codes from the text
	if (strip_color) then
		text = string.gsub(text, color_pattern, "")
	end

	local width = 0
	for i=1, 100 do
		-- find emoji shortcodes
		local match_start, match_end = string.find(string.lower(text), emoji_pattern)
		if (match_start == nil) then
			local bounds = nvgTextBounds_real(text)
			bounds.maxx = bounds.maxx + width
			return bounds
		end

		-- remove shortcode from text string
		if (getEmoji(string.sub(text, match_start+1, match_end-1)) ~= nil) then
			text = string.sub(text, 1, match_start-1) .. string.sub(text, match_end+1, #text)
			width = width + emoji_size
		else
			local bounds = nvgTextBounds_real(text)
			bounds.maxx = bounds.maxx + width
			return bounds
		end
	end

	local bounds = nvgTextBounds_real(text)
	bounds.maxx = bounds.maxx + width
	return bounds
end

function nvgTextBoundsStrip(text, optargs)
	return nvgTextBounds_real(string.gsub(text, color_pattern, ""), optargs)
end

function nvgTextWidthEmoji(text, optargs)
	local emoji_size = nil
	local strip_color = nil
	if (optargs) then
		emoji_size = optargs.emojiSize
		strip_color = optargs.stripColorCodes
		if (optargs.previewColorCodes) then
			strip_color = false
		end
	end
	if (emoji_size == nil) then emoji_size = nvgFontSizeCurrent * emojiSizeMultiplier end

	-- it's desirable to default to stripping mode when measuring text bounds
	if (strip_color == nil and (optargs and optargs.ignoreColorCodes == nil)) then strip_color = true end

	-- strip color codes from the text
	if (strip_color) then
		text = string.gsub(text, color_pattern, "")
	end

	local width = 0
	for i=1, 100 do
		-- find emoji shortcodes
		local match_start, match_end = string.find(string.lower(text), emoji_pattern)
		if (match_start == nil) then
			return width + nvgTextWidth_real(text)
		end

		-- remove shortcode from text string
		if (getEmoji(string.sub(text, match_start+1, match_end-1)) ~= nil) then
			text = string.sub(text, 1, match_start-1) .. string.sub(text, match_end+1, #text)
			width = width + emoji_size
		else
			return width + nvgTextWidth_real(text)
		end
	end

	return width + nvgTextWidth_real(text)
end

function nvgTextWidthStrip(text, optargs)
	return nvgTextWidth_real(string.gsub(text, color_pattern, ""), optargs)
end

function string.lenColor(text)
	return string.len(string.gsub(text, color_pattern, ""))
end

nvgFillColor = function(color)
	nvgFillColorCurrent = clone(color)
	return nvgFillColor_real(color)
end

nvgFontSize = function(size)
	nvgFontSizeCurrent = clone(size)
	return nvgFontSize_real(size)
end

-- missing functions in 0.48.3

if (EaseOut == nil) then
	function EaseInOut(t)
		if t <= 0.5 then
			return 2 * t * t;
		end
		t = t - 0.5;
		return 2.0 * t * (1.0 - t) + 0.5;
	end
	function Linear(t)
		return t;
	end
	function EaseIn(t)	-- quadratic
		return t*t;
	end
	function EaseOut(t)	-- quadratic
		return t*(2-t);
	end
end
