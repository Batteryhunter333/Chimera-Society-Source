local RS = game:GetService("RunService")
local characters = require(game.ReplicatedStorage.Libraries.CharactersLibrary)
local player = game.Players.LocalPlayer

local health_numbers = script.Parent.HealthbarDisplay.Health_Numbers
local health_fill = script.Parent.HealthbarDisplay.Bar_Fill
local health_gradient = health_fill.UIGradient
local char_icon = script.Parent.HealthbarDisplay.Character_Icon

local full_HP_color = Color3.fromRGB(0, 255, 127)
local mid_HP_color = Color3.fromRGB(255, 255, 127)
local low_HP_color = Color3.fromRGB(255, 0, 127)
local fade = 0.01

local function animateHealthbar()
	if player.Character:FindFirstChildWhichIsA("Humanoid") then
		local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")
		local ratio = humanoid.Health / humanoid.MaxHealth

		for _, char in pairs(characters) do -- handles what icon should be displayed on the health bar
			if char.ID == player.Character:GetAttribute("ID") then
				if humanoid.Health <= 0 then
					char_icon.Image = char.DeathIcon
				else
					char_icon.Image = char.HealthbarIcon
				end
			end
		end

		health_numbers.Text = math.floor(humanoid.Health) .. " / " .. math.floor(humanoid.MaxHealth) -- writes the numbers for the health bar

		if ratio >= 0 and ratio + fade <= 1 then -- decides what amount of the health bar should be full
			health_gradient.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0), -- start point
				NumberSequenceKeypoint.new(ratio, 0), -- sets the health bar to fill up based off % of hp you have
				NumberSequenceKeypoint.new(ratio + fade, 1), -- sets a little fade off
				NumberSequenceKeypoint.new(1, 1),
			}) -- end point
		else
			health_gradient.Transparency = NumberSequence.new(0)
		end

		if humanoid.Health / humanoid.MaxHealth >= 0.5 then -- handles the smooth color transition as your health gets lower
			health_fill.ImageColor3 = full_HP_color:Lerp(mid_HP_color, 2 - ratio * 2)
		else
			health_fill.ImageColor3 = mid_HP_color:Lerp(low_HP_color, 1 - (ratio - 0.5) * 2)
		end
	end
end

RS:BindToRenderStep("HealthbarUpdate", 0, animateHealthbar)
