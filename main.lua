local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local autoFarmEnabled = false
local floatSpeed = 30 -- Süzülme hızı (İhtiyaca göre değiştirebilirsin)

-- Eski GUI varsa temizle
if player:WaitForChild("PlayerGui"):FindFirstChild("M11_Gui") then
    player.PlayerGui.M11_Gui:Destroy()
end

-- GUI Oluşturma
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "M11_Gui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 180, 0, 110)
Frame.Position = UDim2.new(0.1, 0, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "M11 Float Farm"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = Frame

local Button = Instance.new("TextButton")
Button.Size = UDim2.new(0.8, 0, 0, 40)
Button.Position = UDim2.new(0.1, 0, 0.45, 0)
Button.Text = "Auto Farm: OFF"
Button.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
Button.TextColor3 = Color3.fromRGB(255, 255, 255)
Button.Font = Enum.Font.SourceSansBold
Button.TextSize = 14
Button.Parent = Frame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = Button

---------------------------------------------------
-- NOCLIP (Duvarlara Takılmamak İçin)
---------------------------------------------------
RunService.Stepped:Connect(function()
    if autoFarmEnabled and player.Character then
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

---------------------------------------------------
-- EN YAKIN PARAYI BULMA
---------------------------------------------------
local function getClosestCoin()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local closest = nil
    local minDist = math.huge

    for _, obj in pairs(workspace:GetDescendants()) do
        local nameLower = string.lower(obj.Name)
        if (string.find(nameLower, "candy") or string.find(nameLower, "coin") or string.find(nameLower, "container")) then
            local cf = nil
            if obj:IsA("BasePart") and obj.Transparency < 1 and obj.Parent ~= nil then
                cf = obj.CFrame
            elseif obj:IsA("Model") and obj.Parent ~= nil then
                cf = obj:GetPivot()
            end

            if cf then
                local dist = (hrp.Position - cf.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = {Object = obj, CFrame = cf}
                end
            end
        end
    end
    return closest
end

---------------------------------------------------
-- BUTON MANTIĞI
---------------------------------------------------
Button.MouseButton1Click:Connect(function()
    autoFarmEnabled = not autoFarmEnabled
    if autoFarmEnabled then
        Button.Text = "Auto Farm: ON"
        Button.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    else
        Button.Text = "Auto Farm: OFF"
        Button.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
end)

---------------------------------------------------
-- YATAY FLOAT FARM DÖNGÜSÜ
---------------------------------------------------
task.spawn(function()
    while task.wait(0.1) do
        if autoFarmEnabled then
            pcall(function()
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                
                if hrp then
                    local target = getClosestCoin()
                    if target and target.Object and target.Object.Parent and target.Object.Transparency < 1 then
                        local distance = (hrp.Position - target.CFrame.Position).Magnitude
                        local duration = distance / floatSpeed

                        -- Yumuşak yatay süzülme (Tween)
                        local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
                        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = target.CFrame})
                        tween:Play()

                        -- Paraya ulaşana kadar yumuşakça süzül
                        local elapsed = 0
                        while elapsed < duration and autoFarmEnabled and target.Object.Parent and target.Object.Transparency < 1 do
                            task.wait(0.05)
                            elapsed = elapsed + 0.05
                        end
                        tween:Cancel()

                        -- Paranın üstüne varıp aldıktan sonra 0.1 saniye bekle
                        if autoFarmEnabled then
                            task.wait(0.1) 
                        end
                    end
                end
            end)
        end
    end
end)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Monitor collection limit and auto-reset when full (50/50)
task.spawn(function()
    pcall(function()
        local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
        local gameplay = remotes and remotes:WaitForChild("Gameplay", 5)
        local coinsStartedEvent = gameplay and gameplay:WaitForChild("CoinsStarted", 5)

        if coinsStartedEvent then
            coinsStartedEvent.OnClientEvent:Connect(function(data)
                if type(data) == "table" then
                    for _, info in pairs(data) do
                        if type(info) == "table" and info.CollectedAmount and info.CollectionLimit then
                            -- If collected amount reaches or exceeds the limit (50)[span_1](start_span)[span_1](end_span)
                            if info.CollectedAmount >= info.CollectionLimit then
                                local char = player.Character
                                if char and char:FindFirstChild("HumanoidRootPart") then
                                    -- Auto reset character
                                    char:BreakJoints()
                                    task.wait(3) -- Wait safely for respawn
                                end
                            end
                        end
                    end
                end
            end)
        end
    end)
end)
