-- GoaHud made by GoaLitiuM
-- 
-- Main module for GoaHud and GoaHud widgets
--

--[[
GoaHud_Addon =
{
	enabled = false, 	-- for modules, controls tick function
	options = {},		-- userData, loaded automatically by main module
	
	-- optional: order in which to render options keys
	optionsDisplayOrder = { "key1", "key2", }
}
GoaHud:registerWidget("GoaHud_Addon", GOAHUD_UI or GOAHUD_MODULE)

--
-- required functions:
--

function GoaHud_Addon:init() end
function GoaHud_Addon:draw() end -- for UI
function GoaHud_Addon:tick() end -- for modules

--
-- optional functions:
--

-- called when module enabled state is changed
function GoaHud_Addon:onEnabled(enabled)

-- provides custom rendering for each options variable
-- by default following function is called for each variable, and is returned:
--   GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs)
-- return: the required height for rendering, or nil if no custom rendering was provided for given variable
function GoaHud_Addon:drawOptionsVariable(varname, x, y, optargs)

--]]

require "base/internal/ui/reflexcore"

GoaHud =
{
	canHide = false,
	canPosition = false,
	
	enabled = false,
	options =
	{
	},
		
	goaWidgets = {},
	
	showOptions = true, -- debug
	dirtyConvars = false,
	convarQueue = {},
	
	colorCodesSupported = false, -- Kimi's EmojiChat
	previewMode = false, -- Brandon's Hud Editor
};
registerWidget("GoaHud")

GOAHUD_FONT1 = "vipnagorgialla"
GOAHUD_FONT2 = "Lato-Heavy-Optimized"
GOAHUD_FONT3 = "Volter__28Goldfish_29"
GOAHUD_FONT4 = "OpenSans-CondBold"

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

GOAHUD_SPACING = 40
GOAHUD_INDENTATION = 60

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

optargs_deadspec =
{
	showWhenDead = true,
	showWhenSpec = true,
}

officialWidgets = { "AmmoCount", "ArmorBar", "AwardNotifier", "Buffs", "ChatLog", "Crosshairs", "FragNotifier", "GameMessages", "GoalList", "HealthBar", "KillFeed", "LagNotifier", "LowAmmo", "Matchmaking", "Message", "MovementKeys", "PickupNotifier", "PickupTimers", "PlayerSpeed", "PlayerStatus", "RaceMessages", "RaceRecords", "RaceTimer", "Scoreboard", "ScreenEffects", "TeamHud", "Timer", "TrueHealth", "Vote", "WeaponName", "WeaponRack" }
replacedOfficialWidgets = { "AmmoCount", "ArmorBar", "Crosshairs", "FragNotifier", "GameMessages", "HealthBar", "LowAmmo", "PlayerStatus", "RaceTimer", "Timer", "WeaponRack", "TrueHealth" }

function GoaHud:initialize()
	self.widgetName = "GoaHud"
	self.draw = self.drawFirst
	GoaHud_LoadOptions(self)
end

function GoaHud:drawOptions(x, y, intensity)
	local optargs = {}
	optargs.intensity = intensity
	optargs.optionalId = 0

	local lastEnabled = self.enabled
	self.enabled = GoaRowCheckbox(x, y, WIDGET_PROPERTIES_COL_INDENT, "Enable GoaHud", self.enabled, optargs)
	GoaLabel("(Warning: enabling will hide some of the official widgets)", x + 320, y, optargs)

	if (lastEnabled ~= self.enabled) then
		local non_experimental_goawidgets = {}
		for i, k in pairs(self.goaWidgets) do
			if (k.category == GOAHUD_UI or k.category == GOAHUD_MODULE) then
				table.insert(non_experimental_goawidgets, k)
			end
		end
		
		if (not isEmpty(self.goaWidgets)) then	
			if (self.enabled) then
				GoaHud:hideWidgets(replacedOfficialWidgets)
				GoaHud:restoreWidgets(non_experimental_goawidgets)
			else
				GoaHud:hideWidgets(self.goaWidgets)
				GoaHud:restoreWidgets(replacedOfficialWidgets)
			end
		end
	end

	local enabled_optargs = clone(optargs)
	enabled_optargs.enabled = self.enabled
	
	local elements_height = self:drawWidgetList(x, y + 60, GOAHUD_UI, enabled_optargs)
	
	local modules_height = self:drawWidgetList(x + 450, y + 60, GOAHUD_MODULE, enabled_optargs)
	local experimental_height = self:drawWidgetList(x + 450, y + 60 + modules_height + 30, GOAHUD_MODULE_EXPERIMENTAL, enabled_optargs)
	local experimental2_height = self:drawWidgetList(x + 450, y + 60 + modules_height + experimental_height + 30, GOAHUD_UI_EXPERIMENTAL, enabled_optargs)
	
	optargs.optionalId = optargs.optionalId + 1

	GoaHud_SaveOptions(self)
	GoaHud_LoadOptions(self)
