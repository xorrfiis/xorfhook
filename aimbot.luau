local plrs = game:GetService("Players")
local rs = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local lp = plrs.LocalPlayer
local cam = workspace.CurrentCamera

-- defaults
getgenv().show_circle = getgenv().show_circle or false
getgenv().Aimbot = getgenv().Aimbot or false
getgenv().SilentAim = getgenv().SilentAim or false
getgenv().SilentAimVisible = getgenv().SilentAimVisible or false -- NEW: Move camera with silent aim
getgenv().SilentAimChance = getgenv().SilentAimChance or 100
getgenv().Triggerbot = getgenv().Triggerbot or false
getgenv().TriggerbotDelay = getgenv().TriggerbotDelay or 0
getgenv().Smoothness = getgenv().Smoothness or 1
getgenv().FOV = getgenv().FOV or 180
getgenv().TeamCheck = getgenv().TeamCheck ~= false
getgenv().WallCheck = getgenv().WallCheck ~= false
getgenv().HitPart = getgenv().HitPart or "Head"

-- Rivals-specific
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local WeaponRemotes = Remotes and Remotes:WaitForChild("Weapon", 10)

-- ============================================
-- MOUSE MOVEREL
-- ============================================
local mousemoverel_func = nil
local function getMouseMoveRel()
    if mousemoverel_func then return mousemoverel_func end
    
    if typeof(mousemoverel) == "function" then
        mousemoverel_func = mousemoverel
    elseif typeof(syn) == "table" and typeof(syn.mousemoverel) == "function" then
        mousemoverel_func = syn.mousemoverel
    elseif typeof(fluxus) == "table" and typeof(fluxus.mousemoverel) == "function" then
        mousemoverel_func = fluxus.mousemoverel
    elseif typeof(KRNL) == "table" and typeof(KRNL.mousemoverel) == "function" then
        mousemoverel_func = KRNL.mousemoverel
    elseif typeof(YUBX) == "table" and typeof(YUBX.mousemoverel) == "function" then
        mousemoverel_func = YUBX.mousemoverel
    elseif typeof(Xeno) == "table" and typeof(Xeno.mousemoverel) == "function" then
        mousemoverel_func = Xeno.mousemoverel
    elseif typeof(mousemove) == "function" then
        mousemoverel_func = mousemove
    elseif typeof(MoveMouse) == "function" then
        mousemoverel_func = MoveMouse
    else
        local VirtualInputManager = game:GetService("VirtualInputManager")
        mousemoverel_func = function(x, y)
            local absX = x + (uis:GetMouseLocation().X)
            local absY = y + (uis:GetMouseLocation().Y)
            VirtualInputManager:SendMouseMoveEvent(absX, absY, game)
        end
    end
    
    return mousemoverel_func
end

-- ============================================
-- DRAWING
-- ============================================
local circle = nil
local function setupCircle()
    if circle then return end
    
    local DrawingLib = Drawing or getgenv().Drawing
    
    if DrawingLib and typeof(DrawingLib.new) == "function" then
        local success, result = pcall(function()
            local c = DrawingLib.new("Circle")
            c.Thickness = 2
            c.Visible = false
            c.Color = Color3.fromRGB(255, 50, 50)
            c.Transparency = 0.5
            c.Filled = false
            c.NumSides = 32
            return c
        end)
        
        if success then
            circle = result
        end
    end
end

setupCircle()

-- ============================================
-- CACHED VARIABLES
-- ============================================
local lastTarget = nil
local lastTargetTime = 0
local targetCacheDuration = 0.05
local frameCount = 0
local skipFrames = 2

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
raycastParams.IgnoreWater = true

local function is_visible(part)
    if not part or not part.Parent then return false end
    
    raycastParams.FilterDescendantsInstances = {lp.Character, cam}
    
    local origin = cam.CFrame.Position
    local direction = (part.Position - origin)
    
    if direction.Magnitude > 1000 then return false end
    
    local result = workspace:Raycast(origin, direction.Unit * direction.Magnitude, raycastParams)
    
    if result then
        return result.Instance:IsDescendantOf(part.Parent)
    end
    return true
