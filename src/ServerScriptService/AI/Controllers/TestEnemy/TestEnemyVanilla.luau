local RunService = game:GetService("RunService")
local NPCRep = game.ReplicatedStorage.Remotes["NPC Replication"]

local EnemyHandler = require(game.ServerScriptService.AI.NPCHandler)
local HumanoidHandler = require(game.ServerScriptService.HumanoidManager)
local StateMachine = require(game.ReplicatedStorage.SharedModules.StateMachine)

local NPCData = require(game.ReplicatedStorage.Libraries.NPCLibrary).NPCData
local FamilyData = NPCData.TestEnemy
local EnemyData = FamilyData.Variants.Vanilla
local Types = require(game.ReplicatedStorage.Libraries.Types)
local Teams = require(game.ReplicatedStorage.Libraries.Tags).Teams

local PathingParams: Types.AgentParameters = {
	AgentRadius = 1,
	AgentHeight = 5,
	AgentCanJump = true,
	AgentCanClimb = false,
	WaypointSpacing = 10,

	PathSettings = {
		SupportPartialPath = true,
	},
}

local enemy = {}
local active = {}

function enemy.Instantiate(frame: CFrame)
	local Model = EnemyData.Model
	local EnemyModel = Model:Clone()

	EnemyModel.Parent = workspace.Camera.EntitiesServer
	EnemyModel:PivotTo(frame)

	local hum = EnemyModel.Humanoid
	local root = EnemyModel.HumanoidRootPart

	HumanoidHandler.Register(hum, EnemyData.Configuration, Teams.Enemy)
	local registered_hum = HumanoidHandler.Get(hum)

	for _, obj in pairs(EnemyModel:GetChildren()) do
		if obj:IsA("BasePart") then
			obj:SetNetworkOwner(nil)
		end
	end

	hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Running, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, false)

	local TestInstance: Types.NPCInstance = {
		Root = root,
		Model = EnemyModel,
		Humanoid = hum,
		ID = registered_hum.ID,

		LastRecalc = workspace:GetServerTimeNow(),
		RecalcDelay = 0.15,
		CurrentWaypoint = 2,
		WaypointDeb = false,
		PathingState = 0,

		Properties = {
			ViewHeight = 50,
			ViewDistance = 200,
			DetectRadius = 30,

			FollowDistance = 20,
			FollowHeightThreshold = 2,

			HeadOffset = CFrame.new(Vector3.new(0, 2, 0)),
			RecalculateDistance = 150,
			AgentParams = PathingParams,
		},
	}

	NPCRep.CreateClientModel:FireAllClients("TestEnemy", "Vanilla", TestInstance.ID, frame, Teams.Enemy)

	local AIMachine = StateMachine.new()
	AIMachine.Data.NPC = TestInstance
	local EnemyStates: { StateMachine.State } = {
		{
			Name = "Neutral",
			Started = function(self)
				local NPC = self.Data.NPC

				if NPC.TargetInstance == nil then
					AIMachine:Set("Targetting")
				end
			end,
		},

		{
			Name = "Spawn",
			Duration = 2,

			Started = function(self)
				local NPC = self.Data.NPC
				EnemyHandler.Pathing.InitializePath(NPC)
			end,

			ExitState = "Neutral",
		},

		{
			Name = "Targetting",
			Started = function(self)
				local NPC = self.Data.NPC

				EnemyHandler.Targetting.GetTargetEnemy(NPC, true)
				if EnemyHandler.Targetting.ValidateTarget(NPC) then
					AIMachine:Set("Tracking")
				else
					AIMachine:Set("Neutral")
				end
			end,
		},

		{
			Name = "Tracking",

			Started = function(self)
				-- set the ai to the following path loop
				local NPC = self.Data.NPC
				EnemyHandler.Pathing.SetFollowing(NPC, 1)
			end,
			Stepped = function(self)
				local NPC = self.Data.NPC

				if
					workspace:GetServerTimeNow() - NPC.LastRecalc >= NPC.RecalcDelay
					and NPC.Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping
					and NPC.Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall
				then
					EnemyHandler.Pathing.RouteToTarget(NPC)
				end
			end,
			Completed = function(self)
				-- set the ai to stop following
				local NPC = self.Data.NPC
				EnemyHandler.Pathing.SetFollowing(NPC, 0)
			end,
		},
	}

	AIMachine:DefineStates(EnemyStates, "Neutral", "Spawn")
	AIMachine:Set("Spawn")

	task.synchronize()
	TestInstance.PathingConnection = TestInstance.Humanoid.MoveToFinished:Connect(
		function(reached: boolean) -- YOU NEED THIS FOR PATHING TO WORK
			if reached and TestInstance.CurrentWaypoint then
				TestInstance.WaypointDeb = true
				TestInstance.CurrentWaypoint += 1
			end
		end
	)

	active[TestInstance.ID] = AIMachine
end

RunService.Heartbeat:Connect(function()
	task.synchronize()
	for i, machine in pairs(active) do
		if machine.Data.NPC.Humanoid.Health <= 0 then
			active[i] = nil
		else
			machine:Update()
		end
	end
end)

return enemy
