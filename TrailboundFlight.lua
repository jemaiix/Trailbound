ForeverAssistFlight={Version='1.9.5'}
local F=ForeverAssistFlight
local account,character,settings,root,nodes,pending,flight
local function readable(v)return not issecretvalue or not issecretvalue(v)end
local function clock(n)n=math.max(0,math.ceil(n));return ('%d:%02d'):format(math.floor(n/60),n%60)end
-- Reference flight times. Exact flights you take always replace these (learned per route, account-wide).
-- MEASURED: seconds from real Forever flights (foreverdb.net travel planner, few flights each).
-- ROUGH: whole minutes per route from wow-travelcraft.com, accurate to about a minute only.
local MEASURED_TEXT=[[
Tarren Mill>Undercity=139
Lakeshire>Sentinel Hill=134
Sentinel Hill>Lakeshire=130
Zoram'gar Outpost>Crossroads=228
Ironforge>Stormwind=210
Talrendis Point>Astranaar=153
Crossroads>Sun Rock Retreat=150
Ironforge>Menethil Harbor=129
Stormwind>Darkshire=116
Camp Taurajo>Thunder Bluff=114
Thelsamar>Ironforge=109
Ironforge>Thelsamar=101
Splintertree Post>Orgrimmar=96
Crossroads>Camp Taurajo=90
Menethil Harbor>Ironforge=89
Darkshire>Stormwind=88
Thunder Bluff>Camp Taurajo=87
Sepulcher>Tarren Mill=74
Tarren Mill>Sepulcher=74
Lakeshire>Darkshire=61
]]
local ROUGH_TEXT=[[
H|Orgrimmar|Splintertree Post=1,Valormok=2,The Crossroads=2,Ratchet=3,Camp Taurajo=3,Thunder Bluff=3,Brackenwall Village=4,Zoram'gar Outpost=4
H|Thunder Bluff|Camp Taurajo=1,Shadowprey Village=3,The Crossroads=3,Sun Rock Retreat=3,Freewind Post=3,Orgrimmar=3,Ratchet=4,Brackenwall Village=4
A|Rut'theran Village|Auberdine=1,Nighthaven=3,Astranaar=4,Nijel's Point=6,Theramore Isle=12
A|Auberdine|Rut'theran Village=1,Nighthaven=2,Astranaar=2,Stonetalon Peak=3,Nijel's Point=5,Theramore Isle=10
A|Ratchet|Theramore Isle=2,Talrendis Point=2,Gadgetzan=4,Thalanaar=4,Astranaar=5,Everlook=6,Nighthaven=7,Nijel's Point=7
H|Ratchet|The Crossroads=1,Camp Taurajo=2,Orgrimmar=3,Thunder Bluff=4,Brackenwall Village=4,Sun Rock Retreat=4,Valormok=4,Freewind Post=4
H|The Crossroads|Ratchet=1,Camp Taurajo=1,Orgrimmar=2,Sun Rock Retreat=3,Thunder Bluff=3,Splintertree Post=3,Brackenwall Village=3,Valormok=3
H|Camp Taurajo|The Crossroads=1,Thunder Bluff=1,Freewind Post=2,Ratchet=2,Orgrimmar=3,Gadgetzan=4,Shadowprey Village=4,Zoram'gar Outpost=5
H|Sun Rock Retreat|The Crossroads=3,Thunder Bluff=3,Ratchet=4,Orgrimmar=4,Splintertree Post=5,Freewind Post=6,Zoram'gar Outpost=6
A|Stonetalon Peak|Nijel's Point=2,Astranaar=3,Auberdine=3,Ratchet=7
A|Astranaar|Auberdine=2,Stonetalon Peak=3,Rut'theran Village=4,Nijel's Point=5,Ratchet=5
H|Splintertree Post|Orgrimmar=1,Valormok=2,The Crossroads=3,Zoram'gar Outpost=3,Thunder Bluff=5,Sun Rock Retreat=5,Bloodvenom Post=6,Freewind Post=6
H|Zoram'gar Outpost|Splintertree Post=3,The Crossroads=4,Orgrimmar=4,Valormok=4,Ratchet=5,Camp Taurajo=5,Sun Rock Retreat=6,Thunder Bluff=6
H|Freewind Post|Gadgetzan=1,Camp Taurajo=2,The Crossroads=3,Thunder Bluff=3,Ratchet=4,Orgrimmar=5,Shadowprey Village=5,Sun Rock Retreat=6
A|Nijel's Point|Stonetalon Peak=2,Feathermoon Stronghold=4,Astranaar=5,Auberdine=5,Theramore Isle=5,Rut'theran Village=6,Ratchet=7,Gadgetzan=8
H|Shadowprey Village|Thunder Bluff=3,Camp Mojache=3,Camp Taurajo=4,Freewind Post=5,Ratchet=6,Orgrimmar=6,Brackenwall Village=7,Valormok=7
A|Theramore Isle|Ratchet=2,Gadgetzan=3,Thalanaar=3,Nijel's Point=5,Auberdine=10,Rut'theran Village=12
H|Brackenwall Village|The Crossroads=3,Ratchet=4,Orgrimmar=4,Gadgetzan=4,Thunder Bluff=4,Marshal's Refuge=5,Shadowprey Village=7,Camp Mojache=7
A|Feathermoon Stronghold|Thalanaar=3,Cenarion Hold=3,Nijel's Point=4
H|Camp Mojache|Gadgetzan=3,Shadowprey Village=3,Thunder Bluff=4,The Crossroads=4,Marshal's Refuge=5,Ratchet=5,Orgrimmar=6,Brackenwall Village=7
A|Thalanaar|Feathermoon Stronghold=3,Theramore Isle=3,Gadgetzan=3,Ratchet=4
A|Gadgetzan|Marshal's Refuge=2,Theramore Isle=3,Thalanaar=3,Ratchet=4,Nijel's Point=8,Talonbranch Glade=11
H|Gadgetzan|Freewind Post=1,Marshal's Refuge=2,Camp Mojache=3,Brackenwall Village=4,Camp Taurajo=4,Thunder Bluff=5,The Crossroads=5,Ratchet=6
A|Talrendis Point|Ratchet=2,Everlook=3
H|Valormok|Splintertree Post=2,Orgrimmar=2,The Crossroads=3,Ratchet=4,Bloodvenom Post=4,Zoram'gar Outpost=4,Thunder Bluff=4,Camp Mojache=7
A|Talonbranch Glade|Everlook=2,Gadgetzan=11
H|Bloodvenom Post|Everlook=3,Valormok=4,The Crossroads=4,Orgrimmar=4,Ratchet=5,Splintertree Post=6,Thunder Bluff=7,Zoram'gar Outpost=8
A|Marshal's Refuge|Gadgetzan=2,Ratchet=7
H|Marshal's Refuge|Gadgetzan=2,Camp Mojache=5,Brackenwall Village=5,Ratchet=7,Orgrimmar=8
A|Everlook|Talonbranch Glade=2,Nighthaven=2,Talrendis Point=3,Ratchet=6
H|Everlook|Nighthaven=2,Bloodvenom Post=3,Orgrimmar=5,Ratchet=6
A|Nighthaven|Everlook=2,Auberdine=2,Rut'theran Village=3,Ratchet=7
H|Nighthaven|Everlook=2,Orgrimmar=6,Ratchet=7,Thunder Bluff=9
A|Cenarion Hold|Feathermoon Stronghold=3
A|Ironforge|Menethil Harbor=1,Thorium Point=2,Thelsamar=2,Southshore=3,Stormwind City=4,Refuge Pointe=4,Chillwind Camp=5,Darkshire=5
A|Stormwind City|Sentinel Hill=1,Darkshire=1,Lakeshire=2,Morgan's Vigil=3,Ironforge=4,Booty Bay=4,Menethil Harbor=4,Thelsamar=5
H|Undercity|The Sepulcher=2,Tarren Mill=2,Hammerfall=4,Light's Hope Chapel=4,Revantusk Village=5,Kargath=8,Thorium Point=9,Stonard=13
A|Thelsamar|Ironforge=2,Menethil Harbor=3,Refuge Pointe=3,Stormwind City=5,Sentinel Hill=6,Lakeshire=7
H|The Sepulcher|Tarren Mill=2,Undercity=2
A|Sentinel Hill|Stormwind City=1,Darkshire=2,Lakeshire=2,Booty Bay=3,Ironforge=6,Thelsamar=6
A|Lakeshire|Darkshire=1,Morgan's Vigil=1,Stormwind City=2,Sentinel Hill=2,Nethergarde Keep=3,Thelsamar=7,Menethil Harbor=7
A|Darkshire|Lakeshire=1,Stormwind City=1,Sentinel Hill=2,Booty Bay=3,Ironforge=5,Menethil Harbor=6
A|Southshore|Aerie Peak=1,Refuge Pointe=1,Chillwind Camp=1,Menethil Harbor=2,Ironforge=3,Stormwind City=7
H|Tarren Mill|The Sepulcher=2,Hammerfall=2,Undercity=2,Revantusk Village=3,Kargath=6,Stonard=11,Grom'gol Base Camp=12
A|Menethil Harbor|Ironforge=1,Southshore=2,Refuge Pointe=2,Thelsamar=3,Stormwind City=4,Darkshire=6,Lakeshire=7
A|Refuge Pointe|Aerie Peak=1,Southshore=1,Menethil Harbor=2,Thelsamar=3,Ironforge=4
H|Hammerfall|Revantusk Village=2,Tarren Mill=2,Undercity=4,Kargath=4,Flame Crest=6,Stonard=9,Booty Bay=11
A|Booty Bay|Darkshire=3,Sentinel Hill=3,Stormwind City=4,Nethergarde Keep=4,Thorium Point=8
H|Booty Bay|Grom'gol Base Camp=1,Stonard=4,Kargath=7,Thorium Point=8,Flame Crest=8,Hammerfall=11,Revantusk Village=12
H|Grom'gol Base Camp|Booty Bay=1,Stonard=3,Kargath=5,Flame Crest=7,Tarren Mill=12
H|Kargath|Thorium Point=1,Flame Crest=1,Hammerfall=4,Stonard=5,Grom'gol Base Camp=5,Tarren Mill=6,Booty Bay=7,Undercity=8
H|Stonard|Grom'gol Base Camp=3,Flame Crest=3,Booty Bay=4,Kargath=5,Thorium Point=5,Hammerfall=9,Revantusk Village=11,Tarren Mill=11
A|Aerie Peak|Chillwind Camp=1,Southshore=1,Refuge Pointe=1
H|Revantusk Village|Hammerfall=2,Tarren Mill=3,Undercity=5,Stonard=11,Booty Bay=12
A|Thorium Point|Ironforge=2,Morgan's Vigil=2,Booty Bay=8,Light's Hope Chapel=9
H|Thorium Point|Kargath=1,Stonard=5,Booty Bay=8,Light's Hope Chapel=9,Undercity=9
A|Nethergarde Keep|Lakeshire=3,Morgan's Vigil=3,Booty Bay=4
A|Morgan's Vigil|Lakeshire=1,Thorium Point=2,Stormwind City=3,Nethergarde Keep=3
H|Flame Crest|Kargath=1,Stonard=3,Hammerfall=6,Grom'gol Base Camp=7,Booty Bay=8
A|Chillwind Camp|Aerie Peak=1,Southshore=1,Ironforge=5
A|Light's Hope Chapel|Ironforge=6,Thorium Point=9
H|Light's Hope Chapel|Undercity=4,Thorium Point=9,Stonard=13
]]
local function norm(name)
 if type(name)~='string' then return '' end
 name=name:lower():gsub(',.*$',''):gsub('^%s+',''):gsub('%s+$','')
 name=name:gsub('^the ',''):gsub(' city$',''):gsub(' isle$','')
 return name
