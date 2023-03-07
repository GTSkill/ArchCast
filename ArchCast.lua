local Caster = {}
Caster.__index = Caster

function Caster.new(CastFidelity: number, DebuggingEnabled: boolean, RayFilter: RaycastParams)
	return setmetatable({
		CastFidelity = CastFidelity;
		Debugging = DebuggingEnabled;
		RayFilter = RayFilter;
	}, Caster);

end

function Caster:CreateSphereVisualization(Position: Vector3, Color: Color3)
	if not self.Debugging then return nil end
	local adornment = Instance.new("SphereHandleAdornment")
	adornment.Adornee = workspace.Terrain
	adornment.CFrame = CFrame.new(Position)
	adornment.Color3 = Color
	adornment.Radius = 0.25
	adornment.Transparency = 0.5
	adornment.Parent = game.Workspace.Terrain
	game:GetService("Debris"):AddItem(adornment, 5)

	return adornment
end

function Caster:CreateSegementVisualization(StartPos, EndPos, Length)
	if not self.Debugging then return nil end
	local Adornment = Instance.new("ConeHandleAdornment")
	Adornment.Adornee = workspace.Terrain
	Adornment.CFrame = 	CFrame.new(StartPos, EndPos)
	Adornment.Height = Length
	Adornment.Color3 = Color3.new()
	Adornment.Radius = 0.25
	Adornment.Transparency = 0.5
	Adornment.Parent = game.Workspace.Terrain
	game:GetService("Debris"):AddItem(Adornment, 5)

	return Adornment
end

function Caster:CreateSegments(Origin: Vector3, Direction: Vector3, BulletDrop: number, BulletSpeed: number, MaxDistance: number)
	local SegmentsTable = {}
	local SimulatedTime = 0
	local LastPosition = Origin
	local DistancePerSegment = (Direction*BulletSpeed)/self.CastFidelity
	local TimeForTravelSim = 1/self.CastFidelity
	local RealDrop = BulletDrop/10000

	local MaxSegments = MaxDistance/DistancePerSegment.Magnitude

	for i = 1, MaxSegments do
		SimulatedTime += TimeForTravelSim
		local EndPos = LastPosition + DistancePerSegment - Vector3.new(0,SimulatedTime*SimulatedTime*RealDrop,0)
		--self:CreateSegementVisualization(LastPosition, EndPos, (EndPos-LastPosition).Magnitude)
		local Distance = (LastPosition - EndPos).Magnitude
		table.insert(SegmentsTable, {StartPos = LastPosition, EndPos = EndPos, Length = Distance, SimulationTime = SimulatedTime})
		LastPosition = EndPos
	end	

	return SegmentsTable
end

function Caster:CreateSegmentsWithTime(Origin: Vector3, Direction: Vector3, BulletDrop: number, BulletSpeed: number, MaxDistance: number, StartTime: number)
	local SegmentsTable = {}
	local SimulatedTime = StartTime
	local LastPosition = Origin + (Direction*BulletSpeed)*StartTime
	local DistancePerSegment = (Direction*BulletSpeed)/self.CastFidelity
	local TimeForTravelSim = 1/self.CastFidelity
	local RealDrop = BulletDrop/10000

	local MaxSegments = MaxDistance/DistancePerSegment.Magnitude

	for i = 1, MaxSegments do
		SimulatedTime += TimeForTravelSim
		local EndPos = LastPosition + DistancePerSegment - Vector3.new(0,SimulatedTime*SimulatedTime*RealDrop,0)
		--self:CreateSegementVisualization(LastPosition, EndPos, (EndPos-LastPosition).Magnitude)
		local Distance = (LastPosition - EndPos).Magnitude
		table.insert(SegmentsTable, {StartPos = LastPosition, EndPos = EndPos, Length = Distance, SimulationTime = SimulatedTime-StartTime})
		LastPosition = EndPos
	end	

	return SegmentsTable
end

