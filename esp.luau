local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

-- Initialize global settings safely
getgenv().ESPEnabled = getgenv().ESPEnabled or false
getgenv().ESPColor = getgenv().ESPColor or Color3.fromRGB(255, 0, 0)

local ESPObjects = {}
local connection

-- Cleanup function
local function cleanupESP()
    for player, drawing in pairs(ESPObjects) do
        if drawing and typeof(drawing.Remove) == "function" then
            pcall(function() drawing:Remove() end)
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

-- Main ESP loop
connection = RunService.RenderStepped:Connect(function()
    local success, err = pcall(function()
        -- Disable all ESP if turned off
        if not getgenv().ESPEnabled then
            for _, v in pairs(ESPObjects) do
                if v then
                    v.Visible = false
                end
            end
            return
        end

        -- Clean up disconnected players
        for player in pairs(ESPObjects) do
            if not player or not player.Parent then
                if ESPObjects[player] then
                    pcall(function() ESPObjects[player]:Remove() end)
                    ESPObjects[player] = nil
                end
            end
        end

        -- Update/create ESP for valid players
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= lp and player.Character then
                local head = player.Character:FindFirstChild("Head")
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                
                if head and humanoid and humanoid.Health > 0 then
                    -- Create ESP object if needed
                    if not ESPObjects[player] then
                        local text = createDrawing("Text")
                        if text then
                            text.Size = 13
                            text.Center = true
                            text.Outline = true
                            text.Font = 2 -- UI font
                            ESPObjects[player] = text
                        end
                    end

                    local esp = ESPObjects[player]
                    if esp then
                        local pos, visible = workspace.CurrentCamera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))

                        if visible then
                            esp.Visible = true
                            esp.Position = Vector2.new(pos.X, pos.Y - 20)
                            esp.Text = player.Name
                            esp.Color = getgenv().ESPColor or Color3.fromRGB(255, 0, 0)
                            esp.Transparency = 1
                        else
                            esp.Visible = false
                        end
                    end
                else
                    -- Hide if dead or no head
                    if ESPObjects[player] then
                        ESPObjects[player].Visible = false
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
