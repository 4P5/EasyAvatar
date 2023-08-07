vanilla_model.PLAYER:setVisible(false)

--------------- Variables
local pages = {}

local avatar_animations = {}
if avatar:getNBT().animations then
    for i, data in ipairs(avatar:getNBT().animations) do
    avatar_animations[i] = animations[data.mdl][data.name]
    end
end

local soundboard = {}
for i, sound in pairs(sounds:getCustomSounds()) do
    soundboard[i] = sounds[sound]
end

--------------- Pings
local function parsePath(path) -- we can't send ModelParts over pings, so we reconstruct them from a string path.
    local part = models
    for name in path:gmatch("([^%.]+)") do
        part = part[name]
    end
    return part
end

function pings.toggleParts(name, parts, value)
    for _, path in pairs(parts) do
        local part = parsePath(path)
        part:setVisible(value)
        for _ = 1, 5 do
            particles["spit"]:pos(part:partToWorldMatrix():apply()):scale(0.5):gravity(0):lifetime(math.random(10,20)):spawn()
        end
    end
    if not player:isLoaded() then return end
    sounds["item.armor.equip_generic"]:pos(player:getPos()):volume(0.7):pitch(0.8):subtitle(name .. (value and " equipped" or " unequipped")):play()
end

-- local function syncParts(paths) -- some weird stuff is going on with pings not running in the right order. This fixes that for now.
--     for path, value in pairs(paths) do
--         local part = parsePath(path)
--         part:setVisible(value)
--     end
-- end
-- function pings.syncParts(paths)
--     if host:isHost() then return end
--     syncParts(paths)
-- end

function pings.playAnimation(animation_index)
    local animation = avatar_animations[animation_index]
    animation:restart()
end
 
function pings.toggleAnimation(animation_index, toggle)
    local animation = avatar_animations[animation_index]
    animation:setPlaying(toggle)
end

function pings.playSound(id, state)
    if state then
        soundboard[id]:play()
        events.RENDER:register(function (delta)
            soundboard[id]:pos(player:getPos(delta))
            if not soundboard[id]:isPlaying() then
                events.RENDER:remove("sound_"..id)
                if host:isHost() then
                    pages.soundboard:getAction(id):setToggled(false)
                end
            end
        end, "sound_"..id)
    else
        soundboard[id]:stop()
        events.RENDER:remove("sound_"..id)
    end
end

if not host:isHost() then return end --------------- Host-only past this point
--------------- Pages
pages = {
    main = action_wheel:newPage(),
}
action_wheel:setPage(pages.main)
function action_wheel:rightClick()
    action_wheel:setPage(pages.main)
end

--------------- Auto Accessories
local accessories = {}

local function addPart(part)
    local function chooseItem(accessory_id)
        local valid_item, item_id = pcall(world.newItem, string.lower(accessory_id)) -- checks if the group name itself is a valid item.
        if valid_item then return item_id, nil end
        local valid_item, item_id = pcall(world.newItem, string.lower(accessory_id:gsub("^%w+_", ""))) -- checks if foo_bar_baz ⇒ bar_baz is a valid item.
        if valid_item then return item_id, accessory_id:gsub("_.*", "") end
    end
    local function getFullPath(part)
        local path = part:getName()
        while part:getParent() and part:getParent():getName() ~= "models" do
            part = part:getParent()
            path = part:getName() .. "." .. path
        end
        return path
    end

    local accessory_id = part:getName():gsub("^A_", ""):gsub("%d+$", "") -- remove initial A_ and trailing numbers.
    if not accessories[accessory_id] then -- if this is the first time we've iterated a part of this accessory, creates a new entry.
        local action_item, modified_title = chooseItem(accessory_id)
        local action_title = modified_title or accessory_id
        accessories[accessory_id] = { title = action_title, item = action_item, parts = {}, paths = {} }
    end
    table.insert(accessories[accessory_id].parts, part)
    table.insert(accessories[accessory_id].paths, getFullPath(part))
end

local function traverseModels(part) -- recursively iterates through all model parts to find accessories.
    for _, part in pairs(part:getChildren()) do
        local name = part:getName()
        if name:sub(1, 2) == "A_" then
            addPart(part)
        end
        traverseModels(part)
    end
end
traverseModels(models) -- populates the `accessories` table with parts starting with `A_`.

if next(accessories) then
    -- local active_accessories = config:load("accessories") or {}
    -- if next(active_accessories) then
    --     syncParts(active_accessories)
    --     pings.syncParts(active_accessories)
    -- end

    pages.accessories = action_wheel:newPage()
    pages.main:newAction():title("Accessories"):item("leather_chestplate"):onLeftClick(function() action_wheel:setPage(pages.accessories) end)
    for _, accessory in pairs(accessories) do
        local function getOverallVisibility(parts) -- returns 0–1 based on how many parts are visible.
            local percent_visible = 0
            for _, part in pairs(parts) do
                percent_visible = percent_visible + (part:getVisible() and 1 or 0)
            end
            percent_visible = percent_visible / #parts
            return percent_visible
        end

        local action = pages.accessories:newAction()
        action:item(accessory.item)
        action:title("Toggle " .. accessory.title)
        accessory.default_visibility = getOverallVisibility(accessory.parts) > 0.5
        action:setToggled(accessory.default_visibility) -- if most of the parts are visible, start toggled on.
        action:onToggle(function(val)
            pings.toggleParts(accessory.title, accessory.paths, val)
            -- if val == accessory.default_visibility then
                -- for _, path in pairs(accessory.paths) do
                --     active_accessories[path] = nil
                -- end
            -- else
                -- for _, path in pairs(accessory.paths) do
                --     active_accessories[path] = val
                -- end
            -- end
            -- config:save("accessories", active_accessories)
        end)
    end
end

--------------- Auto Animations
if next(avatar_animations) then
    pages.animations = action_wheel:newPage()
    pages.main:newAction():title("Animations"):item("armor_stand"):onLeftClick(function() action_wheel:setPage(pages.animations) end)
    for animation_index, animation in ipairs(avatar_animations) do
        local animation_name = animation["name"]
        local action_type, action_item, action_name = animation_name:match('([^/]+)/([^/]+)/([^/]+)') -- split the name into type, item, and name, separated by slashes.
        if action_type == "action" then
            local action = pages.animations:newAction()
            action:title(action_name)
            action:item(action_item)
            action:onLeftClick(function()
                pings.playAnimation(animation_index)
            end)
        elseif action_type == "toggle" then
            local action = pages.animations:newAction()
            action:title(action_name)
            action:item(action_item)
            action:onToggle(function()
                pings.toggleAnimation(animation_index, true)
            end)
            action:onUntoggle(function()
                pings.toggleAnimation(animation_index, false)
            end)
        end
    end
end

--------------- Soundboard
if next(soundboard) then
    pages.soundboard = action_wheel:newPage()
    pages.main:newAction():title("Soundboard"):item("note_block"):onLeftClick(function() action_wheel:setPage(pages.soundboard) end)
    for i, sound in pairs(soundboard) do
        local action = pages.soundboard:newAction(i)
        action:title(i)
        action:item("note_block")
        action:onToggle(function(state)
            pings.playSound(i, state)
        end)
    end
end