end

local function getTargetPart(character)
    local hitPart = character:FindFirstChild(getgenv().HitPart or "Head")
    
    if not hitPart then
        hitPart = character:FindFirstChild("Head") or 
                  character:FindFirstChild("HumanoidRootPart")
    end
    
    return hitPart
end

-- ============================================
-- TARGET ACQUISITION
-- ============================================
local function get_target()
    local now = tick()
    
    if lastTarget and (now - lastTargetTime) < targetCacheDuration then
        if lastTarget.Part and lastTarget.Part.Parent and lastTarget.Player.Parent then
            local humanoid = lastTarget.Part.Parent:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                return lastTarget
            end
        end
    end
    
    local target = nil
    local dist = getgenv().FOV
    local mousePos = uis:GetMouseLocation()
    local myTeam = lp.Team
    local myTeamColor = lp.TeamColor
    
    local players = plrs:GetPlayers()
    
    for i = 1, #players do
        local v = players[i]
        if v ~= lp then
            local character = v.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    if getgenv().TeamCheck then
                        if v.Team == myTeam or v.TeamColor == myTeamColor then
                            continue
                        end
                    end
                    
                    local part = getTargetPart(character)
                    if part then
                        local pos, on_screen = cam:WorldToViewportPoint(part.Position)
                        
                        if on_screen then
                            local mag = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                            
                            if mag < dist and mag < 1000 then
                                if not getgenv().WallCheck or is_visible(part) then
                                    dist = mag
                                    target = {
                                        Player = v,
                                        Part = part,
                                        Position = part.Position,
                                        ScreenPos = pos
                                    }
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    lastTarget = target
    lastTargetTime = now
    
    return target
end

-- ============================================
-- CAMERA LOCK FOR SILENT AIM
-- ============================================
local cameraLockActive = false
local originalCameraCFrame = nil

local function lockCameraToTarget(target)
    if not target or not target.Part then return end
    
    -- Calculate look at CFrame
    local targetPos = target.Position
    local camPos = cam.CFrame.Position
    
    -- Smooth camera movement
    local targetCFrame = CFrame.new(camPos, targetPos)
    cam.CFrame = cam.CFrame:Lerp(targetCFrame, 0.3) -- 0.3 = smooth factor
end

-- ============================================
-- TRIGGERBOT
-- ============================================
local triggerbotDebounce = false
local triggerParams = RaycastParams.new()
triggerParams.FilterType = Enum.RaycastFilterType.Blacklist

local function checkTriggerbot()
    if not getgenv().Triggerbot or triggerbotDebounce then return end
    
    triggerParams.FilterDescendantsInstances = {lp.Character}
    
    local ray = cam:ViewportPointToRay(uis:GetMouseLocation().X, uis:GetMouseLocation().Y)
    local result = workspace:Raycast(ray.Origin, ray.Direction * 500, triggerParams)
    
    if result then
        local hit = result.Instance
        local character = hit:FindFirstAncestorOfClass("Model")
        
        if character then
            local player = plrs:GetPlayerFromCharacter(character)
            if player and player ~= lp then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                
                if humanoid and humanoid.Health > 0 then
                    if getgenv().TeamCheck and (player.Team == lp.Team or player.TeamColor == lp.TeamColor) then
                        return
                    end
                    
                    triggerbotDebounce = true
                    local delay = getgenv().TriggerbotDelay or 0
                    
                    task.delay(delay / 1000, function()
                        if mouse1press and mouse1release then
                            mouse1press()
                            task.wait(0.01)
                            mouse1release()
                        else
                            local VirtualInputManager = game:GetService("VirtualInputManager")
                            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                            task.wait(0.01)
                            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                        end
                        task.wait(0.05)
                        triggerbotDebounce = false
                    end)
                end
            end
        end
    end
