local F, C, L = unpack(select(2, ...))

local parent, ns = ...
local oUF = ns.oUF

local class = select(2, UnitClass("player"))

local colors = setmetatable({}, {__index = oUF.colors})

local powerHeight = C.unitframes.power_height
local altPowerHeight = C.unitframes.altpower_height
local playerWidth = C.unitframes.player_width
local playerHeight = C.unitframes.player_height
local targetWidth = C.unitframes.target_width
local targetHeight = C.unitframes.target_height
local focusWidth = C.unitframes.focus_width
local focusHeight = C.unitframes.focus_height
local petWidth = C.unitframes.pet_width
local petHeight = C.unitframes.pet_height
local bossWidth = C.unitframes.boss_width
local bossHeight = C.unitframes.boss_height
local arenaWidth = C.unitframes.arena_width
local arenaHeight = C.unitframes.arena_height
local partyWidth = C.unitframes.party_width
local partyHeight = C.unitframes.party_height
local partyWidthHealer = C.unitframes.party_width_healer
local partyHeightHealer = C.unitframes.party_height_healer

--[[ Dropdown menu ]]

-- from oUF_Lily

local name, addon = ...
local dropdown = CreateFrame('Frame', 'oUF_FreeDropDown', UIParent, 'UIDropDownMenuTemplate')

function addon:menu()
	dropdown:SetParent(self)
	return ToggleDropDownMenu(1, nil, dropdown, 'cursor', 0, 0)
end

-- Slightly altered version of:
-- FrameXML/CompactUnitFrame.lua:730:CompactUnitFrameDropDown_Initialize
local init = function(self)
	local unit = self:GetParent().unit
	local menu, name, id

	if(not unit) then
		return
	end

	if(UnitIsUnit(unit, "player")) then
		menu = "SELF"
	elseif(UnitIsUnit(unit, "vehicle")) then
		-- NOTE: vehicle check must come before pet check for accuracy's sake because
		-- a vehicle may also be considered your pet
		menu = "VEHICLE"
	elseif(UnitIsUnit(unit, "pet")) then
		menu = "PET"
	elseif(UnitIsPlayer(unit)) then
		id = UnitInRaid(unit)
		if(id) then
			menu = "RAID_PLAYER"
			name = GetRaidRosterInfo(id)
		elseif(UnitInParty(unit)) then
			menu = "PARTY"
		else
			menu = "PLAYER"
		end
	else
		menu = "TARGET"
		name = RAID_TARGET_ICON
	end

	if(menu) then
		UnitPopup_ShowMenu(self, menu, unit, name, id)
	end
end

UIDropDownMenu_Initialize(dropdown, init, 'MENU')

--[[ Short values ]]

local siValue = function(val)
	if(val >= 1e6) then
		return format("%.2fm", val * 0.000001)
	elseif(val >= 1e4) then
		return format("%.1fk", val * 0.001) 
	else
		return val
	end
end

--[[ Tags ]]

oUF.Tags.Methods['free:health'] = function(unit)
	if(not UnitIsConnected(unit) or UnitIsDead(unit) or UnitIsGhost(unit)) then return end

	local min, max = UnitHealth(unit), UnitHealthMax(unit)
	if(unit=="target" or(unit and unit:find("boss%d"))) then
		return format("|cffffffff%s|r %.0f", siValue(min), (min/max)*100)
	else
		return siValue(min)
	end
end
oUF.Tags.Events['free:health'] = oUF.Tags.Events.missinghp

oUF.Tags.Methods['free:maxhealth'] = function(unit)
	if(not UnitIsConnected(unit) or UnitIsDead(unit) or UnitIsGhost(unit)) then return end

	local max = UnitHealthMax(unit)
	return max
end
oUF.Tags.Events['free:maxhealth'] = oUF.Tags.Events.missinghp

local function shortName(unit)
	name = UnitName(unit)
	if name and name:len() > 4 then name = name:sub(1, 4) end

	return name
end

oUF.Tags.Methods['free:name'] = function(unit)
	if not UnitIsConnected(unit) then
		return "Off" 
	elseif UnitIsDead(unit) then
		return "Dead"
	elseif UnitIsGhost(unit) then 
		return "Ghost"
	else
		return shortName(unit)
	end
end
oUF.Tags.Events['free:name'] = oUF.Tags.Events.missinghp

oUF.Tags.Methods['free:missinghealth'] = function(unit)
	local min, max = UnitHealth(unit), UnitHealthMax(unit)

	if not UnitIsConnected(unit) then
		return "Off" 
	elseif UnitIsDead(unit) then
		return "Dead"
	elseif UnitIsGhost(unit) then 
		return "Ghost"
	elseif min ~= max then
		return siValue(max-min)
	else
		return shortName(unit)
	end
end
oUF.Tags.Events['free:missinghealth'] = oUF.Tags.Events.missinghp

oUF.Tags.Methods['free:power'] = function(unit)
	local min, max = UnitPower(unit), UnitPowerMax(unit)
	local _, class = UnitClass(unit)
	if class == "DRUID" then min, max = UnitPower(unit, 0), UnitPowerMax(unit, 0) end
	if(min == 0 or max == 0 or not UnitIsConnected(unit) or UnitIsDead(unit) or UnitIsGhost(unit)) then return end

	return siValue(min)
end
oUF.Tags.Events['free:power'] = oUF.Tags.Events.missingpp

--[[ Update health bar colour ]]

local UpdateHealth = function(self, event, unit)
	if(self.unit == unit) then
		local r, g, b
		local min, max = UnitHealth(unit), UnitHealthMax(unit)
		if(unit == "pet") then
			local _, class = UnitClass("player")
			r, g, b = C.classcolours[class].r, C.classcolours[class].g, C.classcolours[class].b
		elseif(UnitIsPlayer(unit)) then
			local _, class = UnitClass(unit)
			if class then r, g, b = C.classcolours[class].r, C.classcolours[class].g, C.classcolours[class].b else r, g, b = 1, 1, 1 end
		elseif(unit and unit:find("boss%d")) then
			r, g, b = self.ColorGradient(min, max, unpack(self.colors.smooth))
		elseif unit then
			r, g, b = unpack(C.reactioncolours[UnitReaction(unit, "player") or 5])
		end

		self.Power:SetStatusBarColor(r, g, b)
		self.Power.bg:SetVertexColor(r/3, g/3, b/3)

		if UnitIsDead(unit) or UnitIsGhost(unit) then
			self.Healthdef:SetPoint("LEFT", self.Health)
		else
			self.Healthdef:SetPoint("LEFT", self.Health, self:GetWidth() * (min/max), 0)
		end

		if((UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit)) or not UnitIsConnected(unit)) then
			self.gradient:SetGradientAlpha("VERTICAL", .6, .6, .6, .6, .4, .4, .4, .6)
		else
			self.gradient:SetGradientAlpha("VERTICAL", .3, .3, .3, .6, .1, .1, .1, .6)
		end

		if not UnitIsConnected(unit) then
			self.Healthdef:Hide()
		else
			self.Healthdef:Show()
		end

		if FreeUIConfig.layout == 2 then
			if UnitIsDead(unit) or UnitIsGhost(unit) then
				self.Healthdef:Hide()
			end
			self.Healthdef:SetVertexColor(self.ColorGradient(min, max, unpack(self.colors.smooth)))
		end
	end
