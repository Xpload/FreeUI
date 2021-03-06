-- Originally based on aBags by Alza.

local F, C, L = unpack(select(2, ...))

--[[ Get the number of bag and bank container slots used ]]

local function CheckSlots()
	for i = 4, 1, -1 do
		if GetContainerNumSlots(i) ~= 0 then
			return i + 1
		end
	end
	return 1
end

-- [[ Local stuff ]]

local Spacing = 4
local _G = _G
local bu, con, bag, col, row
local buttons, bankbuttons = {}, {}
local firstbankopened = 1

--[[ Function to move buttons ]]

local MoveButtons = function(table, frame, columns)
	col, row = 0, 0
	for i = 1, #table do
		bu = table[i]
		bu:ClearAllPoints()
		bu:SetPoint("TOPLEFT", frame, "TOPLEFT", col * (37 + Spacing) + 3, -1 * row * (37 + Spacing) - 3)
		if(col > (columns - 2)) then
			col = 0
			row = row + 1
		else
			col = col + 1
		end
	end

	frame:SetHeight((row + (col==0 and 0 or 1)) * (37 + Spacing) + 19)
	frame:SetWidth(columns * 37 + Spacing * (columns - 1) + 6)
	col, row = 0, 0
end

--[[ Bags ]]

local holder = CreateFrame("Button", "BagsHolder", UIParent)
holder:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -49, 49)
holder:SetFrameStrata("HIGH")
holder:Hide()
F.CreateBD(holder, .6)

local ReanchorButtons = function()
	table.wipe(buttons)
	for f = 1, CheckSlots() do
		con = "ContainerFrame"..f
		bag = _G[con]
		if not bag.reskinned then
			bag:EnableMouse(false)
			_G[con.."CloseButton"]:Hide()
			_G[con.."PortraitButton"]:EnableMouse(false)

			for i = 1, 7 do
				select(i, bag:GetRegions()):SetAlpha(0)
			end

			bag.reskinned = true
		end

		for i = GetContainerNumSlots(f-1), 1, -1  do
			bu = _G[con.."Item"..i]
			if not bu.reskinned then
				bu:SetNormalTexture("")
				bu:SetPushedTexture("")
				bu:SetFrameStrata("HIGH")
				_G[con.."Item"..i.."Count"]:SetFont(C.media.font, 8, "OUTLINEMONOCHROME")
				_G[con.."Item"..i.."Count"]:ClearAllPoints()
				_G[con.."Item"..i.."Count"]:SetPoint("TOP", bu, 1, -2)
				_G[con.."Item"..i.."IconTexture"]:SetTexCoord(.08, .92, .08, .92)
				_G[con.."Item"..i.."IconQuestTexture"]:SetAlpha(0)
				bu.reskinned = true
			end
			tinsert(buttons, bu)
		end
	end
	MoveButtons(buttons, holder, CheckSlots() + 4)
	holder:Show()
end

local money = _G["ContainerFrame1MoneyFrame"]
money:SetFrameStrata("DIALOG")
money:SetParent(holder)
money:ClearAllPoints()
money:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 12, 2)

--[[ Bank ]]

local bankholder = CreateFrame("Button", "BagsBankHolder", UIParent)
bankholder:SetFrameStrata("HIGH")
bankholder:Hide()
F.CreateBD(bankholder, .6)

local purchase = F.CreateFS(bankholder, 8)
purchase:SetPoint("BOTTOMLEFT", bankholder, "BOTTOMLEFT", 4, 4)
purchase:SetText("New bag slot? Type /freeui purchase.")

