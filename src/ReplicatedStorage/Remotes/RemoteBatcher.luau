local RS = game:GetService("RunService")

local Remotes = {}

local ServerQueue = {}
local ClientQueue = {}

-- batched remote object
local BatchedRemote = {}
BatchedRemote.__index = BatchedRemote

function BatchedRemote.new(remote: RemoteEvent)
	local self = setmetatable({
		Origin = remote,
	}, BatchedRemote)

	return self
end

function BatchedRemote:FireServer(...)
	table.insert(ServerQueue[self.Origin], { ... })
end

function BatchedRemote:FireClient(plr: Player, ...)
	if not ClientQueue[self.Origin.Name][plr] then
		ClientQueue[self.Origin.Name][plr] = {}
	end

	table.insert(ClientQueue[self.Origin.Name][plr], { ... })
end

function BatchedRemote:FireAllClients(...)
	if not ClientQueue[self.Origin.Name]["All"] then
		ClientQueue[self.Origin.Name]["All"] = {}
	end

	table.insert(ClientQueue[self.Origin.Name]["All"], { ... })
end

-- setup and handling
for _, obj in pairs(script.Parent:GetDescendants()) do -- setup to cover all the remotes inside of the remotes folder
	if obj:IsA("RemoteEvent") or obj:IsA("UnreliableRemoteEvent") then
		Remotes[obj.Name] = BatchedRemote.new(obj)
	end
end

if RS:IsServer() then
	for remote, _ in pairs(Remotes) do
		ClientQueue[remote] = {}
	end

	task.spawn(function()
		while task.wait(0.1) do
			for name, queues in pairs(ClientQueue) do
				for address, queue in pairs(queues) do
					if #queue > 0 then
						local remote = game.ReplicatedStorage.Remotes:FindFirstChild(name, true)

						if address == "All" then
							remote:FireAllClients(queue)
						else
							remote:FireClient(address, queue)
						end
						ClientQueue[name][address] = {}
					end
				end
			end
		end
	end)
else
	for remote, _ in pairs(Remotes) do
		ServerQueue[remote] = {}
	end

	task.spawn(function()
		while task.wait() do
			for remote, queue in pairs(ServerQueue) do
				if #queue > 0 then
					remote:FireServer(queue)
					ServerQueue[remote] = {}
				end
			end
		end
	end)
end

return {
	Remotes = Remotes,
	BatchedRemote = BatchedRemote,
}
