local NPCs = require(game.ReplicatedStorage.Libraries.NPCLibrary).NPCData
local Actions = NPCs.TestEnemy.Variants.Vanilla.ActionsIndex

local actions = {
	[Actions.Death] = function()
		script.Parent.Humanoid.Health = 0
		task.wait(5)
		script.Parent:Destroy()
	end,
}

return actions
