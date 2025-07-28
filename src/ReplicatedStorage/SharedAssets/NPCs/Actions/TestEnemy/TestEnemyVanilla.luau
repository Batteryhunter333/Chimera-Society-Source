local NPCs = require(game.ReplicatedStorage.Libraries.NPCLibrary)
local Actions = NPCs.TestEnemy.Variants.Vanilla.Actions

local actions = {
	[Actions.Death] = function()
		script.Parent.Humanoid.Health = 0
		task.wait(5)
		script.Parent:Destroy()
	end,
}

return actions
