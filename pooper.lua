-- ia_pooper/pooper.lua
local modname = core.get_current_modname()


--local function play_sound(soundname, playername, max_hear_distance)
--	local player = core.get_player_by_name(playername)
--	--local player = ia_names.get_actor_by_name(playername)
--	assert(player ~= nil)
--	local pos    = player:get_pos()
--	assert(pos ~= nil)
--	core.sound_play(soundname, {pos=pos, gain = 1.0, max_hear_distance = max_hear_distance,})
--end
function pooper.play_rumble_sound(playername)
	pooper.play_sound("poop_rumble", playername, 10)
end
function pooper.play_defecate_sound(playername)
	pooper.play_sound("poop_defecate", playername, 10)
end

function pooper.defecate(playername)
	local player   = core.get_player_by_name(playername)
	--local player = ia_names.get_actor_by_name(playername)
	assert(player ~= nil)
	local pos      = player:get_pos()
	assert(pos    ~= nil)
	local item     = ItemStack(modname..':poop_turd')
	local meta     = item:get_meta()
	meta:set_string(modname..':creator', playername)
	--local obj = core.add_item(pos, "pooper:poop_turd")
	local obj      = core.add_item(pos, item)
	if not obj then return end
	obj.playername = playername
end

function pooper.defecate_soon(playername, dt)
	pooper.play_rumble_sound(playername)
	core.after(dt, function()
		pooper.defecate(playername)
	end)
end

core.register_node("pooper:poop_pile", {
	description = "Pile of Feces",
	tiles       = {"poop_pile.png"},
	groups      = {crumbly = 3, soil = 1, falling_node = 1},
	drop        = "pooper:poop_turd" .. " 4",
	sounds      = default.node_sound_dirt_defaults(),
        --_compost    = { -- TODO
        --  amount = amount,
        --  C      = C,
        --  N      = N,
        --},
})

core.register_craftitem("pooper:poop_turd", {
	description     = "Feces",
	inventory_image = "poop_turd.png",
	--on_use = core.item_eat(1)
	on_use          = core.item_eat(0), -- TODO poison mod compatibility
        --_compost        = { -- TODO
        --  amount = amount,
        --  C      = C,
        --  N      = N,
        --},
})

core.register_craftitem("pooper:digestive_agent", {
	description = "Raw Digestive Agent",
	inventory_image = "raw_digestive_agent.png",
	stack_max = 1,
	on_use = core.item_eat(0, "vessels:glass_bottle")
})

core.register_craft({
	output = "pooper:poop_pile",
	recipe = {
		{"", "pooper:poop_turd", ""},
		{"pooper:poop_turd", "pooper:poop_turd", "pooper:poop_turd"}
	}
})

core.register_craft({
	output = "pooper:digestive_agent",
	recipe = {
		{"flowers:waterlily"},
		{"flowers:mushroom_red"},
		{"vessels:glass_bottle"}
	}
})

core.register_craft({
	type = "cooking",
	cooktime = 15,
	output = "pooper:laxative",
	recipe = "pooper:digestive_agent"
})

-- Eating food item increases bowel level
--core.register_on_item_eat(function(hp_change, replace_with_item, itemstack, user, pointed_thing)
--	core.after(5, function()
--		local player = user:get_player_name()
--		player_bowels[player] = player_bowels[player] + FOOD_FILLS_BOWELS_BY
--	end)
--end)

core.register_abm( -- TODO radiant_damage
	{nodenames = {"pooper:poop_pile"},
	interval = 2.0,
	chance = 1,
	-- Suffocate players within a 5 node radius of "poop_pile"
	action = function(pos)
	local objects = core.get_objects_inside_radius(pos, 5) -- TODO parametrize
	-- Poll players for names to pass to set_breath()
	for i, obj in ipairs(objects) do
		--local player = fakelib.get_player_interface(obj)
		if (obj:is_player()) then
		--if player then
			--local playername     = obj:get_player_name()
			local playername = player:get_player_name()
			core.log('pooper suffocating: '..playername)
			--local player         = core.get_player_by_name(playername)
			local breath_initial = player:get_breath()
			local depletion      = breath_initial - 1
			if breath_initial > 1 then
				core.log('pooper suffocating: '..playername..', breath: '..depletion)
				player:set_breath(depletion)
			else
				local health_initial = player:get_hp()
				local health_drain = health_initial - 0.5
				if health_drain > 2 then -- TODO parametrize
					core.log('pooper suffocating: '..playername..', hp: '..health_drain)
					player:set_hp(health_drain, {type='suffocating'})
				end
			end
		end
	end
end,
})

-- Clear player bowels on death
--core.register_on_dieplayer(function(player)
--	-- Such a low number to minimize likelihood of idle dead players pooping
--	player_bowels[player:get_player_name()] = -90000
--end)
--
---- Clear player bowels on respawn
--core.register_on_respawnplayer(function(player)
--	player_bowels[player:get_player_name()] = 0
--end)

core.register_craftitem("pooper:laxative", {
	description = "Laxative",
	inventory_image = "laxative.png",
	stack_max = 1,
	on_use = function(itemstack, user, pointed_thing) -- TODO hunger mod compatibility
		--replace_with_item = "vessels:glass_bottle"
		local playername = user:get_player_name()
		core.do_item_eat(0, "vessels:glass_bottle", itemstack, user, pointed_thing)
		core.chat_send_player(playername, "You suddenly do not feel well...")
		pooper.defecate_soon(playername, math.random(4,8)) -- TODO integrate with hunger mod ?
		itemstack:take_item()
		return "vessels:glass_bottle"
	end
})

--if core.get_modpath('composting') then
--  --composting.add_composting_data('pooper:poop_turd', 1, 1) -- TODO adjust numeric params -- FIXME can't use on composter; eats poop instead
--  composting.add_composting_data('pooper:poop_pile', 4, 1) -- TODO adjust numeric params
--end
