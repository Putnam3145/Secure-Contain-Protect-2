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
    if not df.viewscreen_dwarfmodest:is_instance(dfhack.gui.getCurViewscreen()) then return end
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
    function scipNetScreen:getSelectedBuilding()
        
    end
    function scipNetScreen:init()
        self:addviews{
            Button{
                graphic='LEGENDS_BOOK',
                label='Open History Database',
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
            if df.ui_sidebar_mode[df.global.ui.main.mode]~='QueryBuilding' then self:dismiss() return end
            local building=df.global.world.selected_building
            if not building or not df.building_workshopst:is_instance(building) then self:dismiss() return end
            local buildingCustomType=df.building_def.find(building.custom_type)
            if not buildingCustomType or buildingCustomType.code~='SCP_NETWORK_ACCESSOR' then self:dismiss() return end
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

repeat_util.scheduleEvery('monthly_confidence_boost',605,'ticks',increaseConfidence)

----------------------------------------
--------------- SCP-294 ----------------
----------------------------------------

function cleanString(str)
    if not str then return '' end
    return str:lower():gsub('%W','')
end

function desperatelyAttemptToMatchStrings(str1,str2)
    if not str1 or not str2 then return false end
    return cleanString(str1):find(cleanString(str2)) or cleanString(str2):find(cleanString(str1))
end

function findPlant(str,desparate)
    --ugly ugly function, but this whole script is ugly
    if desparate then
        for k,v in ipairs(df.global.world.raws.plants.all) do
            if desperatelyAttemptToMatchStrings(str,v.id) or desperatelyAttemptToMatchStrings(str,v.name) then return {v,'plant'} end
        end
    else
        for k,v in ipairs(df.global.world.raws.plants.all) do
            if cleanString(str)==cleanString(v.id) or cleanString(v.name)==cleanString(str) then return {v,'plant'} end
        end
    end
    return {false,nil}
end

function findCreature(str,desparate)
    if desparate then
        for k,v in ipairs(df.global.world.raws.creatures.all) do
            if desperatelyAttemptToMatchStrings(str,v.creature_id) or desperatelyAttemptToMatchStrings(str,v.name[0]) then return {v,'creature'} end
        end
    else
        for k,v in ipairs(df.global.world.raws.creatures.all) do
            if cleanString(str)==cleanString(v.creature_id) then return {v,'creature'} end --the name equality is handled by the binsearch
        end
    end
    return {false,nil}
end

function findMaterialGivenPlainLanguageString(str)
    --not going to include odd substances :I
    local str=str:gsub("'",''):gsub('"','')
    local tokenStr=string.upper(str:gsub(' ','_'))
    local moddedString=tokenStr:gsub('_',':')
    for i=1,2 do
        if i==1 then
            moddedString='CREATURE:'..moddedString
        else
            moddedString='PLANT:'..moddedString
        end
        local find=dfhack.matinfo.find(tokenStr) or dfhack.matinfo.find(moddedString)
        if find then return find.type,find.index end
    end
    str=string.lower(str:gsub('_',' ')) --making sure it's all nice for the ugly part
    --this is the ugly part
    local utils=require('utils')
    local foundMatchingObject={}
    for word in str:gmatch('%a+') do
        --first, we search for an object, starting with a binsearch followed by a plant search followed by a creature search using a different creature identifier followed by a couple of nasty desperate searches.
        local binsearchResult={utils.binsearch(df.global.world.raws.creatures.alphabetic,string.lower(word),'name',utils.compare_field_key(0))}
        foundMatchingObject=foundMatchingObject[1]==true and foundMatchingObject or binsearchResult[2]==true and binsearchResult or findPlant(word) or findCreature(word) or findPlant(word,true) or findCreature(word,true)
        if foundMatchingObject[1]==true then
            for k,v in ipairs(foundMatchingObject[1].material) do --then we desperately try to find a material that matches the object.
                if desperatelyAttemptToMatchStrings(word,v.id) or desperatelyAttemptToMatchStrings(word,v.state_name.Liquid) or desperatelyAttemptToMatchStrings(word,v.state_name.Solid) or 
                desperatelyAttemptToMatchStrings(str,v.id) or desperatelyAttemptToMatchStrings(str,v.state_name.Liquid) or desperatelyAttemptToMatchStrings(str,v.state_name.Solid) then
                    if v.heat.melting_point~=60001 then
                        if foundMatchingObject[2]==true or foundMatchingObject[2]=='creature' then
                            local find = dfhack.matinfo.find('CREATURE:'..foundMatchingObject[1].creature_id..':'..v.id) --splitting the string doesn't work right now
                            return find.type,find.index
                        elseif foundMatchingObject[2]=='plant' then
                            local find = dfhack.matinfo.find('PLANT:'..foundMatchingObject[1].id..':'..v.id)
                            return find.type,find.index
                        else
                        end
                    end
                end
            end
        end
    end
    return false,false
end

local script=require('gui.script')

function SCP_294(reaction,reaction_product,unit,input_items,input_reagents,output_items,call_native)
    script.start(function()
        local mattype,matindex
        repeat
            local tryAgain
            local ok,matString=script.showInputPrompt('SCP-294','Select your drink.',COLOR_LIGHTGREEN)
            if ok then
                mattype,matindex=findMaterialGivenPlainLanguageString(matString)
            end
            if not mattype then
                script.showMessage('SCP-294','OUT OF RANGE',COLOR_LIGHTGREEN)
                tryAgain=script.showYesNoPrompt('SCP-294','TRY AGAIN?',COLOR_LIGHTGREEN)
            end
        until not tryAgain or mattype
        if mattype then
            for k,v in ipairs(df.global.world.raws.reactions) do
                if v.code:find('SCP_294_DISPENSE') then
                    for _,product in ipairs(v.products) do
                        if product.product_to_container=='container' then
                            product.mat_type=mattype
                            product.mat_index=matindex
                        end
                    end
                end
            end
        end
    end)
end
eventful.registerReaction('LUA_HOOK_SCP_294_SELECT_LIQUID_FOR_DISPENSING',SCP_294)

local function getPizza()
    for k,v in ipairs(df.global.world.raws.itemdefs.food) do
        if v.id=='458_PIZZA' then return v.subtype end
    end
end

function SCP_458(reaction,reaction_product,unit,input_items,input_reagents,output_items,call_native)
    local mattype,matindex
    for k,preference in ipairs(unit.status.current_soul.preferences) do
        if not preference then call_native=false return nil end
        if preference.type==2 and dfhack.matinfo.decode(preference.mattype,preference.matindex) and dfhack.matinfo.decode(preference.mattype,preference.matindex).material.heat.melting_point>10020 then
            mattype,matindex=preference.mattype,preference.matindex
            break
        end
    end
    if mattype then
        for k,v in ipairs(df.global.world.raws.reactions) do
            if v.code:find('SCP_458_GENERATE_PIZZA') then
                for _,product in ipairs(v.products) do
                    product.mat_type=mattype
                    product.mat_index=matindex
                    product.item_type=df.item_type['FOOD'] --lol this and the below line were hardcoded magic numbers
                    product.item_subtype=getPizza()
                end
            end
        end
    else
        call_native=false
    end
end

eventful.enableEvent(eventful.eventType.ITEM_CREATED,1) --I don't see any linear searches through entire vectors, so it should be fine

eventful.onItemCreated.SCP_458=function(item_id)
    local item=df.item.find(item_id)
    if not df.item_foodst:is_instance(item) or item.subtype.id~='458_PIZZA' then return nil end
    item.ingredients:insert('#',{new=df.item_foodst.T_ingredients,item_type=df.item_type.CHEESE})
    item.ingredients:insert('#',{new=df.item_foodst.T_ingredients,item_type=df.item_type.CHEESE,mat_index=item.mat_index,mat_type=item.mat_type})
end

eventful.registerReaction('LUA_HOOK_SET_PIZZA_TYPE_458',SCP_458)