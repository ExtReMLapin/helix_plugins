DEFINE_BASECLASS("ixSubpanelParent")
local PANEL = {}
AccessorFunc(PANEL, "bCharacterOverview", "CharacterOverview", FORCE_BOOL)


local bonestable = {}
bonestable[HITGROUP_HEAD] = {}
bonestable[HITGROUP_HEAD][6] = true
bonestable[HITGROUP_RIGHTARM] = {}
bonestable[HITGROUP_RIGHTARM][9] = true
bonestable[HITGROUP_RIGHTARM][10] = true
bonestable[HITGROUP_RIGHTARM][11] = true
bonestable[HITGROUP_LEFTARM] = {}
bonestable[HITGROUP_LEFTARM][14] = true
bonestable[HITGROUP_LEFTARM][15] = true
bonestable[HITGROUP_LEFTARM][16] = true
bonestable[HITGROUP_RIGHTLEG] = {}
bonestable[HITGROUP_RIGHTLEG][18] = true
bonestable[HITGROUP_RIGHTLEG][19] = true
bonestable[HITGROUP_RIGHTLEG][20] = true
bonestable[HITGROUP_RIGHTLEG][21] = true
bonestable[HITGROUP_LEFTLEG] = {}
bonestable[HITGROUP_LEFTLEG][22] = true
bonestable[HITGROUP_LEFTLEG][23] = true
bonestable[HITGROUP_LEFTLEG][24] = true
bonestable[HITGROUP_LEFTLEG][25] = true
local non_generic_bones = {}

for bonegroup, bonetable in pairs(bonestable) do
	for boneid, validated in pairs(bonetable) do
		non_generic_bones[boneid] = true
	end
end

local vectorNomalScale = Vector(0.90, 0.90, 0.90)
local vectorZero = Vector(0, 0, 0)

local function prepareBoneRender(entity, bone_type)
	local count = entity:GetBoneCount()

	if bone_type == HITGROUP_GENERIC then
		local i = 0

		while (i < count) do
			if non_generic_bones[i] then
				entity:ManipulateBoneScale(i, vectorZero)
			else
				entity:ManipulateBoneScale(i, vectorNomalScale)
			end

			i = i + 1
		end

		return
	end

	local i = 0

	while (i < count) do
		if bonestable[bone_type][i] then
			entity:ManipulateBoneScale(i, vectorNomalScale)
		else
			entity:ManipulateBoneScale(i, vectorZero)
		end

		i = i + 1
	end
end

local function renderEntityBone(panel, boneid, width, height, r, g, b)
	--if boneid == false then return end
	ix.util.ResetStencilValues()
	render.SetStencilEnable(true)
	render.SetStencilWriteMask(2)
	render.SetStencilTestMask(2)
	render.SetStencilReferenceValue(2)
	render.SetStencilCompareFunction(STENCIL_ALWAYS)
	render.SetStencilPassOperation(STENCIL_REPLACE)
	render.SetStencilFailOperation(STENCIL_KEEP)
	render.SetStencilZFailOperation(STENCIL_KEEP)

	if boneid ~= false then
		prepareBoneRender(panel.Entity, boneid)
		panel.Entity:SetupBones()
	end

	panel:PaintManual()
	render.SetStencilCompareFunction(STENCIL_EQUAL)
	render.SetStencilPassOperation(STENCIL_KEEP)
	surface.SetDrawColor(r, g, b or 0, 255)
	surface.DrawRect(0, 0, width, height)
	render.SetStencilEnable(false)
end

local function setupAnimation(pnl, specialPlace, PMentity)
	local sequence = pnl.Entity:SelectWeightedSequence(ACT_IDLE)

	if (sequence > 0) then
		pnl.Entity:ResetSequence(sequence)
	end

	if specialPlace then
		pnl.Entity:SetupBones()
		pnl.Entity:SetParent(PMentity, 0)
		pnl.Entity:AddEffects(EF_BONEMERGE)

		pnl.Paint = function(self, w, h)
			if (not IsValid(self.Entity)) then return end
			local x, y = self:LocalToScreen(0, 0)
			self:LayoutEntity(self.Entity)
			local ang = self.aLookAngle

			if (not ang) then
				ang = (self.vLookatPos - self.vCamPos):Angle()
			end

			cam.Start3D(self.vCamPos, ang, self.fFOV, x, y, w, h, 1, 0)
			render.SuppressEngineLighting(true)
			self:DrawModel()
			render.SuppressEngineLighting(false)
			cam.End3D()
			self.LastPaint = RealTime()
		end
	end

	pnl.LayoutEntity = function(_, ent)
		ent:SetAngles(Angle(0, CurTime() * 20, 0))
		pnl:RunAnimation()
	end
