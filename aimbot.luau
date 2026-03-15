local plrs = game:GetService("Players")
local rs = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local lp = plrs.LocalPlayer
local cam = workspace.CurrentCamera

-- defaults (GUI will overwrite these)
getgenv().show_circle = getgenv().show_circle or false
getgenv().Aimbot = getgenv().Aimbot or false
getgenv().Smoothness = getgenv().Smoothness or 1
getgenv().FOV = getgenv().FOV or 180
getgenv().TeamCheck = getgenv().TeamCheck ~= false
getgenv().WallCheck = getgenv().WallCheck ~= false

-- Universal mousemoverel detection
local mousemoverel_func = nil
local function getMouseMoveRel()
    if mousemoverel_func then return mousemoverel_func end
    
    -- Check various executor implementations
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
    elseif typeof(hookfunction) == "function" then
        -- Fallback: use input injection if available
        local VirtualInputManager = game:GetService("VirtualInputManager")
        mousemoverel_func = function(x, y)
            VirtualInputManager:SendMouseMoveEvent(x, y, game)
        end
    end
    
    return mousemoverel_func
end

-- Drawing setup with fallback
local DrawingLib = Drawing or {}
local circle

local function setupCircle()
    if typeof(DrawingLib.new) == "function" then
        circle = DrawingLib.new("Circle")
        circle.Thickness = 2
        circle.Visible = false
        circle.Color = Color3.fromRGB(255, 50, 50)
        circle.Transparency = 0.5
        circle.Filled = false
    else
        warn("[Xorfhook] Drawing library not available")
    end
end

setupCircle()

-- Wall check with improved raycasting
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
        local instance = result.Instance
        local isVisible = instance:IsDescendantOf(part.Parent) or 
                         (instance.Parent and instance.Parent:IsDescendantOf(part.Parent))
        return isVisible
    end

    return true -- No obstruction found
end

-- Target acquisition
local function get_target()
    local target = nil
    local dist = getgenv().FOV
    local mouse = uis:GetMouseLocation()
    local mouseMoveRel = getMouseMoveRel()
    
    if not mouseMoveRel then return nil end

    for _, v in pairs(plrs:GetPlayers()) do
        if v ~= lp and v.Character then
            local humanoid = v.Character:FindFirstChildOfClass("Humanoid")
            local head = v.Character:FindFirstChild("HeadHB") or 
                        v.Character:FindFirstChild("Head") or 
                        v.Character:FindFirstChild("UpperTorso") or
                        v.Character:FindFirstChild("HumanoidRootPart")

            if humanoid and humanoid.Health > 0 and head then
                -- Team check
                if getgenv().TeamCheck and v.Team == lp.Team then
                    continue
                end

                -- Wall check
                if getgenv().WallCheck and not is_visible(head) then
                    continue
                end

                local pos, on_screen = cam:WorldToViewportPoint(head.Position)

                if on_screen then
                    local mag = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude

                    if mag < dist then
                        dist = mag
                        target = head
                    end
                end
            end
        end
    end

    return target
end

-- Main loop with proper error handling
local connection
connection = rs.RenderStepped:Connect(function()
    local success, err = pcall(function()
        -- Update circle
        if circle then
            circle.Visible = getgenv().Aimbot and getgenv().show_circle
            if circle.Visible then
                circle.Radius = getgenv().FOV
                circle.Position = uis:GetMouseLocation()
            end
        end

        -- Aimbot logic
        if getgenv().Aimbot and uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local target = get_target()

            if target and target.Parent then
                local pos = cam:WorldToViewportPoint(target.Position)
                local mouse_loc = uis:GetMouseLocation()

                local smooth = math.clamp(getgenv().Smoothness, 0.1, 5)
                local x = (pos.X - mouse_loc.X) / smooth
                local y = (pos.Y - mouse_loc.Y) / smooth

                local mouseMoveRel = getMouseMoveRel()
                if mouseMoveRel then
                    mouseMoveRel(x, y)
                end
            end
        end
    end)
    
    if not success then
        warn("[Xorfhook Aimbot] Error: " .. tostring(err))
    end
end)

-- Cleanup on error or script destruction
getgenv().XorfhookAimbotConnection = connection