function Caster:CastRay(CastData: any)
	local Segments = self:CreateSegments(CastData.Origin, CastData.Direction, CastData.BulletDrop, CastData.BulletSpeed, CastData.MaxDistance)
	self:CreateSphereVisualization(CastData.Origin, Color3.new(0.0235294, 0.152941, 1))
	local RayStartTime = tick()

	for i=1, #Segments do
		local CurrentSegment = Segments[i]
		if CastData.PositionUpdateCallback then
			CastData.PositionUpdateCallback(CurrentSegment, CastData)
		end
		local RayTime = tick()-RayStartTime
		while RayTime - CurrentSegment.SimulationTime < 0 do
			RayTime = tick()-RayStartTime
			wait()
		end

		if not self:SegmentCompletion(CastData, CurrentSegment.StartPos, CurrentSegment.EndPos) then return end
		--self:CreateSegementVisualization(CurrentSegment.StartPos, CurrentSegment.EndPos, CurrentSegment.Length)
	end
end


function Caster:CastRayFromTime(CastData: any)
	local Segments = self:CreateSegmentsWithTime(CastData.Origin, CastData.Direction, CastData.BulletDrop, CastData.BulletSpeed, CastData.MaxDistance, CastData.StartTime)
	self:CreateSphereVisualization(CastData.Origin, Color3.new(0.0235294, 0.152941, 1))
	local RayStartTime = tick()
	for i=1, #Segments do
		local CurrentSegment = Segments[i]
		--self.PositionCallback(CurrentSegment)
		if CastData.PositionUpdateCallback then
			local TravelTimeForSegment = tick()-RayStartTime
			CastData.PositionUpdateCallback(CurrentSegment, CastData, TravelTimeForSegment)
		end
		local RayTime = tick()-RayStartTime
		while RayTime - CurrentSegment.SimulationTime < 0 do
			RayTime = tick()-RayStartTime
			wait()
		end

		if not self:SegmentCompletion(CastData, CurrentSegment.StartPos, CurrentSegment.EndPos) then return end
	end
end


function Caster:CastRayInstant(CastData: any)
	local Segments = self:CreateSegments(CastData.Origin, CastData.Direction, CastData.BulletDrop, CastData.BulletSpeed, CastData.MaxDistance)
	self:CreateSphereVisualization(CastData.Origin, Color3.new(0.0235294, 0.152941, 1))

	for i=1, #Segments do
		local CurrentSegment = Segments[i]
		if CastData.PositionUpdateCallback then
			CastData.PositionUpdateCallback(CurrentSegment, CastData)
		end

		if not self:SegmentCompletion(CastData, CurrentSegment.StartPos, CurrentSegment.EndPos) then return end
		--self:CreateSegementVisualization(CurrentSegment.StartPos, CurrentSegment.EndPos, CurrentSegment.Length)
	end
end




function Caster:SegmentCompletion(CastData: CastData, PreviousHitPosition: Vector3, EndPosition: Vector3)
	--TODO Finish this call rays until result doesnt exist aka it hits the end position
	local Filter = CastData.RayFilter
	
	local SegementResult = workspace:Raycast(PreviousHitPosition, EndPosition - PreviousHitPosition, Filter)
	
	while SegementResult do
		table.insert(Filter.FilterDescendantsInstances, SegementResult.Instance)
		self:CreateSegementVisualization(PreviousHitPosition, SegementResult.Position, (PreviousHitPosition - SegementResult.Position).Magnitude)
		self:CreateSphereVisualization(SegementResult.Position, Color3.new(1, 0.243137, 0.254902))
		
		if not CastData.CanPierce(SegementResult, PreviousHitPosition, CastData) then
			CastData.HitCallback(SegementResult, CastData)
			return false
		end
		local NewPos = SegementResult.Position + CastData.Direction * 0.1
		SegementResult = workspace:Raycast(NewPos, EndPosition - NewPos, Filter)
	end
	return true
end


return Caster