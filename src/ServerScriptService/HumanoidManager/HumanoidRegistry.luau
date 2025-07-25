local ModData = require(game.ReplicatedStorage.Libraries.ModifiersLibrary)
local AfflictionData = require(game.ReplicatedStorage.Libraries.AfflictionsLibrary)

local Tags = require(game.ReplicatedStorage.Libraries.Tags)
local Types = require(game.ReplicatedStorage.Libraries.Types)

local Remotes = game.ReplicatedStorage.Remotes

local Batcher = require(Remotes.RemoteBatcher)
local Serialization = require(game.ReplicatedStorage.SharedModules.PacketSerialization)
local Trove = require(game.ReplicatedStorage.SharedModules.Trove)

local RegisteredHumanoid = {} -- the registered humanoid object that gets created
RegisteredHumanoid.__index = RegisteredHumanoid

-- these are used as a fallback if the script cannot find any base stats to give the humanoid
-- these should NEVER be used under normal circumstances
local placeholder_config: Types.HumanoidConfiguration = {
	BaseStats = {
		Name = "Undisclosed",
		BaseHealth = 50,
		BaseArmor = 0,
		BaseDamage = 2,
		BaseSpeed = 16,
		BaseJump = 7.2,
	},

	LevelStats = {
		BaseHealth = 5,
		BaseArmor = 2,
		BaseDamage = 1,
		BaseJump = 0,
		BaseSpeed = 0,
	},

	Tags = {},
}

-- stores all registered humanoids, we only edit this directly within the bindable event functions
-- doing it that way means we dont have to worry about the registry being different across threads
-- dw about that though the humanoidmanager has great easy abstractions that handle that for you
-- DO feel free to directly read this from wherever if you need to though, that should be fine
local Registry = {
	Humanoids = {},

	[Tags.Teams.None] = {},
	[Tags.Teams.Player] = {},
	[Tags.Teams.Enemy] = {},
	[Tags.Teams.Spectator] = {},
}

-- internal function that takes an input and iterates it through a subjects modifiers
-- tags have to be in a table like this {tag1, tag2, tag3}, even if theres only one tag
-- ideally you wont have to work with this function unless your name is battery
local function IterateModifiers(subject: {}, input: number, tags: {})
	local currentValue = input

	local usedMods = {} -- grabbing relevant applied modifiers
	for name, modifier in pairs(subject["Modifiers"]) do
		for __, tag in pairs(modifier.Tags) do
			if table.find(tags, tag) then
				usedMods[name] = modifier
			end
		end
	end

	for _, mod in pairs(usedMods) do -- iterating through the mod functions
		if mod.CalcFunction then
			local newValue = mod.CalcFunction(subject, mod.Stacks, currentValue, tags)
			currentValue = newValue
		end
	end

	local usedAfflictions = {} -- grabbing relevant afflictions
	for name, affliction in pairs(subject["Afflictions"]) do
		for __, tag in pairs(affliction.Tags) do
			if table.find(tags, tag) then
				usedAfflictions[name] = affliction
			end
		end
	end

	for _, affliction in pairs(usedAfflictions) do -- iterating through the affliction calc functions
		if affliction.CalcFunction then
			local newValue = affliction.CalcFunction(subject, affliction.Stacks, currentValue, tags)
			currentValue = newValue
		end
	end

	return currentValue
end

-- this is a set of functions used to create individual ID numbers for each registered humanoid
-- this is so i dont have to use httpservice and generate insane 40 character long strings, so it saves lots of bandwidth :)
local RegisteredIDs = {}
local UnregisteredSlots = {}

local function RegisterNewID(hum: Humanoid)
	local ID

	if #UnregisteredSlots > 0 then
		ID = UnregisteredSlots[1]
		table.remove(UnregisteredSlots, 1)
	else
		ID = #RegisteredIDs + 1
	end

	RegisteredIDs[ID] = hum
	hum:SetAttribute("ID", ID)
	return ID
end

local function UnregisterID(ID: number)
	RegisteredIDs[ID] = nil
	table.insert(UnregisteredSlots, ID)
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------- UNIVERSAL FUNCTIONS
------------------------------------------------------------------------------------------------------------------------------------------------------------------

-------- SETUP FUNCTIONS

