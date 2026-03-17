-- Fly for YUB-X - CFrame Based
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Settings
getgenv().FlyEnabled = getgenv().FlyEnabled or false
getgenv().FlySpeed = getgenv().FlySpeed or 50
getgenv().FlyKey = getgenv().FlyKey or "F"

-- State
local Flying = false
local FlyConnection = nil
local Keys = {W = false, A = false, S = false, D = false, Space = false, LeftShift = false}

-- Start flying
local function StartFlying()
    if Flying then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    Flying = true
    
    FlyConnection = RunService.RenderStepped:Connect(function()
        if not Flying or not getgenv().FlyEnabled then return end
        
        local character = LocalPlayer.Character
        if not character then 
            StopFlying()
            return 
        end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then 
            StopFlying()
            return 
        end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = true
            humanoid.AutoRotate = false
        end
        
        local camera = Workspace.CurrentCamera
        local look = camera.CFrame.LookVector
        local right = camera.CFrame.RightVector
        
        local speed = getgenv().FlySpeed or 50
        local moveDir = Vector3.new(0, 0, 0)
        
        if Keys.W then moveDir = moveDir + Vector3.new(look.X, 0, look.Z).Unit end
        if Keys.S then moveDir = moveDir - Vector3.new(look.X, 0, look.Z).Unit end
        if Keys.A then moveDir = moveDir - right end
        if Keys.D then moveDir = moveDir + right end
        if Keys.Space then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if Keys.LeftShift then moveDir = moveDir - Vector3.new(0, 1, 0) end
        
        if moveDir.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + (moveDir.Unit * speed * 0.016)
        end
        
        hrp.Velocity = Vector3.new(0, 0, 0)
        hrp.RotVelocity = Vector3.new(0, 0, 0)
    end)
    
    print("[Xorfhook] Fly started")
end

-- Stop flying
local function StopFlying()
    if not Flying then return end
    
    Flying = false
    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end
    
    local character = LocalPlayer.Character
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
local function ToggleFly()
    if Flying then StopFlying() else StartFlying() end
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode[getgenv().FlyKey or "F"] then
        if getgenv().FlyEnabled then ToggleFly() end
    end
    
    if input.KeyCode == Enum.KeyCode.W then Keys.W = true end
    if input.KeyCode == Enum.KeyCode.A then Keys.A = true end
    if input.KeyCode == Enum.KeyCode.S then Keys.S = true end
    if input.KeyCode == Enum.KeyCode.D then Keys.D = true end
    if input.KeyCode == Enum.KeyCode.Space then Keys.Space = true end
    if input.KeyCode == Enum.KeyCode.LeftShift then Keys.LeftShift = true end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then Keys.W = false end
    if input.KeyCode == Enum.KeyCode.A then Keys.A = false end
    if input.KeyCode == Enum.KeyCode.S then Keys.S = false end
    if input.KeyCode == Enum.KeyCode.D then Keys.D = false end
    if input.KeyCode == Enum.KeyCode.Space then Keys.Space = false end
    if input.KeyCode == Enum.KeyCode.LeftShift then Keys.LeftShift = false end
end)

-- Monitor setting
task.spawn(function()
    while true do
        task.wait(0.5)
        if not getgenv().FlyEnabled and Flying then
            StopFlying()
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    if Flying then StopFlying() end
end)

-- Expose functions
getgenv().XorfhookFly = {
    Start = StartFlying,
    Stop = StopFlying,
    Toggle = ToggleFly,
    IsFlying = function() return Flying end
}

print("[Xorfhook] Fly loaded (YUB-X) - Press " .. (getgenv().FlyKey or "F") .. " to toggle")
