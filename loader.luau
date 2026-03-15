-- prevent double loading
if getgenv().XorfhookLoaded then
    return
end

getgenv().XorfhookLoaded = true

local loaderURL = "https://raw.githubusercontent.com/xorrfiis/xorfhook/main/loader.luau"
local guiURL = "https://raw.githubusercontent.com/xorrfiis/xorfhook/main/gui.luau"

-- queue script for teleport (matchmaking)
if queue_on_teleport then
    queue_on_teleport('loadstring(game:HttpGet("' .. loaderURL .. '"))()')
elseif syn and syn.queue_on_teleport then
    syn.queue_on_teleport('loadstring(game:HttpGet("' .. loaderURL .. '"))()')
end

-- load GUI
loadstring(game:HttpGet(guiURL))()
