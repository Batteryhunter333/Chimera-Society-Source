-- hi there, this is the script that tells the player what the npcs are doing on the server
-- you really shouldnt have to edit this at all, definitely talk to me before messing with anything in here
local Data = require(game.ReplicatedStorage.Libraries.NPCLibrary).NPCData
local Hits = require(game.ReplicatedStorage.Libraries.HitnumberLibrary)

local ReplicationRemotes = game.ReplicatedStorage.Remotes["NPC Replication"]
local CallVFX = game.Players.LocalPlayer.PlayerScripts.Events.CallVFX

local Serialization = require(game.ReplicatedStorage.SharedModules.PacketSerialization)

local ts = game:GetService("TweenService")

local Replicated = {}
local Healthbars = {}

local function CallNPCAction(ID: number, index: number)
	local NPC = Replicated[ID]
	if NPC then
		local actions = require(NPC:FindFirstChildWhichIsA("ModuleScript"))
		print("action")
		actions[index]()
	end
end

-- we provide this function the specified NPC it needs to make, as well as a humanoid instance and a CFrame
-- the humanoid instance isnt strictly necessary for making the model, but it helps sync things across server and client
-- it also acts as a key we can look for later :)

-- i will NOT be serializing this go die
local full_HP_color = Color3.fromRGB(0, 255, 127)
local mid_HP_color = Color3.fromRGB(255, 255, 127)
local low_HP_color = Color3.fromRGB(255, 0, 127)
local fade = 0.01

-- creates and initializes the model that will replicate the actions of the specified NPC
ReplicationRemotes.CreateClientModel.OnClientEvent:Connect(
	function(NPC, Variant: string, ID: number, frame: CFrame, team: number)
		local npcdata = Data[NPC]
		local variantdata = npcdata.Variants[Variant]
		local model = variantdata.Model
		local new1 = model:Clone()

		local humanoid = new1:FindFirstChildWhichIsA("Humanoid")
		local health_fill = new1.HumanoidRootPart.HealthbarAttachment.BillboardGui.Bar_Fill
		local health_outline = new1.HumanoidRootPart.HealthbarAttachment.BillboardGui.Bar_Outline
		local health_bg = new1.HumanoidRootPart.HealthbarAttachment.BillboardGui.Bar_BG
		local health_gradient = health_fill.UIGradient

		-- place model
		new1.Parent = workspace.Entities
		new1:PivotTo(frame)

		-- sync model stats
		humanoid.WalkSpeed = variantdata.Configuration.BaseStats.BaseSpeed
		humanoid.JumpHeight = variantdata.Configuration.BaseStats.BaseJump
		humanoid.Health = variantdata.Configuration.BaseStats.BaseHealth
		humanoid.MaxHealth = variantdata.Configuration.BaseStats.BaseHealth

		-- set humanoid attributes
		humanoid:SetAttribute("Team", team)
		humanoid:SetAttribute("ID", ID)
		humanoid:SetAttribute("Type", NPC)
		humanoid:SetAttribute("Variant", Variant)

		-- set healthbar behavior
		local HealthAppear = nil
		local HealthDisappear = nil

		local HealthConnection = humanoid.HealthChanged:Connect(function()
			-- actual health bar behavior
			local ratio = humanoid.Health / humanoid.MaxHealth

			if ratio >= 0 and ratio + fade <= 1 then -- decides what amount of the health bar should be full
				health_gradient.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0), -- start point
					NumberSequenceKeypoint.new(ratio, 0), -- sets the health bar to fill up based off % of hp you have
					NumberSequenceKeypoint.new(ratio + fade, 1), -- sets a little fade off
					NumberSequenceKeypoint.new(1, 1),
				}) -- end point
			else
				health_gradient.Transparency = NumberSequence.new(0)
			end

			if humanoid.Health / humanoid.MaxHealth >= 0.5 then -- handles the smooth color transition as your health gets lower
				health_fill.ImageColor3 = full_HP_color:Lerp(mid_HP_color, 2 - ratio * 2)
			else
				health_fill.ImageColor3 = mid_HP_color:Lerp(low_HP_color, 1 - (ratio - 0.5) * 2)
			end

			-- appear/disappear behavior
			-- this is super pointless and really obnoxious looking as a segment of code, but i like having it
			if HealthDisappear then
				for _, tween in pairs(HealthDisappear) do
					tween:Cancel()
				end
				HealthDisappear = nil
			end

			if not HealthAppear then
				HealthAppear = {
					[1] = ts:Create(
						health_fill,
						TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
						{ ImageTransparency = 0 }
					),
					[2] = ts:Create(
						health_bg,
						TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
						{ ImageTransparency = 0 }
					),
					[3] = ts:Create(
						health_outline,
						TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
						{ ImageTransparency = 0 }
					),
				}

				for _, tween in pairs(HealthAppear) do
					tween:Play()
				end

				HealthAppear[1].Completed:Once(function()
					HealthAppear = nil

					HealthDisappear = {
						[1] = ts:Create(
							health_fill,
							TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 5),
							{ ImageTransparency = 1 }
						):Play(),
						[2] = ts:Create(
							health_bg,
							TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 5),
							{ ImageTransparency = 1 }
						):Play(),
						[3] = ts:Create(
							health_outline,
							TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 5),
							{ ImageTransparency = 1 }
						):Play(),
					}
				end)
			end
		end)

		-- log the replicated instance
		Replicated[ID] = new1
		Healthbars[ID] = HealthConnection
	end
)

