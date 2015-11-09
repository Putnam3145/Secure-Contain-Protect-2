local eventful=require('plugins.eventful')

local widgets=require('gui.widgets')

local gui=require('gui')

Button=defclass(Button,widgets.Widget)

Button.ATTRS={
    on_click = DEFAULT_NIL,
    graphic = DEFAULT_NIL, --refers to the name of a tilepage
    label = DEFAULT_NIL
}

function Button:preUpdateLayout()
    self.frame=self.frame or {}
    if not self.page then self.frame.w=0 self.frame.h=0 return end
    self.frame.w=self.page.page_dim_x
    self.frame.h=self.page.page_dim_y
end

function Button:onRenderBody(dc)
    if not self.page then return end
    for k,v in ipairs(self.page.texpos) do
        dc:seek(k%self.frame.w,math.floor(k/self.frame.w)):tile(32,v)
    end
end

function Button:onInput(keys)
    if keys._MOUSE_L_DOWN and self:getMousePos() and self.on_click then
        self.on_click()
    end
end

function Button:init(args)
    if not self.graphic then return end
    for k,v in ipairs(df.global.texture.page) do
        if v.token==self.graphic then self.page=v return end
    end
    error('No tilepage found: '..self.graphic)
end

local eraseReport = function(unit,report)
 for i,v in ipairs(unit.reports.log.Combat) do
  if v == report then
   unit.reports.log.Combat:erase(i)
   break
  end
 end
end

local attackStrFuncs={}

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
    function scipNetScreen:renderSubviews(dc)
        local highlighted=false
        for _,child in ipairs(self.subviews) do
            if child:getMousePos() then self.subviews.highlight_label:setText(child.label) highlighted=true end
            if child.visible then
                child:render(dc)
            end
        end
        if not highlighted then self.subviews.highlight_label:setText('Click an icon to continue.') end
    end
    function scipNetScreen:init()
        self:addviews{
            Button{
                graphic='LEGENDS_BOOK',
                label='Open Legends Mode',
                on_click=function()
                    local legends=dfhack.script_environment('scp/open-legends')
                    legends.show()
                end,
                frame={t=1,l=1}
            },
            Button{
                graphic='SCP_LOGO',
                label='View SCPs',
                on_click=function()
                    dfhack.script_environment('scp/scipnet').showSCPView()
                end,
                frame={t=5,l=1}
            },
            Button{
                graphic='BANKNOTE',
                label='Requisitions',
                on_click=function()
                    dfhack.script_environment('scp/scipnet').showRequisitionsView()
                end,
                frame={t=1,l=5}
            },
            widgets.Label{
                frame={b=1,l=1},
                view_id='highlight_label',
                text=' '
            },
            widgets.Label{
                frame={t=13,l=1},
                text='The foundation currently has\n' .. dfhack.script_environment('scp/resources').getResourceAmount(df.global.ui.site_id,'confidence') .. ' confidence in you.'
            }
        }
    end
    function scipNetScreen:onInput(keys)
        if keys.LEAVESCREEN then
            self:dismiss()
        else
            self:inputToSubviews(keys)
            self:sendInputToParent(keys)
        end
    end
    scipNetScreen():show()
end

eventful.onWorkshopFillSidebarMenu.scp=function(workshop,callnative)
    if df.workshop_type[workshop.type]=='Custom' then
        local customWorkshopType=df.building_def.find(workshop.custom_type)
        local workshopFunc=workshopFuncs[customWorkshopType.code] or function() return end
        workshopFunc(workshop,callnative)
    end
end

eventful.onUnitDeath.scp=function(unit_id)
	local confidence_drop=dfhack.persistent.get('DEAD_OR_ESCAPED_UNIT_CONFIDENCE/'..unit_id)
	if confidence_drop then
        local site_id=df.global.ui.site_id
		local resource=dfhack.script_environment('scp/resources')
		resource.adjustResource(site_id,'confidence',confidence_drop.ints[1])
		resource.adjustResource(site_id,'delta_confidence',math.floor((-confidence_drop.ints[1]/20)+.5))
	end
end

eventful.enableEvent(eventful.eventType.UNIT_DEATH,5)

local function increaseConfidence()
	if df.global.gamemode==df.game_mode.DWARF and ((math.floor(df.global.cur_year_tick)/1200)-1)%28==0 then --rounds year tick to nearest day, makes it count from 0, checks if first day of month
		local resource=dfhack.script_environment('scp/resources')
		local site_id=df.global.ui.site_id
		local delta_confidence=resource.getResourceAmount(site_id,'delta_confidence')
		if delta_confidence<10 then
			resource.adjustResource(site_id,'delta_confidence',10-delta_confidence)
		end
		resource.adjustResource(site_id,'confidence',delta_confidence)
	end
end

local repeat_util=require('repeat-util')

repeat_util.scheduleEvery('monthly_confidence_boost',600,'ticks',increaseConfidence)
