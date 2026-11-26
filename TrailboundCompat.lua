-- Shared addon-only typography and surfaces. Never restyle Blizzard font objects.
TrailboundTheme={accent={.94,.80,.48},text={.96,.89,.76},muted={.73,.64,.51}}
local theme=TrailboundTheme
if CreateFont then
 for name,definition in pairs({TrailboundText={12,theme.text},TrailboundSmall={11,theme.text},TrailboundHeading={12,theme.accent},TrailboundTitle={16,theme.accent},TrailboundMuted={10,theme.muted}})do
  local font=CreateFont(name);font:SetFont('Fonts/FRIZQT__.TTF',definition[1],'');font:SetTextColor(unpack(definition[2]))
 end
end
function theme.Panel(frame,compact)
 if not frame or not frame.SetBackdrop then return end
 frame:SetBackdrop({bgFile='Interface/DialogFrame/UI-DialogBox-Background',edgeFile=compact and 'Interface/Buttons/WHITE8X8'or 'Interface/DialogFrame/UI-DialogBox-Border',tile=true,tileSize=32,edgeSize=compact and 1 or 24,insets={left=compact and 1 or 6,right=compact and 1 or 6,top=compact and 1 or 6,bottom=compact and 1 or 6}})
 frame:SetBackdropColor(.22,.17,.12,.96);frame:SetBackdropBorderColor(.6,.48,.31,1)
end
-- Money formatting across modern and older client API layouts.
function ForeverAssistMoney(copper)
    copper = math.max(0, math.floor(tonumber(copper) or 0))
    local fn = C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString or GetCoinTextureString or GetMoneyString
    if fn then
        local ok, text = pcall(fn, copper)
        if ok and type(text) == "string" then return text end
    end
    local gold = math.floor(copper / 10000)
    local silver = math.floor(copper / 100) % 100
    local coins = copper % 100
    if gold > 0 then return ("%dg %ds %dc"):format(gold, silver, coins) end
    if silver > 0 then return ("%ds %dc"):format(silver, coins) end
    return coins .. "c"
end

-- True only for tables this addon may read and loop over. Battlegrounds hand tainted code event payloads
-- and API tables that "cannot be accessed while tainted"; looping over one raises an error every time.
function ForeverAssistReadableTable(t)
 if type(t)~='table' then return false end
 if issecretvalue and issecretvalue(t) then return false end
 if issecrettable and issecrettable(t) then return false end
 if canaccesstable and not canaccesstable(t) then return false end
 return true
end
-- Never enumerate restricted auras. Nil,false means unavailable, not "no buffs".
local auraRetryAt=0
function ForeverAssistAuraReadable(index)
 if GetTime and GetTime()<auraRetryAt then return false end
 if C_Secrets then
  if C_Secrets.ShouldAurasBeSecret then local ok,restricted=pcall(C_Secrets.ShouldAurasBeSecret);if not ok or restricted then return false end end
  if C_Secrets.ShouldUnitAuraIndexBeSecret then local ok,restricted=pcall(C_Secrets.ShouldUnitAuraIndexBeSecret,'player',index or 1);if not ok or restricted then return false end end
 end
 return true
end
function ForeverAssistReadPlayerAura(index)
 if not ForeverAssistAuraReadable(index) then return nil,false end
 local ok,a
 if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then ok,a=pcall(C_UnitAuras.GetAuraDataByIndex,'player',index,'HELPFUL')
 elseif UnitBuff then
  local name,icon,count,dispel,seconds,expires,source,steal,personal,id
  ok,name,icon,count,dispel,seconds,expires,source,steal,personal,id=pcall(UnitBuff,'player',index)
  if name then a={name=name,icon=icon,applications=count,duration=seconds,expirationTime=expires,sourceUnit=source,spellId=id} end
 else return nil,true end
 if not ok then auraRetryAt=(GetTime and GetTime() or 0)+5;return nil,false end
 if not a then return nil,true end
 return ForeverAssistCleanAura(a)
end
function ForeverAssistCleanAura(a)
 if type(a)~="table" then return nil,false end
 if not ForeverAssistReadableTable(a) then return nil,false end
 local clean={}
 for _,key in ipairs({'name','icon','applications','duration','expirationTime','sourceUnit','spellId','spellID','isHelpful','isHarmful','auraInstanceID'}) do
  local value=a[key]
  if issecretvalue and issecretvalue(value) then return nil,false end
  clean[key]=value
 end
 return clean,true
end