end

--[[ Update health ]]

local PostUpdateHealth = function(Health, unit, min, max)
	if Health.value and unit == "target" then
		Health.value:SetTextColor(unpack(C.reactioncolours[UnitReaction("player", unit) or 5]))
	end

	return UpdateHealth(Health:GetParent(), 'PostUpdateHealth', unit)
end

--[[ Hide Blizz frames ]]

-- This prevents taint when entering/exiting vehicle while in combat, as well as disabling the raid frame manager
-- CompactRaidFrameManager:UnregisterAllEvents()
-- CompactRaidFrameManager.Show = F.dummy
-- CompactRaidFrameManager:Hide()
-- PetFrame_Update = F.dummy

local function KillRaidFrame()
	CompactRaidFrameManager:UnregisterAllEvents()
	if not InCombatLockdown() then CompactRaidFrameManager:Hide() end

	local shown = CompactRaidFrameManager_GetSetting("IsShown")
	if shown and shown ~= "0" then
		CompactRaidFrameManager_SetSetting("IsShown", "0")
	end
end

hooksecurefunc("CompactRaidFrameManager_UpdateShown", function()
	KillRaidFrame()
end)

KillRaidFrame()

--[[ kill party 1 to 5

local function Kill(object)
	if object.UnregisterAllEvents then
		object:UnregisterAllEvents()
	end
	object.Show = F.dummy
	object:Hide()
end

local function KillPartyFrame()
	CompactPartyFrame:Kill()

	for i=1, MEMBERS_PER_RAID_GROUP do
		local name = "CompactPartyFrameMember" .. i
		local frame = _G[name]
		frame:UnregisterAllEvents()
	end			
end

for i=1, MAX_PARTY_MEMBERS do
	local name = "PartyMemberFrame" .. i
	local frame = _G[name]

	frame:Kill()

	_G[name .. "HealthBar"]:UnregisterAllEvents()
	_G[name .. "ManaBar"]:UnregisterAllEvents()
end

if CompactPartyFrame then
	KillPartyFrame()
elseif CompactPartyFrame_Generate then -- 4.1
	hooksecurefunc("CompactPartyFrame_Generate", KillPartyFrame)
end]]

--[[ Debuff highlight ]]

local PostUpdateIcon = function(_, unit, icon, index, _, filter)
	local _, _, _, _, dtype = UnitAura(unit, index, icon.filter)
	if icon.isDebuff and dtype and UnitIsFriend("player", unit) then
		local color = DebuffTypeColor[dtype]
		icon.bg:SetVertexColor(color.r, color.g, color.b)
	else
		icon.bg:SetVertexColor(0, 0, 0)
	end
end

--[[ Update power value ]]

local PostUpdatePower = function(Power, unit, min, max)
	local Health = Power:GetParent().Health
	if(min == 0 or max == 0 or not UnitIsConnected(unit)) then
		Power:SetValue(0)
	elseif(UnitIsDead(unit) or UnitIsGhost(unit)) then
		Power:SetValue(0)
	end
end

--[[ Global ]]

