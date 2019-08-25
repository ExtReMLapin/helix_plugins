local offsetVector = Vector(0, 0, 150)

local LeftmaxFeetAngle = 0.7071068
local RightmaxFeetAngle = -LeftmaxFeetAngle

local minTraceVector = Vector(-18, -18, 0)
local maxTraceVector = Vector(18, 18, 15)
local playerMeta = FindMetaTable("Player")

local voices = {}
voices.leg = {"vo/npc/male01/myleg01.wav", "vo/npc/male01/myleg02.wav"}
voices.arm = {"vo/npc/male01/myarm01.wav", "vo/npc/male01/myarm02.wav"}

local bonesDamageMult = {DMG_SLASH,
DMG_BLAST,
DMG_CLUB,
DMG_SHOCK,
DMG_ACID,
DMG_PLASMA,
DMG_BULLET,
DMG_BUCKSHOT,
DMG_DIRECT,
DMG_BUCKSHOT,
DMG_SNIPER,
DMG_MISSILEDEFENSE}

local function overrideHurtNoise(ply, type)
	local id = ply:SteamID64()
	local sound = table.Random(voices[type])

	hook.Add("GetPlayerPainSound", "nextFrameFix" .. id, function(client)
		if client == ply then return sound end
		hook.Remove("GetPlayerPainSound", "nextFrameFix" .. id)
	end)
end


function playerMeta:ApplyAdvancedDamagesModifiers(character)
	local mult = (100-ix.config.Get("percentageSlowDownPerBrokenLeg")) / 100
	if character:GetBrokenRightLeg() == true then
		self:UpdateWalkSpeedModifier("advDmgRightLeg", ix.plugin.list.runspeed.ModifierTypes.MULT, mult, true)
		self:UpdateRunSpeedModifier("advDmgRightLeg", ix.plugin.list.runspeed.ModifierTypes.MULT, mult, true)
	else
		self:RemoveWalkSpeedModifier("advDmgRightLeg", true)
		self:RemoveRunSpeedModifier("advDmgRightLeg", true)
	end

	if character:GetBrokenLeftLeg() == true then
		self:UpdateWalkSpeedModifier("advDmgLeftLeg", ix.plugin.list.runspeed.ModifierTypes.MULT, mult, true)
		self:UpdateRunSpeedModifier("advDmgLeftLeg", ix.plugin.list.runspeed.ModifierTypes.MULT, mult, true)
	else
		self:RemoveWalkSpeedModifier("advDmgLeftLeg", true)
		self:RemoveRunSpeedModifier("advDmgLeftLeg", true)
	end

	self:UpdateAdvancedRunSpeed()
	self:UpdateAdvancedWalkSpeed()


end



function PLUGIN:PostPlayerLoadout(client)
	local character = client:GetCharacter()
	client:ApplyAdvancedDamagesModifiers(character)
end

function PLUGIN:EntityTakeDamage(entity, dmgInfo)
	if not entity:IsPlayer() then return end
	if dmgInfo:IsFallDamage() then
		dmgInfo:ScaleDamage(ix.config.Get("fallDamageScale"))
		local amount = dmgInfo:GetDamage()

		local tr = util.TraceLine({
			start = entity:GetPos(),
			endpos = entity:GetPos() - offsetVector,
			filter = entity,
			mins = minTraceVector,
			maxs = maxTraceVector
		})

		local angle = tr.HitNormal
		local feetAngle = angle:Dot(entity:GetAngles():Right())
		local rightLegPercentage = math.max(0, math.Remap(feetAngle, 0, RightmaxFeetAngle, 0.5, 1))
		local leftLegPercentage = math.max(0, math.Remap(feetAngle, 0, LeftmaxFeetAngle, 0.5, 1))
		local rightLegDamage = rightLegPercentage * amount
		local leftLegDamage = leftLegPercentage * amount
		local character = entity:GetCharacter()
		local brokenRightLeg = character:GetBrokenRightLeg()
		local brokenLeftLeg = character:GetBrokenLeftLeg()
		local brokenLegMult = ix.config.Get("damageOnBokenMemberMult")

		if brokenRightLeg == true then
			dmgInfo:AddDamage(rightLegDamage * brokenLegMult)
		end

		if brokenLeftLeg == true then
			dmgInfo:AddDamage(leftLegDamage * brokenLegMult)
		end

		local brokeleg = false

		if rightLegDamage >= ix.config.Get("DamageBreakLeg") then
			character:SetBrokenRightLeg(true)
			brokeleg = true
		end

		if leftLegDamage >= ix.config.Get("DamageBreakLeg") then
			character:SetBrokenLeftLeg(true)
			brokeleg = true
		end

		if brokeleg == true then
			entity:ApplyAdvancedDamagesModifiers(character)
			if ix.config.Get("damagesNoisesAndVoices") == true then
				overrideHurtNoise(entity, "leg")
			end
		end
	end
