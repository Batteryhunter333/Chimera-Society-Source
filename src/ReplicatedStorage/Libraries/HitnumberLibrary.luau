local types = require(game.ReplicatedStorage.Libraries.Types)

-- dont make more than 255 of these btw
-- i dont think that will happen, but if it does some stuff will break
local index = {
	Basic = 1,
}

local presets: { types.HitNumber } = {
	[index.Basic] = {
		Random = 0.5,
		Drift = 10,
		Weight = 5,
	},
}

return { index = index, presets = presets }
