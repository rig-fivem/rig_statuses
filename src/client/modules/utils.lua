local m = {}

function m.is_in_water(entity, allow_swimming)
    if not IsEntityInWater(entity) then return false end
    if not allow_swimming and IsPedSwimming(entity) then return false end
    return true
end

return m