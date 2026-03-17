local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Settings
getgenv().AimbotEnabled = getgenv().AimbotEnabled or false
getgenv().AimbotSmoothness = getgenv().AimbotSmoothness or 1
getgenv().AimbotFOV = getgenv().AimbotFOV or 180
getgenv().AimbotTeamCheck = getgenv().AimbotTeamCheck ~= false
getgenv().AimbotWallCheck = getgenv().AimbotWallCheck ~= false
getgenv().AimbotHitPart = getgenv().AimbotHitPart or "Head"
getgenv().AimbotShowFOV = getgenv().AimbotShowFOV or false
getgenv().TriggerbotEnabled = getgenv().TriggerbotEnabled or false
getgenv().TriggerbotDelay = getgenv().TriggerbotDelay or 0

print("[Xorfhook] Aimbot loading...")

-- Drawing setup
local FOVCircle = nil
local function SetupFOVCircle()
    if FOVCircle then return end
    if not Drawing then return end
    
    local success, result = pcall(function()
        local circle = Drawing.new("Circle")
        circle.Visible = false
        circle.Thickness = 1.5
        circle.Color = Color3.fromRGB(255, 50, 50)
        circle.Transparency = 0.7
        circle.Filled = false
        circle.NumSides = 32
        return circle
    end)
    
    if success then
        FOVCircle = result
    end
end

SetupFOVCircle()

-- Get target part
local function GetTargetPart(character)
    local partName = getgenv().AimbotHitPart or "Head"
    local part = character:FindFirstChild(partName)
    
    if not part then
        part = character:FindFirstChild("Head") or 
               character:FindFirstChild("HumanoidRootPart") or
               character:FindFirstChild("UpperTorso")
    end
    
    return part
end

-- Wall check
local WallCheckParams = RaycastParams.new()
WallCheckParams.FilterType = Enum.RaycastFilterType.Blacklist
WallCheckParams.IgnoreWater = true

local function IsVisible(part)
    if not part or not part.Parent then return false end
    
    WallCheckParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    
    local origin = Camera.CFrame.Position
    local targetPos = part.Position
    local direction = (targetPos - origin)
    local distance = direction.Magnitude
    
    if distance > 500 then return false end
    
    local result = Workspace:Raycast(origin, direction.Unit * distance, WallCheckParams)
    
    if result then
        return result.Instance:IsDescendantOf(part.Parent)
    end
    return true
end

-- Get closest target with yielding
local LastTarget = nil
local LastTargetTime = 0
local TargetCache = {}

local function GetTarget()
    local now = tick()
    
    -- Use cache
    if LastTarget and (now - LastTargetTime) < 0.1 then
        if LastTarget.Part and LastTarget.Part.Parent then
            local humanoid = LastTarget.Part.Parent:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                return LastTarget
            end
        end
    end
    
    local closestTarget = nil
    local shortestDistance = getgenv().AimbotFOV or 180
    local mousePos = UserInputService:GetMouseLocation()
    local localTeam = LocalPlayer.Team
    local localTeamColor = LocalPlayer.TeamColor
    
    local allPlayers = Players:GetPlayers()
    local playerCount = #allPlayers
    
    -- Process in batches to prevent freezing
    for i = 1, playerCount do
        -- Yield every 5 players to prevent lag
        if i % 5 == 0 then
            task.wait()
        end
        
        local player = allPlayers[i]
        if player == LocalPlayer then continue end
        
        local character = player.Character
        if not character then continue end
        
        -- Quick checks first
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        
        if getgenv().AimbotTeamCheck then
            if player.Team == localTeam or player.TeamColor == localTeamColor then
                continue
            end
        end
        
        local targetPart = GetTargetPart(character)
        if not targetPart then continue end
        
        -- Distance check before expensive viewport calc
        local distance = (targetPart.Position - Camera.CFrame.Position).Magnitude
        if distance > 1000 then continue end
        
        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if not onScreen then continue end
        
        local distanceFromMouse = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        
        if distanceFromMouse < shortestDistance then
            if getgenv().AimbotWallCheck and not IsVisible(targetPart) then
                continue
            end
            
            shortestDistance = distanceFromMouse
            closestTarget = {
                Player = player,
                Part = targetPart,
                ScreenPosition = Vector2.new(screenPos.X, screenPos.Y),
                WorldPosition = targetPart.Position
            }
        end
    end
    
    LastTarget = closestTarget
    LastTargetTime = now
    
    return closestTarget
