local RayCaster = require(script.Parent:FindFirstChild("ArchCast"))

local module = {}

module.CasterObj = RayCaster.new(25, false, nil)

module.Fire = function()
	--Create cast parameters
	local CastParams = RaycastParams.new()
	CastParams.IgnoreWater = true
	CastParams.FilterType = Enum.RaycastFilterType.Blacklist
	CastParams.FilterDescendantsInstances = {game:GetService("Players").LocalPlayer.Character, workspace.Tracers, game.Workspace.CurrentCamera}
	
	--Create ArchCast raydata
	local Camera = game:GetService("Workspace").CurrentCamera
	local CastData = {
		Origin = Camera.CFrame.Position;
		Direction = Camera.CFrame.LookVector;
		MaxDistance = 700; 
		BulletSpeed = 1000;
		BulletDrop = 0.35;
		RayFilter = CastParams;
		CanPierce = function() return false end --This can be implemented to make bullets pierce certain materials, returning true in the function will cause the way to continue
	}

    --Ray hit function
	local function OnRayHit(RayResultData: RaycastResult, CastData)
		RayResultData.Instance:Destroy()
	end
	
	--Create ArchCast and cast it
	CastData.HitCallback = OnRayHit
	module.CasterObj:CastRay(CastData)
end

return module