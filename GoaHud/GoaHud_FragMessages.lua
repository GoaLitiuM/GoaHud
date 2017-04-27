-- GoaHud_FragMessages made by GoaLitiuM
--
-- Customizable frag messages widget
--

require "base/internal/ui/reflexcore"

local FRAG_STYLE_NORMAL = 1
local FRAG_STYLE_Q3 = 2

local FRAG_STYLE_NAMES =
{
	"Normal",
	"Q3 Style",
}

local KILLER_STYLE_YOU = 1
local KILLER_STYLE_NAME_ALWAYS = 2
local KILLER_STYLE_NAME_SPECTATE = 3

local KILLER_STYLE_NAMES =
{
	"\"You\"",
	"Name",
	"Name (Spectate Only)",
}

local player_nobody = { name = "nobody", country = "bot", index = -1}

GoaHud_FragMessages =
{
	offset = { x = 0, y = 316 },
	anchor = { x = 0, y = -1 },
	options =
	{
		showFraggedMessage = true,
		fragStyle = FRAG_STYLE_Q3,
		killerNameStyle = KILLER_STYLE_NAME_SPECTATE,
		fragShowTime = 2.0,
		fragFadeTime = 0.15,

		showCountry = false,

		shadow =
		{
			shadowEnabled = true,
			shadowOffset = 2,
			shadowBlur = 3,
			shadowColor = Color(0,0,0,255),
			shadowStrength = 1,
		},
	},
	optionsDisplayOrder = { "showFraggedMessage", "fragStyle", "killerNameStyle", "fragShowTime", "fragFadeTime", "preview", "showCountry", "", "shadow" },

	fragInfo =
	{
		killer = player_nobody,
		killed = player_nobody,
		time = -99999,
		placement = 1,
		score = 13,
	},
	timer = 0.0,
}
GoaHud:registerWidget("GoaHud_FragMessages")

function GoaHud_FragMessages:init()
	if (self.firstTime and GoaHud_Messages ~= nil and GoaHud_Messages.options ~= nil) then
		-- migrate settings from GoaHud_Messages
		self.options.showFraggedMessage = GoaHud_Messages.options.showFraggedMessage
		self.options.fragStyle = GoaHud_Messages.options.fragStyle
		self.options.killerNameStyle = GoaHud_Messages.options.killerNameStyle
		self.options.fragShowTime = GoaHud_Messages.options.fragShowTime
		self.options.fragFadeTime = GoaHud_Messages.options.fragFadeTime
		self.options.showCountry = GoaHud_Messages.options.showCountry
		self.options.shadow = clone(GoaHud_Messages.options.shadow)

		GoaHud_Messages.options.showFraggedMessage = nil
		GoaHud_Messages.options.fragStyle = nil
		GoaHud_Messages.options.killerNameStyle = nil
		GoaHud_Messages.options.fragShowTime = nil
		GoaHud_Messages.options.fragFadeTime = nil

		self:saveOptions()
		self:loadOptions()
	end
end

local preview_timer = 99.0
function GoaHud_FragMessages:drawPreview(x, y, intensity)
	nvgSave()

	local cycle_time = self.options.fragShowTime + self.options.fragFadeTime + 0.5
	preview_timer = preview_timer + deltaTimeRaw
	if (preview_timer >= cycle_time) then
		local killer_name = player_nobody.name
		local killer_country = player_nobody.country
		local killer_index = player_nobody.index
		local player = getLocalPlayer()
		if (player ~= nil) then
			killer_name = player.name
			killer_country = player.country
			killer_index = player.index
		end

		self.fragInfo =
		{
			killer = { name = killer_name, country = killer_country, index = killer_index },
			killed = { name = "Goa", country = "fi", killer_index + 9999},
			score = math.random(1, 50),
			placement = math.random(1, 4),
			time = self.timer,
		}
		preview_timer = 0.0
	end

	self:drawFragged(x + 280, y + 40, intensity)

	nvgRestore()
	return 60
end

