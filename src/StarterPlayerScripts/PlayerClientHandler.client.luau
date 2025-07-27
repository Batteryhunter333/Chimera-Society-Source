local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")

local plr = game.Players.LocalPlayer
local request_humanoid_info = game.ReplicatedStorage.Remotes["Game Functions"].RequestHumanoidData
local recalc_signal = game.ReplicatedStorage.Remotes["Game Functions"].AlertHumanoidModChange
local set_humanoid_skill_data = game.ReplicatedStorage.Remotes["Game Functions"].SetHumanoidSkillData

local stacks_deb = false

local SkillsLibrary = require(game.ReplicatedStorage.Libraries.SkillsLibrary)
local Tags = require(game.ReplicatedStorage.Libraries.Tags)
local StateMachine = require(game.ReplicatedStorage.SharedModules.StateMachine)
local CooldownUI = require(plr.PlayerGui.OnscreenInfo.CooldownUIHandler)

local SkillStateMachines = {}

-- these two tables just keep track of info related to each of the keys
local keybinds = {
	[Tags.SkillSlots.Primary] = Enum.UserInputType.MouseButton1,
	[Tags.SkillSlots.Secondary] = Enum.UserInputType.MouseButton2,
	[Tags.SkillSlots.ShortUtility] = Enum.UserInputType.MouseButton3,
	[Tags.SkillSlots.Utility] = Enum.KeyCode.LeftShift,
	[Tags.SkillSlots.Special] = Enum.KeyCode.R,
}

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------- SKILL STATE UTILITIES
------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- this is a loose group of functions used to make everything work properly for the state machines that control your skills

function ValidateSkillUse() -- used to check and ensure you arent actively using any other skills you shouldnt be
	for _, v in pairs(SkillStateMachines) do
		if v.CurrentState ~= "Neutral" and v.CurrentState ~= "Cooldown" then
			return false
		end
	end

	return true
end

function UpdateCooldown(slot) -- changes the duration of the cooldown state for the slot you specify via communication with the server
	local cooldown = request_humanoid_info:InvokeServer("CooldownCalc", slot)
	SkillStateMachines[slot]:UpdateStateDuration("Cooldown", cooldown)
end

function CalcMaxStacks(slot) -- calculates the max stats of a skill via communication with the server
	local extra_index = nil
	local states = SkillStateMachines[slot].States

	for i, _ in pairs(states) do
		if i ~= "Neutral" and i ~= "Cooldown" then
			extra_index = i
			break
		end
	end

	if extra_index then
		local new_stacks = request_humanoid_info:InvokeServer("StacksCalc", slot)
		states[extra_index].MaxStacks = new_stacks
	end
end

function EditStacks(slot, state, amount) -- this does what youd expect, this is specifically for skill states to sync them with a humanoids stats
	CalcMaxStacks(slot)

	SkillStateMachines[slot].States[state].Stacks += amount

	if SkillStateMachines[slot].States[state].Stacks > SkillStateMachines[slot].States[state].MaxStacks then
		SkillStateMachines[slot].States[state].Stacks = SkillStateMachines[slot].States[state].MaxStacks
	elseif SkillStateMachines[slot].States[state].Stacks < 0 then
		SkillStateMachines[slot].States[state].Stacks = 0
	end
end

recalc_signal.OnClientEvent:Connect(function()
	for slot, _ in pairs(SkillStateMachines) do
		UpdateCooldown(slot)
		CalcMaxStacks(slot)
	end
end)

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------- SKILL INPUT TRACKING
------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- these two scripts here just track inputs, firing when a skill key is pressed or released
-- genuinely its just ten billion checks to make sure things fire properly

UIS.InputBegan:Connect(function(input, processed: boolean) -- input begins
	if processed then
		return
	end -- doesnt run if the input was processed for some other roblox function
	if not ValidateSkillUse() then
		return
	end -- ensures youre actually allowed to use the skill

	for index, keybind in pairs(keybinds) do
		if
			(input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == keybind)
			or input.UserInputType == keybind
		then
			local current_skill = SkillStateMachines[index]

			local extra_index = nil
			for i, _ in pairs(current_skill.States) do
				if i ~= "Neutral" and i ~= "Cooldown" then
					extra_index = i
					break
				end
			end

			if
				(
					current_skill.CurrentState == "Neutral"
					or (current_skill.CurrentState == "Cooldown" and current_skill.States[extra_index].Stacks > 0)
				) and current_skill.States[extra_index]
			then
				current_skill:Set(current_skill.States[extra_index].Name)
				UpdateCooldown(index)
				EditStacks(index, extra_index, -1)
			end
		end
	end
end)

