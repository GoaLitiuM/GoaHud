-- GoaHud_Chat made by GoaLitiuM
--
-- Replacement for ChatLog, supports emojis and colored text when available
--

require "base/internal/ui/reflexcore"

CARET_TYPE_VERTICAL = 1
CARET_TYPE_UNDERSCORE = 2

CARET_TYPE_NAMES =
{
	"Vertical",
	"Underscore",
}

CHAT_BEEP_ALWAYS = 1
CHAT_BEEP_DISABLED_MATCH = 2
CHAT_BEEP_DISABLED = 3

CHAT_BEEP_NAMES =
{
	"Always",
	"Disabled During Match",
	"Disabled",
}

GoaHud_Chat =
{
	offset = { x = 10, y = -180 },
	anchor = { x = -1, y = 1 },

	options =
	{
		font = 1,
		fontSize = 25,

		width = 675,
		lineCount = 8,
		lineCountActive = 16,
		backgroundAlpha = 96,

		messageTime = 15.0,
		messageFadeTime = 2.5,

		enableEmojis = true,
		enableColors = true,

		--showChannelText = true,
		useTimestamps = true,
		showSeconds = true,
		utcOffset = 3,

		chatBeepSay = CHAT_BEEP_ALWAYS,
		chatBeepTeam = CHAT_BEEP_ALWAYS,
		chatBeepSpec = CHAT_BEEP_ALWAYS,
		chatBeepParty = CHAT_BEEP_ALWAYS,

		caretType = CARET_TYPE_VERTICAL,
		caretBlinking = true,

		shortenLongNames = false,

		showReadyPlayers = true,

		colorTeam = Color(32, 32, 196, 255),
		colorSpectator = Color(196, 196, 32, 255),
		colorParty = Color(32, 196, 32, 255),

		shadow =
		{
			shadowEnabled = true,
			shadowOffset = 0,
			shadowBlur = 3,
			shadowColor = Color(0,0,0,255),
			shadowStrength = 1.8,
		},
	},

	optionsDisplayOrder =
	{
		"preview",
		"font", "fontSize", "width", "lineCount", "lineCountActive", "backgroundAlpha",
		"",
		"messageTime", "messageFadeTime",
		"",
		"enableEmojis", "enableColors",
		"",
		"useTimestamps", "showSeconds", "utcOffset",
		"",
		"chatBeepSay", "chatBeepTeam", "chatBeepSpec", "chatBeepParty",
		"",
		"caretType", "caretBlinking",
		"",
		"shortenLongNames",
		"",
		"showReadyPlayers",
		"",
		"colorTeam", "colorSpectator", "colorParty",
		"shadow",
	},

	shortenNameLength = 17,

	caretTimer = 0.0,
	caretBlinkTime = 0.25,

	textColor = Color(255, 255, 255, 255),

	messages = {},
	messagesPreview = {},
	messagePosition = 0,
}
GoaHud:registerWidget("GoaHud_Chat")

local consolePrint_real
local last_chat_debug = 0
local function hookConsolePrint()
	local consolePrintHook = function(text, hide)
		consolePrint_real(text)
		if (hide ~= true) then GoaHud_Chat:onDebug(text) end
	end

	consolePrint = consolePrintHook
	GoaHud_Chat:onDebug("consolePrint hooked")
end

local function unhookConsolePrint()
	consolePrint = consolePrint_real
end

function GoaHud_Chat:init()
	consolePrint_real = consolePrint
	widgetCreateConsoleVariable("debug", "int", 0)

	local chat_debug = widgetGetConsoleVariable("debug")
	if (chat_debug ~= last_chat_debug) then
		if (chat_debug ~= 0) then hookConsolePrint()
		else unhookConsolePrint() end
		last_chat_debug = chat_debug
	end

	for i=1, 25 do
		table.insert(self.messagesPreview, { timestamp = 0, source = "Player1", content = "gg" })
		table.insert(self.messagesPreview, { timestamp = 0, source = "Player2", content = "gg" })
	end
end

