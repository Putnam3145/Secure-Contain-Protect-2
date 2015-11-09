local widgets=require('gui.widgets')

local gui=require('gui')

local Button=defclass(Button,widgets.Widget)

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

local SCPTextViewer=defclass(SCPTextViewer,gui.FramedScreen)

SCPTextViewer.ATTRS={
    description="",
}

local function lineBreakTableString(str)
    local prevBreak=1
    local str_list={}
    for i=1,str:len() do
        if str:sub(i,i)=='\n' then
            table.insert(str_list,str:sub(prevBreak,i-1))
            prevBreak=i+1
        end
    end
    table.insert(str_list,str:sub(prevBreak,str:len()))
    return str_list
end

local function wordWrapString(str,limit)
    local words=str:gmatch("%g+")
    local cur_string=""
    local prev_string=""
    local str_list={}
    for word in words do
        prev_string=cur_string
        cur_string=cur_string..word..' '
        if cur_string:len()>limit then
            table.insert(str_list,prev_string)
            cur_string=word..' '
        end
    end
    table.insert(str_list,cur_string)
    return str_list
end

local function separateString(str,limit)
    local str_list={}
    local lineBrokenStrs=lineBreakTableString(str)
    for k,v in ipairs(lineBrokenStrs) do
        for kk,vv in ipairs(wordWrapString(v,limit)) do
            table.insert(str_list,vv)
        end
    end
    return str_list
end

function SCPTextViewer:init()
    self.scroll=0
    self.width,self.height=dfhack.screen.getWindowSize()
    local line=separateString(self.description,self.width-4)
    local labels={}
    for k,v in ipairs(line) do
        table.insert(labels,widgets.Label{text=v,frame={t=k,l=1}})
    end
    self:addviews(labels)
    for k,child in ipairs(self.subviews) do
        if child.frame.t<1 or child.frame.t>self.height then child.visible=false else child.visible=true end
    end
end

function SCPTextViewer:onResize(w,h)
    gui.FramedScreen.onResize(self,w,h)
    self:init()
end

function SCPTextViewer:onInput(keys)
    if keys.STANDARDSCROLL_UP then 
        if self.scroll>0 then
            self.scroll=self.scroll-1
            for k,v in ipairs(self.subviews) do
                v.frame.t=v.frame.t+1
                if v.frame.t<1 or v.frame.t>self.height then v.visible=false else v.visible=true end
                pcall(function() v:updateLayout() end) --this gives an error when it's not in a pcall, but it works perfectly fine either way. I apologize to everyone.
            end
        end
    elseif keys.STANDARDSCROLL_DOWN then
        self.scroll=self.scroll+1
        for k,v in ipairs(self.subviews) do
            v.frame.t=v.frame.t-1
            if v.frame.t<1 or v.frame.t>self.height then v.visible=false else v.visible=true end
            pcall(function() v:updateLayout() end)
        end
    elseif keys.LEAVESCREEN then
        self:dismiss()
    end
end

local skips=dfhack.script_environment('scp/scp_list').skips

local SCPViewScreen=defclass(SCPViewScreen,gui.FramedScreen)

SCPViewScreen.ATTRS={
    description="",
    picture=DEFAULT_NIL, --refers to the name of a tilepage
    cost=0,
    on_enter=DEFAULT_NIL,
    type=DEFAULT_NIL, -- "creature" or "item"
    designation=DEFAULT_NIL, -- raw ID of SCP
    subdesignation='DEFAULT',
    mat={0,0} --refers to mat type and subtype OR index; in short, dfhack.matinfo.find has you covered. Should be iron by default unless I put something that comes before it.
}

function SCPViewScreen:renderSubviews(dc)
    local highlighted=false
    for _,child in ipairs(self.subviews) do
        if child:getMousePos() then self.subviews.highlight_label:setText(child.label) highlighted=true end
        if child.visible then
            child:render(dc)
        end
    end
    if not highlighted then self.subviews.highlight_label:setText('') end
end

local function firstCitizenFound()
    for k,v in ipairs(df.global.world.units.active) do
        if dfhack.units.isCitizen(v) and dfhack.units.isAlive(v) then
            return v
        end
    end
end

local function findItemID(itemName)
    for k,v in ipairs(df.global.world.raws.itemdefs.all) do
        if v.id==itemName then return v.subtype end
    end
