GoaHud_Scores =
{
	canPosition = false,

	left =
	{
		player = nil,
		team = nil,
		follow = false,
		text = "",
		score = 0,
		score_color = Color(0, 0, 0, 0),
		flag = "",
		health = 0,
		health_target = 0,
		armor = 0,
		armor_target = 0,
		health_color = Color(0, 0, 0, 0),
		armor_color = Color(0, 0, 0, 0)
	},
	right =
	{
		player = nil,
		team = nil,
		follow = false,
		text = "",
		score = 0,
		score_color = Color(0, 0, 0, 0),
		flag = "",
		health = 0,
		health_target = 0,
		armor = 0,
		armor_target = 0,
		health_color = Color(0, 0, 0, 0),
		armor_color = Color(0, 0, 0, 0)
	},

	tickTimer = 0.0,

	options =
	{
		enableAnimations = true,
		tickSpeed = 1.0,
		font = { index = 5, face = "" },
		nameFontSize = 32,
		scoreFontSize = 82,

		centerOffset = 170,
		namePlateWidth = 390,
		namePlateHeight = 36,
		healthHeightRatio = 1.0,
		armorHeightRatio = 0.4,

		showFlag = true,

		barBackgroundColor = Color(0,0,0,128),
		healthColorNormal = Color(255,255,255,255),
		healthColorOver = Color(164,164,255,255),
		healthColorMega = Color(64,64,255,255),
		armorColorGreen = Color(0,255,0,255),
		armorColorYellow = Color(255,255,0,255),
		armorColorRed = Color(255,0,0,255),

		movableNamePlates = Movable.new
		{
			name = "NamePlates",
			offset = { x = 0, y = 0 },
			anchor = { x = 0, y = -1 },
		},
		movableScoreCount = Movable.new
		{
			name = "ScoreCount",
			offset = { x = 0, y = 0 },
			anchor = { x = 0, y = -1 },
		},
		movableStats = Movable.new
		{
			name = "Stats",
			offset = { x = 0, y = 0 },
			anchor = { x = 0, y = -1 },
		},

		shadow =
		{
			shadowEnabled = true,
			shadowOffset = 2,
			shadowBlur = 6,
			shadowColor = Color(0,0,0,255),
			shadowStrength = 1.5,
		},
	},
	optionsDisplayOrder =
	{
		"enableAnimations",
		"tickSpeed",
		"",
		"font",
		"nameFontSize",
		"scoreFontSize",
		"",
		"centerOffset",
		"namePlateWidth",
		"namePlateHeight",
		"healthHeightRatio",
		"armorHeightRatio",
		"",
		"showFlag",
		"",
		"barBackgroundColor",
		"healthColorNormal",
		"healthColorOver",
		"healthColorMega",
		"armorColorGreen",
		"armorColorYellow",
		"armorColorRed",
		"",
		"shadow",
		"movableNamePlates", "movableScoreCount", "movableStats",
	},
}
GoaHud:registerWidget("GoaHud_Scores", GOAHUD_UI_EXPERIMENTAL)

function GoaHud_Scores:init()
	self:addMovableElement(self.options.movableNamePlates, self.drawNamePlates)
	self:addMovableElement(self.options.movableScoreCount, self.drawScores)
	self:addMovableElement(self.options.movableStats, self.drawStats)
end