UIS.InputEnded:Connect(function(input, processed: boolean) -- input releases
	if processed then
		return
	end
	for index, keybind in pairs(keybinds) do
		if
			(input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == keybind)
			or input.UserInputType == keybind
		then
			local current_skill = SkillStateMachines[index]
			current_skill:Set("Cooldown")
		end
	end
end)

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------- SKILL SLOT SETUP
------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- this sets up independent state machines for every skill slot defined in the keybinds table above
-- this part of the script also handles skill utilities and other functions used to make skills work properly

for index, _ in pairs(keybinds) do
	local slot_machine = StateMachine.new()

	local default_states: { StateMachine.State } = { -- these are default states that all skills have
		{
			Name = "Neutral",
			Static = true,

			Stepped = function() -- checks to see if there are stacks missing, and replenishes them if possible
				local extra_index = nil

				for i, v in pairs(SkillStateMachines[index].States) do -- this just gets the index of the skills state
					if i ~= "Neutral" and i ~= "Cooldown" and v.Visible then
						extra_index = i
						break
					end
				end

				if extra_index then
					if
						SkillStateMachines[index].States[extra_index].Stacks
							~= SkillStateMachines[index].States[extra_index].MaxStacks
						and stacks_deb == false
					then
						stacks_deb = true
						EditStacks(index, extra_index, 1) -- replenishes a stack once the cooldown is off, if possible
						if
							SkillStateMachines[index].States[extra_index].Stacks
							~= SkillStateMachines[index].States[extra_index].MaxStacks
						then
							SkillStateMachines[index]:Interrupt("Cooldown")
						end
					end
				end
			end,

			Enter = function()
				return true
			end,
		},
		{
			Name = "Cooldown",
			Static = true,

			Completed = function()
				stacks_deb = false
			end,

			Enter = function(old_state)
				return (old_state ~= "Cooldown")
			end,

			ExitState = "Neutral",
		},
	}

	slot_machine:DefineStates(default_states)
	slot_machine:Run(0)
	SkillStateMachines[index] = slot_machine
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------- SKILL SETUP
------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- this deals with the actual skill data
-- above we set up the logic that controls the SLOTS skills go into
-- this properly sets up the actual skills

script.Parent.Events.SetSkills.Event:Connect(
	function(skill_states: { StateMachine.State }) -- gives your skill slot state machines the provided skill states
		local icons = {}
		local skill_data = {}

		for slot, state in pairs(skill_states) do
			local skill = SkillStateMachines[slot]

			for i = 1, #skill.States do
				if i > 2 then
					skill.States[i] = nil
				end
			end

			skill:UpdateStateDuration(skill.States["Cooldown"].Name, SkillsLibrary[state.Name].Cooldown)

			state.Stacks = SkillsLibrary[state.Name].BaseStacks
			state.MaxStacks = SkillsLibrary[state.Name].BaseStacks

			skill:AddStates({ state })
			skill:UpdateStateDuration(state.Name, nil)

			icons[slot] = SkillsLibrary[state.Name].Icon

			skill_data[slot] = {
				["BaseCooldown"] = SkillsLibrary[state.Name].Cooldown,
				["BaseStacks"] = SkillsLibrary[state.Name].BaseStacks,
			}
		end

		CooldownUI.SetIcons(icons) -- set cooldown ui icons
		set_humanoid_skill_data:FireServer(skill_data) -- put cooldown and stack data on the server to help prevent exploiting
	end
)

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------- UI MANAGEMENT
------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- this section of the script is for custom ui that is housed in this script
-- usually ui that requires some sort of info from other parts of the player will be housed here, like the cooldown ui

local function StepCooldownUI() -- basic step function for cooldown ui which syncs them with your applied skill state machines
	local stacks = {}
	local cooldowns = {}

	for slot, machine in pairs(SkillStateMachines) do -- really dense for loop nest to gather the stacks for each skill
		local extra_index = nil
		for i, _ in pairs(machine.States) do
			if i ~= "Neutral" and i ~= "Cooldown" then
				extra_index = i
				break
			end
		end

		if extra_index then
			stacks[slot] = machine.States[extra_index].Stacks
		end

		cooldowns[slot] = machine:GetCompletionRatio()
	end

	CooldownUI.UpdateUI(stacks, cooldowns) -- runs the update function for the cooldown ui
end
RS:BindToRenderStep("UpdateCooldownUI", 0, StepCooldownUI) -- sets the cooldown ui to update every frame
