local F, C, L = unpack(select(2, ...))

SlashCmdList.FRAME = function() print(GetMouseFocus():GetName()) end
SLASH_FRAME1 = "/gn"

SlashCmdList.GETPARENT = function() print(GetMouseFocus():GetParent():GetName()) end
SLASH_GETPARENT1 = "/gp"

SlashCmdList.DISABLE_ADDON = function(s) DisableAddOn(s) end
SLASH_DISABLE_ADDON1 = "/dis"

SlashCmdList.ENABLE_ADDON = function(s) EnableAddOn(s) end
SLASH_ENABLE_ADDON1 = "/en"

SlashCmdList.RELOADUI = ReloadUI
SLASH_RELOADUI1 = "/rl"

SlashCmdList.RCSLASH = DoReadyCheck
SLASH_RCSLASH1 = "/rc"

SlashCmdList.ROLECHECK = InitiateRolePoll
SLASH_ROLECHECK1 = "/rolecheck"
SLASH_ROLECHECK2 = "/rolepoll"

SlashCmdList.GROUPDISBAND = function()
		SendChatMessage("Disbanding group.", "RAID" or "PARTY")
		if UnitInRaid("player") then
			for i = 1, GetNumRaidMembers() do
				local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
				if online and name ~= UnitName("player") then
					UninviteUnit(name)
				end
			end
		else
			for i = MAX_PARTY_MEMBERS, 1, -1 do
				if GetPartyMember(i) then
					UninviteUnit(UnitName("party"..i))
				end
			end
		end
		LeaveParty()
end
SLASH_GROUPDISBAND1 = "/rd"

SlashCmdList.TICKET = ToggleHelpFrame
SLASH_TICKET1 = "/gm"

SlashCmdList.TESTUI = function()
	oUF_FreeBoss1:Show(); oUF_FreeBoss1.Hide = function() end oUF_FreeBoss1.unit = "player"
	oUF_FreeBoss2:Show(); oUF_FreeBoss2.Hide = function() end oUF_FreeBoss2.unit = "player"
end
SLASH_TESTUI1 = "/testui"

SlashCmdList.VOLUME = function(val)
	SetCVar("Sound_MasterVolume", val)
end
SLASH_VOLUME1 = "/vol"

local wf = WatchFrame
local wfmove = false 

SlashCmdList.FREEUI = function(cmd)
	local cmd, args = strsplit(" ", cmd:lower(), 2)
	if cmd == "dps" then
		FreeUIConfig.layout = 1
		ReloadUI()
	elseif(cmd == "heal" or cmd == "healer") then
		FreeUIConfig.layout = 2
		ReloadUI()
	elseif cmd == "watchframe" then
		if wfmove == false then
			wfmove = true
			DEFAULT_CHAT_FRAME:AddMessage("FreeUI: |cffffffffWatchframe unlocked.", unpack(C.class))
			wf:EnableMouse(true);
			wf:RegisterForDrag("LeftButton"); 
			wf:SetScript("OnDragStart", wf.StartMoving); 
			wf:SetScript("OnDragStop", wf.StopMovingOrSizing);
		elseif wfmove == true then
			wf:EnableMouse(false);
			wfmove = false
			DEFAULT_CHAT_FRAME:AddMessage("FreeUI: |cffffffffWatchframe locked.", unpack(C.class))
		end
	elseif cmd == "purchase" then
		if BankFrame and BankFrame:IsShown() then
			local _, full = GetNumBankSlots()
			if full then
				print("Can't buy anymore slots.")
				return
			end
			StaticPopup_Show("CONFIRM_BUY_BANK_SLOT")
		else
			print("You need to open your bank first.")
		end
	elseif cmd == "install" then
		if IsAddOnLoaded("!Install") then
			FreeUI_InstallFrame:Show()
		else
			EnableAddOn("!Install")
			LoadAddOn("!Install")
		end
	elseif cmd == "reset" then
		FreeUIGlobalConfig = {}
		FreeUIConfig = {}
		ReloadUI()
	else
		DEFAULT_CHAT_FRAME:AddMessage("FreeUI |cffffffff"..GetAddOnMetadata("FreeUI", "Version"), unpack(C.class))
		DEFAULT_CHAT_FRAME:AddMessage("|cffffffff/freeui|r [dps/healer]|cffffffff: Select a unitframe layout|r", unpack(C.class))
		DEFAULT_CHAT_FRAME:AddMessage("|cffffffff/freeui|r watchframe|cffffffff: Lock/unlock the watchframe|r", unpack(C.class))
		DEFAULT_CHAT_FRAME:AddMessage("|cffffffff/freeui|r purchase|cffffffff: Buy a new bank slot|r", unpack(C.class))
		DEFAULT_CHAT_FRAME:AddMessage("|cffffffff/freeui|r install|cffffffff: Load the intaller|r", unpack(C.class))
		DEFAULT_CHAT_FRAME:AddMessage("|cffffffff/freeui|r reset|cffffffff: Clear saved settings|r", unpack(C.class))
	end
end
SLASH_FREEUI1 = "/freeui"

SlashCmdList.GPOINT = function(f)
	if f ~= "" then
		f = _G[f]
	else
		f = GetMouseFocus()
	end

	if f ~= nil then
		local a1, p, a2, x, y = f:GetPoint()
		print("|cffFFD100"..a1.."|r "..p:GetName().."|cffFFD100 "..a2.."|r "..x.." "..y)
	end
end

SLASH_GPOINT1 = "/gpoint"