--[[
    clauderepk
    ROCKET Piggy Menu: ESP + Item Menu + Walk-to-Item
    Author: Rocket Way
    Date: 20.05.2026
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LP = Players.LocalPlayer

local CFG = {
    ESP_PIGGY   = true,
    ESP_BOTS    = true,
    ESP_ITEMS   = true,
    ESP_PLAYERS = true,
    WALK_SPEED  = 22,
    ARRIVE_DIST = 3,
    TIMEOUT     = 15,
}

local PIGGY_NAMES = {"Piggy","PiggyBot","PiggyClone","Piggy_AI"}
local BOT_NAMES   = {"Tigry","Zizzy","Pony","Raze","Georgie","Memory","Giraffy","Pandy","MrP","Kolie","Budgey","Filip","Kraxicorde","Grandmother","Willow"}
local ITEM_KEYWORDS = {"Key","Battery","Weapon","Gun","Knife","Bat","Crowbar","Hammer","Plank","Coil","BlueKey","GreenKey","RedKey","OrangeKey","PurpleKey","WhiteKey","YellowKey","BlackKey","PinkKey","CyanKey","MultiKey","Radio","Rope","Wrench","Screwdriver"}

local function notify(t, x)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title=t, Text=x, Duration=2})
    end)
end

local espCache = {}
local function addESP(part, color, name)
    if espCache[part] then return end
    local bb = Instance.new("BillboardGui")
    bb.Name = "clauderepk_ESP"
    bb.Size = UDim2.new(0,200,0,50)
    bb.AlwaysOnTop = true
    bb.StudsOffset = Vector3.new(0,3,0)
    bb.Parent = part
    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1,0,1,0)
    tl.BackgroundTransparency = 1
    tl.Text = name
    tl.TextColor3 = color
    tl.TextStrokeTransparency = 0
    tl.TextScaled = true
    tl.Parent = bb
    espCache[part] = bb
end

local function clearESP()
    for p,b in pairs(espCache) do
        if b and b.Parent then b:Destroy() end
    end
    espCache = {}
end

local function getRoot(model)
    if not model or not model:IsA("Model") then return nil end
    return model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("UpperTorso")
        or model:FindFirstChild("Torso")
        or model.PrimaryPart
end

local function updateESP()
    if CFG.ESP_PIGGY then
        for _,o in ipairs(workspace:GetChildren()) do
            if o:IsA("Model") and table.find(PIGGY_NAMES, o.Name) then
                local r = getRoot(o)
                if r then addESP(r, Color3.fromRGB(255,0,0), "PIGGY") end
            end
        end
    end
    if CFG.ESP_BOTS then
        for _,o in ipairs(workspace:GetChildren()) do
            if o:IsA("Model") and table.find(BOT_NAMES, o.Name) then
                local r = getRoot(o)
                if r then addESP(r, Color3.fromRGB(255,100,0), o.Name) end
            end
        end
    end
    if CFG.ESP_PLAYERS then
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                local r = getRoot(plr.Character)
                if r then addESP(r, Color3.fromRGB(0,255,0), plr.Name) end
            end
        end
    end
    if CFG.ESP_ITEMS then
        for _,o in ipairs(workspace:GetDescendants()) do
            if o:IsA("BasePart") then
                for _,kw in ipairs(ITEM_KEYWORDS) do
                    if o.Name:find(kw) then
                        addESP(o, Color3.fromRGB(0,200,255), o.Name)
                        break
                    end
                end
            end
        end
    end
end

local function scanItems()
    local list, seen = {}, {}
    for _,o in ipairs(workspace:GetDescendants()) do
        if o:IsA("BasePart") then
            for _,kw in ipairs(ITEM_KEYWORDS) do
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