local ReanchorBankButtons = function()
	table.wipe(bankbuttons)
	for i = 1, 28 do
		bu = _G["BankFrameItem"..i]
		if not bu.reskinned then
			bu:SetNormalTexture("")
			bu:SetPushedTexture("")
			bu:SetFrameStrata("HIGH")
			_G["BankFrameItem"..i.."IconTexture"]:SetTexCoord(.08, .92, .08, .92)
			_G["BankFrameItem"..i.."Count"]:SetFont(C.media.font, 8, "OUTLINEMONOCHROME")
			_G["BankFrameItem"..i.."Count"]:ClearAllPoints()
			_G["BankFrameItem"..i.."Count"]:SetPoint("TOP", bu, 1, -2)
			_G["BankFrameItem"..i.."IconQuestTexture"]:SetAlpha(0)
			bu.reskinned = true
		end
		tinsert(bankbuttons, bu)
	end

	if(firstbankopened==1) then
		_G["BankFrame"]:EnableMouse(false)
		_G["BankCloseButton"]:Hide()

		for f = 1, 5 do
			select(f, _G["BankFrame"]:GetRegions()):SetAlpha(0)
		end
		bankholder:SetPoint("BOTTOMRIGHT", "BagsHolder", "BOTTOMLEFT", -10 , 0)
		firstbankopened = 0
	end

	for f = CheckSlots() + 1, CheckSlots() + GetNumBankSlots() + 1, 1 do
		con = "ContainerFrame"..f
		bag = _G[con]
		if not bag.reskinned then
			bag:EnableMouse(false)
			bag:SetScale(1)
			bag.SetScale = F.dummy
			_G[con.."CloseButton"]:Hide()
			_G[con.."PortraitButton"]:EnableMouse(false)

			for i = 1, 7 do
				select(i, bag:GetRegions()):SetAlpha(0)
			end
			bag.reskinned = true
		end

		for i = GetContainerNumSlots(f-1), 1, -1  do
			bu = _G[con.."Item"..i]
			if not bu.reskinned then
				bu:SetNormalTexture("")
				bu:SetPushedTexture("")
				bu:SetFrameStrata("HIGH")
				_G[con.."Item"..i.."Count"]:SetFont(C.media.font, 8, "OUTLINEMONOCHROME")
				_G[con.."Item"..i.."Count"]:ClearAllPoints()
				_G[con.."Item"..i.."Count"]:SetPoint("TOP", bu, 1, -2)
				_G[con.."Item"..i.."IconTexture"]:SetTexCoord(.08, .92, .08, .92)
				_G[con.."Item"..i.."IconQuestTexture"]:SetAlpha(0)
				bu.reskinned = true
			end
			tinsert(bankbuttons, bu)
		end
	end
	local _, full = GetNumBankSlots()
	if full then purchase:Hide() end
	MoveButtons(bankbuttons, bankholder, CheckSlots() + 8)
	bankholder:Show()
end

local money = _G["BankFrameMoneyFrame"]
money:SetFrameStrata("DIALOG")
money:ClearAllPoints()
money:SetPoint("BOTTOMRIGHT", bankholder, "BOTTOMRIGHT", 12, 2)

--[[ Misc. frames ]]

_G["BankFramePurchaseInfo"]:Hide()
_G["BankFramePurchaseInfo"].Show = F.dummy

local BankBagButtons = {
	BankFrameBag1, 
	BankFrameBag2, 
	BankFrameBag3, 
	BankFrameBag4, 
	BankFrameBag5, 
	BankFrameBag6, 
	BankFrameBag7,
}

local BagButtons = {
	CharacterBag0Slot, 
	CharacterBag1Slot, 
	CharacterBag2Slot, 
	CharacterBag3Slot, 
}

local bankbagholder = CreateFrame("Frame", nil, BankFrame)
bankbagholder:SetSize(289, 43)
bankbagholder:SetPoint("BOTTOM", bankholder, "TOP", 0, -1)
F.CreateBD(bankbagholder, .6)
bankbagholder:SetAlpha(0)

bankbagholder:SetScript("OnEnter", function(self)
	self:SetAlpha(1)
	for _, g in pairs(BankBagButtons) do
		g:SetAlpha(1)
	end
end)
bankbagholder:SetScript("OnLeave", function(self)
	self:SetAlpha(0)
	for _, g in pairs(BankBagButtons) do
		g:SetAlpha(0)
	end
end)

local bagholder = CreateFrame("Frame", nil, ContainerFrame1)
bagholder:SetSize(130, 35)
bagholder:SetPoint("BOTTOM", holder, "TOP", 0, -1)

bagholder:SetScript("OnEnter", function(self)
	for _, g in pairs(BagButtons) do
		g:SetAlpha(1)
	end
end)
bagholder:SetScript("OnLeave", function(self)
	for _, g in pairs(BagButtons) do
		g:SetAlpha(0)
	end
end)

