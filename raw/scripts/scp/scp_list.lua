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

--[[
The descriptions should be a game manual first, SCP article second, but I'd rather they stick with the tone of the site.
]]

skips['SCP-173']={
--Author of SCP-173 Moto42
--Article: http://www.scp-wiki.net/scp-173
    description=string.format([[Item #: SCP-173

Object Class: Euclid

Special Containment Procedures: Item SCP-173 is to be kept in a locked container with a metal door at all times. When personnel must enter SCP-173's container, no fewer than 3 may enter at any time and the door is to be relocked behind them. At all times, two persons must maintain direct eye contact with SCP-173 until all personnel have vacated and relocked the container.

Description: Moved to Site-19 1993. Origin is as of yet unknown. It is constructed from concrete and rebar with traces of Krylon brand spray paint. SCP-173 is animate and extremely hostile. The object cannot move while within a direct line of sight. Line of sight must not be broken at any time with SCP-173. Personnel assigned to enter container are instructed to alert one another before blinking. Object is reported to attack by snapping the neck at the base of the skull, or by strangulation. In the event of an attack, personnel are to observe Class 4 hazardous object containment procedures.
Personnel report sounds of scraping stone originating from within the container when no one is present inside. This is considered normal, and any change in this behaviour should be reported to the acting HMCL supervisor on duty.
The reddish brown substance on the floor is a combination of feces and blood. Origin of these materials is unknown. The enclosure must be cleaned on a bi-weekly basis.

Addendum: The CK class restructuring event %s %s ago caused new behavior in SCP-173; it will heal itself when looked upon or unobserved. The exact reason for this behavior is unknown.]],tostring(df.global.cur_year),df.global.cur_year>1 and "years" or "year"),
    cost=-250,
    picture="SCP_173",
    type='creature',
    designation='SCP_173',
    subdesignation='UNFROZEN'
}

skips['SCP-117']={
--Author of SCP-117 ??? (far2 earliest edit, but could easily be due to the EditThis move)
--Article: http://www.scp-wiki.net/scp-117
    description=string.format([[Item #: SCP-117

Object Class: Safe

Special Containment Procedures: SCP-117 is to be kept in a secure location. Guards should be posted at this location to prevent theft.

Description: The CK-class event %s %s ago completely changed the behavior of the object. While the item formerly appeared to be a regular multitool of unknown make and brand, as of now it appears to be simply a tool, albeit one that can do everything tools are capable of doing. Testing has determined that this encompasses all of:

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
  Wheeled container (track or pushed)
  Reaching high places
  
Note from Researcher Putnam: Object no longer has the harmful effects on wielding nor does it appear to have any intelligence; it is simply the most versatile tool possible. The former item designated SCP-117 and this item both fit "complete multitool" and the former SCP-117 disappeared with this item in its place; this seems to imply that the two items are one in the same, but assuming that would not be good. The designation of this object as SCP-117 is more related to the disappearance of the original than the appearance of this one.]],tostring(df.global.cur_year),df.global.cur_year>1 and "years" or "year"), 
--it's the same object, the ck-class event just did some weird stuff, the foundation is skeptical because not being skeptical is a very bad idea for something such as this. SCP-117 is mostly in the mod because it's an easy implementation, heh.
    cost=100,
    type='item',
    designation='SCP_117',
    subdesignation='TOOL',
    material={0,dfhack.matinfo.find('STEEL').index},
}

