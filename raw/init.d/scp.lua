local eventful=require('plugins.eventful')

local eraseReport = function(unit,report)
 for i,v in ipairs(unit.reports.log.Combat) do
  if v == report then
   unit.reports.log.Combat:erase(i)
   break
  end
 end
end

local defendStrFuncs={}

local seenFuncs={}

seenFuncs['SCP_173']=function(attackVerb,defendVerb,attackerId,defenderId,attackReportId,defendReportId)
    dfhack.run_script('modtools/add-syndrome','-syndrome','scp 173 stopped','-resetPolicy','ResetDuration','-target',defenderId,'-skipImmunities')
end

defendStrFuncs['check for being seen']=function(attackVerb,defendVerb,attackerId,defenderId,attackReportId,defendReportId)
    local attacker=df.unit.find(attackerId)
    local defender=df.unit.find(defenderId)
    local attacker_raw=df.creature_raw.find(attacker.race)
    local defender_raw=df.creature_raw.find(defender.race)
    local seenFunc=seenFuncs[attacker_raw.creature_id] or seenFuncs[defender_raw.creature_id] or function() return end
    seenFunc(attackVerb,defendVerb,attackerId,defenderId,attackReportId,defendReportId)
    eraseReport(df.unit.find(defenderId),df.report.find(defendReportId))
end

eventful.onInteraction.scp_stuff=function(attackVerb, defendVerb, attackerId, defenderId, attackReportId, defendReportId)
    local attackStr=attackVerb or ''
    local defendStr=defendVerb or ''
    local blankFunc=function() return end
    local attackFunc=attackStrFuncs[attackStr] or blankFunc
    attackFunc(attackVerb,defendVerb,attackerId,defenderId,attackReportId,defendReportId)
    local defendFunc=defendStrFuncs[defendStr] or blankFunc
    defendFunc(attackVerb,defendVerb,attackerId,defenderId,attackReportId,defendReportId)
    --[[local bothFunc=bothStrFuncs[attackStr..'/'..defendStr]
    if bothFunc then bothFunc(attackVerb,defendVerb,attackerId,defenderId,attackReportId,defendReportId) end]]
end

local stateEvents={}

stateEvents[SC_MAP_LOADED]=function() eventful.enableEvent(eventful.eventType.INTERACTION,2) end

stateEvents[SC_WORLD_LOADED]=stateEvents[SC_MAP_LOADED]

function onStateChange(op)
    local stateChangeFunc=stateEvents[op] or function() return end
    stateChangeFunc()
end

local workshopFuncs={}

workshopFuncs['SCP_NETWORK_ACCESSOR']=function(workshop,callnative)
    local guidm=require('gui.dwarfmode')
    local widgets=require('gui.widgets')
    callnative=false
    local scipNetScreen=defclass(scipNetScreen,guidm.MenuOverlay)
    function scipNetScreen:init()
        self.building=dfhack.gui.getSelectedBuilding()
    end
    function scipNetScreen:onRenderBody(dc)
        dc:seek(1,1):string('Press the '):key('SELECT'):string(' key to access SCiPNET')
        local selectedBuilding=dfhack.gui.getSelectedBuilding()
        if not selectedBuilding or selectedBuilding~=self.building then self:dismiss() end
    end
    function scipNetScreen:onInput(keys)
        if keys.SELECT then
            dfhack.run_script('scp/scipnet')
        else
            self:inputToSubviews(keys)
            self:sendInputToParent(keys)
        end
    end
    scipNetScreen():show()
end

eventful.onWorkshopFillSidebarMenu.scp=function(workshop,callnative)
    if df.workshop_type[workshop.custom_type]=='Custom' then
        local customWorkshopType=df.building_def.find(workshop.custom_type)
        local workshopFunc=workshopFuncs[customWorkshopType.code] or function() return end
        workshopFunc(workshop,callnative)
    end
end