function RegisteredHumanoid:Initialize(base_stats: Types.BaseStats) -- this configures a registered humanoid to fit the provided base stats
	self.Name = base_stats.Name
	self.OriginHumanoid.DisplayName = base_stats.Name
	self.BaseStats = base_stats
	self.Level = 0

	-- stats kept in the humanoid itself
	self.OriginHumanoid.MaxHealth = base_stats.BaseHealth
	self.OriginHumanoid.Health = base_stats.BaseHealth
	self.OriginHumanoid.WalkSpeed = base_stats.BaseSpeed
	self.OriginHumanoid.JumpHeight = base_stats.BaseJump

	-- stats stored in the registered humanoid
	self.Damage = base_stats.BaseDamage
	self.Armor = base_stats.BaseArmor
end

function RegisteredHumanoid:Unregister() -- this removes the humanoid from the registry
	if Registry.Humanoids[self.OriginHumanoid] then
		for _, list in pairs(Registry) do -- remove from registry lists
			if list[self.OriginHumanoid] then
				list[self.OriginHumanoid] = nil
			end
		end

		UnregisterID(self.ID) -- unregister ID
		Batcher.Remotes["RemoveClientModel"]:FireAllClients(Serialization.WriteNPCIDPacket(self.ID)) -- remove on clients

		self.Trove:Destroy()
	else
		warn("Humanoid is already unregistered!")
	end
end

-------- TEAM FUNCTIONS

function RegisteredHumanoid:SetTeam(team: string | number) -- sets all the team related values for the humanoid
	if Tags.Teams[team] then -- if youre using the team name
		self.Team = Tags.Teams[team]
		Registry[Tags.Teams[team]][self.OriginHumanoid] = self
	elseif Registry[team] then -- if youre using the team number
		self.Team = team
		Registry[team][self.OriginHumanoid] = self
	else -- if it cant assign a team or you didnt give one
		self.Team = Tags.Teams.None
		Registry[Tags.Teams.None][self.OriginHumanoid] = self
	end

	self.OriginHumanoid:SetAttribute("Team", self.Team) -- so clients can see :)
end

function RegisteredHumanoid:GetOpposingTeams() -- gets all teams opposing the registered humanoid, returns a table of teams
	local list = {}

	for _, team in pairs(Tags.Teams) do
		if team ~= Tags.Teams.Spectator and team ~= self.Team then
			table.insert(list, team)
		end
	end

	return list
end

function RegisteredHumanoid:GetEnemies()
	local list = {}

	local opps = self:GetOpposingTeams()
	for _, team in pairs(opps) do
		for _, enemy in pairs(Registry[team]) do
			table.insert(list, enemy)
		end
	end

	return list
end

function RegisteredHumanoid:GetOpposingHumanoids()
	local list = {}

	local opps = self:GetOpposingTeams()
	for _, team in pairs(opps) do
		for _, enemy in pairs(Registry[team]) do
			table.insert(list, enemy.OriginHumanoid)
		end
	end

	return list
end

-------- STATS HANDLING FUNCTIONS

function RegisteredHumanoid:RecalulateStats() -- calculates actual stats, starting from base stats
	local ratio = self.OriginHumanoid.Health / self.OriginHumanoid.MaxHealth

	local BaseDamage = self.BaseStats.BaseDamage
	if self.LevelStats.BaseDamage then
		BaseDamage += (self.LevelStats.BaseDamage * self.Level)
	end

	local BaseArmor = self.BaseStats.BaseArmor
	if self.LevelStats.BaseArmor then
		BaseArmor += (self.LevelStats.BaseArmor * self.Level)
	end

	local BaseHealth = self.BaseStats.BaseHealth
	if self.LevelStats.BaseHealth then
		BaseHealth += (self.LevelStats.BaseHealth * self.Level)
	end

	local BaseSpeed = self.BaseStats.BaseSpeed
	if self.LevelStats.BaseSpeed then
		BaseSpeed += (self.LevelStats.BaseSpeed * self.Level)
	end

	local BaseJump = self.BaseStats.BaseJump
	if self.LevelStats.BaseJump then
		BaseJump += (self.LevelStats.BaseJump * self.Level)
	end

	self.Damage = IterateModifiers(self, BaseDamage, { Tags.Calculations.CalcDamageStat })
	self.Armor = IterateModifiers(self, BaseArmor, { Tags.Calculations.CalcArmorStat })
	self.OriginHumanoid.MaxHealth = IterateModifiers(self, BaseHealth, { Tags.Calculations.CalcMaxHealth })
	self.OriginHumanoid.Health = self.OriginHumanoid.MaxHealth * ratio
	self.OriginHumanoid.WalkSpeed = IterateModifiers(self, BaseSpeed, { Tags.Calculations.CalcSpeedStat })
	self.OriginHumanoid.JumpHeight = IterateModifiers(self, BaseJump, { Tags.Calculations.CalcJumpHeight })

	if self:IsPlayer() then
		Remotes["Game Functions"].AlertHumanoidModChange:FireClient(
			game.Players:GetPlayerFromCharacter(self.OriginHumanoid.Parent)
		)
	end
