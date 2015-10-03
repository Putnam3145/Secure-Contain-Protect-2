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
        if v.token==self.graphic then self.page=v break end
    end
end

SCPViewScreen=defclass(SCPViewScreen,gui.FramedScreen)

SCPViewScreen.ATTRS={
    description="",
    picture=DEFAULT_NIL,
    cost=0,
    on_enter=DEFAULT_NIL
}

function separateString(str,limit)
    local str_list={}
    for i=1,str:len(),limit do
        table.insert(str_list,str:sub(i,i+str_limit-1))
    end
    return str_list
end

function SCPViewScreen:init()
    local line=separateString(self.description,self.frame_width)
    local labels={}
    for k,v in ipairs(line) do
        table.insert(labels,widgets.Label{text=v,frame={t=k,l=1}})
    end
    self:addviews(labels)
    for k,child in ipairs(self.subviews) do
        if child.frame.t<1 or child.frame.t>self.frame_height then child.visible=false end
    end
end

function SCPViewScreen:onInput(keys)
    if keys.STANDARDSCROLL_UP then
        for k,v in ipairs(self.subviews) do
            v.frame.t=v.frame.t+1
            if child.frame.t<1 or child.frame.t>self.frame_height then child.visible=false end
        end
    elseif keys.STANDARDSCROLL_DOWN then
        for k,v in ipairs(self.subviews) do
            v.frame.t=v.frame.t-1
            if child.frame.t<1 or child.frame.t>self.frame_height then child.visible=false end
        end
    elseif keys.LEAVESCREEN then
        self:dismiss()
    end
end

function SCPViewScreen:postUpdateLayout(parent_rect)
    local line=separateString(self.description,self.frame_width)
    local labels={}
    self.subviews={}
    for k,v in ipairs(line) do
        table.insert(labels,widgets.Label{text=v,frame={t=k,l=1}})
    end
    self:addviews(labels)
    for k,child in ipairs(self.subviews) do
        if child.frame.t<1 or child.frame.t>self.frame_height then child.visible=false end
    end
end

skips={}

skips['SCP-173']={
    description=[[
Item #: SCP-173

Object Class: Euclid

Special Containment Procedures: Item SCP-173 is to be kept in a locked container at all times. When personnel must enter SCP-173's container, no fewer than 3 may enter at any time and the door is to be relocked behind them. At all times, two persons must maintain direct eye contact with SCP-173 until all personnel have vacated and relocked the container.

Description: Moved to Site-19 1993. Origin is as of yet unknown. It is constructed from concrete and rebar with traces of Krylon brand spray paint. SCP-173 is animate and extremely hostile. The object cannot move while within a direct line of sight. Line of sight must not be broken at any time with SCP-173. Personnel assigned to enter container are instructed to alert one another before blinking. Object is reported to attack by snapping the neck at the base of the skull, or by strangulation. In the event of an attack, personnel are to observe Class 4 hazardous object containment procedures.

Personnel report sounds of scraping stone originating from within the container when no one is present inside. This is considered normal, and any change in this behaviour should be reported to the acting HMCL supervisor on duty.

The reddish brown substance on the floor is a combination of feces and blood. Origin of these materials is unknown. The enclosure must be cleaned on a bi-weekly basis.
    ]]
}

SCPList=defclass(SCPList,gui.FramedScreen)

function SCPList:init()
    self:addviews{
        widgets.List{
            choices={
                'SCP-173',
            },
            on_submit=function(index,choice)
                SCPViewScreen(skips[choice])
            end
        }
    }
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
            label=''
        },
    }
end

local scipnet=ScipNetScreen()

scipnet:show()