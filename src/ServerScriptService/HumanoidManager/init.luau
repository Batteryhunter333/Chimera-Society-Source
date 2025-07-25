local Types = require(game.ReplicatedStorage.Libraries.Types)

local Register = script.Register
local Unregister = script.Unregister

local HumanoidRegistry = require(script.HumanoidRegistry)
local Registry = HumanoidRegistry.Registry
local RegisteredIDs = HumanoidRegistry.IDs

local HumanoidHandler = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------- REGISTRY UTILITIES
------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- these are all just friendly abstractions of some internal stuff that the humanoid utils use
-- i split the functions into multiple scripts so i could use bindable events to ensure the registry stays put across threads
-- before i did this the registry would be different between different actors it was so bad

-- registers a roblox humanoid object to the registry, giving it all of the associated functions and whatnot
function HumanoidHandler.Register(hum: Humanoid, configuration: Types.HumanoidConfiguration, team: number | string)
	if configuration.BaseStats.Name then
		print("Registering a new " .. configuration.BaseStats.Name)
	end

	Register:Fire(hum, configuration, team)
end

-- tells the registry to take a humanoid out back and wipe it from the table
function HumanoidHandler.Unregister(hum: Humanoid)
	Unregister:Fire(hum)
end

-- this allows you to grab the specific registered version of a humanoid object
-- theres a bit of a delay in here to ensure the humanoid has been indexed
-- sometimes it takes a moment for humanoids to be registered, so this safeguards against you running the function too early
function HumanoidHandler.Get(hum: Humanoid)
	local step = 0

	repeat
		step += 1
		task.wait()
	until Registry.Humanoids[hum] or step > 100

	return Registry.Humanoids[hum]
end

function HumanoidHandler.GetFromID(ID: number)
	local step = 0

	repeat
		step += 1
		task.wait()
	until RegisteredIDs[ID] or step > 100

	return Registry.Humanoids[RegisteredIDs[ID]]
end

HumanoidHandler.IDs = RegisteredIDs
HumanoidHandler.Registry = Registry

return HumanoidHandler
