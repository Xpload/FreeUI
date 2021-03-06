-- caelNamePlates by Caellian, modified.

local F, C, L = unpack(select(2, ...))

local caelNamePlates = CreateFrame("Frame", nil, UIParent)
caelNamePlates:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)

local select = select

local freq = C.performance.nameplates
local tfreq = C.performance.namethreat

local paladinR, paladinG, paladinB = C.classcolours["PALADIN"].r, C.classcolours["PALADIN"].g, C.classcolours["PALADIN"].b
local shamanR, shamanG, shamanB = C.classcolours["SHAMAN"].r, C.classcolours["SHAMAN"].g, C.classcolours["SHAMAN"].b

local CreateBG = function(parent, r, g, b, a, layer)
	local offset = UIParent:GetScale() / parent:GetEffectiveScale()
	local bg = parent:CreateTexture(nil, layer or "BACKGROUND")
	bg:SetTexture(r or 0, g or 0, b or 0, a or 1)
	bg:SetPoint("BOTTOMRIGHT", offset, -offset)
	bg:SetPoint("TOPLEFT", -offset, offset)
	return bg
end

local function IsValidFrame(frame)
	local name = frame:GetName()
	return name and name:find("NamePlate")
end

local ThreatUpdate = function(self, elapsed)
	self.elapsed = self.elapsed + elapsed
	if self.elapsed >= tfreq then
		if self.oldglow:IsShown() then
			local _, green = self.oldglow:GetVertexColor()
			if(green > .7) then
				self.healthBar:SetStatusBarColor(1, 1, .3) -- medium threat
			elseif(green > .1) then
				self.healthBar:SetStatusBarColor(1, .5, 0) -- losing aggro
			else
				self.healthBar:SetStatusBarColor(.3, 1, .3) -- tanking
			end
		else
			self.healthBar:SetStatusBarColor(self.r, self.g, self.b) -- normal colours e.g. not tanking/not NPC
		end
		self.elapsed = 0
	end
end

local UpdateFrame = function(self)
	local r, g, b = self.healthBar:GetStatusBarColor()
	local newr, newg, newb
	if g + b == 0 then
		newr, newg, newb = 255/255, 30/255, 60/255
		self.healthBar:SetStatusBarColor(255/255, 30/255, 60/255)
	elseif r + b == 0 then
		newr, newg, newb = 0.33, 0.59, 0.33
		self.healthBar:SetStatusBarColor(0.33, 0.59, 0.33)
	elseif r + g == 0 then
		newr, newg, newb = 0.31, 0.45, 0.63
		self.healthBar:SetStatusBarColor(0.31, 0.45, 0.63)
	elseif 2 - (r + g) < 0.05 and b == 0 then
		newr, newg, newb = 1, 1, .3
		self.healthBar:SetStatusBarColor(1, 1, .3)
	elseif r > 0.9 and g > 0.5 and g < 0.6 and b > 0.7 and b < 0.8 then
		newr, newg, newb = paladinR, paladinG, paladinB
		self.healthBar:SetStatusBarColor(paladinR, paladinG, paladinB)
	elseif g > 0.4 and g < 0.5 and b > 0.8 and b < 0.9 then
		newr, newg, newb = shamanR, shamanG, shamanB
		self.healthBar:SetStatusBarColor(shamanR, shamanG, shamanB)
	else
		newr, newg, newb = r, g, b
	end

	self.r, self.g, self.b = newr, newg, newb

	self.healthBar:ClearAllPoints()
	self.healthBar:SetPoint("CENTER", self.healthBar:GetParent())
	self.healthBar:SetHeight(5)
	self.healthBar:SetWidth(80)

	self.castBar:ClearAllPoints()
	self.castBar:SetPoint("TOP", self.healthBar, "BOTTOM", 0, -2)
	self.castBar:SetHeight(5)
	self.castBar:SetWidth(80)

	self.highlight:SetTexture(nil)

	self.name:SetText(self.oldname:GetText())

	local level, elite, mylevel = tonumber(self.level:GetText()), self.elite:IsShown(), UnitLevel("player")
	self.level:ClearAllPoints()
	self.level:SetPoint("RIGHT", self.healthBar, "LEFT", -2, 0)
	self.level:SetFont(C.media.font, 8 * UIParent:GetScale(), "OUTLINEMONOCHROME")
	self.level:SetShadowColor(0, 0, 0, 0)
	if self.boss:IsShown() then
		self.level:SetText("B")
		self.level:SetTextColor(0.8, 0.05, 0)
		self.level:Show()
	elseif not elite and level == mylevel then
		self.level:Hide()
	else
		self.level:SetText(level..(elite and "+" or ""))
	end
