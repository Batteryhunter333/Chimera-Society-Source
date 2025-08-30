local StateMachine = require(game.ReplicatedStorage.SharedModules.StateMachine)
local HitDetection = require(game.ReplicatedStorage.SharedModules.HitDetection)
local ts = game:GetService("TweenService")

local SkillsLibrary = require(game.ReplicatedStorage.Libraries.SkillsLibrary)
local HitsLibrary = require(game.ReplicatedStorage.Libraries.HitnumberLibrary)
local Tags = require(game.ReplicatedStorage.Libraries.Tags)

local CallVFX = game.Players.LocalPlayer.PlayerScripts.Events.CallVFX
local SendDamage = game.ReplicatedStorage.Remotes["Game Functions"].SendDamage
local SendKnockback = game.ReplicatedStorage.Remotes["Game Functions"].SendKnockback

local skin = script.Parent:GetAttribute("Skin")
local troll = SkillsLibrary.CinderBlockThrow

local CharacterSkillStates: { StateMachine.State } = {
	{
		Name = SkillsLibrary.CinderBlockThrow.ID,
		Visible = true,

		Started = function()
			local character = game.Players.LocalPlayer.Character
			local hum = character:FindFirstChildWhichIsA("Humanoid")
			local ID = hum:GetAttribute("ID")
			print("hi")

			local hits = HitDetection.HitBoxOnce(
				CFrame.new(game.Players.LocalPlayer:GetMouse().Hit.Position),
				Vector3.new(3, 3, 3),
				true
			)
			hits = HitDetection.FilterHits(hits, HitDetection.FilteringTypes.PlayerHit)
			hits = HitDetection.ConvertToIDs(hits)
			SendDamage:FireServer(hits, ID, SkillsLibrary.CinderBlockThrow.Damage, HitsLibrary.index.Basic)
		end,

		Stepped = function() end,

		Completed = function() end,
	},

	{
		Name = SkillsLibrary.BlockDrop.ID,
		Visible = true,

		Completed = function()
			CallVFX:Fire("ConcreteManVFX", SkillsLibrary.BlockDrop.ID, game.Players.LocalPlayer:GetMouse().Hit, skin)
		end,
	},

	{
		Name = SkillsLibrary.ConcreteBlast.ID,
		Visible = true,

		Started = function()
			local character = game.Players.LocalPlayer.Character
			local HRP = character:FindFirstChild("HumanoidRootPart")
			local hum = character:FindFirstChildWhichIsA("Humanoid")
			local ID = hum:GetAttribute("ID")

			if HRP:IsA("BasePart") then
				CallVFX:Fire("ConcreteManVFX", SkillsLibrary.ConcreteBlast.ID, HRP, skin)

				ts:Create(
					HRP,
					TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
					{ Velocity = Vector3.new(150, 150, 150) * hum.MoveDirection + Vector3.new(0, 75, 0) }
				):Play()

				local hits = HitDetection.HitSphereOnce(HRP.Position, 10, true)
				hits = HitDetection.FilterHits(hits, HitDetection.FilteringTypes.PlayerHit)
				hits = HitDetection.ConvertToIDs(hits)
				SendDamage:FireServer(hits, ID, SkillsLibrary.ConcreteBlast.Damage, HitsLibrary.index.Basic)
				SendKnockback:FireServer(hits, HRP.Position, 200)
			end
		end,
	},
}

local LocalPlayer = game.Players.LocalPlayer
local LocalSkillSetter = LocalPlayer.PlayerScripts.Events.SetSkills

print(LocalSkillSetter)

LocalSkillSetter:Fire({
	[Tags.SkillSlots.Primary] = CharacterSkillStates[1],
	[Tags.SkillSlots.Secondary] = CharacterSkillStates[2],
	[Tags.SkillSlots.Utility] = CharacterSkillStates[3],
})
