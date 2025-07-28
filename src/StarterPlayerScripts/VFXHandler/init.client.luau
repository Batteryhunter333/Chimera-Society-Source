game.ReplicatedStorage.Remotes.VFX.CallVFX.OnClientEvent:Connect(function(calls) -- uses batching
	for _, call in pairs(calls) do
		local VFXname = call[1]
		local functionName = call[2]

		table.remove(call, 1)
		table.remove(call, 1)

		local module = require(script.VFXModules:WaitForChild(VFXname))
		module[functionName](call)
	end
end)

game.ReplicatedStorage.Remotes.VFX.CallVFXUnreliable.OnClientEvent:Connect(function(calls)
	for _, call in pairs(calls) do
		local VFXname = call[1]
		local functionName = call[2]

		table.remove(call, 1)
		table.remove(call, 1)

		local module = require(script.VFXModules:WaitForChild(VFXname))
		module[functionName](call)
	end
end)

script.Parent.Events.CallVFX.Event:Connect(function(VFXname, functionName, ...)
	local args = { ... }
	local module = require(script.VFXModules:WaitForChild(VFXname))
	module[functionName](args)
end)

--[[

Hi there! I don't know who will be reading this, likely just myself, but here's some info for you!
This whole system runs off of a tonnnn of information, which is why we have our args list.

* the first argument should be the name of the VFX module you wish to access.
* the second argument should be the name of the function you wish to access.
* all future arguments should just be all the arguments you wish to pass to the function. 
	- all of these arguments are packed into a table and passed to the module via the batcher

]]
-- remember these are the vfx you want to show everyone ELSE, not the player using them
-- the vfx the player sees are used immediately inside of the client skills module