local Shared = function(self, unit, isSingle)
	self.menu = addon.menu

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:RegisterForClicks("AnyUp")

	local bd = CreateFrame("Frame", nil, self)
	bd:SetPoint("TOPLEFT", -1, 1)
	bd:SetPoint("BOTTOMRIGHT", 1, -1)
	bd:SetFrameLevel(self:GetFrameLevel()-1)
	F.CreateBD(bd, 0)

	self.bd = bd

	local gradient = self:CreateTexture(nil, "BACKGROUND")
	gradient:SetPoint("TOPLEFT")
	gradient:SetPoint("BOTTOMRIGHT")
	gradient:SetTexture(C.media.backdrop)
	gradient:SetGradientAlpha("VERTICAL", .3, .3, .3, .6, .1, .1, .1, .6)

	self.gradient = gradient

	--[[ Health ]]

	local Health = CreateFrame("StatusBar", nil, self)
	Health:SetStatusBarTexture(C.media.texture)
	Health:SetStatusBarColor(0, 0, 0, 0)

	Health.frequentUpdates = true

	Health:SetPoint("TOP")
	Health:SetPoint("LEFT")
	Health:SetPoint("RIGHT")
	Health:SetPoint("BOTTOM", 0, 1 + powerHeight)

	self.Health = Health

	--[[ Health deficit colour ]]

	local Healthdef = self:CreateTexture(nil, "BORDER")
	Healthdef:SetPoint("TOPRIGHT", Health)
	Healthdef:SetPoint("BOTTOMRIGHT", Health)
	Healthdef:SetPoint("LEFT", Health)
	Healthdef:SetTexture(C.media.texture)

	if FreeUIConfig.layout == 2 then Healthdef:SetVertexColor(1, 1, 1) else Healthdef:SetVertexColor(0, 0, 0, .6) end

	self.Healthdef = Healthdef

	--[[ Power ]]

	local Power = CreateFrame("StatusBar", nil, self)
	Power:SetStatusBarTexture(C.media.texture)

	Power.frequentUpdates = true

	Power:SetHeight(powerHeight)

	Power:SetPoint("LEFT")
	Power:SetPoint("RIGHT")
	Power:SetPoint("TOP", Health, "BOTTOM", 0, -1)

	self.Power = Power

	local Powertex = Power:CreateTexture(nil, "OVERLAY")
	Powertex:SetHeight(1)
	Powertex:SetPoint("TOPLEFT", 0, 1)
	Powertex:SetPoint("TOPRIGHT", 0, 1)
	Powertex:SetTexture(C.media.backdrop)
	Powertex:SetVertexColor(0, 0, 0)

	Power.bg = Power:CreateTexture(nil, "BACKGROUND")
	Power.bg:SetHeight(powerHeight)
	Power.bg:SetPoint("LEFT")
	Power.bg:SetPoint("RIGHT")
	Power.bg:SetTexture(C.media.backdrop)

	--[[ Alt Power ]]

	if unit == "player" or unit == "pet" then
		local AltPowerBar = CreateFrame("StatusBar", nil, self)
		AltPowerBar:SetWidth(playerWidth)
		AltPowerBar:SetHeight(altPowerHeight)
		AltPowerBar:SetStatusBarTexture(C.media.texture)
		AltPowerBar:SetPoint("BOTTOM", oUF_FreePlayer, 0, -2)

		local abd = CreateFrame("Frame", nil, AltPowerBar)
		abd:SetPoint("TOPLEFT", -1, 1)
		abd:SetPoint("BOTTOMRIGHT", 1, -1)
		abd:SetFrameLevel(AltPowerBar:GetFrameLevel()-1)
		F.CreateBD(abd)

		AltPowerBar.Text = F.CreateFS(AltPowerBar, 8, "RIGHT")
		AltPowerBar.Text:SetPoint("RIGHT", oUF_FreePlayer, "TOPRIGHT", 0, 6)

		local r, g, b
		local max
		local texture = AltPowerBar:GetStatusBarTexture()

		AltPowerBar:SetScript("OnValueChanged", function()
			local cur = AltPowerBar:GetValue()
			_, max = AltPowerBar:GetMinMaxValues()
			r, g, b = self.ColorGradient(cur, max, unpack(self.colors.smooth))
			texture:SetGradient("VERTICAL", r/2, g/2, b/2, r, g, b)

			AltPowerBar.Text:SetText(cur)
			AltPowerBar.Text:SetTextColor(r, g, b)
		end)

		self.AltPowerBar = AltPowerBar

		AltPowerBar:HookScript("OnShow", function()
			oUF_FreePlayer.MaxHealthPoints:Hide()
		end)
		AltPowerBar:HookScript("OnHide", function()
			oUF_FreePlayer.MaxHealthPoints:Show()
		end)
	end

	--[[ Castbar ]]

	local Castbar = CreateFrame("StatusBar", nil, self)
	Castbar:SetStatusBarTexture("")

	local Spark = Castbar:CreateTexture(nil, "OVERLAY")
	Spark:SetBlendMode("ADD")
	Spark:SetWidth(16)
	Castbar.Spark = Spark

	self.Castbar = Castbar

	local PostCastStart = function(Castbar, unit, spell, spellrank)
		if self.Iconbg then
			if Castbar.interrupt and (unit=="target" or unit:find("boss%d")) then
				self.Iconbg:SetVertexColor(1, 0, 0)
			else
				self.Iconbg:SetVertexColor(0, 0, 0)
			end
		end
	end

	local PostCastStop = function(Castbar, unit)
		if Castbar.Text then Castbar.Text:SetText("") end
	end

	local PostCastStopUpdate = function(self, event, unit)
		if(unit ~= self.unit) then return end
		return PostCastStop(self.Castbar, unit)
	end

	self:RegisterEvent("UNIT_NAME_UPDATE", PostCastStopUpdate)
	table.insert(self.__elements, PostCastStopUpdate)

	-- [[ Heal prediction ]]

	if FreeUIConfig.layout == 2 then
		local mhpb = CreateFrame("StatusBar", nil, self.Health)
		mhpb:SetPoint("TOPLEFT", self.Health:GetStatusBarTexture(), "TOPRIGHT")
		mhpb:SetPoint("BOTTOMLEFT", self.Health:GetStatusBarTexture(), "BOTTOMRIGHT")
		mhpb:SetStatusBarTexture(C.media.texture)
		mhpb:SetStatusBarColor(0, .5, 1, 0.75)

		local ohpb = CreateFrame("StatusBar", nil, self.Health)
		ohpb:SetPoint("TOPLEFT", mhpb:GetStatusBarTexture(), "TOPRIGHT")
		ohpb:SetPoint("BOTTOMLEFT", mhpb:GetStatusBarTexture(), "BOTTOMRIGHT")
		ohpb:SetStatusBarTexture(C.media.texture)
		ohpb:SetStatusBarColor(.5, 0, 1, 0.75)

		if unit == "player" then
			mhpb:SetWidth(playerWidth)
			ohpb:SetWidth(playerWidth)
		elseif unit == "target" then
			mhpb:SetWidth(targetWidth)
			ohpb:SetWidth(targetWidth)
		elseif unit == "focus" then
			mhpb:SetWidth(focusWidth)
			ohpb:SetWidth(focusWidth)
		elseif unit == "pet" then
			mhpb:SetWidth(petWidth)
			ohpb:SetWidth(petWidth)
		else
			mhpb:SetWidth(partyWidthHealer)
			ohpb:SetWidth(partyWidthHealer)
		end

		self.mhpb = mhpb
		self.ohpb = ohpb

		self.HealPrediction = {
			-- status bar to show my incoming heals
			myBar = mhpb,

			-- status bar to show other peoples incoming heals
			otherBar = ohpb,

			-- amount of overflow past the end of the health bar
			maxOverflow = 1,
		}
	end

	-- [[ Raid target icons ]]

	local RaidIcon = self:CreateTexture()
	RaidIcon:SetSize(16, 16)
	RaidIcon:SetPoint("RIGHT", self, "LEFT", -3, 0)

	self.RaidIcon = RaidIcon

	--[[ Set up the layout ]]

	self.colors = colors

	self.disallowVehicleSwap = true

	if(isSingle) then
		if unit == "player" then
			self:SetSize(playerWidth, playerHeight)
		elseif unit == "target" then
			self:SetSize(targetWidth, targetHeight)
		elseif unit:find("arena%d") then
			self:SetSize(arenaWidth, arenaHeight)
		elseif unit == "focus" then
			self:SetSize(focusWidth, focusHeight)
		elseif unit == "pet" then
			self:SetSize(petWidth, petHeight)
		elseif unit and unit:find("boss%d") then
			self:SetSize(bossWidth, bossHeight)
		end
	end

	Castbar.PostChannelStart = PostCastStart
	Castbar.PostCastStart = PostCastStart

	Castbar.PostCastStop = PostCastStop
	Castbar.PostChannelStop = PostCastStop

	Health.PostUpdate = PostUpdateHealth
	Power.PostUpdate = PostUpdatePower
end

-- [[ Unit specific functions ]]

