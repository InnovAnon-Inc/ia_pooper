-- ia_pooper/util.lua
assert(ia_util.has_placeable_buckets_redo())

local modname = core.get_current_modname()

function pooper.play_sound_at(soundname, pos, max_hear_distance)
	assert(pos ~= nil)
	core.sound_play(soundname, {pos=pos, gain = 1.0, max_hear_distance = max_hear_distance,})
end

function pooper.play_sound(soundname, playername, max_hear_distance)
	local player = core.get_player_by_name(playername)
	assert(player ~= nil)
	local pos    = player:get_pos()
	play_sound_at(soundname, pos, max_hear_distance)
end

function pooper.try_fill_held_glass(player, glass)
	assert(player ~= nil)
	--assert(player.get_wield_item ~= nil)
    local itemstack = player:get_wielded_item()
    local name = itemstack:get_name()

    -- Check if player is wielding an empty drinking glass
    if name == "vessels:drinking_glass" then
        -- Remove one empty glass
        itemstack:take_item(1)
        player:set_wielded_item(itemstack)

        --local pee_item = modname..":jcu_blood" -- Replace 'modname' with your actual mod prefix
        local inv = player:get_inventory()
        
        if inv:room_for_item("main", glass) then
            inv:add_item("main", glass)
        else
            -- Drop on ground if inventory is full
            core.add_item(player:get_pos(), glass)
        end
        
        return true
    end

    return false
end

function pooper.on_impact_primary(pos)
    if not core.get_modpath('pedology') then return false end
    pos            = vector.round(pos)
    local expected = core.get_node(pos)
    pedology.wetten(pos)
    local actual   = core.get_node(pos)
    if actual ~= expected then return true end
    local below    = {x=0, y=-1, z=0}
    pos            = vector.add(pos, below)
    pedology.wetten(pos)
    return (actual ~= expected)
end

function pooper.can_discharge_on(pos, nodename)
    pos            = vector.round(pos)
    local node     = core.get_node(pos)
    if node      == nil                       then return false end
    if node.name == 'air'                     then return true  end
    -- TODO if buildable to ?
    --local def      = core.registered_nodes[node.name]
    --return def.walkable
    if node.name ~= nodename then return false end
    local level    = core.get_node_level(pos)
    local max      = core.get_node_max_level(pos)
    return (level < max)
end

function pooper.on_impact_secondary(pos, nodename)
    pos            = vector.round(pos)
    local above    = {x=0, y= 1, z=0}
    if not pooper.can_discharge_on(pos, nodename) then
	core.log('cannot discharge bodily fluids at '..tostring(pos))
        pos        = vector.add(pos, above)
    end
    if not can_discharge_on(pos, nodename) then
	core.log('cannot discharge bodily fluids on '..tostring(pos))
         return false
    end
    local expected = core.get_node(pos)
    if expected.name == nodename then
        core.add_node_level(pos, 1)
	return true
    end
    core.set_node(pos, {name = nodename, param2 = 1})
    local actual   = core.get_node(pos)
    return (actual ~= expected)
end

function pooper.on_impact_tag_meta(pos, playername)
    assert(type(pos)        == 'table')
    assert(type(playername) == 'string')
    local meta             = core.get_meta(pos)
    local data             = meta:get_string(modname..':dischargers')
    local deser            = core.deserialize(data) or {}
    if deser[self.playername] then return false end
    deser[self.playername] = true
    data                   = core.serialize(deser)
    meta:set_string(modname..':dischargers', data)
    return true
end

function pooper.on_impact_helper(pos, nodename, playername)
    assert(type(pos)        == 'table')
    assert(type(nodename)   == 'string')
    assert(type(playername) == 'string')
    pooper.on_impact_tag_meta(pos, playername)
    local wetted = pooper.on_impact_primary  (pos)
    if wetted then return true end
    wetted       = pooper.on_impact_secondary(pos, nodename)
    if wetted then return true end
    return false
end

function pooper.register_bodily_fluid(color, node_alpha, alpha, name, desc, groups)
    assert(ia_util.has_placeable_buckets_redo())
    local bucket      = modname..':bucket_'     ..name
    local bucket_wood = modname..':bucket_wood_'..name 
    placeable_buckets.register_liquid(
	    modname,
	    color, node_alpha, alpha,
	    name, desc,
	    groups,
	    'default:water_source', 'default:water_flowing',
	    bucket, bucket_wood)
    placeable_buckets.register_drink_vessels(
	    modname,
	    color,
	    name, desc,
	    1, -1,
            modname..':'..name..'_source', modname..':'..name..'_flowing',
	    bucket,  bucket_wood)
end

