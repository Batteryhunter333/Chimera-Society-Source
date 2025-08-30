local Types = require(game.ReplicatedStorage.Libraries.Types)
local Models = game.ReplicatedStorage.SharedAssets.NPCs.Models
local Actions = game.ReplicatedStorage.SharedAssets.NPCs.Actions

local module: { Types.NPCData } = {

	-------- ENEMY NPC DATA
	-- actual enemies spawned by the game go here

	TestEnemy = {
		ID = "TestEnemy",

		Variants = {
			Vanilla = { -- default variant
				ControllerModule = nil,
				ActionsModule = Actions.TestEnemy.TestEnemyVanilla,
				Model = Models.TestEnemy.TestEnemyVanilla,

				Configuration = {
					BaseStats = {
						Name = "Reginald Matthews",
						BaseHealth = 30,
						BaseDamage = 5,
						BaseArmor = 0,
						BaseSpeed = 14,
						BaseJump = 8,
					},

					Tags = {},
				},

				ActionsIndex = {
					Death = 0,
				},
			},
		},
	},

	-------- CUSTOM NPC DATA
	-- things like minions spawned by characters go here
	-- technically every npc in this module is custom but these guys dont spawn in naturally soooo
}

if game:GetService("RunService"):IsServer() then -- init module families
	local Controllers = game.ServerScriptService.AI.Controllers

	for _, data in pairs(module) do
		for variant, info in pairs(data.Variants) do
			info.ControllerModule = Controllers:FindFirstChild(data.ID):FindFirstChild(data.ID .. variant)
		end
	end
end

return {
	NPCData = module,
}
