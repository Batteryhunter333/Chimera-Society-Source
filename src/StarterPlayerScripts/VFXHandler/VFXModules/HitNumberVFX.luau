local debris = game.Debris
local ts = game:GetService("TweenService")
local MiscUtils = require(game.ReplicatedStorage.SharedModules.MiscUtils)
local Types = require(game.ReplicatedStorage.Libraries.Types)

local module = {}

function module.Create(args: {})
	local HitNumber: Types.HitNumber = table.unpack(args)

	local hitnumber = game.ReplicatedStorage.VFXAssets.System.HitNumber:Clone()
	hitnumber.Parent = workspace.Junk
	hitnumber.Position = HitNumber.Position
	if HitNumber.Random then
		hitnumber.Position += Vector3.new(
			(math.random() - 0.5) * HitNumber.Random,
			(math.random() - 0.5) * HitNumber.Random,
			(math.random() - 0.5) * HitNumber.Random
		)
	end

	hitnumber.Billboard.Number.Text = MiscUtils.TruncateNumber(HitNumber.Value)
	debris:AddItem(hitnumber, 1)

	-- custom appearance
	if HitNumber.Scale then
		hitnumber.Billboard.Size = UDim2.fromOffset(
			hitnumber.Billboard.Size.X.Offset * HitNumber.Scale,
			hitnumber.Billboard.Size.Y.Offset * HitNumber.Scale
		)
	end
	if HitNumber.MainColor then
		hitnumber.Billboard.Number.TextColor3 = HitNumber.MainColor
	end
	if HitNumber.StrokeColor then
		hitnumber.Billboard.Number.TextStrokeColor3 = HitNumber.StrokeColor
	end
	if HitNumber.Brightness then
		hitnumber.Billboard.Brightness = HitNumber.Brightness
	end
	if HitNumber.Font then
		hitnumber.Billboard.Number.Font = HitNumber.Font
	end

	-- motion
	if HitNumber.Drift then
		ts:Create(
			hitnumber,
			TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{
				Position = hitnumber.Position
					+ Vector3.new((math.random() - 0.5) * HitNumber.Drift, 1.5, (math.random() - 0.5) * HitNumber.Drift),
			}
		):Play()
	end

	-- enter animation
	if HitNumber.Weight then
		local rot = 5 * math.log(HitNumber.Weight - 1)
		local inflationX = 10 * HitNumber.Weight
		local inflationY = inflationX / 5

		hitnumber.Billboard.Number.Rotation += rot
		hitnumber.Billboard.Size = UDim2.fromOffset(
			hitnumber.Billboard.Size.X.Offset + inflationX,
			hitnumber.Billboard.Size.Y.Offset + inflationY
		)

		ts:Create(
			hitnumber.Billboard.Number,
			TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
			{ Rotation = 0 }
		):Play()
		ts:Create(
			hitnumber.Billboard,
			TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
			{ Size = hitnumber.Billboard.Size - UDim2.fromOffset(inflationX, inflationY) }
		):Play()
	end

	-- exit animation
	task.delay(0.5, function()
		ts:Create(
			hitnumber.Billboard.Number,
			TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ TextTransparency = 1, TextStrokeTransparency = 1 }
		):Play()
	end)
end

return module