-- removes the specified model from the client
ReplicationRemotes.RemoveClientModel.OnClientEvent:Connect(function(calls: {}) -- serialized
	for _, call in pairs(calls) do
		local ID = Serialization.ReadNPCIDPacket(call[1])
		local NPC = Replicated[ID]

		if NPC then
			Replicated[ID] = nil
			Healthbars[ID]:Disconnect()

			if NPC:FindFirstChild("HealthbarAttachment", true) then
				NPC:FindFirstChild("HealthbarAttachment", true):Destroy()
			end

			local NPCtype = NPC:FindFirstChildWhichIsA("Humanoid"):GetAttribute("Type")
			local NPCVariant = NPC:FindFirstChildWhichIsA("Humanoid"):GetAttribute("Variant")
			local death = Data[NPCtype].Variants[NPCVariant].ActionsIndex["Death"]

			if death then
				task.spawn(function()
					local actions = require(NPC:FindFirstChildWhichIsA("ModuleScript"))
					actions[death]()
				end)
			else
				NPC:Destroy()
			end
		end
	end
end)

-- tells a replicated npc to perform an action it is coded to do
ReplicationRemotes.CallAction.OnClientEvent:Connect(function(packet: buffer) -- serialized
	local ID, index = Serialization.ReadNPCActionPacket(packet)
	CallNPCAction(ID, index)
end)

-- sets the WalkToPosition variable of a specified npc
ReplicationRemotes.SetWalkTo.OnClientEvent:Connect(function(calls: {}) -- serialized
	for _, call in pairs(calls) do
		local ID, pos = Serialization.ReadNPCMovementPacket(call[1])

		local model = Replicated[ID]
		if model then
			model:FindFirstChildWhichIsA("Humanoid").WalkToPoint = pos
		end
	end
end)

-- makes the replicated npc jump
ReplicationRemotes.Jump.OnClientEvent:Connect(function(calls: {}) -- serialized
	for _, call in pairs(calls) do
		local model = Replicated[Serialization.ReadNPCIDPacket(call[1])]
		if model then
			model:FindFirstChildWhichIsA("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

-- updates the specified stat of a replicated npc
ReplicationRemotes.UpdateStats.OnClientEvent:Connect(function(calls: {})
	for _, call in pairs(calls) do
		print(call[1])
	end
end)

-- damages a replicated npc to keep consistent with the server
ReplicationRemotes.ReplicateDamage.OnClientEvent:Connect(function(calls: {})
	for _, call in pairs(calls) do
		local ID, index, damage = Serialization.ReadHitPacket(call[1])
		local NPC = Replicated[ID]

		if NPC then
			NPC:FindFirstChildWhichIsA("Humanoid"):TakeDamage(damage)

			local hitnum = Hits.presets[index]
			hitnum.Position = NPC.PrimaryPart.Position
			hitnum.Value = damage
			CallVFX:Fire("HitNumberVFX", "Create", hitnum)
		end
	end
end)

-- applies the knockback recieved by an npc on the server
ReplicationRemotes.ReplicateKnockback.OnClientEvent:Connect(function(calls: {})
	for _, call in pairs(calls) do
		local ID, dir, power = Serialization.ReadKnockbackPacket(call[1])
		print(ID)
		local NPC = Replicated[ID]
		local HRP = NPC:FindFirstChild("HumanoidRootPart")

		local att = Instance.new("Attachment")
		att.Parent = HRP
		local force = Instance.new("LinearVelocity")
		force.Parent = att

		force.Attachment0 = att
		force.MaxForce = 9999999
		force.VectorVelocity = dir * power

		game.TweenService
			:Create(
				force,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ VectorVelocity = dir * 0.1 }
			)
			:Play()
		game.Debris:AddItem(att, 0.3)
	end
end)
