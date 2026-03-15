-- Custom Crosshair for Xorfhook
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local lp = Players.LocalPlayer

-- Initialize settings
getgenv().CrosshairEnabled = getgenv().CrosshairEnabled or false
getgenv().CrosshairColor = getgenv().CrosshairColor or Color3.fromRGB(255, 255, 255)
getgenv().CrosshairSize = getgenv().CrosshairSize or 10
getgenv().CrosshairThickness = getgenv().CrosshairThickness or 2
getgenv().CrosshairGap = getgenv().CrosshairGap or 4
getgenv().CrosshairDot = getgenv().CrosshairDot or true
getgenv().CrosshairOutline = getgenv().CrosshairOutline or true

-- Drawing objects
local crosshairParts = {}
local connection = nil

-- Safe Drawing creation
local function createDrawing(type)
    if typeof(Drawing) == "table" and typeof(Drawing.new) == "function" then
        local success, result = pcall(Drawing.new, type)
        if success then
            return result
        end
    end
    return nil
end

-- Setup crosshair parts
local function setupCrosshair()
    -- Clean up old parts
    for _, part in pairs(crosshairParts) do
        if part then
            pcall(function() part:Remove() end)
        end
    end
    crosshairParts = {}
    
    -- Create 4 lines (top, bottom, left, right)
    for i = 1, 4 do
        local line = createDrawing("Line")
        if line then
            line.Visible = false
            line.Transparency = 1
            table.insert(crosshairParts, line)
        end
    end
    
    -- Create center dot
    local dot = createDrawing("Circle")
    if dot then
        dot.Visible = false
        dot.Filled = true
        dot.Transparency = 1
        crosshairParts.Dot = dot
    end
    
    -- Create outlines (4 lines + dot)
    if getgenv().CrosshairOutline then
        for i = 1, 4 do
            local outline = createDrawing("Line")
            if outline then
                outline.Visible = false
                outline.Color = Color3.fromRGB(0, 0, 0)
                outline.Transparency = 1
                table.insert(crosshairParts, outline)
            end
        end
        
        local dotOutline = createDrawing("Circle")
        if dotOutline then
            dotOutline.Visible = false
            dotOutline.Filled = true
            dotOutline.Color = Color3.fromRGB(0, 0, 0)
            dotOutline.Transparency = 1
            crosshairParts.DotOutline = dotOutline
        end
    end
end

setupCrosshair()

-- Update crosshair position and style
local function updateCrosshair()
    if not getgenv().CrosshairEnabled then
        for _, part in pairs(crosshairParts) do
            if part then
                part.Visible = false
            end
        end
        return
    end
    
    local screenCenter = UserInputService:GetMouseLocation()
    local size = getgenv().CrosshairSize or 10
    local thickness = getgenv().CrosshairThickness or 2
    local gap = getgenv().CrosshairGap or 4
    local color = getgenv().CrosshairColor or Color3.fromRGB(255, 255, 255)
    local outlineEnabled = getgenv().CrosshairOutline
    local showDot = getgenv().CrosshairDot
    
    -- Calculate positions
    local cx, cy = screenCenter.X, screenCenter.Y
    
    -- Line configurations: {startX, startY, endX, endY}
    local lineConfigs = {
        {cx, cy - gap - size, cx, cy - gap},           -- Top
        {cx, cy + gap, cx, cy + gap + size},           -- Bottom
        {cx - gap - size, cy, cx - gap, cy},           -- Left
        {cx + gap, cy, cx + gap + size, cy}            -- Right
    }
    
    -- Update main lines
    for i = 1, 4 do
        local line = crosshairParts[i]
        if line then
            local config = lineConfigs[i]
            line.Visible = true
            line.From = Vector2.new(config[1], config[2])
            line.To = Vector2.new(config[3], config[4])
            line.Color = color
            line.Thickness = thickness
        end
    end
    
    -- Update outlines (indices 5-8 if they exist)
    if outlineEnabled then
        for i = 5, 8 do
            local outline = crosshairParts[i]
            if outline then
                local config = lineConfigs[i - 4]
                outline.Visible = true
                outline.From = Vector2.new(config[1], config[2])
                outline.To = Vector2.new(config[3], config[4])
                outline.Thickness = thickness + 2
            end
        end
    else
        for i = 5, 8 do
            local outline = crosshairParts[i]
            if outline then
                outline.Visible = false
            end
        end
    end
    
    -- Update center dot
    local dot = crosshairParts.Dot
    local dotOutline = crosshairParts.DotOutline
    
    if showDot and dot then
        dot.Visible = true
        dot.Position = Vector2.new(cx, cy)
        dot.Radius = math.max(thickness, 2)
        dot.Color = color
        
        if outlineEnabled and dotOutline then
            dotOutline.Visible = true
            dotOutline.Position = Vector2.new(cx, cy)
            dotOutline.Radius = dot.Radius + 1
        elseif dotOutline then
            dotOutline.Visible = false
        end
    else
        if dot then dot.Visible = false end
        if dotOutline then dotOutline.Visible = false end
    end
end

-- Main loop
connection = RunService.RenderStepped:Connect(function()
    local success, err = pcall(updateCrosshair)
    if not success then
        warn("[Xorfhook Crosshair] Error: " .. tostring(err))
    end
end)

-- Cleanup
getgenv().XorfhookCrosshairConnection = connection
getgenv().XorfhookCrosshairCleanup = function()
    for _, part in pairs(crosshairParts) do
        if part then
            pcall(function() part:Remove() end)
        end
    end
    if connection then
        connection:Disconnect()
    end
end

print("[Xorfhook] Crosshair loaded")