end

local function getRaceID(creatureName)
    for k,v in ipairs(df.global.world.raws.creatures.all) do
        if v.creature_id==creatureName then return k end
    end
end

local function getCaste(creatureRaw,casteName)
    for k,v in ipairs(creatureRaw.caste) do
        if v.caste_id==casteName then return k end
    end
end

local function offerToContain(cost,scp_type,scp_designation,scp_subdesignation,mat)
    local resources=dfhack.script_environment('scp/resources')
    local site=df.global.ui.site_id
    local confidenceSpendSuccesful=resources.adjustResource(site,'confidence',cost,true)
    if dfhack.persistent.get('SCP_ALREADY_HERE/'..site) and false then 
        local dlg=require('gui.dialogs')
        dlg.showMessage('SCiPNET message','You cannot contain an SCP twice.')
        return false
    end
    if confidenceSpendSuccesful then
        if scp_type=='creature' then
            local teleportPos
            for k,v in ipairs(df.global.world.buildings.other.WORKSHOP_CUSTOM) do
                local customWorkshopType=df.building_def.find(v.custom_type)
                if customWorkshopType.code=='SCP_WELCOMING_STATION' then
                    teleportPos={x=v.x1,y=v.y1,z=v.z}
                    break
                end
            end
            if not teleportPos then
                local dlg=require('gui.dialogs')
                dlg.showMessage('SCiPNET message','You have not built a station to accept that SCP.')
                return
            end
            local createUnit=dfhack.script_environment('scp/create-unit').createUnit
            local creatureType=getRaceID(scp_designation)
            local newUnit=createUnit(creatureType,getCaste(df.creature_raw.find(creatureType),scp_subdesignation))
            dfhack.persistent.save({key='DEAD_OR_ESCAPED_UNIT_CONFIDENCE/'..newUnit,ints={math.abs(cost*2)}})
            local teleport = dfhack.script_environment('scp/teleport')
            teleport.teleport(df.unit.find(newUnit),teleportPos)
            resources.adjustResource(site,'delta_confidence',cost/10)
            dfhack.timeout(1,'ticks',function() dfhack.gui.makeAnnouncement(df.announcement_type.MASTERPIECE_CRAFTED,{RECENTER=true,DO_MEGA=true,PAUSE=true},teleportPos,scp_designation..' delivered to '..'this location.',COLOR_GREEN,true) end)
        elseif scp_type=='item' then
            local citizen=firstCitizenFound()
            local itemtype=findItemID(scp_designation)
            local success,errormsg=pcall(function() dfhack.items.createItem(df.item_type[scp_subdesignation], itemtype, mat[1], mat[2],citizen) end)
            if not success then
                print(df.item_type[scp_subdesignation],scp_subdesignation,findItemID(scp_designation),scp_designation,mat[1],mat[2],citizen)
                error(errormsg)
            end
            dfhack.timeout(1,'ticks',function() dfhack.gui.makeAnnouncement(df.announcement_type.MASTERPIECE_CRAFTED,{RECENTER=true,DO_MEGA=true,PAUSE=true},citizen.pos,scp_designation..' delivered to '..dfhack.TranslateName(dfhack.units.getVisibleName(citizen)),COLOR_GREEN,true) end)
        end
    else
        local dlg=require('gui.dialogs')
        dlg.showMessage('SCiPNET message','We are not confident enough in your containment abilities to grant that SCP.')
    end
end

function SCPViewScreen:init()
    self:addviews{
        Button{
            graphic='DESCRIPTION_LOGO',
            label='View SCP Description',
            on_click=function()
                if not self.description then
                    SCPTextViewer{description='No data found.'}:show()
                    return false
                end
                SCPTextViewer{description=self.description}:show()
           end,
            frame={t=1,l=1}
        },
        Button{
            graphic='OFFER_TO_CONTAIN_LOGO',
            label='Offer to contain this SCP',
            on_click=function()
                if not self.type then
                    --but nothing happened
                    return false
                end
                offerToContain(self.cost,self.type,self.designation,self.subdesignation,self.mat)
            end,
            frame={t=1,l=9}
        },
        Button{
            graphic=self.picture,
            label="Figure of SCP",
            frame={t=0,r=0}
        },
        widgets.Label{
            frame={b=1,l=1},
            view_id='highlight_label',
            text=' '
        },
    }