local walking = false
local function walkTo(target)
    if walking then return end
    walking = true
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then walking = false; return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then walking = false; return end

    local oldSpeed = hum.WalkSpeed
    hum.WalkSpeed = CFG.WALK_SPEED
    local start = tick()
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not target or not target.Parent then
            conn:Disconnect(); hum.WalkSpeed = oldSpeed; walking = false
            notify("clauderepk", "Предмет исчез"); return
        end
        if tick() - start > CFG.TIMEOUT then
            conn:Disconnect(); hum.WalkSpeed = oldSpeed; walking = false
            notify("clauderepk", "Не добрался"); return
        end
        if not char.Parent or not char:FindFirstChild("HumanoidRootPart") then
            conn:Disconnect(); walking = false; return
        end
        local hrp = char.HumanoidRootPart
        local dist = (target.Position - hrp.Position).Magnitude
        if dist <= CFG.ARRIVE_DIST then
            hum:MoveTo(hrp.Position)
            local prompt = target:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then pcall(function() fireproximityprompt(prompt) end) end
            local cd = target:FindFirstChildWhichIsA("ClickDetector", true)
            if cd then pcall(function() fireclickdetector(cd) end) end
            pcall(function()
                firetouchinterest(hrp, target, 0)
                task.wait(0.05)
                firetouchinterest(hrp, target, 1)
            end)
            conn:Disconnect(); hum.WalkSpeed = oldSpeed; walking = false
            notify("clauderepk", "Подобрал: " .. target.Name); return
        end
        hum:MoveTo(target.Position)
    end)
end

local function buildGUI()
    local screen = Instance.new("ScreenGui")
    screen.Name = "clauderepk_Menu"
    screen.ResetOnSpawn = false
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local ok = pcall(function() screen.Parent = CoreGui end)
    if not ok then screen.Parent = LP:WaitForChild("PlayerGui") end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 320, 0, 420)
    frame.Position = UDim2.new(0, 20, 0, 80)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screen

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 36)
    title.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    title.BorderSizePixel = 0
    title.Text = "clauderepk | PIGGY MENU"
    title.TextColor3 = Color3.fromRGB(0, 200, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Parent = frame
    local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0,10); tc.Parent = title

    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.new(0, 140, 0, 30)
    refreshBtn.Position = UDim2.new(0, 10, 0, 44)
    refreshBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
    refreshBtn.BorderSizePixel = 0
    refreshBtn.Text = "Обновить список"
    refreshBtn.TextColor3 = Color3.fromRGB(255,255,255)
    refreshBtn.Font = Enum.Font.Gotham
    refreshBtn.TextSize = 13
    refreshBtn.Parent = frame
    local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0,6); rc.Parent = refreshBtn

    local tpBtn = Instance.new("TextButton")
    tpBtn.Size = UDim2.new(0, 140, 0, 30)
    tpBtn.Position = UDim2.new(0, 160, 0, 44)
    tpBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
    tpBtn.BorderSizePixel = 0
    tpBtn.Text = "Идти к ближайшему"
    tpBtn.TextColor3 = Color3.fromRGB(255,255,255)
    tpBtn.Font = Enum.Font.Gotham
    tpBtn.TextSize = 13
    tpBtn.Parent = frame
    local tpc = Instance.new("UICorner"); tpc.CornerRadius = UDim.new(0,6); tpc.Parent = tpBtn

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -90)
    scroll.Position = UDim2.new(0, 10, 0, 82)
    scroll.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 6
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.Parent = frame
    local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0,6); sc.Parent = scroll

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    local function refreshList()
        for _,c in ipairs(scroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        local items = scanItems()
        scroll.CanvasSize = UDim2.new(0, 0, 0, #items * 34 + 8)
        for i, part in ipairs(items) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -8, 0, 30)
            btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
            btn.BorderSizePixel = 0
            btn.Text = "  " .. part.Name
            btn.TextColor3 = Color3.fromRGB(0, 220, 255)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 13
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.LayoutOrder = i
            btn.Parent = scroll
            local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,5); bc.Parent = btn
            btn.MouseButton1Click:Connect(function()
                notify("clauderepk", "Иду к: " .. part.Name)
                walkTo(part)
            end)
        end
    end

    refreshBtn.MouseButton1Click:Connect(refreshList)
    tpBtn.MouseButton1Click:Connect(function()
        local items = scanItems()
        if #items == 0 then notify("clauderepk", "Предметов нет"); return end
        local char = LP.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local hrp = char.HumanoidRootPart
        local best, bd = nil, math.huge
        for _,p in ipairs(items) do
            local d = (hrp.Position - p.Position).Magnitude
            if d < bd then bd = d; best = p end
        end
        if best then
            notify("clauderepk", "Ближайший: " .. best.Name)
            walkTo(best)
        end
    end)

    refreshList()
    task.spawn(function()
        while screen.Parent do
            task.wait(3)
            refreshList()
        end
    end)

    return screen
end

RunService.RenderStepped:Connect(function()
    updateESP()
end)

LP.CharacterAdded:Connect(function()
    task.wait(1)
    clearESP()
end)

buildGUI()
notify("clauderepk", "Меню загружено. Кликай по предмету.")
print("[clauderepk] loaded.")
