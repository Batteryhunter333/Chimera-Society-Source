local HumanoidManager = require(script.Parent)
local ServerEntities = workspace.Camera.EntitiesServer

ServerEntities.ChildAdded:Connect(function(child)
	local hum = child:FindFirstChildWhichIsA("Humanoid")

	if hum then
		local registered = HumanoidManager.Get(hum)

		hum.Died:Once(function()
			registered:Unregister()
		end)
	end
end)
