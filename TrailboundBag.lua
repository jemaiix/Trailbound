-- Optional Trailbound bag window. It replaces the combined backpack on screen with one window that
-- also holds the reagent bag, using Blizzard's portrait-frame chrome and secure container item
-- buttons (so right-click use, drag, split and modified clicks behave like the normal bag).
-- Opt-in (Bags settings). The Blizzard frame is only parked off-screen while it is active.
ForeverAssistBag={Version='1.8.98'}
local B=ForeverAssistBag
local SIZE,GAP,COLS,PAD=37,5,10,14
local REAGENT=(Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag) or 5
local function combat() return InCombatLockdown and InCombatLockdown() end
local function safe(v) return not issecretvalue or not issecretvalue(v) end
local function cfg() return ForeverAssistPlay and ForeverAssistPlay.Settings and ForeverAssistPlay.Settings() or {} end
local function say(text) print('|cffd2b077Trailbound:|r '..text) end
local window,holders,buttons,disabled,search,layoutKey={}, {}, {}, false,'',nil
local pending=false
local searchCache={}

local function usingCombined()
 local m=ContainerFrameSettingsManager
 if not m or not m.IsUsingCombinedBags then return false end
 local ok,v=pcall(m.IsUsingCombinedBags,m);return ok and v and true or false
end
function B.Active()
 local c=cfg()
 -- 1.8.91 briefly defaulted this on; it is an opt-in experiment, so reset it once.
 if c.bagDefaultV~=67 then c.customBag=false;c.bagDefaultV=67 end
 return c.customBag==true and not disabled and usingCombined()
end

