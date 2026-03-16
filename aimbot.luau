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

-- Universal mousemoverel
local MouseMoveRel = nil
local function GetMouseMoveRel()
    if MouseMoveRel then return MouseMoveRel end
    
    local options = {
        mousemoverel,
        (syn and syn.mousemoverel),
        (fluxus and fluxus.mousemoverel),
        (KRNL and KRNL.mousemoverel),
        (YUBX and YUBX.mousemoverel),
        (Xeno and Xeno.mousemoverel),
        (getgenv().mousemoverel),
        mousemove,
        MoveMouse
    }
    
    for _, opt in ipairs(options) do
        if typeof(opt) == "function" then
            MouseMoveRel = opt
            print("[Xorfhook Aimbot] mousemoverel found")
            return MouseMoveRel
        end
    end
    
    -- Fallback
    local VIM = game:GetService("VirtualInputManager")
    MouseMoveRel = function(x, y)
        local currentPos = UserInputService:GetMouseLocation()
        VIM:SendMouseMoveEvent(currentPos.X + x, currentPos.Y + y, game)
    end
    print("[Xorfhook Aimbot] Using VIM fallback")
    return MouseMoveRel
end

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

-- Get closest target
local LastTarget = nil
local LastTargetTime = 0

local function GetTarget()
    local now = tick()
    
    -- Cache for 50ms
    if LastTarget and (now - LastTargetTime) < 0.05 then
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
    
    for i = 1, #allPlayers do
        local player = allPlayers[i]
        if player == LocalPlayer then continue end
        
        local character = player.Character
        if not character then continue end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        
        -- Team check
        if getgenv().AimbotTeamCheck then
            if player.Team == localTeam or player.TeamColor == localTeamColor then
                continue
            end
        end
        
        local targetPart = GetTargetPart(character)
        if not targetPart then continue end
        
        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if not onScreen then continue end
        
        local distanceFromMouse = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        
        if distanceFromMouse < shortestDistance then
            -- Wall check last
            if getgenv().AimbotWallCheck and not IsVisible(targetPart) then
                continue
            end
            
            shortestDistance = distanceFromMouse
            closestTarget = {
                Player = player,
                Part = targetPart,
                ScreenPosition = Vector2.new(screenPos.X, screenPos.Y)
            }
        end
    end
    
    LastTarget = closestTarget
    LastTargetTime = now
    
    return closestTarget
end

-- Triggerbot
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
                        -- Click mouse
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
                        task.wait(0.05)
                        TriggerDebounce = false
                    end)
                end
            end
        end
    end
end

-- Main loop
local FrameCount = 0
local Connection = RunService.RenderStepped:Connect(function()
    FrameCount = FrameCount + 1
    
    local success, err = pcall(function()
        -- Update FOV Circle (every frame for smoothness)
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
        
        -- Triggerbot (every other frame)
        if getgenv().TriggerbotEnabled and FrameCount % 2 == 0 then
            CheckTriggerbot()
        end
        
        -- Aimbot (only when right mouse held)
        if getgenv().AimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local target = GetTarget()
            
            if target and target.ScreenPosition then
                local mousePos = UserInputService:GetMouseLocation()
                local smoothness = math.clamp(getgenv().AimbotSmoothness or 1, 0.1, 10)
                
                local deltaX = (target.ScreenPosition.X - mousePos.X) / smoothness
                local deltaY = (target.ScreenPosition.Y - mousePos.Y) / smoothness
                
                -- Skip tiny movements
                if math.abs(deltaX) < 0.5 and math.abs(deltaY) < 0.5 then
                    return
                end
                
                local mover = GetMouseMoveRel()
                if mover then
                    -- Try integer first
                    local ok = pcall(function()
                        mover(math.floor(deltaX), math.floor(deltaY))
                    end)
                    
                    -- Fallback to float
                    if not ok then
                        pcall(function()
                            mover(deltaX, deltaY)
                        end)
                    end
                end
            end
        end
    end)
    
    if not success then
        warn("[Xorfhook Aimbot] Error: " .. tostring(err))
    end
end)

-- Cleanup
getgenv().XorfhookAimbotConnection = Connection

print("[Xorfhook] Aimbot loaded - Right click to aim, enable Triggerbot for auto-shoot")
