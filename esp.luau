local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer
local cam = workspace.CurrentCamera

-- Initialize global settings safely
getgenv().ESPEnabled = getgenv().ESPEnabled or false
getgenv().ESPColor = getgenv().ESPColor or Color3.fromRGB(255, 0, 0)
getgenv().ESPBox = getgenv().ESPBox or false
getgenv().ESPName = getgenv().ESPName or true
getgenv().ESPHealth = getgenv().ESPHealth or true
getgenv().ESPDistance = getgenv().ESPDistance or false

local ESPObjects = {}
local connection

-- Cleanup function
local function cleanupESP()
    for player, data in pairs(ESPObjects) do
        if data then
            for _, drawing in pairs(data) do
                if drawing and typeof(drawing.Remove) == "function" then
                    pcall(function() drawing:Remove() end)
                end
            end
        end
    end
    ESPObjects = {}
end

-- Safe Drawing creation
local function createDrawing(type)
    if typeof(Drawing) == "table" and typeof(Drawing.new) == "function" then
        local success, result = pcall(Drawing.new, type)
        if success then
            return result
        end
    end
    return nil
end

-- Get character bounding box
local function getBoundingBox(character)
    local cframe, size = character:GetBoundingBox()
    return cframe, size
end

-- Format distance
local function formatDistance(studs)
    if studs < 1000 then
        return math.floor(studs) .. "m"
    else
        return string.format("%.1fkm", studs / 1000)
    end
end

