--[[
SCPViewScreen.ATTRS={
    description="",
    picture=DEFAULT_NIL, --refers to the name of a tilepage
    cost=0,
    on_enter=DEFAULT_NIL,
    type=DEFAULT_NIL, -- "creature" or "item"
    designation=DEFAULT_NIL -- raw ID of SCP
}
]]

skips={}

skips.generate=function(self)
    local generated_list={}
    for k,v in pairs(self) do
        if type(v)=='table' then
            table.insert(generated_list,k)
        end
    end
    table.sort(generated_list)
    return generated_list
end

skips['SCP-173']={
    description=string.format([[Item #: SCP-173

Object Class: Euclid

Special Containment Procedures: Item SCP-173 is to be kept in a locked container with a metal door at all times. When personnel must enter SCP-173's container, no fewer than 3 may enter at any time and the door is to be relocked behind them. At all times, two persons must maintain direct eye contact with SCP-173 until all personnel have vacated and relocked the container.

Description: Moved to Site-19 1993. Origin is as of yet unknown. It is constructed from concrete and rebar with traces of Krylon brand spray paint. SCP-173 is animate and extremely hostile. The object cannot move while within a direct line of sight. Line of sight must not be broken at any time with SCP-173. Personnel assigned to enter container are instructed to alert one another before blinking. Object is reported to attack by snapping the neck at the base of the skull, or by strangulation. In the event of an attack, personnel are to observe Class 4 hazardous object containment procedures.
Personnel report sounds of scraping stone originating from within the container when no one is present inside. This is considered normal, and any change in this behaviour should be reported to the acting HMCL supervisor on duty.
The reddish brown substance on the floor is a combination of feces and blood. Origin of these materials is unknown. The enclosure must be cleaned on a bi-weekly basis.

Addendum: Ever since the CK class restructuring event %s %s ago, it can heal itself when it is looked upon or unobserved due to a body transformation.]],tostring(df.global.cur_year),df.global.cur_year>1 and "years" or "year"),
    cost=-250,
    picture="SCP_173",
    type='creature',
    designation='SCP_173',
    subdesignation='UNFROZEN'
}

skips['SCP-117']={
    description=string.format([[Item #: SCP-117

Object Class: Safe

Special Containment Procedures: SCP-117 is to be kept in a secure location. Guards should be posted at this location to prevent theft.

Description: The CK-class event %s %s ago completely changed the operation of the object. While the item formerly appeared to be a regular multitool of unknown make and brand, as of now it appears to be simply a tool, just one that can do everything tools are capable of doing, a surprisingly limited list from what has been determined in research on the event:

  Various kitchen knife behaviors (carving, slicing, boning, cleaving)
  Cooking liquids
  Mortar or Pestle (note the OR; object only acts as one at a time)
  Ladling liquids
  Holding meat for carving
  Containing meals
  Bird nesting
  Containing liquids
  Storing food
  Insect hives
  Small object storage
  Container on wheels (for use with track)
  Container on wheels (for pushing)
  Reaching high places
  
It no longer has the harmful effects on wielding nor does it appear to have any intelligence; it is simply the most versatile tool possible, no more and no less. The only apparent connection with the former item designated SCP-117 is the idea of a "complete multitool"; the primary reason this item is given the same designation is that the former SCP-117 was gone and this item was found in its place.]],tostring(df.global.cur_year),df.global.cur_year>1 and "years" or "year"),
    cost=100,
    type='item',
    designation='SCP_117',
    subdesignation='TOOL',
    material={0,dfhack.matinfo.find('STEEL').index},
}
