-- Camp items (Forever's campfire objects): show the buff each one gives, on item and object tooltips.
-- Effects follow Forever's published camping tables; numbers scale with your level where noted.
ForeverAssistCamp={Version='1.8.86'}
local function safe(v) return not issecretvalue or not issecretvalue(v) end
local MANA_WELL='Mana regeneration: %d mana every 5 seconds at your level (10 to 29 by level). Does not stack with Blessing of Wisdom.'
local function manaWell()
 local level=UnitLevel('player') or 1
 local mana=level>=54 and 29 or level>=44 and 24 or level>=34 and 20 or level>=24 and 15 or 10
 return MANA_WELL:format(mana)
end
local TENT='Rested experience up to 5% of a level, once an hour.'
local WHEEL='Strength: +6 to +34 depending on level.'
local INCENSE='Intellect, scaling with level.'
local BOWL='Increases all stats (up to 8%). Does not stack with Blessing of Kings.'
local LUTE='Enchanted Lute buff. Does not stack with Mark of the Wild.'
local CHAIR='+2% critical strike chance. Does not stack with Moonkin Aura.'
-- name (lowercase) -> {profession, effect text or function, extra}
local CAMP={
 ['mana well']={'Alchemy',manaWell},
 ['fermenter']={'Alchemy',manaWell,'Also makes certain reagents.'},
 ['alchemy laboratory']={'Alchemy',manaWell,'Also a crafting station for recipes that need it.'},
 ['sharpening wheel']={'Blacksmithing',WHEEL},
 ['anvil']={'Blacksmithing',WHEEL,'Also a crafting station.'},
 ['master forge']={'Blacksmithing',WHEEL,'Also a crafting station for the top recipes.'},
 ['camp tent']={'Leatherworking',TENT},
 ['tanning rack']={'Leatherworking',TENT,'Also makes certain reagents; needed for many Leatherworking recipes.'},
 ['sewing machine']={'Leatherworking',TENT,'Also a crafting station for recipes that need it.'},
 ['camp chair']={'Skinning',CHAIR},
 ['incense candle']={'Herbalism',INCENSE},
 ['greenhouse']={'Herbalism',INCENSE,'Also a crafting station.'},
 ['seed hybridizer']={'Herbalism',INCENSE,'Also a crafting station.'},
 ['fish bowl']={'Fishing',BOWL},['fishing bowl']={'Fishing',BOWL},
 ['fishing rack']={'Fishing',BOWL,'Also a crafting station.'},
 ['fishing hut']={'Fishing',BOWL,'Also a crafting station.'},
 ['enchanted lute']={'Enchanting',LUTE},
 ['arcane salvager']={'Enchanting',LUTE,'Also disenchants more efficiently.'},
 ['arcane forge']={'Enchanting',LUTE,'Also a crafting station.'},
 ['first aid kit']={'First Aid','Stamina: +3 to +56 depending on level.'},
}
local function lookup(name)
 if type(name)~='string' or not safe(name) then return end
 name=name:lower():gsub('^blueprint:%s*',''):gsub('^recipe:%s*',''):gsub('^plans?:%s*',''):gsub('^pattern:%s*',''):gsub('^schematic:%s*','')
 return CAMP[name]
end
local function addLines(tooltip,info)
 if not tooltip or not tooltip.AddLine or not info or tooltip.tbCampShown then return end
 tooltip.tbCampShown=true
 local effect=info[2];if type(effect)=='function' then effect=effect() end
 tooltip:AddLine(' ')
 tooltip:AddLine('Camp buff ('..info[1]..'):',1,.82,0)
 tooltip:AddLine(effect,.55,.9,.55,true)
 if info[3] then tooltip:AddLine(info[3],.8,.8,.8,true) end
 tooltip:AddLine('Sit at the campfire for a minute to receive it. Lasts an hour.',.6,.6,.6,true)
 tooltip:Show()
end
local function firstLine(tooltip)
 local name=tooltip.GetName and tooltip:GetName();local fs=name and _G[name..'TextLeft1']
 return fs and fs:GetText()
end
if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
 local function handler(tooltip,data)
  if InCombatLockdown and InCombatLockdown() then return end
  local ok=pcall(function() local info=lookup(firstLine(tooltip));if info then addLines(tooltip,info) end end)
 end
 TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item,handler)
 if Enum.TooltipDataType.Object then TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Object,handler) end
 for _,tip in ipairs({GameTooltip,ItemRefTooltip}) do
  if tip and tip.HookScript then pcall(tip.HookScript,tip,'OnTooltipCleared',function(self) self.tbCampShown=nil end) end
 end
end
