-- Rivals-Compatible Fly Script for Xorfhook - FIXED VERSION
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local lp = Players.LocalPlayer

-- Settings
getgenv().FlyEnabled = getgenv().FlyEnabled or false
getgenv().FlySpeed = getgenv().FlySpeed or 50
getgenv().FlyKey = getgenv().FlyKey or "F"

-- Fly state
local flying = false
local flyConnection = nil
local keys = {W = false, A = false, S = false, D = false, Space = false, LeftShift = false}
local bodyVelocity = nil
local bodyGyro = nil

-- Get camera direction
local function getCameraDirection()
    local camera = Workspace.CurrentCamera
    return camera.CFrame.LookVector, camera.CFrame.RightVector, camera.CFrame.UpVector
end

-- Start flying
local function startFlying()
    if flying then return end
    
    local character = lp.Character
    if not character then 
        warn("[Xorfhook Fly] No character found")
        return 
    end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not hrp then 
        warn("[Xorfhook Fly] Missing humanoid or HRP")
        return 
    end
    
    -- Check if already flying (body movers exist)
    if hrp:FindFirstChild("XorfhookFlyGyro") or hrp:FindFirstChild("XorfhookFlyVelocity") then
        -- Clean up existing
        for _, child in pairs(hrp:GetChildren()) do
            if child.Name == "XorfhookFlyGyro" or child.Name == "XorfhookFlyVelocity" then
                child:Destroy()
            end
        end
    end
    
    flying = true
    
    -- Create body gyro for rotation
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.Name = "XorfhookFlyGyro"
    bodyGyro.P = 9e4
    bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.CFrame = hrp.CFrame
    bodyGyro.Parent = hrp
    
    -- Create body velocity for movement
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Name = "XorfhookFlyVelocity"
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bodyVelocity.Parent = hrp
    
    -- Set humanoid state
    humanoid.PlatformStand = true
    humanoid.AutoRotate = false
    
    -- Fly loop
    flyConnection = RunService.RenderStepped:Connect(function()
        if not flying or not getgenv().FlyEnabled then
            return
        end
        
        -- Check if character still valid
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
        
        -- Check if body movers still exist (might be destroyed by game)
        if not hrp:FindFirstChild("XorfhookFlyGyro") or not hrp:FindFirstChild("XorfhookFlyVelocity") then
            stopFlying()
            return
        end
        
        local look, right, up = getCameraDirection()
        local speed = getgenv().FlySpeed or 50
        
        local moveDirection = Vector3.new(0, 0, 0)
        
        -- Calculate movement based on keys
        if keys.W then
            moveDirection = moveDirection + Vector3.new(look.X, 0, look.Z).Unit
        end
        if keys.S then
            moveDirection = moveDirection - Vector3.new(look.X, 0, look.Z).Unit
        end
        if keys.A then
            moveDirection = moveDirection - right
        end
        if keys.D then
            moveDirection = moveDirection + right
        end
        if keys.Space then
            moveDirection = moveDirection + Vector3.new(0, 1, 0)
        end
        if keys.LeftShift then
            moveDirection = moveDirection - Vector3.new(0, 1, 0)
        end
        
        -- Normalize and apply velocity
        if moveDirection.Magnitude > 0 then
            bodyVelocity.Velocity = moveDirection.Unit * speed
        else
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
        
        -- Update rotation to match camera
        bodyGyro.CFrame = Workspace.CurrentCamera.CFrame
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
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        
        if hrp then
            -- Remove body movers by name
            for _, child in pairs(hrp:GetChildren()) do
                if child.Name == "XorfhookFlyGyro" or child.Name == "XorfhookFlyVelocity" then
                    child:Destroy()
                end
            end
        end
        
        if humanoid then
            humanoid.PlatformStand = false
            humanoid.AutoRotate = true
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
    
    bodyVelocity = nil
    bodyGyro = nil
    
    print("[Xorfhook] Fly stopped")
end

-- Toggle fly
local function toggleFly()
    if flying then
        stopFlying()
    else
        startFlying()
    end
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Toggle key
    local flyKey = getgenv().FlyKey or "F"
    if input.KeyCode == Enum.KeyCode[flyKey] then
        if getgenv().FlyEnabled then
            toggleFly()
        else
            warn("[Xorfhook Fly] Fly is not enabled in menu!")
        end
    end
    
    -- Movement keys
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

-- Monitor FlyEnabled setting
task.spawn(function()
    while true do
        task.wait(0.5)
        if not getgenv().FlyEnabled and flying then
            stopFlying()
        end
    end
end)

-- Cleanup on character change
lp.CharacterAdded:Connect(function()
    if flying then
        stopFlying()
    end
end)

-- Store functions for external access
getgenv().XorfhookFly = {
    Start = startFlying,
    Stop = stopFlying,
    Toggle = toggleFly,
    IsFlying = function() return flying end
}

print("[Xorfhook] Fly loaded - Press " .. (getgenv().FlyKey or "F") .. " to toggle (must enable in menu first)")