end

-------- MODIFIER HANDLING FUNCTIONS

function RegisteredHumanoid:AddModifier(mod_ID, amount: number) -- adds a specified amount of a modifier to the registered humanoid's mod storage
	local mod = ModData[mod_ID]

	if mod then
		if self.Modifiers[mod_ID] then -- add stacks if you have the mod
			self.Modifiers[mod_ID].Stacks += amount
		else -- add a new mod if you dont have it
			self.Modifiers[mod_ID] = mod
			self.Modifiers[mod_ID].Stacks = amount
		end
	else
		warn("No modifier found. Please check that you are inputting the correct mod ID.")
	end

	self:RecalulateStats()
end

function RegisteredHumanoid:SubtractModifier(mod_ID, amount: number) -- subtracts the specified amount of a given modifier
	local mod = ModData[mod_ID]

	if mod and self.Modifiers[mod_ID] then
		self.Modifiers[mod_ID].Stacks -= amount

		if self.Modifiers[mod_ID].Stacks <= 0 then
			self.Modifiers[mod_ID] = nil
		end
	end

	self:RecalulateStats()
end

-------- AFFLICTION HANDLING FUNCTIONS

function RegisteredHumanoid:AddAffliction(affliction_ID, amount: number, lifetime: number, data: {})
	local affliction = AfflictionData[affliction_ID]

	if affliction then
		if self.Afflictions[affliction_ID] then -- checks if you already have the affliction
			if affliction.Stackable then -- stacks if possible
				self.Afflictions[affliction_ID].Stacks += amount
			end

			if affliction.IsTimed and not affliction.GlobalTime and lifetime then -- updates time if possible
				self.Afflictions[affliction_ID].Time += lifetime
			end

			if affliction.Data then
				for entry, info in pairs(affliction.Data) do
					if data[entry] then
						affliction.Data[entry] = info
					end
				end
			end
		else -- in case you do not have the affliction
			self.Afflictions[affliction_ID] = affliction -- inserts the afflictions

			self.Afflictions[affliction_ID].Applied = workspace:GetServerTimeNow() -- setting timers
			self.Afflictions[affliction_ID].LastTick = workspace:GetServerTimeNow()

			if affliction.Stackable then -- only stacks past 1 if it is stackable
				self.Afflictions[affliction_ID].Stacks = amount
			else
				self.Afflictions[affliction_ID].Stacks = 1
			end

			-- sets the time variable based on the afflictions configuration
			if affliction.GlobalTime then -- checks for a global constant lifetime
				self.Afflictions[affliction_ID].Time = affliction.GlobalTime
			elseif affliction.IsTimed then -- checks if the affliction is timed
				self.Afflictions[affliction_ID].Time = lifetime
			else -- otherwise sets the affliction to not be timed
				self.Afflictions[affliction_ID].Time = -1
			end

			if data then
				affliction.Data = data
			end
		end

		if affliction.ApplyFunction then
			affliction.ApplyFunction(self, self.Afflictions[affliction_ID].Stacks) -- plays the remove function
		end
	else
		warn("No affliction found. Please check that you are inputting the correct affliction ID.")
	end

	self:RecalulateStats()
end

function RegisteredHumanoid:SubtractAffliction(affliction_ID, amount: number)
	local affliction = AfflictionData[affliction_ID]

	if affliction and self.Afflictions[affliction_ID] then -- if it exists and you have it
		if affliction.RemoveFunction then
			affliction.RemoveFunction(self, self.Afflictions[affliction_ID].Stacks) -- plays the remove function
		end

		self.Afflictions[affliction_ID].Stacks -= amount -- removes the affliction

		if self.Afflictions[affliction_ID].Stacks <= 0 then -- removes the debuff if nothing is left
			self.Afflictions[affliction_ID] = nil
		end
	end

	self:RecalulateStats()
end