end

function SCPViewScreen:onInput(keys)
    if keys.LEAVESCREEN then
        self:dismiss()
    end
    self:inputToSubviews(keys)
end

local SCPList=defclass(SCPList,gui.FramedScreen)

function SCPList:init()
    self:addviews{
        widgets.FilteredList{
            choices=skips:generate(),
            on_submit=function(index,choice)
                if not choice then
                    SCPViewScreen{picture='SCP_S'}:show() 
                    --SCP-S by CryogenChaos
                    --article: http://www.scp-wiki.net/scp-s
                end
                SCPViewScreen(skips[choice.text]):show()
            end
        }
    }
end

function SCPList:onInput(keys)
    if keys.LEAVESCREEN then
        self:dismiss()
    end
    self:inputToSubviews(keys)
end

function showSCPView()
    local scp_list=SCPList()
    return scp_list:show()
end


local function getRestrictiveMatFilter(itemType)
 local itemTypes={
   WEAPON=function(mat,parent,typ,idx)
    return (mat.flags.ITEMS_WEAPON or mat.flags.ITEMS_WEAPON_RANGED)
   end,
   AMMO=function(mat,parent,typ,idx)
    return (mat.flags.ITEMS_AMMO)
   end,
   ARMOR=function(mat,parent,typ,idx)
    return (mat.flags.ITEMS_ARMOR)
   end,
   INSTRUMENT=function(mat,parent,typ,idx)
    return (mat.flags.ITEMS_HARD)
   end,
   AMULET=function(mat,parent,typ,idx)
    return (mat.flags.ITEMS_SOFT or mat.flags.ITEMS_HARD)
   end,
   ROCK=function(mat,parent,typ,idx)
    return (mat.flags.IS_STONE)
   end,
   BOULDER=ROCK,
   BAR=function(mat,parent,typ,idx)
    return (mat.flags.IS_METAL or mat.flags.SOAP or mat.id==COAL)
   end

  }
 for k,v in ipairs({'GOBLET','FLASK','TOY','RING','CROWN','SCEPTER','FIGURINE','TOOL'}) do
  itemTypes[v]=itemTypes.INSTRUMENT
 end
 for k,v in ipairs({'SHOES','SHIELD','HELM','GLOVES'}) do
    itemTypes[v]=itemTypes.ARMOR
 end
 for k,v in ipairs({'EARRING','BRACELET'}) do
    itemTypes[v]=itemTypes.AMULET
 end
 itemTypes.BOULDER=itemTypes.ROCK
 return itemTypes[df.item_type[itemType]]
end

local function getMatFilter(itemtype)
  local itemTypes={
   SEEDS=function(mat,parent,typ,idx)
    return mat.flags.SEED_MAT
   end,
   PLANT=function(mat,parent,typ,idx)
    return mat.flags.STRUCTURAL_PLANT_MAT
   end,
   LEAVES=function(mat,parent,typ,idx)
    return mat.flags.LEAF_MAT
   end,
   MEAT=function(mat,parent,typ,idx)
    return mat.flags.MEAT
   end,
   CHEESE=function(mat,parent,typ,idx)
    return (mat.flags.CHEESE_PLANT or mat.flags.CHEESE_CREATURE)
   end,
   LIQUID_MISC=function(mat,parent,typ,idx)
    return (mat.flags.LIQUID_MISC_PLANT or mat.flags.LIQUID_MISC_CREATURE or mat.flags.LIQUID_MISC_OTHER)
   end,
   POWDER_MISC=function(mat,parent,typ,idx)
    return (mat.flags.POWDER_MISC_PLANT or mat.flags.POWDER_MISC_CREATURE)
   end,
   DRINK=function(mat,parent,typ,idx)
    return (mat.flags.ALCOHOL_PLANT or mat.flags.ALCOHOL_CREATURE)
   end,
   GLOB=function(mat,parent,typ,idx)
    return (mat.flags.STOCKPILE_GLOB)
   end,
   WOOD=function(mat,parent,typ,idx)
    return (mat.flags.WOOD)
   end,
   THREAD=function(mat,parent,typ,idx)
    return (mat.flags.THREAD_PLANT)
   end,
   LEATHER=function(mat,parent,typ,idx)
    return (mat.flags.LEATHER)
   end
  }
  return itemTypes[df.item_type[itemtype]] or getRestrictiveMatFilter(itemtype)
