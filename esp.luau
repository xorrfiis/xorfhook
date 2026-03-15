local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ESPObjects = {}

RunService.RenderStepped:Connect(function()

    if not getgenv().ESPEnabled then
        for _,v in pairs(ESPObjects) do
            v.Visible = false
        end
        return
    end

    for _,player in pairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then

            if not ESPObjects[player] then
                local text = Drawing.new("Text")
                text.Size = 13
                text.Center = true
                text.Outline = true
                ESPObjects[player] = text
            end

            local head = player.Character.Head
            local pos, visible = workspace.CurrentCamera:WorldToViewportPoint(head.Position)

            local esp = ESPObjects[player]

            if visible then
                esp.Visible = true
                esp.Position = Vector2.new(pos.X, pos.Y)
                esp.Text = player.Name
                esp.Color = getgenv().ESPColor or Color3.fromRGB(255,0,0)
            else
                esp.Visible = false
            end
        end
    end

end)