end

function GoaHud:drawWidgetList(x, y, category, optargs)
	local offset_x = 20
	local offset_y = 40

	local count = 0
	
	for i, w in ipairs(self.goaWidgets) do
		local name = w.name
		local name_short = string.gsub(name, "GoaHud_", "")

		if (w.category == category) then
			count = count + 1
			
			local widget
			for j, k in ipairs(widgets) do
				if (k.name == w.name) then widget = k; break end
			end
			
			local widget_table = loadstring(string.format("return %s", name))()
			
			local enabled, old_enabled
			optargs.optionalId = optargs.optionalId + 1
			
			if (category == GOAHUD_MODULE) then
				enabled = widget_table.enabled
				old_enabled = enabled

				enabled = GoaRowCheckbox(x + offset_x, y + offset_y, WIDGET_PROPERTIES_COL_INDENT, name_short, enabled, optargs);
				if (enabled ~= old_enabled) then
					widget_table.enabled = enabled
					
					if (widget_table.onEnabled ~= nil) then
						widget_table.onEnabled(widget_table, enabled)
					end
					
					widget_table.saveOptions()
					widget_table.loadOptions()
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

function GoaHud_DrawOptions(self, x, y, intensity)
	local optargs = { intensity = intensity, optionalId = 1 }
	local offset_x = 0
	local offset_y = 0

	local reset_pressed, hover = GoaButton("Reset Settings", x + offset_x, y + offset_y, 150, 35, optargs)
	if (reset_pressed) then
		self.options = clone(self.defaults)
	end
	
	if (not popupActive) then
		if (self.drawPreview ~= nil) then
			offset_y = offset_y + self:drawPreview(x + 150 + 20, y, intensity)
		else
			offset_y = offset_y + GOAHUD_SPACING*1.5
		end
	end

	optargs.optionalId = optargs.optionalId + 1
	
	-- we try to iterate names over defaults table because the order of keys in options table may not remain the same
	local options_keys = self.defaults
	local pairs_func = pairs
	local name_func = function(key) return key end
	
	-- ...unless addon wants to display it in different order
	if (self.optionsDisplayOrder ~= nil) then
		options_keys = self.optionsDisplayOrder
		pairs_func = ipairs
		name_func = function(key) return options_keys[key] end
	end

	for i in pairs_func(options_keys) do
		local name = name_func(i)
		if (name ~= "enabled" and name ~= "shadow") then
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
		local value = self.options.shadow
		value.shadowEnabled = GoaRowCheckbox(x + offset_x, y + offset_y, 190, "Enable Shadows:", value.shadowEnabled, optargs)

		local optargs_shadows = clone(optargs)
		optargs_shadows.enabled = value.shadowEnabled
		
		offset_x = offset_x + GOAHUD_INDENTATION
		offset_y = offset_y + GOAHUD_SPACING

		local shadow_offset = value.shadowOffset
		GoaLabel("Offset: ", x + offset_x, y + offset_y, optargs_shadows)
		shadow_offset = GoaSlider(x + offset_x + 90, y + offset_y, 200, -10, 10, shadow_offset, optargs_shadows)
		value.shadowOffset = round(shadow_offset * 1) / 1.0
		
		shadow_offset = value.shadowOffset
		shadow_offset = GoaEditBox0Decimals(shadow_offset, x + offset_x + 90 + 220, y + offset_y, 75, optargs_shadows)
		value.shadowOffset = shadow_offset
		
		offset_y = offset_y + GOAHUD_SPACING
		
		local shadow_blur = value.shadowBlur
		GoaLabel("Blur: ", x + offset_x, y + offset_y, optargs_shadows)
		shadow_blur = GoaSlider(x + offset_x + 90, y + offset_y, 200, 0, 40, shadow_blur, optargs_shadows)
		value.shadowBlur = round(shadow_blur * 10) / 10.0
		
		shadow_blur = value.shadowBlur
		shadow_blur = GoaEditBox2Decimals(shadow_blur, x + offset_x + 90 + 220, y + offset_y, 75, optargs_shadows)
		value.shadowBlur = shadow_blur
		
		offset_y = offset_y + GOAHUD_SPACING
		
		local shadow_strength = value.shadowStrength
		GoaLabel("Strength: ", x + offset_x, y + offset_y, optargs_shadows)
		shadow_strength = GoaSlider(x + offset_x + 90, y + offset_y, 200, 0.2, 5, shadow_strength, optargs_shadows)
		value.shadowStrength = round(shadow_strength * 10) / 10.0
		
		shadow_strength = value.shadowStrength
		shadow_strength = GoaEditBox2Decimals(shadow_strength, x + offset_x + 90 + 220, y + offset_y, 75, optargs_shadows)
		value.shadowStrength = shadow_strength
		
		offset_y = offset_y + GOAHUD_SPACING
		
		GoaLabel("Color: ", x + offset_x, y + offset_y, optargs_shadows)
		local shadow_color = value.shadowColor
		shadow_color = GoaColorPicker(x + offset_x + 90, y + offset_y, shadow_color, optargs_shadows)
		value.shadowColor = shadow_color
		
		offset_x = offset_x - GOAHUD_INDENTATION
		offset_y = offset_y + GOAHUD_SPACING
	end
	
	self.getOptionsHeight = function() return offset_y end

	self:saveOptions()
	self:loadOptions()
