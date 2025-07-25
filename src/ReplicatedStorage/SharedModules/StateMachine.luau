-- oh, these guys? theyre the state machines!
-- theyre broadly applicable, generally useful, and fully customizable (they looooove running a function)
-- the type below shows you how states should be set up when youre creating some to pass to a state machine
-- remember that the first state on a state table that you pass a state machine WILL become the default state unless specified otherwise
-- while you should try to just define all your states in one go when making a new state machine, this code DOES allow for more to be added
-- (the method to add extra states is literally just the define code but without the line that makes you default to the first state in the list)

export type State = { -- type stuff for states, just outlines what all they have
	Name: string,
	Duration: number,
	Static: boolean, -- sets if the state can be overwritten once added (you can still alter the properties of static states, this is just about their index)
	Started: ({}) -> (), -- btw this little setup with the arrow just means function input and output
	Stepped: ({}) -> (),
	Completed: ({}) -> (),
	Enter: (string) -> boolean, -- this is a simple return function that you can use to define the names of what states are allowed to enter this new one
	ExitState: string, -- string where you put the name of the state that the new state should exit into (put nothing for default)
	Data: {},
	Visible: boolean, -- this is a weird misc thing you can set if you dont want the state to be found by certain functions
}

local StateMachine = {}
StateMachine.__index = StateMachine

local runningStateMachines = {}

function StateMachine.new() -- creating a state machine class
	local self = setmetatable({ -- THESE ARE NOT IMPORTANT ON THEIR OWN THEY ARE HERE TO BE USED LATER
		States = {},
		CurrentState = "",
		DefaultState = "",
		LastUpdate = 0,

		_startTime = 0,
		_duration = 0,

		Data = {},
	}, StateMachine)

	return self
end

function StateMachine:DefineStates(states: { State }, default: string, start: string) -- function to define the states for a set machine
	for _, state in states do
		self.States[state.Name] = state
	end

	if start then -- sets starting state
		self.CurrentState = self.States[start].Name
	else
		self.CurrentState = states[1].Name
	end

	if default then -- sets default state
		self.DefaultState = self.States[default].Name
	else
		self.DefaultState = states[1].Name
	end
end

function StateMachine:AddStates(states: { State }) -- this lets you add extra states later, BE CAREFUL ABOUT HOW YOU USE THIS
	for _, state in states do
		self.States[state.Name] = state
	end
end

function StateMachine:OverwriteState(index: string, state: State) -- overwrites a nonstatic state at the index provided
	if self.States[index].Static then
		return
	end

	self.States[index] = state
end

function StateMachine:UpdateStateDuration(state: string, duration: number) -- pass this a function to change how the duration for the chosen state is calculated
	self.States[state].Duration = duration
end

function StateMachine:Set(state_name: string) -- checks if you can go from one state to another, then transitions into the provided state if possible
	local old_state_name = self.CurrentState
	local old_state: State = self.States[old_state_name]
	local new_state: State = self.States[state_name]

	if not new_state then
		return
	end

	-- checks if you can transition
	-- this defaults to true, meaning it will change the state, but you can change this using a states enter function
	-- this is useful if you dont wanna let one state enter another or something (obviously)
	local valid = true
	if new_state.Enter then
		valid = new_state.Enter(old_state_name)
	end

	-- transitions you if possible
	if valid then
		self.CurrentState = state_name
		self._duration = new_state.Duration
		self._startTime = workspace:GetServerTimeNow()

		if old_state.Completed then -- completes old state first
			old_state.Completed(self)
		end

		if new_state.Started then -- starts new state
			new_state.Started(self)
		end
	else
		self.CurrentState = old_state_name -- does nothing if the transition isnt valid
	end
end

function StateMachine:Interrupt(state_name: string) -- this is the same function as above, but it does not fire the complete event for the old state
	local old_state_name = self.CurrentState
	local new_state: State = self.States[state_name]

	if not new_state then
		return
	end

	local valid = true
	if new_state.Enter then
		valid = new_state.Enter(old_state_name)
	end

	if valid then
		self.CurrentState = state_name
		self._duration = new_state.Duration
		self._startTime = workspace:GetServerTimeNow()

		if new_state.Started then -- starts new state
			new_state.Started(self)
		end
	else
		self.CurrentState = old_state_name -- does nothing if the transition isnt valid
	end
end

function StateMachine:Update(interval: number) -- take a wild guess what this one does
	if self.CurrentState == nil then
		return
	end

	local t_now = workspace:GetServerTimeNow()
	local pm_elapsed_time = t_now - self._startTime -- gets the delta time for the state

	if interval then
		if t_now - self.LastUpdate < interval then
			return
		else
			self.LastUpdate = t_now
		end
	end

	local current_state: State = self.States[self.CurrentState]

	if self._duration == nil or self._duration == 0 or pm_elapsed_time < self._duration then -- if youre not past duration it runs the stepped function
		if current_state.Stepped then
			current_state.Stepped(self)
		end
	else -- otherwise it boots you out of the state, either to your exit state your the default value
		if current_state.ExitState then
			self:Set(current_state.ExitState)
		else
			self:Set(self.DefaultState)
		end
	end
end

function StateMachine:GetCompletionRatio()
	local t_now = workspace:GetServerTimeNow()
	local pm_elapsed_time = t_now - self._startTime

	if self._duration == nil or self._duration == 0 or pm_elapsed_time > self._duration then
		return 1
	else
		return pm_elapsed_time / self._duration
	end
end

function StateMachine:Run(interval: number)
	if interval then
		self.UpdateInterval = interval
		self.LastUpdate = workspace:GetServerTimeNow()
	end
	table.insert(runningStateMachines, self)
end

function StateMachine:Stop()
	table.remove(runningStateMachines, table.find(runningStateMachines, self))
end

function StateMachine:Destroy()
	self = nil
end

local function runStateMachines()
	while task.wait() do
		for _, machine in pairs(runningStateMachines) do
			if workspace:GetServerTimeNow() - machine.LastUpdate >= machine.UpdateInterval then
				machine:Update()
				machine.LastUpdate = workspace:GetServerTimeNow()
			end
		end
	end
end
task.spawn(runStateMachines)

return StateMachine
