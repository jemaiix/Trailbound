-- Fish with the space bar. Only while a fishing pole is equipped (and the option is on):
--   Space casts Fishing (first applying a lure from your bags when the pole has none),
--   Space while the line is out interacts with the bobber to reel the fish in.
-- Without a fishing pole equipped nothing is bound and Space behaves normally.
-- Bindings are override bindings on a secure button, so they are never active in combat.
ForeverAssistFishing={Version='1.8.96'}
local F=ForeverAssistFishing
local FISHING_SPELL=7620
local LURES={6533,6532,7307,6530,6529}   -- strongest first: Aquadynamic Fish Attractor, Bright Baubles, Flesh Eating Worm, Nightcrawlers, Shiny Bauble
local function combat() return InCombatLockdown and InCombatLockdown() end
local function safe(v) return not issecretvalue or not issecretvalue(v) end
local function cfg() return ForeverAssistPlay and ForeverAssistPlay.Settings and ForeverAssistPlay.Settings() or {} end
local function say(text) print('|cffd2b077Trailbound:|r '..text) end

local owner=CreateFrame('Frame')
local button=CreateFrame('Button','TrailboundFishButton',UIParent,'SecureActionButtonTemplate')
button:RegisterForClicks('AnyUp','AnyDown')
button:SetAttribute('type','macro')
local lastChannelStop,pending=0,false

local function poleEquipped()
 local id=GetInventoryItemID and GetInventoryItemID('player',16)
 if not id or not safe(id) then return false end
 local instant=C_Item and C_Item.GetItemInfoInstant
 if not instant then return false end
 local _,_,subName,_,_,classID,subclassID=instant(id)
 if classID==2 and subclassID==20 then return true end      -- weapon class, fishing pole subclass
 return type(subName)=='string' and safe(subName) and subName:lower():find('fishing pole',1,true)~=nil
end
local function fishingName()
 local info=C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(FISHING_SPELL)
 if type(info)=='table' and info.name then return info.name end
 local name=GetSpellInfo and GetSpellInfo(FISHING_SPELL)
 return name or 'Fishing'
end
local function bestLure()
 local count=C_Item and C_Item.GetItemCount or GetItemCount
 if not count then return end
 for _,id in ipairs(LURES) do
  local ok,n=pcall(count,id,false)
  if ok and safe(n) and type(n)=='number' and n>0 then return id end
 end
end
-- What Space does when the line is not out: apply a lure if the pole has none, else cast.
local function castMacro()
 if cfg().fishLure~=false and GetWeaponEnchantInfo then
  local ok,hasMain=pcall(GetWeaponEnchantInfo)
  if ok and not hasMain then
   local lure=bestLure()
   if lure then return '/use item:'..lure..'\n/use 16' end
  end
 end
 return '/cast '..fishingName()
end

-- Louder fishing: SFX to full, music/ambience/dialog turned down, so the bobber splash stands out.
-- Originals are saved and put back as soon as the pole is not equipped (or on logout).
local SOUND_CVARS={'Sound_SFXVolume','Sound_MusicVolume','Sound_AmbienceVolume','Sound_DialogVolume'}
local function setSound(name,value) if SetCVar then pcall(SetCVar,name,tostring(value)) end end
local function restoreSounds()
 local c=cfg()
 if c.fishSavedSound then
  for name,value in pairs(c.fishSavedSound) do if value~=nil then setSound(name,value) end end
  c.fishSavedSound=nil
 end
 F.soundsActive=false
end
function F.UpdateSounds()
 local c=cfg()
 local want=c.fishSounds~=false and poleEquipped()
 if want then
  if F.soundsActive then return end
  if not c.fishSavedSound then
   local saved={}
   for _,name in ipairs(SOUND_CVARS) do saved[name]=GetCVar and GetCVar(name) end
   c.fishSavedSound=saved
  end
  local s=c.fishSavedSound
  setSound('Sound_SFXVolume',1)
  setSound('Sound_MusicVolume',math.min(tonumber(s.Sound_MusicVolume) or 0,.1))
  setSound('Sound_AmbienceVolume',math.min(tonumber(s.Sound_AmbienceVolume) or 0,.2))
  setSound('Sound_DialogVolume',math.min(tonumber(s.Sound_DialogVolume) or 0,.3))
  F.soundsActive=true
 elseif F.soundsActive or c.fishSavedSound then
  restoreSounds()
 end
end
function F.Update()
 pcall(F.UpdateSounds)
 if combat() then pending=true;return end
 pending=false
 ClearOverrideBindings(owner)
 if cfg().fishSpace~=true or not poleEquipped() then return end
 local channeling=UnitChannelInfo and UnitChannelInfo('player')
 if channeling then
  -- Line is out: Space interacts with the bobber (reels in / loots the fish).
  SetOverrideBinding(owner,true,'SPACE','INTERACTTARGET')
 else
  button:SetAttribute('macrotext',castMacro())
  SetOverrideBindingClick(owner,true,'SPACE','TrailboundFishButton')
 end
end

-- The bobber is a soft interact target; make sure the client allows interacting with it.
function F.Apply()
 local c=cfg()
 if c.fishSpace==true then
  if GetCVar and SetCVar and not combat() then
   local current=GetCVar('softTargetInteract')
   if current=='0' or current=='1' then
    c.fishPrevSoftInteract=current
    SetCVar('softTargetInteract','3')
    say('Fishing: turned on "interact with target" so Space can reel in the bobber.')
   end
  end
 elseif c.fishPrevSoftInteract and not combat() then
  SetCVar('softTargetInteract',c.fishPrevSoftInteract);c.fishPrevSoftInteract=nil
 end
 F.Update()
end

local events=CreateFrame('Frame')
for _,e in ipairs({'PLAYER_LOGOUT','PLAYER_ENTERING_WORLD','PLAYER_EQUIPMENT_CHANGED','UNIT_SPELLCAST_CHANNEL_START','UNIT_SPELLCAST_CHANNEL_STOP','UNIT_SPELLCAST_STOP','UNIT_SPELLCAST_INTERRUPTED','UNIT_SPELLCAST_SUCCEEDED','UNIT_INVENTORY_CHANGED','BAG_UPDATE_DELAYED','PLAYER_REGEN_ENABLED','LOOT_READY','LOOT_CLOSED'}) do pcall(events.RegisterEvent,events,e) end
events:SetScript('OnEvent',function(_,event,unit)
 if event=='PLAYER_LOGOUT' then pcall(restoreSounds);return end
 if event=='LOOT_READY' then
  -- With auto-loot off the fish would sit in the loot window; take it right away while fishing.
  local autoLoot=unit
  if cfg().fishSpace==true and poleEquipped() and GetTime()-lastChannelStop<4 and not autoLoot and GetNumLootItems and not combat() then
   for i=GetNumLootItems(),1,-1 do pcall(LootSlot,i) end
  end
  return
 end
 if type(unit)=='string' and unit~='player' and event:find('^UNIT_') then return end
 if event=='UNIT_SPELLCAST_CHANNEL_STOP' then lastChannelStop=GetTime() end
 -- The channel state changes a moment after the event; re-evaluate immediately and once more shortly after.
 F.Update()
 if C_Timer then C_Timer.After(.15,function() F.Update() end) end
end)
