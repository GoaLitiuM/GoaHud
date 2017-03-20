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
	},
	optionsDisplayOrder = { "hideMelee", "hideBurstGun", "hideInRace", "hideInWarmup", "coloredAmmo", "textColor"},
	
	showWeapons = {},
};
GoaHud:registerWidget("GoaHud_WeaponRack");

function GoaHud_WeaponRack:init()
	for i=1, 10 do
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
	local offset_x = 0
	local weapons_picked = 0
	local weapon_count = 0
	local icon_size = 15
	local font_size = 40
	local offset_width = icon_size*2 + font_size*0.75*3
	
	for i in ipairs(weaponDefinitions) do
		weapon_count = weapon_count + 1
		if (self.showWeapons[i] and player.weapons[i].pickedup) then weapons_picked = weapons_picked + 1 end
	end
	
	offset_x = -weapons_picked * offset_width / 2
	
	if (weapons_picked > 0) then
		local border = 5
		local background_width = (weapons_picked * offset_width) + border*2
		local background_height = math.max(font_size*0.6, icon_size*2) + border*2
		
		nvgBeginPath()
		nvgFillColor(Color(0, 0, 0, 64))
		nvgRect(-icon_size-border + offset_x, -background_height/2, background_width, background_height)
		nvgFill()
	end
	
	nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_MIDDLE)
	nvgFontFace(GOAHUD_FONT1)
	nvgFontSize(font_size)
	nvgTextLetterSpacing(0)

	for i=1, weapon_count do
		if (self.showWeapons[i] and player.weapons[i].pickedup) then 
			local def = weaponDefinitions[i];
			local ammo = math.min(player.weapons[i].ammo, 999)
			local color = Color(def.color.r, def.color.g, def.color.b, def.color.a);
			
			local weapon_icon
			if (i == 1 and player.inventoryMelee ~= nil) then
				weapon_icon = inventoryDefinitions[player.inventoryMelee].asset or weapon_icon
			else
				weapon_icon = "internal/ui/icons/weapon" .. i
			end
	
			nvgFillColor(color)
			nvgSvg(weapon_icon, offset_x, 0, icon_size)
			
			if (not self.options.coloredAmmo) then
				nvgFillColor(self.options.textColor)
			end

			local ammo_str = tostring(ammo)
			nvgText(offset_x + offset_width/2, 0, ammo_str)

			offset_x = offset_x + offset_width
		end
	end
end