skips['SCP-294']={
--Author of SCP-294 Arcibi 
--Article: http://www.scp-wiki.net/scp-294
    description=[[Item #: SCP-294

Object Class: Euclid 

Special Containment Procedures: There are no standard special containment procedures on file for Item SCP-294. However, only personnel of security clearance level 2 or higher are allowed to interact with it (see document SCP-294a). SCP-294 should be monitored by two guards of security clearance level 3 at all times.

Description: Item SCP-294 appears to be a standard coffee vending machine, the only noticeable difference being an entry touchpad with buttons corresponding to an English QWERTY keyboard. Upon depositing fifty cents US currency into the coin slot, the user is prompted to enter the name of any liquid using the touchpad. Upon doing so, a standard 12-ounce paper drinking cup is placed and the liquid indicated is poured. Ninety-seven initial test runs were performed (including requests for water, coffee, beer, and soda, non-consumable liquids such as sulfuric acid, wiper fluid, and motor oil, as well as substances that do not usually exist in liquid state, such as nitrogen, iron and glass) and each one returned a success. Test runs with solid materials such as diamond have failed, however, as it appears that SCP-294 can only deliver substances that can exist in liquid state.

It is of note that after approximately fifty uses, the machine would not respond to further requests. After a period of approximately 90 minutes, the machine seemed to have restocked itself. It is also interesting to note that many caustic liquids that would have eaten through a normal paper cup seemed to have no effect on the cups dispensed by the machine.

Testing is ongoing. Following incident 294-01, guards were stationed at the item and a security clearance became necessary to interact with it.

Document SCP-294a (regarding incident 294-01): On August 21, 2005, Agent Joseph ██████ attempted to use Item SCP-294 to obtain coffee during his allotted break time at 9:30 AM. At the request of Agent █████ █████████ "to see what it would do", ██████ requested "a cup of Joe" from the item. Moments after confirming the selection, Agent Joseph ██████ began to sweat profusely and complained of dizziness before collapsing. After moving the unconscious agent to the infirmary, the medical team recovered the contents of the cup dispensed by Item SCP-294: a combination of blood, tissue, and other bodily fluids. Testing revealed the DNA sequence of the biological material dispensed by SCP-294 matched that of Agent ██████.

Agent ██████ made a complete recovery after four weeks of rest and intravenous hydration. X-rays and CAT scans showed no further signs of injury, and ██████ was released. Both agents were reprimanded. Additional security measures for SCP-294 have been recommended.]],
    cost=300,
    type='item',
    designation='294',
    subdesignation='TOY',
    material={0,dfhack.matinfo.find('IRON').index},
}

skips['SCP-458']={
--Author of SCP-458 Palhinuk
--Article: http://www.scp-wiki.net/scp-458
    description=[[Item: SCP-458  

Object Class: Safe

Special Containment Procedures: SCP-458 is considered safe and therefore is to be stored in the staff canteen at Site 17, with no access restrictions required.  

Description: SCP-458 is a large-sized pizza box from the pizza chain Little Caesar's, of their Hot-n-Ready variety. It is made of simple cardboard, measures 25.4cmx25.4cmx2.54cm (10inx10inx1in), and weighs about 20 to 20.49 grams depending on toppings. As a result of the unusual nature of SCP-458, measurement of weight is inconsistent.

What makes SCP-458 an oddity is that, while appearing to be an ordinary pizza box, when it comes into contact with human hands, it instantaneously replicates within it the holder's subconsciously preferred choice of pizza, down to favorite sauce, cheese, crust, and topping. It is not limited to the Little Caesars brand, as pizza from all major pizza chains, as well as local and even handmade pizzas have been produced. There seems to be no limit to its ability, except that it cannot make anything but pizza, and its toppings must be edible by normal human standards (see Addendum 1a). The box is also rather indestructible, as all tests to destroy or dismantle the box have proven fruitless.

It is assumed the box is semi-sentient, having at least enough telepathic or empathetic ability to sense what the holder's personal choices regarding pizza are.

After constant testing showed SCP-458's seemingly infinite power to generate pizza (but with little other use), it has henceforth been placed inside the canteen at Site-17 for free use by personnel. After its open usage has been allowed, personnel morale has shown to have sharply increased.]],
    cost=500,
    type='item',
    designation='458',
    subdesignation='TOY',
    material={0,dfhack.matinfo.find('SIMPLE_CARDBOARD_SCP').index}
}
