-- Character window (C): item level on every equipped item, your average equipped item level,
-- and the enchant on each item (or a red "No enchant" for slots that can be enchanted).
-- Everything is drawn on the existing character frame; there is no separate window.
ForeverAssistCharacter={Version='1.9.10'}
local C=ForeverAssistCharacter
local function cfg() return ForeverAssistPlay and ForeverAssistPlay.Settings and ForeverAssistPlay.Settings() or {} end
local function safe(v) return not issecretvalue or not issecretvalue(v) end

local SLOTS={'Head','Neck','Shoulder','Back','Chest','Shirt','Tabard','Wrist','Hands','Waist','Legs','Feet','Finger0','Finger1','Trinket0','Trinket1','MainHand','SecondaryHand','Ranged'}
local LEFT={Head=1,Neck=1,Shoulder=1,Back=1,Chest=1,Shirt=1,Tabard=1,Wrist=1}
local BOTTOM={MainHand=1,SecondaryHand=1,Ranged=1}
-- Slots where players normally put an enchant; a missing one is flagged.
local ENCHANTABLE={Neck=1,Chest=1,Back=1,Wrist=1,Hands=1,Feet=1,MainHand=1,SecondaryHand=1}  -- Forever added neck enchants
local NO_ILVL={Shirt=1,Tabard=1}
local enchantPattern
do
 local fmt=ENCHANTED_TOOLTIP_LINE or 'Enchanted: %s'
 enchantPattern='^'..fmt:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]','%%%0'):gsub('%%%%s','(.+)')..'$'
end
local cache={}
local overlays={}
local avgText

local function itemLevel(link)
 if not link then return end
 local level=C_Item and C_Item.GetDetailedItemLevelInfo and C_Item.GetDetailedItemLevelInfo(link)
 if not level and GetDetailedItemLevelInfo then level=GetDetailedItemLevelInfo(link) end
 if not level then local _,_,_,l=GetItemInfo(link);level=l end
 if type(level)=='number' and safe(level) and level>0 then return level end
end
local function enchantId(link)
 local id=link and link:match('item:%d+:(%d*)')
 id=tonumber(id)
 return id and id>0 and id or nil
end
local function enchantText(slotId)
 local data=C_TooltipInfo and C_TooltipInfo.GetInventoryItem and C_TooltipInfo.GetInventoryItem('player',slotId)
 if type(data)~='table' or not data.lines then return end
 for _,line in ipairs(data.lines) do
  local text=line.leftText
  if type(text)=='string' and safe(text) then
   local name=text:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r','')
   local found=name:match(enchantPattern)
   if found then return found end
  end
 end
end
local function shortText(text)
 text=text:gsub('^Enchant %a+ %- ',''):gsub('^Enchant ','')
 if #text>22 then text=text:sub(1,21)..'…' end
 return text end
local function shortBottom(text) if #text>9 then text=text:sub(1,8)..'…' end
 return text
end
local function canBeEnchanted(name,link)
 if not ENCHANTABLE[name] then return false end
 if name=='SecondaryHand' or name=='MainHand' then
  local _,_,_,_,_,classId,subId=C_Item.GetItemInfoInstant(link)
  if classId==4 and subId~=6 and name=='SecondaryHand' then return false end -- off-hand frills cannot be enchanted; shields can
  if classId==2 and subId==20 then return false end                           -- fishing pole
  if classId~=2 and classId~=4 then return false end
 end
 return true
end
local function atMaxLevel()
 local max=GetMaxPlayerLevel and GetMaxPlayerLevel() or 60
 return (UnitLevel('player') or 1)>=max
end

local function overlay(button,name)
 local o=overlays[button]
 if o then return o end
 o={}
 o.ilvl=button:CreateFontString(nil,'OVERLAY')
 o.ilvl:SetFont(STANDARD_TEXT_FONT,12,'OUTLINE');o.ilvl:SetPoint('BOTTOM',button,'BOTTOM',0,3)
 o.ench=button:CreateFontString(nil,'OVERLAY')
 o.ench:SetFont(STANDARD_TEXT_FONT,10,'OUTLINE')
 if LEFT[name] then o.ench:SetPoint('LEFT',button,'RIGHT',6,-9);o.ench:SetJustifyH('LEFT')
 elseif BOTTOM[name] then o.ench:SetPoint('TOP',button,'BOTTOM',0,-2);o.ench:SetWidth(54);o.ench:SetJustifyH('CENTER');o.ench:SetWordWrap(false)
 else o.ench:SetPoint('RIGHT',button,'LEFT',-6,-9);o.ench:SetJustifyH('RIGHT') end
 overlays[button]=o
 return o
end

local function refreshSlot(name)
 local button=_G['Character'..name..'Slot']
 if not button then return end
 local o=overlay(button,name)
 local c=cfg()
 o.ilvl:SetText('');o.ench:SetText('')
 local slotId=button:GetID()
 local link=GetInventoryItemLink('player',slotId)
 if not link or not safe(link) then return end
 if c.charItemLevel~=false and not NO_ILVL[name] then
  local level=itemLevel(link)
  if level then
   local quality=C_Item.GetItemQualityByID and C_Item.GetItemQualityByID(link) or select(3,GetItemInfo(link))
   local color=quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
   if color then o.ilvl:SetTextColor(color.r,color.g,color.b) else o.ilvl:SetTextColor(1,1,1) end
   o.ilvl:SetText(level)
  end
 end
 if c.charEnchants~=false and not NO_ILVL[name] then
  if enchantId(link) then
   local key=slotId..link
   if cache[key]==nil then cache[key]=enchantText(slotId) or false end
   o.ench:SetTextColor(.35,1,.45)
   local label=shortText(cache[key] or 'Enchanted');o.ench:SetText(BOTTOM[name] and shortBottom(label) or label)
  elseif atMaxLevel() and canBeEnchanted(name,link) then
   o.ench:SetTextColor(1,.25,.25);o.ench:SetText(BOTTOM[name] and 'None' or 'No enchant')
  end
 end
