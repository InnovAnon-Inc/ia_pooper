-- ia_pooper/peeer.lua
--assert(ia_util.has_drinks_redo())
assert(ia_util.has_placeable_buckets_redo())

local modname    = core.get_current_modname()
local pee_color  = ia_peeer.color
local node_alpha = ia_peeer.node_alpha
local alpha      = ia_peeer.alpha
local droplet    = 'fireflies_firefly.png'
droplet          = droplet.."^[colorize:"..pee_color..":"..node_alpha

--
--
--

--local function play_sound_at(soundname, pos, max_hear_distance)
--	assert(pos ~= nil)
--	core.sound_play(soundname, {pos=pos, gain = 1.0, max_hear_distance = max_hear_distance,})
--end
--
--local function play_sound(soundname, playername, max_hear_distance)
--	local player = core.get_player_by_name(playername)
--	assert(player ~= nil)
--	local pos    = player:get_pos()
--	play_sound_at(soundname, pos, max_hear_distance)
--end

function ia_peeer.play_zipper_sound(playername)
	--play_sound("poop_rumble", playername, 10) -- TODO need resources
end
function ia_peeer.play_splatter_sound_at(pos)
	--play_sound_at("poop_defecate", pos, 10) -- TODO need resources
end

--
--
--

function ia_peeer.get_urine_amount(playername) -- exposed for convenient monkey-patching
    assert(playername ~= nil)
    return 10.0 -- a reasonable default
end

function ia_peeer.set_urine_amount(playername, amount)
    assert(playername ~= nil)
    assert(amount     ~= nil)
    core.log('ia_peeer.set_urine_amount(playername='..playername..', amount='..amount..')')
end

function ia_peeer.decrement_urine_amount(playername, amount)
    assert(playername ~= nil)
    assert(amount     ~= nil)
    core.log('ia_peeer.decrement_urine_amount(playername='..playername..', amount='..amount..')')
end

--
--
--

--function ia_peeer.try_fill_held_glass(player)
--	assert(player ~= nil)
--	--assert(player.get_wield_item ~= nil)
--    local itemstack = player:get_wielded_item() -- FIXME
--    local name = itemstack:get_name()
--
--    -- Check if player is wielding an empty drinking glass
--    if name == "vessels:drinking_glass" then
--        -- Remove one empty glass
--        itemstack:take_item(1)
--        player:set_wielded_item(itemstack)
--
--        local pee_item = modname..":jcu_urine" -- Replace 'modname' with your actual mod prefix
--        local inv = player:get_inventory()
--        
--        if inv:room_for_item("main", pee_item) then
--            inv:add_item("main", pee_item)
--        else
--            -- Drop on ground if inventory is full
--            core.add_item(player:get_pos(), pee_item)
--        end
--        
--        return true
--    end
--
--    return false
--end

function ia_peeer.urinate(playername, amount)
    assert(playername ~= nil)
    local player     = core.get_player_by_name(playername)
    assert(player     ~= nil)
    local pos        = player:get_pos()
    assert(pos        ~= nil)
    amount           = (amount or ia_peeer.get_urine_amount(player))
    --local freq       = 0.05
    local freq       = 1
    local start_time = 0
    local flag       = false

    local function spawn_stream()
        if not core.get_player_by_name(playername) then return end
	if start_time < amount then
	   ia_peeer.spawn_pee_droplet_entity_from_player(playername, freq)
           start_time   = (start_time + freq)
           core.after(freq, spawn_stream)
	   return
        end
	if flag then return end
	ia_peeer.play_zipper_sound(playername)
	flag     = true
    end

    ia_peeer.play_zipper_sound(playername)
    --spawn_stream()
    return (pooper.try_fill_held_glass(player, modname..':jcu_urine') or spawn_stream())
end

function ia_peeer.spawn_pee_droplet_entity_from_player(playername, freq)
    local player       = core.get_player_by_name(playername)
    assert(player ~= nil)
    local pos         = player:get_pos()
    assert(pos    ~= nil)
    local look_dir     = player:get_look_dir()
    local eye_height   = player:get_properties().eye_height or 1.5
    --local spawn_pos    = vector.add(pos, {x=0, y=eye_height - 0.5, z=0})
    local spawn_pos    = vector.add(pos, {x=0, y=eye_height - 0.5 - 0.3, z=0})
    spawn_pos          = vector.add(spawn_pos, vector.multiply(look_dir, 0.2))
    local obj          = ia_peeer.spawn_pee_droplet_entity(spawn_pos, look_dir, freq)
    if not obj then return nil end
    local ent          = obj:get_luaentity()
    if ent then
        ent.playername = playername -- Attach the name here
    end
    ia_peeer.decrement_urine_amount(playername, 1)
    return obj
