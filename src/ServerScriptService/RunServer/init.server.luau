local ServerUpdates = require(script.ServerUpdatesModule)
local HumanoidHandler = require(game.ServerScriptService.HumanoidManager)

local Teams = require(game.ReplicatedStorage.Libraries.Tags).Teams
local Remotes = game.ReplicatedStorage.Remotes

local serverSize = 0
local playersLoaded = 0

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- literally all this does is set up the server depending on the context
game.Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		if char.Parent then
			char.Parent = workspace.Entities
		end
	end)

	local joinData = plr:GetJoinData()
	local tpData = joinData.TeleportData

	if not serverSize and tpData then
		serverSize = tpData[1]
		workspace.Info.Players.Value = serverSize
	end
end)

game.ReplicatedStorage.Remotes["Game Functions"].SetPlayerLoaded.OnServerEvent:Connect(function(plr)
	if game:GetService("RunService"):IsStudio() then -- this will set your character and related info to whatever is stored in the value under this script
		ServerUpdates.ChangePlayerCharacterModel(
			plr,
			script:GetAttribute("TestCharacter"),
			script:GetAttribute("Skin"),
			CFrame.new(0, 5, 0)
		)
	else -- this sets everything up using the teleport data from the lobby place
		local joinData = plr:GetJoinData()
		local tpData = joinData.TeleportData
		print(tpData)

		playersLoaded += 1
	end
end)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------- area handling client requests for important server-sided humanoid data

-- these are functions the client can name with the RequestHumanoidData remotefunction
-- providing a topic will run the function its assigned to and return the relevant result to the client
local topics = {
	["CooldownCalc"] = function(registered_hum, slot, cooldown)
		return registered_hum:CalcSkillCooldown(slot, cooldown)
	end,
	["StacksCalc"] = function(registered_hum, slot, stacks)
		return registered_hum:CalcSkillStacks(slot, stacks)
	end,
}

Remotes["Game Functions"].RequestHumanoidData.OnServerInvoke = function(plr, topic, ...)
	local registered_hum = HumanoidHandler.Get(plr.Character:FindFirstChildWhichIsA("Humanoid"))

	return topics[topic](registered_hum, ...)
end

-- this is for setting the skill data of a players registered humanoid
Remotes["Game Functions"].SetHumanoidSkillData.OnServerEvent:Connect(function(plr, data)
	local registered_hum = HumanoidHandler.Get(plr.Character:FindFirstChildWhichIsA("Humanoid"))
	registered_hum:SetSkillData(data)
end)

-- this is the event used for when a player wishes to damage a specific target
-- the damage amount is provided as a percentage, which will be multiplied with the sources damage stat
Remotes["Game Functions"].SendDamage.OnServerEvent:Connect(
	function(plr, targets: { number }, sourceID: number, amount: number, numindex: number)
		local rPlr = HumanoidHandler.Get(plr.Character:FindFirstChildWhichIsA("Humanoid"))
		local rSource = HumanoidHandler.GetFromID(sourceID)

		for _, ID in pairs(targets) do
			local rTarget = HumanoidHandler.GetFromID(ID)

			-- this check runs server side to stop players from damaging team members
			-- i dont want exploiters to be able to instantly kill players, so this only lets players damage enemies and themself
			-- also you cant hit spectators obviously
			if (rTarget.Team ~= rPlr.Team or rPlr.ID == rTarget.ID) and rTarget.Team ~= Teams.Spectator then
				rTarget:TakeDamage(amount * rSource.Damage, rSource, numindex)
			end
		end
	end
)

-- this is the event used for when a player wishes to damage a specific target
-- the damage amount is provided as a percentage, which will be multiplied with the sources damage stat
Remotes["Game Functions"].SendKnockback.OnServerEvent:Connect(
	function(plr, targets: { number }, vector3: Vector3, power: number)
		local rPlr = HumanoidHandler.Get(plr.Character:FindFirstChildWhichIsA("Humanoid"))

		for _, ID in pairs(targets) do
			local rTarget = HumanoidHandler.GetFromID(ID)

			-- same check for knockback, do NOT fling your teammates out of the map
			if (rTarget.Team ~= rPlr.Team or rPlr.ID == rTarget.ID) and rTarget.Team ~= Teams.Spectator then
				-- this just checks if the vector3 given is a position or a directions for convenience sake
				-- that way the script will automatically do a pulse/knockback depending on what you give it
				if
					vector3.X > 1
					or vector3.Y > 1
					or vector3.Z > 1
					or vector3.X < -1
					or vector3.Y < -1
					or vector3.Z < -1
				then
					rTarget:ApplyPulse(vector3, power)
				else
					rTarget:ApplyKnockback(vector3, power)
				end
			end
		end
	end
)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