function RegisteredHumanoid:ClearAffliction(affliction_ID)
	local affliction = AfflictionData[affliction_ID]

	if affliction and self.Afflictions[affliction_ID] then -- if it exists and you have it
		if affliction.RemoveFunction then
			affliction.RemoveFunction(self, self.Afflictions[affliction_ID].Stacks) -- plays the remove function
		end

		self.Afflictions[affliction_ID] = nil -- removes affliction
	end

	self:RecalulateStats()
end

-------- HUMANOID ACTIONS

-- this is the same as iterate modifiers, but it doesnt take an input and doesnt return an output
-- stuff that is triggered this way 100% needs to be designed to be used that way
function RegisteredHumanoid:TriggerModifiers(tags: {})
	local usedMods = {}
	for name, modifier in pairs(self.Modifiers) do
		for __, tag in pairs(modifier.Tags) do
			if table.find(tags, tag) then
				usedMods[name] = modifier
			end
		end
	end

	for _, mod in pairs(usedMods) do
		if mod.TriggerFunction then
			mod.TriggerFunction(self, mod.Stacks, tags)
		end
	end

	local usedAfflictions = {}
	for name, affliction in pairs(self.Afflictions) do
		for __, tag in pairs(affliction.Tags) do
			if table.find(tags, tag) then
				usedAfflictions[name] = affliction
			end
		end
	end

	for _, affliction in pairs(usedAfflictions) do
		if affliction.TriggerFunction then
			affliction.TriggerFunction(self, affliction.Stacks, tags)
		end
	end
end

function RegisteredHumanoid:ChangeLevel(amount: number)
	self.Level += amount
	self:RecalculateStats()
end

function RegisteredHumanoid:SetLevel(level: number)
	self.Level = level
	self:RecalculateStats()
end

-- applies a burst of force over a fixed amount of time
function RegisteredHumanoid:ApplyKnockback(dir: Vector3, power: number)
	local HRP = self.OriginHumanoid.Parent.PrimaryPart

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

	if not self:IsPlayer() then
		Batcher.Remotes["ReplicateKnockback"]:FireAllClients(Serialization.WriteKnockbackPacket(self.ID, dir, power))
	end
end

-- applies a burst of force pointed away from a specified position
function RegisteredHumanoid:ApplyPulse(position: Vector3, power: number)
	local HRP = self.OriginHumanoid.Parent.PrimaryPart

	local att = Instance.new("Attachment")
	att.Parent = HRP
	local force = Instance.new("LinearVelocity")
	force.Parent = att

	local dir = CFrame.lookAt(position, HRP.Position).LookVector

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

	if not self:IsPlayer() then
		Batcher.Remotes["ReplicateKnockback"]:FireAllClients(Serialization.WriteKnockbackPacket(self.ID, dir, power))
	end
end

-- function used to deal damage to a humanoid, uses modifiers
function RegisteredHumanoid:TakeDamage(amount: number, source, numindex: number)
	-- damage calculation
	local dealt_damage = amount

	if source then
		dealt_damage = IterateModifiers(source, dealt_damage, { Tags.Calculations.DealDamageCalc })
	else
		warn("No source detected. Damage will be dealt without modification.")
	end

	dealt_damage = IterateModifiers(self, dealt_damage, { Tags.Calculations.RecieveDamageCalc })
	dealt_damage *= (1 - self.Armor / (100 + math.abs(self.Armor)))

	self.OriginHumanoid:TakeDamage(dealt_damage)

	-- visual feedback
	if source:IsPlayer() then
		Batcher.Remotes["ReplicateDamage"]:FireAllClients(Serialization.WriteHitPacket(self.ID, numindex, dealt_damage))
	end
end

-------- GETTERS/CHECKS AND OTHER STUFF

function RegisteredHumanoid:IsPlayer() -- simply checks if the registered humanoid belongs to a player
	return game.Players:GetPlayerFromCharacter(self.OriginHumanoid.Parent)
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------- PLAYER FUNCTIONS
------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- these should only be used (and will only work) on registered humanoids tied to a specific player
-- a lot of this is just skill cooldown stuff, since npc humanoids dont use skills
-- the server and client also both need to interact for skill cooldown stuff, so theres all this malarky

function RegisteredHumanoid:CalcSkillStacks(slot: string) -- calculates your max stacks for a skill
	if self:IsPlayer() then
		local new_stacks = self.SkillData[slot]["BaseStacks"]
		new_stacks = IterateModifiers(self, new_stacks, { Tags.Calculations.ExtraStacksCalc[slot] })
		return new_stacks
	else
		warn(
			"This method is player-only. Please do not call this method if the registered humanoid does not belong to a player!"
		)
	end
	return nil
