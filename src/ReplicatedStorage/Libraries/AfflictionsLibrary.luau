local Types = require(game.ReplicatedStorage.Libraries.Types)
local Tags = require(game.ReplicatedStorage.Libraries.Tags)
local CalcTags = Tags.Calculations

local afflictions: { Types.AfflictionData } = {

	["TestAffliction"] = { -- testing affliction so i can make sure things are working
		Name = "Chronic  Wasting Disease",
		IsTimed = true,
		Stackable = true,
		StepRate = 1,

		Tags = { CalcTags.CalcMaxHealth },
		CalcFunction = function(subject: {}, stacks: number, input: number, tags: {})
			print(subject, stacks, tags)
			return input + 25
		end,

		ApplyFunction = function()
			print("it has begun")
		end,

		StepFunction = function()
			print("im wastinggggg")
		end,

		RemoveFunction = function()
			print("its over!")
		end,
	},
}

-- initialize affliction ids
-- same reason we initialize mod ids, if you wanna know more just go check that script
for i, affliction in pairs(afflictions) do
	affliction.ID = i
end

return afflictions
