local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NPCLibrary = require(ReplicatedStorage.Libraries.NPCLibrary).NPCData
local Types = require(game.ReplicatedStorage.Libraries.Types)
local Teams = require(game.ReplicatedStorage.Libraries.Tags).Teams
local Data = require(game.ReplicatedStorage.Libraries.NPCLibrary).NPCData

local HumanoidManager = require(game.ServerScriptService.HumanoidManager)
local StateMachine = require(game.ReplicatedStorage.SharedModules.StateMachine)
local Batcher = require(game.ReplicatedStorage.Remotes.RemoteBatcher)
local Serialization = require(game.ReplicatedStorage.SharedModules.PacketSerialization)

local active = {}

-------- function to instantiate NPC instances
local function Instantiate(NPC: string, variant: string, frame: CFrame, initializer: Types.NPCInitializer)
	-- setting up necessary and universal variables for every NPC
	local Data = NPCLibrary[NPC].Variants[variant]
	local Model = Data.Model:Clone()

	Model.Parent = workspace.Camera.EntitiesServer
	Model:PivotTo(frame)

	local hum = Model.Humanoid
	local root = Model.HumanoidRootPart

	HumanoidManager.Register(hum, Data.Configuration, Teams.Enemy)
	local registered_hum = HumanoidManager.Get(hum)

	-- doing necessary model and humanoid cleanup for the NPC
	for _, obj in pairs(Model:GetChildren()) do
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

	-- creates a proper instance object for the NPC
	local NPCInstance = initializer.InstanceConfiguration
	NPCInstance.Root = root
	NPCInstance.Model = Model
	NPCInstance.Humanoid = hum
	NPCInstance.ID = registered_hum.ID

	-- creating a model of the NPC for clients to view
	game.ReplicatedStorage.Remotes["NPC Replication"].CreateClientModel:FireAllClients(
		NPC,
		variant,
		NPCInstance.ID,
		frame,
		Teams.Enemy
	)

	-- setting up the state machine for the ai
	local NPCMachine = StateMachine.new()
	NPCMachine.Data.NPC = NPCInstance
	NPCMachine.Data.SanityTick = workspace:GetServerTimeNow()
	NPCMachine:DefineStates(initializer.States, "Neutral", "Spawn")
	NPCMachine:Set("Spawn")

	-- adds the NPCs required pathing connection so it can cleanly follow its assigned path
	task.synchronize()
	NPCInstance.PathingConnection = NPCInstance.Humanoid.MoveToFinished:Connect(
		function(reached: boolean) -- YOU NEED THIS FOR PATHING TO WORK
			if reached and NPCInstance.CurrentWaypoint then
				NPCInstance.WaypointDeb = true
				NPCInstance.CurrentWaypoint += 1
			end
		end
	)

	-- adds the NPCs state machine to the active list of state machines
	active[NPCInstance.ID] = NPCMachine
end

-------- actual reciever for outside messages
script.Parent:BindToMessage("Instantiate", function(NPC: string, variant: string, frame: CFrame)
	print("Getting variant for " .. NPC)
	local NPCData = Data[NPC]

	if NPCData then -- making sure you put a real npc
		local selected_variant
		local variant_name

		if NPCData.Variants[variant] then
			selected_variant = NPCData.Variants[variant]
			variant_name = variant
		else
			warn("Unable to find variant of " .. NPC .. ". Defaulting to first listed variant.")

			for i, v in pairs(NPCData.Variants) do -- easy way to default to the first index of the variants list no matter what
				selected_variant = v
				variant_name = i
				break
			end
		end

		local initializer = require(selected_variant.ControllerModule)
		if initializer then
			if frame then
				Instantiate(NPC, variant_name, frame, initializer) -- spawn the variant of the enemy at the given cframe
			else
				warn("Missing spawn CFrame for variant.")
			end
		else
			warn("Unable to locate variant module.")
		end
	else
		warn("Unable to find NPC with name " .. NPC .. ". Make sure you are inputting correct data.")
	end
end)

-------- loop to run all active NPC state machines
game["Run Service"].Heartbeat:ConnectParallel(function()
	for i, machine in pairs(active) do
		if workspace:GetServerTimeNow() - machine.Data.SanityTick >= 5 then
			machine.Data.SanityTick = workspace:GetServerTimeNow()

			local packet = Serialization.WriteNPCMovementPacket(machine.Data.NPC.Root.Position, i)
			Batcher.Remotes["SanityCheck"]:FireAllClients(packet)
		end

		if machine.Data.NPC.Humanoid.Health <= 0 then
			active[i] = nil
		else
			machine:Update()
		end
	end
end)
