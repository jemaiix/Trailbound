-- Right-click shortcuts: lockboxes (pick the lock, bags and trade) and untranslated mage scrolls
-- (Comprehend Scroll), plus the Lockpicking skill each box needs on its tooltip.
-- Item and skill data only; no spawn or loot data.
ForeverAssistLockbox={Version='1.9.5'}
local L=ForeverAssistLockbox
local PICK_LOCK=1804
local function combat() return InCombatLockdown and InCombatLockdown() end
local function safe(v) return not issecretvalue or not issecretvalue(v) end
local disabled=false

-- Lockpicking skill needed, by item ID (Classic lockbox tables) with English names as a fallback.
local byID={[4632]=1,[4633]=25,[4634]=70,[4636]=125,[4637]=175,[4638]=225,[5758]=225,[5759]=225,[5760]=225,
 [16882]=1,[16883]=70,[16884]=175,[16885]=250,[29569]=300,[31952]=350}
local byName={['ornate bronze lockbox']=1,['heavy bronze lockbox']=25,['iron lockbox']=70,['strong iron lockbox']=125,
 ['steel lockbox']=175,['reinforced steel lockbox']=225,['mithril lockbox']=225,['thorium lockbox']=225,['eternium lockbox']=225,
 ['battered junkbox']=1,['worn junkbox']=70,['sturdy junkbox']=175,['heavy junkbox']=250,['strong junkbox']=300,['reinforced junkbox']=350,
 ['khorium lockbox']=325,['froststeel lockbox']=375,['titanium lockbox']=400}
local function requirement(id)
 if not id or not safe(id) then return end
 if byID[id] then return byID[id] end
 local name=C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)
 if name and safe(name) and type(name)=='string' then return byName[name:lower()] end
end
local function playerSkill()
 if not (GetNumSkillLines and GetSkillLineInfo) then return end
 local ok,n=pcall(GetNumSkillLines);if not ok or type(n)~='number' then return end
 for i=1,n do
  local got,name,header,_,rank=pcall(GetSkillLineInfo,i)
  if got and safe(name) and name=='Lockpicking' and not header and type(rank)=='number' then return rank end
 end
end
local function knowsPickLock()
 for _,fn in pairs({C_SpellBook and C_SpellBook.IsSpellKnown,IsPlayerSpell,IsSpellKnown}) do
  if fn then local ok,v=pcall(fn,PICK_LOCK);if ok and safe(v) and v==true then return true end end
 end
 return false
end
local function pickName()
 local info=C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(PICK_LOCK)
 if type(info)=='table' and info.name then return info.name end
 local name=GetSpellInfo and GetSpellInfo(PICK_LOCK)
 return name or 'Pick Lock'
end
-- Can the right-click shortcut be used right now for a box needing this skill?
local function canPick(need)
 if disabled or not knowsPickLock() then return false end
 local have=playerSkill()
 return have==nil or have>=need
end

-- Mage scrolls: untranslated "Scroll: ..." drops are deciphered with Comprehend Scroll (5 second cast).
local COMPREHEND=1296017
local decipherCache={}
local function comprehendName()
 local info=C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(COMPREHEND)
 if type(info)=='table' and info.name then return info.name end
 local name=GetSpellInfo and GetSpellInfo(COMPREHEND)
 return name or 'Comprehend Scroll'
end
local function knowsComprehend()
 local _,class=UnitClass('player');if class~='MAGE' then return false end
 for _,fn in pairs({C_SpellBook and C_SpellBook.IsSpellKnown,IsPlayerSpell,IsSpellKnown}) do
  if fn then local ok,v=pcall(fn,COMPREHEND);if ok and safe(v) and v==true then return true end end
 end
 -- Later ranks carry other spell IDs; the name resolves only while it is in the spellbook.
 local info=C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo('Comprehend Scroll')
 return type(info)=='table' and safe(info.name)
