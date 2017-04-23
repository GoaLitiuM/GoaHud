-- GoaHud_GrenadeTimer made by GoaLitiuM
--
-- Comment.
--
-- TODO:
-- - trigger again while holding attack
-- - prevent triggering during weapon cooldown and while switching weapons

require "base/internal/ui/reflexcore"

GoaHud_GrenadeTimer =
{
	options =
	{
		circleRadius = 55,
		lineWidth = 3,
		alpha = 255,
	},

	timer = 0.0,
	lastAttack = false,
	lastGrenadesFired = 0,
	lastGameState = -1,
	active = false,
	rotation = 0.0,
	grenades = {},
	grenadeCount = 0,
	grenadeDetonationTime = 2.0,
	rotationSpeed = -math.pi / 2.000,
};
GoaHud:registerWidget("GoaHud_GrenadeTimer", GOAHUD_UI_EXPERIMENTAL)

function GoaHud_GrenadeTimer:init()
	local player = getPlayer()
	if (player ~= nil) then
		self.lastGrenadesFired = player.weaponStats[4].shotsFired
	end
end

function GoaHud_GrenadeTimer:drawOptionsVariable(varname, x, y, optargs)
	if (varname == "circleRadius") then
		local optargs = clone(optargs)
		optargs.min_value = 1
		optargs.max_value = 250
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs)
	elseif (varname == "lineWidth") then
		local optargs = clone(optargs)
		optargs.min_value = 0.1
		optargs.max_value = 30
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs)
	elseif (varname == "alpha") then
		local optargs = clone(optargs)
		optargs.min_value = 0
		optargs.max_value = 255
		optargs.tick = 1
		return GoaHud_DrawOptionsVariable(self.options, varname, x, y, optargs)
	end

	return nil
end


function GoaHud_GrenadeTimer:draw()
	if (not GoaHud.previewMode and not shouldShowHUD()) then return end

	local player = getPlayer()
	if (player == nil) then return end

	local warmup = world ~= nil and world.gameState == GAME_STATE_WARMUP

	local weapon = player.weaponIndexSelected
	local fired = false

	if (GoaHud.previewMode) then
		if (self.grenadeCount == 0) then
			table.insert(self.grenades, self.timer)
			self.grenadeCount = self.grenadeCount + 1
		end
	elseif (warmup) then
		local attack = player.buttons.attack and weapon == 4

		if (self.lastAttack ~= attack and attack) then
			fired = true
		end

		self.lastAttack = attack
	else
		local grenades_fired = player.weaponStats[4].shotsFired

		if (grenades_fired > self.lastGrenadesFired) then
			fired = true
		end

		self.lastGrenadesFired = grenades_fired
	end

	if (fired) then
		table.insert(self.grenades, self.timer)
		self.grenadeCount = self.grenadeCount + 1
	end

	if (self.grenadeCount > 0) then
		nvgStrokeLinearGradient(0, -self.options.circleRadius*0.2, 0, 0, Color(0,0,0,0), Color(255,255,255,self.options.alpha))
		nvgStrokeWidth(self.options.lineWidth)

		nvgBeginPath()
		nvgCircle(0, 0, self.options.circleRadius)
		nvgStroke()

		local expired = {}
		for i, grenade_time in ipairs(self.grenades) do
			local duration = self.timer - grenade_time
			nvgSave()
			nvgStrokeColor(Color(255,255,255,self.options.alpha))
			nvgRotate(duration * self.rotationSpeed + math.pi/2)
			nvgBeginPath()
			nvgMoveTo(0, 25)
			nvgLineTo(0, self.options.circleRadius * 1.25)
			nvgStroke()
			nvgRestore()

			if (duration >= self.grenadeDetonationTime) then
				table.insert(expired, i)
			end
		end

		for i in ipairs(expired) do
			table.remove(self.grenades, i)
			self.grenadeCount = self.grenadeCount - 1
		end
	end

	self.timer = self.timer + deltaTimeRaw
end