-- Shared styling for ForeverAssist-owned text buttons only.
function ForeverAssistStyleButton(b)
 if not b or b.faButtonSkin then return b end
 for _,method in ipairs({'GetNormalTexture','GetPushedTexture','GetHighlightTexture','GetDisabledTexture'}) do
  if b[method] then local texture=b[method](b);if texture then texture:Hide() end end
 end
 for _,key in ipairs({'Left','Middle','Right'}) do if b[key] and b[key].Hide then b[key]:Hide() end end
 local skin=CreateFrame('Frame',nil,b,'BackdropTemplate');skin:SetAllPoints(b);skin:EnableMouse(false)
 if skin.SetFrameLevel and b.GetFrameLevel then skin:SetFrameLevel(b:GetFrameLevel()+1) end
 skin:SetBackdrop({bgFile='Interface/Buttons/WHITE8X8',edgeFile='Interface/Buttons/WHITE8X8',edgeSize=1})
 skin:SetBackdropColor(.14,.09,.045,1);skin:SetBackdropBorderColor(.48,.34,.17,1)
 local label=skin:CreateFontString(nil,'OVERLAY','TrailboundSmall');label:SetPoint('CENTER');label:SetText(b:GetText() or '');label:SetTextColor(.96,.86,.65)
 if b.GetFontString then local old=b:GetFontString();if old then old:Hide() end end
 b.faButtonSkin=skin;skin.label=label
 hooksecurefunc(b,'SetText',function(_,value)label:SetText(value or '')end)
 b:HookScript('OnEnter',function()skin:SetBackdropColor(.26,.17,.07,1)end)
 b:HookScript('OnLeave',function()skin:SetBackdropColor(.14,.09,.045,1)end)
 b:HookScript('OnDisable',function()label:SetTextColor(.47,.42,.33)end)
 b:HookScript('OnEnable',function()label:SetTextColor(.96,.86,.65)end)
 return b
end
-- Keep mail addresses separate from display names and stable character keys.
local function plain(text)
 if type(text)~='string' or (issecretvalue and issecretvalue(text)) then return end
 text=text:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r',''):gsub('|T.-|t',''):gsub('|A.-|a','')
 return (text:match('^%s*(.-)%s*$'))
