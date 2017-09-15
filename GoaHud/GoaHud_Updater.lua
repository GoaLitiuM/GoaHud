GoaHud_Updater =
{
	options =
	{
		autoUpdateGoaHud = true,
	},

	shadow =
	{
		shadowOffset = 0,
		shadowColor = Color(0, 0, 0, 255),
		shadowStrength = 2.0,
		shadowBlur = 4.0
	},

	updatingAddon = nil,
}
GoaHud:registerWidget("GoaHud_Updater", GOAHUD_MODULE)

function GoaHud_Updater:init()
	if (self.options.autoUpdateGoaHud) then
		self:updateAddon("GoaHud")
	end
end

function GoaHud_Updater:drawOptionsVariable(varname, x, y, optargs)
	if (varname == "autoUpdateGoaHud") then
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs, "Auto Update GoaHud")
	end
	return nil
end

function GoaHud_Updater:updateAddon(addon_name, force)
	local addon
	for i, a in pairs(addons) do
		if (a.name == addon_name) then addon = a; break; end
	end

	if (addon == nil) then return end
	if (not addon.canDownload) then return end
	if (force ~= true) then
		if (addon.epochTimeUpdatedOnDisk >= addon.epochTimeUpdatedOnWorkshop) then return end
		if (addon.fileSize <= 0) then return end -- updater gets stuck on empty workshop entries
	end

	consolePrint("Updating addon " .. addon.name)
	workshopDownloadAddon(addon.workshopId, addon.name)
	self.updatingAddon = addon
end

function GoaHud_Updater:drawText(x, y, value)
	GoaHud:drawTextWithShadow(x, y, value, self.shadow)
end

function GoaHud_Updater:draw()
	if (replayName ~= "menu" and (replayName == "" and world.mapName ~= '')) then return end
	if (isInMenu()) then return end

	local font_size = 32
	local x = -viewport.width/2 + 10
	local y = -viewport.height/2 + 220

	nvgFontSize(font_size)
	nvgFontFace(GOAHUD_FONT5)

	nvgFillColor(Color(255, 255, 255, 255))
	if (assetsChangedRestartRequired) then
		self:drawText(x, y, "Addons updated, restart is required")
		y = y + font_size*2
	end

	nvgFillColor(Color(255, 0, 0, 255))
	for i, addon in pairs(addons) do
		if (addon.epochTimeUpdatedOnDisk < addon.epochTimeUpdatedOnWorkshop) then
			self:drawText(x, y, "Update available: " .. addon.name)
			y = y + font_size
		end
	end

	nvgFillColor(Color(255, 255, 0, 255))
	if (self.updatingAddon) then
		self:drawText(x, y, "Updating " .. self.updatingAddon.name .. "...")
		y = y + font_size

		if (self.updatingAddon.epochTimeUpdatedOnDisk >= self.updatingAddon.epochTimeUpdatedOnWorkshop) then
			self.updatingAddon = nil
		elseif (self.updatingAddon.errorQueryingWorkshop) then
			self.updatingAddon = nil
		end
	end
end