local StateMachine = require(game.ReplicatedStorage.SharedModules.StateMachine)

export type BaseStats = {
	Name: string | nil,
	BaseHealth: number,
	BaseDamage: number,
	BaseArmor: number,
	BaseSpeed: number,
	BaseJump: number,
}

export type TargettingStats = {
	RigPriority: number,
	PlayerPriority: number,
	MinionPriority: number,
}

export type HumanoidConfiguration = {
	BaseStats: BaseStats, -- base stats of the humanoid
	LevelStats: BaseStats, -- stats gained per level
	TargettingStats: TargettingStats | nil,
	Tags: {}, -- extra tags for the humanoid that can be read by scripts
}

export type CharacterData = {
	ID: string, -- this should make the index of the character in the library
	CharacterScripts: Folder, -- their scripts and other code related objects inside of replicatedstorage
	CharacterSkins: Folder, -- skin models stored inside replicatedstorage

	HealthbarIcon: string,
	DamagedIcon: string,
	DeathIcon: string,
	TalkIcon: string,

	Configuration: HumanoidConfiguration,
}

export type NPCData = {
	ID: string, -- name of the folder in the ai controllers folder

	Variants: { NPCVariant }, -- list of all the variants of the npc, this often could just have one entry
	Maps: {}, -- places where the npc can spawn, used really just for enemy spawns
}

export type NPCVariant = {
	ControllerModule: ModuleScript,
	ActionsModule: ModuleScript,
	Model: Model,

	Configuration: HumanoidConfiguration,
	ActionsIndex: {}, -- indexes for an npcs actions on the client
}

export type NPCInitializer = {
	States: { StateMachine.State },
	InstanceConfiguration: NPCInstance,

	Initialize: (NPCInstance) -> (),
}

export type SkillData = { -- data type that stores all the skill info stuff
	ID: string,
	Name: string,
	Cooldown: number, -- seconds
	BaseStacks: number,
	Damage: number, -- percent of user's damage stat
	Icon: string,
	VFXmodule: string,
}

export type ModData = {
	ID: string,
	Name: string,

	Tags: {},
	Data: {},

	CalcFunction: (subject: {}, stacks: number, input: number, tags: {}) -> number,
	TriggerFunction: (subject: {}, stacks: number, tags: {}) -> (),
}

export type AfflictionData = {
	ID: string,
	Name: string,
	IsTimed: boolean,
	Stackable: boolean,
	StepRate: number,
	GlobalTime: number,

	Tags: {},
	Data: {},

	CalcFunction: (subject: {}, stacks: number, input: number, tags: {}) -> number,
	TriggerFunction: (subject: {}, stacks: number, tags: {}) -> (),

	ApplyFunction: (subject: {}, stacks: number) -> (),
	StepFunction: (subject: {}, stacks: number) -> (),
	RemoveFunction: (subject: {}, stacks: number) -> (),
}

export type AgentParameters = { -- these are parameters for handling things in the world
	AgentRadius: number,
	AgentHeight: number,
	AgentCanJump: boolean,
	AgentCanClimb: boolean,
	WaypointSpacing: number,
	Costs: { [string]: number }? | nil,
	PathSettings: {
		SupportPartialPath: boolean,
	},
}

export type NPCInstance = {
	Root: BasePart | nil,
	Humanoid: Humanoid | nil,
	Model: Model | nil,
	ID: string | nil,

	TargetInstance: Model | nil,
	CurrentPath: Path | nil,
	CurrentWaypoint: number | nil,
	WaypointDeb: boolean,

	PathingState: number,
	PathingConnection: RBXScriptConnection | nil,

	RecalcDelay: number,
	LastRecalc: number,

	Properties: {
		ViewDistance: number,
		ViewHeight: number,
		DetectRadius: number,

		FollowDistance: number,
		FollowHeightThreshold: number,

		HeadOffset: CFrame,
		RecalculateDistance: number,
		AgentParams: AgentParameters,
	},

	[string]: any,
}

export type HitNumber = {
	Value: number,
	Position: Vector3,
	Random: number,
	Drift: number,
	Weight: number,
	Scale: number,
	MainColor: Color3,
	StrokeColor: Color3,
	Brightness: number,
	Font: Enum.Font,
}

return {}
