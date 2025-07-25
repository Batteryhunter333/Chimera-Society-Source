-- these are the tags used to differentiate modifiers
-- PLEASE reference this module instead of just putting strings as an input, this helps standardize things

local Context = {
	["Begin"] = "Begin",
	["End"] = "End",
}

local SkillSlots = {
	["Primary"] = "Primary",
	["Secondary"] = "Secondary",
	["ShortUtility"] = "ShortUtility",
	["Utility"] = "Utility",
	["Special"] = "Special",
}

local Teams = {
	["None"] = 0,
	["Player"] = 1,
	["Enemy"] = 2,
	["Spectator"] = 3,
}

local Calculations = {
	["DealDamageCalc"] = "DealDamage",
	["RecieveDamageCalc"] = "RecieveDamage",
	["OnHealCalc"] = "OnHealing",
	["OnKill"] = "OnKill",

	["ExtraStacksCalc"] = {
		["Primary"] = "StacksM1",
		["Secondary"] = "StacksM2",
		["ShortUtility"] = "StacksM3",
		["Utility"] = "StacksShift",
		["Special"] = "StacksR",
	},
	["SkillCooldownCalc"] = {
		["Primary"] = "CooldownM1",
		["Secondary"] = "CooldownM2",
		["ShortUtility"] = "CooldownM3",
		["Utility"] = "CooldownShift",
		["Special"] = "CooldownR",
	},

	["CalcDamageStat"] = "CalcDS",
	["CalcArmorStat"] = "CalcAS",
	["CalcMaxHealth"] = "CalcMHP",
	["CalcSpeedStat"] = "CalcSPD",
	["CalcJumpHeight"] = "CalcJMP",
}

local HumanoidAttributes = {
	["Conductive"] = "Conductive",
}

return {
	Context = Context,
	SkillSlots = SkillSlots,
	Teams = Teams,
	Calculations = Calculations,
	HumanoidAttributes = HumanoidAttributes,
}
