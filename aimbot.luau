local plrs = game:GetService("Players")
local rs = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local lp = plrs.LocalPlayer
local cam = workspace.CurrentCamera

-- defaults
getgenv().show_circle = getgenv().show_circle or false
getgenv().Aimbot = getgenv().Aimbot or false
getgenv().SilentAim = getgenv().SilentAim or false
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
-- UNIVERSAL MOUSE MOVEREL (YUB-X, Xeno, etc.)
-- ============================================
local mousemoverel_func = nil
local function getMouseMoveRel()
    if mousemoverel_func then return mousemoverel_func end
    
    -- Try global first
    if typeof(mousemoverel) == "function" then
        mousemoverel_func = mousemoverel
        print("[Xorfhook] Using global mousemoverel")
    -- Try syn
    elseif typeof(syn) == "table" and typeof(syn.mousemoverel) == "function" then
        mousemoverel_func = syn.mousemoverel
        print("[Xorfhook] Using syn.mousemoverel")
    -- Try fluxus
    elseif typeof(fluxus) == "table" and typeof(fluxus.mousemoverel) == "function" then
        mousemoverel_func = fluxus.mousemoverel
        print("[Xorfhook] Using fluxus.mousemoverel")
    -- Try KRNL
    elseif typeof(KRNL) == "table" and typeof(KRNL.mousemoverel) == "function" then
        mousemoverel_func = KRNL.mousemoverel
        print("[Xorfhook] Using KRNL.mousemoverel")
    -- Try YUB-X specific
    elseif typeof(YUBX) == "table" and typeof(YUBX.mousemoverel) == "function" then
        mousemoverel_func = YUBX.mousemoverel
        print("[Xorfhook] Using YUBX.mousemoverel")
    -- Try Xeno specific
    elseif typeof(Xeno) == "table" and typeof(Xeno.mousemoverel) == "function" then
        mousemoverel_func = Xeno.mousemoverel
        print("[Xorfhook] Using Xeno.mousemoverel")
    -- Try alternative names
    elseif typeof(mousemove) == "function" then
        mousemoverel_func = mousemove
        print("[Xorfhook] Using mousemove")
    elseif typeof(MoveMouse) == "function" then
        mousemoverel_func = MoveMouse
        print("[Xorfhook] Using MoveMouse")
    -- Try VirtualInputManager fallback
    else
        local VirtualInputManager = game:GetService("VirtualInputManager")
        mousemoverel_func = function(x, y)
            local absX = x + (uis:GetMouseLocation().X)
            local absY = y + (uis:GetMouseLocation().Y)
            VirtualInputManager:SendMouseMoveEvent(absX, absY, game)
        end
        print("[Xorfhook] Using VirtualInputManager fallback")
    end
    
    return mousemoverel_func
end

-- Test mousemoverel immediately
task.spawn(function()
    task.wait(1)
    local mm = getMouseMoveRel()
    if mm then
        print("[Xorfhook] MouseMoveRel ready!")
    else
        warn("[Xorfhook] MouseMoveRel NOT FOUND - Aimbot may not work!")
    end
end)

-- ============================================
-- UNIVERSAL DRAWING SETUP
-- ============================================
local circle = nil
local function setupCircle()
    -- Try to get Drawing library
    local DrawingLib = nil
    
    if typeof(Drawing) == "table" then
        DrawingLib = Drawing
    elseif typeof(getgenv().Drawing) == "table" then
        DrawingLib = getgenv().Drawing
    end
    
    if DrawingLib and typeof(DrawingLib.new) == "function" then
        local success, result = pcall(function()
            local c = DrawingLib.new("Circle")
            c.Thickness = 2
            c.Visible = false
            c.Color = Color3.fromRGB(255, 50, 50)
            c.Transparency = 0.5
            c.Filled = false
            c.NumSides = 64
            return c
        end)
        
        if success then
            circle = result
            print("[Xorfhook] FOV Circle ready")
        else
            warn("[Xorfhook] Failed to create circle: " .. tostring(result))
        end
    else
        warn("[Xorfhook] Drawing library not available")
    end