end
local measured,rough={}, {}
for from,to,seconds in MEASURED_TEXT:gmatch("([^>\n]+)>([^=\n]+)=(%d+)") do measured[norm(from)..'>'..norm(to)]=tonumber(seconds) end
for faction,origin,list in ROUGH_TEXT:gmatch("(%u)|([^|\n]+)|([^\n]+)") do
 local o=norm(origin);rough[faction]=rough[faction] or {};rough[faction][o]=rough[faction][o] or {}
 for dest,minutes in list:gmatch("([^,=]+)=(%d+)") do rough[faction][o][norm(dest)]=tonumber(minutes) end
end
-- Returns seconds and 'measured' (reference), or minutes*60 and 'rough', or nil.
function F.Reference(faction,from,to)
 if not from or not to or from=='' or to=='' then return end
 local exact=measured[from..'>'..to]
 if exact then return exact,'measured' end
 local code=faction=='Horde' and 'H' or faction=='Alliance' and 'A' or nil
 local minutes=code and rough[code] and rough[code][from] and rough[code][from][to]
 if minutes then return minutes*60,'rough' end
end
F.Normalize=norm
function F.CaptureNodes()
 nodes={};local origin
 if not NumTaxiNodes or not TaxiNodeName or not TaxiNodePosition or not TaxiNodeGetType then return end
 for i=1,NumTaxiNodes()do
  local name=TaxiNodeName(i);local x,y=TaxiNodePosition(i)
  if readable(name) and readable(x) and readable(y) and name then
   nodes[i]={name=name,point=('%s:%.4f:%.4f'):format(name,x or 0,y or 0)}
   if TaxiNodeGetType(i)=='CURRENT' then origin=nodes[i].point;nodes.originName=name end
  end
 end
 nodes.origin=origin;nodes.map=GetTaxiMapID and GetTaxiMapID() or 0