end

local function toReadable(str)
	return FirstToUpper(str:gsub("%u", function(c) return ' ' .. c end))
end

function GoaHud_DrawOptionsVariable(options, name, x, y, optargs, name_readable)
	local offset_x = 0
	local offset_y = 0
	local value = options[name]
	local vartype = type(value)
	local name_readable = name_readable or toReadable(name)
	local draw_label = vartype ~= "boolean"
	
	nvgSave()
	ui2FontNormal()
	local name_length = nvgTextWidth(name_readable)
	
	nvgRestore()
	
	local label_offset = 0
	local label_width = name_length + 35
	local checkbox_width = math.max(190, name_length + 35)

	if (draw_label) then
		if (name_length >= 145) then
			offset_y = offset_y + GOAHUD_SPACING*0.85
			label_offset = -GOAHUD_SPACING*0.85
			label_width = 90
		end
		
		GoaLabel(name_readable .. ":", x + offset_x, y + offset_y + label_offset, optargs)
	end
	
	if (vartype == "table" and string.find(name_readable, "Color")) then
		local color = GoaColorPicker(x + offset_x + label_width, y + offset_y, value, optargs)
		if (color.r ~= nil and color.g ~= nil and color.b ~= nil and color.a ~= nil) then
			options[name] = color
		end
		
		offset_y = offset_y + GOAHUD_SPACING
	elseif (vartype == "boolean") then
		local checked = value
		checked = GoaRowCheckbox(x + offset_x, y + offset_y, checkbox_width, name_readable .. ":", checked, optargs)
		options[name] = checked

		offset_y = offset_y + GOAHUD_SPACING
	elseif (vartype == "number") then
		offset_x = offset_x + GOAHUD_INDENTATION
		
		local min_value = 0.0
		local max_value = 5.0
		
		local milliseconds = false
		local seconds = false
		
		if (optargs.milliseconds ~= nil or optargs.seconds ~= nil) then
			if (optargs.milliseconds ~= nil) then milliseconds = optargs.milliseconds end
			if (optargs.seconds ~= nil) then seconds = optargs.seconds end
		elseif (string.find(name_readable, "Time")) then
			seconds = true
		elseif (string.find(name_readable, "Interval")) then
			milliseconds = true
		end
		
		if (milliseconds) then
			GoaLabel("ms", x + offset_x + 90 + 220 + 85, y + offset_y, optargs)
		elseif (seconds) then
			GoaLabel("seconds", x + offset_x + 90 + 220 + 85, y + offset_y, optargs)
		end
		
		local new_value = value
		
		if (optargs.min_value ~= nil or optargs.max_value ~= nil) then
			if (optargs.min_value ~= nil) then min_value = optargs.min_value end
			if (optargs.max_value ~= nil) then max_value = optargs.max_value end
		elseif (milliseconds) then
			min_value = 0.0
			max_value = 300
		elseif (string.find(name_readable, "Fov")) then
			min_value = 10
			max_value = 178
		end
		
		if (milliseconds) then new_value = new_value * 1000 end
		
		new_value = GoaSlider(x + offset_x + 90, y + offset_y, 200, min_value, max_value, new_value, optargs)
		
		local show_editbox = true
		if (optargs.show_editbox ~= nil) then show_editbox = optargs.show_editbox end
		
		if (show_editbox) then
			optargs.optionalId = optargs.optionalId + 1
			new_value = GoaEditBox2Decimals(new_value, x + offset_x + 90 + 220, y + offset_y, 75, optargs)
		end
		
		if (optargs.tick ~= nil) then
			new_value = round(new_value * optargs.tick) / optargs.tick
		elseif (milliseconds) then
			new_value = round(new_value)
			new_value = math.min(max_value, new_value)
			new_value = math.max(min_value, new_value)
			new_value = new_value / 1000.0
		else
			new_value = round(new_value * 100) / 100.0
		end
		
		if (not milliseconds) then
			new_value = math.min(max_value, new_value)
			new_value = math.max(min_value, new_value)
		end
		
		if (not show_editbox) then
			GoaLabel(new_value, x + offset_x + 90 + 220, y + offset_y, optargs)
		end
		
		options[name] = new_value
		
		offset_x = offset_x - GOAHUD_INDENTATION
		offset_y = offset_y + GOAHUD_SPACING
	else
		offset_y = offset_y + GOAHUD_SPACING
		consolePrint("??? : " .. name)
	end
	
	optargs.optionalId = optargs.optionalId + 1
	
	return offset_y