local comboBoxData1 = {}
function GoaHud_Scores:drawOptionsVariable(varname, x, y, optargs)
	if (varname == "tickSpeed") then
		local optargs = clone(optargs)
		optargs.min_value = 0.0
		optargs.max_value = 3.0
		optargs.tick = 100
		optargs.units = "x"
		optargs.enabled = self.options.enableAnimations
		optargs.indent = 1
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs, "Bar Tick Speed")
	elseif (varname == "font") then
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, table.merge(optargs, { font = true }), "Font")
	elseif (varname == "nameFontSize") then
		local optargs = clone(optargs)
		optargs.min_value = 10
		optargs.max_value = 170
		optargs.tick = 1
		optargs.indent = 1
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs, "Name Font Size")
	elseif (varname == "scoreFontSize") then
		local optargs = clone(optargs)
		optargs.min_value = 10
		optargs.max_value = 170
		optargs.tick = 1
		optargs.indent = 1
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs, "Score Font Size")
	elseif (varname == "centerOffset") then
		local optargs = clone(optargs)
		optargs.min_value = 0
		optargs.max_value = 600
		optargs.tick = 1
		optargs.units = "px"
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs, "Center Offset")
	elseif (varname == "namePlateWidth") then
		local optargs = clone(optargs)
		optargs.min_value = 0
		optargs.max_value = 600
		optargs.tick = 1
		optargs.units = "px"
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs, "Width")
	elseif (varname == "namePlateHeight") then
		local optargs = clone(optargs)
		optargs.min_value = 0
		optargs.max_value = 600
		optargs.tick = 1
		optargs.units = "px"
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs, "Height")
	elseif (varname == "healthHeightRatio") then
		local optargs = clone(optargs)
		optargs.min_value = 0.1
		optargs.max_value = 1.0
		optargs.tick = 100
		optargs.units = "x"
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs, "Health Height Ratio")
	elseif (varname == "armorHeightRatio") then
		local optargs = clone(optargs)
		optargs.min_value = 0.1
		optargs.max_value = 1.0
		optargs.tick = 100
		optargs.units = "x"
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs, "Armor Height Ratio")
	elseif (string.find(varname, "movable") ~= nil) then
		return 0
	end
end

function GoaHud_Scores:getHealthColor(health, armor, protection, mega)
	if (health > 100) then
		local fade = math.min(20, health-100) / 20
		local color_target = self.options.healthColorNormal
		local color = self.options.healthColorOver
		if (mega) then
			color = self.options.healthColorMega
		end
		color = Color(
			lerp(color_target.r, color.r, fade),
			lerp(color_target.g, color.g, fade),
			lerp(color_target.b, color.b, fade),
			lerp(color_target.a, color.a, fade))
		return color
	end

	return self.options.healthColorNormal
end

function GoaHud_Scores:getArmorColor(health, armor, protection)
	if (protection == 0) then return self.options.armorColorGreen
	elseif (protection == 1) then return self.options.armorColorYellow
	else return self.options.armorColorRed end
end

local function shouldShowScores()
	local local_player = getLocalPlayer()
	return shouldShowHUD(optargs_deadspec) and not isRaceOrTrainingMode() and (local_player and local_player.state == LOG_CHATTYPE_SPECTATOR)
end

function GoaHud_Scores:drawScores()
	if (not shouldShowScores()) then return end

	nvgSave()
	nvgFontFace(GoaHud:getFont(self.options.font))
	local score_font_size = self.options.scoreFontSize

	local center_offset = self.options.centerOffset
	local text_padding = 10

	local nameplate_width = self.options.namePlateWidth
	local text_max_width = nameplate_width - text_padding*2

	nvgFontSize(score_font_size)

	-- left side
	nvgSave()
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_TOP)

	nvgTranslate(-center_offset+14, -11)

	nvgFillColor(self.left.score_color)
	GoaHud:drawTextWithShadow(0, 0, self.left.score, self.options.shadow)
	nvgRestore()

	-- right side
	nvgSave()
	nvgTextAlign(NVG_ALIGN_RIGHT, NVG_ALIGN_TOP)

	nvgTranslate(center_offset-14, -11)

	nvgFillColor(self.right.score_color)
	GoaHud:drawTextWithShadow(0, 0, self.right.score, self.options.shadow)
	nvgRestore()

	nvgRestore()
end