local comboBoxData1 = {}
local comboBoxData2 = {}
local comboBoxData3 = {}
local comboBoxData4 = {}
local comboBoxData5 = {}
local comboBoxData6 = {}
function GoaHud_Chat:drawOptionsVariable(varname, x, y, optargs)
	if (varname == "preview") then
		return self:drawPreview(x, y, 1.0)
	elseif (varname == "font") then
		GoaLabel("Font: ", x, y, optargs)
		self.options.font = GoaComboBoxIndex(GOAHUD_FONTS_NAMES, self.options.font, x + 225, y, 250, comboBoxData1, optargs)

		return GOAHUD_SPACING
	elseif (varname == "fontSize") then
		local optargs = clone(optargs)
		optargs.min_value = 10
		optargs.max_value = 170
		optargs.tick = 1
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs, "Font Size")
	elseif (varname == "width") then
		local optargs = clone(optargs)
		optargs.min_value = 175
		optargs.max_value = 1920
		optargs.tick = 1
		optargs.units = "px"

		y = y + GOAHUD_SPACING
		GoaLabel("Line: ", x, y, optargs)
		y = y + GOAHUD_SPACING

		return 2*GOAHUD_SPACING + GoaHud_DrawOptionsVariable(self.options, varname, x + GOAHUD_INDENTATION, y, optargs, "Width")
	elseif (varname == "lineCount") then
		local optargs = clone(optargs)
		optargs.min_value = 1
		optargs.max_value = 100
		optargs.tick = 1
		optargs.units = "lines"
		return GoaHud_DrawOptionsVariable(self.options, varname, x + GOAHUD_INDENTATION, y, optargs, "Height")
	elseif (varname == "lineCountActive") then
		local optargs = clone(optargs)
		optargs.min_value = 1
		optargs.max_value = 100
		optargs.tick = 1
		optargs.units = "lines"
		return GoaHud_DrawOptionsVariable(self.options, varname, x + GOAHUD_INDENTATION, y, optargs, "Height (Active)")
	elseif (varname == "backgroundAlpha") then
		local optargs = clone(optargs)
		optargs.min_value = 0
		optargs.max_value = 255
		optargs.tick = 1
		return GoaHud_DrawOptionsVariable(self.options, varname, x + GOAHUD_INDENTATION, y, optargs, "Transparency")
	elseif (varname == "messageTime") then
		local optargs = clone(optargs)
		optargs.min_value = 1
		optargs.max_value = 60
		optargs.tick = 1
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs)
	elseif (varname == "messageFadeTime") then
		local optargs = clone(optargs)
		optargs.min_value = 0
		optargs.max_value = 10
		optargs.tick = 10
		optargs.seconds = true
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs, "Message Fade")
	elseif (varname == "useTimestamps") then
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs, "Show Timestamps")
	elseif (varname == "showSeconds") then
		local optargs = clone(optargs)
		optargs.enabled = self.options.useTimestamps
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs)
	elseif (varname == "utcOffset") then
		local optargs = clone(optargs)
		optargs.enabled = self.options.useTimestamps
		optargs.values = UTC_OFFSETS
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs, "UTC Offset")
	elseif (varname == "chatBeepSay") then
		GoaLabel("Chat Beep (say): ", x, y, optargs)
		self.options.chatBeepSay = GoaComboBoxIndex(CHAT_BEEP_NAMES, self.options.chatBeepSay, x + 225, y, 250, comboBoxData2, optargs)

		return GOAHUD_SPACING
	elseif (varname == "chatBeepTeam") then
		GoaLabel("Chat Beep (team): ", x, y, optargs)
		self.options.chatBeepTeam = GoaComboBoxIndex(CHAT_BEEP_NAMES, self.options.chatBeepTeam, x + 225, y, 250, comboBoxData3, optargs)

		return GOAHUD_SPACING
	elseif (varname == "chatBeepSpec") then
		GoaLabel("Chat Beep (spec): ", x, y, optargs)
		self.options.chatBeepSpec = GoaComboBoxIndex(CHAT_BEEP_NAMES, self.options.chatBeepSpec, x + 225, y, 250, comboBoxData4, optargs)

		return GOAHUD_SPACING
	elseif (varname == "chatBeepParty") then
		GoaLabel("Chat Beep (party): ", x, y, optargs)
		self.options.chatBeepParty = GoaComboBoxIndex(CHAT_BEEP_NAMES, self.options.chatBeepParty, x + 225, y, 250, comboBoxData5, optargs)

		return GOAHUD_SPACING
	elseif (varname == "caretType") then
		GoaLabel("Caret Type: ", x, y, optargs)
		self.options.caretType = GoaComboBoxIndex(CARET_TYPE_NAMES, self.options.caretType, x + 225, y, 250, comboBoxData6, optargs)

		return GOAHUD_SPACING
	end
	return nil
