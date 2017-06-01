-- GoaHud_BetterSpectator made by GoaLitiuM
--
-- Control spectator camera with attack, jump and crouch keys (no rebinding required)
--

require "base/internal/ui/reflexcore"

-- toggle between modes: ui_goahud_spectator_mode -1 or "toggle"
local SPECTATE_MODE_DISABLED = 1		-- ui_goahud_spectator_mode 0 or "disabled"
local SPECTATE_MODE_FOLLOW_KILLER = 2	-- ui_goahud_spectator_mode 1 or "killer"
local SPECTATE_MODE_FOLLOW_LEADER = 3	-- ui_goahud_spectator_mode 2 or "leader"
local SPECTATE_MODE_LAST = SPECTATE_MODE_FOLLOW_LEADER

local SPECTATE_MODE_NAMES =
{
	"Disabled",
	"Follow Killer",
	"Follow Leader",
}

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

		saveUserData(nil)

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

		autoSpectateMode = SPECTATE_MODE_DISABLED,
	},

	optionsDisplayOrder =
	{
		"binds",
		"",
		"autoSpectateMode"
	},

	lastPlayer = -1,
	lastFollowedPlayer = -1,
	lastButtons = {},

	nextPlayer = -1,

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

	GoaHud:createConsoleVariable("spectator_mode", "int", 0, true)
end

local comboBoxData1 = {}
local comboBoxData2 = {}
local comboBoxData3 = {}
local comboBoxData4 = {}
function GoaHud_BetterSpectator:drawOptionsVariable(varname, x, y, optargs)
	if (varname == "binds") then
		local offset_x = 0
		local offset_y = 0

		local camera_next_bind = ""
		local camera_prev_bind = ""
		local camera_free_bind = ""

		for i, bind in pairs(self.options.binds) do
			if (bind == "cl_camera_next_player") then camera_next_bind = i
			elseif (bind == "cl_camera_prev_player") then camera_prev_bind = i
			elseif (bind == "cl_camera_freecam") then camera_free_bind = i end
		end

		local camera_next = 1
		local camera_prev = 1
		local camera_free = 1

		-- bindable values to human readable names
		for i, value in pairs(BIND_VALUES) do
			if (camera_next_bind == value) then camera_next = i end
			if (camera_prev_bind == value) then camera_prev = i end
			if (camera_free_bind == value) then camera_free = i end
		end

		GoaLabel("Hook actions to camera controls:", x + offset_x, y + offset_y, optargs)
		offset_x = offset_x + GOAHUD_INDENTATION
		offset_y = offset_y + GOAHUD_SPACING

		GoaLabel("Camera Next: ", x + offset_x, y + offset_y, optargs)
		camera_next = GoaComboBoxIndex(BIND_NAMES, camera_next, x + offset_x + 175, y + offset_y, 150, comboBoxData3, optargs)
		optargs.optionalId = optargs.optionalId + 1
		offset_y = offset_y + GOAHUD_SPACING

		GoaLabel("Camera Previous: ", x + offset_x, y + offset_y, optargs)
		camera_prev = GoaComboBoxIndex(BIND_NAMES, camera_prev, x + offset_x + 175, y + offset_y, 150, comboBoxData2, optargs)
		optargs.optionalId = optargs.optionalId + 1
		offset_y = offset_y + GOAHUD_SPACING

		GoaLabel("Free Camera: ", x + offset_x, y + offset_y, optargs)
		camera_free = GoaComboBoxIndex(BIND_NAMES, camera_free, x + offset_x + 175, y + offset_y, 150, comboBoxData1, optargs)
		optargs.optionalId = optargs.optionalId + 1
		offset_y = offset_y + GOAHUD_SPACING

		camera_next_bind = BIND_VALUES[camera_next]
		camera_prev_bind = BIND_VALUES[camera_prev]
		camera_free_bind = BIND_VALUES[camera_free]

		for k, v in pairs(self.options.binds) do
			local value = ""
			if (k == camera_next_bind) then value = "cl_camera_next_player" end
			if (k == camera_prev_bind) then value = "cl_camera_prev_player" end
			if (k == camera_free_bind) then value = "cl_camera_freecam" end

			self.options.binds[k] = value
		end

		return offset_y
	elseif (varname == "autoSpectateMode") then
		GoaLabel("Hook actions to camera controls:", x, y, optargs)

		GoaLabel("Auto Spectator: ", x, y, optargs)
		self.options.autoSpectateMode = GoaComboBoxIndex(SPECTATE_MODE_NAMES, self.options.autoSpectateMode, x + 175, y, 250, comboBoxData4, optargs)

		return GOAHUD_SPACING
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

	if (entry.type == LOG_TYPE_DEATHMESSAGE) then
		if (entry.deathKilled == local_player.name) then
			self.deathTimer = 0.75
		end

		if (self.options.autoSpectateMode == SPECTATE_MODE_FOLLOW_KILLER) then
			local killer_index = -1
			for i, p in pairs(players) do
				if (p.name == entry.deathKiller) then
					killer_index = p.index
					break
				end
			end

			if (killer_index >= 0) then
				self.deathTimer = 0.75
				self.nextPlayer = killer_index - 1
			end
		elseif (self.options.autoSpectateMode == SPECTATE_MODE_FOLLOW_LEADER) then
			-- pass 1: find the highest score
			local leader_score = -9999
			for i, p in pairs(players) do
				if (p.score > leader_score) then
					leader_score = p.score
				end
			end

			-- pass 2: find players with highest score
			local leader_index = -1
			for i, p in pairs(players) do
				if (p.score == leader_score) then
					if (leader_index == -1) then
						leader_index = p.index
					else
						-- players are tied, give up and leave camera untouched
						leader_index = -1
						break
					end
				end
			end

			if (leader_index >= 0) then
				self.deathTimer = 0.75
				self.nextPlayer = leader_index - 1
			end
		end
	end
end

local last_spectator_mode = 0
function GoaHud_BetterSpectator:draw()
	if (not isInMenu()) then
		local new_spectator_mode = GoaHud:getConsoleVariable("spectator_mode")
		if (new_spectator_mode ~= last_spectator_mode) then
			local mode = new_spectator_mode
			if (new_spectator_mode == -1) then
				self.options.autoSpectateMode = (self.options.autoSpectateMode % SPECTATE_MODE_LAST) + 1
			elseif (new_spectator_mode == SPECTATE_MODE_DISABLED) then
				self.options.autoSpectateMode = mode
			elseif (new_spectator_mode == SPECTATE_MODE_FOLLOW_KILLER) then
				self.options.autoSpectateMode = mode
			elseif (new_spectator_mode == SPECTATE_MODE_FOLLOW_LEADER) then
				self.options.autoSpectateMode = mode
			end

			GoaHud:setConsoleVariable("spectator_mode", self.options.autoSpectateMode)
			last_spectator_mode = new_spectator_mode

			self:saveOptions()
		end
	end

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

		if (self.nextPlayer ~= -1) then
			consolePerformCommand("cl_camera_player " .. self.nextPlayer)
			self.nextPlayer = -1
		end
	else
		self.deathTimer = self.deathTimer - deltaTimeRaw
	end

	self.lastButtons = buttons
	self.lastPlayer = playerIndexCameraAttachedTo
end