local function slotCount(bag) local n=C_Container.GetContainerNumSlots(bag);return type(n)=='number' and n or 0 end
local function generalSlots()
 local list={}
 for bag=0,(NUM_BAG_SLOTS or 4) do for slot=1,slotCount(bag) do list[#list+1]={bag,slot} end end
 return list
end
local function reagentSlots()
 local list={}
 for slot=1,slotCount(REAGENT) do list[#list+1]={REAGENT,slot} end
 return list
end

local function makeButton(bag,slot)
 holders[bag]=holders[bag] or (function() local h=CreateFrame('Frame',nil,window);h:SetAllPoints(window);h:SetID(bag);return h end)()
 local ok,btn=pcall(CreateFrame,'ItemButton',nil,holders[bag],'ContainerFrameItemButtonTemplate')
 if not ok or not btn then ok,btn=pcall(CreateFrame,'Button',nil,holders[bag],'ContainerFrameItemButtonTemplate') end
 if not ok or not btn then return nil,btn end
 btn:SetID(slot);btn.bag=bag;btn.slot=slot;btn:SetSize(SIZE,SIZE)
 btn.tbEmpty=btn:CreateTexture(nil,'BACKGROUND',nil,2);btn.tbEmpty:SetAllPoints();btn.tbEmpty:Hide()
 return btn
end

local function haystack(id)
 local text=searchCache[id]
 if text then return text end
 local name=C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(id) or ''
 local _,kind,sub=C_Item and C_Item.GetItemInfoInstant and C_Item.GetItemInfoInstant(id)
 text=((name or '')..' '..(kind or '')..' '..(sub or '')):lower()
 if name and name~='' then searchCache[id]=text end
 return text
end
local function matches(info)
 if search=='' then return true end
 if not info then return false end
 local text=haystack(info.itemID)
 for term in search:gmatch('[^|]+') do
  term=term:match('^%s*(.-)%s*$')
  if term~='' and text:find(term,1,true) then return true end
 end
 return false
end

local emptyArt
local function findEmptyArt()
 if emptyArt then return emptyArt end
 local f=ContainerFrameCombinedBags
 for _,item in ipairs(f and f.Items or {}) do
  local bag,id=item.GetBagID and item:GetBagID(),item.GetID and item:GetID()
  if bag and id and not C_Container.GetContainerItemInfo(bag,id) then
   local icon=item.icon or item.Icon
   if icon then
    local atlas=icon.GetAtlas and icon:GetAtlas()
    if atlas and safe(atlas) and atlas~='' then emptyArt={atlas=atlas};return emptyArt end
    local tex=icon.GetTexture and icon:GetTexture()
    if tex and safe(tex) and icon.GetTexCoord then emptyArt={tex=tex,coords={icon:GetTexCoord()}};return emptyArt end
   end
  end
 end
end

local function paint(btn)
 local info=C_Container.GetContainerItemInfo(btn.bag,btn.slot)
 if info and not safe(info) then info=nil end
 if info and info.iconFileID and safe(info.iconFileID) then
  SetItemButtonTexture(btn,info.iconFileID);SetItemButtonCount(btn,info.stackCount or 1)
  if SetItemButtonDesaturated then SetItemButtonDesaturated(btn,info.isLocked and true or false) end
  if SetItemButtonQuality then pcall(SetItemButtonQuality,btn,info.quality,info.hyperlink) end
  btn.tbEmpty:Hide()
 else
  SetItemButtonTexture(btn,nil);SetItemButtonCount(btn,0)
  if SetItemButtonQuality then pcall(SetItemButtonQuality,btn,nil) end
  local art=findEmptyArt()
  if art then
   if art.atlas then btn.tbEmpty:SetAtlas(art.atlas) else btn.tbEmpty:SetTexture(art.tex);btn.tbEmpty:SetTexCoord(unpack(art.coords)) end
   btn.tbEmpty:SetVertexColor(btn.bag==REAGENT and .62 or 1,btn.bag==REAGENT and .95 or 1,btn.bag==REAGENT and .88 or 1);btn.tbEmpty:Show()
  end
 end
 if btn.Cooldown or btn.cooldown then
  local ok,start,duration,enable=pcall(C_Container.GetContainerItemCooldown,btn.bag,btn.slot)
  local cd=btn.Cooldown or btn.cooldown
  if ok and type(start)=='number' and type(duration)=='number' and CooldownFrame_Set then CooldownFrame_Set(cd,start,duration,enable) end
 end
 btn:SetAlpha(matches(info) and 1 or .25)
end

local function create()
 if window.frame then return window.frame end
 local made,frame=pcall(CreateFrame,'Frame','TrailboundBagWindow',UIParent,'PortraitFrameTemplate')
 if not made or not frame then error('PortraitFrameTemplate unavailable: '..tostring(frame)) end
 window.frame=frame
 if frame.SetTitle then frame:SetTitle('Backpack') elseif frame.TitleText then frame.TitleText:SetText('Backpack') end
 if frame.SetPortraitToAsset then pcall(frame.SetPortraitToAsset,frame,'Interface/Buttons/Button-Backpack-Up') end
 frame:SetClampedToScreen(true);frame:SetMovable(true);frame:EnableMouse(true);frame:SetToplevel(true);frame:SetFrameStrata('MEDIUM')
 -- Drag from the title strip.
 local drag=CreateFrame('Frame',nil,frame);drag:SetPoint('TOPLEFT',58,-2);drag:SetPoint('TOPRIGHT',-30,-2);drag:SetHeight(24);drag:EnableMouse(true);drag:RegisterForDrag('LeftButton')
 drag:SetScript('OnDragStart',function() if not combat() then frame:StartMoving() end end)
 drag:SetScript('OnDragStop',function()
  frame:StopMovingOrSizing();if frame.SetUserPlaced then frame:SetUserPlaced(false) end
  local x,y=frame:GetCenter();local ux,uy=UIParent:GetCenter()
  if x and ux then local s=frame:GetEffectiveScale()/UIParent:GetEffectiveScale();cfg().customBagPos={x*s-ux,y*s-uy} end
 end)
 -- Search: plain words, or alternatives with | (food|potion). Matches name, type and subtype.
 local box=CreateFrame('EditBox',nil,frame,'SearchBoxTemplate');box:SetPoint('TOPLEFT',frame,'TOPLEFT',PAD+6,-34);box:SetSize(260,20);box:SetAutoFocus(false)
 window.box=box
 box:SetScript('OnTextChanged',function(self) if SearchBoxTemplate_OnTextChanged then SearchBoxTemplate_OnTextChanged(self) end;search=(self:GetText() or ''):lower();B.Paint() end)
 box:SetScript('OnEscapePressed',function(self) self:SetText('');self:ClearFocus() end)
 -- Sort
 local sort=CreateFrame('Button',nil,frame);sort:SetSize(22,22);sort:SetPoint('LEFT',box,'RIGHT',8,0)
 sort.icon=sort:CreateTexture(nil,'ARTWORK');sort.icon:SetAllPoints();sort.icon:SetTexture('Interface/ICONS/INV_Pet_Broom')
 sort:SetScript('OnClick',function() if not combat() and C_Container.SortBags then C_Container.SortBags() end end)
 sort:SetScript('OnEnter',function(self) GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText('Sort bags');GameTooltip:Show() end)
 sort:SetScript('OnLeave',function() GameTooltip:Hide() end)
 window.divider=frame:CreateTexture(nil,'ARTWORK');window.divider:SetColorTexture(.55,.42,.2,.9);window.divider:SetHeight(1)
 window.money=frame:CreateFontString(nil,'OVERLAY','GameFontHighlight');window.money:SetPoint('BOTTOMRIGHT',-PAD-4,PAD-2)
 window.free=frame:CreateFontString(nil,'OVERLAY','GameFontNormalSmall');window.free:SetPoint('BOTTOMLEFT',PAD+4,PAD)
 frame:Hide()
 return frame
end

function B.Layout()
 if combat() then pending=true;return end
 local frame=create()
 local general,reagent=generalSlots(),reagentSlots()
 local key=#general..':'..#reagent
 local rowsG=math.max(1,math.ceil(#general/COLS));local rowsR=math.ceil(#reagent/COLS)
 local top=66;local step=SIZE+GAP
 local width=PAD*2+COLS*step-GAP
 local height=top+rowsG*step-GAP+(rowsR>0 and (14+rowsR*step-GAP) or 0)+44
 frame:SetSize(width,height)
 local function place(list,startY)
  for i,pair in ipairs(list) do
   local bag,slot=pair[1],pair[2];local id=bag..':'..slot
   local btn=buttons[id]
   if not btn then
    local made,err=makeButton(bag,slot)
    if not made then error('Item button creation failed: '..tostring(err)) end
    btn=made;buttons[id]=btn
   end
   local row,col=math.floor((i-1)/COLS),(i-1)%COLS
   btn:ClearAllPoints();btn:SetPoint('TOPLEFT',frame,'TOPLEFT',PAD+col*step,-(startY+row*step));btn:Show()
  end
 end
 place(general,top)
 place(reagent,top+rowsG*step-GAP+14)
 -- Hide buttons whose slot no longer exists (bag swapped for a smaller one).
 local live={};for _,p in ipairs(general) do live[p[1]..':'..p[2]]=true end;for _,p in ipairs(reagent) do live[p[1]..':'..p[2]]=true end
 for id,btn in pairs(buttons) do if not live[id] then btn:Hide() end end
 window.divider:ClearAllPoints()
 if rowsR>0 then window.divider:SetPoint('TOPLEFT',frame,'TOPLEFT',PAD,-(top+rowsG*step-GAP+6));window.divider:SetPoint('TOPRIGHT',frame,'TOPRIGHT',-PAD,-(top+rowsG*step-GAP+6));window.divider:Show() else window.divider:Hide() end
 layoutKey=key
end

function B.Paint()
 if not window.frame or not window.frame:IsShown() then return end
 for _,btn in pairs(buttons) do if btn:IsShown() then paint(btn) end end
 window.money:SetText(GetMoneyString and GetMoneyString(GetMoney(),true) or tostring(GetMoney()))
 local free=0
 for bag=0,(NUM_BAG_SLOTS or 4) do local n,kind=C_Container.GetContainerNumFreeSlots(bag);if type(n)=='number' and (kind==nil or kind==0) then free=free+n end end
 window.free:SetText('Free: '..free)
end

-- Trailbound's own buttons hang off the Blizzard frame; follow the window while it is active.
local followed={'faAccountButton','faBankButton','faAccountGold'}
local origin={}
local function reanchor(toWindow)
 local f=ContainerFrameCombinedBags;if not f then return end
 for _,name in ipairs(followed) do
  local piece=f[name]
  if piece and piece.GetPoint and piece.ClearAllPoints and not combat() then
   if toWindow then
    local point,rel,relPoint,x,y=piece:GetPoint(1)
    if rel==f then origin[name]={point,relPoint,x,y};piece:ClearAllPoints();piece:SetPoint(point,window.frame,relPoint,x,y) end
   elseif origin[name] then
    local o=origin[name];piece:ClearAllPoints();piece:SetPoint(o[1],f,o[2],o[3],o[4]);origin[name]=nil
   end
  end
 end
end
local function park()
 local f=ContainerFrameCombinedBags
 if f and B.Active() and f:IsShown() and not combat() then f:ClearAllPoints();f:SetPoint('TOPLEFT',UIParent,'TOPLEFT',-6000,6000) end
end

local function fail(err)
 if disabled then return end
 disabled=true
 if window.frame then window.frame:Hide() end
 say('The Trailbound bag window was switched off after an error and the normal bag is back: '..tostring(err))
 if not combat() then reanchor(false) end
end

function B.Show()
 if not B.Active() then return end
 local ok,err=pcall(function()
  local frame=create()
  if combat() then pending=true else B.Layout() end
  frame:ClearAllPoints()
  local pos=cfg().customBagPos
  if type(pos)=='table' and type(pos[1])=='number' then frame:SetPoint('CENTER',UIParent,'CENTER',pos[1],pos[2]) else frame:SetPoint('BOTTOMRIGHT',UIParent,'BOTTOMRIGHT',-30,95) end
  frame:Show();reanchor(true);park();B.Paint()
 end)
 if not ok then fail(err) end
end
function B.Hide()
 if window.frame and window.frame:IsShown() then window.frame:Hide() end
end
-- Settings changed: switch between the Blizzard bag and this window without closing the bags.
function B.Refresh()
 local f=ContainerFrameCombinedBags;if not f then return end
 if B.Active() then
  if f:IsShown() then B.Show() end
 else
  B.Hide()
  if not combat() then reanchor(false) end
 end
end

local function install()
 local f=ContainerFrameCombinedBags
 if not f or f.tbBagHooked then return end
 f.tbBagHooked=true
 f:HookScript('OnShow',function() B.Show() end)
 f:HookScript('OnHide',function() B.Hide() end)
 if UpdateContainerFrameAnchors then hooksecurefunc('UpdateContainerFrameAnchors',function() park();if B.Active() and f:IsShown() and window.frame and not window.frame:IsShown() then B.Show() end end) end
end
local events=CreateFrame('Frame')
for _,e in ipairs({'PLAYER_LOGIN','BAG_UPDATE_DELAYED','ITEM_LOCK_CHANGED','BAG_UPDATE_COOLDOWN','PLAYER_MONEY','PLAYER_REGEN_ENABLED'}) do pcall(events.RegisterEvent,events,e) end
events:SetScript('OnEvent',function(_,event)
 install()
 if not B.Active() or not window.frame or not window.frame:IsShown() then return end
 local ok,err=pcall(function()
  if event=='PLAYER_REGEN_ENABLED' and pending then pending=false;B.Layout();reanchor(true);park() end
  if event=='BAG_UPDATE_DELAYED' and not combat() then
   local general,reagent=generalSlots(),reagentSlots()
   if layoutKey~=#general..':'..#reagent then B.Layout() end
  end
  B.Paint()
 end)
 if not ok then fail(err) end
end)
