-- Simple Crosshair using ScreenGui (More reliable than Drawing)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer

-- Settings
getgenv().CrosshairEnabled = getgenv().CrosshairEnabled or false
getgenv().CrosshairColor = getgenv().CrosshairColor or Color3.fromRGB(255, 255, 255)
getgenv().CrosshairSize = getgenv().CrosshairSize or 10
getgenv().CrosshairThickness = getgenv().CrosshairThickness or 2
getgenv().CrosshairGap = getgenv().CrosshairGap or 4
getgenv().CrosshairDot = getgenv().CrosshairDot or true
getgenv().CrosshairOutline = getgenv().CrosshairOutline or true

-- GUI elements
local screenGui = nil
local lines = {}
local dot = nil

-- Create crosshair using Frame GUI (works in all executors)
local function createCrosshair()
    -- Clean up old
    if screenGui then
        pcall(function() screenGui:Destroy() end)
    end
    
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "XorfhookCrosshair"
    screenGui.Parent = lp:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    
    local size = getgenv().CrosshairSize or 10
    local thickness = getgenv().CrosshairThickness or 2
    local gap = getgenv().CrosshairGap or 4
    local color = getgenv().CrosshairColor or Color3.fromRGB(255, 255, 255)
    local outline = getgenv().CrosshairOutline
    
    -- Create lines
    lines = {}
    
    local function createLine(name, pos, size)
        local frame = Instance.new("Frame")
        frame.Name = name
        frame.BackgroundColor3 = color
        frame.BorderSizePixel = 0
        frame.Size = size
        frame.Position = pos
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.Parent = screenGui
        
        if outline then
            frame.BorderSizePixel = 1
            frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        end
        
        return frame
    end
    
    -- Top line
    table.insert(lines, createLine("Top", 
        UDim2.new(0.5, 0, 0.5, -gap - size/2), 
        UDim2.new(0, thickness, 0, size)))
    
    -- Bottom line
    table.insert(lines, createLine("Bottom", 
        UDim2.new(0.5, 0, 0.5, gap + size/2), 
        UDim2.new(0, thickness, 0, size)))
    
    -- Left line
    table.insert(lines, createLine("Left", 
        UDim2.new(0.5, -gap - size/2, 0.5, 0), 
        UDim2.new(0, size, 0, thickness)))
    
    -- Right line
    table.insert(lines, createLine("Right", 
        UDim2.new(0.5, gap + size/2, 0.5, 0), 
        UDim2.new(0, size, 0, thickness)))
    
    -- Center dot
    if getgenv().CrosshairDot then
        dot = Instance.new("Frame")
        dot.Name = "Dot"
        dot.BackgroundColor3 = color
        dot.BorderSizePixel = 0
        dot.Size = UDim2.new(0, math.max(thickness, 3), 0, math.max(thickness, 3))
        dot.Position = UDim2.new(0.5, 0, 0.5, 0)
        dot.AnchorPoint = Vector2.new(0.5, 0.5)
        dot.Parent = screenGui
        
        -- Make it circular
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = dot
        
        if outline then
            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(0, 0, 0)
            stroke.Thickness = 1
            stroke.Parent = dot
        end
    end
end

-- Update crosshair
local function updateCrosshair()
    if not getgenv().CrosshairEnabled then
        if screenGui then
            screenGui.Enabled = false
        end
        return
    end
    
    if not screenGui or not screenGui.Parent then
        createCrosshair()
    end
    
    if screenGui then
        screenGui.Enabled = true
        
        -- Update color if changed
        local color = getgenv().CrosshairColor or Color3.fromRGB(255, 255, 255)
        for _, line in pairs(lines) do
            if line then
                line.BackgroundColor3 = color
            end
        end
        if dot then
            dot.BackgroundColor3 = color
        end
    end
end

-- Initial creation
createCrosshair()

-- Update loop
local connection = RunService.RenderStepped:Connect(function()
    pcall(updateCrosshair)
end)

-- Cleanup
getgenv().XorfhookCrosshairConnection = connection
getgenv().XorfhookCrosshairCleanup = function()
    if screenGui then
        pcall(function() screenGui:Destroy() end)
    end
    if connection then
        connection:Disconnect()
    end
end

print("[Xorfhook] Crosshair loaded (GUI version)")
