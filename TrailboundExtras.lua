-- Named account profiles and explicit junk management.
ForeverAssistExtras = {}
local E = ForeverAssistExtras
local account, character, getSettings, applySettings
local function Print(msg) print("|cffd2b077Trailbound:|r " .. msg) end
local function Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for k, v in pairs(value) do result[k] = Copy(v) end
    return result
end
E.Copy = Copy
-- Profiles contain ForeverAssist settings only. No Blizzard interface snapshots.
E.nativeInterfaceRestoreSuspended=true
function E.Initialize(a,c,defaults)
    account,character=a,c
    account.profiles=account.profiles or {};account.junkItems=account.junkItems or {};account.junkExcluded=account.junkExcluded or {}
    if not account.profiles.Default then
        local imported=account.profiles["Imported settings"]
        account.profiles.Default=Copy(imported or {})
        local initial=character.settings or account.profile or account.profiles.Default.settings or {}
        account.profiles.Default.settings=Copy(initial)
        for key,value in pairs(defaults) do if account.profiles.Default.settings[key]==nil then if character[key]~=nil then account.profiles.Default.settings[key]=character[key] else account.profiles.Default.settings[key]=value end end end
        account.profiles.Default.settings.interface=nil
    end
    if account.profiles["Imported settings"] and not account.defaultProfileMigration then
        account.profiles["Imported settings"]=nil;account.defaultProfileMigration=true
    end
    -- Remove obsolete Blizzard snapshots without reading or changing native UI state.
    for _,profile in pairs(account.profiles) do
        profile.interfaceOptions=nil;profile.cvars=nil;profile.actionBars=nil
        profile.registered=nil;profile.layout=nil;profile.editSettings=nil
        if profile.settings then profile.settings.interface=nil end
    end
    local name=character.profileName
    if not name or name=="Imported settings" or name:lower()=="default" or not account.profiles[name] then
        character.profileName="Default";character.settings=account.profiles.Default.settings
    else character.settings=character.settings or Copy(account.profiles[name].settings or {}) end
    character.settings.interface=nil
    return character.settings
end
function E.CanForgetCharacter(key)
    if not account or not key then return false end
    local r=(account.characters or {})[key] or (account.bankCharacters or {})[key] or (account.goldLedger or {})[key] or (account.characterBackups or {})[key]
    if not r then return false end
    local name,realm=UnitName("player"),GetRealmName()
    return not (r.name==name and r.realm==realm) and key~=(UnitGUID and UnitGUID("player"))
end
function E.ForgetCharacter(key)
    if not E.CanForgetCharacter(key) then Print("Select an offline character to forget.");return false end
    local r=(account.characters or {})[key] or (account.bankCharacters or {})[key] or (account.goldLedger or {})[key] or (account.characterBackups or {})[key]
    for _,field in ipairs({"characters","bankCharacters","goldLedger","characterBackups"}) do
        for id,entry in pairs(account[field] or {}) do
            if id==key or entry.name==r.name and entry.realm==r.realm then account[field][id]=nil end
        end
    end
    if ForeverAssistSystems then ForeverAssistSystems.RefreshInventory();ForeverAssistSystems.RefreshGoldDisplays() end
    if ForeverAssistBank then ForeverAssistBank.Refresh() end
    Print("Forgot "..ForeverAssistCharacterLabel(r).." (saved bags, bank and money).");return true
end
function E.RequestForgetCharacter(key)
    if not E.CanForgetCharacter(key) then Print("Select an offline character to forget.");return end
    local r=(account.characters or {})[key] or (account.bankCharacters or {})[key] or (account.goldLedger or {})[key] or (account.characterBackups or {})[key]
    StaticPopup_Show("FOREVERASSIST_FORGET_CHARACTER",ForeverAssistCharacterLabel(r),nil,key)
end
local function ProfileName(name)
    name=(name or ""):match("^%s*(.-)%s*$")
    return name:lower()=="default" and "Default" or name
end
function E.Configure(get, apply) getSettings, applySettings = get, apply end