end

function GoaHud_Chat:onError(widget, err)
	local msg =
	{
		timestamp = epochTimeMs,
		timestampHide = epochTimeMs + self.options.messageTime,

		source = "LUA ERROR",
		content = string.format("%s: %s", widget, err),
		colorBackground = Color(255, 0, 0, math.min((self.options.backgroundAlpha/255)*2, 1.0)*255),
	}
	self:newMessage(msg)
end

local debugLastMsg = {}
function GoaHud_Chat:onDebug(text)
	if (text == nil or string.len(text) == 0) then return end

	if (text == debugLastMsg.content) then
		debugLastMsg.debugRepeat = debugLastMsg.debugRepeat + 1
		debugLastMsg.timestamp = epochTimeMs
		return
	end

	local msg =
	{
		timestamp = epochTimeMs,
		source = "DEBUG",
		content = text,

		bold = true,
		colorBackground = Color(255, 255, 0, math.min((self.options.backgroundAlpha/255), 1.0)*255),

		debugRepeat = 1,
	}
	self:newMessage(msg)
	debugLastMsg = msg
end

function GoaHud_Chat:onLog(entry)
	local msg = nil
	local timestamp_real = epochTimeMs - entry.age
	if (entry.type == LOG_TYPE_CHATMESSAGE) then
		local color = Color(0, 0, 0, 255)
		local prefix = ""
		local source = entry.chatPlayer

		if (entry.chatType == LOG_CHATTYPE_TEAM) then
			color = clone(self.options.colorTeam)
		elseif (entry.chatType == LOG_CHATTYPE_SPECTATOR) then
			color = clone(self.options.colorSpectator)
		elseif (entry.chatType == LOG_CHATTYPE_PARTY) then
			color = clone(self.options.colorParty)
		end

		color.a = math.min(color.a * (self.options.backgroundAlpha/255), 255)

		--if (self.options.showChannelText) then
			if (entry.chatType == LOG_CHATTYPE_TEAM) then prefix = "(team) "
			elseif (entry.chatType == LOG_CHATTYPE_SPECTATOR) then prefix = "(spec) "
			elseif (entry.chatType == LOG_CHATTYPE_PARTY) then prefix = "(party) " end
		--end

		local game_active = world.timerActive and world.gameState == GAME_STATE_ACTIVE and getLocalPlayer().state == PLAYER_STATE_INGAME
		local should_beep = false
		if (entry.chatType == LOG_CHATTYPE_NORMAL) then
			should_beep = self.options.chatBeepSay == CHAT_BEEP_ALWAYS or (not game_active and self.options.chatBeepSay == CHAT_BEEP_DISABLED_MATCH)
		end
		if (entry.chatType == LOG_CHATTYPE_TEAM) then
			should_beep = self.options.chatBeepTeam == CHAT_BEEP_ALWAYS or (not game_active and self.options.chatBeepTeam == CHAT_BEEP_DISABLED_MATCH)
		end
		if (entry.chatType == LOG_CHATTYPE_SPECTATOR) then
			should_beep = self.options.chatBeepSpec == CHAT_BEEP_ALWAYS or (not game_active and self.options.chatBeepSpec == CHAT_BEEP_DISABLED_MATCH)
		end
		if (entry.chatType == LOG_CHATTYPE_PARTY) then
			should_beep = self.options.chatBeepParty == CHAT_BEEP_ALWAYS or (not game_active and self.options.chatBeepParty == CHAT_BEEP_DISABLED_MATCH)
		end

		if (should_beep) then
			if (entry.age < 1.0) then
				playSound("internal/misc/chat")
			end
		end

		msg =
		{
			source = prefix .. source,
			content = clone(entry.chatMessage),
			chatType = entry.chatType,

			colorBackground = color,
		}
	elseif (entry.type == LOG_TYPE_NOTIFICATION) then
		local color_background = Color(64, 64, 16, 255)
		color_background.a = math.min(color_background.a * (self.options.backgroundAlpha/255), 255)

		local color = self.textColor

		-- reformat notification messages to prevent color codes leaking from player names
		local content = entry.notification
		local joined_player, joined_content = string.match(entry.notification, '^(.*) (has joined the game)')
		local spectating_player, spectating_content = string.match(entry.notification, '^(.*) (is now spectating)')
		local disconnected_player, disconnected_content = string.match(entry.notification, '^(.*) (has disconnected)')
		local editor_player, editor_content = string.match(entry.notification, '^(.*) (has become an editor)')
		local referee_player, referee_content = string.match(entry.notification, '^(.*) (is now a referee)')
		local unreferee_player, unreferee_content = string.match(entry.notification, '^(.*) (is no longer a referee)')
		local renamed_player_old, renamed_content, renamed_player_new = string.match(entry.notification, '^player (.*) (renamed to) (.*)')

		if (joined_player and joined_content) then
			content = string.format("^[%s^] %s", joined_player, joined_content)
			color = Color(200, 200, 48, 255)
		elseif (spectating_player and spectating_content) then
			content = string.format("^[%s^] %s", spectating_player, spectating_content)
			color = Color(200, 200, 48, 255)
		elseif (disconnected_player and disconnected_content) then
			content = string.format("^[%s^] %s", disconnected_player, disconnected_content)
			color = Color(200, 200, 48, 255)
		elseif (editor_player and editor_content) then
			content = string.format("^[%s^] %s", editor_player, editor_content)
			color = Color(200, 200, 48, 255)
		elseif (referee_player and referee_content) then
			content = string.format("^[%s^] %s", referee_player, referee_content)
			color = Color(200, 200, 48, 255)
		elseif (unreferee_player and unreferee_content) then
			content = string.format("^[%s^] %s", unreferee_player, unreferee_content)
			color = Color(200, 200, 48, 255)
		elseif (renamed_player_old and renamed_content and renamed_player_new) then
			content = string.format("player ^[%s^] %s ^[%s^]", renamed_player_old, renamed_content, renamed_player_new)
			color = Color(200, 200, 48, 255)
		end

		msg =
		{
			content = content,
			bold = true,

			color = color,
			colorBackground = color_background,
		}

		-- hide join messages triggered by menu replay
		if (replayName == "menu") then msg = nil end
	elseif (entry.type == LOG_TYPE_DROP or entry.type == LOG_TYPE_RECEIVED) then
		local player_name = entry.dropPlayerName
		if (entry.type == LOG_TYPE_RECEIVED) then player_name = entry.receivedPlayerName end

		if (entry.type == LOG_TYPE_DROP and getLocalPlayer().name == player_name) then
			playSound("internal/ui/sounds/notifyDrop")
		end

		local color = Color(128, 255, 128, 255)
		local color_background = Color(16, 64, 16, 255)
		color_background.a = math.min(color_background.a * (self.options.backgroundAlpha/255), 255)

		local def_id = entry.dropItemDefId
		local quantity = 1
		if (entry.type == LOG_TYPE_RECEIVED) then
			def_id = entry.receivedItemDefId
			quantity = entry.receivedItemQuantity
		end

		local item = "item" .. def_id
		local def = inventoryDefinitions[def_id]
		if (def ~= nil) then item = def.name end

		local content
		if (quantity > 1) then
			content = string.format("^[%s^] received items: %dx %s!", player_name, quantity, item)
		else
			content = string.format("^[%s^] received item: %s!", player_name, item)
		end

		msg =
		{
			content = content,
			bold = true,

			color = color,
			colorBackground = color_background,
		}
	elseif (entry.type == LOG_TYPE_RACEEVENT) then
		if (entry.raceEvent == RACE_EVENT_FINISH or entry.raceEvent == RACE_EVENT_FINISHANDWASRECORD) then
			local color = Color(255, 255, 96, 255)
			local color_background = Color(0, 64, 64, 255)
			if (entry.raceEvent == RACE_EVENT_FINISHANDWASRECORD) then
				color = Color(96, 255, 96, 255)
			end

			color_background.a = math.min(color_background.a * (self.options.backgroundAlpha/255), 255)

			msg =
			{
				content = string.format("^[%s^] finished race in %s", entry.raceName, FormatTimeToDecimalTime(entry.raceTime)),
				bold = true,

				color = color,
				colorBackground = color_background,
			}
		end
	end

	if (msg ~= nil) then
		msg.timestamp = timestamp_real
		msg.timestampHide = timestamp_real + self.options.messageTime

		self:newMessage(msg)
	end
