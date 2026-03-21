-- ia_pooper/coomer.lua
--assert(ia_util.has_drinks_redo())
assert(ia_util.has_placeable_buckets_redo())

local modname     = core.get_current_modname()
local semen_color = ia_coomer.color
local node_alpha  = ia_coomer.node_alpha
local alpha       = ia_coomer.alpha
local droplet     = 'fireflies_firefly.png'
droplet           = droplet.."^[colorize:"..semen_color..":"..node_alpha

--
--
--

function ia_coomer.play_zipper_sound(playername)
	--pooper.play_sound("poop_rumble", playername, 10) -- TODO need resources
end
function ia_coomer.play_splatter_sound_at(pos)
	--pooper.play_sound_at("poop_defecate", pos, 10) -- TODO need resources
end

--
--
--

function ia_coomer.get_semen_amount(playername) -- exposed for convenient monkey-patching
    assert(playername ~= nil)
    return 10.0 -- a reasonable default
end

function ia_coomer.set_semen_amount(playername, amount)
    assert(playername ~= nil)
    assert(amount     ~= nil)
    core.log('ia_coomer.set_semen_amount(playername='..playername..', amount='..amount..')')
end

function ia_coomer.decrement_semen_amount(playername, amount)
    assert(playername ~= nil)
    assert(amount     ~= nil)
    core.log('ia_coomer.decrement_semen_amount(playername='..playername..', amount='..amount..')')
end

--
--
--

function ia_coomer.ejaculate(playername, amount)
    assert(playername ~= nil)
    local player     = core.get_player_by_name(playername)
    assert(player     ~= nil)
    local pos        = player:get_pos()
    assert(pos        ~= nil)
    amount           = (amount or ia_coomer.get_semen_amount(player))
    --local freq       = 0.05
    local freq       = 1
    local start_time = 0
    local flag       = false

    local function spawn_stream()
        if not core.get_player_by_name(playername) then return end
	if start_time < amount then
	   ia_coomer.spawn_semen_droplet_entity_from_player(playername, freq)
           start_time   = (start_time + freq)
           core.after(freq, spawn_stream)
	   return
        end
	if flag then return end
	ia_coomer.play_zipper_sound(playername)
	flag     = true
    end

    ia_coomer.play_zipper_sound(playername)
    --spawn_stream()
    return (pooper.try_fill_held_glass(player, modname..':jcu_semen') or spawn_stream())
end

function ia_coomer.spawn_semen_droplet_entity_from_player(playername, freq)
    local player       = core.get_player_by_name(playername)
    assert(player ~= nil)
    local pos         = player:get_pos()
    assert(pos    ~= nil)
    local look_dir     = player:get_look_dir()
    local eye_height   = player:get_properties().eye_height or 1.5
    --local spawn_pos    = vector.add(pos, {x=0, y=eye_height - 0.5, z=0})
    local spawn_pos    = vector.add(pos, {x=0, y=eye_height - 0.5 - 0.3, z=0})
    spawn_pos          = vector.add(spawn_pos, vector.multiply(look_dir, 0.2))
    local obj          = ia_coomer.spawn_semen_droplet_entity(spawn_pos, look_dir, freq)
    if not obj then return nil end
    local ent          = obj:get_luaentity()
    if ent then
        ent.playername = playername -- Attach the name here
    end
    ia_coomer.decrement_semen_amount(playername, 1)
    return obj
end

function ia_coomer.spawn_semen_droplet_entity(spawn_pos, look_dir, freq)
    local obj         = core.add_entity(spawn_pos, modname..":semen_droplet")
    if not obj then return nil end
    local initial_vel = vector.multiply(look_dir, 8)
    obj:set_velocity(initial_vel)
    obj:set_acceleration({x=0, y=-9.81, z=0}) -- TODO in space ?

    -- TODO less streaming, more spurting

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

local function on_impact(self, pos)
    ia_coomer.play_splatter_sound_at(pos)
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
    assert(self.playername ~= nil)
    --local meta   = core.get_meta(pos)
    --meta:set_string(modname..':coomer', self.playername) -- TODO append table
    local result = pooper.on_impact_helper(pos, modname..':semen_flowing', self.playername)
    if result then return end
    core.log('ia_coomer.on_impact failure')
end

--
--
--

core.register_chatcommand("ejaculate", {
    params = "[amount]",
    description = "Release the pressure.",
    func = function(playername, param)
        local amount = tonumber(param)
        ia_coomer.ejaculate(playername, amount)
        return true, "Relief!"
    end,
})

core.register_entity(modname..":semen_droplet", {
    initial_properties = {
        visual = "sprite",
        textures = {droplet},
        visual_size = {x = 0.1, y = 0.1},
        collisionbox = {0, 0, 0, 0, 0, 0}, -- Small for precision
        physical = true,
        static_save = false, -- Don't save semen in the map file
    },
    on_step            = on_step,
    on_impact          = on_impact,
})