-- Profiles save and apply addon settings only.
function E.SaveProfile(name,silent)
    name = ProfileName(name)
    if name == "" then Print("Enter a profile name first."); return false end
    if #name > 40 then Print("Use a profile name of 40 characters or fewer."); return false end
    local snapshot = {settings=Copy(getSettings()), savedBy=UnitName("player"), savedAt=time()}
    if name=="Default" and character.profileName=="Default" then snapshot.settings=getSettings() end
    if name=="Default" then snapshot.captured=true end
    account.profiles[name] = snapshot
    if not silent then Print("Saved account profile '" .. name .. "'. Available on all characters.") end
    return true
end
function E.LoadProfile(name,silent)
    name = ProfileName(name)
    local snapshot = account.profiles[name]
    if not snapshot then Print("Profile not found: " .. tostring(name)); return false end
    if InCombatLockdown() then Print("Load profiles after combat."); return false end
    character.settings = name=="Default" and snapshot.settings or Copy(snapshot.settings or {})
    character.settings.interface = nil
    character.profileName = name
    applySettings(character.settings)
    if not silent then Print("Loaded profile '" .. name .. "'.") end
    return true
end
function E.DefaultLogin()
    if character.profileName~="Default" then return end
    -- Initialize already selects the shared settings before PLAYER_LOGIN.
    -- Do not replay the profile's callbacks into native UI initialization.
    account.profiles.Default.captured=true
end
function E.DefaultLogout()
    if character.profileName=="Default" then E.SaveProfile("Default",true);account.profiles.Default.captured=true end
end
function E.DeleteProfile(name)
    name=ProfileName(name)
    if name=="Default" then Print("Default is the built-in shared profile. Delete a named profile instead.");return false end
    if not account.profiles[name] then Print("Select a saved profile to delete.");return false end
    if character.profileName==name then
        if InCombatLockdown() then Print("Delete the active profile after combat.");return false end
        E.LoadProfile("Default",true)
    end
    account.profiles[name]=nil;Print("Deleted profile '"..name.."'.");return true
end
function E.ProfileNames()
    local names = {}
    for name in pairs(account.profiles) do names[#names+1]=name end
    table.sort(names,function(a,b) if a=="Default" then return true elseif b=="Default" then return false end;return a<b end)
    return names
end

-- Bag contents are always rescanned before selling or deleting.
local function Container() return C_Container or _G end
local function BagInfo(bag, slot)
    local C = Container()
    local ok, info = pcall(C.GetContainerItemInfo or GetContainerItemInfo, bag, slot)
    if not ok then return nil end
    if type(info) ~= "table" then return nil end
    return info
end
local function ItemPrice(id)
    local fn = C_Item and C_Item.GetItemInfo or GetItemInfo
    if not fn then return nil end
    local ok, name, _, quality, _, _, _, _, _, _, _, price = pcall(fn, id)
    if ok and name and type(price) == "number" then return price, quality end
    if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, id) end
end
function E.ScanJunk(grayOnly)
    local result, missing = {}, false
    local C = Container()
    local slots = C.GetContainerNumSlots or GetContainerNumSlots
    if not slots then return result, missing end
    local lastBag = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4
    for bag = 0, lastBag do
        local ok, n = pcall(slots, bag)
        for slot = 1, (ok and n or 0) do
            local info = BagInfo(bag, slot)
            if info and info.itemID then
                local price, quality = ItemPrice(info.itemID)
                quality = info.quality or quality
                local marked = account.junkItems[info.itemID]
                if not account.junkExcluded[info.itemID] and (quality == 0 or (not grayOnly and marked)) and (not grayOnly or not ForeverAssistPlay or ForeverAssistPlay.AutoSellAllowed(info.itemID)) then
                    if price == nil then missing = true end
                    result[#result+1] = {bag=bag, slot=slot, id=info.itemID, link=info.hyperlink,
                        count=info.stackCount or 1, price=price, quality=quality, locked=info.isLocked,
                        noValue=info.hasNoValue, marked=marked}
                end
            end
        end
    end
    table.sort(result, function(a,b)
        if a.price == nil or b.price == nil then
            if a.price ~= b.price then return a.price ~= nil end
        elseif a.price * a.count ~= b.price * b.count then return a.price * a.count < b.price * b.count end
        if a.id ~= b.id then return a.id < b.id end
        if a.bag ~= b.bag then return a.bag < b.bag end
        return a.slot < b.slot
    end)
    return result, missing