end

setupCircle()

-- ============================================
-- TARGETING FUNCTIONS
-- ============================================
local function is_visible(part)
    if not part or not part.Parent then return false end
    
    local origin = cam.CFrame.Position
    local direction = (part.Position - origin)
    local distance = direction.Magnitude
    direction = direction.Unit * distance

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {lp.Character, cam}
    params.IgnoreWater = true

    local result = workspace:Raycast(origin, direction, params)
    
    if result then
        return result.Instance:IsDescendantOf(part.Parent)
    end
    return true
end

local function getTargetPart(character)
    local hitPart = getgenv().HitPart or "Head"
    local part = character:FindFirstChild(hitPart)
    
    if not part then
        part = character:FindFirstChild("Head") or 
               character:FindFirstChild("HumanoidRootPart") or
               character:FindFirstChild("UpperTorso")
    end
    
    return part
end

local function get_target()
    local target = nil
    local dist = getgenv().FOV
    local mousePos = uis:GetMouseLocation()

    for _, v in pairs(plrs:GetPlayers()) do
        if v ~= lp and v.Character then
            local humanoid = v.Character:FindFirstChildOfClass("Humanoid")
            local part = getTargetPart(v.Character)

            if humanoid and humanoid.Health > 0 and part then
                if getgenv().TeamCheck then
                    if v.Team == lp.Team or v.TeamColor == lp.TeamColor then
                        continue
                    end
                end

                if getgenv().WallCheck and not is_visible(part) then
                    continue
                end

                local pos, on_screen = cam:WorldToViewportPoint(part.Position)

                if on_screen then
                    local mag = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude

                    if mag < dist then
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

    return target
end

-- ============================================
-- TRIGGERBOT
-- ============================================
local triggerbotDebounce = false

local function checkTriggerbot()
    if not getgenv().Triggerbot or triggerbotDebounce then return end
    
    local ray = cam:ViewportPointToRay(uis:GetMouseLocation().X, uis:GetMouseLocation().Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {lp.Character}
    
    local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
    
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
                        -- Try multiple mouse click methods
                        if mouse1press and mouse1release then
                            mouse1press()
                            task.wait(0.01)
                            mouse1release()
                        elseif typeof(syn) == "table" and syn.mouse1press then
                            syn.mouse1press()
                            task.wait(0.01)
                            syn.mouse1release()
                        else
                            -- Fallback to VirtualInputManager
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
-- SILENT AIM
-- ============================================
local silentAimTarget = nil

local function setupSilentAim()
    if not WeaponRemotes then 
        warn("[Xorfhook] Weapon remotes not found")
        return 
    end
    
    -- Hook all weapon remotes
    for _, remote in pairs(WeaponRemotes:GetChildren()) do
        if remote:IsA("RemoteEvent") then
            local oldFire = remote.FireServer
            remote.FireServer = function(self, ...)
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
                return oldFire(self, ...)
            end
        end
    end
    
    print("[Xorfhook] Silent Aim enabled")
end

task.spawn(function()
    task.wait(2)
    pcall(setupSilentAim)
end)

rs.RenderStepped:Connect(function()
    if getgenv().SilentAim then
        silentAimTarget = get_target()
    else
        silentAimTarget = nil
    end
end)

-- ============================================
-- MAIN LOOP
-- ============================================
local connection = rs.RenderStepped:Connect(function()
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
        if getgenv().Triggerbot then
            checkTriggerbot()
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
                    -- YUB-X might need integers
                    local success, err = pcall(function()
                        mouseMoveRel(math.floor(x), math.floor(y))
                    end)
                    if not success then
                        -- Try with floats if integers fail
                        pcall(function()
                            mouseMoveRel(x, y)
                        end)
                    end
                end
            end
        end
    end)
    
    if not success then
        warn("[Xorfhook Aimbot] Error:", tostring(err))
    end
end)

getgenv().XorfhookAimbotConnection = connection
print("[Xorfhook] Aimbot module loaded")
