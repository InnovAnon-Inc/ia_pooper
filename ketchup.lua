-- ia_pooper/ketchup.lua
assert(ia_util.has_placeable_buckets_redo())

-- FIXME blood source/flowing looks kinda maroon
local modname     = core.get_current_modname()
--local blood_color = '#8A0303'
local node_alpha  = ia_ketchup.node_alpha
--local node_alpha  = 200
local alpha       = ia_ketchup.alpha  
--local droplet     = 'fireflies_firefly.png'
----droplet           = droplet.."^[colorize:"..blood_color..":"..node_alpha
--local kill_blue = "^[brighten^[multiply:#ffffff" -- NOTE testing
--droplet           = '('..droplet..kill_blue..')'.."^[colorize:"..blood_color..":"..node_alpha -- FIXME too yellow (because the fireflies)
local blood_color = ia_ketchup.color

---- Strips existing color so the red isn't "poisoned" by the firefly yellow
local base_droplet = "fireflies_firefly.png"
---- Option A: Desaturate first (Cleaner red)
--local droplet = base_droplet .. "^[greyscale^[colorize:" .. blood_color .. ":" .. node_alpha -- invalid modification greyscale
---- Option B: For a darker, "dried" blood look (Maroon/Brownish)
---- We multiply by a dark grey first to lower the brightness floor
local droplet = base_droplet .. "^[multiply:#888888^[colorize:" .. blood_color .. ":" .. node_alpha

--local node_alpha  = 150      -- Higher opacity prevents the ground color from muddying the red
--local alpha       = 200

-- 1. Greyscale strips the firefly yellow
-- 2. Colorize adds the red
-- 3. Brighten pushes it into "vibrant" territory
--droplet = "fireflies_firefly.png^[greyscale^[colorize:"..blood_color..":"..node_alpha.."^[brighten"
--droplet = "fireflies_firefly.png^[greyscale^[colorize:"..blood_color..":255"

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

function ia_ketchup.play_spatter_sound(playername)
	--play_sound("poop_rumble", playername, 10) -- TODO need resources
end
function ia_ketchup.play_splatter_sound_at(pos)
	--play_sound_at("poop_defecate", pos, 10) -- TODO need resources
end

--function ia_ketchup.try_fill_held_glass(player)
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
--        local pee_item = modname..":jcu_blood" -- Replace 'modname' with your actual mod prefix
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

--function ia_ketchup.squirt(playername, amount)
--    assert(playername ~= nil)
--    local player     = core.get_player_by_name(playername)
--    assert(player     ~= nil)
--    local pos        = player:get_pos()
--    assert(pos        ~= nil)
--    amount           = (amount or 1)
--    -- TODO set hp
--    --local freq       = 0.05
--    local freq       = 1
--    local start_time = 0
--    local flag       = false
--
--    local function spawn_stream()
--        if not core.get_player_by_name(playername) then return end
--	if start_time < amount then
--	   ia_ketchup.spawn_ketchup_droplet_entity_from_player(playername, freq)
--           start_time   = (start_time + freq)
--           core.after(freq, spawn_stream)
--	   return
--        end
--	if flag then return end
--	--ia_ketchup.play_zipper_sound(playername)
--	flag     = true
--    end
--
--    --ia_ketchup.play_zipper_sound(playername)
--    --spawn_stream()
--    return (ia_ketchup.try_fill_held_glass(player) or spawn_stream())
--end

function ia_ketchup.spawn_ketchup_droplet_entity_from_player(playername, freq)
    local player       = core.get_player_by_name(playername)
    assert(player ~= nil)
    local pos         = player:get_pos()
    assert(pos    ~= nil)
    local look_dir     = player:get_look_dir()
    local eye_height   = player:get_properties().eye_height or 1.5 -- TODO not eye height ?
    local spawn_pos    = vector.add(pos, {x=0, y=eye_height - 0.5, z=0})
    spawn_pos          = vector.add(spawn_pos, vector.multiply(look_dir, 0.2))
    local obj          = ia_ketchup.spawn_ketchup_droplet_entity(spawn_pos, look_dir, freq)
    if not obj then return nil end
    local ent          = obj:get_luaentity()
    if ent then
        ent.playername = playername -- Attach the name here
    end
    --ia_ketchup.decrement_blood_amount(playername, 1)
    player:set_hp(player:get_hp() - 1, {type='bleeding'})
    return obj
end

