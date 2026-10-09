--[[
    clauderepk v1.1
    ROCKET Piggy Menu: ESP + Cheats + Item Teleport
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
    ESP_Piggy = true,
    ESP_Bots = true,
    ESP_Players = true,
    ESP_Items = true,
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

-- === ESP (обводка + имя) ===
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

-- === ТЕЛЕПОРТ К ПРЕДМЕТУ С ВОЗВРАТОМ ===
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
    notify("clauderepk", "Забрал: " .. target.Name .. " — вернулся")
end

-- === GUI ===
local function buildGUI()
    local screen = Instance.new("ScreenGui")
    screen.Name = "clauderepk_v11"
    screen.ResetOnSpawn = false
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local ok = pcall(function() screen.Parent = CoreGui end)
    if not ok then screen.Parent = LP:WaitForChild("PlayerGui") end

    -- Компактная главная рамка
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 260, 0, 300)
    frame.Position = UDim2.new(0, 15, 0, 70)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screen

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    -- Заголовок
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    title.BorderSizePixel = 0
    title.Text = "clauderepk v1.1"
    title.TextColor3 = Color3.fromRGB(0, 200, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.Parent = frame
    local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0,8); tc.Parent = title

    -- Кнопка свернуть
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 22, 0, 22)
    minBtn.Position = UDim2.new(1, -26, 0, 4)
    minBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    minBtn.BorderSizePixel = 0
    minBtn.Text = "—"
    minBtn.TextColor3 = Color3.fromRGB(255,255,255)
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 14
    minBtn.Parent = title
    local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0,4); mc.Parent = minBtn

    -- Контент
    local content = Instance.new("Frame")
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

    -- Функция создания страницы
    local function makePage(name, titleText)
        local page = Instance.new("ScrollingFrame")
        page.Name = name
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 4
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.Visible = false
        page.Parent = pages

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 3)
        layout.Parent = page

        return page
    end

    local pageESP = makePage("ESP", "ESP")
    local pageCheat = makePage("Cheat", "Чит")
    local pageItems = makePage("Items", "Предметы")

    -- Кнопка таба
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
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,4); bc.Parent = btn
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

    -- Кнопка-переключатель
    local function makeToggle(parent, text, getState, setState)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -8, 0, 26)
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        btn.BorderSizePixel = 0
        btn.Text = "  " .. text
        btn.TextColor3 = getState() and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(180, 180, 180)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = parent
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,4); bc.Parent = btn

        btn.MouseButton1Click:Connect(function()
            setState(not getState())
            btn.TextColor3 = getState() and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(180, 180, 180)
        end)
        return btn
    end

    -- ESP раздел
    makeToggle(pageESP, "Piggy", function() return State.ESP_Piggy end, function(v) State.ESP_Piggy = v end)
    makeToggle(pageESP, "Боты", function() return State.ESP_Bots end, function(v) State.ESP_Bots = v end)
    makeToggle(pageESP, "Игроки", function() return State.ESP_Players end, function(v) State.ESP_Players = v end)
    makeToggle(pageESP, "Предметы", function() return State.ESP_Items end, function(v) State.ESP_Items = v end)

    -- Чит раздел
    makeToggle(pageCheat, "Fly", function() return State.Fly end, function(v)
        State.Fly = v
        if v then startFly() else stopFly() end
    end)
    makeToggle(pageCheat, "Noclip (сквозь стены)", function() return State.Noclip end, function(v)
        State.Noclip = v
        if v then startNoclip() else stopNoclip() end
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
    local rbc = Instance.new("UICorner"); rbc.CornerRadius = UDim.new(0,4); rbc.Parent = refreshBtn

    local listFrame = Instance.new("Frame")
    listFrame.Size = UDim2.new(1, -8, 0, 180)
    listFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
    listFrame.BorderSizePixel = 0
    listFrame.Parent = pageItems
    local lfc = Instance.new("UICorner"); lfc.CornerRadius = UDim.new(0,4); lfc.Parent = listFrame

    local listScroll = Instance.new("ScrollingFrame")
    listScroll.Size = UDim2.new(1, 0, 1, 0)
    listScroll.BackgroundTransparency = 1
    listScroll.BorderSizePixel = 0
    listScroll.ScrollBarThickness = 4
    listScroll.CanvasSize = UDim2.new(0,0,0,0)
    listScroll.Parent = listFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 2)
    listLayout.Parent = listScroll

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
            local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,3); bc.Parent = btn
            btn.MouseButton1Click:Connect(function()
                teleportToItem(part)
            end)
        end
    end

    refreshBtn.MouseButton1Click:Connect(refreshItems)
    refreshItems()

    -- Свернуть
    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            frame.Size = UDim2.new(0, 260, 0, 30)
            content.Visible = false
        else
            frame.Size = UDim2.new(0, 260, 0, 300)
            content.Visible = true
        end
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
    if State.Fly then stopFly(); if State.Fly then startFly() end end
    if State.Noclip then stopNoclip(); startNoclip() end
end)

-- === СТАРТ ===
buildGUI()
notify("clauderepk v1.1", "Меню загружено. 3 раздела.")
print("[clauderepk v1.1] loaded.")
