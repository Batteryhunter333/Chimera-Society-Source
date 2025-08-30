-- this stores the internal names and info for the skills of various characters
-- the context values are also stored here, just to keep them standardized
-- PLEASE reference this module instead of just typing names randomly
-- !!ENSURE CHARACTERS SECTIONS ARE NAMED THE SAME AS
local Types = require(game.ReplicatedStorage.Libraries.Types)

local module = {}

local skills: { Types.SkillData } = { -- data for skills
	-------- Concrete Man
	CinderBlockThrow = {
		ID = "CinderBlockThrow",
		Name = "Heave",
		Cooldown = 0.1,
		BaseStacks = 1,
		Damage = 1.0,
		Icon = "rbxassetid://2673551132",
		VFXmodule = "ConcreteManVFX",
	},

	BlockDrop = {
		ID = "BlockDrop",
		Name = "Crush",
		Cooldown = 3,
		Damage = 3.5,
		Icon = "rbxassetid://15115263397",
		BaseStacks = 1,
		VFXmodule = "ConcreteManVFX",
	},

	ConcreteBlast = {
		ID = "ConcreteBlast",
		Name = "Thrust",
		Cooldown = 4,
		BaseStacks = 3,
		Damage = 4.5,
		Icon = "rbxassetid://2874491128",
		VFXmodule = "ConcreteManVFX",
	},

	ConcretePlaceholder = {
		ID = "ConcretePlaceholder",
		Name = "Does NOTHING LOL!!",
		Cooldown = 9,
		BaseStacks = 1,
		Damage = 2.0,
		Icon = "rbxassetid://647908715",
		VFXmodule = "ConcreteManVFX",
	},
}

function module.Test()
	print("Test")
end

function module.GetSkills()
	return skills
end

module.Skills = skills
return module
