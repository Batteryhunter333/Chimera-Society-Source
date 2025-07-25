local Types = require(game.ReplicatedStorage.Libraries.Types)
local Models = game.ReplicatedStorage.NPCModels

local module: { Types.NPCData } = {

	-------- ENEMY NPC DATA
	-- actual enemies spawned by the game go here

	TestEnemy = {
		ID = "TestEnemy",
		ModuleFamily = "TestEnemy",
		ModelFamily = Models.TestEnemy,

		Variants = {
			Vanilla = { -- default variant
				ModuleName = "TestEnemyVanilla",
				ModelName = "TestEnemyVanilla",

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

				Actions = {
					Death = 0,
				},
			},
		},
	},

	-------- CUSTOM NPC DATA
	-- things like minions spawned by characters go here
	-- technically every npc in this module is custom but these guys dont spawn in naturally soooo
}

if game:GetService("RunService"):IsServer() then
	local Controllers = game.ServerScriptService.AI.Controllers

	for _, data in pairs(module) do
		data.ModuleFamily = Controllers:FindFirstChild(data.ModuleFamily)
	end
end

return module