end

function ia_peeer.spawn_pee_droplet_entity(spawn_pos, look_dir, freq)
    local obj         = core.add_entity(spawn_pos, modname..":urine_droplet")
    if not obj then return nil end
    local initial_vel = vector.multiply(look_dir, 8)
    obj:set_velocity(initial_vel)
    obj:set_acceleration({x=0, y=-9.81, z=0}) -- TODO in space ?

    -- TODO scale inversely with freq
    core.add_particlespawner({
        --amount = 15,
        amount = 120,
        time = 0, -- Stay alive until the entity is removed
        minpos = {x=0, y=0, z=0},
        maxpos = {x=0, y=0, z=0},
        minvel = {x=-0.05, y=-0.05, z=-0.05},
        maxvel = {x= 0.05, y= 0.05, z= 0.05},
        minacc = {x=0, y=0, z=0},
        maxacc = {x=0, y=0, z=0},
        --minexptime = 0.2,
        minexptime = 0.2,
        --maxexptime = 0.5,
        maxexptime = 0.5,
        minsize = 1.2, -- Slightly larger than the droplet for volume
        maxsize = 2.0,
        texture = droplet,
        attached = obj, -- This is the key
	--collisiondetection = true,
	--collision_removal = true,
    })

    return obj
end

--
--
--