function ia_ketchup.spawn_ketchup_droplet_entity(spawn_pos, look_dir, freq)
    local obj         = core.add_entity(spawn_pos, modname..":ketchup_droplet")
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
--local function can_bleed_on(pos)
--    pos            = vector.round(pos)
--    local node     = core.get_node(pos)
--    if node      == nil                       then return false end
--    if node.name == 'air'                     then return true  end
--    --local def      = core.registered_nodes[node.name]
--    --return def.walkable
--    if node.name ~= modname..":blood_flowing" then return false end
--    local level    = core.get_node_level(pos)
--    local max      = core.get_node_max_level(pos)
--    return (level < max)
--end
--
--local function on_impact_secondary(pos)
--    pos            = vector.round(pos)
--    local above    = {x=0, y= 1, z=0}
--    if not can_bleed_on(pos) then
--	core.log('cannot bleed at '..tostring(pos))
--        pos        = vector.add(pos, above)
--    end
--    if not can_bleed_on(pos) then
--	core.log('cannot bleed on '..tostring(pos))
--         return false
--    end
--    local expected = core.get_node(pos)
--    if expected.name == modname..":blood_flowing" then
--        core.add_node_level(pos, 1)
--	return true
--    end
--    core.set_node(pos, {name = modname..":blood_flowing", param2 = 1})
--    local actual   = core.get_node(pos)
--    return (actual ~= expected)
--end

local function on_impact(self, pos)
    ia_ketchup.play_splatter_sound_at(pos)
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
    --local wetted = on_impact_primary  (pos)
    --if wetted then return end
    --wetted       = on_impact_secondary(pos)
    --if wetted then return end
    assert(self.playername ~= nil)
    --local meta   = core.get_meta(pos)
    --meta:set_string(modname..':bleeder', self.playername) -- TODO append table
    local result = pooper.on_impact_helper(pos, modname..':blood_flowing', self.playername)
    if result then return end
    core.log('ia_ketchup.on_impact failure')
end

--
--
--

core.register_chatcommand("bleed", {
    params = "[amount]",
    description = "Release the pressure.",
    func = function(playername, param)
        local amount = tonumber(param)
        ia_ketchup.bleed(playername, amount)
        return true, "Relief!"
    end,
})

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

core.register_entity(modname..":blood_droplet", {
    initial_properties = {
        visual = "sprite",
        textures = {droplet},
        visual_size = {x = 0.1, y = 0.1},
        collisionbox = {0, 0, 0, 0, 0, 0}, -- Small for precision
        physical = true,
        static_save = false, -- Don't save blood in the map file
    },
    on_step            = on_step,
    on_impact          = on_impact,
})









function ia_ketchup.bleed(playername, amount)
    assert(playername ~= nil)
    local player     = core.get_player_by_name(playername)
    assert(player     ~= nil)
    local pos        = player:get_pos()
    assert(pos        ~= nil)
    local min_amount = 5
    amount           = (amount or min_amount)
    local result     = false
    local hp         = player:get_hp()
    amount           = math.min(amount, hp)
    player:set_hp(hp - amount, {type='bleeding'})
    if amount >= min_amount then
	if pooper.try_fill_held_glass(player, modname..':jcu_blood') then return true end
    end
    ia_ketchup.spawn_ketchup_from_player(playername, amount)
end

--function ia_ketchup.spawn_ketchup_from_player(playername, amount)
--    error('TODO') -- TODO
--    if not obj then return nil end
--    local ent          = obj:get_luaentity()
--    if ent then
--        ent.playername = playername -- Attach the name here
--    end
--    --ia_ketchup.decrement_blood_amount(playername, 1)
--    player:set_hp(player:get_hp() - amount)
--    return obj
--end
--
--ia_ketchup.function spawn_ketchup(pos, amount)
--    core.add_particlespawner({
--        amount = amount,
--        time = 0.1,
--        minpos = {x = pos.x - 0.2, y = pos.y + 1.2, z = pos.z - 0.2},
--        maxpos = {x = pos.x + 0.2, y = pos.y + 1.5, z = pos.z + 0.2},
--        minvel = {x = -1, y = 1, z = -1},
--        maxvel = {x = 1, y = 3, z = 1},
--        minacc = {x = 0, y = -9.81, z = 0},
--        maxacc = {x = 0, y = -9.81, z = 0},
--        minexptime = 0.5,
--        maxexptime = 1.5,
--        minsize = 1,
--        maxsize = 3,
--        collisiondetection = true,
--        vertical = false,
--        texture = texture, -- droplet.."^[colorize:#8a0303:200", -- Deep red
--    })
--end
--
--core.register_on_player_hpchange(function(player, hp_change, reason)
--    -- Only proceed if the player is losing health
--    if hp_change >= 0 then
--	    core.log('hp change: '..player:get_player_name())
--	    return hp_change end
--
--    -- Filter out hunger_ng and metabolic damage
--    -- reason.type can be "set_hp", "punch", "fall", "node_damage", "drown", "respawn"
--    local cause = reason.type
--    
--    -- "Reasonable" damage types: physical impacts
--    local physical_damage = {
--        punch = true,
--        fall = true,
--        node_damage = true, -- e.g. cactus, lava
--    }
--
--    -- If the cause is metabolic (like hunger_ng calling set_hp) or not in our list, skip
--    if not physical_damage[cause] then
--	    core.log('no cause: '..player:get_player_name())
--        return hp_change
--    end
--
--    -- Optional: check for specific hunger_ng indicators if it uses custom reasons
--    if reason.mod == "hunger_ng" then
--	    core.log('hunger_ng: '..player:get_player_name())
--        return hp_change
--    end
--
--    -- Visual effect
--    local pos = player:get_pos()
--    local intensity = math.abs(hp_change) * 5
--    spawn_ketchup(pos, math.min(intensity, 30))
--
--    return hp_change
--end)
-- ia_ketchup/init.lua

