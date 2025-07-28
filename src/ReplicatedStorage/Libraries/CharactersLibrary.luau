-- the model in replicated storage has an ID tag that gets set to the id assigned here
local Types = require(game.ReplicatedStorage.Libraries.Types)
local Tags = require(game.ReplicatedStorage.Libraries.Tags)
local Characters = game.ReplicatedStorage.SharedAssets.Characters

local characters: { Types.CharacterData } = {
	["ConcreteMan"] = {

		CharacterScripts = Characters.Scripts["Concrete Man"],
		CharacterSkins = Characters.Models["Concrete Man"],

		HealthbarIcon = "rbxassetid://118693043360000",
		DamagedIcon = "rbxassetid://117696618639414",
		DeathIcon = "rbxassetid://113704589856808",
		TalkIcon = "rbxassetid://138089956153567",

		Configuration = {
			BaseStats = {
				Name = "Concrete Man",
				BaseHealth = 75,
				BaseDamage = 2,
				BaseArmor = 10,
				BaseSpeed = 16,
				BaseJump = 7.2,
			},

			Tags = {},
		},
	},

	["Remedy"] = {
		CharacterScripts = Characters.Scripts.Remedy,
		CharacterSkins = Characters.Models.Remedy,

		HealthbarIcon = "rbxassetid://118693043360000",
		DamagedIcon = "rbxassetid://117696618639414",
		DeathIcon = "rbxassetid://113704589856808",
		TalkIcon = "rbxassetid://138089956153567",

		Configuration = {
			BaseStats = {
				Name = "Remedy",
				BaseHealth = 50,
				BaseDamage = 3.5,
				BaseArmor = 5,
				BaseSpeed = 22,
				BaseJump = 8,
			},

			Tags = { Tags.HumanoidAttributes.Conductive },
		},
	},
}

for index, char in pairs(characters) do
	char.ID = index

	for _, skin in pairs(char.CharacterSkins:GetChildren()) do
		skin:SetAttribute("ID", char.ID)
		skin:SetAttribute("Skin", skin.Name)
	end
end

return characters
