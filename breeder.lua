-- ia_pooper/breeder.lua
-- TODO on hp change, change of miscarriage
-- TODO on death, clear pregnancy
assert(core.get_modpath('ia_progeny'))
local modname = core.get_current_modname()

local pending_procreation = {}

--- Helper to find where a player is sleeping in standard 'beds' mod
local function get_bed_pos(player)
    local playername = player:get_player_name()
    -- Check if player is in the beds mod's internal tracking table
    local in_bed = (beds.player[playername] ~= nil)
    if not in_bed then return nil end
    return player:get_pos()
end

--- Adjacency check for "pushed together" beds
local function are_beds_adjacent(pos1, pos2)
    local dist = vector.distance(pos1, pos2)
    return dist > 0 and dist <= 2.1
end

core.register_chatcommand("procreate", {
    description = "Initiate procreation with a partner in an adjacent bed.",
    func = function(name)
        local player = core.get_player_by_name(name)
        local bed_pos = get_bed_pos(player)
        local gender = ia_gender.get_gender(name)

        if gender ~= 'male' and gender ~= 'female' then
            return false, 'Biological gender not recognized for procreation.'
        end

        if not bed_pos then
            return false, "You must be lying in a bed to procreate."
        end

        -- 1. Check for a pending handshake from a valid biological partner
        for partner_name, data in pairs(pending_procreation) do
            local partner = core.get_player_by_name(partner_name)
            local p_gender = ia_gender.get_gender(partner_name)

            -- Basic biological check: Must be opposite gender
            if partner and p_gender ~= gender and (p_gender == 'male' or p_gender == 'female') then
                if os.time() - data.time < ia_breeder.consent then
                    local partner_bed = get_bed_pos(partner)

                    if partner_bed and are_beds_adjacent(bed_pos, partner_bed) then
                        -- Handshake Success
                        -- Determine who is the 'mother' for gestation purposes
                        local mother = (gender == 'female') and name or partner_name
                        local father = (gender == 'male')   and name or partner_name

                        ia_breeder.impregnate(mother, father)
                        pending_procreation[partner_name] = nil
                        return true, "Success. Gestation period has begun for " .. mother .. "."
                    end
                end
            end
        end

        -- 2. No valid neighbor has initiated; start our own timer
        pending_procreation[name] = {
            time = os.time(),
            pos = bed_pos
        }

        -- Cleanup timer to prevent table bloat
        core.after(ia_breeder.consent, function()
            if pending_procreation[name] and os.time() - pending_procreation[name].time >= ia_breeder.consent then
                pending_procreation[name] = nil
            end
        end)

        return true, "Procreation initiated. An opposite-gender partner in an adjacent bed has " ..
                     ia_breeder.consent .. " seconds to /procreate."
    end,
})

function ia_breeder.impregnate(mother_name, father_name, mob_type)
    assert(not ia_breeder.is_pregnant(mother_name))
    local mother = core.get_player_by_name(mother_name)
    if not mother then return end
    local meta = mother:get_meta()

    local conception = {
        parents = {
            [mother_name] = "mother",
            [father_name] = "father"
        },
        mob_type = mob_type or ia_breeder.default_mob,
        timestamp = os.time()
    }

    meta:set_string(ia_breeder.attr, core.serialize(conception))
    -- Note: hunger_ng manages the gestation_progress float incrementing.

    core.log("action", string.format("[ia_breeder] %s is now carrying a child from %s", mother_name, father_name))
end

function ia_breeder.execute_birth(mother_name)
    assert(ia_breeder.is_pregnant(mother_name))
    local mother = core.get_player_by_name(mother_name)
    if not mother then return end

    local meta = mother:get_meta()
    local data_str = meta:get_string(ia_breeder.attr)
    local data = core.deserialize(data_str)

    if not data then return end

    local pos = mother:get_pos()
    local obj = core.add_entity(pos, data.mob_type)

    pooper.on_impact_helper(pos, 'default:water_flowing', mother_name)
    meta:set_string(ia_breeder.attr, "")
    local hp     = mother:get_hp()
    hp           = math.random(0, hp) -- can die
    mother:set_hp(hp, {type='birth'})

    -- Delay to ensure ia_fake_player/ia_mob has initialized identity
    core.after(0.2, function()
        if not obj or not obj:is_valid() then return end

        -- Get the name (works for both real players and ia_fake_player bridged entities)
        local child_name = obj:get_player_name()

        if child_name and child_name ~= "" then
            ia_progeny.register_descendant(child_name, data.parents)

            -- Reset gestation state
            --meta:set_string(ia_breeder.attr, "")
            -- meta:set_float("ia_progeny:gestation_progress", 0) -- Managed by hunger_ng
        end
    end)
end

function ia_breeder.is_pregnant(playername)
    assert(type(playername) == 'string')
    local player = core.get_player_by_name(playername)
    if not player then return false end
    local meta   = player:get_meta()
    local data   = meta:get_string(ia_breeder.attr)
    if not data then return false end
    if data == "" then return false end
    local deser  = core.deserialize(data)
    --core.log('is pregnant: '..tostring(playername))
    return (deser and true or false)
end

function ia_breeder.pregnancy_pain(playername)
    assert(type(playername) == 'string')
    local player = core.get_player_by_name(playername)
    assert(player ~= nil)
    assert(ia_breeder.is_pregnant(playername))
    local hp     = player:get_hp()
    hp           = math.random(1, hp) -- generally non-fatal; see on_player_hpchange
    player:set_hp(hp, {type='pregnancy'})
end

function ia_breeder.miscarry(playername)
    assert(type(playername) == 'string')
    local player = core.get_player_by_name(playername)
    assert(player ~= nil)
    assert(ia_breeder.is_pregnant(playername))
    local pos    = player:get_pos()
    pooper.on_impact_helper(pos, modname..':blood_flowing', playername)
    local meta   = player:get_meta()
    meta:set_string(ia_breeder.attr, '')
    local hp     = mother:get_hp()
    hp           = math.random(0, hp) -- can die
    player:set_hp(hp, {type='miscarriage'})
end

core.register_on_player_hpchange(function(player, hp_change, reason)
    if hp_change >= 0                         then return hp_change end
    assert(hp_change < 0)
    local playername     = player:get_player_name()
    if not ia_breeder.is_pregnant(playername) then return hp_change end
   
    local risk           = math.random(0, ia_breeder.risk)
    assert(risk >= 0)
    assert(risk <  ia_breeder.risk)
    local is_miscarriage = (risk == 0)
    if not is_miscarriage                     then return hp_change end

    local meta           = player:get_meta()
    meta:set_string(ia_breeder.attr, '')
    local hp             = player:get_hp()
    local next_hp        = (hp + hp_change)
    assert(next_hp < hp)
    if next_hp <= 0                           then return hp_change end
    assert(next_hp > 0)
    local new_hp         = math.random(0, next_hp) -- hp + hp_change
    assert(new_hp >= 0)
    assert(new_hp <  next_hp)
    assert(new_hp <  hp)
    local d_hp           = (new_hp - hp)
    assert(d_hp < 0) -- because new_hp < hp
    assert(d_hp <  hp_change)
    assert(math.abs(d_hp) > math.abs(hp_change))
    return d_hp
end)