--- Decorative particle burst
function ia_ketchup.spawn_ketchup(pos, amount)
    assert(pos ~= nil)
    assert(amount ~= nil)
    core.log('spawn_ketchup(amount='..amount..')')
    core.add_particlespawner({
        amount = amount,
        time = 0.1,
        minpos = {x = pos.x - 0.2, y = pos.y + 1.2, z = pos.z - 0.2},
        maxpos = {x = pos.x + 0.2, y = pos.y + 1.5, z = pos.z + 0.2},
        minvel = {x = -1, y = 1, z = -1},
        maxvel = {x = 1, y = 3, z = 1},
        minacc = {x = 0, y = -9.81, z = 0},
        maxacc = {x = 0, y = -9.81, z = 0},
        minexptime = 0.5,
        maxexptime = 1.5,
        minsize = 1,
        maxsize = 3,
        collisiondetection = true,
        vertical = false,
        texture = droplet, -- Using the localized droplet string from the top of your file
    })
end

--- Physical droplet that spawns blood nodes on impact
function ia_ketchup.spawn_ketchup_from_player(playername, amount)
    core.log('spawn_ketchup_from_player(amount='..amount..')')
    assert(playername ~= nil)
    assert(amount ~= nil)
    local player = core.get_player_by_name(playername)
    assert(player ~= nil)
    --if not player then return nil end
    
    local pos = player:get_pos()
    local look_dir = player:get_look_dir()
    
    -- Decorative burst at the source
    --ia_ketchup.spawn_ketchup(pos, amount * 10)
    ia_ketchup.spawn_ketchup(pos, amount * 100)
    
    -- Fire physical droplet entities based on the 'amount'
    --for i = 1, amount do
    for i = 1, amount * 10 do
        -- Add slight variance to look_dir for a spray effect
        local spread = {
            x = look_dir.x + (math.random() - 0.5) * 0.2,
            y = look_dir.y + (math.random() - 0.5) * 0.2,
            z = look_dir.z + (math.random() - 0.5) * 0.2
        }
        ia_ketchup.spawn_ketchup_droplet_entity_from_player(playername, 1)
    end
end

-- Core Handler for all damage
local function run_ketchup_logic(player, hp_change, reason)
    if hp_change >= 0 then return end

    local cause = reason and reason.type
    local physical_damage = {
        punch = true,
        fall = true,
        node_damage = true,
    }

    if not physical_damage[cause] then
        return
    end

    local pos = player:get_pos()
    if not pos then return end
    
    local intensity = math.abs(hp_change) * 5
    --ia_ketchup.spawn_ketchup(pos, math.min(intensity, 40))
    ia_ketchup.spawn_ketchup_from_player(player, math.min(intensity, 40))
end

-- 1. Hook for real players (returns number to satisfy engine)
core.register_on_player_hpchange(function(player, hp_change, reason)
    run_ketchup_logic(player, hp_change, reason)
    return hp_change 
end)

-- 2. Hook for fake players (mobs/NPCs)
--if core.get_modpath('ia_fake_player') then
--    ia_fake_player.registered_on_hp_change = ia_fake_player.registered_on_hp_change or {}
--    table.insert(ia_fake_player.registered_on_hp_change, function(player, hp_change, reason)
--        run_ketchup_logic(player, hp_change, reason)
--    end)
--end

