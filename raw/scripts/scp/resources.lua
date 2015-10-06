function getResourcePersist(site,resource)
    return dfhack.persistent.save({key='RESOURCE/'..resource:upper()..'/'..site})
end

function adjustResource(site,resource,amount,spend)
    local resource=getResourcePersist(site,resource)
    if (not spend) or amount>0 then 
        resource.ints[1]=resource.ints[1]<0 and amount or resource.ints[1]+amount
    elseif amount<0 then
        if resource.ints[1]+amount<0 then return false else resource.ints[1]=resource.ints[1]+amount end
    end
    resource:save()
    return resource.ints[1]
end

function getResourceAmount(site,resource)
    return adjustResource(site,resource,0)
end