end
function F.Select(index)
 if not account or not nodes or not nodes.origin or not nodes[index] then return end
 local faction=UnitFactionGroup and UnitFactionGroup('player') or ''
 pending={key=table.concat({GetRealmName(),faction,tostring(nodes.map),nodes.origin,nodes[index].point},'|'),destination=nodes[index].name,at=GetTime(),from=norm(nodes.originName),to=norm(nodes[index].name),faction=faction}
end
function F.Update()
 if not settings or not F.ready then return end
 local flying=UnitOnTaxi and UnitOnTaxi('player');if not readable(flying) then return end
 if flying and not flight then
  if pending then
   flight={key=pending.key,destination=pending.destination,start=GetTime(),startedAt=time(),from=pending.from,to=pending.to,faction=pending.faction};pending=nil;character.flightSession=flight
  elseif character.flightSession then
   flight=character.flightSession;flight.start=GetTime()-math.max(0,time()-flight.startedAt)
  else flight={destination='Flight path',start=GetTime(),untracked=true} end
 end
 if pending and GetTime()-pending.at>30 then pending=nil end
 if flight and not flying then
  local seconds=GetTime()-flight.start
  if not flight.interrupted and not flight.untracked and seconds>=5 and seconds<7200 then account.flightTimes[flight.key]={seconds=seconds,updatedAt=time()} end
  flight=nil;character.flightSession=nil
 end
 if not flying and not flight then character.flightSession=nil end
 if not root then
  root=CreateFrame('Frame','ForeverAssistFlightTimer',UIParent);root:SetSize(420,45);root:SetFrameStrata('HIGH')
  root.label=root:CreateFontString(nil,'OVERLAY','TrailboundText');root.label:SetAllPoints();root.label:SetFont(STANDARD_TEXT_FONT,16,'OUTLINE')
 end
 local p=settings().flightPosition;root:ClearAllPoints();root:SetPoint('CENTER',UIParent,'CENTER',p and p[1] or 0,p and p[2] or 300)
 root:SetShown(flight~=nil and settings().flightTimer~=false and not (ForeverAssistLayout and ForeverAssistLayout.active))
 if flight then
  local elapsed=GetTime()-flight.start;local saved=flight.key and account.flightTimes[flight.key]
  local remaining=saved and saved.seconds-elapsed
  local detail=remaining and remaining>0 and ('~'..clock(remaining)..' remaining / '..clock(saved.seconds)..' total') or saved and 'Arriving soon — '..clock(elapsed)..' elapsed' or nil
  if not detail then
   local reference,kind=F.Reference(flight.faction,flight.from,flight.to)
   if kind=='measured' then
    detail=reference>elapsed and ('~'..clock(reference-elapsed)..' remaining / about '..clock(reference)..' total (reference)') or 'Arriving soon — '..clock(elapsed)..' elapsed'
   elseif kind=='rough' then
    detail=('About %d–%d min total (rough guide) — %s elapsed, exact time saved on arrival'):format(reference/60,reference/60+1,clock(elapsed))
   else detail=clock(elapsed)..' elapsed — learning this route' end
  end
  root.label:SetText(flight.destination..'\n'..detail)
 end
