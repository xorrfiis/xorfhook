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

-- DEBUG: Print settings on load
print("[Xorfhook Aimbot] Settings loaded:")
print("  Enabled: " .. tostring(getgenv().AimbotEnabled))
print("  FOV: " .. tostring(getgenv().AimbotFOV))
print("  Smoothness: " .. tostring(getgenv().AimbotSmoothness))

-- YUB-X mousemoverel
local MouseMoveRel = nil

local function GetMouseMoveRel()
    if MouseMoveRel then return MouseMoveRel end
    
    -- Try YUB-X first
    if typeof(YUBX) == "table" and typeof(YUBX.mousemoverel) == "function" then
        MouseMoveRel = YUBX.mousemoverel
        print("[Xorfhook] Using YUBX.mousemoverel")
        return MouseMoveRel
    end
    
    -- Fallbacks
    if typeof(mousemoverel) == "function" then
        MouseMoveRel = mousemoverel
        print("[Xorfhook] Using global mousemoverel")
    elseif typeof(syn) == "table" and typeof(syn.mousemoverel) == "function" then
        MouseMoveRel = syn.mousemoverel
        print("[Xorfhook] Using syn.mousemoverel")
    else
        local VIM = game:GetService("VirtualInputManager")
        MouseMoveRel = function(x, y)
            local currentPos = UserInputService:GetMouseLocation()
            VIM:SendMouseMoveEvent(currentPos.X + x, currentPos.Y + y, game)
        end
        print("[Xorfhook] Using VIM fallback")
    end
    
    return MouseMoveRel
end

-- Test mousemoverel on load
task.spawn(function()
    task.wait(1)
    local mover = GetMouseMoveRel()
    if mover then
        print("[Xorfhook] MouseMoveRel ready!")
    else
        warn("[Xorfhook] MouseMoveRel NOT FOUND!")
    end
end)

-- Drawing setup
local FOVCircle = nil
local function SetupFOVCircle()
    if FOVCircle then return end
    if not Drawing then 
        warn("[Xorfhook] Drawing library not available!")
        return 
    end
    
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
        print("[Xorfhook] FOV Circle created")
    else
        warn("[Xorfhook] Failed to create FOV Circle: " .. tostring(result))
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
    
    -- DEBUG: Count players
    local checked = 0
    local valid = 0
    
    for i = 1, #allPlayers do
        local player = allPlayers[i]
        if player == LocalPlayer then continue end
        
        checked = checked + 1
        
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
            
            valid = valid + 1
            shortestDistance = distanceFromMouse
            closestTarget = {
                Player = player,
                Part = targetPart,
                ScreenPosition = Vector2.new(screenPos.X, screenPos.Y)
            }
        end
    end
    
    -- DEBUG: Print target info occasionally
    if closestTarget and (now % 1 < 0.1) then
        print("[Xorfhook] Target: " .. closestTarget.Player.Name .. " | Dist: " .. math.floor(shortestDistance))
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
local DebugTimer = 0
local Connection = RunService.RenderStepped:Connect(function(deltaTime)
    FrameCount = FrameCount + 1
    DebugTimer = DebugTimer + deltaTime
    
    local success, err = pcall(function()
        -- Update FOV Circle
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
        
        -- Triggerbot
        if getgenv().TriggerbotEnabled and FrameCount % 2 == 0 then
            CheckTriggerbot()
        end
        
        -- DEBUG: Print status every 2 seconds
        if DebugTimer > 2 then
            DebugTimer = 0
            local rightMouse = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
            print("[Xorfhook] Status - Enabled: " .. tostring(getgenv().AimbotEnabled) .. " | RightClick: " .. tostring(rightMouse))
        end
        
        -- Aimbot
        if getgenv().AimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local target = GetTarget()
            
            if target and target.ScreenPosition then
                local mousePos = UserInputService:GetMouseLocation()
                local smoothness = math.clamp(getgenv().AimbotSmoothness or 1, 0.1, 10)
                
                -- Calculate delta
                local deltaX = (target.ScreenPosition.X - mousePos.X) / smoothness
                local deltaY = (target.ScreenPosition.Y - mousePos.Y) / smoothness
                
                -- DEBUG: Print movement occasionally
                if FrameCount % 60 == 0 then
                    print("[Xorfhook] Moving: dx=" .. string.format("%.2f", deltaX) .. " dy=" .. string.format("%.2f", deltaY))
                end
                
                -- Skip tiny movements
                if math.abs(deltaX) < 0.5 and math.abs(deltaY) < 0.5 then
                    return
                end
                
                local mover = GetMouseMoveRel()
                if mover then
                    pcall(function()
                        mover(deltaX, deltaY)
                    end)
                else
                    warn("[Xorfhook] No mouse mover available!")
                end
            else
                -- DEBUG: No target
                if FrameCount % 120 == 0 then
                    print("[Xorfhook] No target found")
                end
            end
        end
    end)
    
    if not success then
        warn("[Xorfhook Aimbot] Error: " .. tostring(err))
    end
end)

getgenv().XorfhookAimbotConnection = Connection

print("[Xorfhook] Aimbot loaded (DEBUG MODE)")
print("[Xorfhook] Right-click to aim. Check console for debug info.")