end
local function linesMention(lines,word)
 if type(lines)~='table' or not safe(lines) then return false end
 for _,line in ipairs(lines) do
  local text=type(line)=='table' and line.leftText
  if text and safe(text) and type(text)=='string' and text:lower():find(word,1,true) then return true end
 end
 return false
end
-- Undeciphered scrolls have scrambled capital names ("Scroll: DOST OREM") and say a Mage can decipher them.
local function undecipheredScroll(bag,slot,id,link)
 if decipherCache[id]~=nil then return decipherCache[id] end
 local name=link and safe(link) and type(link)=='string' and link:match('%[(.-)%]')
 if not name then return false end
 if not name:find('^Scroll: ') then decipherCache[id]=false;return false end
 local api=C_TooltipInfo and C_TooltipInfo.GetBagItem
 if not api then decipherCache[id]=true;return true end
 local ok,data=pcall(api,bag,slot)
 if not ok or type(data)~='table' or not safe(data) then return false end
 decipherCache[id]=linesMention(data.lines,'decipher')
 return decipherCache[id]
end

-- Tooltip: required skill, plus a right-click hint when the shortcut is available.
local function addTooltipLines(tooltip,id)
 if not tooltip or combat() or not tooltip.AddLine then return end
 if tooltip.tbLockboxFor==id then return end
 local need=requirement(id)
 if not need then
  -- Untranslated mage scroll: hint when the tooltip says it can be deciphered.
  if not disabled and knowsComprehend() and tooltip.GetName then
   local name=tooltip:GetName()
   if name then
    for i=1,tooltip:NumLines() do
     local fs=_G[name..'TextLeft'..i];local text=fs and fs:GetText()
     if text and safe(text) and type(text)=='string' and text:lower():find('decipher this',1,true) then
      tooltip.tbLockboxFor=id;tooltip:AddLine('Right-click to decipher with Comprehend Scroll',.55,.8,1);tooltip:Show();return
     end
    end
   end
  end
  return
 end
 tooltip.tbLockboxFor=id
 if canPick(need) then tooltip:AddLine('Right-click to pick the lock',.55,.8,1) end
 tooltip:Show()
end
local function clearTooltip(tooltip) tooltip.tbLockboxFor=nil end
if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
 TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item,function(tooltip,data)
  if type(data)=='table' and safe(data.id) then pcall(addTooltipLines,tooltip,data.id) end
 end)
 for _,tooltip in ipairs({GameTooltip,ItemRefTooltip}) do
  if tooltip and tooltip.HookScript then pcall(tooltip.HookScript,tooltip,'OnTooltipCleared',clearTooltip) end
 end
end

-- Right-click: a transparent secure button over the item runs "cast Pick Lock, then use the item".
-- Left clicks, dragging and hover tooltips pass straight through to the real item button.
local probe=CreateFrame('Frame')
local supported=probe.SetPassThroughButtons~=nil and probe.SetPropagateMouseMotion~=nil
local function overlayFor(button)
 local o=button.tbPick
 if o then return o end
 if not supported then return end
 o=CreateFrame('Button',nil,button,'SecureActionButtonTemplate')
 o:SetAllPoints(button);o:SetFrameLevel(button:GetFrameLevel()+10)
 o:RegisterForClicks('RightButtonUp','RightButtonDown');o:SetAttribute('useOnKeyDown',false)
 o:SetPassThroughButtons('LeftButton');o:SetPropagateMouseMotion(true)
 o:SetAttribute('type2','macro');o:Hide()
 button.tbPick=o
 return o
end
local function setOverlay(button,macro)
 if combat() then return end
 local o=overlayFor(button)
 if not o then return end
 if macro then
  if o.tbMacro~=macro then o:SetAttribute('macrotext2',macro);o.tbMacro=macro end
  if not o:IsShown() then o:Show() end
 elseif o:IsShown() then o:Hide() end