end
-- Flight map tooltips: show the learned time, else a reference or rough time, for each destination.
local function routeText(slot,destName)
 if not nodes or not nodes.origin then return end
 local faction=UnitFactionGroup and UnitFactionGroup('player') or ''
 local dest=slot and nodes[slot]
 local key=dest and table.concat({GetRealmName(),faction,tostring(nodes.map),nodes.origin,dest.point},'|')
 local learned=key and account and account.flightTimes[key]
 if learned then return 'Flight time: '..clock(learned.seconds),.4,1,.5 end
 local reference,kind=F.Reference(faction,norm(nodes.originName),norm(destName or (dest and dest.name)))
 if kind=='measured' then return 'Flight time: about '..clock(reference)..' (reference)',.7,.9,1 end
 if kind=='rough' then return ('Flight time: about %d–%d min (rough guide)'):format(reference/60,reference/60+1),.7,.9,1 end
 return 'Flight time: not known yet, saved after your first flight',.7,.7,.7
end
local function hookTaxiTooltips()
 if F.tooltipHooked then return end
 local mixin=FlightMap_FlightPointPinMixin
 if mixin and mixin.OnMouseEnter and hooksecurefunc then
  hooksecurefunc(mixin,'OnMouseEnter',function(self)
   pcall(function()
    local data=self.taxiNodeData
    local current=Enum and Enum.FlightPathState and Enum.FlightPathState.Current
    if type(data)~='table' or not readable(data.name) or (current and data.state==current) then return end
    local text,r,g,b=routeText(data.slotIndex,data.name)
    if text and GameTooltip:IsShown() then GameTooltip:AddLine(text,r,g,b);GameTooltip:Show() end
   end)
  end)
  F.tooltipHooked=true
 end