end

function PANEL:Init()
	if (IsValid(ix.gui.quickmenu)) then
		ix.gui.quickmenu:Remove()
	end

	self.brightness = 1
	ix.gui.quickmenu = self
	self.noAnchor = CurTime() + 0.2
	self.anchorMode = true
	self:SetSize(ScrW() / 2, ScrH() / 1.2)
	self:SetPos(ScrW() / 1000, ScrH() / 8)
	self.StencilPlayerModel = vgui.Create("DModelPanel", self)
	self.StencilPlayerModel:SetModel(LocalPlayer():GetModel())
	self.StencilPlayerModel:SetFOV(50)
	self.StencilPlayerModel:SetPaintedManually(true)
	self.StencilPlayerModel:SetWide(self:GetWide() / 1.4)
	self.StencilPlayerModel:SetTall(self:GetTall())
	setupAnimation(self.StencilPlayerModel)
	self.skeleton = vgui.Create("DModelPanel", self)
	--self.skeleton:SetPos(200,0)
	self.skeleton:SetModel("models/player/skeleton.mdl")
	self.skeleton:SetFOV(50)
	self.skeleton:SetPaintedManually(true)
	self.skeleton:SetWide(self:GetWide() / 1.4)
	self.skeleton:SetTall(self:GetTall())
	setupAnimation(self.skeleton, true, self.StencilPlayerModel.Entity)
	self:MakePopup()
end

function PANEL:OnKeyCodePressed(key)
	self.noAnchor = CurTime() + 0.5

	if (key == KEY_F1) then
		self:Remove()
	end
end

function PANEL:Think()
	if (self.bClosing) then return end
	local bTabDown = input.IsKeyDown(KEY_F1)

	if (bTabDown and (self.noAnchor or CurTime() + 0.2) < CurTime() and self.anchorMode) then
		self.anchorMode = false
		surface.PlaySound("buttons/lightswitch2.wav")
	end

	if ((not self.anchorMode and not bTabDown) or gui.IsGameUIVisible()) then
		self:Remove()
	end
end

local bonecolorR, bonecolorG, bonecolorB = 227, 218, 201

function PANEL:Paint(width, height)
	derma.SkinFunc("PaintMenuBackground", self, width, height, self.currentBlur)
	local char = LocalPlayer():GetCharacter()
	BaseClass.Paint(self, width, height)
	surface.SetDrawColor(0, 0, 0, 200)
	surface.DrawRect(0, 0, width, height)
	local r, g, b = 0, 0, 0
	renderEntityBone(self.StencilPlayerModel, false, width, height, r, g, b)

	if char:GetBrokenRightArm() == true then
		r, g, b = 255, 0, 0
	else
		r, g, b = bonecolorR, bonecolorG, bonecolorB
	end

	renderEntityBone(self.skeleton, HITGROUP_RIGHTARM, width, height, r, g, b)

	if char:GetBrokenLeftArm() == true then
		r, g, b = 255, 0, 0
	else
		r, g, b = bonecolorR, bonecolorG, bonecolorB
	end

	renderEntityBone(self.skeleton, HITGROUP_LEFTARM, width, height, r, g, b)

	if char:GetBrokenRightLeg() == true then
		r, g, b = 255, 0, 0
	else
		r, g, b = bonecolorR, bonecolorG, bonecolorB
	end

	renderEntityBone(self.skeleton, HITGROUP_RIGHTLEG, width, height, r, g, b)

	if char:GetBrokenLeftLeg() == true then
		r, g, b = 255, 0, 0
	else
		r, g, b = bonecolorR, bonecolorG, bonecolorB
	end

	renderEntityBone(self.skeleton, HITGROUP_LEFTLEG, width, height, r, g, b)
	local health = LocalPlayer():Health()
	renderEntityBone(self.skeleton, HITGROUP_GENERIC, width, height, bonecolorR, bonecolorB, bonecolorB)

	if char:GetBrainTrauma() == true then
		r, g, b = 255, 0, 0
	else
		r, g, b = bonecolorR, bonecolorG, bonecolorB
	end

	renderEntityBone(self.skeleton, HITGROUP_HEAD, width, height, r, g, b)
end

vgui.Register("ixQuickMenu", PANEL, "ixSubpanelParent")

if (IsValid(ix.gui.quickmenu)) then
	ix.gui.quickmenu:Remove()
end

--vgui.Create("ixQuickMenu")