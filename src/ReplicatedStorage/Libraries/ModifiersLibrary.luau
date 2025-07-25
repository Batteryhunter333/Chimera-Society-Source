local Types = require(game.ReplicatedStorage.Libraries.Types)
local Tags = require(game.ReplicatedStorage.Libraries.Tags).Calculations

local mods: { Types.ModData } = {

	-------- ANY USE CASE MODS
	-- these are called through functions used on any registered humanoid

	["TestingDamageMult"] = { -- 10% damage mod
		Name = "Test Damage Buff",
		Tags = { Tags.DealDamageCalc },

		CalcFunction = function(subject, stacks, input, tags)
			print(subject, tags) -- so VSC doesnt yell at me
			return input * (1.1 ^ stacks)
		end,
	},

	["TestingDamageRes"] = { -- 5 damage reduction mod
		Name = "Test Damage Res",
		Tags = { Tags.RecieveDamageCalc },

		CalcFunction = function(subject, stacks, input, tags)
			print(subject, tags) -- so VSC doesnt yell at me
			return input - (5 * stacks)
		end,
	},

	-------- PLAYER ONLY MODS
	-- these are only called through functions used exclusively on players

	["TestingSecondaryCDR"] = { -- reduce secondary cooldown mod
		Name = "Test Secondary CDR",
		Tags = { Tags.SkillCooldownCalc.Secondary },

		CalcFunction = function(subject, stacks, input, tags)
			print(subject, tags) -- so VSC doesnt yell at me
			return input * (0.5 ^ stacks)
		end,
	},

	["TestingSecondaryStacking"] = { -- add extra secondary stack mod
		Name = "Test Secondary Stacking",
		Tags = { Tags.ExtraStacksCalc.Secondary },

		CalcFunction = function(subject, stacks, input, tags)
			print(subject, tags) -- so VSC doesnt yell at me
			return (input + stacks)
		end,
	},
}

-- initialize mod ids
-- we do this so we can send what mod we wanna reference to a script easily, if you dont wanna type the string
-- its a bit redundant, but it helps
for i, mod in pairs(mods) do
	mod.ID = i
end

return mods
