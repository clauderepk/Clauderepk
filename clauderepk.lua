--[[
    clauderepk v1.2
    ROCKET Piggy Menu: ESP + Cheats + Item Teleport + Collapse + FlySpeed Slider
    Author: Rocket Way
    Date: 20.05.2026
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer

-- === СОСТОЯНИЕ ===
local State = {
    ESP_Piggy = false,
    ESP_Bots = false,
    ESP_Players = false,
    ESP_Items = false,
    Fly = false,
    Noclip = false,
    FlySpeed = 60,
}

-- === СПИСКИ ===
local PIGGY_NAMES = {"Piggy","PiggyBot","PiggyClone","Piggy_AI"}
local BOT_NAMES   = {"Tigry","Zizzy","Pony","Raze","Georgie","Memory","Giraffy","Pandy","MrP","Kolie","Budgey","Filip","Kraxicorde","Grandmother","Willow"}
local ITEM_KEYWORDS = {"Key","Battery","Weapon","Gun","Knife","Bat","Crowbar","Hammer","Plank","Coil","BlueKey","GreenKey","RedKey","OrangeKey","PurpleKey","WhiteKey","YellowKey","BlackKey","PinkKey","CyanKey","MultiKey","Radio","Rope","Wrench","Screwdriver"}

-- === УТИЛИТЫ ===
local function notify(t, x)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title=t, Text=x, Duration=2})
    end)
end

local function getRoot(model)
    if not model or not model:IsA("Model") then return nil end
    return model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("UpperTorso")
        or model:FindFirstChild("Torso")
        or model.PrimaryPart
end

-- === ESP ===
local espCache = {}
local function addESP(part, color, name)
    if espCache[part] then return end
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "clauderepk_Box"
    box.Size = part.Size + Vector3.new(0.2, 0.2, 0.2)
    box.Adornee = part
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Transparency = 0.5
    box.Color3 = color
    box.Parent = part

    local bb = Instance.new("BillboardGui")
    bb.Name = "clauderepk_Label"
    bb.Size = UDim2.new(0, 120, 0, 24)
    bb.AlwaysOnTop = true
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.Parent = part

    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.Text = name
    tl.TextColor3 = color
    tl.TextStrokeTransparency = 0
    tl.TextScaled = true
    tl.Font = Enum.Font.GothamBold
    tl.Parent = bb

    espCache[part] = {box = box, bb = bb}
end

local function clearESP()
    for p, data in pairs(espCache) do
        if data.box then data.box:Destroy() end
        if data.bb then data.bb:Destroy() end
    end
    espCache = {}
end

local function updateESP()
    if State.ESP_Piggy then
        for _, o in ipairs(workspace:GetChildren()) do
            if o:IsA("Model") and table.find(PIGGY_NAMES, o.Name) then
                local r = getRoot(o)
                if r then addESP(r, Color3.fromRGB(255, 0, 0), "PIGGY") end
            end
        end
    end
    if State.ESP_Bots then
        for _, o in ipairs(workspace:GetChildren()) do
            if o:IsA("Model") and table.find(BOT_NAMES, o.Name) then
                local r = getRoot(o)
                if r then addESP(r, Color3.fromRGB(255, 120, 0), o.Name) end
            end
        end
    end
    if State.ESP_Players then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                local r = getRoot(plr.Character)
                if r then addESP(r, Color3.fromRGB(0, 255, 0), plr.Name) end
            end
        end
    end
    if State.ESP_Items then
        for _, o in ipairs(workspace:GetDescendants()) do
            if o:IsA("BasePart") then
                for _, kw in ipairs(ITEM_KEYWORDS) do
                    if o.Name:find(kw) then
                        addESP(o, Color3.fromRGB(0, 200, 255), o.Name)
                        break
                    end
                end
            end
        end
    end
end