end

function PLUGIN:ScalePlayerDamage(ply, hitgroup, dmgInfo)
	local found = false
	for k, v in ipairs(bonesDamageMult) do
		if dmgInfo:IsDamageType(v) then
			found = true
			break
		end
	end
	if not found then return end
	local character = ply:GetCharacter()


	if hitgroup == HITGROUP_RIGHTARM or hitgroup == HITGROUP_LEFTARM then

		local armdamage = dmgInfo:GetDamage()

		if armdamage >= ix.config.Get("DamageBreakArm") then

			if hitgroup == HITGROUP_RIGHTARM then
				character:SetBrokenRightArm(true)
			else
				character:SetBrokenLeftArm(true)
			end
		end
		if hitgroup == HITGROUP_RIGHTARM and ix.config.Get("rightArmShotDropWeapon") == true then
			local weapon = ply:GetActiveWeapon()
			local item = weapon.ixItem
			if (not IsValid(weapon) or not weapon.ixItem) then return end
			item:Unequip(ply)
			local ent = item:Transfer(nil, nil, nil, item.player)
			ent:SetAngles(ply:EyeAngles())
			ent:SetPos(ply:EyePos() + ply:GetAngles():Forward() * 20) -- meh
			ent:SetVelocity(ply:EyeAngles():Forward() * 250)
			--needs to be fixed
		end
	elseif hitgroup == HITGROUP_HEAD then
		dmgInfo:ScaleDamage(ix.config.Get("headshotDamageScale"))
		if character:GetBrainTrauma() == true then
			dmgInfo:ScaleDamage(ix.config.Get("damageOnBokenMemberMult"))
		elseif dmgInfo:GetDamage() >= ix.config.Get("headDamageBrainTrauma") then
			character:SetBrainTrauma(true)
		end
	elseif hitgroup == HITGROUP_RIGHTLEG or hitgroup == HITGROUP_LEFTLEG then

		local legdamage = dmgInfo:GetDamage()
		local brokenLegMult = ix.config.Get("damageOnBokenMemberMult")

		if legdamage >= ix.config.Get("DamageBreakLeg") then
			if HITGROUP_RIGHTLEG then
				if character:GetBrokenRightLeg() == true then
					dmgInfo:ScaleDamage(brokenLegMult)
				else
					character:SetBrokenRightLeg(true)
					ply:ApplyAdvancedDamagesModifiers(character)
				end
			else
				if character:GetBrokenLeftLeg() == true then
					dmgInfo:ScaleDamage(brokenLegMult)
				else
					character:SetBrokenLeftLeg(true)
					ply:ApplyAdvancedDamagesModifiers(character)
				end
			end

			if ix.config.Get("damagesNoisesAndVoices") == true then
				overrideHurtNoise(ply, "leg")
			end
		else
			if HITGROUP_RIGHTLEG then
				if character:GetBrokenRightLeg() == true then
					dmgInfo:ScaleDamage(brokenLegMult)
				end
			else
				if character:SetBrokenLeftLeg() == true then
					dmgInfo:ScaleDamage(brokenLegMult)
				end
			end
		end
	end
end

function PLUGIN:PlayerDeath(client, inflictor, attacker)
	local character = client:GetCharacter()
	character:SetBrainTrauma(false)
	character:SetBrokenRightLeg(false)
	character:SetBrokenLeftLeg(false)
	character:SetBrokenRightArm(false)
	character:SetBrokenLeftArm(false)
end

util.AddNetworkString("advancedDamagesOpenMenu")

function PLUGIN:ShowHelp(client)
	net.Start("advancedDamagesOpenMenu")
	net.Send(client)
end