end

-- ============================================
-- SILENT AIM WITH CAMERA LOCK
-- ============================================
local silentAimTarget = nil
local hooked = false

local function setupSilentAim()
    if hooked or not WeaponRemotes then return end
    
    for _, remote in pairs(WeaponRemotes:GetChildren()) do
        if remote:IsA("RemoteEvent") and not remote:GetAttribute("XorfhookHooked") then
            remote:SetAttribute("XorfhookHooked", true)
            
            local oldFire = remote.FireServer
            remote.FireServer = function(self, ...)
                if self:GetAttribute("XorfhookHooked") then
                    if getgenv().SilentAim and silentAimTarget and math.random(1, 100) <= (getgenv().SilentAimChance or 100) then
                        local args = {...}
                        
                        for i, arg in ipairs(args) do
                            if typeof(arg) == "Vector3" then
                                args[i] = silentAimTarget.Position
                            elseif typeof(arg) == "table" then
                                for k, v in pairs(arg) do
                                    if typeof(v) == "Vector3" then
                                        arg[k] = silentAimTarget.Position
                                    elseif k == "Hit" or k == "Target" then
                                        arg[k] = silentAimTarget.Part
                                    end
                                end
                            end
                        end
                        
                        return oldFire(self, unpack(args))
                    end
                end
                return oldFire(self, ...)
            end
        end
    end
    
    hooked = true
    print("[Xorfhook] Silent Aim enabled")
end

task.spawn(function()
    task.wait(2)
    pcall(setupSilentAim)
end)

-- Update silent aim target
task.spawn(function()
    while true do
        task.wait(0.05)
        if getgenv().SilentAim then
            silentAimTarget = get_target()
        else
            silentAimTarget = nil
        end
    end
end)

-- ============================================
-- MAIN LOOP
-- ============================================
local connection = rs.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    
    if frameCount % (skipFrames + 1) ~= 0 then
        return
    end
    
    local success, err = pcall(function()
        -- Update circle
        if circle then
            local shouldShow = (getgenv().Aimbot or getgenv().SilentAim) and getgenv().show_circle
            circle.Visible = shouldShow
            
            if shouldShow then
                circle.Radius = getgenv().FOV
                circle.Position = uis:GetMouseLocation()
                
                if getgenv().SilentAim and silentAimTarget then
                    circle.Color = Color3.fromRGB(0, 255, 0)
                    circle.Filled = true
                    circle.Transparency = 0.3
                else
                    circle.Color = Color3.fromRGB(255, 50, 50)
                    circle.Filled = false
                    circle.Transparency = 0.5
                end
            end
        end

        -- Triggerbot
        if getgenv().Triggerbot and frameCount % 2 == 0 then
            checkTriggerbot()
        end

        -- SILENT AIM WITH CAMERA LOCK
        if getgenv().SilentAim and silentAimTarget then
            if getgenv().SilentAimVisible then
                -- Move camera to target (smooth)
                lockCameraToTarget(silentAimTarget)
            end
        end

        -- Regular Aimbot
        if getgenv().Aimbot and not getgenv().SilentAim and uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local target = get_target()

            if target and target.Part then
                local pos = cam:WorldToViewportPoint(target.Position)
                local mousePos = uis:GetMouseLocation()

                local smooth = math.clamp(getgenv().Smoothness, 0.1, 5)
                local x = (pos.X - mousePos.X) / smooth
                local y = (pos.Y - mousePos.Y) / smooth

                local mouseMoveRel = getMouseMoveRel()
                if mouseMoveRel then
                    pcall(function()
                        mouseMoveRel(x, y)
                    end)
                end
            end
        end
    end)
    
    if not success then
        warn("[Xorfhook Aimbot] Error:", tostring(err))
    end
end)

getgenv().XorfhookAimbotConnection = connection
print("[Xorfhook] Aimbot loaded with Visible Silent Aim support")