local comboBoxData1 = {}
local comboBoxData2 = {}
function GoaHud_FragMessages:drawOptionsVariable(varname, x, y, optargs)
	if (varname == "fragStyle") then
		GoaLabel("Style: ", x + GOAHUD_INDENTATION, y, optargs)
		self.options.fragStyle = GoaComboBoxIndex(FRAG_STYLE_NAMES, self.options.fragStyle, x + 225, y, 250, comboBoxData1,
			table.merge(optargs, { enabled = self.options.showFraggedMessage }))

		return GOAHUD_SPACING
	elseif (varname == "killerNameStyle") then
		ui2Label("Killer Name: ", x + GOAHUD_INDENTATION, y, optargs)
		self.options.killerNameStyle = GoaComboBoxIndex(KILLER_STYLE_NAMES, self.options.killerNameStyle, x + 225, y, 250, comboBoxData2,
			table.merge(optargs, { enabled = self.options.showFraggedMessage }))

		return GOAHUD_SPACING
	elseif (varname == "fragShowTime") then
		local optargs = clone(optargs)
		optargs.enabled = self.options.showFraggedMessage
		return GoaHud_DrawOptionsVariable(self.options, varname, x + GOAHUD_INDENTATION, y, optargs, "Show Time")
	elseif (varname == "fragFadeTime") then
		local optargs = clone(optargs)
		optargs.milliseconds = true
		optargs.enabled = self.options.showFraggedMessage
		return GoaHud_DrawOptionsVariable(self.options, varname, x + GOAHUD_INDENTATION, y, optargs, "Fade Time")
	elseif (varname == "showCountry") then
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs, "Show Player Country Flag")
	end
	return nil
end

function GoaHud_FragMessages:onLog(entry)
	local player = getPlayer()

	-- fragged message
	if (self.options.showFraggedMessage and entry.type == LOG_TYPE_DEATHMESSAGE and entry.deathKiller == player.name and not entry.deathSuicide) then
		local function sortByScore(a, b)
			return a.score > b.score
		end

		local players_sorted = {}
		for i, p in ipairs(players) do
			if (p.connected) then
				table.insert(players_sorted, p)
			end
		end
		table.sort(players_sorted, sortByScore)

		local placement = -1
		local killed = nil
		for i, p in ipairs(players_sorted) do
			if (p.name == player.name) then
				placement = i
			end
			if (p.name == entry.deathKilled) then killed = p end
		end

		self.fragInfo =
		{
			killer = clone(player),
			killed = clone(killed) or player_nobody,
			score = player.score,
			placement = placement,
			time = self.timer,
		}

	end
end

function GoaHud_FragMessages:draw()
	if (world == nil) then return end
	self.timer = self.timer + deltaTimeRaw

	self:drawFragged(0, 0, 1.0)
end