end

local function showMaterialPrompt(title, prompt, filter, inorganic, creature, plant) --the one included with DFHack doesn't have a filter or the inorganic, creature, plant things available
 require('gui.materials').MaterialDialog{
  frame_title = title,
  prompt = prompt,
  mat_filter = filter,
  use_inorganic = inorganic,
  use_creature = creature,
  use_plant = plant,
  on_select = script.mkresume(true),
  on_cancel = script.mkresume(false),
  on_close = script.qresume(nil)
 }:show()
 
  return script.wait()
end

local requisitionsTable=dfhack.script_environment('scp/requisitions_list').requisitions

local function requisitionItem(cost,itemtype,itemsubtype,mat,quantity)
    local resources=dfhack.script_environment('scp/resources')
    local confidenceSpendSuccesful=resources.adjustResource(df.global.ui.site_id,'confidence',cost,true)
    print('tested confidence')
    if confidenceSpendSuccesful then
        print('succesful')
        if mat then
            if type(mat)=='string' then
                local matinfo=dfhack.matinfo.find(mat)
                local unit=firstCitizenFound()
                if quantity then
                    if df.item_type.attrs[itemtype].is_stackable then
                        local item=dfhack.items.createItem(itemtype, itemsubtype, matinfo.type, matinfo.index, unit)
                        df.item.find(item):setStackSize(quantity)
                    else
                        for i=1,quantity do
                            dfhack.items.createItem(itemtype, itemsubtype, matinfo.type, matinfo.index, unit)
                        end
                    end
                else
                    dfhack.items.createItem(itemtype, itemsubtype, matinfo.type, matinfo.index, unit)
                end
            else
                qerror('TODO: add non-string mat specifications; if you see this error, Putnam messed up')
            end
        else
            local script=require('gui.script')
            script.start(function()
                local specificmatFilter=getMatFilter(itemtype)
                local matFilter=function(mat,parent,typ,idx)
                    return not mat.flags.SPECIAL and specificmatFilter(mat,parent,typ,idx)
                end
                local matok,mattype,matindex=showMaterialPrompt('Requisitions','Choose a material',matFilter,true,false,false)
                local unit=firstCitizenFound()
                dfhack.items.createItem(itemtype, itemsubtype, mattype, matindex, unit)
            end)
        end
    else
        local dlg=require('gui.dialogs')
        dlg.showMessage('SCiPNET message','We are not confident enough in your containment abilities to grant that request.')
    end
end

local RequisitionView=defclass(RequisitionView,gui.FramedScreen)

function RequisitionView:init()
    self.costLabel=widgets.Label{frame={t=1,l=6}}
    self.descriptionLabel=widgets.Label{frame={t=2,l=1}}
    self.highlightPanel=widgets.Panel{
        subviews={
            widgets.Label{
                text='Cost: ',
                frame={t=1,l=1}
            },
            self.costLabel,
            self.descriptionLabel
        },
        frame={t=0,r=1,w=40}
    }
    self:addviews{
        widgets.FilteredList{
            choices=requisitionsTable:generate(),
            on_select=function(index,choice)
                if not choice then return end
                local properChoice=type(choice)=='string' and choice or choice.text
                local choiceInfo=requisitionsTable[properChoice]
                local description=table.concat(wordWrapString(choiceInfo.description,40),"\n")
                self.descriptionLabel:setText(description)
                self.costLabel:setText(tostring(choiceInfo.cost))
            end,
            on_submit=function(index,choice)
                if not choice then return end
                local properChoice=type(choice)=='string' and choice or choice.text
                local choiceInfo=requisitionsTable[properChoice]
                requisitionItem(choiceInfo.cost,df.item_type[choiceInfo.type],findItemID(choiceInfo.subtype),choiceInfo.mat,choiceInfo.quantity)
            end,
            edit_below=true
        },
        self.highlightPanel
    }
end

function RequisitionView:onInput(keys)
    if keys.LEAVESCREEN then
        self:dismiss()
    end
    self:inputToSubviews(keys)
end

function showRequisitionsView()
    local requisitions=RequisitionView()
    return requisitions:show()
end
