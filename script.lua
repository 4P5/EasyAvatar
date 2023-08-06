vanilla_model.PLAYER:setVisible(false)

local avatar_animations = {}
if avatar:getNBT().animations then
    for i, data in ipairs(avatar:getNBT().animations) do
    avatar_animations[i] = animations[data.mdl][data.name]
    end
end

--------------- Pings
function pings.toggleParts(name, parts, val)
    local function parsePath(path) -- we can't send ModelParts over pings, so we reconstruct them from a string path.
        local part = models
        for name in path:gmatch("([^%.]+)") do
            part = part[name]
        end
        return part
    end

    for _, path in pairs(parts) do
        local part = parsePath(path)
        part:setVisible(val)
        for _ = 1, 5 do
            particles["spit"]:pos(part:partToWorldMatrix():apply()):scale(0.5):gravity(0):lifetime(math.random(10,20)):spawn()
        end
    end
    if not player:isLoaded() then return end
    sounds["item.armor.equip_generic"]:pos(player:getPos()):volume(0.7):pitch(0.8):subtitle(name .. (val and " equipped" or " unequipped")):play()
end

function pings.playAnimation(animation_index)
    local animation = avatar_animations[animation_index]
    animation:restart()
end
 
function pings.toggleAnimation(animation_index, toggle)
    local animation = avatar_animations[animation_index]
    animation:setPlaying(toggle)
end




if not host:isHost() then return end
--------------- Pages
local pages = {
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

local function registerAccessories()
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
        action:setToggled(getOverallVisibility(accessory.parts) > 0.5) -- if most of the parts are visible, start toggled on.
        action:onToggle(function(val)
            pings.toggleParts(accessory.title, accessory.paths, val)
        end)
    end
end

if next(accessories) then
    pages.accessories = action_wheel:newPage()
    pages.main:newAction():title("Accessories"):item("leather_chestplate"):onLeftClick(function() action_wheel:setPage(pages.accessories) end)
    registerAccessories()
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
local soundboard = {}
for i, sound in pairs(sounds:getCustomSounds()) do
    soundboard[i] = sound
end

if next(soundboard) then
    pages.soundboard = action_wheel:newPage()
    pages.soundboard:newAction():title("Soundboard"):item("note_block"):onLeftClick(function() action_wheel:setPage(pages.soundboard) end)

end