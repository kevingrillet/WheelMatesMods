local ModName = "CheckListDiagnostics"
local previous_customization_tags = nil

--- Writes one complete diagnostic console line.
local function log(message)
    print(string.format("[%s] %s\n", ModName, message))
end

--- Returns true only for a reflected Unreal object that can still be inspected.
local function is_valid(object)
    return object ~= nil and object.IsValid ~= nil and object:IsValid()
end

--- Extracts values held by UE4SS remote-property wrappers.
local function unwrap(value)
    local ok, unwrapped = pcall(function()
        return value:get()
    end)
    return ok and unwrapped or value
end

--- Iterates either a UE4SS container or a plain Lua table returned by FindAllOf.
local function for_each_object(objects, callback)
    if type(objects) == "table" then
        for _, object in pairs(objects) do
            callback(unwrap(object))
        end
    elseif objects ~= nil and objects.ForEach ~= nil then
        objects:ForEach(function(_, object)
            callback(unwrap(object))
        end)
    end
end

--- Converts a reflected or Lua value to safe diagnostic text.
local function value_text(value)
    local ok, text = pcall(function()
        return value:ToString()
    end)
    return ok and tostring(text) or tostring(value)
end

--- Reports candidate collectible runtime classes and their reflected properties.
local function report_discovery()
    local matches = {}
    for_each_object(FindAllOf("Actor"), function(actor)
        if not is_valid(actor) then
            return
        end
        local short_name = string.lower(actor:GetClass():GetFName():ToString())
        if
            string.find(short_name, "collectable", 1, true)
            or string.find(short_name, "collectible", 1, true)
            or string.find(short_name, "scannable", 1, true)
            or string.find(short_name, "neuro", 1, true)
        then
            local class = actor:GetClass():GetFullName()
            matches[class] = matches[class] or { count = 0, actor = actor }
            matches[class].count = matches[class].count + 1
        end
    end)
    local classes = {}
    for class in pairs(matches) do
        table.insert(classes, class)
    end
    table.sort(classes)
    log("Collectible actor discovery (read-only)")
    for _, class in ipairs(classes) do
        local entry, properties = matches[class], {}
        entry.actor:GetClass():ForEachProperty(function(property)
            table.insert(properties, property:GetFName():ToString())
        end)
        table.sort(properties)
        log(string.format("Candidate | %d instance(s) | Class=%s", entry.count, class))
        log("Properties | " .. table.concat(properties, ", "))
    end
    log(string.format("Discovery complete: %d candidate class(es).", #classes))
end

--- Reports loaded Gear actors and compares saved customization tags with the previous probe.
local function report_gears_and_unlocks()
    log("Gear and customization probe (read-only)")
    local count = 0
    for_each_object(FindAllOf("Actor"), function(actor)
        if is_valid(actor) and string.find(string.lower(actor:GetFullName()), "bp_collectable_gear", 1, true) then
            local location = actor:K2_GetActorLocation()
            count = count + 1
            log(
                string.format(
                    "Gear candidate | %s | {X=%.3f, Y=%.3f, Z=%.3f}",
                    actor:GetFullName(),
                    location.X,
                    location.Y,
                    location.Z
                )
            )
        end
    end)
    log(string.format("Gear candidates loaded: %d.", count))
    for_each_object(FindAllOf("VehicleSaveGame"), function(save)
        if not is_valid(save) then
            return
        end
        local current = {}
        local unlocks = save.UnlockedCustomizationOptions
        local tags = unlocks and unlocks.GameplayTags
        if tags ~= nil and tags.ForEach ~= nil then
            tags:ForEach(function(_, tag)
                local entry = unwrap(tag)
                current[value_text(entry.TagName)] = true
            end)
        end
        local total, added = 0, 0
        for tag in pairs(current) do
            total = total + 1
            if previous_customization_tags ~= nil and not previous_customization_tags[tag] then
                log("New customization unlock | " .. tag)
                added = added + 1
            end
        end
        log(string.format("Customization unlock tags saved: %d.", total))
        if previous_customization_tags == nil then
            log("Customization snapshot saved; probe again after collecting a Gear to compare.")
        elseif added == 0 then
            log("No new customization tag since the previous Gear probe.")
        end
        previous_customization_tags = current
    end)
    log("Gear and customization probe complete.")
end

RegisterKeyBind(Key.NUM_ONE, { ModifierKey.CONTROL }, function()
    ExecuteInGameThread(report_discovery)
end)
RegisterKeyBind(Key.NUM_TWO, { ModifierKey.CONTROL }, function()
    ExecuteInGameThread(report_gears_and_unlocks)
end)

log("Loaded (disabled by default). Ctrl+NumPad1: collectible discovery. Ctrl+NumPad2: Gear/customization probe.")
