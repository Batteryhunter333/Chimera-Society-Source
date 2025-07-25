export type BaseStats = {
	Name: string | nil,
	BaseHealth: number,
	BaseDamage: number,
	BaseArmor: number,
	BaseSpeed: number,
	BaseJump: number,
}

export type HumanoidConfiguration = {
	BaseStats: BaseStats, -- base stats of the humanoid
	LevelStats: BaseStats, -- stats gained per level
	Tags: { string }, -- extra tags for the humanoid that can be read by scripts
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
	ModuleFamily: Folder, -- specified here so nothing breaks
	ModelFamily: Folder,

	Variants: { NPCVariant }, -- list of all the variants of the npc, this often could just have one entry
	Maps: {}, -- places where the npc can spawn, used really just for enemy spawns
}

export type NPCVariant = {
	ModuleName: string, -- using strings so nothing breaks with tryna call values that dont exist on the client
	ModelName: string,
	Configuration: HumanoidConfiguration,
	Actions: {}, -- indexes for an npcs actions on the client
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

	Tags: { string },
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

	Tags: { string },
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
	AgentSupportPartialPath: boolean,
	WaypointSpacing: number,
	Costs: { [string]: number }?,
	PathSettings: {
		SupportPartialPath: boolean,
	},
}

export type NPCInstance = {
	Root: BasePart,
	Humanoid: Humanoid,
	Model: Model,
	ID: string,

	TargetInstance: Model | nil,
	CurrentPath: Path,
	CurrentWaypoint: number,
	WaypointDeb: boolean,

	PathingState: number,
	PathingConnection: RBXScriptConnection,

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
	Value: number | nil,
	Position: Vector3 | nil,
	Random: number | nil,
	Drift: number | nil,
	Weight: number | nil,
	Scale: number | nil,
	MainColor: Color3 | nil,
	StrokeColor: Color3 | nil,
	Brightness: number | nil,
	Font: Enum.Font | nil,
}

return {}