-- === FLY ===
local flyConn
local function startFly()
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local bodyVel = Instance.new("BodyVelocity")
    bodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bodyVel.Velocity = Vector3.zero
    bodyVel.Parent = hrp

    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bodyGyro.P = 1e4
    bodyGyro.Parent = hrp

    flyConn = RunService.RenderStepped:Connect(function()
        if not char.Parent then return end
        local cam = workspace.CurrentCamera
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0, 1, 0) end
        bodyVel.Velocity = move * State.FlySpeed
        bodyGyro.CFrame = cam.CFrame
    end)
end

local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    local char = LP.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, v in ipairs(hrp:GetChildren()) do
                if v:IsA("BodyVelocity") or v:IsA("BodyGyro") then v:Destroy() end
            end
        end
    end
end

-- === NOCLIP ===
local noclipConn
local function startNoclip()
    noclipConn = RunService.Stepped:Connect(function()
        local char = LP.Character
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then
                p.CanCollide = false
            end
        end
    end)
end

local function stopNoclip()
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
end

-- === ТЕЛЕПОРТ ===
local function scanItems()
    local list, seen = {}, {}
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("BasePart") then
            for _, kw in ipairs(ITEM_KEYWORDS) do
                if o.Name:find(kw) then
                    if not seen[o] then
                        seen[o] = true
                        table.insert(list, o)
                    end
                    break
                end
            end
        end
    end
    return list
end

local function teleportToItem(target)
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local origin = hrp.CFrame
    hrp.CFrame = CFrame.new(target.Position + Vector3.new(0, 3, 0))
    task.wait(0.15)

    local prompt = target:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then pcall(function() fireproximityprompt(prompt) end) end
    local cd = target:FindFirstChildWhichIsA("ClickDetector", true)
    if cd then pcall(function() fireclickdetector(cd) end) end
    pcall(function()
        firetouchinterest(hrp, target, 0)
        task.wait(0.05)
        firetouchinterest(hrp, target, 1)
    end)

    task.wait(0.1)
    hrp.CFrame = origin
    notify("clauderepk", "Забрал: " .. target.Name)
end