local function on_step(self, dtime)
    local pos = self.object:get_pos()
    local vel = self.object:get_velocity()
    local fin = vector.add(pos, vector.multiply(vel, dtime))

    local ray = core.raycast(pos, fin, false, false)
    for pointed in ray do
        if pointed.type == "node" then
            -- We found an impact!
            self:on_impact(pointed.under)
            self.object:remove()
            return
        end
    end

    -- Add trail particles so it looks like a stream
    -- core.add_particlespawner({
    core.add_particle({ 
        pos = pos,
        --velocity = {x=0, y=0, z=0},
        --acceleration = {x=0, y=0, z=0},
        expirationtime = 0.2,
        --expirationtime = 0.3,
        size = 0.8,
        --size = 1.5,
        --texture = droplet,
        texture = droplet.."^[brighten",
    })

    -- Check for collision manually for better control
    -- If velocity magnitude drops significantly, we've hit something

    -- Safety: remove if it falls into the void/unloaded blocks
--    if pos.y < -30000 then self.object:remove() end

    -- Calculate next position to perform a "look-ahead" raycast

    -- Raycast to detect collisions BEFORE they happen
end

--local function on_impact_primary(pos)
--    if not core.get_modpath('pedology') then return false end
--    pos            = vector.round(pos)
--    local expected = core.get_node(pos)
--    pedology.wetten(pos)
--    local actual   = core.get_node(pos)
--    if actual ~= expected then return true end
--    local below    = {x=0, y=-1, z=0}
--    pos            = vector.add(pos, below)
--    pedology.wetten(pos)
--    return (actual ~= expected)
--end
--
--local function can_pee_on(pos)
--    pos            = vector.round(pos)
--    local node     = core.get_node(pos)
--    if node      == nil                       then return false end
--    if node.name == 'air'                     then return true  end
--    --local def      = core.registered_nodes[node.name]
--    --return def.walkable
--    if node.name ~= modname..":urine_flowing" then return false end
--    local level    = core.get_node_level(pos)
--    local max      = core.get_node_max_level(pos)
--    return (level < max)
--end
--
--local function on_impact_secondary(pos)
--    pos            = vector.round(pos)
--    local above    = {x=0, y= 1, z=0}
--    if not can_pee_on(pos) then
--	core.log('cannot pee at '..tostring(pos))
--        pos        = vector.add(pos, above)
--    end
--    if not can_pee_on(pos) then
--	core.log('cannot pee on '..tostring(pos))
--         return false
--    end
--    local expected = core.get_node(pos)
--    if expected.name == modname..":urine_flowing" then
--        core.add_node_level(pos, 1)
--	return true
--    end
--    core.set_node(pos, {name = modname..":urine_flowing", param2 = 1})
--    local actual   = core.get_node(pos)
--    return (actual ~= expected)
--end

local function on_impact(self, pos)
    ia_peeer.play_splatter_sound_at(pos)
    --local playername = self.playername
    core.add_particlespawner({
        amount = 100,
        --time = 0.1,
        time = 0.05,
        pos = pos,
        minvel = {x=-1, y=1, z=-1},
        maxvel = {x=1, y=2, z=1},
        minacc = {x=0, y=-9.81, z=0}, -- TODO in space ?
        texture = droplet,
    })
--    local wetted = on_impact_primary  (pos)
--    if wetted then return end
--    wetted       = on_impact_secondary(pos)
--    if wetted then return end
    assert(self.playername ~= nil)
    --local meta   = core.get_meta(pos)
    --meta:set_string(modname..':peeer', self.playername) -- TODO append table
    local result = pooper.on_impact_helper(pos, modname..':urine_flowing', self.playername)
    if result then return end
    core.log('ia_peeer.on_impact failure')
end

--
--
--

core.register_chatcommand("urinate", {
    params = "[amount]",
    description = "Release the pressure.",
    func = function(playername, param)
        local amount = tonumber(param)
        ia_peeer.urinate(playername, amount)
        return true, "Relief!"
    end,
})

core.register_entity(modname..":urine_droplet", {
    initial_properties = {
        visual = "sprite",
        textures = {droplet},
        visual_size = {x = 0.1, y = 0.1},
        collisionbox = {0, 0, 0, 0, 0, 0}, -- Small for precision
        physical = true,
        static_save = false, -- Don't save pee in the map file
    },
    on_step            = on_step,
    on_impact          = on_impact,
})

--local groups     = {urine=1}
--local bucket_urine      = modname..':bucket_urine'
--local bucket_wood_urine = modname..':bucket_wood_urine'
----local bucket_urine      = modname..':jbu_urine'
----local bucket_wood_urine = modname..':jbw_urine'
--placeable_buckets.register_liquid(modname, pee_color, node_alpha, alpha, 'urine', 'Urine', groups, 'default:water_source', 'default:water_flowing', bucket_urine, bucket_wood_urine)
--placeable_buckets.register_drink_vessels(modname, pee_color, 'urine', 'Urine', 1, -1,
--    modname..':urine_source', modname..':urine_flowing', bucket_urine, bucket_wood_urine)
--pooper.register_bodily_fluid(pee_color, node_alpha, alpha, 'urine', 'Urine', groups)
    --'default:water_source', 'default:water_flowing')
-- TODO register all the glasses, glass bottles, heavy steel bottles and such
--
--core.register_node("ia_peeer:urine_source", {
--    description = "Urine Source",
--    drawtype = "liquid",
--    tiles = {{
--        name = "ia_peeer_urine_animated.png",
--        animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 3.0}
--    }},
--    alpha = 180,
--    paramtype = "light",
--    walkable = false,
--    pointable = false,
--    diggable = false,
--    buildable_to = true,
--    drop = "",
--    drowning = 0,
--    liquidtype = "source",
--    liquid_alternative_flowing = "ia_peeer:urine_flowing",
--    liquid_alternative_source = "ia_peeer:urine_source",
--    liquid_viscosity = 1,
--    liquid_renewable = false,
--    groups = {liquid = 3, urine = 1},
--})
--
--core.register_node("ia_peeer:urine_flowing", {
--    description = "Flowing Urine",
--    drawtype = "flowingliquid",
--    tiles = {"ia_peeer_urine.png"},
--    special_tiles = {{
--        name = "ia_peeer_urine_animated.png",
--        backface_culling = false,
--        animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 0.8}
--    }, {
--        name = "ia_peeer_urine_animated.png",
--        backface_culling = true,
--        animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 0.8}
--    }},
--    alpha = 180,
--    paramtype = "light",
--    param2 = 0, -- Flow level
--    walkable = false,
--    pointable = false,
--    diggable = false,
--    buildable_to = true,
--    drop = "",
--    drowning = 0,
--    liquidtype = "flowing",
--    liquid_alternative_flowing = "ia_peeer:urine_flowing",
--    liquid_alternative_source = "ia_peeer:urine_source",
--    liquid_viscosity = 1,
--    liquid_renewable = false,
--    groups = {liquid = 3, urine = 1, not_in_creative_inventory = 1},
--})