end
local function MerchantOpen() return MerchantFrame and MerchantFrame:IsShown() end
local sale, pending, saleClock
local autoSaleDelay
-- One request at a time, confirmed against the bag before advancing.
-- Short polling removes the old 200 ms pause without flooding the vendor.
local saleInterval = 0.05
local SALE_BATCH = 8
function E.RequestAutoSale() autoSaleDelay = saleInterval end
local function StopSale(reason)
    local finished = sale
    -- Clear the queue before reporting so a formatting error cannot repeat every frame.
    sale, pending, saleClock = nil, nil, 0
    if finished and finished.count > 0 and getSettings().junkReport then
        local rows={};for _,row in pairs(finished.items) do rows[#rows+1]=row end
        table.sort(rows,function(a,b)return a.id<b.id end)
        for _,row in ipairs(rows) do
            local name=row.link or (GetItemInfo and GetItemInfo(row.id)) or ("Item "..row.id)
            Print(("Sold %s x%d for %s."):format(name,row.count,ForeverAssistMoney(row.total)))
        end
        Print("Total sold: "..ForeverAssistMoney(finished.total)..".")
    end
    if reason then Print(reason) end
end
function E.CancelAutomaticSale()
    autoSaleDelay = nil
    if sale and sale.grayOnly then StopSale() end
end

function E.StartSale(grayOnly)
    if sale then return end
    if not MerchantOpen() then Print("Open a vendor window first."); return end
    if InCombatLockdown() then Print("Sell junk after combat."); return end
    if CursorHasItem and CursorHasItem() then Print("Clear the item on your cursor first."); return end
    if InRepairMode and InRepairMode() then Print("Leave repair mode before selling junk."); return end
    sale = {grayOnly=grayOnly, count=0, total=0, elapsed=0, attempted={}, items={}}
    pending, saleClock = nil, 0
end
local function SaleTick(elapsed)
    if not sale then return end
    if sale.grayOnly and not getSettings().sellJunk then StopSale(); return end
    if not MerchantOpen() then StopSale(); return end
    if InCombatLockdown() then StopSale("Junk sale stopped during combat."); return end
    if CursorHasItem and CursorHasItem() then StopSale("Junk sale stopped: an item is on the cursor."); return end
    if InRepairMode and InRepairMode() then StopSale("Junk sale stopped in repair mode."); return end
    sale.elapsed = sale.elapsed + elapsed
    saleClock = (saleClock or 0) + elapsed
    if saleClock < saleInterval then return end
    saleClock = 0
    -- Confirm what was already sent to the vendor.
    sale.inflight = sale.inflight or {}
    for key, row in pairs(sale.inflight) do
        local info = BagInfo(row.bag, row.slot)
        if not info or info.itemID ~= row.id or (info.stackCount or 1) < row.count then
            sale.count = sale.count + 1
            local quantity = row.count
            if info and info.itemID == row.id then quantity = math.max(0, row.count - (info.stackCount or 1)) end
            sale.total = sale.total + row.price * quantity
            local entry = sale.items[row.id] or {id=row.id,link=row.link,count=0,total=0}
            entry.count = entry.count + quantity; entry.total = entry.total + row.price * quantity; sale.items[row.id] = entry
            sale.inflight[key] = nil
        elseif sale.elapsed - row.started > 2 then
            sale.attempted[key] = true
            sale.inflight[key] = nil
        end
    end
    local list, missing = E.ScanJunk(sale.grayOnly)
    local use = Container().UseContainerItem or UseContainerItem
    if not use then StopSale("Vendor item API is unavailable."); return end
    -- Several items per tick: no waiting for each sale to clear before sending the next.
    local sent = 0
    for _, row in ipairs(list) do
        local key = row.bag .. ":" .. row.slot
        if not row.locked and not row.noValue and row.price and row.price > 0 and not sale.attempted[key] and not sale.inflight[key] then
            row.started = sale.elapsed
            sale.inflight[key] = row
            if pcall(use, row.bag, row.slot) then sent = sent + 1 else sale.attempted[key] = true; sale.inflight[key] = nil end
            if sent >= SALE_BATCH then break end
        end
    end
    if sent > 0 or next(sale.inflight) then return end
    -- Give uncached/locked items time to finish loading; never fabricate a price.
    local locked = false
    for _, row in ipairs(list) do if row.locked then locked = true end end
    if (missing or locked) and sale.elapsed < 10 then return end
    StopSale(missing and "Some item prices are still loading. Try Sell again." or nil)
end
function E.AddCursorJunk()
    local kind, id = GetCursorInfo()
    if kind ~= "item" or not id then return end
    account.junkItems[id] = true
    account.junkExcluded[id] = nil
    ClearCursor()
    Print("Added item to the account junk list.")
    E.RefreshJunk()
end
local function DeleteItem(row)
    if GetCursorInfo() then Print("Clear your cursor first."); return end
    local info = BagInfo(row.bag, row.slot)
    if not info or info.itemID ~= row.id or info.hyperlink ~= row.link or info.isLocked or (info.stackCount or 1) ~= row.count then
        Print("That item moved or is locked. Refresh the list and try again."); return
    end
    local C = Container()
    local fn = C.PickupContainerItem
    if not fn then Print("This client cannot pick up that item."); return end
    local ok = pcall(fn, row.bag, row.slot)
    local kind, id = GetCursorInfo()
    if not ok or kind ~= "item" or id ~= row.id then ClearCursor(); Print("Could not pick up the item."); return end
    DeleteCursorItem()
    E.RefreshJunk()
end
StaticPopupDialogs["FOREVERASSIST_DELETE_JUNK"] = {
    text="Delete the entire stack of %s? This cannot be undone.", button1=DELETE or "Delete", button2=CANCEL or "Cancel",
    OnAccept=function(self, data) DeleteItem(data or self.data) end,
    timeout=0, whileDead=true, hideOnEscape=true, preferredIndex=3,
}

StaticPopupDialogs["FOREVERASSIST_FORGET_CHARACTER"] = {
    text="Forget %s? Remove their saved bags, bank and money from ForeverAssist. A character you log into again will be recorded anew.",
    button1="Forget character",button2=CANCEL or "Cancel",
    OnAccept=function(self,data) E.ForgetCharacter(data or self.data) end,
    timeout=0,whileDead=true,hideOnEscape=true,preferredIndex=3,
}

local function Window(name, title, width, height)
    local frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    frame:SetSize(width,height); frame:SetPoint("CENTER"); frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true); frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart",frame.StartMoving); frame:SetScript("OnDragStop",frame.StopMovingOrSizing)
    frame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=24,insets={left=6,right=6,top=6,bottom=6}})
    local t=frame:CreateFontString(nil,"OVERLAY","TrailboundTitle");t:SetPoint("TOP",0,-15);t:SetText(title)
    local close=CreateFrame("Button",nil,frame,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",-4,-4);close.faEditorClose=true
    tinsert(UISpecialFrames,name);frame:Hide();return frame
end
local function Button(parent, text, x, y, width, callback)
    local button=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    button:SetSize(width,26);button:SetPoint("TOPLEFT",x,y);button:SetText(text);button:SetScript("OnClick",callback)
    if ForeverAssistStyleButton then ForeverAssistStyleButton(button) end
    return button
end
local junkWindow, junkContent, junkRows, junkNote, junkSell, junkDelete, junkLoot, junkTotal
function E.RefreshJunk()
    if not junkWindow or not junkWindow:IsShown() then return end
    local list, missing = E.ScanJunk(false)
    junkWindow.list=list
    for i,row in ipairs(list) do
        local button=junkRows[i]
        if not button then
            button=CreateFrame("Button",nil,junkContent);button:SetSize(330,25);button:SetPoint("TOPLEFT",0,-(i-1)*25)
            button.left=button:CreateFontString(nil,"OVERLAY","TrailboundSmall");button.left:SetPoint("LEFT",0,0);button.left:SetWidth(205);button.left:SetJustifyH("LEFT")
            button.right=button:CreateFontString(nil,"OVERLAY","TrailboundSmall");button.right:SetPoint("RIGHT",-4,0);button.right:SetWidth(115);button.right:SetJustifyH("RIGHT")
            button:SetScript("OnReceiveDrag",E.AddCursorJunk)
            button:RegisterForClicks("LeftButtonUp","RightButtonUp")
            button:SetScript("OnClick",function(self,mouse)
                if mouse=='RightButton' or IsShiftKeyDown() then
                    account.junkItems[self.itemID]=nil;account.junkExcluded[self.itemID]=true
                    GameTooltip:Hide();E.RefreshJunk();return
                end
                if CursorHasItem() then E.AddCursorJunk() end
            end)
            button:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); if self.link then GameTooltip:SetHyperlink(self.link) end;GameTooltip:AddLine("Right-click: remove this item type from the list",1,1,1);GameTooltip:AddLine("Keeps items in bags and excludes them from auto-selling.",1,1,1);GameTooltip:Show() end)
            button:SetScript("OnLeave",function() GameTooltip:Hide() end)
            junkRows[i]=button
        end
        button.itemID,button.link=row.id,row.link
        button.left:SetText((row.link or ("Item "..row.id)).." x"..row.count)
        button.right:SetText(row.price and ForeverAssistMoney(row.price * row.count) or "Loading...")
        button:Show()
    end
    for i=#list+1,#junkRows do junkRows[i]:Hide() end
    junkContent:SetHeight(math.max(1,#list*25))
    junkSell:SetEnabled(MerchantOpen() and not sale and not InCombatLockdown())
    junkDelete:SetEnabled(#list>0 and not missing)
    if junkLoot then junkLoot:SetEnabled(true) end
    local worth=0
    for _,row in ipairs(list) do if row.price then worth=worth+row.price*row.count end end
    if junkTotal then
        junkTotal:SetText(#list>0 and ("Listed items are worth "..ForeverAssistMoney(worth)..(missing and " (+ some still loading)" or "").." in total") or "Nothing listed")
    end
    junkNote:SetText("Lowest stack vendor value first. Delete removes a STACK.\nRight-click removes from list only. Drop items to add them back.")
end
function E.ToggleJunk()
    if not junkWindow then
        junkWindow=Window("ForeverAssistJunk","Junk Manager",400,372);junkRows={}
        junkWindow:SetScript("OnReceiveDrag",E.AddCursorJunk)
        junkWindow:SetScript("OnMouseUp",function() if CursorHasItem() then E.AddCursorJunk() end end)
        local scroll=CreateFrame("ScrollFrame",nil,junkWindow,"UIPanelScrollFrameTemplate");scroll:SetPoint("TOPLEFT",24,-48);scroll:SetPoint("BOTTOMRIGHT",-44,112)
        junkContent=CreateFrame("Frame",nil,scroll);junkContent:SetSize(330,1);scroll:SetScrollChild(junkContent)
        scroll:SetScript("OnReceiveDrag",E.AddCursorJunk);junkContent:SetScript("OnReceiveDrag",E.AddCursorJunk)
        junkTotal=junkWindow:CreateFontString(nil,"OVERLAY","TrailboundSmall");junkTotal:SetPoint("TOPLEFT",26,-31);junkTotal:SetWidth(350);junkTotal:SetJustifyH("LEFT");junkTotal:SetTextColor(1,.82,0)
        junkNote=junkWindow:CreateFontString(nil,"OVERLAY","TrailboundSmall");junkNote:SetPoint("BOTTOMLEFT",24,110);junkNote:SetWidth(350);junkNote:SetJustifyH("LEFT")
        junkSell=Button(junkWindow,"Sell listed items",24,-282,166,function() E.StartSale(false);E.RefreshJunk() end)
        junkDelete=Button(junkWindow,"Delete lowest stack",202,-282,174,function()
            local list, missing=E.ScanJunk(false)
            if list[1] and not missing then StaticPopup_Show("FOREVERASSIST_DELETE_JUNK",(list[1].link or ("Item "..list[1].id)) .. " x" .. list[1].count,nil,Copy(list[1])) end
        end)
        junkLoot=Button(junkWindow,"Delete lowest-value item & loot",24,-318,352,function()
            local row=E.LowestWorth()
            if row then StaticPopup_Show("FOREVERASSIST_DELETE_FOR_LOOT",(row.link or ("Item "..row.id)).." x"..row.count,nil,Copy(row))
            else Print("Nothing safe to delete: no listed junk and no item with a vendor value.") end
        end)
        junkSell:HookScript("OnReceiveDrag",E.AddCursorJunk);junkDelete:HookScript("OnReceiveDrag",E.AddCursorJunk)
        junkWindow:SetScript("OnShow",E.RefreshJunk)
    end
    junkWindow:SetShown(not junkWindow:IsShown());E.RefreshJunk()
end
-- Bags full while looting: open the junk manager and offer to delete the lowest-value item.
local function LootOpen() return GetNumLootItems and (GetNumLootItems() or 0)>0 and LootFrame and LootFrame:IsShown() end
local function ProtectedItem(id)
    local fn = C_Item and C_Item.GetItemInfoInstant
    if not fn then return true end
    local ok, _, _, _, _, _, classID = pcall(fn, id)
    return not ok or classID == 12 or classID == 13 -- quest items and keys are never offered
end
-- Listed junk first (cheapest stack); otherwise the cheapest vendor-valued stack in the bags.
function E.LowestWorth()
    local list = E.ScanJunk(false)
    if list[1] then return list[1] end
    local best, bestValue
    local C = Container()
    local slots = C.GetContainerNumSlots or GetContainerNumSlots
    if not slots then return end
    for bag = 0, (NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4) do
        local ok, n = pcall(slots, bag)
        for slot = 1, (ok and n or 0) do
            local info = BagInfo(bag, slot)
            if info and info.itemID and not info.isLocked and not info.hasNoValue and not ProtectedItem(info.itemID) then
                local price, quality = ItemPrice(info.itemID)
                if type(price) == "number" and price > 0 then
                    local count = info.stackCount or 1
                    local value = price * count
                    if not bestValue or value < bestValue then
                        bestValue = value
                        best = {bag=bag, slot=slot, id=info.itemID, link=info.hyperlink, count=count, price=price, quality=info.quality or quality, locked=info.isLocked}
                    end
                end
            end
        end
    end
    return best
end
StaticPopupDialogs["FOREVERASSIST_DELETE_FOR_LOOT"] = {
    text="Bags are full. Delete the entire stack of %s to make room and loot the new item? This cannot be undone.", button1=DELETE or "Delete", button2=CANCEL or "Cancel",
    OnAccept=function(self, data) E.retryLoot = true; DeleteItem(data or self.data) end,
    timeout=0, whileDead=false, hideOnEscape=true, preferredIndex=3,
}
local fullEvents, lastFullOpen = CreateFrame("Frame"), 0
fullEvents:RegisterEvent("UI_ERROR_MESSAGE"); fullEvents:RegisterEvent("BAG_UPDATE_DELAYED")
fullEvents:SetScript("OnEvent", function(_, event, first, second)
    if event == "UI_ERROR_MESSAGE" then
        local message = type(second) == "string" and second or first
        if issecretvalue and issecretvalue(message) then return end
        if getSettings and getSettings().fullBagJunk ~= false and ERR_INV_FULL and message == ERR_INV_FULL and LootOpen() and GetTime() - lastFullOpen > 2 then
            lastFullOpen = GetTime()
            if not (junkWindow and junkWindow:IsShown()) then E.ToggleJunk() end
            Print("Bags are full. Junk manager opened: use \"Delete lowest-value item & loot\" to make room.")
        end
    elseif E.retryLoot then
        E.retryLoot = false
        if LootOpen() then for i = GetNumLootItems(), 1, -1 do pcall(LootSlot, i) end end
    end
end)
local profileWindow, profileName, profileContent, profileRows, profileStatus
function E.RefreshProfiles()
    if not profileWindow or not profileWindow:IsShown() then return end
    local names=E.ProfileNames()
    for i,name in ipairs(names) do
        local button=profileRows[i]
        if not button then
            button=CreateFrame("Button",nil,profileContent,"UIPanelButtonTemplate");button:SetSize(382,28);button:SetPoint("TOPLEFT",0,-(i-1)*32)
            button:SetScript("OnClick",function(self) profileName:SetText(self.profile);profileStatus:SetText("Selected: "..self.profile) end)
            profileRows[i]=button
        end
        button.profile=name;button:SetText(name);button:Show()
    end
    for i=#names+1,#profileRows do profileRows[i]:Hide() end
    profileContent:SetHeight(math.max(1,#names*32))
end
function E.ToggleProfiles()
    if not profileWindow then
        profileWindow=Window("ForeverAssistProfiles","ForeverAssist Profiles",450,520);profileRows={}
        local nameLabel=profileWindow:CreateFontString(nil,"OVERLAY","TrailboundHeading");nameLabel:SetPoint("TOPLEFT",24,-50);nameLabel:SetText("Profile name")
        profileName=CreateFrame("EditBox",nil,profileWindow,"InputBoxTemplate");profileName:SetSize(376,25);profileName:SetPoint("TOPLEFT",30,-70);profileName:SetAutoFocus(false);profileName:SetMaxLetters(40)
        profileName:SetText(character.profileName or "Default")
        local help=profileWindow:CreateFontString(nil,"OVERLAY","TrailboundSmall");help:SetPoint("TOPLEFT",24,-108);help:SetWidth(382);help:SetHeight(32);help:SetJustifyH("LEFT");help:SetText("Default shares Trailbound settings.\nProfiles save addon settings only.")
        local scroll=CreateFrame("ScrollFrame",nil,profileWindow,"UIPanelScrollFrameTemplate");scroll:SetPoint("TOPLEFT",24,-148);scroll:SetPoint("BOTTOMRIGHT",-44,184)
        profileContent=CreateFrame("Frame",nil,scroll);profileContent:SetSize(382,1);scroll:SetScrollChild(profileContent)
        profileStatus=profileWindow:CreateFontString(nil,"OVERLAY","TrailboundSmall");profileStatus:SetPoint("TOPLEFT",24,-350);profileStatus:SetWidth(382);profileStatus:SetHeight(48);profileStatus:SetJustifyH("LEFT");profileStatus:SetJustifyV("TOP")
        local function ActiveStatus() profileStatus:SetText("Active: "..(character.profileName or "Default")) end
        ActiveStatus()
        Button(profileWindow,"Save / overwrite",24,-408,182,function() if E.SaveProfile(profileName:GetText()) then profileStatus:SetText("Saved: "..ProfileName(profileName:GetText())) end;E.RefreshProfiles() end)
        Button(profileWindow,"Load selected",224,-408,182,function() if E.LoadProfile(profileName:GetText()) then ActiveStatus() end;E.RefreshProfiles() end)
        local pendingDelete
        local delete
        delete=Button(profileWindow,"Delete selected",24,-445,182,function()
            local name=ProfileName(profileName:GetText())
            if name=="Default" then profileStatus:SetText("Default is shared and cannot be deleted.");return end
            if not account.profiles[name] then profileStatus:SetText("Select a saved profile to delete.");return end
            if pendingDelete~=name then pendingDelete=name;delete:SetText("Confirm delete");profileStatus:SetText("Press Confirm delete to remove '"..name.."'.");return end
            if E.DeleteProfile(name) then profileName:SetText(character.profileName or "Default");ActiveStatus();E.RefreshProfiles() end
            pendingDelete=nil;delete:SetText("Delete selected")
        end)
        profileName:HookScript("OnTextChanged",function() pendingDelete=nil;delete:SetText("Delete selected") end)
        local back=Button(profileWindow,"Back to settings",0,0,170,function() profileWindow:Hide();if ForeverAssistOptions then ForeverAssistOptions:Show() end end)
        back:ClearAllPoints();back:SetPoint("BOTTOMLEFT",24,12)
        profileWindow:SetScript("OnShow",function() ActiveStatus();E.RefreshProfiles() end)
    end
    if profileWindow:IsShown() then profileWindow:Hide() elseif ForeverAssistShowEditor then ForeverAssistShowEditor(profileWindow) else profileWindow:Show() end;E.RefreshProfiles()
end
SLASH_FOREVERASSISTJUNK1="/junk"
SlashCmdList["FOREVERASSISTJUNK"]=function() if account then E.ToggleJunk() end end
local ticker=CreateFrame("Frame")
local update=0
ticker:SetScript("OnUpdate",function(_,elapsed)
    if not account then return end
    if autoSaleDelay then
        autoSaleDelay = autoSaleDelay - elapsed
        if autoSaleDelay <= 0 then
            autoSaleDelay = nil
            if MerchantOpen() and getSettings().sellJunk then E.StartSale(true) end
        end
    end
    SaleTick(elapsed)
    update=update+elapsed
    if update>=0.5 then update=0;E.RefreshJunk() end
end)