function GoaHud_FragMessages:drawFragged(x, y, intensity)
	local fragEndTime = self.fragInfo.time + self.options.fragShowTime + self.options.fragFadeTime
	if (self.timer <= fragEndTime) then
		local alpha
		if (self.options.fragFadeTime > 0.0) then
			alpha = math.min(self.options.fragFadeTime, fragEndTime - self.timer) / self.options.fragFadeTime
		else
			alpha = 1.0
		end

		alpha = alpha * intensity

		local title_font_size = 40
		local is_local_killer = true
		local killer = "You"
		local message = "fragged"
		local killed = self.fragInfo.killed.name

		if (self.options.killerNameStyle == KILLER_STYLE_NAME_ALWAYS) then
			killer = self.fragInfo.killer.name
			is_local_killer = false
		elseif (self.options.killerNameStyle == KILLER_STYLE_NAME_SPECTATE) then
			local local_player = getLocalPlayer()
			if (local_player == nil or local_player.index ~= self.fragInfo.killer.index) then
				killer = self.fragInfo.killer.name
				is_local_killer = false
			end
		end

		nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_BASELINE)
		nvgSave()

		GoaHud:drawTextStyle1(title_font_size)
		local frag_width = nvgTextWidthEmoji(string.format("%s %s %s", killer, message, killed), title_font_size)
		local killer_width = nvgTextWidthEmoji(killer .. " ", title_font_size)
		local message_width = nvgTextWidthEmoji(message .. " ", title_font_size)

		nvgRestore()

		local flag_size = title_font_size * 0.5
		local flag_offset = 8

		local flag1_svg = "internal/ui/icons/flags/" .. self.fragInfo.killer.country
		local flag2_svg = "internal/ui/icons/flags/" .. self.fragInfo.killed.country

		local offset_x = -frag_width/2
		if (self.options.showCountry) then
			if (not is_local_killer) then
				offset_x = offset_x - (flag_size + flag_offset/2)*2
			else
				offset_x = offset_x - (flag_size + flag_offset/2)
			end
		end

		if (self.options.showCountry and not is_local_killer and isValidCountry(self.fragInfo.killer.country)) then
			offset_x = offset_x + flag_size

			nvgSave()
			nvgGlobalAlpha(alpha)

			if (self.options.shadow.shadowEnabled) then
				nvgFillColor(Color(0,0,0,255))
				nvgSvg(flag1_svg, offset_x + x + self.options.shadow.shadowOffset, y - flag_size/2 + self.options.shadow.shadowOffset, flag_size, self.options.shadow.shadowBlur * 1.5)
			end

			nvgFillColor(Color(255,255,255,255))
			nvgSvg(flag1_svg, offset_x + x, y - flag_size/2, flag_size)

			nvgRestore()

			offset_x = offset_x + flag_size + flag_offset
		end

		GoaHud:drawText1(offset_x + x, y, title_font_size, Color(255,255,255,alpha * 255), self.options.shadow, killer, true)
		offset_x = offset_x + killer_width

		GoaHud:drawText1(offset_x + x, y, title_font_size, Color(255,255,255,alpha * 255), self.options.shadow, message, true)
		offset_x = offset_x + message_width

		if (self.options.showCountry and isValidCountry(self.fragInfo.killed.country)) then
			offset_x = offset_x + flag_size

			nvgSave()
			nvgGlobalAlpha(alpha)

			if (self.options.shadow.shadowEnabled) then
				nvgFillColor(Color(0,0,0,255))
				nvgSvg(flag2_svg, offset_x + x + self.options.shadow.shadowOffset, y - flag_size/2 + self.options.shadow.shadowOffset, flag_size, self.options.shadow.shadowBlur * 1.5)
			end

			nvgFillColor(Color(255,255,255,255))
			nvgSvg(flag2_svg, offset_x + x, y - flag_size/2, flag_size)

			nvgRestore()

			offset_x = offset_x + flag_size + flag_offset
		end

		GoaHud:drawText1(offset_x + x, y, title_font_size, Color(255,255,255,alpha * 255), self.options.shadow, killed, true)

		nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_BASELINE)
		if (self.options.fragStyle == FRAG_STYLE_Q3) then
			local placement = tostring(self.fragInfo.placement)
			local placement_color = Color(255,255,255,alpha * 255)

			if (self.fragInfo.placement == 1) then placement = placement .. "st"; placement_color = Color(0,0,255,alpha * 255)
			elseif (self.fragInfo.placement == 2) then placement = placement .. "nd"; placement_color = Color(255,0,0,alpha * 255)
			elseif (self.fragInfo.placement == 3) then placement = placement .. "rd"; placement_color = Color(255,255,0,alpha * 255)
			else placement = placement .. "th" end

			local frag_extra_message = string.format(" place with %d", self.fragInfo.score)
			local size = 27
			GoaHud:drawTextStyle1(size)

			local bounds_extra = nvgTextBoundsEmoji(frag_extra_message)
			local bounds_placement = nvgTextBoundsEmoji(placement)

			GoaHud:drawText1(x + bounds_placement.maxx , y + size, size, Color(255,255,255,alpha * 255), self.options.shadow, frag_extra_message)
			GoaHud:drawText1(x - bounds_extra.maxx, y + size, size, placement_color, self.options.shadow, placement)
		end
	end
end