for i = 1, 7 do
	local bag = _G["BankFrameBag"..i]
	local ic = _G["BankFrameBag"..i.."IconTexture"]
	_G["BankFrameBag"..i.."HighlightFrame"]:Hide()

	bag:SetParent(bankholder)
	bag:ClearAllPoints()

	if i == 1 then
		bag:SetPoint("BOTTOM", bankholder, "TOP", -123, 2)
	else
		bag:SetPoint("LEFT", _G["BankFrameBag"..i-1], "RIGHT", 4, 0)
	end

	bag:SetNormalTexture("")
	bag:SetPushedTexture("")

	ic:SetTexCoord(.08, .92, .08, .92)
	
	bag:SetAlpha(0)
	bag:HookScript("OnEnter", function(self)
		bankbagholder:SetAlpha(1)
		for _, g in pairs(BankBagButtons) do
			g:SetAlpha(1)
		end
	end)
	bag:HookScript("OnLeave", function(self)
		bankbagholder:SetAlpha(0)
		for _, g in pairs(BankBagButtons) do
			g:SetAlpha(0)
		end
	end)
end

for i = 0, 3 do
	local bag = _G["CharacterBag"..i.."Slot"]
	local ic = _G["CharacterBag"..i.."SlotIconTexture"]

	bag:SetParent(holder)
	bag:ClearAllPoints()

	if i == 0 then
		bag:SetPoint("BOTTOM", holder, "TOP", -46, 1)
	else
		bag:SetPoint("LEFT", _G["CharacterBag"..(i-1).."Slot"], "RIGHT", 1, 0)
	end

	bag:SetNormalTexture("")
	bag:SetCheckedTexture("")
	bag:SetPushedTexture("")

	ic:SetTexCoord(.08, .92, .08, .92)
	ic:SetPoint("TOPLEFT", 1, -1)
	ic:SetPoint("BOTTOMRIGHT", -1, 1)
	F.CreateBD(bag)

	bag:SetAlpha(0)
	bag:HookScript("OnEnter", function(self)
		for _, g in pairs(BagButtons) do
			g:SetAlpha(1)
		end
	 end)
	bag:HookScript("OnLeave", function(self)
		for _, g in pairs(BagButtons) do
			g:SetAlpha(0)
		end
	end)
end

local moneytext = {"ContainerFrame1MoneyFrameGoldButtonText", "ContainerFrame1MoneyFrameSilverButtonText", "ContainerFrame1MoneyFrameCopperButtonText", "BankFrameMoneyFrameGoldButtonText", "BankFrameMoneyFrameSilverButtonText", "BankFrameMoneyFrameCopperButtonText", "BackpackTokenFrameToken1Count", "BackpackTokenFrameToken2Count", "BackpackTokenFrameToken3Count"}

for i = 1, 9 do
	_G[moneytext[i]]:SetFont(C.media.font, 8, "OUTLINEMONOCHROME")
end

--[[ Show & Hide functions etc ]]

tinsert(UISpecialFrames, bankholder)
tinsert(UISpecialFrames, holder)

local CloseBags = function()
	bankholder:Hide()
	holder:Hide()
	for i = 0, 11 do
		CloseBag(i)
	end
end

local CloseBags2 = function()
	bankholder:Hide()
	holder:Hide()
	CloseBankFrame()
end

local OpenBags = function()
	for i = 0, 11 do
		OpenBag(i)
	end
end

local ToggleBags = function()
	if(IsBagOpen(0)) then
		CloseBankFrame()
		CloseBags()
	else
		OpenBags()
	end
end

for i = 1, 5 do
	local bag = _G["ContainerFrame"..i]
	hooksecurefunc(bag, "Show", ReanchorButtons)
	hooksecurefunc(bag, "Hide", CloseBags2)
	bag.SetScale = F.dummy
end
hooksecurefunc(BankFrame, "Show", function()
	OpenBags()
	ReanchorBankButtons()
end)
hooksecurefunc(BankFrame, "Hide", CloseBags)

ToggleBackpack = ToggleBags
OpenAllBags = OpenBags
OpenBackpack = OpenBags
CloseAllBags = CloseBags

-- [[ Currency ]]

BackpackTokenFrame:GetRegions():Hide()
BackpackTokenFrameToken1:ClearAllPoints()
BackpackTokenFrameToken1:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, 2)
for i = 1, 3 do
	local bu = _G["BackpackTokenFrameToken"..i]
	local ic = _G["BackpackTokenFrameToken"..i.."Icon"]
	_G["BackpackTokenFrameToken"..i.."Count"]:SetShadowOffset(0, 0)

	bu:SetFrameStrata("DIALOG")
	ic:SetDrawLayer("OVERLAY")
	ic:SetTexCoord(.08, .92, .08, .92)

	F.CreateBG(ic)
end

-- [[ Search ]]

