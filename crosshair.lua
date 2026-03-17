-- Crosshair for YUB-X - ScreenGui Version (More Reliable)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Settings
getgenv().CrosshairEnabled = getgenv().CrosshairEnabled or false
getgenv().CrosshairColor = getgenv().CrosshairColor or Color3.fromRGB(255, 255, 255)
getgenv().CrosshairSize = getgenv().CrosshairSize or 10
getgenv().CrosshairThickness = getgenv().CrosshairThickness or 2
getgenv().CrosshairGap = getgenv().CrosshairGap or 4
getgenv().CrosshairDot = getgenv().CrosshairDot or true
getgenv().CrosshairOutline = getgenv().CrosshairOutline or true

-- GUI elements
local ScreenGui = nil
local Lines = {}
local Dot = nil
local Connection = nil

-- Create crosshair
local function CreateCrosshair()
    -- Clean up old
    if ScreenGui then
        pcall(function() ScreenGui:Destroy() end)
    end
    
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "XorfhookCrosshair"
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    
    local size = getgenv().CrosshairSize or 10
    local thickness = getgenv().CrosshairThickness or 2
    local gap = getgenv().CrosshairGap or 4
    local color = getgenv().CrosshairColor or Color3.fromRGB(255, 255, 255)
    local outline = getgenv().CrosshairOutline
    
    -- Helper to create line
    local function CreateLine(name, position, size)
        local frame = Instance.new("Frame")
        frame.Name = name
        frame.BackgroundColor3 = color
        frame.BorderSizePixel = 0
        frame.Size = size
        frame.Position = position
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.Parent = ScreenGui
        
        if outline then
            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(0, 0, 0)
            stroke.Thickness = 1
            stroke.Parent = frame
        end
        
        return frame
    end
    
    Lines = {}
    
    -- Top line
    table.insert(Lines, CreateLine("Top", 
        UDim2.new(0.5, 0, 0.5, -gap - size/2), 
        UDim2.new(0, thickness, 0, size)))
    
    -- Bottom line
    table.insert(Lines, CreateLine("Bottom", 
        UDim2.new(0.5, 0, 0.5, gap + size/2), 
        UDim2.new(0, thickness, 0, size)))
    
    -- Left line
    table.insert(Lines, CreateLine("Left", 
        UDim2.new(0.5, -gap - size/2, 0.5, 0), 
        UDim2.new(0, size, 0, thickness)))
    
    -- Right line
    table.insert(Lines, CreateLine("Right", 
        UDim2.new(0.5, gap + size/2, 0.5, 0), 
        UDim2.new(0, size, 0, thickness)))
    
    -- Center dot
    if getgenv().CrosshairDot then
        Dot = Instance.new("Frame")
        Dot.Name = "Dot"
        Dot.BackgroundColor3 = color
        Dot.BorderSizePixel = 0
        Dot.Size = UDim2.new(0, math.max(thickness, 3), 0, math.max(thickness, 3))
        Dot.Position = UDim2.new(0.5, 0, 0.5, 0)
        Dot.AnchorPoint = Vector2.new(0.5, 0.5)
        Dot.Parent = ScreenGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = Dot
        
        if outline then
            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(0, 0, 0)
            stroke.Thickness = 1
            stroke.Parent = Dot
        end
    end
end

-- Update crosshair
local function UpdateCrosshair()
    if not getgenv().CrosshairEnabled then
        if ScreenGui then
            ScreenGui.Enabled = false
        end
        return
    end
    
    if not ScreenGui or not ScreenGui.Parent then
        CreateCrosshair()
    end
    
    if ScreenGui then
        ScreenGui.Enabled = true
        
        -- Update color
        local color = getgenv().CrosshairColor or Color3.fromRGB(255, 255, 255)
        for _, line in pairs(Lines) do
            if line then
                line.BackgroundColor3 = color
            end
        end
        if Dot then
            Dot.BackgroundColor3 = color
        end
    end
end

-- Initial creation
CreateCrosshair()

-- Update loop
Connection = RunService.RenderStepped:Connect(function()
    pcall(UpdateCrosshair)
end)

-- Cleanup
getgenv().XorfhookCrosshairConnection = Connection
getgenv().XorfhookCrosshairCleanup = function()
    if ScreenGui then
        pcall(function() ScreenGui:Destroy() end)
    end
    if Connection then
        Connection:Disconnect()
    end
end

print("[Xorfhook] Crosshair loaded (YUB-X)")
