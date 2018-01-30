-- GoaHud_WeaponRack made by GoaLitiuM
--
-- Displays ammo for each weapon
--

require "base/internal/ui/reflexcore"

GoaHud_WeaponRack =
{
	offset = { x = 0, y = -20 },
	anchor = { x = 0, y = 1 },

	options =
	{
		hideMelee = true,
		hideBurstGun = true,

		hideInRace = true,
		hideInWarmup = false,

		coloredAmmo = false,
		textColor = Color(255,255,255,255),

		coloredSelection = false,
		selectedColor = Color(255,255,255,128),

		showBackground = true,
		backgroundColor = Color(0, 0, 0, 64),

		shadow =
		{
			shadowEnabled = true,
			shadowOffset = 2,
			shadowBlur = 5,
			shadowColor = Color(0,0,0,255),
			shadowStrength = 1,
		},
	},
	optionsDisplayOrder =
	{
		"hideMelee", "hideBurstGun",
		"",
		"hideInRace", "hideInWarmup",
		"",
		"coloredAmmo", "textColor",
		"coloredSelection", "selectedColor",
		"showBackground", "backgroundColor",
		"",
		"shadow",
	},

	showWeapons = {},
};
GoaHud:registerWidget("GoaHud_WeaponRack");

function GoaHud_WeaponRack:init()
	for i=1, 9 do
		table.insert(self.showWeapons, true);
	end
end

function GoaHud_WeaponRack:show()
end

function GoaHud_WeaponRack:drawOptionsVariable(varname, x, y, optargs)
	local options_table = nil
	local id = 100
	if (varname == "hideWeapons") then
		options_table = self.options.hideWeapons
	elseif (varname == "hideModes") then
		options_table = self.options.hideModes
		id = 105
	elseif (varname == "textColor") then
		local optargs = clone(optargs)
		optargs.enabled = not self.options.coloredAmmo
		optargs.indent = 1
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs, "Ammo Text Color")
	elseif (varname == "selectedColor") then
		local optargs = clone(optargs)
		optargs.enabled = not self.options.coloredSelection
		optargs.indent = 1
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs)
	elseif (varname == "backgroundColor") then
		local optargs = clone(optargs)
		optargs.enabled = self.options.showBackground
		optargs.indent = 1
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs)
	end

	local offset = nil
	if (options_table ~= nil) then
		offset = 0
		for name in pairs(options_table) do
			offset = offset + GoaHud_DrawOptionsVariable(options_table, name, x, y + offset, optargs)
			id = id + 1
		end
	end

	return offset
end

function GoaHud_WeaponRack:draw()
	if (not shouldShowHUD()) then return end;
	if (not GoaHud.previewMode) then
		if (self.options.hideInRace and isRaceMode()) then return end
		if (self.options.hideInWarmup and world ~= nil and world.gameState == GAME_STATE_WARMUP) then return end
	end

	self.showWeapons[1] = not self.options.hideMelee
	self.showWeapons[2] = not self.options.hideBurstGun

	local player = getPlayer()
	local weapon = player.weaponIndexweaponChangingTo
	local offset_x
	local weapons_picked = 0
	local weapon_count = 0
	local icon_size = 15
	local font_size = 40
	local border = 5
	local offset_width = icon_size*2 + font_size*0.75*3 + border
	local weapon_definitions = weaponDefinitions

	-- show stake in competitive mode if player has it
	if (player.weapons[9].pickedup and player.weapons[9].ammo > 0 and weapon_definitions[9] == nil) then
		weapon_definitions = clone(weaponDefinitions)
		table.insert(weapon_definitions, { lowAmmoWarning = 5, color = Color(128, 0, 0, 255), damagePerPellet = 100, maxAmmo = 20, name = "Stake Launcher", reloadTime = 1250 })
	end

	for i in ipairs(weapon_definitions) do
		weapon_count = weapon_count + 1
		if (self.showWeapons[i] and player.weapons[i].pickedup) then weapons_picked = weapons_picked + 1 end
	end

	local background_width = (weapons_picked * (offset_width)) --+ border*2
	local background_height = math.max(font_size*0.6, icon_size*2) + border*2

	offset_x = -weapons_picked * offset_width / 2

	if (weapons_picked > 0 and self.options.showBackground) then
		nvgBeginPath()
		nvgFillColor(self.options.backgroundColor)
		nvgRect(-icon_size - border + offset_x, -background_height/2, background_width, background_height)
		nvgFill()
	end

	nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_MIDDLE)
	nvgFontFace(GOAHUD_FONT1)
	nvgFontSize(font_size)
	nvgTextLetterSpacing(0)

	for i=1, weapon_count do
		local def = weapon_definitions[i]
		if (def ~= nil and self.showWeapons[i] and player.weapons[i].pickedup) then
			local ammo = math.min(player.weapons[i].ammo, 999)
			local color = clone(def.color)

			-- selected weapon glow
			if (weapon == i) then
				nvgBeginPath()
				if (not self.options.coloredSelection) then
					nvgFillColor(self.options.selectedColor)
				else
					nvgFillColor(Color(color.r, color.g, color.b, color.a * 0.6))
				end
				nvgRect(offset_x - icon_size - border , -background_height/2, offset_width, background_height)
				nvgFill()
			end

			local weapon_icon = "internal/ui/icons/weapon" .. i
			if (i == 1 and player.inventoryMelee ~= nil) then
				local melee_def = inventoryDefinitions[player.inventoryMelee]
				if (melee_def ~= nil) then
					weapon_icon = melee_def.asset or weapon_icon
				end
			end

			nvgFillColor(color)
			GoaHud:drawSvgWithShadow(weapon_icon, offset_x, 0, icon_size, 0, self.options.shadow)

			if (not self.options.coloredAmmo) then
				color = clone(self.options.textColor)
				nvgFillColor(color)
			end

			if (i ~= 1) then
				GoaHud:drawTextWithShadow(offset_x + (font_size*3 - border/2)/2, 0, tostring(ammo), self.options.shadow, { alpha = color.a })
			end

			offset_x = offset_x + offset_width
		end
	end
end