local UnitSpecific = {
	pet = function(self, ...)
		Shared(self, ...)

		local Health = self.Health
		local Power = self.Power
		local Castbar = self.Castbar
		local Spark = Castbar.Spark

		Health:SetHeight(petHeight - powerHeight - 1)

		Castbar:SetAllPoints(Health)
		Castbar.Width = self:GetWidth()

		Spark:SetHeight(self.Health:GetHeight())
	end,

	player = function(self, ...)
		Shared(self, ...)

		local Health = self.Health
		local Power = self.Power
		local Castbar = self.Castbar
		local Spark = Castbar.Spark

		Health:SetHeight(playerHeight - powerHeight - 1)

		local HealthPoints = F.CreateFS(Health, 8)
		self.MaxHealthPoints = F.CreateFS(Health, 8, "RIGHT")

		HealthPoints:SetPoint("LEFT", self, "TOPLEFT", 0, 6)
		HealthPoints:SetJustifyH("LEFT")
		self.MaxHealthPoints:SetPoint("RIGHT", self, "TOPRIGHT", 0, 6)

		self:Tag(HealthPoints, '[dead][offline][free:health]')
		self:Tag(self.MaxHealthPoints, '[free:maxhealth]')
		Health.value = HealthPoints

		local _, UnitPowerType = UnitPowerType("player")
		if UnitPowerType == "MANA" or class == "DRUID" then
			local PowerPoints = F.CreateFS(Power, 8)
			PowerPoints:SetPoint("LEFT", HealthPoints, "RIGHT", 2, 0)
			PowerPoints:SetTextColor(.4, .7, 1)

			self:Tag(PowerPoints, '[free:power]')
			Power.value = PowerPoints
		end

		Castbar.Width = self:GetWidth()
		Spark:SetHeight(self.Health:GetHeight())
		Castbar.Text = F.CreateFS(Castbar, 8)
		Castbar.Text:SetDrawLayer("ARTWORK")

		local IconFrame = CreateFrame("Frame", nil, Castbar)

		local Icon = IconFrame:CreateTexture(nil, "OVERLAY")
		Icon:SetAllPoints(IconFrame)
		Icon:SetTexCoord(.08, .92, .08, .92)

		Castbar.Icon = Icon

		self.Iconbg = IconFrame:CreateTexture(nil, "BACKGROUND")
		self.Iconbg:SetPoint("TOPLEFT", -1 , 1)
		self.Iconbg:SetPoint("BOTTOMRIGHT", 1, -1)
		self.Iconbg:SetTexture(C.media.backdrop)

		if C.unitframes.castbar == 2 then
			Castbar:SetStatusBarTexture(C.media.texture)
			Castbar:SetStatusBarColor(unpack(C.class))
			Castbar:SetWidth(self:GetWidth())
			Castbar:SetHeight(self:GetHeight())
			Castbar:SetPoint(unpack(C.unitframes.cast))
			Castbar.Text:SetAllPoints(Castbar)
			local sf = Castbar:CreateTexture(nil, "OVERLAY")
			sf:SetVertexColor(.5, .5, .5, .5)
			Castbar.SafeZone = sf
			IconFrame:SetPoint("LEFT", Castbar, "RIGHT", 3, 0)
			IconFrame:SetSize(22, 22)

			local bg = CreateFrame("Frame", nil, Castbar)
			bg:SetPoint("TOPLEFT", -1, 1)
			bg:SetPoint("BOTTOMRIGHT", 1, -1)
			bg:SetFrameLevel(Castbar:GetFrameLevel()-1)
			F.CreateBD(bg)
		else
			Castbar:SetAllPoints(Health)
			Castbar.Text:SetAllPoints(Health)
			IconFrame:SetPoint("RIGHT", self, "LEFT", -10, 0)
			IconFrame:SetSize(44, 44)
		end

		if C.unitframes.pvp == true then
			local PvP = F.CreateFS(self, 8)
			PvP:SetPoint("RIGHT", self.MaxHealthPoints, "LEFT", -3, 0)
			PvP:SetText("P")
			PvP:SetTextColor(1, 0, 0)

			local UpdatePvP = function(self, event, unit)
				if(unit ~= self.unit) then return end

				local pvp = self.PvP

				local factionGroup = UnitFactionGroup(unit)
				if(UnitIsPVPFreeForAll(unit) or (factionGroup and UnitIsPVP(unit))) then
					pvp:Show()
				else
					pvp:Hide()
				end
			end

			self.PvP = PvP
			PvP.Override = UpdatePvP
		end

		local Debuffs = CreateFrame("Frame", nil, self)
		Debuffs.initialAnchor = "TOPRIGHT"
		if (class == "DEATHKNIGHT" and C.classmod.deathknight == true) or (class == "DRUID" and C.classmod.druid == true) or (class == "WARLOCK" and C.classmod.warlock == true) then
			Debuffs:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -8)
		else
			Debuffs:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -4)
		end
		Debuffs["growth-x"] = "LEFT"
		Debuffs["growth-y"] = "DOWN"
		Debuffs['spacing-x'] = 3
		Debuffs['spacing-y'] = 3

		Debuffs:SetHeight(60)
		Debuffs:SetWidth(playerWidth)
		Debuffs.num = C.unitframes.num_player_debuffs
		Debuffs.size = 26

		self.Debuffs = Debuffs
		Debuffs.PostUpdateIcon = PostUpdateIcon

		if class == "DEATHKNIGHT" and C.classmod.deathknight == true then
			local runes = CreateFrame("Frame", nil, self)
			runes:SetWidth(playerWidth)
			runes:SetHeight(2)
			runes:SetPoint("BOTTOMRIGHT", Debuffs, "TOPRIGHT", 0, 3)

			local rbd = CreateFrame("Frame", nil, runes)
			rbd:SetBackdrop({
				edgeFile = C.media.backdrop,
				edgeSize = 1,
			})
			rbd:SetBackdropBorderColor(0, 0, 0)
			rbd:SetPoint("TOPLEFT", -1, 1)
			rbd:SetPoint("BOTTOMRIGHT", 1, -1)

			for i = 1, 6 do
				runes[i] = CreateFrame("StatusBar", nil, self)
				runes[i]:SetHeight(2)
				runes[i]:SetStatusBarTexture(C.media.texture)
				runes[i]:SetStatusBarColor(255/255,101/255,101/255)

				local rbd = CreateFrame("Frame", nil, runes[i])
				rbd:SetBackdrop({
					edgeFile = C.media.backdrop,
					edgeSize = 1,
				})
				rbd:SetBackdropBorderColor(0, 0, 0)
				rbd:SetPoint("TOPLEFT", runes[i], -1, 1)
				rbd:SetPoint("BOTTOMRIGHT", runes[i], 1, -1)

				if i == 1 then
					runes[i]:SetPoint("LEFT", runes)
					runes[i]:SetWidth(38)
				elseif i == 2 then
					runes[i]:SetPoint("LEFT", runes[i-1], "RIGHT", 1, 0)
					runes[i]:SetWidth(38)
				else
					runes[i]:SetPoint("LEFT", runes[i-1], "RIGHT", 1, 0)
					runes[i]:SetWidth(37)
				end
			end

			self.Runes = runes
		elseif class == "DRUID" and C.classmod.druid == true then
			local eclipseBar = CreateFrame("Frame", nil, self)
			eclipseBar:SetWidth(playerWidth)
			eclipseBar:SetHeight(2)
			eclipseBar:SetPoint("BOTTOMRIGHT", Debuffs, "TOPRIGHT", 0, 3)

			local ebd = CreateFrame("Frame", nil, eclipseBar)
			ebd:SetBackdrop({
				edgeFile = C.media.backdrop,
				edgeSize = 1,
			})
			ebd:SetBackdropBorderColor(0, 0, 0)
			ebd:SetPoint("TOPLEFT", -1, 1)
			ebd:SetPoint("BOTTOMRIGHT", 1, -1)

			local glow = CreateFrame("Frame", nil, eclipseBar)
			glow:SetBackdrop({
				edgeFile = C.media.glow,
				edgeSize = 5,
			})
			glow:SetPoint("TOPLEFT", -6, 6)
			glow:SetPoint("BOTTOMRIGHT", 6, -6)

			local hasEclipse = function(self, unit)
				if self.hasSolarEclipse then
					glow:SetBackdropBorderColor(.80, .82, .60, 1)
				elseif self.hasLunarEclipse then
					glow:SetBackdropBorderColor(.30, .52, .90, 1)
				else
					glow:SetBackdropBorderColor(0, 0, 0, 0)
				end
			end

			local LunarBar = CreateFrame("StatusBar", nil, eclipseBar)
			LunarBar:SetPoint("LEFT", eclipseBar, "LEFT")
			LunarBar:SetSize(eclipseBar:GetWidth(), eclipseBar:GetHeight())
			LunarBar:SetStatusBarTexture(C.media.texture)
			LunarBar:SetStatusBarColor(.80, .82, .60)
			LunarBar:SetFrameStrata("LOW")
			eclipseBar.LunarBar = LunarBar

			local SolarBar = CreateFrame("StatusBar", nil, eclipseBar)
			SolarBar:SetPoint("LEFT", LunarBar:GetStatusBarTexture(), "RIGHT")
			SolarBar:SetSize(eclipseBar:GetWidth(), eclipseBar:GetHeight())
			SolarBar:SetStatusBarTexture(C.media.texture)
			SolarBar:SetStatusBarColor(.30, .52, .90)
			SolarBar:SetFrameStrata("LOW")
			eclipseBar.SolarBar = SolarBar

			local eclipseBarText = F.CreateFS(eclipseBar, 24)
			eclipseBarText:SetPoint("LEFT", self, "RIGHT", 10, 0)
			self:Tag(eclipseBarText, '[pereclipse]')

			self.EclipseBar = eclipseBar

			self.EclipseBar.PostUnitAura = hasEclipse

			eclipseBar:RegisterEvent("PLAYER_REGEN_ENABLED")
			eclipseBar:RegisterEvent("PLAYER_REGEN_DISABLED")
			eclipseBar:RegisterEvent("PLAYER_ENTERING_WORLD")
			eclipseBar:HookScript("OnEvent", function()
				if InCombatLockdown() then
					eclipseBarText:Show()
				else
					eclipseBarText:Hide()
				end
			end)

			self.EclipseBar.PostUpdatePower = function(self)
				if GetEclipseDirection() == "sun" then
					eclipseBarText:SetTextColor(.30, .52, .90)
				elseif GetEclipseDirection() == "moon" then
					eclipseBarText:SetTextColor(.80, .82, .60)
				else
					eclipseBarText:SetTextColor(1, 1, 1)
				end

				if UnitPower("player", SPELL_POWER_ECLIPSE) == 0 then
					eclipseBarText:Hide()
				else
					eclipseBarText:Show()
				end
			end

			self.EclipseBar.PostUpdateVisibility = function()
				if self.EclipseBar:IsShown() then
					if self.AltPowerBar:IsShown() then
						self.Debuffs:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -(9 + altPowerHeight))
					else
						self.Debuffs:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -8)
					end
				else
					if self.AltPowerBar:IsShown() then
						self.Debuffs:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -(5 + altPowerHeight))
					else
						self.Debuffs:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -4)
					end
				end
			end
		elseif class == "PALADIN" and C.classmod.paladin == true then
			local UpdateHoly = function(self, event, unit, powerType)
				if(self.unit ~= unit or (powerType and powerType ~= 'HOLY_POWER')) then return end
				local num = UnitPower(unit, SPELL_POWER_HOLY_POWER)
				for i = 1, MAX_HOLY_POWER do
					if(i <= num) then
						self.glow:SetAlpha(1)
						F.CreatePulse(self.glow)
						self.count:SetText(num)
						self.count:SetTextColor(1, 1, 0)
						self.count:SetFont(C.media.font, 40, "OUTLINEMONOCHROME")
					elseif num == 0 then
						self.glow:SetScript("OnUpdate", nil)
						self.glow:SetAlpha(0)
						self.count:SetText("")
					else
						self.glow:SetScript("OnUpdate", nil)
						self.glow:SetAlpha(0)
						self.count:SetText(num)
						self.count:SetTextColor(1, 1, 1)
						self.count:SetFont(C.media.font, 24, "OUTLINEMONOCHROME")
					end
				end
			end

			local glow = CreateFrame("Frame", nil, self)
			glow:SetBackdrop({
				edgeFile = C.media.glow,
				edgeSize = 5,
			})
			glow:SetPoint("TOPLEFT", self, -6, 6)
			glow:SetPoint("BOTTOMRIGHT", self, 6, -6)
			glow:SetBackdropBorderColor(228/255, 225/255, 16/255)

			self.glow = glow

			local count = F.CreateFS(self, 24)
			count:SetPoint("LEFT", self, "RIGHT", 10, 0)

			self.count = count

			self.HolyPower = glow
			glow.Override = UpdateHoly
		elseif class == "WARLOCK" and C.classmod.warlock == true then
			local bars = CreateFrame("Frame", nil, self)
			bars:SetWidth(playerWidth)
			bars:SetHeight(1)
			bars:SetPoint("BOTTOMRIGHT", Debuffs, "TOPRIGHT", 0, 3)

			local bbd = CreateFrame("Frame", nil, bars)
			bbd:SetPoint("TOPLEFT", -1, 1)
			bbd:SetPoint("BOTTOMRIGHT", 1, -1)
			bbd:SetFrameLevel(bars:GetFrameLevel()-1)
			F.CreateBD(bbd)

			for i = 1, 3 do
				bars[i] = CreateFrame("StatusBar", nil, self)
				bars[i]:SetHeight(1)
				bars[i]:SetStatusBarTexture(C.media.texture)
				bars[i]:SetStatusBarColor(255/255,101/255,101/255)

				local bbd = CreateFrame("Frame", nil, bars[i])
				bbd:SetBackdrop({
					edgeFile = C.media.backdrop,
					edgeSize = 1,
				})
				bbd:SetBackdropBorderColor(0, 0, 0)
				bbd:SetPoint("TOPLEFT", bars[i], -1, 1)
				bbd:SetPoint("BOTTOMRIGHT", bars[i], 1, -1)

				if i == 1 then
					bars[i]:SetPoint("LEFT", bars)
					bars[i]:SetWidth(75)
				else
					bars[i]:SetPoint("LEFT", bars[i-1], "RIGHT", 1, 0)
					bars[i]:SetWidth(76)
				end
			end

			self.SoulShards = bars
		end

		self.AltPowerBar:HookScript("OnShow", function()
			if (class == "DEATHKNIGHT" and C.classmod.deathknight == true) or (class == "DRUID" and C.classmod.druid == true) or (class == "WARLOCK" and C.classmod.warlock == true) then
				Debuffs:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -(9 + altPowerHeight))
			else
				Debuffs:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -(5 + altPowerHeight))
			end
		end)

		self.AltPowerBar:HookScript("OnHide", function()
			if (class == "DEATHKNIGHT" and C.classmod.deathknight == true) or (class == "DRUID" and C.classmod.druid == true) or (class == "WARLOCK" and C.classmod.warlock == true) then
				Debuffs:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -(7 + altPowerHeight))
			else
				Debuffs:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -(3 + altPowerHeight))
			end
		end)

	end,

	target = function(self, ...)
		Shared(self, ...)

		local Health = self.Health
		local Power = self.Power
		local Castbar = self.Castbar
		local Spark = Castbar.Spark

		Health:SetHeight(targetHeight - powerHeight - 1)

		local HealthPoints = F.CreateFS(Health, 8)

		HealthPoints:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 2)
		HealthPoints:SetJustifyH("LEFT")

		self:Tag(HealthPoints, '[dead][offline][free:health]')
		Health.value = HealthPoints

		local PowerPoints = F.CreateFS(Power, 8)
		PowerPoints:SetPoint("BOTTOMLEFT", Health.value, "BOTTOMRIGHT")

		self:Tag(PowerPoints, '[free:power]')

		Power.value = PowerPoints

		local tt = CreateFrame("Frame", nil, self)
		local a1, p, a2, x, y = Health:GetPoint()
		tt:SetPoint(a1, p, a2, x+60, y+26)
		tt:SetWidth(110)
		tt:SetHeight(12)

		ttt = F.CreateFS(tt, 8, "RIGHT")
		ttt:SetAllPoints(tt)

		tt:RegisterEvent("UNIT_TARGET")
		tt:RegisterEvent("PLAYER_TARGET_CHANGED")
		tt:SetScript("OnEvent", function()
			if(UnitName("targettarget")==UnitName("player")) then
				ttt:SetText("> YOU <")
				ttt:SetTextColor(1, 0, 0)
			else
				ttt:SetText(UnitName"targettarget")
				ttt:SetTextColor(1, 1, 1)
			end
		end)

		Castbar:SetAllPoints(Health)
		Castbar.Width = self:GetWidth()

		Spark:SetHeight(self.Health:GetHeight())

		Castbar.Text = F.CreateFS(Castbar, 8)
		Castbar.Text:SetDrawLayer("ARTWORK")
		Castbar.Text:SetAllPoints(Health)

		local IconFrame = CreateFrame("Frame", nil, Castbar)
		IconFrame:SetPoint("LEFT", self, "RIGHT", 3, 0)
		IconFrame:SetHeight(44)
		IconFrame:SetWidth(44)

		local Icon = IconFrame:CreateTexture(nil, "OVERLAY")
		Icon:SetAllPoints(IconFrame)
		Icon:SetTexCoord(.08, .92, .08, .92)

		Castbar.Icon = Icon

		self.Iconbg = IconFrame:CreateTexture(nil, "BACKGROUND")
		self.Iconbg:SetPoint("TOPLEFT", -1 , 1)
		self.Iconbg:SetPoint("BOTTOMRIGHT", 1, -1)
		self.Iconbg:SetTexture(C.media.backdrop)

		local Name = F.CreateFS(self, 8)
		Name:SetPoint("BOTTOMLEFT", Power.value, "BOTTOMRIGHT")
		Name:SetPoint("RIGHT", self)
		Name:SetJustifyH"RIGHT"
		Name:SetTextColor(1, 1, 1)

		self:Tag(Name, '[name]')
		self.Name = Name

		local Auras = CreateFrame("Frame", nil, self)
		Auras:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -4)
		Auras.initialAnchor = "TOPLEFT"
		Auras["growth-x"] = "RIGHT"
		Auras["growth-y"] = "DOWN"
		Auras['spacing-x'] = 3
		Auras['spacing-y'] = 3
		Auras.numDebuffs = C.unitframes.num_target_debuffs
		Auras.numBuffs = C.unitframes.num_target_buffs
		Auras:SetHeight(500)
		Auras:SetWidth(targetWidth)
		Auras.size = 26
		Auras.gap = true

		self.Auras = Auras

		Auras.PostUpdateIcon = PostUpdateIcon

		-- complicated filter is complicated
		-- icon hides if:
		-- it's a debuff on an enemy target which isn't yours and isn't in the useful buffs filter
		-- it's a buff on an enemy player target which is not important

		local playerUnits = {
			player = true,
			pet = true,
			vehicle = true,
		}

		Auras.CustomFilter = function(_, unit, icon, _, _, _, _, _, _, _, caster, _, _, spellID)
			if(not playerUnits[icon.owner] and not C.debuffFilter[spellID] and not UnitIsFriend("player", unit) and icon.isDebuff)
			or(UnitIsPlayer(unit) and not UnitIsFriend("player", unit) and not icon.isDebuff and not C.dangerousBuffs[spellID]) then
				return false
			end
			return true
		end
	end,

	focus = function(self, ...)
		Shared(self, ...)

		local Health = self.Health
		local Power = self.Power
		local Castbar = self.Castbar
		local Spark = Castbar.Spark

		Health:SetHeight(focusHeight - powerHeight - 1)

		Castbar:SetAllPoints(Health)
		Castbar.Width = self:GetWidth()

		Spark:SetHeight(Health:GetHeight())

		local Debuffs = CreateFrame("Frame", nil, self)
		Debuffs:SetPoint("CENTER", UIParent, "CENTER", -216, -56)
		Debuffs.initialAnchor = "BOTTOMLEFT"
		Debuffs["growth-x"] = "RIGHT"
		Debuffs["growth-y"] = "DOWN"
		Debuffs["spacing-x"] = 3
		Debuffs:SetHeight(22)
		Debuffs:SetWidth(focusWidth)
		Debuffs.size = 22
		Debuffs.num = C.unitframes.num_focus_debuffs
		self.Debuffs = Debuffs

		Debuffs.PostUpdateIcon = PostUpdateIcon
	end,

	boss = function(self, ...)
		Shared(self, ...)

		local Health, Power = self.Health, self.Power
		local Castbar = self.Castbar
		local Spark = Castbar.Spark

		self:SetAttribute('initial-height', bossHeight)
		self:SetAttribute('initial-width', bossWidth)

		Health:SetHeight(bossHeight - powerHeight - 1)

		local HealthPoints = F.CreateFS(Health, 8, "RIGHT")
		HealthPoints:SetPoint("RIGHT", self, "TOPRIGHT", 0, 6)
		self:Tag(HealthPoints, '[dead][free:health]')

		Health.value = HealthPoints

		local Name = F.CreateFS(self, 8, "LEFT")
		Name:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 2)
		Name:SetWidth(110)
		Name:SetHeight(8)

		self:Tag(Name, '[name]')
		self.Name = Name

		local AltPowerBar = CreateFrame("StatusBar", nil, self)
		AltPowerBar:SetWidth(bossWidth)
		AltPowerBar:SetHeight(altPowerHeight)
		AltPowerBar:SetStatusBarTexture(C.media.texture)
		AltPowerBar:SetPoint("BOTTOM", 0, -2)

		local abd = CreateFrame("Frame", nil, AltPowerBar)
		abd:SetPoint("TOPLEFT", -1, 1)
		abd:SetPoint("BOTTOMRIGHT", 1, -1)
		abd:SetFrameLevel(AltPowerBar:GetFrameLevel()-1)
		F.CreateBD(abd)

		AltPowerBar.Text = F.CreateFS(AltPowerBar, 8, "CENTER")
		AltPowerBar.Text:SetPoint("CENTER", self, "TOP", 0, 6)

		local r, g, b
		local max
		local texture = AltPowerBar:GetStatusBarTexture()

		AltPowerBar:SetScript("OnValueChanged", function()
			local cur = AltPowerBar:GetValue()
			_, max = AltPowerBar:GetMinMaxValues()
			r, g, b = self.ColorGradient(cur / max, unpack(self.colors.smooth))
			texture:SetGradient("VERTICAL", r/2, g/2, b/2, r, g, b)

			AltPowerBar.Text:SetText(cur)
			AltPowerBar.Text:SetTextColor(r, g, b)
		end)

		self.AltPowerBar = AltPowerBar

		Castbar:SetAllPoints(Health)
		Castbar.Width = self:GetWidth()

		Spark:SetHeight(self.Health:GetHeight())

		Castbar.Text = F.CreateFS(self, 8)
		Castbar.Text:SetDrawLayer("ARTWORK")
		Castbar.Text:SetAllPoints(Health)

		local IconFrame = CreateFrame("Frame", nil, Castbar)
		IconFrame:SetPoint("LEFT", self, "RIGHT", 3, 0)
		IconFrame:SetHeight(22)
		IconFrame:SetWidth(22)

		local Icon = IconFrame:CreateTexture(nil, "OVERLAY")
		Icon:SetAllPoints(IconFrame)
		Icon:SetTexCoord(.08, .92, .08, .92)

		Castbar.Icon = Icon

		self.Iconbg = IconFrame:CreateTexture(nil, "BACKGROUND")
		self.Iconbg:SetPoint("TOPLEFT", -1 , 1)
		self.Iconbg:SetPoint("BOTTOMRIGHT", 1, -1)
		self.Iconbg:SetTexture(C.media.backdrop)

		local Buffs = CreateFrame("Frame", nil, self)
		Buffs.initialAnchor = "TOPLEFT"
		Buffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -4)
		Buffs["growth-x"] = "RIGHT"
		Buffs["growth-y"] = "DOWN"
		Buffs['spacing-x'] = 3
		Buffs['spacing-y'] = 3

		Buffs:SetHeight(22)
		Buffs:SetWidth(bossWidth - 24)
		Buffs.num = C.unitframes.num_boss_buffs
		Buffs.size = 26

		self.Buffs = Buffs

		Buffs.PostUpdateIcon = PostUpdateIcon

		AltPowerBar:HookScript("OnShow", function()
			Buffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -(5 + altPowerHeight))
		end)

		AltPowerBar:HookScript("OnHide", function()
			Buffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -(3 + altPowerHeight))
		end)
	end,

	arena = function(self, ...)
		Shared(self, ...)

		local Health, Power = self.Health, self.Power
		local Castbar = self.Castbar
		local Spark = Castbar.Spark

		self:SetAttribute('initial-height', arenaHeight)
		self:SetAttribute('initial-width', arenaWidth)

		Health:SetHeight(arenaHeight - powerHeight - 1)

		local HealthPoints = F.CreateFS(Health, 8, "RIGHT")
		HealthPoints:SetPoint("RIGHT", self, "TOPRIGHT", 0, 6)
		self:Tag(HealthPoints, '[dead][free:health]')

		Health.value = HealthPoints

		local Name = F.CreateFS(self, 8, "LEFT")
		Name:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 2)
		Name:SetWidth(110)
		Name:SetHeight(8)

		self:Tag(Name, '[name]')
		self.Name = Name

		Castbar:SetAllPoints(Health)
		Castbar.Width = self:GetWidth()

		Spark:SetHeight(self.Health:GetHeight())

		Castbar.Text = F.CreateFS(self, 8)
		Castbar.Text:SetDrawLayer("ARTWORK")
		Castbar.Text:SetAllPoints(Health)

		local IconFrame = CreateFrame("Frame", nil, Castbar)
		IconFrame:SetPoint("LEFT", self, "RIGHT", 3, 0)
		IconFrame:SetHeight(22)
		IconFrame:SetWidth(22)

		local Icon = IconFrame:CreateTexture(nil, "OVERLAY")
		Icon:SetAllPoints(IconFrame)
		Icon:SetTexCoord(.08, .92, .08, .92)

		Castbar.Icon = Icon

		self.Iconbg = IconFrame:CreateTexture(nil, "BACKGROUND")
		self.Iconbg:SetPoint("TOPLEFT", -1 , 1)
		self.Iconbg:SetPoint("BOTTOMRIGHT", 1, -1)
		self.Iconbg:SetTexture(C.media.backdrop)

		local Buffs = CreateFrame("Frame", nil, self)
		Buffs.initialAnchor = "TOPLEFT"
		Buffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -4)
		Buffs["growth-x"] = "RIGHT"
		Buffs["growth-y"] = "DOWN"
		Buffs['spacing-x'] = 3
		Buffs['spacing-y'] = 3

		Buffs:SetHeight(22)
		Buffs:SetWidth(arenaWidth)
		Buffs.num = C.unitframes.num_arena_buffs
		Buffs.size = 26

		self.Buffs = Buffs

		Buffs.PostUpdateIcon = PostUpdateIcon

		self.RaidIcon:SetPoint("LEFT", self, "RIGHT", 3, 0)

		if C.unitframes.arena_trinkets == true then
			local Trinket = CreateFrame("Frame", nil, self)
			Trinket:SetHeight(22)
			Trinket:SetWidth(22)
			Trinket:SetPoint("RIGHT", self, "LEFT", -3, 0)
			Trinket.trinketUseAnnounce = true
			Trinket.trinketUpAnnounce = true

			self.Trinket = Trinket

			local f = CreateFrame("Frame", nil, Trinket)
			f:SetPoint("TOPLEFT", -1, 1)
			f:SetPoint("BOTTOMRIGHT", 1, -1)
			F.CreateBD(f, 0)
		end
	end,
}

