-- welcome to the hit detection module bros, brosephines, and brochachos!
-- this module has a lot of various different customizeable ways to get humanoids in a specific area
-- if we need a new kind of hitbox or hit detection, we can add it here and have it be available for whatever we may need
local HitDetection = {}

-------- this is some internal stuff used to filter the humanoids based on where the hit detection is coming from
-------- this is because hitboxes are all done on the client so we gotta treat them differently depending on the situation

HitDetection.FilteringTypes = {
	PlayerHit = 1,
	NPCHit = 2,
}

function HitDetection.FilterHumanoids(parts: { BasePart })
	local hums = {}

	for _, part in pairs(parts) do
		local hum = part.Parent:FindFirstChildWhichIsA("Humanoid")
		if hum then
			if not table.find(hums, hum) and hum.Health > 0 then
				table.insert(hums, hum)
			end
		end
	end

	return hums
end

function HitDetection.ConvertToIDs(hums: { Humanoid })
	local IDs = {}

	for _, hum in pairs(hums) do
		table.insert(IDs, hum:GetAttribute("ID"))
	end

	return IDs
end

function HitDetection.FilterHits(hits: {}, filter)
	local filtered = {}

	if filter == HitDetection.FilteringTypes.PlayerHit then
		for _, hum in pairs(hits) do
			if hum:GetAttribute("Team") ~= 1 then
				table.insert(filtered, hum)
			end
		end
	elseif filter == HitDetection.FilteringTypes.NPCHit then
		for _, hum in pairs(hits) do
			if hum == game.Players.LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid") then
				table.insert(filtered, hum)
			end
		end
	end

	return filtered
end

-------- this is where all the hitboxes are, ill add relevant descriptions as needed
-------- theyre pretty simple though they shouldnt be tooooo hard to use :)

-- single sphere hit
function HitDetection.HitSphereOnce(pos: Vector3, rad: number, visualize: boolean)
	local params = OverlapParams.new()
	params.FilterDescendantsInstances = workspace.Entities:GetDescendants()
	params.FilterType = Enum.RaycastFilterType.Include

	if visualize then
		local part = Instance.new("Part")
		part.Parent = workspace.Junk
		part.Position = pos
		part.Size = Vector3.new(rad * 2, rad * 2, rad * 2)
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Transparency = 0.5
		part.Color = Color3.new(1, 0.2, 0.2)
		part.Material = Enum.Material.Neon
		part.Shape = Enum.PartType.Ball

		game:GetService("TweenService")
			:Create(part, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Transparency = 1 })
			:Play()
		game.Debris:AddItem(part, 1)
	end

	return HitDetection.FilterHumanoids(workspace:GetPartBoundsInRadius(pos, rad))
end

return HitDetection
