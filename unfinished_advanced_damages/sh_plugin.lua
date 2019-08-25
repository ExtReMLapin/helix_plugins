
local PLUGIN = PLUGIN

PLUGIN.name = "Advanced damages"
PLUGIN.author = "ExtReM Lapin"
PLUGIN.description = "New damage system, broken legs, headshots etc"

if not ix.plugin.Get("runspeed") then ErrorNoHalt("The plugin runspeed is missing") end

ix.config.Add("fallDamageScale", 2, "The fall damages multiplier scale", nil, {
	data = {min = 0.1, max = 10, decimals = 1},
	category = "Advanced Damages"
})

ix.config.Add("headshotDamageScale", 3, "Headshots damages multiplier scale", nil, {
	data = {min = 1, max = 10, decimals = 1},
	category = "Advanced Damages"
})

ix.config.Add("DamageBreakLeg", 30, "How much damage (after being scaled) to break a leg", nil, {
	data = {min = 1, max = 100, decimals = 0},
	category = "Advanced Damages"
})

ix.config.Add("DamageBreakArm", 30, "How much damage (after being scaled) to break an arm", nil, {
	data = {min = 1, max = 100, decimals = 0},
	category = "Advanced Damages"
})

ix.config.Add("headDamageBrainTrauma", 50, "How much head damage (after being scaled) to trigger a brain damage", nil, {
	data = {min = 1, max = 100, decimals = 0},
	category = "Advanced Damages"
})

ix.config.Add("damageOnBokenMemberMult", 2, "Multiplier of damage took on a broken member (Added to already existing damages).\nFor example, if you take 10 of fall damage and 60% of the fall damage was absorbed by your left broken leg, with a value at 2 you'll get\n10 + (10*0.6*2) = 22 pts of damages.", nil, {
	data = {min = 0, max = 10, decimals = 0},
	category = "Advanced Damages"
})

ix.config.Add("rightArmShotDropWeapon", true, "When the right arm is shot, the player will drop his weapon.", nil, {
	category = "Advanced Damages"
})

ix.config.Add("damagesNoisesAndVoices", true, "Make the player talk or scream when he get a special damage even like a broken leg, brain trauma or shot in the arm.", nil, {
	category = "Advanced Damages"
})

ix.config.Add("percentageSlowDownPerBrokenLeg", 30, "By how much percent we should reduce the player speed for each broken leg. (50 >= can't move with both legs broken)", nil, {
	data = {min = 0, max = 80, decimals = 0},
	category = "Advanced Damages"
})

ix.char.RegisterVar("brokenLeftLeg", {
	field = "brokenLeftLeg",
	fieldType = ix.type.bool,
	default = false,
	isLocal = false,
})

ix.char.RegisterVar("brokenRightLeg", {
	field = "brokenRightLeg",
	fieldType = ix.type.bool,
	default = false,
	isLocal = false,
})

ix.char.RegisterVar("brokenLeftArm", {
	field = "brokenLeftLeg",
	fieldType = ix.type.bool,
	default = false,
	isLocal = false,
})

ix.char.RegisterVar("brokenRightArm", {
	field = "brokenRightLeg",
	fieldType = ix.type.bool,
	default = false,
	isLocal = false,
})

ix.char.RegisterVar("brainTrauma", {
	field = "brainTrauma",
	fieldType = ix.type.bool,
	default = false,
	isLocal = false,
})

ix.util.Include("sv_plugin.lua")
ix.util.Include("cl_plugin.lua")