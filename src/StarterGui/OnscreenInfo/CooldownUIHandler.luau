local module = {}

function module.UpdateUI(Stacks: {}, Cooldowns: {})
	for slot, stacks in pairs(Stacks) do
		script.Parent.CooldownDisplays[slot].Outline.StacksDisplay.TextLabel.Text = stacks
	end

	for slot, cooldown in pairs(Cooldowns) do
		script.Parent.CooldownDisplays[slot].Icon.CooldownProgress.Size = UDim2.fromScale(1, 1 - cooldown)
	end
end

function module.SetIcons(Icons: {})
	for slot, icon in pairs(Icons) do
		script.Parent.CooldownDisplays[slot].Icon.Image = icon
	end
end

return module
