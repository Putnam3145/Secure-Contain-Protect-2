requisitions={}

requisitions.generate=function(self)
    local generated_list={}
    for k,v in pairs(self) do
        if type(v)=='table' then
            table.insert(generated_list,k)
        end
    end
    table.sort(generated_list)
    return generated_list
end

requisitions['rifle']={
    description='A tool to shoot small projectiles at very high speeds.',
    cost=5,
    type='WEAPON',
    subtype='RIFLE_SCP',
    mat='INORGANIC:ALUMINUM'
}

requisitions['body armor']={
    description='A para-aramid synthetic fiber ballistic vest. Very strong for its weight.',
    cost=10,
    type='ARMOR',
    subtype='ITEM_ARMOR_BODY_ARMOR',
    mat='INORGANIC:KEVLAR',
}

requisitions['rifle ammo']={
    description='A small projectile to be shot at high speed.',
    cost=0.1,
    type='AMMO',
    subtype='RIFLE_AMMO_SCP',
    mat='INORGANIC:LEAD',
    quantity=10
}