function GoaHud_Scores:drawNamePlates()
	if (not shouldShowScores()) then return end

	local game_mode = gamemodes[world.gameModeIndex]

	local font_size = self.options.nameFontSize
	local emoji_size = font_size

	nvgSave()

	nvgFontFace(GoaHud:getFont(self.options.font))
	nvgFontSize(font_size)

	local center_offset = self.options.centerOffset
	local text_padding = math.floor(font_size*0.25)
	local text_offset_y = (self.options.namePlateHeight-font_size)/2
	local flag_size = font_size/2
	local flag_offset = flag_size*2 + text_padding

	local nameplate_width = self.options.namePlateWidth
	local text_max_width = nameplate_width - text_padding*2

	local show_flag = self.options.showFlag and not game_mode.hasTeams

	if (not show_flag) then
		flag_offset = 0
	end

	-- bars

	-- background
	nvgFillColor(self.options.barBackgroundColor)

	nvgBeginPath()
	nvgRect(-center_offset-nameplate_width, 0, nameplate_width, self.options.namePlateHeight)
	nvgFill()

	nvgBeginPath()
	nvgRect(center_offset, 0, nameplate_width, self.options.namePlateHeight)
	nvgFill()

	-- left side health/armor

	if (self.left.health > 0) then
		local left_health_width = self.left.health/200.0 * nameplate_width
		nvgBeginPath()
		nvgFillColor(self.left.health_color)
		nvgRect(-center_offset-left_health_width, 0, left_health_width, self.options.namePlateHeight*self.options.healthHeightRatio)
		nvgFill()
	end

	if (self.left.armor > 0) then
		local left_armor_width = self.left.armor/200.0 * nameplate_width
		nvgBeginPath()
		nvgFillColor(self.left.armor_color)
		nvgRect(-center_offset-left_armor_width, self.options.namePlateHeight*(1.0-self.options.armorHeightRatio), left_armor_width, self.options.namePlateHeight*self.options.armorHeightRatio)
		nvgFill()
	end

	-- right side health/armor

	if (self.right.health > 0) then
		local right_health_width = self.right.health/200 * nameplate_width
		nvgBeginPath()
		nvgFillColor(self.right.health_color)
		nvgRect(center_offset, 0, right_health_width, self.options.namePlateHeight*self.options.healthHeightRatio)
		nvgFill()
	end

	if (self.right.armor > 0) then
		local right_armor_width = self.right.armor/200 * nameplate_width
		nvgBeginPath()
		nvgFillColor(self.right.armor_color)
		nvgRect(center_offset, self.options.namePlateHeight*(1.0-self.options.armorHeightRatio), right_armor_width, self.options.namePlateHeight*self.options.armorHeightRatio)
		nvgFill()
	end


	-- names

	nvgFillColor(Color(255,255,255,255))
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_TOP)

	-- left side
	nvgSave()
	local left_bounds = nvgTextBoundsEmoji(self.left.text)
	local left_width = left_bounds.maxx - left_bounds.minx

	if (show_flag) then
		nvgFillColor(Color(255,255,255,255))
		GoaHud:drawSvgWithShadow(self.left.flag, -center_offset-flag_size-text_padding, text_offset_y+flag_size, flag_size, 0, self.options.shadow, { emoji_size = emoji_size })
	end

	if (left_width > text_max_width) then
		nvgTranslate(-center_offset-text_padding-flag_offset - text_max_width, 0)
		nvgScale(text_max_width / left_width, 1.0)
	else
		nvgTranslate(-center_offset-text_padding-flag_offset - left_width, text_offset_y)
	end

	GoaHud:drawTextWithShadow(0, 0, self.left.text, self.options.shadow, { emoji_size = emoji_size })

	nvgRestore()


	-- right side
	nvgSave()

	local right_bounds = nvgTextBoundsEmoji(self.right.text)
	local right_width = right_bounds.maxx - right_bounds.minx

	if (show_flag) then
		nvgFillColor(Color(255,255,255,255))
		GoaHud:drawSvgWithShadow(self.right.flag, center_offset+flag_size+text_padding, text_offset_y+flag_size, flag_size, 0, self.options.shadow, { emoji_size = emoji_size })
	end

	nvgTranslate(center_offset+text_padding+flag_offset, text_offset_y)
	if (right_width > text_max_width) then
		nvgScale(text_max_width / right_width, 1.0)
	end

	GoaHud:drawTextWithShadow(0, 0, self.right.text, self.options.shadow, { emoji_size = emoji_size })
	nvgRestore()

	nvgRestore()
end

function GoaHud_Scores:drawStats()
	if (not shouldShowScores()) then return end
end

