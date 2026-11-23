-- PvP helpers.
--  * In arenas and battlegrounds Tab targets enemy PLAYERS only (no critters, pets or NPCs).
--    Everywhere else (dungeons, raids, open world) Tab is left exactly as the game has it.
--  * Optional automatic spirit release when you die in a battleground.
-- Tab is switched with override bindings, which the game only allows outside combat, so the
-- binding is refreshed on zone changes and when combat ends.
ForeverAssistPvP={Version='1.9.5'}
local V=ForeverAssistPvP
local function combat() return InCombatLockdown and InCombatLockdown() end
local function cfg() return ForeverAssistPlay and ForeverAssistPlay.Settings and ForeverAssistPlay.Settings() or {} end
local owner=CreateFrame('Frame')
local pending=false

local function instanceType()
 local ok,_,kind=pcall(IsInInstance)
 if ok then return kind end
end
local function inPvPZone()
 local kind=instanceType()
 return kind=='arena' or kind=='pvp'
end

local function bindKeys(action,fallback)
 local keys={GetBindingKey(action)}
 if #keys==0 and fallback then keys={fallback} end
 return keys
end

function V.Update()
 if combat() then pending=true;return end
 pending=false
 ClearOverrideBindings(owner)
 if cfg().pvpTabPlayers==false or not inPvPZone() then return end
 for _,key in ipairs(bindKeys('TARGETNEARESTENEMY','TAB')) do
  pcall(SetOverrideBinding,owner,true,key,'TARGETNEARESTENEMYPLAYER')
 end
 for _,key in ipairs(bindKeys('TARGETPREVIOUSENEMY','SHIFT-TAB')) do
  pcall(SetOverrideBinding,owner,true,key,'TARGETPREVIOUSENEMYPLAYER')
 end
end

local function canSelfResurrect()
 if HasSoulstone and HasSoulstone() then return true end
 return false
end
local function release()
 if cfg().bgRelease~=true or instanceType()~='pvp' then return end
 if not UnitIsDead('player') or UnitIsGhost('player') then return end
 if IsShiftKeyDown and IsShiftKeyDown() then return end
 if canSelfResurrect() then return end
 pcall(RepopMe)
end

local events=CreateFrame('Frame')
for _,e in ipairs({'PLAYER_ENTERING_WORLD','ZONE_CHANGED_NEW_AREA','PLAYER_REGEN_ENABLED','UPDATE_BINDINGS','PLAYER_DEAD'}) do pcall(events.RegisterEvent,events,e) end
events:SetScript('OnEvent',function(_,event)
 if event=='PLAYER_DEAD' then
  if C_Timer and C_Timer.After then C_Timer.After(.6,release) else release() end
 elseif event=='PLAYER_REGEN_ENABLED' then
  if pending then V.Update() end
 else
  V.Update()
 end
end)
