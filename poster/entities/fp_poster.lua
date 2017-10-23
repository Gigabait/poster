AddCSLuaFile()

ENT.Type = "anim"

ENT.PrintName = "Poster"
ENT.Category = "Facepunch"
ENT.Spawnable = true

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "URL")
	self:NetworkVar("Int", 0, "OffsetX")
	self:NetworkVar("Int", 1, "OffsetY")
	self:NetworkVar("Int", 2, "CropW")
	self:NetworkVar("Int", 3, "CropH")
	self:NetworkVar("Float", 0, "Scale")
	self:NetworkVar("Float", 1, "LastUpdate")
end

if (SERVER) then
	util.AddNetworkString("FP_Poster.Menu")
	util.AddNetworkString("FP_Poster.Edit")

	function ENT:Initialize()
		self:SetModel("models/PHXtended/bar1x.mdl")
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		self:DrawShadow(false)
		
		self:SetScale(1)
		self:SetCropW(1280)
		self:SetCropH(720)
	end

	function ENT:Use(ply)
		if (!ply:IsAdmin()) then
			ply:ChatPrint("Can't edit poster: not an admin")
			return
		end

		net.Start("FP_Poster.Menu")
			net.WriteEntity(self)
		net.Send(ply)
	end

	net.Receive("FP_Poster.Edit", function(_, ply)
		local ent = net.ReadEntity()
		if (!IsValid(ent) or ent:GetClass() ~= "fp_poster") then
			return end
		
		if (!ply:IsAdmin()) then
			ply:ChatPrint("Can't edit poster: not an admin")
			return
		end

		local url = net.ReadString()
		local sc = net.ReadFloat()
		local ox = net.ReadInt(32)
		local oy = net.ReadInt(32)
		local cw = net.ReadUInt(32)
		local ch = net.ReadUInt(32)
		
		local old = ent:GetURL()
		
		ent:SetURL(url)
		ent:SetScale(sc)
		ent:SetOffsetX(ox)
		ent:SetOffsetY(oy)
		ent:SetCropW(cw)
		ent:SetCropH(ch)
		
		if (old ~= url) then
			ent:SetLastUpdate(CurTime())
		end
	end)
else
	ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

	function ENT:Initialize()
		self:SetRenderBounds(Vector(-64, -64, -16), Vector(64, 64, 80))
	end
	
	function ENT:DrawTranslucent()
		if (LocalPlayer():IsAdmin()) then
			local w = LocalPlayer():GetActiveWeapon()
			if (IsValid(w)) and (w:GetClass() == "weapon_physgun" or w:GetClass() == "gmod_tool") then
				self:DrawModel()
			end
		end

		local lu = self:GetLastUpdate()
		if (lu > 0 and lu ~= self.m_fLastUpdate) then
			self.m_fLastUpdate = lu
			
			if (IsValid(self.m_HTML)) then
				self.m_HTML:Remove()
			end

			local h = vgui.Create("DHTML")
			h:SetHTML([[
				<style>
					body
					{
						overflow: hidden;
						background-image: url(]] .. self:GetURL() .. [[);
					}
				</style>
			]])
			h:SetPaintedManually(true)
			h:SetSize(self:GetCropW(), self:GetCropH())
			self.m_HTML = h
		end
		
		local pos, ang = self:GetPos(), self:GetAngles()
		ang:RotateAroundAxis(ang:Up(), 90)
		ang:RotateAroundAxis(ang:Forward(), 90)

		cam.Start3D2D(pos - ang:Right() * (50 + self:GetOffsetY()) + ang:Up() * 1 + (ang:Forward() * self:GetOffsetX()), ang, 0.25 * self:GetScale())
			if (IsValid(self.m_HTML)) then
				self.m_HTML:SetSize(self:GetCropW(), self:GetCropH())
				self.m_HTML:PaintManual()
			elseif (LocalPlayer():IsAdmin()) then
				draw.SimpleText("Unset poster", "DermaLarge", 96, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		cam.End3D2D()
	end

	function ENT:OnRemove()
		if (IsValid(self.m_HTML)) then
			self.m_HTML:Remove()
		end
	end

	net.Receive("FP_Poster.Menu", function()
		local ent = net.ReadEntity()
		if (!IsValid(ent)) then
			return end
		
		if (IsValid(_FP_POSTER)) then
			_FP_POSTER:Remove()
		end

		local f = vgui.Create("DFrame")
		f:SetDraggable(true)
		f:SetTitle("Setup poster")
		f:SetSize(250, 300)
		f:MakePopup()
		_FP_POSTER = f
		
			local change
		
			Label("URL: ", f):Dock(TOP)

			local url = vgui.Create("DTextEntry", f)
			url:SetValue(ent:GetURL())
			url:Dock(TOP)
			url.OnChange = function()
				change = CurTime()
			end
		
			Label("Scale: ", f):Dock(TOP)

			local sc = vgui.Create("DNumSlider", f)
			sc:SetMinMax(0.01, 4)
			sc:SetValue(ent:GetScale())
			sc:Dock(TOP)
			sc.Label:SetVisible(false)
			sc.OnValueChanged = function()
				change = CurTime()
			end
		
			Label("Offset X: ", f):Dock(TOP)

			local ox = vgui.Create("DNumSlider", f)
			ox:SetDecimals(0)
			ox:SetMinMax(-128, 128)
			ox:SetValue(ent:GetOffsetX())
			ox:Dock(TOP)
			ox.Label:SetVisible(false)
			ox.OnValueChanged = function()
				change = CurTime()
			end
		
			Label("Offset Y: ", f):Dock(TOP)

			local oy = vgui.Create("DNumSlider", f)
			oy:SetDecimals(0)
			oy:SetMinMax(-128, 128)
			oy:SetValue(ent:GetOffsetY())
			oy:Dock(TOP)
			oy.Label:SetVisible(false)
			oy.OnValueChanged = function()
				change = CurTime()
			end
		
			Label("Crop width: ", f):Dock(TOP)

			local cw = vgui.Create("DNumSlider", f)
			cw:SetDecimals(0)
			cw:SetMinMax(0, 2048)
			cw:SetValue(ent:GetCropW())
			cw:Dock(TOP)
			cw.Label:SetVisible(false)
			cw.OnValueChanged = function()
				change = CurTime()
			end
		
			Label("Crop height: ", f):Dock(TOP)

			local ch = vgui.Create("DNumSlider", f)
			ch:SetDecimals(0)
			ch:SetMinMax(0, 2048)
			ch:SetValue(ent:GetCropH())
			ch:Dock(TOP)
			ch.Label:SetVisible(false)
			ch.OnValueChanged = function()
				change = CurTime()
			end
			
			f.Think = function()
				if (change and CurTime() > change + 0.01) then
					change = nil
					
					net.Start("FP_Poster.Edit")
						net.WriteEntity(ent)
						net.WriteString(url:GetValue())
						net.WriteFloat(sc:GetValue(), 32)
						net.WriteInt(ox:GetValue(), 32)
						net.WriteInt(oy:GetValue(), 32)
						net.WriteUInt(cw:GetValue(), 32)
						net.WriteUInt(ch:GetValue(), 32)
					net.SendToServer()
				end
			end
			
			f:InvalidateLayout(true)
			f:SizeToChildren(true, true)

		f:Center()
	end)
end