end

--
-- ui element wrappers
--

local popupActive = false
function GoaLabel(text, x, y, optargs)
	if (popupActive) then return value end
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
	if (popupActive) then return value end
	return ui2ComboBox(options, selection, x, y, w, comboBoxData, optargs)
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

--
-- draw
--

function GoaHud:drawFirst()
	self:processConVars()
	
	if (nvgColorText ~= nil) then self.colorCodesSupported = true end
	
	self.draw = self.drawReal
end

function GoaHud:drawReal()
	--[[
	if (self.showOptions and shouldShowHUD()) then
		nvgSave()
		nvgBeginPath()
		nvgFillColor(Color(64,64,64,255))
		nvgRect(-350, -350, 1000, 750)
		nvgFill()
		nvgRestore()
		
		callWidgetDrawOptions("GoaHud", -300, -300, 1.0)
		consolePerformCommand("m_enabled 1")
	end
	--]]

	
	if (br_HudEditorPopup ~= nil) then self.previewMode = not br_HudEditorPopup.show_menu end
	
	self:processConVars()
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
	local color_codes = color_codes or false

	nvgSave()
	self:drawTextStyle1(size)

	nvgTranslate(round(x), round(y))
	
	if (shadow.shadowEnabled) then
		self:drawTextShadow(0, 0, shadow, value, color.a, color_codes)
	end

	nvgFillColor(color)
	
	if (color_codes) then
		if (self.colorCodesSupported) then
			nvgColorText(0, 0, value)
		else
			nvgText(0, 0, string.gsub(value, "%^[0-9]", ""))
		end
	else
		nvgText(0, 0, value)
	end
	
	nvgRestore()
end

function GoaHud:drawTextStyleHA(size)
	self:drawTextStyle1(size)
end

function GoaHud:drawTextHA(x, y, size, color, shadow, value)
	self:drawText1(x, y, size, color, shadow, value, color_codes)
end

function GoaHud:drawTextShadow(x, y, shadow, value, alpha, color_codes)
	if (shadow == nil or shadow == {}) then return end
	local alpha = alpha or 255
	local color_codes = color_codes or false
	
	-- HACK: with transparent text, shadows will shine through the text...
	-- halven the transparency to make it look better visually 
	if (alpha < 255) then
		alpha = alpha * 0.5
	end
	
	-- strip color codes from the text, we don't want to color our shadows
	if (color_codes) then
		value = string.gsub(value, "%^[0-9]", "")
	end
	
	nvgSave()
	local shadow_x = shadow.shadowOffset
	local shadow_y = shadow.shadowOffset

	nvgFontBlur(shadow.shadowBlur)
	
	local shadow_color = shadow.shadowColor
	local shadow_left = shadow.shadowStrength * (alpha / 255)
	
	while (shadow_left > 0.0) do
		local shadow_alpha = math.min(1.0, shadow_left)
		
		nvgFillColor(Color(shadow.shadowColor.r, shadow.shadowColor.g, shadow.shadowColor.b, shadow.shadowColor.a * shadow_alpha))
		nvgText(x + shadow_x, y + shadow_y, value)

		shadow_left = shadow_left - shadow_alpha
	end

	nvgRestore()
end

--
-- widget helpers
--

