-- GoaHud_BetterSpectator made by GoaLitiuM
--
-- Control spectator camera with attack, jump and crouch keys (no rebinding required)
--

require "base/internal/ui/reflexcore"

-- dummy widget
GoaHud_BetterSpecControls =
{
	canHide = false,
	isMenu = true,

	options = { binds = {}, },
}

function GoaHud_BetterSpecControls:initialize()
	if (GoaHud_BetterSpectator ~= nil and GoaHud_BetterSpectator.options ~= nil) then
		local options = loadUserData()

		if (options == nil or isEmpty(options)) then return end

		-- migrate settings from
		GoaHud_BetterSpectator.options.binds = clone(options.binds)
		if (options.enabled ~= nil) then GoaHud_BetterSpectator.enabled = options.enabled end

		saveUserData({})

		-- save the new widget options
		GoaHud:invokeSaveLoadOptions(GoaHud_BetterSpectator)
	end
end

function GoaHud_BetterSpecControls:draw()
end

GoaHud_BetterSpectator =
{
	canHide = false,
	canPosition = false,
	enabled = true,

	options =
	{
		binds =
		{
			["attack"] = "cl_camera_next_player",
			["jump"] = "cl_camera_prev_player",
			["crouch"] = "cl_camera_freecam",
			["forward"] = "",
			["back"] = "",
			["left"] = "",
			["right"] = "",
		},
	},

	lastPlayer = -1,
	lastFollowedPlayer = -1,
	lastButtons = {},

	deathTimer = 0,
};
GoaHud:registerWidget("GoaHud_BetterSpectator", GOAHUD_MODULE)

local BIND_NAMES = { "Disabled", "Attack", "Jump", "Crouch", "Forward", "Back", "Strafe Left", "Strafe Right" }
local BIND_VALUES = { "", "attack", "jump", "crouch", "forward", "back", "left", "right" }

function GoaHud_BetterSpectator:init()
	if (self.firstTime) then
		-- register the old widget as a dummy so we can migrate settings from it to this new widget
		registerWidget("GoaHud_BetterSpecControls")
	end
end

local comboBoxData1 = {}
local comboBoxData2 = {}
local comboBoxData3 = {}
function GoaHud_BetterSpectator:drawOptionsVariable(varname, x, y, optargs)
	if (varname == "binds") then
		local offset_y = 150

		local camera_next = ""
		local camera_prev = ""
		local camera_free = ""

		for i, bind in pairs(self.options.binds) do
			if (bind == "cl_camera_next_player") then camera_next = i
			elseif (bind == "cl_camera_prev_player") then camera_prev = i
			elseif (bind == "cl_camera_freecam") then camera_free = i end
		end

		-- bindable values to human readable names
		for i, value in pairs(BIND_VALUES) do
			if (camera_next == value) then camera_next = BIND_NAMES[i] end
			if (camera_prev == value) then camera_prev = BIND_NAMES[i] end
			if (camera_free == value) then camera_free = BIND_NAMES[i] end
		end

		ui2Label("Hooks actions to camera controls", x, y, optargs)

		ui2Label("Free Camera: ", x, y + offset_y, optargs)
		camera_free = ui2ComboBox(BIND_NAMES, camera_free, x + 175, y + offset_y, 150, comboBoxData1, optargs)
		offset_y = offset_y - 50

		ui2Label("Camera Previous: ", x, y + offset_y, optargs)
		camera_prev = ui2ComboBox(BIND_NAMES, camera_prev, x + 175, y + offset_y, 150, comboBoxData2, optargs)
		offset_y = offset_y - 50

		ui2Label("Camera Next: ", x, y + offset_y, optargs)
		camera_next = ui2ComboBox(BIND_NAMES, camera_next, x + 175, y + offset_y, 150, comboBoxData3, optargs)

		for i, name in pairs(BIND_NAMES) do
			if (camera_next == name) then camera_next = BIND_VALUES[i] end
			if (camera_prev == name) then camera_prev = BIND_VALUES[i] end
			if (camera_free == name) then camera_free = BIND_VALUES[i] end
		end

		for k, v in pairs(self.options.binds) do
			local value = ""
			if (k == camera_next) then value = "cl_camera_next_player" end
			if (k == camera_prev) then value = "cl_camera_prev_player" end
			if (k == camera_free) then value = "cl_camera_freecam" end

			self.options.binds[k] = value
		end

		return 150
	end
	return nil
end

function GoaHud_BetterSpectator:getHookedBind(command)
	for i, k in pairs(self.options.binds) do
		if (k == command) then
			if (i == "") then return nil
			else
				return "+" .. i
			end
		end
	end
	return nil
end

function GoaHud_BetterSpectator:command(action, command)
	if (command == "") then return end
	local freecam = playerIndexCameraAttachedTo == playerIndexLocalPlayer

	if (freecam) then
		if (command == "cl_camera_freecam" and self.lastPlayer == playerIndexLocalPlayer) then
			if (self.lastFollowedPlayer == -1) then
				consolePerformCommand("cl_camera_next_player")
			else
				consolePerformCommand("cl_camera_player " .. self.lastFollowedPlayer - 1)
			end
		elseif (action == "attack") then
			consolePerformCommand(command)
		end
	elseif (not freecam) then
		self.lastFollowedPlayer = playerIndexCameraAttachedTo
		consolePerformCommand(command)
	end
end

function GoaHud_BetterSpectator:onLog(entry)
	local local_player = getLocalPlayer()
	if (local_player == nil) then return end

	if (entry.type == LOG_TYPE_DEATHMESSAGE and entry.deathKilled == local_player.name) then
		self.deathTimer = 0.75
	end
end

function GoaHud_BetterSpectator:draw()
	local local_player = getLocalPlayer()
	if (local_player == nil) then return end

	local buttons = local_player.buttons

	if (self.deathTimer <= 0.0) then
		if (buttons.attack and self.lastButtons.attack ~= buttons.attack) then
			self:command("attack", self.options.binds["attack"])
		end
		if (buttons.jump and self.lastButtons.jump ~= buttons.jump) then
			self:command("jump", self.options.binds["jump"])
		end
		if (buttons.crouch and self.lastButtons.crouch ~= buttons.crouch) then
			self:command("crouch", self.options.binds["crouch"])
		end
		if (buttons.forward and self.lastButtons.forward ~= buttons.forward) then
			self:command("forward", self.options.binds["forward"])
		end
		if (buttons.back and self.lastButtons.back ~= buttons.back) then
			self:command("back", self.options.binds["back"])
		end
		if (buttons.left and self.lastButtons.left ~= buttons.left) then
			self:command("left", self.options.binds["left"])
		end
		if (buttons.right and self.lastButtons.right ~= buttons.right) then
			self:command("right", self.options.binds["right"])
		end
	else
		self.deathTimer = self.deathTimer - deltaTimeRaw
	end

	self.lastButtons = buttons
	self.lastPlayer = playerIndexCameraAttachedTo
end