end

function GoaHud_Chat:newMessage(msg)
	table.insert(self.messages, 1, msg)
	debugLastMsg = {}

	-- keep the currently scrolled message position
	if (self.messagePosition ~= 1) then self.messagePosition = self.messagePosition + 1 end
end

function GoaHud_Chat:getFont(bold, italics)
	local font = GOAHUD_FONTS[self.options.font]
	local face
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
	return face
end

-- modified version of pullWord but also pulls valid emojis
function pullWordEmojis(text)
	local space = string.find(text, "%s");
	if space == nil then
		-- look for emojis
		local match_start, match_end = string.find(string.lower(text), ':([-+%w_]+):')
		if (match_start == nil) then
			return text, "";
		end

		if (isEmoji(string.sub(text, match_start+1, match_end-1))) then
			return string.sub(text, 0, match_end), string.sub(text, match_end+1)
		else
			return text, "";
		end
	else
		return string.sub(text, 0, space-1), string.sub(text, space+1);
	end
end

-- modified version of reflexcore SplitTextToMultipleLines to use nvgTextWidthEmoji
function SplitTextToMultipleLinesEmojis(text, w, optargs)
	local lines = {};
	local lineCount = 0;
	local newLine = "";

	while string.len(text) > 0 do
		local newWord
		local nextLine = ""
		newWord, text = pullWordEmojis(text);

		-- spit out new line
		if nvgTextWidthEmoji(newLine .. " " .. newWord, optargs) > w then
			lineCount = lineCount + 1;

			--if (optargs and optargs.specialColorCodes) then
				local _m, start_count = string.gsub(newLine, "%^%[", "")
				local _m, end_count = string.gsub(newLine, "%^%]", "")

				if (start_count > end_count) then
					local diff = start_count - end_count
					for i=1, diff do
						newLine = newLine .. "^]"
						nextLine = nextLine .. "^["
					end
				end
			--end

			lines[lineCount] = newLine;
			newLine = nextLine;
		end

		-- append new word
		if string.len(newLine) > 0 then
			newLine = newLine .. " " .. newWord;
		else
			newLine = newWord;
		end
	end

	-- if there's left-overs, it goes on new line
	if string.len(newLine) > 0 then
		lineCount = lineCount + 1;
		lines[lineCount] = newLine;
	end

	return lines, lineCount;