function GoaHud:registerWidget(widget_name, category)
	local category = category or GOAHUD_UI

	local widget_table = loadstring(string.format("return %s", widget_name))()
	local widget_info =
	{
		name = widget_name,
		category = category
	}
	
	local isExperimental = category == GOAHUD_UI_EXPERIMENTAL or category == GOAHUD_MODULE_EXPERIMENTAL
	local isModule = category == GOAHUD_MODULE or category == GOAHUD_MODULE_EXPERIMENTAL
	
	-- define missing variables
	
	if (isModule) then
		widget_table.canHide = false
		widget_table.canPosition = false
		if (widget_table.enabled == nil) then
			widget_table.enabled = false
		end
		
		-- modules should not have draw functions, but instead
		-- we call tick every frame instead only if the module is enabled
		
		local nop = function() end
		
		local tick_wrapper = function()
			if (not widget_table.enabled) then return end
			widget_table:tick()
		end

		function widget_table:draw()
			if (widget_table.tick ~= nil) then
				widget_table.draw = tick_wrapper
			else
				consolePrint(widget_name .. " does not have tick() function")
				widget_table.draw = nop
			end
		end
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
	
	-- default drawOptions for widget
	local variable_count = 0	
	for i in pairs(widget_table.options) do variable_count = variable_count + 1 end
	
	if (variable_count > 0) then
		function widget_table:drawOptions(x, y, intensity)
			GoaHud_DrawOptions(widget_table, x, y, intensity)
		end
	end
	
	-- hook initialize function
	function widget_table:initialize()
		if (widget_table.init == nil) then
			consolePrint(widget_name .. " does not have init() function")
			return
		end
		
		if (widget_table.optionsDisplayOrder ~= nil) then
			local count_display = 0
			local count_options = 0
			for i in pairs(widget_table.optionsDisplayOrder) do
				local key = widget_table.optionsDisplayOrder[i]
				count_display = count_display + 1
				if (widget_table.options[key] == nil) then
					consolePrint(widget_name .. ": invalid optionsDisplayOrder key '" .. key .. "'")
				end
			end
			
			for key in pairs(widget_table.options) do
				count_options = count_options + 1
				
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
		
		-- load widget options automatically
		widget_table:loadOptions()

		widget_table:init()
	end
	
	widget_table.widgetName = widget_name
	
	registerWidget(widget_name)
	table.insert(self.goaWidgets, widget_info)
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
			setWidgetVisibility(widget.name, widget.name ~= "WeaponName")
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
			setWidgetVisibility(widget.name, false)
		end
	end
end

--
-- convar stuff
--

function GoaHud:processConVars()
	if (not self.dirtyConvars) then return end
	
	self.dirtyConvars = false
	for i, k in ipairs(self.convarQueue) do
		widgetCreateConsoleVariable(k[1], k[2], k[3])
		widgetSetConsoleVariable(k[1], k[3])
	end
	self.convarQueue = {}
end

function GoaHud:createConsoleVariable(name, vartype, value)
	table.insert(self.convarQueue, {name, vartype, value})
	self.dirtyConvars = true
end

function GoaHud:setConsoleVariable(name, value)
	if (self.dirtyConvars) then
		-- convar has not been created yet, change initial value instead
		for i, k in ipairs(self.convarQueue) do
			if k[1] == name then
				k[3] = value
				return
			end
		end
	end
	
	consolePerformCommand(string.format("ui_goahud_%s", name) .. " " .. value)
end

function GoaHud:getConsoleVariable(name)
	if (self.dirtyConvars) then
		-- try to read the value from convar queue if it hasn't been created yet
		for i, k in ipairs(self.convarQueue) do
			if k[1] == name then
				return k[3]
			end
		end
	end
	
	return consoleGetVariable(string.format("ui_goahud_%s", name))
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

function applyDefaults(container, varname, vartype, defaults)
	if (defaults == nil) then return end

	local t = type(container[varname])
	
	if (vartype == "table") then
		if (container[varname] == nil) then
			container[varname] = clone(defaults)
		else
			for i, v in pairs(defaults) do
				applyDefaults(container[varname], i, type(defaults[i]), defaults[i])
			end
		end
	elseif (t ~= vartype) then
		container[varname] = defaults
	end
end

function GoaHud_LoadOptions(self)
	assert(self.options ~= nil, self.widgetName .. ": options is not defined")
	
	if (self.defaults == nil and self.options ~= nil) then
		self.defaults = clone(self.options)
		self.defaults.enabled = self.enabled
	end
	
	self.options = loadUserData()
	
	local first_time = self.options == nil

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

function GoaHud_SaveOptions(self, options)
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
	self.options = clone(self.defaults)
	
	if (self.enabled ~= nil) then
		self.enabled = self.options.enabled
		self.options.enabled = nil
	end
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

--
-- utility
--


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
        if type(v) == "table" then
            target[k] = clone(v)
        else
            target[k] = v
        end
    end
    setmetatable(target, meta)
    return target
end
