-- Vendors and mail conveniences:
--  * Shift-click an item at a vendor: choose ANY quantity (not just one stack); it is bought as
--    several stacks.
--  * Ctrl+right-click an item in your bags while the mail Send tab is open: attach every stack of it.
ForeverAssistTrade={Version='1.8.98'}
local T=ForeverAssistTrade
local function combat() return InCombatLockdown and InCombatLockdown() end
local function safe(v) return not issecretvalue or not issecretvalue(v) end
local function say(text) print('|cffd2b077Trailbound:|r '..text) end
local function editBoxOf(dialog) return dialog.editBox or dialog.EditBox or (dialog.GetEditBox and dialog:GetEditBox()) end

-- ---------------------------------------------------------------- vendor: any quantity
function T.MaxStack(index)
 local fn=GetMerchantItemMaxStack or (C_MerchantFrame and C_MerchantFrame.GetMerchantItemMaxStack)
 local ok,value=pcall(function() return fn and fn(index) end)
 return ok and type(value)=='number' and value>0 and value or 1
end
-- GetMerchantItemInfo was replaced by C_MerchantFrame.GetItemInfo, which returns a table.
local function merchantInfo(index)
 local name,price,stackCount,numAvailable
 if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
  local info=C_MerchantFrame.GetItemInfo(index)
  if type(info)=='table' then name,price,stackCount,numAvailable=info.name,info.price,info.stackCount,info.numAvailable end
 elseif GetMerchantItemInfo then
  local n,_,p,s,a=GetMerchantItemInfo(index);name,price,stackCount,numAvailable=n,p,s,a
 end
 return name,price,(type(stackCount)=='number' and stackCount>0 and stackCount or 1),numAvailable
end
function T.Buy(data,total)
 if combat() or type(data)~='table' or not data.index then return end
 if not MerchantFrame or not MerchantFrame:IsShown() then return end
 total=tonumber(total);if not total or total<1 then return end
 total=math.floor(total)
 local index=data.index
 -- The merchant page may have changed while the box was open.
 if GetMerchantItemLink(index)~=data.link then say('That vendor slot changed; shift-click the item again.');return end
 local name,price,stackCount,numAvailable=merchantInfo(index)
 local maxStack=T.MaxStack(index)
 local limit=total
 if type(numAvailable)=='number' and numAvailable>=0 then limit=math.min(limit,numAvailable*stackCount) end
 if price and price>0 then limit=math.min(limit,math.floor(GetMoney()/(price/stackCount))) end
 if limit<1 then say('You cannot buy any of that right now (gold or vendor stock).');return end
 if limit<total then say(('Buying %d instead of %d (all you can afford or the vendor has).'):format(limit,total)) end
 local remaining,step=limit,0
 while remaining>0 do
  local chunk=math.min(remaining,maxStack)
  step=step+1
  C_Timer.After((step-1)*0.12,function()
   if MerchantFrame and MerchantFrame:IsShown() and GetMerchantItemLink(index)==data.link then BuyMerchantItem(index,chunk) end
  end)
  remaining=remaining-chunk
 end
 if step>1 then say(('Buying %d x %s as %d stacks.'):format(limit,data.link or name or 'item',step)) end
end
StaticPopupDialogs['FOREVERASSIST_BULK_BUY']={
 text='Buy how many %s?\nAny amount: it is bought as several stacks.',button1=ACCEPT,button2=CANCEL,hasEditBox=1,maxLetters=7,
 OnShow=function(self,data)
  local box=editBoxOf(self);if box then box:SetText(tostring(data and data.default or 1));box:HighlightText();box:SetFocus() end
 end,
 OnAccept=function(self,data) local box=editBoxOf(self);T.Buy(data or self.data,box and tonumber(box:GetText())) end,
 EditBoxOnEnterPressed=function(self)
  local parent=self:GetParent();T.Buy(parent.data,tonumber(self:GetText()));parent:Hide()
 end,
 EditBoxOnEscapePressed=function(self) self:GetParent():Hide() end,
 timeout=0,whileDead=false,hideOnEscape=true,preferredIndex=3,
}
local function merchantButtonIndex(frame)
 local name=frame and frame.GetName and frame:GetName()
 if name and name:find('^MerchantItem%d+ItemButton$') and frame.GetID then return frame:GetID() end
