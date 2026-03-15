-- Rivals Fly Script using CFrame (Bypasses body mover deletion)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local lp = Players.LocalPlayer

-- Settings
getgenv().FlyEnabled = getgenv().FlyEnabled or false
getgenv().FlySpeed = getgenv().FlySpeed or 50
getgenv().FlyKey = getgenv().FlyKey or "F"

-- State
local flying = false
local flyConnection = nil
local keys = {W = false, A = false, S = false, D = false, Space = false, LeftShift = false}

-- Start flying
local function startFlying()
    if flying then return end
    
    local character = lp.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    flying = true
    
    -- Store original settings
    local originalCFrame = hrp.CFrame
    
    flyConnection = RunService.RenderStepped:Connect(function()
        if not flying or not getgenv().FlyEnabled then return end
        
        local character = lp.Character
        if not character then 
            stopFlying()
            return 
        end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then 
            stopFlying()
            return 
        end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = true
            humanoid.AutoRotate = false
        end
        
        -- Get camera direction
        local camera = Workspace.CurrentCamera
        local look = camera.CFrame.LookVector
        local right = camera.CFrame.RightVector
        local up = Vector3.new(0, 1, 0)
        
        local speed = getgenv().FlySpeed or 50
        local moveDir = Vector3.new(0, 0, 0)
        
        if keys.W then moveDir = moveDir + Vector3.new(look.X, 0, look.Z).Unit end
        if keys.S then moveDir = moveDir - Vector3.new(look.X, 0, look.Z).Unit end
        if keys.A then moveDir = moveDir - right end
        if keys.D then moveDir = moveDir + right end
        if keys.Space then moveDir = moveDir + up end
        if keys.LeftShift then moveDir = moveDir - up end
        
        if moveDir.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + (moveDir.Unit * speed * 0.016)
        end
        
        -- Prevent falling
        hrp.Velocity = Vector3.new(0, 0, 0)
        hrp.RotVelocity = Vector3.new(0, 0, 0)
    end)
    
    print("[Xorfhook] Fly started")
end

-- Stop flying
local function stopFlying()
    if not flying then return end
    
    flying = false
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    
    local character = lp.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
            humanoid.AutoRotate = true
        end
    end
    
    print("[Xorfhook] Fly stopped")
end

-- Toggle
local function toggleFly()
    if flying then stopFlying() else startFlying() end
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode[getgenv().FlyKey or "F"] then
        if getgenv().FlyEnabled then toggleFly() end
    end
    
    if input.KeyCode == Enum.KeyCode.W then keys.W = true end
    if input.KeyCode == Enum.KeyCode.A then keys.A = true end
    if input.KeyCode == Enum.KeyCode.S then keys.S = true end
    if input.KeyCode == Enum.KeyCode.D then keys.D = true end
    if input.KeyCode == Enum.KeyCode.Space then keys.Space = true end
    if input.KeyCode == Enum.KeyCode.LeftShift then keys.LeftShift = true end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then keys.W = false end
    if input.KeyCode == Enum.KeyCode.A then keys.A = false end
    if input.KeyCode == Enum.KeyCode.S then keys.S = false end
    if input.KeyCode == Enum.KeyCode.D then keys.D = false end
    if input.KeyCode == Enum.KeyCode.Space then keys.Space = false end
    if input.KeyCode == Enum.KeyCode.LeftShift then keys.LeftShift = false end
end)

-- Monitor setting
task.spawn(function()
    while true do
        task.wait(0.5)
        if not getgenv().FlyEnabled and flying then
            stopFlying()
        end
    end
end)

lp.CharacterAdded:Connect(function()
    if flying then stopFlying() end
end)

getgenv().XorfhookFly = {
    Start = startFlying,
    Stop = stopFlying,
    Toggle = toggleFly,
    IsFlying = function() return flying end
}

print("[Xorfhook] Fly loaded")
