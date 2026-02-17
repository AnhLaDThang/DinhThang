--// ================================
--//  DINHTHANG HUB | FINAL SMART PRO
--// ================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local lp = Players.LocalPlayer

-- SETTINGS
local ESP_SIZE = 13
local HEALTHBAR_WIDTH = 2
local HEALTHBAR_HEIGHT = 22
local AIM_FOV = 180
local AIM_SMOOTH = 0.65     -- độ dính aim
local AIM_PART = "Head"

ESP_ENABLED = false
AIM_ENABLED = false

-- ================= GUI =================
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "DinhThangHub"
gui.ResetOnSpawn = false

local floatBtn = Instance.new("TextButton", gui)
floatBtn.Size = UDim2.new(0,45,0,45)
floatBtn.Position = UDim2.new(0.03,0,0.5,0)
floatBtn.Text = "DT"
floatBtn.BackgroundColor3 = Color3.fromRGB(20,20,20)
floatBtn.TextColor3 = Color3.fromRGB(255,255,255)
floatBtn.Font = Enum.Font.GothamBold
floatBtn.TextSize = 18
floatBtn.BorderSizePixel = 0
floatBtn.Active = true
floatBtn.Draggable = true
Instance.new("UICorner", floatBtn).CornerRadius = UDim.new(1,0)

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0,240,0,170)
main.Position = UDim2.new(0.6,0,0.25,0)
main.BackgroundColor3 = Color3.fromRGB(22,22,22)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Visible = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0,18)

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1,0,0,38)
title.BackgroundTransparency = 1
title.Text = "DinhThang - HUB 😈🔥"
title.Font = Enum.Font.GothamBold
title.TextSize = 17
title.TextStrokeTransparency = 0.4
title.TextColor3 = Color3.fromRGB(255,0,0)

local function createBtn(text,y)
    local btn = Instance.new("TextButton", main)
    btn.Size = UDim2.new(0.88,0,0,40)
    btn.Position = UDim2.new(0.06,0,y,0)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(55,55,55)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,14)
    return btn
end

local espBtn = createBtn("ESP : OFF",0.28)
local aimBtn = createBtn("AIMBOT : OFF",0.58)

espBtn.MouseButton1Click:Connect(function()
    ESP_ENABLED = not ESP_ENABLED
    espBtn.Text = ESP_ENABLED and "ESP : ON" or "ESP : OFF"
    espBtn.BackgroundColor3 = ESP_ENABLED and Color3.fromRGB(0,170,100) or Color3.fromRGB(55,55,55)
end)

aimBtn.MouseButton1Click:Connect(function()
    AIM_ENABLED = not AIM_ENABLED
    aimBtn.Text = AIM_ENABLED and "AIMBOT : ON" or "AIMBOT : OFF"
    aimBtn.BackgroundColor3 = AIM_ENABLED and Color3.fromRGB(170,0,0) or Color3.fromRGB(55,55,55)
end)

floatBtn.MouseButton1Click:Connect(function()
    main.Visible = not main.Visible
end)

-- ================= RAINBOW TITLE =================
local hue = 0
RunService.RenderStepped:Connect(function()
    hue = hue + 0.0015
    if hue > 1 then hue = 0 end
    title.TextColor3 = Color3.fromHSV(hue,1,1)
end)

-- ================= UTILS =================
local function isAlive(char)
    local hum = char:FindFirstChild("Humanoid")
    return hum and hum.Health > 0
end

local function isEnemy(plr)
    if not lp.Team or not plr.Team then return true end
    return plr.Team ~= lp.Team
end

local function getTeamColor(plr)
    if plr.Team and plr.Team.TeamColor then
        return plr.Team.TeamColor.Color
    end
    return Color3.fromRGB(255,255,255)
end

-- ================= HIGHLIGHT =================
local function applyHighlight(plr)
    if not plr.Character then return end
    local char = plr.Character
    if char:FindFirstChild("DT_Highlight") then return end

    local hl = Instance.new("Highlight")
    hl.Name = "DT_Highlight"
    hl.FillTransparency = 1
    hl.OutlineTransparency = 0.12
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = char
end

local function removeHighlight(plr)
    if plr.Character and plr.Character:FindFirstChild("DT_Highlight") then
        plr.Character.DT_Highlight:Destroy()
    end
end

-- ================= ESP =================
local espCache = {}