end
local function hookSplit()
 if T.splitHooked or not StackSplitFrame or not StackSplitFrame.OpenStackSplitFrame then return end
 T.splitHooked=true
 hooksecurefunc(StackSplitFrame,'OpenStackSplitFrame',function(self,maxStack,parent)
  if combat() or not MerchantFrame or not MerchantFrame:IsShown() then return end
  local index=merchantButtonIndex(parent)
  if not index then return end
  local link=GetMerchantItemLink(index);if not link then return end
  self:Hide()
  local maxItems=T.MaxStack(index)
  StaticPopup_Show('FOREVERASSIST_BULK_BUY',link,nil,{index=index,link=link,default=maxItems})
 end)
end

-- ---------------------------------------------------------------- mail: attach every stack
local attaching=false
local function sendTabOpen() return MailFrame and MailFrame:IsShown() and SendMailFrame and SendMailFrame:IsShown() end
local function freeAttachments()
 local free=0
 for i=1,(ATTACHMENTS_MAX_SEND or 12) do if not GetSendMailItem(i) then free=free+1 end end
 return free
end
local function attachAllStacks(bag,slot)
 if attaching or combat() or not sendTabOpen() then return end
 local info=C_Container.GetContainerItemInfo(bag,slot)
 local id=info and safe(info) and info.itemID
 if not id then return end
 local targets={}
 for b=0,(NUM_BAG_SLOTS or 4) do
  for s=1,(C_Container.GetContainerNumSlots(b) or 0) do
   if not (b==bag and s==slot) then
    local other=C_Container.GetContainerItemInfo(b,s)
    if other and safe(other) and other.itemID==id and not other.isLocked then targets[#targets+1]={b,s} end
   end
  end
 end
 if #targets==0 then return end
 attaching=true
 local done=0
 for i,t in ipairs(targets) do
  C_Timer.After(i*0.1,function() if sendTabOpen() then pcall(C_Container.UseContainerItem,t[1],t[2]);done=done+1 end end)
 end
 C_Timer.After(#targets*0.1+0.4,function()
  attaching=false
  say(('Attached the other %d stack%s of %s to the mail (up to %d attachments fit).'):format(#targets,#targets==1 and '' or 's',info.hyperlink or 'that item',ATTACHMENTS_MAX_SEND or 12))
 end)
end
local function hookMail()
 if T.mailHooked then return end
 T.mailHooked=true
 -- Normal right-click use of an item (attaches it while the Send tab is open).
 if C_Container and C_Container.UseContainerItem then
  hooksecurefunc(C_Container,'UseContainerItem',function(bag,slot)
   if attaching or not (IsControlKeyDown and IsControlKeyDown()) then return end
   attachAllStacks(bag,slot)
  end)
 end
 -- Ctrl-modified clicks go through the item-click handler; find the button under the mouse.
 if HandleModifiedItemClick then
  hooksecurefunc('HandleModifiedItemClick',function()
   if attaching or not sendTabOpen() or not (IsControlKeyDown and IsControlKeyDown()) then return end
   if not (IsMouseButtonDown and IsMouseButtonDown('RightButton')) then return end
   local focus=GetMouseFoci and GetMouseFoci()
   focus=type(focus)=='table' and focus[1] or (GetMouseFocus and GetMouseFocus())
   if focus and focus.GetBagID and focus.GetID then
    local bag,slot=focus:GetBagID(),focus:GetID()
    if bag and slot then attachAllStacks(bag,slot) end
   end
  end)
 end
end

local events=CreateFrame('Frame')
for _,e in ipairs({'PLAYER_LOGIN','MERCHANT_SHOW','MAIL_SHOW'}) do pcall(events.RegisterEvent,events,e) end
events:SetScript('OnEvent',function() pcall(hookSplit);pcall(hookMail) end)