end

local function averageLevel()
 if GetAverageItemLevel then
  local _,equipped=GetAverageItemLevel()
  if type(equipped)=='number' and safe(equipped) and equipped>0 then return equipped end
 end
 local total,count=0,0
 local mainLink=GetInventoryItemLink('player',16)
 local offLink=GetInventoryItemLink('player',17)
 for _,slotId in ipairs({1,2,3,15,5,9,10,6,7,8,11,12,13,14,16,17,18}) do
  local link=GetInventoryItemLink('player',slotId)
  local level=itemLevel(link)
  if level then total=total+level;count=count+1
  elseif slotId==17 and mainLink and not offLink then
   local l=itemLevel(mainLink);if l then total=total+l;count=count+1 end -- two-hander counts for both hands
  elseif slotId~=18 then count=count+1 end
 end
 if count>0 then return total/count end
end

function C.Update()
 if not PaperDollFrame and not CharacterFrame then return end
 for _,name in ipairs(SLOTS) do pcall(refreshSlot,name) end
 if not avgText then
  local parent=CharacterFrame or PaperDollFrame
  -- Own frame in a higher strata than the 3D model and the stats panes, so nothing paints over it.
  local holder=CreateFrame('Frame',nil,parent)
  holder:SetSize(170,18);holder:SetFrameStrata('DIALOG');holder:SetFrameLevel(parent:GetFrameLevel()+60)
  local anchor=_G.CharacterLevelText
  if anchor and anchor.GetText and anchor:GetText() and anchor:GetText()~='' then
   -- Same row as "Level 60 Priest", just to its right.
   holder:SetPoint('LEFT',anchor,'RIGHT',12,0)
  else holder:SetPoint('TOP',parent,'TOP',0,-34) end
  avgText=holder:CreateFontString(nil,'OVERLAY')
  avgText:SetFont(STANDARD_TEXT_FONT,13,'OUTLINE');avgText:SetPoint('LEFT',holder,'LEFT',0,0);avgText:SetJustifyH('LEFT')
  C.holder=holder
 end
 C.lastError=nil
 if cfg().charItemLevel==false then avgText:SetText('');return end
 local ok,level=pcall(averageLevel)
 if not ok then C.lastError=level end
 if ok and level then avgText:SetText(string.format('|cffd2b077iLvl|r |cffffffff%.1f|r',level)) else avgText:SetText('') end
end

local pendingUpdate=false
local function schedule()
 if pendingUpdate then return end
 pendingUpdate=true
 local run=function() pendingUpdate=false;if CharacterFrame and CharacterFrame:IsShown() then pcall(C.Update) end end
 if C_Timer and C_Timer.After then C_Timer.After(.15,run) else run() end
end

local events=CreateFrame('Frame')
for _,e in ipairs({'PLAYER_EQUIPMENT_CHANGED','UNIT_INVENTORY_CHANGED','PLAYER_LEVEL_UP','GET_ITEM_INFO_RECEIVED','PLAYER_ENTERING_WORLD'}) do pcall(events.RegisterEvent,events,e) end
events:SetScript('OnEvent',function(_,event)
 if event=='PLAYER_EQUIPMENT_CHANGED' then wipe(cache) end
 schedule()
end)

local hooked=false
local function hook()
 if hooked or not CharacterFrame then return end
 hooked=true
 CharacterFrame:HookScript('OnShow',function() wipe(cache);schedule() end)
 if PaperDollFrame then PaperDollFrame:HookScript('OnShow',schedule) end
 if _G.PaperDollItemSlotButton_Update then hooksecurefunc('PaperDollItemSlotButton_Update',schedule) end
end
local loader=CreateFrame('Frame')
loader:RegisterEvent('PLAYER_LOGIN');loader:RegisterEvent('ADDON_LOADED')
loader:SetScript('OnEvent',function() pcall(hook) end)

function C.Debug()
 local function p(t) print('|cffd2b077Trailbound char:|r '..t) end
 p('CharacterFrame='..tostring(CharacterFrame~=nil)..' shown='..tostring(CharacterFrame and CharacterFrame:IsShown())..' levelText='..tostring(_G.CharacterLevelText and _G.CharacterLevelText:GetText()))
 local api,equipped=nil,nil
 if GetAverageItemLevel then api,equipped=GetAverageItemLevel() end
 p('GetAverageItemLevel -> '..tostring(api)..' / '..tostring(equipped))
 local ok,v=pcall(averageLevel);p('computed -> '..tostring(v)..(ok and '' or ' (error)'))
 p('text created='..tostring(avgText~=nil)..' text="'..tostring(avgText and avgText:GetText())..'" visible='..tostring(C.holder and C.holder:IsVisible()))
 if C.lastError then p('last error: '..tostring(C.lastError)) end
end