local function createESP(plr)
    if plr == lp then return end

    local name = Drawing.new("Text")
    name.Size = ESP_SIZE
    name.Center = true
    name.Outline = true
    name.OutlineColor = Color3.new(0,0,0)

    local health = Drawing.new("Square")
    health.Filled = true

    espCache[plr] = {name=name, health=health}

    if plr.Character then
        applyHighlight(plr)
    end
end

local function removeESP(plr)
    if espCache[plr] then
        for _,v in pairs(espCache[plr]) do
            v:Remove()
        end
        espCache[plr] = nil
    end
    removeHighlight(plr)
end

for _,p in pairs(Players:GetPlayers()) do
    if p ~= lp then createESP(p) end
    if p.Character then applyHighlight(p) end
    p.CharacterAdded:Connect(function()
        task.wait(0.3)
        applyHighlight(p)
    end)
end

Players.PlayerAdded:Connect(function(plr)
    createESP(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.3)
        applyHighlight(plr)
    end)
end)

Players.PlayerRemoving:Connect(removeESP)

-- ================= SMART STICKY AIM =================
local currentTarget = nil
local lastLook = nil
local swipeThreshold = 0.12 -- độ vuốt để đổi target
local canSwitch = false

local function wallCheck(targetPos, targetChar)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {lp.Character, targetChar}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local ray = Workspace:Raycast(Camera.CFrame.Position, (targetPos - Camera.CFrame.Position), rayParams)
    return ray == nil
end

local function getNewTarget()
    local closest = nil
    local minDist = AIM_FOV
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= lp 
        and (not lp.Team or not plr.Team or plr.Team ~= lp.Team)
        and plr.Character and plr.Character:FindFirstChild(AIM_PART)
        and isAlive(plr.Character) then

            local part = plr.Character[AIM_PART]
            local pos, onscreen = Camera:WorldToViewportPoint(part.Position)
            if onscreen then
                local dist = (Vector2.new(pos.X,pos.Y) - center).Magnitude
                if dist < minDist and wallCheck(part.Position, plr.Character) then
                    minDist = dist
                    closest = plr
                end
            end
        end
    end
    return closest
end

-- ================= MAIN LOOP =================
RunService.RenderStepped:Connect(function()
    -- ESP LOOP
    for plr,data in pairs(espCache) do
        local char = plr.Character
        if ESP_ENABLED and char and char:FindFirstChild("HumanoidRootPart") and isAlive(char) then
            local hrp = char.HumanoidRootPart
            local hum = char:FindFirstChild("Humanoid")
            local pos, onscreen = Camera:WorldToViewportPoint(hrp.Position)

            if onscreen then
                local color = getTeamColor(plr)

                data.name.Visible = true
                data.name.Text = plr.Name
                data.name.Color = color
                data.name.Position = Vector2.new(pos.X,pos.Y-34)

                if hum then
                    local hpPercent = hum.Health / hum.MaxHealth
                    data.health.Visible = true
                    if hpPercent > 0.3 then
                        data.health.Color = Color3.fromRGB(0,255,0)
                    else
                        data.health.Color = Color3.fromRGB(255,0,0)
                    end
                    data.health.Size = Vector2.new(HEALTHBAR_WIDTH, HEALTHBAR_HEIGHT * hpPercent)
                    data.health.Position = Vector2.new(pos.X-16,pos.Y-11 + (HEALTHBAR_HEIGHT - HEALTHBAR_HEIGHT*hpPercent))
                end

                if char:FindFirstChild("DT_Highlight") then
                    char.DT_Highlight.OutlineColor = color
                    char.DT_Highlight.Enabled = true
                end
            else
                data.name.Visible = false
                data.health.Visible = false
            end
        else
            data.name.Visible = false
            data.health.Visible = false
        end
    end

    -- AIM LOOP
    if not AIM_ENABLED then
        currentTarget = nil
        lastLook = nil
        return
    end

    local camCF = Camera.CFrame

    -- detect swipe
    if lastLook then
        local delta = (camCF.LookVector - lastLook).Magnitude
        if delta > swipeThreshold then
            canSwitch = true
        end
    end
    lastLook = camCF.LookVector

    if not currentTarget then
        currentTarget = getNewTarget()
    elseif canSwitch then
        currentTarget = getNewTarget()
        canSwitch = false
    end

    if currentTarget and currentTarget.Character 
    and currentTarget.Character:FindFirstChild(AIM_PART)
    and isAlive(currentTarget.Character) then
        local part = currentTarget.Character[AIM_PART]
        local aimCF = CFrame.new(camCF.Position, part.Position)
        Camera.CFrame = camCF:Lerp(aimCF, AIM_SMOOTH)
    else
        currentTarget = nil
    end
end) 
