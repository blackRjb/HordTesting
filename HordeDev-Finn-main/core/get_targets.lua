local get_targets = {}

local debug_mode = false
local last_target_switch_time = 0
local current_target_id = nil
local current_target_priority = 0
local TARGET_SWITCH_COOLDOWN = 1.0  -- 1 second cooldown

local priority_map = {
    Boss = 8,
    HellSeeker = 7,
    Champion = 6,
    Membrane = 5,
    Mass = 4,
    Spire = 3,
    Elite = 2,
    Monster = 1
}

local target_types = {"Boss", "HellSeeker", "Champion", "Membrane", "Mass", "Spire", "Elite", "Monster"}

-- Cache for actor types to reduce repeated calculations
local actor_type_cache = setmetatable({}, {__mode = "k"})  -- Weak keys to allow garbage collection

-- Weight factors for target selection
local PRIORITY_WEIGHT = 1000
local HEALTH_WEIGHT = 1
local DISTANCE_WEIGHT = 10  -- Adjust this to change the importance of distance

function get_targets.set_debug_mode(mode)
    debug_mode = mode
end

function get_targets.set_priority(target_type, priority)
    if priority_map[target_type] then
        priority_map[target_type] = priority
    end
end

function get_targets.is_valid_enemy(actor)
    local name = actor:get_skin_name()
    
    if name == "BSK_Soulspire" then
        return actor:get_current_health() > 0
    end

    return actor:get_current_health() > 0 and
           actor:is_enemy() and
           not actor:is_untargetable() and
           not actor:is_basic_particle()
end

function get_targets.get_target_type(actor)
    if actor_type_cache[actor] then
        return actor_type_cache[actor]
    end

    local name = actor:get_skin_name()
    local target_type
    if actor:is_boss() then
        target_type = "Boss"
    elseif name:match("^BSK_HellSeeker") then
        target_type = "HellSeeker"
    elseif actor:is_champion() then
        target_type = "Champion"
    elseif name == "MarkerLocation_BSK_Occupied" then
        target_type = "Membrane"
    elseif name == "BSK_Structure_BonusAether" then
        target_type = "Mass"
    elseif name == "BSK_Soulspire" then
        target_type = "Spire"
    elseif actor:is_elite() then
        target_type = "Elite"
    else
        target_type = "Monster"
    end

    actor_type_cache[actor] = target_type
    return target_type
end

function get_targets.calculate_score(priority, health, distance)
    return priority * PRIORITY_WEIGHT + health * HEALTH_WEIGHT - math.sqrt(distance) * DISTANCE_WEIGHT
end

function get_targets.select_target(source, dist)
    if not source then
        console.print("Error: Invalid source provided to select_target")
        return nil
    end

    local current_time = get_time_since_inject()
    local dist_squared = dist * dist
    
    -- Check if we're still in cooldown and if the current target is still valid
    if current_target_id and current_time - last_target_switch_time < TARGET_SWITCH_COOLDOWN then
        for _, actor in pairs(actors_manager.get_enemy_actors()) do
            if actor:get_id() == current_target_id and 
               get_targets.is_valid_enemy(actor) and 
               source:squared_dist_to_ignore_z(actor:get_position()) <= dist_squared then
                return actor
            end
        end
    end

    local target_counts = {}
    for _, t in ipairs(target_types) do
        target_counts[t] = 0
    end

    local all_target_info = debug_mode and {} or nil
    local best_target, best_score = nil, -math.huge

    for _, actor in pairs(actors_manager.get_enemy_actors()) do
        if get_targets.is_valid_enemy(actor) then
            local distance_squared = source:squared_dist_to_ignore_z(actor:get_position())

            if distance_squared <= dist_squared and not evade.is_dangerous_position(actor:get_position()) then
                local target_type = get_targets.get_target_type(actor)

                target_counts[target_type] = target_counts[target_type] + 1

                local priority = priority_map[target_type]
                local health = actor:get_current_health()
                local score = get_targets.calculate_score(priority, health, distance_squared)

                if score > best_score then
                    best_target = actor
                    best_score = score
                end

                if debug_mode then
                    table.insert(all_target_info, {
                        name = actor:get_skin_name(),
                        id = actor:get_id(),
                        type_id = actor:get_type_id(),
                        type = target_type,
                        health = health,
                        distance = math.sqrt(distance_squared),
                        score = score
                    })
                end
            end
        end
    end

    if best_target and (best_target:get_id() ~= current_target_id or best_score > current_target_priority) then
        last_target_switch_time = current_time
        current_target_id = best_target:get_id()
        current_target_priority = best_score
    end

    if debug_mode then
        console.print("All targets (" .. #all_target_info .. "):")
        table.sort(all_target_info, function(a, b) return a.score > b.score end)
        for _, info in ipairs(all_target_info) do
            console.print(string.format("  Name: %s, ID: %d, Type: %s, Health: %.2f, Distance: %.2f, Score: %.2f", 
                          info.name, info.id, info.type, info.health, info.distance, info.score))
        end
        console.print("Target counts:")
        for _, t in ipairs(target_types) do
            console.print("  " .. t .. ": " .. target_counts[t])
        end
        if best_target then
            local best_type = get_targets.get_target_type(best_target)
            console.print(string.format("Selected target: %s (ID: %d, Type: %s, Health: %.2f, Distance: %.2f, Score: %.2f)",
                          best_target:get_skin_name(),
                          best_target:get_id(),
                          best_type,
                          best_target:get_current_health(),
                          math.sqrt(source:squared_dist_to_ignore_z(best_target:get_position())),
                          best_score))
        else
            console.print("No target selected")
        end
    end

    return best_target
end

return get_targets