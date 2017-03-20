-- GoaHud_LagTimer made by GoaLitiuM
-- 
-- Visualizes server delay when attack is pressed
--


require "base/internal/ui/reflexcore"

GoaHud_LagTimer =
{
	circleRadius = 35,
	lineWidth = 3,
	alpha = 255,
	minLatency = 80,
	
	lastAttack = false,
	active = false,
	rotation = 0.0,
	rotationSpeed = 0.0,
};
GoaHud:registerWidget("GoaHud_LagTimer", GOAHUD_UI_EXPERIMENTAL);

function GoaHud_LagTimer:init()
end

function GoaHud_LagTimer:draw()
	local player = getPlayer()
	if (player == nil) then return end

	local attack = player.buttons.attack
	local latency = player.latency
	--latency = 150 -- fake latency for testing
	
	if (GoaHud.previewMode) then
		if (not self.active) then
			latency = 500
			self.lastAttack = false
			attack = true
		end
	end

	if (self.lastAttack ~= attack and attack) then
		if (latency > self.minLatency) then
			self.active = true
			self.rotationSpeed = math.pi / (latency / 1000.0)
			self.rotation = 0
		end
	end

	if (self.active) then
		nvgStrokeLinearGradient(0, -self.circleRadius/2.0, 0, 0, Color(255,255,255,self.alpha), Color(0,0,0,0))
		nvgStrokeWidth(self.lineWidth)
		
		nvgBeginPath()
		nvgCircle(0, 0, self.circleRadius)
		nvgStroke()
		
		nvgStrokeColor(Color(255,255,255,self.alpha))
		nvgRotate(self.rotation + math.pi/2)
		nvgBeginPath()
		nvgMoveTo(0, 0)
		nvgLineTo(0, self.circleRadius * 1.25)
		nvgStroke()
		
		self.rotation = self.rotation + deltaTimeRaw * self.rotationSpeed
		if (self.rotation >= math.pi) then
			self.active = false
		end
	end
	
	self.lastAttack = attack
end