-- === GUI ===
local function buildGUI()
    local screen = Instance.new("ScreenGui")
    screen.Name = "clauderepk_v12"
    screen.ResetOnSpawn = false
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local ok = pcall(function() screen.Parent = CoreGui end)
    if not ok then screen.Parent = LP:WaitForChild("PlayerGui") end

    -- Главная рамка
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 260, 0, 320)
    frame.Position = UDim2.new(0, 15, 0, 70)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screen
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 8); corner.Parent = frame

    -- Заголовок
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    title.BorderSizePixel = 0
    title.Text = "clauderepk v1.2"
    title.TextColor3 = Color3.fromRGB(0, 200, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.Parent = frame
    local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 8); tc.Parent = title

    -- Кнопка свернуть (полоска)
    local collapseBtn = Instance.new("TextButton")
    collapseBtn.Size = UDim2.new(0, 24, 0, 22)
    collapseBtn.Position = UDim2.new(1, -28, 0, 4)
    collapseBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
    collapseBtn.BorderSizePixel = 0
    collapseBtn.Text = "—"
    collapseBtn.TextColor3 = Color3.fromRGB(0, 200, 255)
    collapseBtn.Font = Enum.Font.GothamBold
    collapseBtn.TextSize = 16
    collapseBtn.Parent = title
    local cbc = Instance.new("UICorner"); cbc.CornerRadius = UDim.new(0, 4); cbc.Parent = collapseBtn

    -- Контент
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 1, -30)
    content.Position = UDim2.new(0, 0, 0, 30)
    content.BackgroundTransparency = 1
    content.Parent = frame

    -- Табы
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, 0, 0, 26)
    tabBar.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    tabBar.BorderSizePixel = 0
    tabBar.Parent = content
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 2)
    tabLayout.Parent = tabBar

    local pages = Instance.new("Frame")
    pages.Size = UDim2.new(1, 0, 1, -26)
    pages.Position = UDim2.new(0, 0, 0, 26)
    pages.BackgroundTransparency = 1
    pages.Parent = content

    local function makePage()
        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 4
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.Visible = false
        page.Parent = pages
        local l = Instance.new("UIListLayout"); l.Padding = UDim.new(0, 3); l.Parent = page
        return page
    end

    local pageESP = makePage()
    local pageCheat = makePage()
    local pageItems = makePage()

    local function makeTab(text, page)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 80, 1, 0)
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.Parent = tabBar
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 4); bc.Parent = btn
        btn.MouseButton1Click:Connect(function()
            pageESP.Visible = false
            pageCheat.Visible = false
            pageItems.Visible = false
            page.Visible = true
        end)
        return btn
    end

    makeTab("ESP", pageESP)
    makeTab("Чит", pageCheat)
    makeTab("Предметы", pageItems)
    pageESP.Visible = true

    -- Тумблер
    local function makeToggle(parent, text, stateKey)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -8, 0, 26)
        btn.BorderSizePixel = 0
        btn.Text = "  " .. text
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = parent
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 4); bc.Parent = btn

        local function refresh()
            if State[stateKey] then
                btn.BackgroundColor3 = Color3.fromRGB(30, 90, 50)
                btn.TextColor3 = Color3.fromRGB(0, 255, 120)
            else
                btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
                btn.TextColor3 = Color3.fromRGB(180, 180, 180)
            end
        end
        refresh()

        btn.MouseButton1Click:Connect(function()
            State[stateKey] = not State[stateKey]
            refresh()
            notify("clauderepk", text .. ": " .. (State[stateKey] and "ВКЛ" or "ВЫКЛ"))
        end)
        return btn
    end

    -- ESP
    makeToggle(pageESP, "Piggy ESP", "ESP_Piggy")
    makeToggle(pageESP, "Боты ESP", "ESP_Bots")
    makeToggle(pageESP, "Игроки ESP", "ESP_Players")
    makeToggle(pageESP, "Предметы ESP", "ESP_Items")

    -- Чит
    local flyBtn = makeToggle(pageCheat, "Fly", "Fly")
    flyBtn.MouseButton1Click:Connect(function()
        task.wait(0.01)
        if State.Fly then startFly() else stopFly() end
    end)

    local noclipBtn = makeToggle(pageCheat, "Noclip (сквозь стены)", "Noclip")
    noclipBtn.MouseButton1Click:Connect(function()
        task.wait(0.01)
        if State.Noclip then startNoclip() else stopNoclip() end
    end)

    -- Слайдер FlySpeed
    local sliderLabel = Instance.new("TextLabel")
    sliderLabel.Size = UDim2.new(1, -8, 0, 22)
    sliderLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    sliderLabel.BorderSizePixel = 0
    sliderLabel.Text = "FlySpeed: " .. State.FlySpeed
    sliderLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
    sliderLabel.Font = Enum.Font.Gotham
    sliderLabel.TextSize = 12
    sliderLabel.Parent = pageCheat
    local slc = Instance.new("UICorner"); slc.CornerRadius = UDim.new(0, 4); slc.Parent = sliderLabel

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -8, 0, 12)
    sliderBg.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = pageCheat
    local sbc = Instance.new("UICorner"); sbc.CornerRadius = UDim.new(0, 6); sbc.Parent = sliderBg

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((State.FlySpeed - 10) / 290, 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg
    local sfc = Instance.new("UICorner"); sfc.CornerRadius = UDim.new(0, 6); sfc.Parent = sliderFill

    local sliderKnob = Instance.new("TextButton")
    sliderKnob.Size = UDim2.new(0, 16, 0, 16)
    sliderKnob.Position = UDim2.new((State.FlySpeed - 10) / 290, -8, 0.5, -8)
    sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderKnob.BorderSizePixel = 0
    sliderKnob.Text = ""
    sliderKnob.Parent = sliderBg
    local skc = Instance.new("UICorner"); skc.CornerRadius = UDim.new(1, 0); skc.Parent = sliderKnob

    local dragging = false
    local function updateSlider(input)
        local rel = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        local val = math.floor(10 + rel * 290)
        State.FlySpeed = val
        sliderFill.Size = UDim2.new(rel, 0, 1, 0)
        sliderKnob.Position = UDim2.new(rel, -8, 0.5, -8)
        sliderLabel.Text = "FlySpeed: " .. val
    end

    sliderKnob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    sliderKnob.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)

    -- Предметы
    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.new(1, -8, 0, 26)
    refreshBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
    refreshBtn.BorderSizePixel = 0
    refreshBtn.Text = "Обновить список"
    refreshBtn.TextColor3 = Color3.fromRGB(255,255,255)
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.TextSize = 12
    refreshBtn.Parent = pageItems
    local rbc = Instance.new("UICorner"); rbc.CornerRadius = UDim.new(0, 4); rbc.Parent = refreshBtn

    local listScroll = Instance.new("ScrollingFrame")
    listScroll.Size = UDim2.new(1, -8, 0, 200)
    listScroll.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
    listScroll.BorderSizePixel = 0
    listScroll.ScrollBarThickness = 4
    listScroll.CanvasSize = UDim2.new(0,0,0,0)
    listScroll.Parent = pageItems
    local lsc = Instance.new("UICorner"); lsc.CornerRadius = UDim.new(0, 4); lsc.Parent = listScroll
    local listLayout = Instance.new("UIListLayout"); listLayout.Padding = UDim.new(0, 2); listLayout.Parent = listScroll

    local function refreshItems()
        for _, c in ipairs(listScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        local items = scanItems()
        listScroll.CanvasSize = UDim2.new(0, 0, 0, #items * 28 + 4)
        for i, part in ipairs(items) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -4, 0, 26)
            btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
            btn.BorderSizePixel = 0
            btn.Text = part.Name
            btn.TextColor3 = Color3.fromRGB(0, 220, 255)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 11
            btn.LayoutOrder = i
            btn.Parent = listScroll
            local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 3); bc.Parent = btn
            btn.MouseButton1Click:Connect(function() teleportToItem(part) end)
        end
    end
    refreshBtn.MouseButton1Click:Connect(refreshItems)
    refreshItems()

    -- === СВОРАЧИВАНИЕ В СВИНЬЮ ===
    local pigBtn = Instance.new("TextButton")
    pigBtn.Name = "PigBtn"
    pigBtn.Size = UDim2.new(0, 60, 0, 60)
    pigBtn.Position = UDim2.new(0, 15, 0, 70)
    pigBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 200)
    pigBtn.BorderSizePixel = 0
    pigBtn.Text = "🐷"
    pigBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    pigBtn.Font = Enum.Font.GothamBold
    pigBtn.TextSize = 30
    pigBtn.Visible = false
    pigBtn.Active = true
    pigBtn.Draggable = true
    pigBtn.Parent = screen
    local pbc = Instance.new("UICorner"); pbc.CornerRadius = UDim.new(1, 0); pbc.Parent = pigBtn

    local minimized = false
    collapseBtn.MouseButton1Click:Connect(function()
        minimized = true
        frame.Visible = false
        pigBtn.Visible = true
    end)
    pigBtn.MouseButton1Click:Connect(function()
        minimized = false
        pigBtn.Visible = false
        frame.Visible = true
    end)

    return screen
end

-- === ОСНОВНОЙ ЦИКЛ ===
RunService.RenderStepped:Connect(function()
    updateESP()
end)

LP.CharacterAdded:Connect(function()
    task.wait(1)
    clearESP()
    if State.Fly then stopFly(); task.wait(0.1); if State.Fly then startFly() end end
    if State.Noclip then stopNoclip(); task.wait(0.1); if State.Noclip then startNoclip() end end
end)

-- === СТАРТ ===
buildGUI()
notify("clauderepk v1.2", "Меню загружено")
print("[clauderepk v1.2] loaded.")
