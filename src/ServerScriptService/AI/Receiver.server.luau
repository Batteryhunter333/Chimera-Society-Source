local Data = require(game.ReplicatedStorage.Libraries.NPCLibrary)

script.Parent:BindToMessage("Instantiate", function(NPC, Variant: string, frame: CFrame)
	local NPCData = Data[NPC]

	if NPCData then -- making sure you put a real npc
		local selected_variant

		for _, v in pairs(NPCData.Variants) do -- easy way to default to the first index of the variants list no matter what
			selected_variant = v
			break
		end

		if NPCData.Variants[Variant] then
			selected_variant = NPCData.Variants[Variant]
		else
			warn("Unable to find variant of " .. NPC .. ". Defaulting to first listed variant.")
		end

		local module = require(selected_variant.ControllerModule)
		if module then
			if frame then
				module.Instantiate(frame) -- spawn the variant of the enemy at the given cframe
			else
				warn("Missing spawn CFrame for variant.")
			end
		else
			warn("Unable to locate variant module.")
		end
	else
		warn("Unable to find NPC with name " .. NPC .. ". Make sure you are inputting correct data.")
	end
end)