do
	local range = {
		insideAlpha = 1,
		outsideAlpha = .3,
	}

	UnitSpecific.party = function(self, ...)
		Shared(self, ...)

		self.disallowVehicleSwap = false

		local Health, Power = self.Health, self.Power

		local Text = F.CreateFS(Health, 8, "CENTER")
		Text:SetPoint("CENTER", 1, 0)
		self.Text = Text

		if FreeUIConfig.layout == 2 then
			Health:SetHeight(partyHeightHealer - powerHeight - 1)
			self:Tag(Text, '[free:missinghealth]')

		else
			Health:SetHeight(partyHeight - powerHeight - 1)
			if C.unitframes.party_name_always == true then
				self:Tag(Text, '[free:name]')
			else
				self:Tag(Text, '[dead][offline]')
			end
		end

		local Resurrect = CreateFrame("Frame")
		Resurrect:RegisterEvent("INCOMING_RESURRECT_CHANGED")
		Resurrect:SetScript("OnEvent", function()
			if UnitHasIncomingResurrection(self.unit) then
				Text:SetTextColor(0, 1, 0)
			else
				Text:SetTextColor(1, 1, 1)
			end
		end)

		self.RaidIcon:ClearAllPoints()
		self.RaidIcon:SetPoint("CENTER", self, "CENTER")

		local Leader = F.CreateFS(self, 8, "LEFT")
		Leader:SetText("l")
		Leader:SetPoint("TOPLEFT", Health, 2, -1)

		self.Leader = Leader

		local MasterLooter = F.CreateFS(self, 8, "RIGHT")
		MasterLooter:SetText("m")
		MasterLooter:SetPoint("TOPRIGHT", Health, 1, 0)

		self.MasterLooter = MasterLooter

		local rc = self:CreateTexture(nil, "OVERLAY")
		rc:SetPoint("TOPLEFT", Health)
		rc:SetHeight(16)
		rc:SetWidth(16)
		self.ReadyCheck = rc

		local UpdateLFD = function(self, event)
			local lfdrole = self.LFDRole
			local role = UnitGroupRolesAssigned(self.unit)

			if role == "DAMAGER" then
				lfdrole:SetTextColor(1, .1, .1, 1)
			elseif role == "TANK" then
				lfdrole:SetTextColor(.3, .4, 1, 1)
			elseif role == "HEALER" then
				lfdrole:SetTextColor(0, 1, 0, 1)
			else
				lfdrole:SetTextColor(0, 0, 0, 0)
			end
		end

		local lfd = F.CreateFS(Health, 16, "CENTER")
		lfd:SetPoint("BOTTOM", Health)
		lfd:SetText(".")
		lfd.Override = UpdateLFD

		self.LFDRole = lfd

		if FreeUIConfig.layout == 2 then
			local Debuffs = CreateFrame("Frame", nil, self)
			Debuffs.initialAnchor = "CENTER"
			Debuffs:SetPoint("BOTTOM", 0, powerHeight - 1)
			Debuffs["growth-x"] = "RIGHT"
			Debuffs["spacing-x"] = 3

			Debuffs:SetHeight(16)
			Debuffs:SetWidth(37)
			Debuffs.num = 2
			Debuffs.size = 16

			self.Debuffs = Debuffs

			Debuffs.PostCreateIcon = function(icons, index)
				index:EnableMouse(false)
			end

			-- Import the global table for faster usage
			local hideDebuffs = C.hideDebuffs

			Debuffs.CustomFilter = function(_, _, _, _, _, _, _, _, _, _, caster, _, _, spellID)
				if hideDebuffs[spellID] then
					return false
				end
				return true
			end

			Debuffs.PostUpdate = function(icons)
				local vb = icons.visibleDebuffs

				if vb == 2 then
					Debuffs:SetPoint("BOTTOM", -9, 0)
				else
					Debuffs:SetPoint("BOTTOM")
				end
			end

			Debuffs.PostUpdateIcon = function(icons, unit, icon, index, _, filter)
				local _, _, _, _, dtype = UnitAura(unit, index, icon.filter)
				if dtype and UnitIsFriend("player", unit) then
					local color = DebuffTypeColor[dtype]
					icon.bg:SetVertexColor(color.r, color.g, color.b)
				else
					icon.bg:SetVertexColor(0, 0, 0)
				end
				icon:EnableMouse(false)
			end

			local Buffs = CreateFrame("Frame", nil, self)
			Buffs.initialAnchor = "CENTER"
			Buffs:SetPoint("TOP", 0, -2)
			Buffs["growth-x"] = "RIGHT"
			Buffs["spacing-x"] = 3

			Buffs:SetSize(43, 12)
			Buffs.num = 3
			Buffs.size = 12

			self.Buffs = Buffs

			Buffs.PostCreateIcon = function(icons, index)
				index:EnableMouse(false)
				index.cd.noshowcd = true
			end

			Buffs.PostUpdateIcon = function(_, _, icon)
				icon:EnableMouse(false)
			end

			local myBuffs = C.myBuffs
			local allBuffs = C.allBuffs

			Buffs.CustomFilter = function(_, _, _, _, _, _, _, _, _, _, caster, _, _, spellID)
				if (caster == "player" and myBuffs[spellID]) or allBuffs[spellID] then
					return true
				end
			end

			Buffs.PostUpdate = function(icons)
				local vb = icons.visibleBuffs

				if vb == 3 then
					Buffs:SetPoint("TOP", -15, -2)
				elseif vb == 2 then
					Buffs:SetPoint("TOP", -7, -2)
				else
					Buffs:SetPoint("TOP", 0, -2)
				end
			end
		end

		local UpdateThreat = function(self, event, unit)
			if(unit ~= self.unit) then return end

			local threat = self.Threat

			unit = unit or self.unit
			local status = UnitThreatSituation(unit)

			if(status and status > 0) then
				local r, g, b = GetThreatStatusColor(status)
				self.bd:SetBackdropBorderColor(r, g, b)
			else
				self.bd:SetBackdropBorderColor(0, 0, 0)
			end
		end

		local Threat = CreateFrame("Frame", nil, self)
		self.Threat = Threat
		Threat.Override = UpdateThreat

		self.Range = range
	end
