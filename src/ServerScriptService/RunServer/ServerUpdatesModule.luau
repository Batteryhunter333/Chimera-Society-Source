local updates = {}
local HumanoidHandler = require(game.ServerScriptService.HumanoidManager)
local Characters = require(game.ReplicatedStorage.Libraries.CharactersLibrary)
local Teams = require(game.ReplicatedStorage.Libraries.Tags).Teams

-- does what youd expect
-- be sure to update the libraries when you make a character, because this script assumes you did that already
function updates.ChangePlayerCharacterModel(player: Player, char_id, skin: string, location: CFrame)
	print(char_id)
	local character = Characters[char_id]

	-- finding and cloning the model for the character
	local model = character.CharacterSkins:GetChildren()[1]

	if character.CharacterSkins:FindFirstChild(skin) then
		model = character.CharacterSkins:FindFirstChild(skin)
	elseif character.CharacterSkins:FindFirstChild("Default") then
		model = character.CharacterSkins:FindFirstChild("Default")
	end

	local clone = model:Clone()

	-- copying the character scripts into the model
	for _, obj in pairs(character.CharacterScripts:GetChildren()) do
		obj:Clone().Parent = clone
	end

	-- registering the humanoid
	local hum = clone:FindFirstChildWhichIsA("Humanoid")
	HumanoidHandler.Register(hum, character.Configuration, Teams.Player)

	if location then
		clone:PivotTo(location)
	elseif player.Character then
		local HRP = player.Character:FindFirstChild("HumanoidRootPart")
		clone:FindFirstChild("HumanoidRootPart").CFrame = HRP.CFrame
	end

	-- initializing the rest of the needed values
	clone.Name = player.Name

	if player.Character then
		player.Character:Destroy()
	end

	player.Character = clone
	clone.Parent = workspace.Entities
end

return updates