BankItemSearchBox:Hide()
BankItemSearchBox.Show = F.dummy

BagItemSearchBoxLeft:Hide()
BagItemSearchBoxMiddle:Hide()
BagItemSearchBoxRight:Hide()

BagItemSearchBox:SetHeight(18)
BagItemSearchBox:ClearAllPoints()
BagItemSearchBox:SetPoint("TOPLEFT", holder, "BOTTOMLEFT", 0, 1)
BagItemSearchBox:SetPoint("TOPRIGHT", holder, "BOTTOMRIGHT", 0, 1)
BagItemSearchBox.SetPoint = F.dummy
BagItemSearchBox:SetWidth(holder:GetWidth())
BagItemSearchBox:SetFont(C.media.font, 8, "OUTLINEMONOCHROME")
BagItemSearchBox:SetShadowColor(0, 0, 0, 0)
BagItemSearchBox:SetJustifyH("CENTER")
BagItemSearchBox:SetAlpha(0)
F.CreateBD(BagItemSearchBox, .6)

BagItemSearchBoxSearchIcon:SetPoint("LEFT", BagItemSearchBox, "LEFT", 4, -2)

local HideSearch = function()
	BagItemSearchBox:SetAlpha(0)
end

BagItemSearchBox:HookScript("OnEditFocusGained", function(self)
	self:SetScript("OnLeave", nil)
	self:SetTextColor(1, 1, 1)
	BagItemSearchBoxSearchIcon:SetVertexColor(1, 1, 1)
end)

BagItemSearchBox:HookScript("OnEditFocusLost", function(self)
	self:SetScript("OnLeave", HideSearch)
	self.clearButton:Click()
	HideSearch()
	self:SetText("Search")
	self:SetTextColor(.5, .5, .5)
	BagItemSearchBoxSearchIcon:SetVertexColor(.6, .6, .6)
end)

BagItemSearchBox:HookScript("OnEnter", function(self)
	self:SetAlpha(1)
end)
BagItemSearchBox:HookScript("OnLeave", HideSearch)

hooksecurefunc("ContainerFrame_UpdateSearchResults", function(frame)
	local id = frame:GetID();
	local name = frame:GetName().."Item";
	local itemButton;
	local _, isFiltered;

	for i=1, frame.size, 1 do
		itemButton = _G[name..i];
		_, _, _, _, _, _, _, isFiltered = GetContainerItemInfo(id, itemButton:GetID());	
		if ( isFiltered ) then
			itemButton.glow:SetAlpha(0);
		else
			itemButton.glow:SetAlpha(1);
		end
	end
end)

-- [[ Money ]]

local function FormatMoney(money)
	local gold = abs(money / 10000)
	local cash = ""
	cash = format("%.2d\124TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0\124t", gold)		
	return cash
end

local name = UnitName("player")
local realm = GetRealmName()
local r, g, b = unpack(C.class)

local function ShowMoney()
	GameTooltip:SetOwner(ContainerFrame1MoneyFrameGoldButton, "ANCHOR_NONE")
	GameTooltip:SetPoint("BOTTOMRIGHT", BagsHolder, "BOTTOMLEFT", -1, 0)

	local total = 0
	local realmlist = FreeUIGlobalConfig.gold[realm]

	for k, v in pairs(realmlist) do
		total = total + v
	end

	GameTooltip:AddDoubleLine(realm, FormatMoney(total), r, g, b, 1, 1, 1)
	GameTooltip:AddLine(" ")
	for k, v in pairs(realmlist) do
		local class = FreeUIGlobalConfig.class[realm][k]
		if v >= 10000 then
			GameTooltip:AddDoubleLine(k, FormatMoney(v), C.classcolours[class].r, C.classcolours[class].g, C.classcolours[class].b, 1, 1, 1)
		end
	end

	GameTooltip:Show()
end

ContainerFrame1MoneyFrameGoldButton:HookScript("OnEnter", ShowMoney)
ContainerFrame1MoneyFrameSilverButton:HookScript("OnEnter", ShowMoney)
ContainerFrame1MoneyFrameCopperButton:HookScript("OnEnter", ShowMoney)
ContainerFrame1MoneyFrameGoldButton:HookScript("OnLeave", GameTooltip_Hide)
ContainerFrame1MoneyFrameSilverButton:HookScript("OnLeave", GameTooltip_Hide)
ContainerFrame1MoneyFrameCopperButton:HookScript("OnLeave", GameTooltip_Hide)