end

local FixCastbar = function(self)
	self.castbarOverlay:Hide()

	self:SetHeight(5)
	-- self:SetWidth(80)
	self:ClearAllPoints()
	self:SetPoint("TOP", self.healthBar, "BOTTOM", 0, -2)
end

local ColorCastBar = function(self, shielded)
	if shielded then
		self.iconbg:SetTexture(1, 0, 0)
	else
		self.iconbg:SetTexture(0, 0, 0)
	end
end

local OnSizeChanged = function(self)
	self.needFix = true
end

local OnValueChanged = function(self, curValue)
	if self.needFix then
		FixCastbar(self)
		self.needFix = nil
	end
end

local OnShow = function(self)
	self.channeling  = UnitChannelInfo("target") 
	FixCastbar(self)
	ColorCastBar(self, self.shieldedRegion:IsShown())
end

local OnEvent = function(self, event, unit)
	if unit == "target" then
		if self:IsShown() then
			ColorCastBar(self, event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
		end
	end
end

local CreateFrame = function(frame)
	if frame.done then return end

	frame.nameplate = true

	frame.healthBar, frame.castBar = frame:GetChildren()
	local healthBar, castBar = frame.healthBar, frame.castBar
	local glowRegion, overlayRegion, highlightRegion, nameTextRegion, levelTextRegion, bossIconRegion, raidIconRegion, stateIconRegion = frame:GetRegions()
	local _, castbarOverlay, shieldedRegion, spellIconRegion = castBar:GetRegions()

	frame.oldname = nameTextRegion
	nameTextRegion:Hide()

	local newNameRegion = F.CreateFS(healthBar, 8 * UIParent:GetScale(), "CENTER")
	newNameRegion:SetPoint("BOTTOM", healthBar, "TOP", 0, 2)
	newNameRegion:SetWidth(80)
	newNameRegion:SetHeight(7)
	frame.name = newNameRegion

	frame.level = levelTextRegion

	healthBar:SetStatusBarTexture(C.media.texture)

	castBar.castbarOverlay = castbarOverlay
	castBar.healthBar = healthBar
	castBar.shieldedRegion = shieldedRegion
	castBar:SetStatusBarTexture(C.media.texture)

	castBar:HookScript("OnShow", OnShow)
	castBar:HookScript("OnSizeChanged", OnSizeChanged)
	castBar:HookScript("OnValueChanged", OnValueChanged)
	castBar:HookScript("OnEvent", OnEvent)
	castBar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
	castBar:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")

	frame.highlight = highlightRegion

	raidIconRegion:ClearAllPoints()
	raidIconRegion:SetPoint("BOTTOM", healthBar, "TOP", 0, 10)
	raidIconRegion:SetHeight(14)
	raidIconRegion:SetWidth(14)

	frame.oldglow = glowRegion
	frame.elite = stateIconRegion
	frame.boss = bossIconRegion

	frame.done = true

	glowRegion:SetTexture(nil)
	overlayRegion:SetTexture(nil)
	shieldedRegion:SetTexture(nil)
	castbarOverlay:SetTexture(nil)
	stateIconRegion:SetTexture(nil)
	bossIconRegion:SetTexture(nil)

	UpdateFrame(frame)
	frame:SetScript("OnShow", UpdateFrame)
	frame:SetScript("OnHide", OnHide)

	frame.elapsed = 0
	frame:SetScript("OnUpdate", ThreatUpdate)

	CreateBG(castBar)
	CreateBG(healthBar)

	local iconFrame = CreateFrame("Frame", nil, castBar)
	iconFrame:SetPoint("TOPLEFT", healthBar, "TOPRIGHT", 2, 2)
	iconFrame:SetHeight(16)
	iconFrame:SetWidth(16)
	iconFrame:SetFrameLevel(0)

	castBar.iconbg = CreateBG(iconFrame)

	spellIconRegion:ClearAllPoints()
	spellIconRegion:SetAllPoints(iconFrame)
	spellIconRegion:SetTexCoord(.1, .9, .1, .9)
end

local numKids = 0
local last = 0
local OnUpdate = function(self, elapsed)
	last = last + elapsed

	if last > freq then
		last = 0

		if WorldFrame:GetNumChildren() ~= numKids then
			numKids = WorldFrame:GetNumChildren()
			for i = 1, select("#", WorldFrame:GetChildren()) do
				frame = select(i, WorldFrame:GetChildren())

				if IsValidFrame(frame) then
					CreateFrame(frame)
				end
			end
		end
	end
end

caelNamePlates:SetScript("OnUpdate", OnUpdate)