end

-- CFRAME AIM METHOD
local function AimAtTarget(target)
    if not target or not target.WorldPosition then return end
    
    local smoothness = math.clamp(getgenv().AimbotSmoothness or 1, 1, 10)
    local targetPos = target.WorldPosition
    local camPos = Camera.CFrame.Position
    
    local targetCFrame = CFrame.new(camPos, targetPos)
    Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 / smoothness)
end

-- Triggerbot with debounce
local TriggerDebounce = false
local TriggerParams = RaycastParams.new()
TriggerParams.FilterType = Enum.RaycastFilterType.Blacklist

local function CheckTriggerbot()
    if not getgenv().TriggerbotEnabled or TriggerDebounce then return end
    
    TriggerParams.FilterDescendantsInstances = {LocalPlayer.Character}
    
    local ray = Camera:ViewportPointToRay(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
    local result = Workspace:Raycast(ray.Origin, ray.Direction * 500, TriggerParams)
    
    if result then
        local hit = result.Instance
        local character = hit:FindFirstAncestorOfClass("Model")
        
        if character then
            local player = Players:GetPlayerFromCharacter(character)
            if player and player ~= LocalPlayer then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                
                if humanoid and humanoid.Health > 0 then
                    if getgenv().AimbotTeamCheck and (player.Team == LocalPlayer.Team or player.TeamColor == LocalPlayer.TeamColor) then
                        return
                    end
                    
                    TriggerDebounce = true
                    local delay = getgenv().TriggerbotDelay or 0
                    
                    task.delay(delay / 1000, function()
                        pcall(function()
                            if mouse1press and mouse1release then
                                mouse1press()
                                task.wait(0.01)
                                mouse1release()
                            else
                                local VIM = game:GetService("VirtualInputManager")
                                VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                                task.wait(0.01)
                                VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                            end
                        end)
                        task.wait(0.05)
                        TriggerDebounce = false
                    end)
                end
            end
        end
    end
end

-- Main loop with frame skipping
local FrameCount = 0
local Connection = RunService.RenderStepped:Connect(function()
    FrameCount = FrameCount + 1
    
    -- Skip frames for performance (run at 20 FPS instead of 60)
    if FrameCount % 3 ~= 0 then
        return
    end
    
    local success, err = pcall(function()
        -- Update FOV Circle (cheap)
        if FOVCircle then
            local showCircle = getgenv().AimbotShowFOV and getgenv().AimbotEnabled
            FOVCircle.Visible = showCircle
            
            if showCircle then
                FOVCircle.Radius = getgenv().AimbotFOV or 180
                FOVCircle.Position = UserInputService:GetMouseLocation()
                
                local target = GetTarget()
                if target then
                    FOVCircle.Color = Color3.fromRGB(0, 255, 0)
                    FOVCircle.Filled = true
                    FOVCircle.Transparency = 0.3
                else
                    FOVCircle.Color = Color3.fromRGB(255, 50, 50)
                    FOVCircle.Filled = false
                    FOVCircle.Transparency = 0.7
                end
            end
        end
        
        -- Triggerbot (every 6 frames)
        if getgenv().TriggerbotEnabled and FrameCount % 6 == 0 then
            CheckTriggerbot()
        end
        
        -- Aimbot
        if getgenv().AimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local target = GetTarget()
            if target then
                AimAtTarget(target)
            end
        end
    end)
    
    if not success then
        warn("[Xorfhook Aimbot] Error: " .. tostring(err))
    end
end)

getgenv().XorfhookAimbotConnection = Connection

print("[Xorfhook] Optimized Aimbot loaded")
print("[Xorfhook] Runs at 20 FPS to prevent lag")
