local module = {}
local ts = game:GetService("TweenService")
local SkillLibrary = require(game.ReplicatedStorage.Libraries.SkillsLibrary).Skills

local SecondaryCubeColors = {
	Default = Color3.new(0.8, 0.8, 0.8),
	Green = Color3.new(0.3, 1, 0.5),
}

module[SkillLibrary.BlockDrop.ID] = function(args: {})
	local mouseHit, skin = table.unpack(args)

	local cube = Instance.new("Part")
	cube.Parent = workspace.Junk
	cube.Position = mouseHit.Position + Vector3.new(0, 42, 0)
	cube.Size = Vector3.new(20, 20, 20)
	cube.CFrame = CFrame.fromMatrix(cube.Position, mouseHit.XVector, cube.CFrame.YVector)
	cube.Anchored = true
	cube.CanCollide = false

	if SecondaryCubeColors[skin] then
		cube.Color = SecondaryCubeColors[skin]
	else
		cube.Color = SecondaryCubeColors.Default
	end

	task.delay(0.5, function()
		local result = workspace:Raycast(cube.Position, Vector3.new(0, -1000, 0))

		ts:Create(
			cube,
			TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
			{ Position = result.Position + Vector3.new(0, 5, 0) }
		):Play()
		task.wait(0.25)

		local BOOM = Instance.new("Explosion")
		BOOM.Parent = workspace.Junk
		BOOM.Position = cube.Position
		BOOM.ExplosionType = Enum.ExplosionType.NoCraters
		BOOM.BlastRadius = 0

		ts:Create(cube, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Transparency = 1 })
			:Play()
		task.wait(0.5)
		cube:Destroy()
	end)
end

module[SkillLibrary.ConcreteBlast.ID] = function(args: {})
	local HRP = table.unpack(args)

	HRP.Trail.Enabled = true

	local BOOM = Instance.new("Explosion")
	BOOM.Parent = workspace.Junk
	BOOM.Position = HRP.Position
	BOOM.ExplosionType = Enum.ExplosionType.NoCraters
	BOOM.BlastRadius = 0

	task.delay(0.75, function()
		HRP.Trail.Enabled = false
	end)
end

return module