end

--[[ Register and activate style ]]

oUF:RegisterStyle("Free", Shared)
for unit,layout in next, UnitSpecific do
	oUF:RegisterStyle('Free - ' .. unit:gsub("^%l", string.upper), layout)
end

local spawnHelper = function(self, unit, ...)
	if(UnitSpecific[unit]) then
		self:SetActiveStyle('Free - ' .. unit:gsub("^%l", string.upper))
	elseif(UnitSpecific[unit:match('[^%d]+')]) then -- boss1 -> boss
		self:SetActiveStyle('Free - ' .. unit:match('[^%d]+'):gsub("^%l", string.upper))
	else
		self:SetActiveStyle'Free'
	end

	local object = self:Spawn(unit)
	object:SetPoint(...)
	return object
end

oUF:Factory(function(self)
	spawnHelper(self, 'player', unpack(C.unitframes.player))

	if FreeUIConfig.layout == 1 then
		spawnHelper(self, 'target', unpack(C.unitframes.target))
	else
		spawnHelper(self, 'target', unpack(C.unitframes.target_heal))
	end

	spawnHelper(self, 'focus', "BOTTOMRIGHT", oUF_FreePlayer, "TOPRIGHT", 0, 12)
	spawnHelper(self, 'pet', "BOTTOMLEFT", oUF_FreePlayer, "TOPLEFT", 0, 12)

	for n = 1, 4 do
		spawnHelper(self,'boss' .. n, 'LEFT', 50, 0 - (56 * n))
	end

	for n = 1, 5 do
		spawnHelper(self, 'arena' .. n, 'TOP', oUF_FreePlayer, 'TOP', 0, 0 - (56 * n))
	end

	self:SetActiveStyle'Free - Party'

	local party_width, party_height
	if FreeUIConfig.layout == 2 then
		party_width = partyWidthHealer
		party_height = partyHeightHealer
	else
		party_width = partyWidth
		party_height = partyHeight
	end

	local party = self:SpawnHeader(nil, nil, "custom [@raid6,exists] hide; show", 
		'showParty', true, 
		'showPlayer', true and FreeUIConfig.layout == 2 or false, 
		'showSolo', false, 
		'yoffset', -3, 
		'maxColumns', 5, 
		'unitsperColumn', 1, 
		'columnSpacing', 3, 
		'columnAnchorPoint', "RIGHT",
		'oUF-initialConfigFunction', ([[
			self:SetHeight(%d)
			self:SetWidth(%d)
		]]):format(party_height, party_width)
	)

	if FreeUIConfig.layout == 1 then
		party:SetPoint("BOTTOM", oUF_FreePlayer, "TOP", 0, 50)
	else
		party:SetPoint(unpack(C.unitframes.party))
	end

	local raid = self:SpawnHeader(nil, nil, "custom [@raid6,exists] show; hide",
		'showPlayer', true,
		'showParty', false,
		'showRaid', true,
		'xoffset', 5,
		'yOffset', -4,
		'point', "TOP",
		'groupFilter', '1,2,3,4,5,6,7,8',
		'groupingOrder', '1,2,3,4,5,6,7,8',
		'groupBy', 'GROUP',
		'maxColumns', 8,
		'unitsPerColumn', 5,
		'columnSpacing', 5,
		'columnAnchorPoint', "RIGHT",
		'oUF-initialConfigFunction', ([[
			self:SetHeight(%d)
			self:SetWidth(%d)
		]]):format(party_height, party_width)
	)

	if FreeUIConfig.layout == 1 then
		raid:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMLEFT", -5, 0)
	else
		raid:SetPoint(unpack(C.unitframes.raid))
	end
end)