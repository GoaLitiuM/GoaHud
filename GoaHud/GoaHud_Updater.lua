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
		shadowBlur = 3.0
	},

	updatingAddon = nil,
}
GoaHud:registerWidget("GoaHud_Updater", GOAHUD_MODULE)

function GoaHud_Updater:init()
	if (self.options.autoUpdateGoaHud) then
		self:updateAddon("GoaHud")
	end
end

function GoaHud_Updater:updateAddon(addon_name)
	local addon
	for i, a in pairs(addons) do
		if (a.name == addon_name) then addon = a; break; end
	end

	if (addon == nil) then return end
	if (addon.epochTimeUpdatedOnDisk >= addon.epochTimeUpdatedOnWorkshop) then return end

	consolePrint("Updating addon " .. addon.name)
	workshopDownloadAddon(addon.workshopId, addon.name)
	self.updatingAddon = addon
end

function GoaHud_Updater:drawText(x, y, value)
	GoaHud:drawTextShadow(x, y, value, self.shadow)
	nvgText(x, y, value)
end

function GoaHud_Updater:tick()
	if (replayName ~= "menu" and (replayName == "" and world.mapName ~= '')) then return end
	if (isInMenu()) then return end

	local x = -viewport.width/2 + 10
	local y = -viewport.height/2 + 220

	nvgFontSize(32)
	nvgFontFace(GOAHUD_FONT5)
	nvgFillColor(Color(255, 255, 255, 255))

	if (assetsChangedRestartRequired) then
		self:drawText(x, y, "Addons updated, restart is required")
	end

	for i, addon in pairs(addons) do
		if (addon.epochTimeUpdatedOnDisk < addon.epochTimeUpdatedOnWorkshop) then
			self:drawText(x, y, "Update available: " .. addon.name)
			y = y + 32
		end
	end

	if (self.updatingAddon) then
		self:drawText(x, y, "Updating " .. self.updatingAddon.name .. "...")

		if (self.updatingAddon.epochTimeUpdatedOnDisk >= self.updatingAddon.epochTimeUpdatedOnWorkshop) then
			self.updatingAddon = nil
		end
	end
end