function GoaHud_Scores:draw()
	if (world == nil) then return end
	if (replayName == "menu") then return end
	local game_mode = gamemodes[world.gameModeIndex]

	local left_player = getPlayer()
	local right_player
	local left_team_index = 1
	local left_team --= world.teams[left_team_index]
	local right_team
	local left_text = ""
	local right_text = ""
	local left_flag_svg = "internal/ui/icons/flags/"
	local right_flag_svg = "internal/ui/icons/flags/"
	local left_health = 0
	local right_health = 0
	local left_armor = 0
	local right_armor = 0
	local left_health_color = Color(0,0,0,0)
	local right_health_color = Color(0,0,0,0)
	local left_armor_color = Color(0,0,0,0)
	local right_armor_color = Color(0,0,0,0)
	local local_player = getLocalPlayer()
	local left_score = 0
	local right_score = 0
	local left_score_color = Color(255,255,255,255)
	local right_score_color = Color(255,255,255,255)

	-- prevent swapping the player sides during the game, force local player on left side
	if (playerIndexLocalPlayer == playerIndexCameraAttachedTo and local_player and local_player.state == PLAYER_STATE_INGAME) then
		left_team_index = local_player.team
	elseif (local_player and local_player.state == LOG_CHATTYPE_SPECTATOR) then
		left_player = nil
		left_team_index = 1
	end

	if (game_mode.hasTeams) then
		if (not left_player) then left_team_index = 1 end
		left_team = world.teams[left_team_index]

		left_score_color = teamColors[left_team_index]
		for i, t in pairs(world.teams) do
			if (i ~= left_team_index) then
				right_team = t
				right_score_color = teamColors[i]
			end
		end
		left_score = left_team.score
		right_score = right_team.score
	else
		if (left_player == nil) then
			for i=1,32,1 do
				if (players[i] ~= nil and players[i].connected and players[i].state == PLAYER_STATE_INGAME) then
					left_player = players[i]
					break
				end
			end
		end

		for i, p in pairs(players) do
			if (p.connected and p.state == PLAYER_STATE_INGAME) then
				if (left_player and p.index ~= left_player.index) then
					right_score = p.score
					right_player = p
				end
			end
		end
	end

	if (game_mode.hasTeams) then
		left_text = left_team.name
		right_text = right_team.name
	else
		if (left_player) then
			left_text = left_player.name
			left_score = left_player.score
			left_flag_svg = "internal/ui/icons/flags/" .. left_player.country
			left_health = left_player.health
			left_armor = left_player.armor
			left_health_color = GoaHud_Scores:getHealthColor(left_health, left_armor, left_player.armorProtection, left_player.hasMega)
			left_armor_color = GoaHud_Scores:getArmorColor(left_health, left_armor, left_player.armorProtection)
		end
		if (right_player) then
			right_text = right_player.name
			right_score = right_player.score
			right_flag_svg = "internal/ui/icons/flags/" .. right_player.country
			right_health = right_player.health
			right_armor = right_player.armor
			right_health_color = GoaHud_Scores:getHealthColor(right_health, right_armor, right_player.armorProtection, right_player.hasMega)
			right_armor_color = GoaHud_Scores:getArmorColor(right_health, right_armor, right_player.armorProtection)
		end
	end

	if (left_health <= 0) then left_armor = 0; left_health = 0 end
	if (right_health <= 0) then right_armor = 0; right_health = 0 end

	self.left.player = left_player
	self.left.team = left_team
	self.left.follow = left_player and playerIndexCameraAttachedTo == left_player.index
	self.left.text = left_text
	self.left.score = left_score
	self.left.score_color = left_score_color
	self.left.flag = left_flag_svg
	self.left.health_target = left_health
	self.left.armor_target = left_armor
	self.left.health_color = left_health_color
	self.left.armor_color = left_armor_color

	self.right.player = right_player
	self.right.team = right_team
	self.right.follow = right_player and playerIndexCameraAttachedTo == right_player.index
	self.right.text = right_text
	self.right.score = right_score
	self.right.score_color = right_score_color
	self.right.flag = right_flag_svg
	self.right.health_target = right_health
	self.right.armor_target = right_armor
	self.right.health_color = right_health_color
	self.right.armor_color = right_armor_color

	if (self.options.enableAnimations and self.options.tickSpeed > 0) then
		local function tickValue(current, target, delta)
			if (math.floor(current) == target) then return target end

			local step = 100*delta

			-- catch up faster if difference is too large
			if (math.abs(target - current) >= 15) then step = step * 10 end

			if (target > current) then
				current = current + step
				if (current > target) then current = target end
			elseif (target < current) then
				current = current - step
				if (current < target) then current = target end
			end

			if (current < 0) then current = 0 end
			return current
		end

		local delta = deltaTime*self.options.tickSpeed
		self.left.health = tickValue(self.left.health, left_health, delta)
		self.left.armor = tickValue(self.left.armor, left_armor, delta)
		self.right.health = tickValue(self.right.health, right_health, delta)
		self.right.armor = tickValue(self.right.armor, right_armor, delta)
	else
		self.left.health = left_health
		self.left.armor = left_armor
		self.right.health = right_health
		self.right.armor = right_armor
	end
end