local HumanoidManager = require(script.Parent)
local Registry = HumanoidManager.Registry

game["Run Service"].Stepped:Connect(function()
	for _, registered in pairs(Registry.Humanoids) do
		for id, affliction in pairs(registered.Afflictions) do
			if workspace:GetServerTimeNow() - affliction.LastTick >= affliction.StepRate then
				if affliction.StepFunction then
					affliction.StepFunction(registered, affliction.Stacks)
				end

				affliction.LastTick = workspace:GetServerTimeNow()
			end

			if workspace:GetServerTimeNow() - affliction.Applied >= affliction.Time then
				registered:ClearAffliction(id)
			end
		end
	end
end)