end
local function stillLocked(bag,slot)
 -- An already-opened box (loot left inside) no longer carries the Locked line.
 local api=C_TooltipInfo and C_TooltipInfo.GetBagItem
 if not api or not LOCKED then return true end
 local ok,data=pcall(api,bag,slot)
 if not ok or type(data)~='table' or not safe(data.lines) or type(data.lines)~='table' then return true end
 for _,line in ipairs(data.lines) do
  local text=type(line)=='table' and line.leftText
  if text and safe(text) and text==LOCKED then return true end
 end
 return false
end
local function itemIDAt(bag,slot)
 local info=C_Container.GetContainerItemInfo(bag,slot)
 if not info or not safe(info) then return end
 local id=info.itemID
 if id and safe(id) then return id,info.hyperlink end
end
local function refreshFrame(frame)
 if combat() or disabled or not frame then return end
 local known=knowsPickLock()
 local scrolls=knowsComprehend()
 local function visit(item)
  if item and item.GetBagID and item.GetID then
   local macro
   if (known or scrolls) and item:IsShown() then
    local bag,slot=item:GetBagID(),item:GetID()
    local id,link
    if bag and slot then id,link=itemIDAt(bag,slot) end
    local need=id and requirement(id)
    if need then
     if known and canPick(need) and stillLocked(bag,slot) then macro='/cast '..pickName()..'\n/use '..bag..' '..slot end
    elseif id and scrolls and undecipheredScroll(bag,slot,id,link) then
     macro='/cast '..comprehendName()..'\n/use '..bag..' '..slot
    end
   end
   if macro or item.tbPick then setOverlay(item,macro) end
  end
 end
 if frame.Items then for _,item in ipairs(frame.Items) do visit(item) end
 elseif frame.EnumerateValidItems then for _,item in frame:EnumerateValidItems() do visit(item) end end
end
local bagFrames={'ContainerFrameCombinedBags','ContainerFrame1','ContainerFrame2','ContainerFrame3','ContainerFrame4','ContainerFrame5'}
local function refreshBags()
 for _,name in ipairs(bagFrames) do local f=_G[name];if f and f:IsShown() then refreshFrame(f) end end
end
local function install()
 for _,name in ipairs(bagFrames) do
  local f=_G[name]
  if f and not f.tbLockHooked then
   f.tbLockHooked=true
   if type(f.UpdateItemSlots)=='function' then hooksecurefunc(f,'UpdateItemSlots',function(self) pcall(refreshFrame,self) end) end
   f:HookScript('OnShow',function(self) pcall(refreshFrame,self);if C_Timer then C_Timer.After(0,function() pcall(refreshFrame,self) end) end end)
  end
 end
end
-- Trade window: the box sits in the recipient's "will not be traded" slot.
local function refreshTrade()
 if combat() or disabled then return end
 local button=_G.TradeRecipientItem7ItemButton
 if not button then return end
 local macro
 if knowsPickLock() and GetTradeTargetItemLink then
  local link=GetTradeTargetItemLink(7)
  local id=link and safe(link) and type(link)=='string' and tonumber(link:match('item:(%d+)'))
  local need=id and requirement(id)
  if need and canPick(need) then macro='/cast '..pickName()..'\n/click TradeRecipientItem7ItemButton' end
 end
 if macro or button.tbPick then setOverlay(button,macro) end
end
local events=CreateFrame('Frame')
for _,event in ipairs({'PLAYER_LOGIN','BAG_UPDATE_DELAYED','PLAYER_REGEN_ENABLED','SPELLS_CHANGED','SKILL_LINES_CHANGED','TRADE_SHOW','TRADE_UPDATE','TRADE_TARGET_ITEM_CHANGED','TRADE_PLAYER_ITEM_CHANGED'}) do pcall(events.RegisterEvent,events,event) end
events:SetScript('OnEvent',function(_,event)
 if event=='PLAYER_LOGIN' then install() end
 if event=='SPELLS_CHANGED' then decipherCache={} end
 install()
 local ok,err=pcall(function() refreshBags();refreshTrade() end)
 if not ok and not disabled then disabled=true;print('|cffd2b077Trailbound:|r lockbox shortcut switched off after an error: '..tostring(err)) end
end)