end
function F.Initialize(a,c,get)
 account,character,settings=a,c,get;account.flightTimes=account.flightTimes or {}
 if not F.hooked and hooksecurefunc then
  if TakeTaxiNode then hooksecurefunc('TakeTaxiNode',F.Select) end
  if TaxiRequestEarlyLanding then hooksecurefunc('TaxiRequestEarlyLanding',function()if flight then flight.interrupted=true end end) end
  F.hooked=true
 end
 pcall(hookTaxiTooltips)
 F.Update()
end
local events=CreateFrame('Frame');for _,e in ipairs({'TAXIMAP_OPENED','PLAYER_ENTERING_WORLD','PLAYER_CONTROL_LOST','PLAYER_CONTROL_GAINED','PLAYER_LOGOUT'})do events:RegisterEvent(e)end
events:SetScript('OnEvent',function(_,event)
 if event=='TAXIMAP_OPENED' then F.CaptureNodes();pcall(hookTaxiTooltips) elseif event=='PLAYER_LOGOUT' then F.ready=false;return else if event=='PLAYER_ENTERING_WORLD'then F.ready=true end;F.Update()end
end)
local elapsed=0;events:SetScript('OnUpdate',function(_,dt)if not settings or not (pending or flight)then return end;elapsed=elapsed+dt;if elapsed>=.2 then elapsed=0;F.Update()end end)
