local HumanoidHandler = require(game.ServerScriptService.HumanoidManager)

local hum = script.Parent:FindFirstChildWhichIsA("Humanoid")
local registered_hum = HumanoidHandler.Get(hum)
print(registered_hum)

local rFunction = script.Parent.RemoteFunction

local rFunctions = {}

rFunction.OnServerInvoke = function(_, key, ...)
	return rFunctions[key](...)
end
