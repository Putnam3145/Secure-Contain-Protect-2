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
    self.frame.w=self.page.page_dim_x
    self.frame.h=self.page.page_dim_y
end

function Button:onRenderBody(dc)
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
    for k,v in ipairs(df.global.texture.page) do
        if v.token==self.graphic then self.page=v return end
    end
    error('No tilepage found: '..self.graphic)
end

SCPViewScreen=defclass(SCPViewScreen,gui.FramedScreen)

SCPViewScreen.ATTRS={
    description="",
    picture=DEFAULT_NIL,
    cost=0,
    on_enter=DEFAULT_NIL
}

function lineBreakTableString(str)
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

function wordWrapString(str,limit)
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

function separateString(str,limit)
    local str_list={}
    local lineBrokenStrs=lineBreakTableString(str)
    for k,v in ipairs(lineBrokenStrs) do
        for kk,vv in ipairs(wordWrapString(v,limit)) do
            table.insert(str_list,vv)
        end
    end
    return str_list
end

function SCPViewScreen:init()
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

function SCPViewScreen:onInput(keys)
    if keys.STANDARDSCROLL_UP then 
        for k,v in ipairs(self.subviews) do
            v.frame.t=v.frame.t+1
            if v.frame.t<1 or v.frame.t>self.height then v.visible=false else v.visible=true end
            pcall(function() v:updateLayout() end) --this gives an error when it's not in a pcall, but it works perfectly fine either way. I apologize to everyone.
        end
    elseif keys.STANDARDSCROLL_DOWN then
        for k,v in ipairs(self.subviews) do
            v.frame.t=v.frame.t-1
            if v.frame.t<1 or v.frame.t>self.height then v.visible=false else v.visible=true end
            pcall(function() v:updateLayout() end)
        end
    elseif keys.LEAVESCREEN then
        self:dismiss()
    end
end

SCPViewScreen.postUpdateLayout=SCPViewScreen.init

skips={}

skips['SCP-173']={
    description=string.format([[Item #: SCP-173

Object Class: Euclid

Special Containment Procedures: Item SCP-173 is to be kept in a locked container at all times. When personnel must enter SCP-173's container, no fewer than 3 may enter at any time and the door is to be relocked behind them. At all times, two persons must maintain direct eye contact with SCP-173 until all personnel have vacated and relocked the container.

Description: Moved to Site-19 1993. Origin is as of yet unknown. It is constructed from concrete and rebar with traces of Krylon brand spray paint. SCP-173 is animate and extremely hostile. The object cannot move while within a direct line of sight. Line of sight must not be broken at any time with SCP-173. Personnel assigned to enter container are instructed to alert one another before blinking. Object is reported to attack by snapping the neck at the base of the skull, or by strangulation. In the event of an attack, personnel are to observe Class 4 hazardous object containment procedures.
Personnel report sounds of scraping stone originating from within the container when no one is present inside. This is considered normal, and any change in this behaviour should be reported to the acting HMCL supervisor on duty.
The reddish brown substance on the floor is a combination of feces and blood. Origin of these materials is unknown. The enclosure must be cleaned on a bi-weekly basis.

Note from Researcher Putnam: Can't get through metal doors. Keep at least two people on it at all times or it will kill something. Ever since the CK class restructuring event %s %s ago, it can heal itself when it is looked upon or unobserved due to its entire body transforming for that effect to happen.]],tostring(df.global.cur_year),df.global.cur_year>1 and "years" or "year")
}

SCPList=defclass(SCPList,gui.FramedScreen)

function SCPList:init()
    self:addviews{
        widgets.List{
            choices={
                'SCP-173',
            },
            on_submit=function(index,choice)
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

ScipNetScreen = defclass(ScipNetscreen,gui.FramedScreen)

function ScipNetScreen:renderSubviews(dc)
    local highlighted=false
    for _,child in ipairs(self.subviews) do
        if child:getMousePos() then self.subviews.highlight_label:setText(child.label) highlighted=true end
        if child.visible then
            child:render(dc)
        end
    end
    if not highlighted then self.subviews.highlight_label:setText('') end
end

function ScipNetScreen:init()
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
                showSCPView()
            end,
            frame={t=5,l=1}
        },
        Button{
            graphic='BANKNOTE',
            label='Requisitions',
            on_click=function()
                --[[
                showRequisitionsView()
                ]]
            end,
            frame={t=1,l=5}
        },
        widgets.Label{
            frame={b=1,l=1},
            view_id='highlight_label',
            text=' '
        },
    }
end

function ScipNetScreen:onInput(keys)
    if keys.LEAVESCREEN then
        self:dismiss()
    end
    self:inputToSubviews(keys)
end

local scipnet=ScipNetScreen()

scipnet:show()