end

function GoaHud_Chat:drawPreview(x, y, intensity)
	local linecount = 3
	local lineheight = self.options.fontSize*linecount
	nvgSave()

	nvgSave()
	local width = 550
	local height = lineheight + 11
	nvgBeginPath()
	nvgFillLinearGradient(x, y, x + width, y + height, Color(0,0,0,0), Color(255,255,255,255))
	nvgRect(x, y, width, height)
	nvgFill()
	nvgRestore()

	local say = {}
	say.text = "gg"
	say.hover = true
	say.cursor = #say.text
	say.cursorStart = say.cursor

	nvgTranslate(x + 10, y + lineheight)
	self:drawCurrentLine(say)
	self:drawMessages(say, self.messagesPreview, 0, linecount-1)

	nvgRestore()

	return height + 10
end

local readyPlayers = {}
function GoaHud_Chat:handleEvents()
	if (self.options.showReadyPlayers) then
		local ready_players = {}

		-- detect ready players
		for i, p in pairs(players) do
			if (p.connected and p.state == PLAYER_STATE_INGAME) then
				table.insert(ready_players, { index = p.index, name = p.name, ready = p.ready })
			end
		end

		for i, p in pairs(ready_players) do
			for j, r in pairs(readyPlayers) do
				if (r.index == p.index) then
					if (p.ready ~= r.ready) then
						local color_background = Color(64, 64, 16, 255)
						color_background.a = math.min(color_background.a * (self.options.backgroundAlpha/255), 255)
						local ready_text = "ready"
						if (not p.ready) then ready_text = "no longer ready" end

						msg =
						{
							content = string.format("^[%s^] is %s", p.name, ready_text),
							bold = true,

							color = Color(255, 255, 255, 255),
							colorBackground = color_background,
						}

						msg.timestamp = epochTimeMs
						msg.timestampHide = epochTimeMs + self.options.messageTime

						self:newMessage(msg)
					end
				end
			end
		end

		readyPlayers = ready_players
	end
