local EnemyHandler = require(game.ServerScriptService.AI.NPCHandler)
local Types = require(game.ReplicatedStorage.Libraries.Types)

-------- TEST SETUP FOR NEW MODULE FORMAT
local Initializer: Types.NPCInitializer = {
	States = {
		{
			Name = "Neutral",
			Started = function(self)
				local NPC = self.Data.NPC

				if NPC.TargetInstance == nil then
					self:Set("Targetting")
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
					self:Set("Tracking")
				else
					self:Set("Neutral")
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
	},

	InstanceConfiguration = {
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
			AgentParams = {
				AgentRadius = 1,
				AgentHeight = 5,
				AgentCanJump = true,
				AgentCanClimb = false,
				WaypointSpacing = 10,

				PathSettings = {
					SupportPartialPath = true,
				},
			},
		},
	},

	Initialize = function(NPC: Types.NPCInstance) end,
}

return Initializer
