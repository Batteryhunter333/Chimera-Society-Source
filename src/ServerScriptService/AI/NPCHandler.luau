-- this is the broad handler for enemy ai, controllers use the types and functions in this script as a baseline to build off of
-- this is a parallel script, so expect to see a TONNNNNNNNNNNNN of syncing and desyncing
local HumanoidHandler = require(game.ServerScriptService.HumanoidManager)
local Serialization = require(game.ReplicatedStorage.SharedModules.PacketSerialization)

local Types = require(game.ReplicatedStorage.Libraries.Types)

local Batcher = require(game.ReplicatedStorage.Remotes.RemoteBatcher)

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------- TARGETTING FUNCTIONS
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Targetting = {}

-- this function does what it says on the label, and now that i made it not suck its a great method
-- this is also used by other functions in the module so be careful if you edit it (you probably shouldnt edit anything in this script)
function Targetting.GetEnemyHumanoids(ai: Types.NPCInstance)
	task.desynchronize()
	if not ai.Humanoid then
		return
	end

	local registered_hum = HumanoidHandler.Get(ai.Humanoid)
	if not registered_hum then
		return
	end
	return registered_hum:GetOpposingHumanoids()
end

-- targetting function for getting a suitable target for a given NPC instance
-- considers things like head offset, distance from objective, and more
function Targetting.GetTargetEnemy(ai: Types.NPCInstance, esp: boolean)
	task.synchronize()
	if not ai.Humanoid then
		return
	end
	if not ai.Root then
		return
	end

	local registered_hum = HumanoidHandler.Get(ai.Humanoid)
	if not registered_hum then
		return
	end

	task.desynchronize()
	local opposition = Targetting.GetEnemyHumanoids(ai)
	local candidates = {}

	local head_CFrame = ai.Root.CFrame * ai.Properties.HeadOffset
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include

	for _, enemy in pairs(opposition) do -- gets all registered humanoids that meet our conditions to be able to target
		local target_CFrame = enemy.Parent:FindFirstChild("HumanoidRootPart").CFrame

		local dist = (head_CFrame.Position - target_CFrame.Position).Magnitude
		local height = math.abs(head_CFrame.Y - target_CFrame.Y)

		if esp or (dist <= ai.Properties.ViewDistance and height <= ai.Properties.ViewHeight) then
			candidates[enemy] = dist
		end
	end

	local target = nil
	local nearest = 0

	for candidate, distance in pairs(candidates) do -- loop through all possible candidates
		if esp then -- check to see if raycasting is needed
			if target then
				if distance < nearest then
					target = candidate
					nearest = distance
				end
			else
				target = candidate
				nearest = distance
			end
		else
			local origin = head_CFrame.Position
			local direction = candidate.Root.CFrame.Position - origin
			local result = workspace:Raycast(origin, direction)

			params.RespectCanCollide = true
			params.FilterDescendantsInstances = workspace.Map:GetChildren()
			params.FilterType = Enum.RaycastFilterType.Include

			if result then
				if result.Instance.Parent == candidate.Root.Parent then
					if target then
						if distance < nearest then
							target = candidate
							nearest = distance
						end
					else
						target = candidate
						nearest = distance
					end
				end
			end
		end
	end

	if target then
		ai.TargetInstance = target.Parent
	end
end

-- this function is a placeholder rn, but its SUPPOSED to account for a ton of different variables that make a target valid
function Targetting.ValidateTarget(ai: Types.NPCInstance)
	if ai.TargetInstance then
		if ai.TargetInstance:FindFirstChildWhichIsA("Humanoid") then
			return true
		end
	end
	ai.TargetInstance = nil
	return false
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------- PATHING
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Pathing = {}
local Active = {}

-- npc instances have a path variable that it follows when told
-- this should be run before using any pathing functions, as it sets up the ais CurrentPath variable
function Pathing.InitializePath(ai: Types.NPCInstance)
	task.synchronize()
	local path = game:GetService("PathfindingService"):CreatePath({
		AgentRadius = ai.Properties.AgentParams.AgentRadius,
		AgentHeight = ai.Properties.AgentParams.AgentHeight,
		AgentCanJump = ai.Properties.AgentParams.AgentCanJump,
		AgentCanClimb = ai.Properties.AgentParams.AgentCanClimb,
		WaypointSpacing = ai.Properties.AgentParams.WaypointSpacing,

		Costs = ai.Properties.AgentParams.Costs,

		PathSettings = ai.Properties.AgentParams.PathSettings,
	})

	ai.CurrentPath = path
	task.desynchronize()