end

function GoaHud_Chat:draw()
	local chat_debug = widgetGetConsoleVariable("debug")
	if (chat_debug ~= last_chat_debug) then
		if (chat_debug ~= 0) then hookConsolePrint()
		else unhookConsolePrint() end
		last_chat_debug = chat_debug
	end

	if (not GoaHud.previewMode) then
		if (replayName == "menu" or getLocalPlayer() == nil or isInMenu()) then return end
	end

	self:handleEvents()

	local say = sayRegion()
	local messages = self.messages

	-- mock preview
	if (GoaHud.previewMode) then
		say.text = "> gg"
		say.hover = true
		messages = self.messagesPreview
	end

	-- chat scrolling
	if (say.hover ~= last_hover) then
		if (say.hover) then
			if (say.mouseWheel > 0) then
				self.messagePosition = self.messagePosition + 1
			elseif (say.mouseWheel < 0) then
				self.messagePosition = self.messagePosition - 1
			end

			local messagecount = 0
			for i in ipairs(messages) do
				messagecount = messagecount + 1
			end

			local linecount
			if (say.hover) then
				linecount = self.options.lineCountActive
			else
				linecount = self.options.lineCount
			end

			self.messagePosition = math.min(self.messagePosition, messagecount-linecount+1)
			self.messagePosition = math.max(self.messagePosition, 1)
			--consolePerformCommand("m_enabled 1")
		else
			self.messagePosition = 0
			--consolePerformCommand("m_enabled 0")
		end
	end

	self:drawCurrentLine(say)
	self:drawMessages(say, messages, self.messagePosition)
end

