-- ia_pooper/init.lua

assert(core.get_modpath('ia_util'))
assert(ia_util ~= nil)
local modname                    = core.get_current_modname() or "ia_pooper"
local storage                    = core.get_mod_storage()

ia_breeder     = {
    attr       = modname..':conception',
    consent    = 30, -- Seconds for the partner to respond
    mob        = (core.settings:get(modname..":default_mob") or 'ia_fake_player:example'),
    mod        = 'ia',
}

ia_coomer      = {
    alpha      = 150,
    color      = '#FDFFF5', -- TODO more yellow than milk ?
    mod        = 'ia',
    node_alpha = 100,
}

ia_ketchup     = {
    alpha      = 150,
    color      = '#A00303',
    mod        = 'ia',
    node_alpha = 100,
}

ia_milker      = {
    alpha      = 250,
    color      = '#FDFFF5',
    mod        = 'ia',
    node_alpha = 200,
}

ia_peeer       = {
    alpha      = 150,
    color      = '#DDD618',
    mod        = 'ia',
    node_alpha = 100,
}

pooper         = {}
pooper.mod     = 'ia'

local modpath, S                 = ia_util.loadmod(modname) -- NOTE finds & loads lua files; load order is not guaranteed by the API (undefined, but not necessarily non-deterministic)

assert(ia_util.has_placeable_buckets_redo())
pooper.register_bodily_fluid(ia_coomer .color, ia_coomer .node_alpha, ia_coomer .alpha, 'semen', 'Semen', {semen=1})
pooper.register_bodily_fluid(ia_ketchup.color, ia_ketchup.node_alpha, ia_ketchup.alpha, 'blood', 'Blood', {blood=1})
pooper.register_bodily_fluid(ia_milker .color, ia_milker .node_alpha, ia_milker .alpha, 'milk',  'Milk',  {milk =1})
pooper.register_bodily_fluid(ia_peeer  .color, ia_peeer  .node_alpha, ia_peeer  .alpha, 'urine', 'Urine', {urine=1})

