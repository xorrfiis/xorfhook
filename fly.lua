-- Rivals-Compatible Fly Script for Xorfhook
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

-- Get camera direction
local function getCameraDirection()
    local camera = Workspace.CurrentCamera
    return camera.CFrame.LookVector, camera.CFrame.RightVector, camera.CFrame.UpVector
end

-- Start flying
local function startFlying()
    if flying then return end
    
    local character = lp.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not hrp then return end
    
    flying = true
    
    -- Disable gravity and collisions for flying
    local originalGravity = humanoid.JumpPower
    humanoid.PlatformStand = true
    humanoid.AutoRotate = false
    
    -- Create body movers for smooth movement
    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.P = 9e4
    bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.CFrame = hrp.CFrame
    bodyGyro.Parent = hrp
    
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bodyVelocity.Parent = hrp
    
    -- Fly loop
    flyConnection = RunService.RenderStepped:Connect(function()
        if not flying or not getgenv().FlyEnabled then
            return
        end
        
        local character = lp.Character
        if not character then
            stopFlying()
            return
        end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        local look, right, up = getCameraDirection()
        local speed = getgenv().FlySpeed or 50
        
        local moveDirection = Vector3.new(0, 0, 0)
        
        -- Calculate movement based on keys
        if keys.W then
            moveDirection = moveDirection + look
        end
        if keys.S then
            moveDirection = moveDirection - look
        end
        if keys.A then
            moveDirection = moveDirection - right
        end
        if keys.D then
            moveDirection = moveDirection + right
        end
        if keys.Space then
            moveDirection = moveDirection + up
        end
        if keys.LeftShift then
            moveDirection = moveDirection - up
        end
        
        -- Apply velocity
        if moveDirection.Magnitude > 0 then
            bodyVelocity.Velocity = moveDirection.Unit * speed
        else
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
        
        -- Update rotation
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
            -- Remove body movers
            for _, child in pairs(hrp:GetChildren()) do
                if child:IsA("BodyGyro") or child:IsA("BodyVelocity") then
                    child:Destroy()
                end
            end
        end
        
        if humanoid then
            humanoid.PlatformStand = false
            humanoid.AutoRotate = true
        end
    end
    
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
    if input.KeyCode == Enum.KeyCode[getgenv().FlyKey or "F"] then
        if getgenv().FlyEnabled then
            toggleFly()
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
        task.wait(0.1)
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

print("[Xorfhook] Fly loaded - Press " .. (getgenv().FlyKey or "F") .. " to toggle when enabled")