local last_cursor = -1
function GoaHud_Chat:drawCurrentLine(say)
	nvgFontFace(self:getFont())
	nvgFontSize(self.options.fontSize)
	nvgFillColor(self.textColor)

	local padding = round(self.options.fontSize * 0.14)
	local say_background = Color(0, 0, 0, 255)
	local say_prefix = ""
	local say_line = ""

	if (say.hover) then
		if (say.sayTeam) then
			say_background = clone(self.options.colorTeam)
		elseif (say.saySpec) then
			say_background = clone(self.options.colorSpectator)
		elseif (say.sayParty) then
			say_background = clone(self.options.colorParty)
		else
			say_background = Color(0, 0, 0, 255)
		end

		--if (self.options.showChannelText) then
			if (say.sayTeam) then say_prefix = "team "
			elseif (say.saySpec) then say_prefix = "spec "
			elseif (say.sayParty) then say_prefix = "party " end
		--end
		say_prefix = say_prefix .. "> "
		say_line = say_prefix .. say.text
	end
	say_background.a = math.min(say_background.a * (self.options.backgroundAlpha/255), 255)

	-- background
	local say_bounds
	if (say.hover) then
		nvgSave()
		nvgBeginPath()
		nvgFillColor(say_background)

		say_bounds = nvgTextBounds(say_line)
		nvgRect(-padding, round(say_bounds.miny), self.options.width + padding*2, round(say_bounds.maxy - say_bounds.miny))

		nvgFill()
		nvgRestore()
	end

	-- display current line
	local optargs_emoji_preview = {}
	if (self.options.enableColors) then optargs_emoji_preview.previewColorCodes = true
	else optargs_emoji_preview.ignoreColorCodes = true end

	GoaHud:drawTextWithShadow(0, 0, say_line, self.options.shadow, optargs_emoji_preview)

	-- caret
	if (say.hover) then
		local caret_alpha = 196

		-- reset blinking after cursor moved
		if (last_cursor ~= say.cursor) then self.caretTimer = self.caretBlinkTime; last_cursor = say.cursor end

		-- caret blinking
		if (self.options.caretBlinking) then
			if (self.caretTimer >= 0) then
				self.caretTimer = self.caretTimer - deltaTimeRaw
				if (self.caretTimer <= 0.0) then self.caretTimer = -self.caretBlinkTime end
			elseif (self.caretTimer < 0) then
				caret_alpha = 0
				self.caretTimer = self.caretTimer + deltaTimeRaw
				if (self.caretTimer >= 0.0) then self.caretTimer = self.caretBlinkTime end
			end
		end

		local prefix_width = nvgTextWidthEmoji(say_prefix, optargs_emoji_preview)
		local caret_x = prefix_width + nvgTextWidthEmoji(string.sub(say.text, 0, say.cursor), optargs_emoji_preview)

		if (self.options.caretType == CARET_TYPE_VERTICAL) then
			local letter_width = 2
			if (say.cursor == #say.text) then letter_width = 3 end

			nvgSave()
			nvgBeginPath()
			nvgFillColor(Color(255,255,255,caret_alpha))

			nvgRect(caret_x, round(say_bounds.miny) + 2, letter_width, round(say_bounds.maxy - say_bounds.miny) - 4)

			nvgFill()
			nvgRestore()
		elseif (self.options.caretType == CARET_TYPE_UNDERSCORE) then
			local letter_width = nvgTextWidthEmoji(string.sub(say.text, say.cursor+1, say.cursor+1), optargs_emoji_preview)
			if (say.cursor == #say.text) then
				letter_width = nvgTextWidthEmoji("_", optargs_emoji_preview)
			end

			nvgSave()
			nvgBeginPath()
			nvgFillColor(Color(255,255,255,caret_alpha))

			nvgRect(caret_x, round(say_bounds.maxy) - 4, letter_width, 4)

			nvgFill()
			nvgRestore()
		end

		-- cursor selection
		if (say.cursor ~= say.cursorStart) then
			local selection_start_x = nvgTextWidthEmoji(string.sub(say.text, 0, say.cursorStart), optargs_emoji_preview)
			local letter_width = nvgTextWidthEmoji(string.sub(say.text, 0, say.cursor), optargs_emoji_preview)

			nvgSave()
			nvgBeginPath()
			nvgFillColor(Color(255,255,255,128))

			nvgRect(prefix_width + selection_start_x, round(say_bounds.miny), letter_width - selection_start_x, round(say_bounds.maxy - say_bounds.miny))

			nvgFill()
			nvgRestore()
		end
	end
end

function GoaHud_Chat:drawMessages(say, messages, messagepos, linecount)
	local line_height = self.options.fontSize
	local emoji_size = self.options.fontSize*0.9
	local line_y = 0

	local linecount = linecount
	if (say.hover) then
		linecount = linecount or self.options.lineCountActive
	else
		linecount = linecount or self.options.lineCount
	end

	local height = (linecount+1) * line_height
	local padding = round(self.options.fontSize * 0.14)

	local optargs_emoji = {}
	if (self.options.enableEmojis) then optargs_emoji.emojiSize = emoji_size end
	if (self.options.enableColors) then
		optargs_emoji.specialColorCodes = true
	else
		optargs_emoji.ignoreColorCodes = true
	end

	nvgFontFace(self:getFont())
	nvgFontSize(self.options.fontSize)
	nvgFillColor(self.textColor)

	for i, m in ipairs(messages) do
		if (line_y <= -height) then break end

		if (i >= messagepos) then
			local age = epochTimeMs - m.timestamp

			-- always show messages while typing
			if (say.hover) then age = 0.0 end

			if (line_y > -height and age < self.options.messageTime + self.options.messageFadeTime) then
				nvgSave()

				-- fade out alpha
				if (age >= self.options.messageTime) then
					local alpha = 1.0 - ((age - self.options.messageTime) / self.options.messageFadeTime)
					nvgGlobalAlpha(EaseOut(alpha))
				end

				local line_y_start = line_y
				local content = m.content
				local content_offset = 0
				local prefix
				local bold = m.bold or false
				local italic = m.italic or false
				local timestamp, timestamp_max

				nvgFontFace(self:getFont(bold, italic))
				nvgFillColor(m.color or self.textColor)

				-- repeated count for debug messages
				if (m.debugRepeat ~= nil and m.debugRepeat > 1) then
					content = string.format("[%d] %s", m.debugRepeat, content)
				end

				if (m.source) then
					if (self.options.shortenLongNames and m.source ~= "DEBUG" and string.lenColor(m.source) > self.shortenNameLength) then
						local break_pos
						-- break at last possible word before hitting the length limit
						for index = self.shortenNameLength, 0, -1 do
							break_pos = string.find(m.source, "[ _.-:]", index)
							if (break_pos ~= nil and break_pos <= self.shortenNameLength+1) then break end
						end

						-- fallback to character length
						if (break_pos == nil) then break_pos = self.shortenNameLength+1 end

						prefix = string.sub(m.source, 0, break_pos-1) .. "...: "
					else
						prefix = m.source .. ": "
					end
					content = prefix .. content
					content_offset = content_offset + string.len(prefix)
				end

				if (self.options.useTimestamps) then
					local t = GoaHud:formatTime(m.timestamp + (self.options.utcOffset * 60 * 60))

					local format_str
					if (self.options.showSeconds) then
						format_str = "%02d:%02d:%02d "
					else
						format_str = "%02d:%02d "
					end

					timestamp = string.format(format_str, t.hours_total % 24, t.mins_total % 60, t.secs_total % 60)
					timestamp_max = string.format(format_str, 88, 88, 88)
					content = timestamp_max .. content
					content_offset = content_offset + string.len(timestamp_max)
				end

				local content_lines, line_count = SplitTextToMultipleLinesEmojis(content, self.options.width, optargs_emoji)

				local color_background = m.colorBackground or Color(0, 0, 0, self.options.backgroundAlpha)
				line_y = line_y - (line_height * line_count)

				for j, line in ipairs(content_lines) do
					if (line_y > -height) then
						-- line background
						if (color_background ~= nil) then
							nvgSave()
							nvgBeginPath()
							nvgFillColor(color_background)

							local bounds = nvgTextBoundsEmoji(line, optargs_emoji)
							nvgRect(-padding, line_y + round(bounds.miny), self.options.width + padding*2, round(bounds.maxy - bounds.miny))

							nvgFill()
							nvgRestore()
						end

						local content_offset_x = 0
						if (j == 1) then -- first line
							-- timestamps
							if (timestamp ~= nil) then
								nvgSave()

								nvgFillColor(self.textColor)
								nvgFontFace(self:getFont())

								GoaHud:drawTextWithShadow(0, line_y, timestamp, self.options.shadow, optargs_emoji)
								content_offset_x = content_offset_x + nvgTextWidthEmoji(timestamp_max, optargs_emoji)

								nvgRestore()
							end

							-- source (player name)
							if (prefix ~= nil) then
								nvgSave()

								nvgFillColor(self.textColor)
								nvgFontFace(self:getFont(true))

								GoaHud:drawTextWithShadow(content_offset_x, line_y, prefix, self.options.shadow, optargs_emoji)
								content_offset_x = content_offset_x + nvgTextWidthEmoji(prefix, optargs_emoji)

								nvgRestore()
							end
							line = string.sub(line, content_offset+1)
						end

						-- content
						GoaHud:drawTextWithShadow(content_offset_x, line_y, line, self.options.shadow, optargs_emoji)
					end
					line_y = line_y + line_height
				end

				line_y = line_y_start - (line_height * line_count)
				nvgRestore()
			end
		end
	end
end