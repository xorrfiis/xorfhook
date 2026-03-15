-- prevent double loading
if getgenv().XorfhookLoaded then
    return
end

getgenv().XorfhookLoaded = true

local loaderURL = "https://raw.githubusercontent.com/xorrfiis/xorfhook/main/loader.luau"
local guiURL = "https://raw.githubusercontent.com/xorrfiis/xorfhook/main/gui.luau"

-- Universal queue_on_teleport with proper error handling
local function setupQueueOnTeleport()
    local queued = false
    
    -- Try various executor implementations
    if typeof(queue_on_teleport) == "function" then
        local success, err = pcall(function()
            queue_on_teleport('loadstring(game:HttpGet("' .. loaderURL .. '"))()')
        end)
        if success then queued = true end
    end
    
    if not queued and typeof(syn) == "table" and typeof(syn.queue_on_teleport) == "function" then
        local success, err = pcall(function()
            syn.queue_on_teleport('loadstring(game:HttpGet("' .. loaderURL .. '"))()')
        end)
        if success then queued = true end
    end
    
    if not queued and typeof(fluxus) == "table" and typeof(fluxus.queue_on_teleport) == "function" then
        local success, err = pcall(function()
            fluxus.queue_on_teleport('loadstring(game:HttpGet("' .. loaderURL .. '"))()')
        end)
        if success then queued = true end
    end
    
    if not queued and typeof(KRNL) == "table" and typeof(KRNL.queue_on_teleport) == "function" then
        local success, err = pcall(function()
            KRNL.queue_on_teleport('loadstring(game:HttpGet("' .. loaderURL .. '"))()')
        end)
        if success then queued = true end
    end
    
    -- YUB-X specific
    if not queued and typeof(YUBX) == "table" and typeof(YUBX.queue_on_teleport) == "function" then
        local success, err = pcall(function()
            YUBX.queue_on_teleport('loadstring(game:HttpGet("' .. loaderURL .. '"))()')
        end)
        if success then queued = true end
    end
end

-- Safe wrapper for loadstring + HttpGet with proper yielding
local function safeLoad(url)
    local success, result = pcall(function()
        local httpGetSuccess, content = pcall(game.HttpGet, game, url)
        if not httpGetSuccess then
            -- Try alternate method for some executors
            httpGetSuccess, content = pcall(function()
                return game:HttpGet(url, true)
            end)
        end
        
        if httpGetSuccess and content then
            local loadSuccess, loaded = pcall(loadstring, content)
            if loadSuccess and typeof(loaded) == "function" then
                return loaded
            else
                error("Failed to loadstring: " .. tostring(loaded))
            end
        else
            error("HttpGet failed: " .. tostring(content))
        end
    end)
    
    if success then
        return result
    else
        warn("[Xorfhook] Failed to load from URL: " .. tostring(result))
        return nil
    end
end

-- Setup teleport queue (non-blocking)
setupQueueOnTeleport()

-- Load GUI with proper yielding for advanced executors
task.spawn(function()
    local guiScript = safeLoad(guiURL)
    if guiScript then
        local execSuccess, execErr = pcall(guiScript)
        if not execSuccess then
            warn("[Xorfhook] GUI execution error: " .. tostring(execErr))
        end
    end
end)