end

function RegisteredHumanoid:CalcSkillCooldown(slot: string) -- calculates your cooldown for a skill
	if self:IsPlayer() then
		local new_cooldown = self.SkillData[slot]["BaseCooldown"]
		new_cooldown = IterateModifiers(self, new_cooldown, { Tags.Calculations.SkillCooldownCalc[slot] })
		return new_cooldown
	else
		warn(
			"This method is player-only. Please do not call this method if the registered humanoid does not belong to a player!"
		)
	end
	return nil
end

function RegisteredHumanoid:SetSkillData(data: {}) -- sets a humanoids skill data, which is used for cooldowns mainly
	if self:IsPlayer() then
		for slot, skill_data in pairs(data) do
			self.SkillData[slot] = skill_data
		end
	else
		warn(
			"This method is player-only. Please do not call this method if the registered humanoid does not belong to a player!"
		)
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------- REGISTER/UNREGISTER FUNCTIONS
------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- these are tied to bindable events so nothing breaks across threads
-- its one central pipeline all the data can come through, that way everyone gets the same copy of the registry
-- i wouldnt recommend messing with this, come get me if you think the issue requires changing anything here

script.Parent.Register.Event:Connect(
	function(hum: Humanoid, configuration: Types.HumanoidConfiguration, team: number | string) -- register
		if Registry.Humanoids[hum] then -- if a humanoid already exists in the registry, don't register again
			warn(
				"This humanoid has already been registered! Don't register multiple of the same humanoid you dimwit..."
			)
			return
		end

		if not hum.Parent then
			return
		end
		if not hum.Parent:IsA("Model") then
			return
		end

		-- these are the default values shared by every single registered humanoid instance

		local Registered = setmetatable({
			Name = "Undisclosed",
			Level = 0,
			Team = Tags.Teams.None,

			Damage = 2,
			Armor = 0,
			BaseStats = placeholder_config.BaseStats,
			LevelStats = placeholder_config.LevelStats,

			ID = RegisterNewID(hum),
			OriginHumanoid = hum, -- humanoid provided to register
			Root = hum.Parent:FindFirstChild("HumanoidRootPart"), -- root of the npc model

			Modifiers = {}, -- holder of the humanoids modifiers
			Afflictions = {}, -- holder of the humanoids afflictions
			Tags = {}, -- tags that can be given to a registered humanoid, and read by other scripts

			Trove = Trove.new(),
		}, RegisteredHumanoid)
		hum.UseJumpPower = false

		-- initializes the values for the registered humanoid based off what is provided in the configuration
		if configuration then
			if configuration.BaseStats then
				Registered:Initialize(configuration.BaseStats)
			else
				Registered:Initialize(placeholder_config.BaseStats) -- this should never be used
			end

			if configuration.LevelStats then
				Registered.LevelStats = configuration.LevelStats
			end

			if configuration.Tags then
				Registered.Tags = configuration.Tags
			end
		end

		-- assigns a team regardless of what you provide, as well as adding it to its team list
		Registered:SetTeam(team)

		-- if the humanoid is one belonging to a player, initializes the player's skill data
		if Registered:IsPlayer() then
			Registered.SkillData = {
				[Tags.SkillSlots.Primary] = {
					["BaseCooldown"] = 0,
					["BaseStacks"] = 0,
				},

				[Tags.SkillSlots.Secondary] = {
					["BaseCooldown"] = 0,
					["BaseStacks"] = 0,
				},

				[Tags.SkillSlots.ShortUtility] = {
					["BaseCooldown"] = 0,
					["BaseStacks"] = 0,
				},

				[Tags.SkillSlots.Utility] = {
					["BaseCooldown"] = 0,
					["BaseStacks"] = 0,
				},

				[Tags.SkillSlots.Special] = {
					["BaseCooldown"] = 0,
					["BaseStacks"] = 0,
				},
			}
		end

		-- adds all the stuff that needs cleaning to the humanoid's trove
		-- everything in the trove is deleted after the humanoid is unregistered
		Registered.Trove:Add(hum.Parent)

		-- enters the humanoid into the big registry list
		Registry.Humanoids[Registered.OriginHumanoid] = Registered
	end
)

script.Parent.Unregister.Event:Connect(function() -- unregister
end)

return {
	Registry = Registry,
	IDs = RegisteredIDs,
}