end
-- Every place the client may expose a "First Second" character name. Returns candidates in priority order.
local function nameCandidates(unit)
 local list={}
 local function add(source,value) list[#list+1]={source=source,value=plain(value)} end
 for _,api in ipairs({'UnitNameUnmodified','UnitFullName','UnitName'}) do
  if type(_G[api])=='function' then local ok,name=pcall(_G[api],unit);if ok then add(api,name) end end
 end
 if GetUnitName then
  local ok,name=pcall(GetUnitName,unit,false);if ok then add('GetUnitName',name) end
  ok,name=pcall(GetUnitName,unit,true);if ok then add('GetUnitName(true)',name) end
 end
 if unit=='player' then
  if UnitPVPName then local ok,name=pcall(UnitPVPName,unit);if ok then add('UnitPVPName',name) end end
  for _,region in ipairs({'CharacterNameText','PlayerName','PlayerFrameNameText'}) do
   local r=_G[region];if r and r.GetText then local ok,t=pcall(r.GetText,r);if ok then add(region,t) end end
  end
 end
 return list
end
function ForeverAssistFullMailName(unit)
 local candidates=nameCandidates(unit)
 local base
 for _,c in ipairs(candidates) do if c.source=='UnitName' and c.value and c.value~='' then base=c.value end end
 for _,c in ipairs(candidates) do
  local value=c.value
  if value and value~='' then
   if base and #value>#base and value:find(base,1,true) and not value:find('^'..base:gsub('%p','%%%0')..'$') then
    -- Titles come before or after the name ("Private Grunt Je Mai", "Grunt Je Mai, the Insane"): keep from the name onward.
    local from=value:find(base,1,true)
    local tail=value:sub(from):gsub(',.*$','')
    tail=tail:match('^%s*(.-)%s*$')
    if tail:find('%S+%s+%S+') then return tail end
   elseif value:find('%S+%s+%S+') and (not base or value:sub(1,#base)==base) then return value end
  end
 end
end
function ForeverAssistNameDebug()
 for _,c in ipairs(nameCandidates('player')) do print('|cffd2b077Trailbound name:|r '..c.source..' = "'..tostring(c.value)..'"') end
 print('|cffd2b077Trailbound name:|r chosen = "'..tostring(ForeverAssistFullMailName('player'))..'"')
end
-- Realm names like "CAMWOW EU5 Realm 2 PvP" are shown as just the server type (PvP, PvE, RP, RP-PvP).
function ForeverAssistRealmLabel(realm)
 if type(realm)~='string' or realm=='' then return realm or '' end
 local text=' '..realm:lower():gsub('[%-_/]',' ')..' '
 local rp=text:find('%srp%s')~=nil or text:find('roleplay',1,true)~=nil
 local pvp=text:find('pvp',1,true)~=nil
 local pve=text:find('pve',1,true)~=nil or text:find('%snormal%s')~=nil
 if rp and pvp then return 'RP-PvP' end
 if rp then return 'RP' end
 if pvp then return 'PvP' end
 if pve then return 'PvE' end
 if text:find('hardcore',1,true) then return 'Hardcore' end
 return realm
end
-- The server name, from whichever API the client fills in (some return an empty string).
local function realmIsServerType(value)
 if type(value)~='string' or value=='' then return false end
 local text=' '..value:lower():gsub('[%-_/]',' ')..' '
 return text:find('pvp',1,true)~=nil or text:find('pve',1,true)~=nil or text:find('%srp%s')~=nil or text:find('roleplay',1,true)~=nil or text:find('hardcore',1,true)~=nil or text:find('%snormal%s')~=nil
end
-- Clients with two-word character names can report the second word of the name as the "realm". The server of the
-- account is the same for every character, so a value that names a server type (PvP, PvE, RP...) wins, and the
-- first server-type value ever seen is remembered for the whole account.
function ForeverAssistGetRealm()
 local function ok(v) return type(v)=='string' and (not issecretvalue or not issecretvalue(v)) and v:match('%S') and v:match('^%s*(.-)%s*$') or nil end
 local list={}
 local function add(v) v=ok(v);if v then list[#list+1]=v end end
 if GetRealmName then add(GetRealmName()) end
 if GetNormalizedRealmName then add(GetNormalizedRealmName()) end
 if GetServerName then add(GetServerName()) end
 if GetCVar then local good,v=pcall(GetCVar,'realmName');if good then add(v) end end
 if UnitFullName then local _,realm=UnitFullName('player');add(realm) end
 for _,v in ipairs(list) do
  if realmIsServerType(v) then
   if type(ForeverAssistAccountDB)=='table' then ForeverAssistAccountDB.commonRealm=v end
   return v
  end
 end
 if type(ForeverAssistAccountDB)=='table' and ok(ForeverAssistAccountDB.commonRealm) then return ForeverAssistAccountDB.commonRealm end
 return list[1] or ''
end
function ForeverAssistRealmDebug()
 local function show(label,v) print('|cffd2b077Trailbound realm:|r '..label..' = "'..tostring(v)..'"') end
 show('GetRealmName',GetRealmName and GetRealmName());show('GetNormalizedRealmName',GetNormalizedRealmName and GetNormalizedRealmName())
 if UnitFullName then local _,realm=UnitFullName('player');show('UnitFullName realm',realm) end
 show('GetCVar realmName',GetCVar and GetCVar('realmName'));show('chosen',ForeverAssistGetRealm())
end
-- First and second name, then level and class, then the server, e.g. "Grunt Je Mai (60 Priest) - PvP".
function ForeverAssistCharacterLabel(record,fullName)
 if type(record)~='table' then return '' end
 local name=fullName or record.mailName or record.name or '?'
 local text=name
 if record.level or record.className then
  local token=record.class
  local color=token and RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
  local classText=record.className or ''
  if color and classText~='' then classText=string.format('|cff%02x%02x%02x%s|r',(color.r or 1)*255,(color.g or 1)*255,(color.b or 1)*255,classText) end
  text=text..' |cffaaaaaa('..(record.level and (record.level..' ') or '')..'|r'..classText..'|cffaaaaaa)|r'
 end
 local rawRealm=type(record.realm)=='string' and record.realm:match('%S') and record.realm or ''
 if rawRealm~='' and not realmIsServerType(rawRealm) and type(ForeverAssistAccountDB)=='table' then
  local common=ForeverAssistAccountDB.commonRealm
  if type(common)~='string' and type(ForeverAssistAccountDB.characters)=='table' then
   for _,other in pairs(ForeverAssistAccountDB.characters) do if type(other)=='table' and realmIsServerType(other.realm) then common=other.realm;break end end
  end
  if type(common)=='string' then rawRealm=common end
 end
 local realm=rawRealm~='' and ForeverAssistRealmLabel(rawRealm) or ''
 -- A "realm" that is just part of the character's own name is not a server.
 if realm~='' and not realmIsServerType(rawRealm) then
  local lowered=realm:lower()
  for word in tostring(name):lower():gmatch('%a+') do if #word>=2 and (word:find(lowered,1,true)==1 or lowered:find(word,1,true)==1) then realm='';break end end
 end
 if realm~='' then text=text..' - '..realm end
 return text
end
