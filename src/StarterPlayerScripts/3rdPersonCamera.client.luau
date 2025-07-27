task.wait(0.1)

local CAS = game:GetService("ContextActionService")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local cam = workspace.CurrentCamera
local plr = game.Players.LocalPlayer

local outMax = 30
local outMin = 4
local out = outMin + (outMax - outMin) / 5

local upMax = 4.5
local upMin = 2.5
local up = upMin + (upMax - upMin) / 5

local zoomFactor = 0.1
local offset = Vector3.new(0, up, out)
local offsetTarget = Vector3.new(0, up, out)

local toggleLockin = true
local faceCursor = false
cam.FieldOfView = 80

plr.CharacterAdded:Connect(function(char)
	local hum = char:WaitForChild("Humanoid")
	local root = char:WaitForChild("HumanoidRootPart")
	local camAngleX = 0
	local camAngleY = 0

	hum.AutoRotate = false

	local function updateCamAngle(_, inputState, inputObject)
		if inputState == Enum.UserInputState.Change then
			camAngleX -= inputObject.Delta.X
			camAngleY = math.clamp(camAngleY - inputObject.Delta.Y * 0.4, -75, 75)
		end
	end

	local function updateZoom(_, inputState, inputObject)
		if inputState == Enum.UserInputState.Change then
			local scrollChange = tonumber(inputObject.Position.Z)
			offsetTarget = Vector3.new(
				0,
				math.clamp(offsetTarget.Y - scrollChange * (upMax - upMin) * zoomFactor, upMin, upMax),
				math.clamp(offsetTarget.Z - scrollChange * (outMax - outMin) * zoomFactor, outMin, outMax)
			)
		end
	end

	CAS:BindAction("MouseMov", updateCamAngle, false, Enum.UserInputType.MouseMovement)
	CAS:BindAction("MouseScroll", updateZoom, false, Enum.UserInputType.MouseWheel)

	RS:BindToRenderStep("UpdateCam", Enum.RenderPriority.Camera.Value, function()
		local originCFrame = CFrame.new(root.CFrame.Position)
			* CFrame.Angles(0, math.rad(camAngleX), 0)
			* CFrame.Angles(math.rad(camAngleY), 0, 0)
		local camCFrame = originCFrame:PointToWorldSpace(offset)
		local camFocus = originCFrame:PointToWorldSpace(Vector3.new(offset.X, offset.Y, -100000))

		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { workspace.Info.CurrentMap.Value }
		local result = workspace:Raycast(originCFrame.Position, camCFrame - originCFrame.Position, params)
		if result then
			camCFrame = result.Position + (result.Normal * 0.15)
		end

		cam.CFrame = CFrame.lookAt(camCFrame, camFocus)

		local lookingCFrame = CFrame.lookAt(root.Position, cam.CFrame:PointToWorldSpace(Vector3.new(0, 0, -100000)))
		if hum.MoveDirection ~= Vector3.new(0, 0, 0) or faceCursor == true then
			root.CFrame =
				root.CFrame:Lerp(CFrame.fromMatrix(root.Position, lookingCFrame.XVector, root.CFrame.YVector), 0.2)
		end

		if math.abs(offset.Magnitude - offsetTarget.Magnitude) >= 0.05 then
			offset = offset:Lerp(offsetTarget, 0.3)
		else
			offset = offsetTarget
		end
	end)
end)

local function mouseLock(toggle)
	if toggle == true then
		cam.CameraType = Enum.CameraType.Scriptable
		UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
		UIS.MouseIconEnabled = false
	elseif toggle == false then
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		UIS.MouseIconEnabled = true
	end
end

UIS.InputBegan:Connect(function(input)
	if
		input.UserInputType == Enum.UserInputType.Focus
		or input.UserInputType == Enum.UserInputType.MouseButton1 and toggleLockin == true
	then
		mouseLock(true)
	end
end)
script.Parent.Events.ToggleCam.Event:Connect(function(state)
	toggleLockin = state
	mouseLock(state)
end)