-- Main ESP loop
connection = RunService.RenderStepped:Connect(function()
    local success, err = pcall(function()
        -- Disable all ESP if turned off
        if not getgenv().ESPEnabled then
            for _, data in pairs(ESPObjects) do
                if data then
                    for _, drawing in pairs(data) do
                        if drawing then
                            drawing.Visible = false
                        end
                    end
                end
            end
            return
        end

        -- Clean up disconnected players
        for player in pairs(ESPObjects) do
            if not player or not player.Parent then
                if ESPObjects[player] then
                    for _, drawing in pairs(ESPObjects[player]) do
                        pcall(function() drawing:Remove() end)
                    end
                    ESPObjects[player] = nil
                end
            end
        end

        -- Update/create ESP for valid players
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= lp and player.Character then
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                local head = player.Character:FindFirstChild("Head")
                
                if humanoid and humanoid.Health > 0 and hrp and head then
                    -- Create ESP objects if needed
                    if not ESPObjects[player] then
                        ESPObjects[player] = {
                            Box = createDrawing("Square"),
                            BoxOutline = createDrawing("Square"),
                            Name = createDrawing("Text"),
                            Health = createDrawing("Text"),
                            Distance = createDrawing("Text"),
                            HealthBar = createDrawing("Square"),
                            HealthBarOutline = createDrawing("Square")
                        }
                        
                        -- Setup Box
                        if ESPObjects[player].Box then
                            ESPObjects[player].Box.Thickness = 1
                            ESPObjects[player].Box.Filled = false
                            ESPObjects[player].Box.Transparency = 1
                        end
                        
                        -- Setup Box Outline
                        if ESPObjects[player].BoxOutline then
                            ESPObjects[player].BoxOutline.Thickness = 3
                            ESPObjects[player].BoxOutline.Filled = false
                            ESPObjects[player].BoxOutline.Color = Color3.fromRGB(0, 0, 0)
                            ESPObjects[player].BoxOutline.Transparency = 1
                        end
                        
                        -- Setup Name
                        if ESPObjects[player].Name then
                            ESPObjects[player].Name.Size = 13
                            ESPObjects[player].Name.Center = true
                            ESPObjects[player].Name.Outline = true
                            ESPObjects[player].Name.Font = 2
                        end
                        
                        -- Setup Health
                        if ESPObjects[player].Health then
                            ESPObjects[player].Health.Size = 11
                            ESPObjects[player].Health.Center = true
                            ESPObjects[player].Health.Outline = true
                            ESPObjects[player].Health.Font = 2
                        end
                        
                        -- Setup Distance
                        if ESPObjects[player].Distance then
                            ESPObjects[player].Distance.Size = 11
                            ESPObjects[player].Distance.Center = true
                            ESPObjects[player].Distance.Outline = true
                            ESPObjects[player].Distance.Font = 2
                        end
                        
                        -- Setup Health Bar
                        if ESPObjects[player].HealthBar then
                            ESPObjects[player].HealthBar.Filled = true
                            ESPObjects[player].HealthBar.Transparency = 1
                        end
                        
                        if ESPObjects[player].HealthBarOutline then
                            ESPObjects[player].HealthBarOutline.Filled = true
                            ESPObjects[player].HealthBarOutline.Color = Color3.fromRGB(0, 0, 0)
                            ESPObjects[player].HealthBarOutline.Transparency = 1
                        end
                    end

                    local data = ESPObjects[player]
                    local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                    local distance = (cam.CFrame.Position - hrp.Position).Magnitude

                    if onScreen and distance < 5000 then -- Max distance 5000 studs
                        local _, size = getBoundingBox(player.Character)
                        local scale = 1000 / pos.Z
                        local width = math.clamp(size.X * scale, 20, 100)
                        local height = math.clamp(size.Y * scale, 40, 150)
                        
                        local x = pos.X
                        local y = pos.Y
                        
                        local color = getgenv().ESPColor or Color3.fromRGB(255, 0, 0)
                        
                        -- Box ESP
                        if getgenv().ESPBox and data.Box and data.BoxOutline then
                            data.Box.Visible = true
                            data.BoxOutline.Visible = true
                            data.Box.Size = Vector2.new(width, height)
                            data.Box.Position = Vector2.new(x - width/2, y - height/2)
                            data.Box.Color = color
                            
                            data.BoxOutline.Size = Vector2.new(width, height)
                            data.BoxOutline.Position = Vector2.new(x - width/2, y - height/2)
                        else
                            if data.Box then data.Box.Visible = false end
                            if data.BoxOutline then data.BoxOutline.Visible = false end
                        end
                        
                        -- Name ESP
                        if getgenv().ESPName and data.Name then
                            data.Name.Visible = true
                            data.Name.Position = Vector2.new(x, y - height/2 - 15)
                            data.Name.Text = player.Name
                            data.Name.Color = color
                        elseif data.Name then
                            data.Name.Visible = false
                        end
                        
                        -- Health ESP
                        local healthPercent = humanoid.Health / humanoid.MaxHealth
                        local healthColor = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
                        
                        if getgenv().ESPHealth then
                            -- Health Text
                            if data.Health then
                                data.Health.Visible = true
                                data.Health.Position = Vector2.new(x, y + height/2 + 2)
                                data.Health.Text = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
                                data.Health.Color = healthColor
                            end
                            
                            -- Health Bar
                            if data.HealthBar and data.HealthBarOutline then
                                local barWidth = 4
                                local barHeight = height
                                local barX = x - width/2 - barWidth - 2
                                local barY = y - height/2
                                
                                data.HealthBarOutline.Visible = true
                                data.HealthBarOutline.Size = Vector2.new(barWidth, barHeight)
                                data.HealthBarOutline.Position = Vector2.new(barX, barY)
                                
                                data.HealthBar.Visible = true
                                data.HealthBar.Size = Vector2.new(barWidth, barHeight * healthPercent)
                                data.HealthBar.Position = Vector2.new(barX, barY + barHeight * (1 - healthPercent))
                                data.HealthBar.Color = healthColor
                            end
                        else
                            if data.Health then data.Health.Visible = false end
                            if data.HealthBar then data.HealthBar.Visible = false end
                            if data.HealthBarOutline then data.HealthBarOutline.Visible = false end
                        end
                        
                        -- Distance ESP
                        if getgenv().ESPDistance and data.Distance then
                            data.Distance.Visible = true
                            data.Distance.Position = Vector2.new(x, y + height/2 + (getgenv().ESPHealth and 15 or 2))
                            data.Distance.Text = "[" .. formatDistance(distance) .. "]"
                            data.Distance.Color = Color3.fromRGB(200, 200, 200)
                        elseif data.Distance then
                            data.Distance.Visible = false
                        end
                    else
                        -- Hide if off screen or too far
                        for _, drawing in pairs(data) do
                            if drawing then
                                drawing.Visible = false
                            end
                        end
                    end
                else
                    -- Hide if dead
                    if ESPObjects[player] then
                        for _, drawing in pairs(ESPObjects[player]) do
                            if drawing then
                                drawing.Visible = false
                            end
                        end
                    end
                end
            end
        end
    end)
    
    if not success then
        warn("[Xorfhook ESP] Error: " .. tostring(err))
    end
end)

-- Store connection for cleanup
getgenv().XorfhookESPConnection = connection
getgenv().XorfhookESPCleanup = cleanupESP

-- Auto-cleanup on script re-execution
if getgenv().XorfhookESPOldCleanup then
    pcall(getgenv().XorfhookESPOldCleanup)
end
getgenv().XorfhookESPOldCleanup = cleanupESP
