--[[
    Sirius-style auto farm UI and utility script.
    This version does NOT depend on Rayfield being reachable over the network.
    It creates a local dark UI directly in Roblox, so it is much more reliable.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local state = {
    farm = {
        Egg = false,
        Wood = false,
        Metal = false,
        Fabric = false,
    },
    event = {
        Pumpkin = false,
    },
    visuals = {
        ESP = false,
        Egg = false,
        Wood = false,
        Metal = false,
        Fabric = false,
        Pumpkin = false,
        FullBright = false,
    },
    character = {
        WalkSpeed = 16,
        JumpPower = 50,
        Scale = 1,
    },
}

local resourceColors = {
    Egg = Color3.fromRGB(255, 204, 0),
    Wood = Color3.fromRGB(126, 94, 58),
    Metal = Color3.fromRGB(170, 180, 190),
    Fabric = Color3.fromRGB(255, 255, 255),
    Pumpkin = Color3.fromRGB(255, 140, 0),
}

local function lowerName(value)
    if typeof(value) == "string" then
        return string.lower(value)
    end
    return ""
end

local function getCharacter()
    local character = LocalPlayer.Character
    if character then
        return character
    end

    local newCharacter = LocalPlayer.CharacterAdded:Wait()
    return newCharacter
end

local function getHumanoid()
    local character = getCharacter()
    if character then
        return character:FindFirstChildOfClass("Humanoid")
    end
    return nil
end

local function getRootPart()
    local character = getCharacter()
    if character then
        return character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function getBasePartFromInstance(inst)
    if not inst then
        return nil
    end
    if inst:IsA("BasePart") then
        return inst
    end

    local primary = inst:FindFirstChild("PrimaryPart")
    if primary and primary:IsA("BasePart") then
        return primary
    end

    local part = inst:FindFirstChildWhichIsA("BasePart")
    if part then
        return part
    end

    return nil
end

local function findNearestPrompt(resourceName)
    local root = getRootPart()
    if not root then
        return nil
    end

    local targetName = lowerName(resourceName)
    local bestPrompt = nil
    local bestDistance = math.huge

    for _, desc in ipairs(Workspace:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            local parent = desc.Parent
            if parent and desc.Enabled then
                local name = lowerName(parent.Name)
                if name:find(targetName) and not name:find("pumpkin") then
                    local part = getBasePartFromInstance(parent)
                    if part then
                        local dist = (part.Position - root.Position).Magnitude
                        if dist < bestDistance then
                            bestPrompt = desc
                            bestDistance = dist
                        end
                    end
                end
            end
        end
    end

    return bestPrompt
end

local function findNearestPumpkin()
    local root = getRootPart()
    if not root then
        return nil
    end

    local bestPart = nil
    local bestDistance = math.huge

    for _, desc in ipairs(Workspace:GetDescendants()) do
        local name = lowerName(desc.Name or "")
        if name:find("pumpkin") then
            local part = getBasePartFromInstance(desc)
            if part then
                local dist = (part.Position - root.Position).Magnitude
                if dist < bestDistance then
                    bestPart = part
                    bestDistance = dist
                end
            end
        end
    end

    return bestPart
end

local function getPointsCountValue()
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui then
        return 0
    end

    for _, child in ipairs(playerGui:GetDescendants()) do
        if (child:IsA("TextLabel") or child:IsA("TextBox")) and child.Name == "PointsCount" then
            local text = child.Text or "0"
            local num = tonumber((text:gsub("[^0-9]", "")))
            if num then
                return num
            end
        end
    end

    return 0
end

local function setFullBright(enabled)
    if enabled then
        Lighting.Brightness = 2
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = 1
        Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 140)
        Lighting.Ambient = Color3.fromRGB(140, 140, 140)
        Lighting.GlobalShadows = true
    end
end

local function applyCharacterSettings()
    local humanoid = getHumanoid()
    if not humanoid then
        return
    end

    humanoid.WalkSpeed = state.character.WalkSpeed
    humanoid.JumpPower = state.character.JumpPower

    local character = getCharacter()
    if character then
        for _, value in ipairs(character:GetDescendants()) do
            if value:IsA("NumberValue") then
                local name = lowerName(value.Name)
                if name:find("body") and name:find("scale") then
                    value.Value = state.character.Scale
                end
            end
        end
    end
end

local function updateVisuals()
    for _, highlight in ipairs(Workspace:GetDescendants()) do
        if highlight:IsA("Highlight") and highlight.Name == "SiriusESP" then
            highlight:Destroy()
        end
    end

    if not state.visuals.ESP then
        return
    end

    local checks = {
        Egg = { enabled = state.visuals.Egg, color = resourceColors.Egg },
        Wood = { enabled = state.visuals.Wood, color = resourceColors.Wood },
        Metal = { enabled = state.visuals.Metal, color = resourceColors.Metal },
        Fabric = { enabled = state.visuals.Fabric, color = resourceColors.Fabric },
        Pumpkin = { enabled = state.visuals.Pumpkin, color = resourceColors.Pumpkin },
    }

    for _, model in ipairs(Workspace:GetDescendants()) do
        local name = lowerName(model.Name or "")
        for key, data in pairs(checks) do
            if data.enabled and name:find(lowerName(key)) then
                local highlight = Instance.new("Highlight")
                highlight.Name = "SiriusESP"
                highlight.Adornee = model
                highlight.FillColor = data.color
                highlight.OutlineColor = data.color
                highlight.FillTransparency = 0.45
                highlight.OutlineTransparency = 0
                highlight.Parent = model
                break
            end
        end
    end
end

local function createHud()
    local gui = Instance.new("ScreenGui")
    gui.Name = "SiriusMiniHud"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Name = "Main"
    frame.Size = UDim2.new(0, 220, 0, 70)
    frame.Position = UDim2.new(0, 14, 0, 14)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(90, 120, 255)
    stroke.Thickness = 1
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -18, 0, 22)
    title.Position = UDim2.new(0, 10, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = "Collected total"
    title.Font = Enum.Font.GothamSemibold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local count = Instance.new("TextLabel")
    count.Name = "Count"
    count.Size = UDim2.new(1, -18, 0, 28)
    count.Position = UDim2.new(0, 10, 0, 30)
    count.BackgroundTransparency = 1
    count.Text = "0"
    count.Font = Enum.Font.GothamBold
    count.TextSize = 22
    count.TextColor3 = Color3.fromRGB(120, 200, 255)
    count.TextXAlignment = Enum.TextXAlignment.Left
    count.Parent = frame

    task.spawn(function()
        while task.wait(0.25) do
            count.Text = tostring(getPointsCountValue())
        end
    end)

    return gui
end

local function autoFarmLoop()
    task.spawn(function()
        while true do
            local root = getRootPart()
            if root then
                for resourceName, enabled in pairs(state.farm) do
                    if enabled then
                        local prompt = findNearestPrompt(resourceName)
                        if prompt then
                            local parent = prompt.Parent
                            local part = getBasePartFromInstance(parent)
                            if part then
                                root.CFrame = CFrame.new(part.Position + Vector3.new(0, 4, 0))
                                fireproximityprompt(prompt, 0.1)
                            end
                        end
                    end
                end

                if state.event.Pumpkin then
                    local pumpkin = findNearestPumpkin()
                    if pumpkin then
                        root.CFrame = CFrame.new(pumpkin.Position + Vector3.new(0, 3.5, 0))
                    end
                end
            end

            task.wait(0.2)
        end
    end)
end

local function createText(text)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    return label
end

local function createToggle(parent, text, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -12, 0, 30)
    container.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
    container.BorderSizePixel = 0
    container.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container

    local label = createText(text)
    label.Size = UDim2.new(1, -80, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Parent = container

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 62, 0, 20)
    button.Position = UDim2.new(1, -72, 0.5, -10)
    button.BackgroundColor3 = default and Color3.fromRGB(78, 164, 255) or Color3.fromRGB(60, 60, 64)
    button.Text = default and "ON" or "OFF"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 12
    button.BorderSizePixel = 0
    button.Parent = container

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = button

    local enabled = default
    local function refresh()
        enabled = enabled or false
        button.BackgroundColor3 = enabled and Color3.fromRGB(78, 164, 255) or Color3.fromRGB(60, 60, 64)
        button.Text = enabled and "ON" or "OFF"
        callback(enabled)
    end

    button.MouseButton1Click:Connect(function()
        enabled = not enabled
        refresh()
    end)

    refresh()
    return { Set = function(value)
        enabled = value
        refresh()
    end }
end

local function createSlider(parent, text, minValue, maxValue, defaultValue, step, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -12, 0, 46)
    container.BackgroundColor3 = Color3.fromRGB(32, 32, 36)
    container.BorderSizePixel = 0
    container.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container

    local label = createText(text)
    label.Size = UDim2.new(1, -120, 0, 18)
    label.Position = UDim2.new(0, 10, 0, 6)
    label.Parent = container

    local valueLabel = Instance.new("TextLabel")
    valueLabel.BackgroundTransparency = 1
    valueLabel.Size = UDim2.new(0, 60, 0, 18)
    valueLabel.Position = UDim2.new(1, -70, 0, 6)
    valueLabel.Text = tostring(defaultValue)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextColor3 = Color3.fromRGB(120, 200, 255)
    valueLabel.TextSize = 12
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = container

    local minus = Instance.new("TextButton")
    minus.Size = UDim2.new(0, 26, 0, 22)
    minus.Position = UDim2.new(0, 10, 0, 22)
    minus.Text = "-"
    minus.Font = Enum.Font.GothamBold
    minus.TextSize = 14
    minus.TextColor3 = Color3.fromRGB(255, 255, 255)
    minus.BackgroundColor3 = Color3.fromRGB(52, 52, 60)
    minus.BorderSizePixel = 0
    minus.Parent = container

    local plus = Instance.new("TextButton")
    plus.Size = UDim2.new(0, 26, 0, 22)
    plus.Position = UDim2.new(1, -36, 0, 22)
    plus.Text = "+"
    plus.Font = Enum.Font.GothamBold
    plus.TextSize = 14
    plus.TextColor3 = Color3.fromRGB(255, 255, 255)
    plus.BackgroundColor3 = Color3.fromRGB(52, 52, 60)
    plus.BorderSizePixel = 0
    plus.Parent = container

    local value = defaultValue

    local function setValue(newValue)
        value = math.clamp(newValue, minValue, maxValue)
        valueLabel.Text = tostring(value)
        callback(value)
    end

    minus.MouseButton1Click:Connect(function()
        setValue(value - step)
    end)

    plus.MouseButton1Click:Connect(function()
        setValue(value + step)
    end)

    setValue(defaultValue)
    return { Set = setValue }
end

local function createMenu()
    local gui = Instance.new("ScreenGui")
    gui.Name = "SiriusMenu"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = CoreGui

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 420, 0, 420)
    main.Position = UDim2.new(0.5, -210, 0.5, -210)
    main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    main.BorderSizePixel = 0
    main.Parent = gui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 14)
    mainCorner.Parent = main

    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 44)
    topBar.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
    topBar.BorderSizePixel = 0
    topBar.Parent = main

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Sirius Menu"
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = topBar

    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 120, 1, -44)
    sidebar.Position = UDim2.new(0, 0, 0, 44)
    sidebar.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    sidebar.BorderSizePixel = 0
    sidebar.Parent = main

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -120, 1, -44)
    content.Position = UDim2.new(0, 120, 0, 44)
    content.BackgroundColor3 = Color3.fromRGB(25, 25, 29)
    content.BorderSizePixel = 0
    content.Parent = main

    local pages = {}
    local tabs = {}
    local activePage = nil

    local function setPage(name)
        for pageName, page in pairs(pages) do
            page.Visible = pageName == name
        end
        for tabName, tab in pairs(tabs) do
            tab.BackgroundColor3 = tabName == name and Color3.fromRGB(60, 120, 255) or Color3.fromRGB(32, 32, 36)
        end
        activePage = name
    end

    local function addPage(name)
        local page = Instance.new("ScrollingFrame")
        page.Name = name
        page.Size = UDim2.new(1, 0, 1, 0)
        page.Position = UDim2.new(0, 0, 0, 0)
        page.CanvasSize = UDim2.new(0, 0, 0, 600)
        page.ScrollBarThickness = 5
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.Visible = false
        page.Parent = content

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.Parent = page

        pages[name] = page
        return page
    end

    local function addTabButton(name)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -12, 0, 34)
        button.BackgroundColor3 = Color3.fromRGB(32, 32, 36)
        button.Text = name
        button.Font = Enum.Font.GothamSemibold
        button.TextSize = 13
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.BorderSizePixel = 0
        button.Parent = sidebar

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = button

        tabs[name] = button
        button.MouseButton1Click:Connect(function()
            setPage(name)
        end)
    end

    addPage("AutoFarm")
    addPage("Event")
    addPage("Character")
    addPage("Visuals")

    addTabButton("AutoFarm")
    addTabButton("Event")
    addTabButton("Character")
    addTabButton("Visuals")

    local function addSection(page, titleText)
        local section = Instance.new("Frame")
        section.Size = UDim2.new(1, -12, 0, 22)
        section.BackgroundTransparency = 1
        section.Parent = page

        local label = createText(titleText)
        label.Size = UDim2.new(1, 0, 1, 0)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.Font = Enum.Font.GothamBold
        label.TextColor3 = Color3.fromRGB(140, 170, 255)
        label.TextSize = 12
        label.Parent = section

        return section
    end

    local autoPage = pages["AutoFarm"]
    addSection(autoPage, "Collection")
    createToggle(autoPage, "Egg", false, function(value) state.farm.Egg = value end)
    createToggle(autoPage, "Wood", false, function(value) state.farm.Wood = value end)
    createToggle(autoPage, "Metal", false, function(value) state.farm.Metal = value end)
    createToggle(autoPage, "Fabric", false, function(value) state.farm.Fabric = value end)

    local eventPage = pages["Event"]
    addSection(eventPage, "Event")
    createToggle(eventPage, "Pumpkin", false, function(value) state.event.Pumpkin = value end)

    local characterPage = pages["Character"]
    addSection(characterPage, "Movement")
    createSlider(characterPage, "WalkSpeed", 16, 500, 16, 1, function(value)
        state.character.WalkSpeed = value
        applyCharacterSettings()
    end)
    createSlider(characterPage, "JumpPower", 50, 250, 50, 5, function(value)
        state.character.JumpPower = value
        applyCharacterSettings()
    end)
    createSlider(characterPage, "Scale", 1, 3, 1, 0.1, function(value)
        state.character.Scale = value
        applyCharacterSettings()
    end)

    local visualsPage = pages["Visuals"]
    addSection(visualsPage, "ESP")
    createToggle(visualsPage, "ESP", false, function(value)
        state.visuals.ESP = value
        updateVisuals()
    end)
    createToggle(visualsPage, "Egg ESP", false, function(value)
        state.visuals.Egg = value
        updateVisuals()
    end)
    createToggle(visualsPage, "Wood ESP", false, function(value)
        state.visuals.Wood = value
        updateVisuals()
    end)
    createToggle(visualsPage, "Metal ESP", false, function(value)
        state.visuals.Metal = value
        updateVisuals()
    end)
    createToggle(visualsPage, "Fabric ESP", false, function(value)
        state.visuals.Fabric = value
        updateVisuals()
    end)
    createToggle(visualsPage, "Pumpkin ESP", false, function(value)
        state.visuals.Pumpkin = value
        updateVisuals()
    end)
    addSection(visualsPage, "World")
    createToggle(visualsPage, "Full Bright", false, function(value)
        state.visuals.FullBright = value
        setFullBright(value)
    end)
    createSlider(visualsPage, "Time", 0, 24, 12, 0.5, function(value)
        Lighting.ClockTime = value
        Lighting.TimeOfDay = tostring(value)
    end)

    setPage("AutoFarm")
    return gui
end

createHud()
createMenu()
autoFarmLoop()

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    applyCharacterSettings()
end)

print("Sirius AutoFarm loaded.")