end

-- this is a simple function that routes the NPCs CurrentPath variable to its TargetInstance variable
function Pathing.RouteToTarget(ai: Types.NPCInstance)
	task.synchronize()
	if not ai.Root then
		return
	end

	pcall(function()
		if ai.TargetInstance and ai.CurrentPath then
			local HRP = ai.TargetInstance:FindFirstChild("HumanoidRootPart")
			ai.CurrentPath:ComputeAsync(ai.Root.Position, HRP.Position)
			ai.LastRecalc = workspace:GetServerTimeNow()
			ai.CurrentWaypoint = 2
			ai.WaypointDeb = true
		end
	end)
	task.desynchronize()
end

function Pathing.GenerateMidairPath()
	-- temp
end

-- sets the following mode of an entity, either changing it to a certain behavior, or taking the NPC out of the following loop
-- this lets ai state machines just tell the model to follow or not
-- also making it so all the ai using the same pathing code means that the replication is way easier
function Pathing.SetFollowing(ai: Types.NPCInstance, condition: number)
	task.desynchronize()

	ai.PathingState = condition
	local entry = table.find(Active, ai)

	if condition == 0 and entry then
		table.remove(Active, entry)
	elseif not entry then
		if condition == 1 then
			print("follwing a path")
		elseif condition == 2 then
			print("following direct")
		end
		table.insert(Active, ai)
	end

	-- im not making libraries for these its too niche and i dont care hop off
	-- 0 = not following anything, so remove it from the loop
	-- 1 = following a path, so set it in the loop
	-- 2 = directly moving towards an instance, so set it to do as such
end

-- this is a really simple debug function that will place balls along the path of the NPC instance
-- white are normal waypoints, green are jump waypoints
function Pathing.VisualizePath(ai: Types.NPCInstance)
	if not ai.CurrentPath then
		return
	end

	task.synchronize()
	local waypoints = ai.CurrentPath:GetWaypoints()

	for _, waypoint in pairs(waypoints) do
		local part = Instance.new("Part")

		part.Size = Vector3.new(1, 1, 1)
		part.CanCollide = false
		part.Shape = Enum.PartType.Ball
		part.Material = Enum.Material.Neon
		part.Anchored = true
		part.Position = waypoint.Position
		part.Parent = workspace.Junk
		game.Debris:AddItem(part, 5)

		if waypoint.Action == Enum.PathWaypointAction.Jump then
			part.Color = Color3.new(0, 1, 0)
		elseif waypoint.Action == Enum.PathWaypointAction.Custom then
			part.Color = Color3.new(0, 0, 1)
		end
	end
	task.desynchronize()
end

-------- IMPORTANT PATHING LOOP
-- this is what lets the SetFollowing function work
local function UpdatePathing()
	task.desynchronize()

	for _, ai in pairs(Active) do
		task.synchronize()
		local waypoints = ai.CurrentPath:GetWaypoints()
		task.desynchronize()

		-- if the npc has finished a movement, move to next waypoint
		if ai.WaypointDeb then
			ai.WaypointDeb = false -- set the debounce back to false

			if #waypoints >= ai.CurrentWaypoint then
				local waypoint = waypoints[ai.CurrentWaypoint]

				-- jump if necessary
				if
					waypoint.Action == Enum.PathWaypointAction.Jump
					and ai.Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping
					and ai.Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall
				then
					task.synchronize()
					ai.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
					local packet = Serialization.WriteNPCIDPacket(ai.ID)
					Batcher.Remotes["Jump"]:FireAllClients(packet)
				end

				-- start walking to the next waypoint
				task.synchronize()
				ai.Humanoid.WalkToPoint = waypoint.Position
				local packet = Serialization.WriteNPCMovementPacket(waypoints[ai.CurrentWaypoint].Position, ai.ID)
				Batcher.Remotes["SetWalkTo"]:FireAllClients(packet)
				task.desynchronize()
			end
		end
	end
end

game:GetService("RunService").Heartbeat:ConnectParallel(UpdatePathing)

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------- EXPORT
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

local package = {
	Data = require(game.ReplicatedStorage.Libraries.NPCLibrary),
	Targetting = Targetting,
	Pathing = Pathing,
}
return package
