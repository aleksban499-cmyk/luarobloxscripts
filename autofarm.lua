--[[
    Sirius-style Roblox script for auto farming and utility menu.
    Tabs:
      - AutoFarm: Egg, Wood, Metal, Fabric
      - Event: Pumpkin
      - Character: Speed, Jump, Scale
      - Visuals: ESP, resource ESP, Time, Full Bright

    Requirements:
      - Rayfield UI library is loaded automatically from the public Rayfield source.
      - Works best in a game with resource prompts such as PickupPrompt and a Pumpkin event object.
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
        Enabled = false,
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
    Wood = Color3.fromRGB(112, 70, 38),
    Metal = Color3.fromRGB(169, 177, 190),
    Fabric = Color3.fromRGB(255, 255, 255),
    Pumpkin = Color3.fromRGB(255, 140, 0),
}

local function getCharacter()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return character
end

local function getRootPart()
    local character = getCharacter()
    if not character then
        return nil
    end
    return character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local character = getCharacter()
    if not character then
        return nil
    end
    return character:FindFirstChildOfClass("Humanoid")
end

local function lowerName(value)
    if typeof(value) == "string" then
        return string.lower(value)
    end
    return ""
end

local function normalizeResourceName(name)
    local n = lowerName(name)
    if n:find("egg") then
        return "egg"
    end
    if n:find("wood") then
        return "wood"
    end
    if n:find("metal") then
        return "metal"
    end
    if n:find("fabric") then
        return "fabric"
    end
    if n:find("pumpkin") then
        return "pumpkin"
    end
    return ""
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

local function findClosestPrompt(resourceKind)
    local root = getRootPart()
    if not root then
        return nil
    end

    local bestPrompt = nil
    local bestDistance = math.huge

    for _, descendant in ipairs(Workspace:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") then
            local owner = descendant.Parent
            if owner and descendant.Enabled then
                local name = lowerName(owner.Name)
                if name:find(resourceKind) and not name:find("pumpkin") then
                    local base = getBasePartFromInstance(owner)
                    if base then
                        local dist = (base.Position - root.Position).Magnitude
                        if dist < bestDistance then
                            bestPrompt = descendant
                            bestDistance = dist
                        end
                    end
                end
            end
        end
    end

    return bestPrompt
end

local function findClosestPumpkin()
    local root = getRootPart()
    if not root then
        return nil
    end

    local bestPart = nil
    local bestDistance = math.huge

    for _, descendant in ipairs(Workspace:GetDescendants()) do
        if descendant:IsA("BasePart") or descendant:IsA("Model") then
            local name = lowerName(descendant.Name)
            if name:find("pumpkin") then
                local base = getBasePartFromInstance(descendant)
                if base then
                    local dist = (base.Position - root.Position).Magnitude
                    if dist < bestDistance then
                        bestPart = base
                        bestDistance = dist
                    end
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
        if child:IsA("TextLabel") or child:IsA("TextBox") then
            local name = child.Name
            if name == "PointsCount" then
                local value = tonumber((child.Text or "0"):gsub("[^0-9]", ""))
                if value then
                    return value
                end
            end
        end
    end

    return 0
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

    local function updateHud()
        local value = getPointsCountValue()
        count.Text = tostring(value)
    end

    task.spawn(function()
        while task.wait(0.25) do
            updateHud()
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
                        local prompt = findClosestPrompt(string.lower(resourceName))
                        if prompt then
                            local owner = prompt.Parent
                            local base = getBasePartFromInstance(owner)
                            if base then
                                root.CFrame = CFrame.new(base.Position + Vector3.new(0, 4, 0))
                                fireproximityprompt(prompt, 0.1)
                            end
                        end
                    end
                end

                if state.event.Pumpkin then
                    local pumpkinPart = findClosestPumpkin()
                    if pumpkinPart then
                        root.CFrame = CFrame.new(pumpkinPart.Position + Vector3.new(0, 3.5, 0))
                        task.wait(0.15)
                    end
                end
            end

            task.wait(0.2)
        end
    end)
end

local function applyCharacterSettings()
    local humanoid = getHumanoid()
    if not humanoid then
        return
    end

    humanoid.WalkSpeed = state.character.WalkSpeed
    humanoid.JumpPower = state.character.JumpPower

    local char = getCharacter()
    if char then
        for _, value in ipairs(char:GetDescendants()) do
            if value:IsA("NumberValue") then
                local name = value.Name:lower()
                if name:find("body") and name:find("scale") then
                    value.Value = state.character.Scale
                end
            end
        end
    end
end

local function updateVisuals()
    if not state.visuals.Enabled then
        for _, highlight in ipairs(Workspace:GetDescendants()) do
            if highlight:IsA("Highlight") and highlight.Name == "SiriusESP" then
                highlight:Destroy()
            end
        end
        return
    end

    for _, highlight in ipairs(Workspace:GetDescendants()) do
        if highlight:IsA("Highlight") and highlight.Name == "SiriusESP" then
            highlight:Destroy()
        end
    end

    local checks = {
        Egg = { enabled = state.visuals.Egg, color = resourceColors.Egg },
        Wood = { enabled = state.visuals.Wood, color = resourceColors.Wood },
        Metal = { enabled = state.visuals.Metal, color = resourceColors.Metal },
        Fabric = { enabled = state.visuals.Fabric, color = resourceColors.Fabric },
        Pumpkin = { enabled = state.visuals.Pumpkin, color = resourceColors.Pumpkin },
    }

    for _, model in ipairs(Workspace:GetDescendants()) do
        if model:IsA("Model") then
            local name = lowerName(model.Name)
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
end

local function setFullBright(enabled)
    if enabled then
        Lighting.Brightness = 2
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = 1
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        Lighting.Ambient = Color3.fromRGB(128, 128, 128)
        Lighting.GlobalShadows = true
    end
end

local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua"))()
end)

local Window

if success and Rayfield then
    Window = Rayfield:CreateWindow({
        Name = "Sirius Menu",
        LoadingTitle = "Loading Sirius",
        LoadingSubtitle = "AutoFarm + utilities",
        KeySystem = false,
        Theme = "Dark",
    })
else
    warn("Rayfield failed to load; using simple fallback window.")

    local fallback = Instance.new("ScreenGui")
    fallback.Name = "SiriusFallback"
    fallback.ResetOnSpawn = false
    fallback.Parent = CoreGui

    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 260, 0, 220)
    container.Position = UDim2.new(0.5, -130, 0.5, -110)
    container.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    container.Parent = fallback

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 32)
    title.BackgroundTransparency = 1
    title.Text = "Sirius Menu"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = container

    Window = {
        CreateTab = function()
            return {
                CreateSection = function() end,
                CreateToggle = function(opts)
                    return opts.Callback and opts.Callback(false)
                end,
                CreateSlider = function(opts)
                    return opts.Callback and opts.Callback(opts.CurrentValue)
                end,
                CreateLabel = function() end,
            }
        end,
    }
end

if Window then
    local AutofarmTab = Window:CreateTab("AutoFarm", 4483362458)
    local EventTab = Window:CreateTab("Event", 4483362458)
    local CharacterTab = Window:CreateTab("Character", 4483362458)
    local VisualsTab = Window:CreateTab("Visuals", 4483362458)

    AutofarmTab:CreateSection("Collection")
    AutofarmTab:CreateToggle({
        Name = "Egg",
        CurrentValue = false,
        Flag = "autofarm_egg",
        Callback = function(value)
            state.farm.Egg = value
        end,
    })
    AutofarmTab:CreateToggle({
        Name = "Wood",
        CurrentValue = false,
        Flag = "autofarm_wood",
        Callback = function(value)
            state.farm.Wood = value
        end,
    })
    AutofarmTab:CreateToggle({
        Name = "Metal",
        CurrentValue = false,
        Flag = "autofarm_metal",
        Callback = function(value)
            state.farm.Metal = value
        end,
    })
    AutofarmTab:CreateToggle({
        Name = "Fabric",
        CurrentValue = false,
        Flag = "autofarm_fabric",
        Callback = function(value)
            state.farm.Fabric = value
        end,
    })

    EventTab:CreateSection("Event")
    EventTab:CreateToggle({
        Name = "Pumpkin",
        CurrentValue = false,
        Flag = "event_pumpkin",
        Callback = function(value)
            state.event.Pumpkin = value
        end,
    })

    CharacterTab:CreateSection("Movement")
    CharacterTab:CreateSlider({
        Name = "WalkSpeed",
        Range = {16, 500},
        Increment = 1,
        CurrentValue = 16,
        Suffix = " speed",
        Flag = "walkspeed",
        Callback = function(value)
            state.character.WalkSpeed = value
            applyCharacterSettings()
        end,
    })
    CharacterTab:CreateSlider({
        Name = "JumpPower",
        Range = {50, 250},
        Increment = 5,
        CurrentValue = 50,
        Suffix = " jump",
        Flag = "jumppower",
        Callback = function(value)
            state.character.JumpPower = value
            applyCharacterSettings()
        end,
    })
    CharacterTab:CreateSlider({
        Name = "Scale",
        Range = {1, 3},
        Increment = 0.1,
        CurrentValue = 1,
        Suffix = "x",
        Flag = "body_scale",
        Callback = function(value)
            state.character.Scale = value
            applyCharacterSettings()
        end,
    })

    VisualsTab:CreateSection("ESP")
    VisualsTab:CreateToggle({
        Name = "ESP Master",
        CurrentValue = false,
        Flag = "esp_master",
        Callback = function(value)
            state.visuals.Enabled = value
            updateVisuals()
        end,
    })
    VisualsTab:CreateToggle({
        Name = "Egg ESP",
        CurrentValue = false,
        Flag = "esp_egg",
        Callback = function(value)
            state.visuals.Egg = value
            updateVisuals()
        end,
    })
    VisualsTab:CreateToggle({
        Name = "Wood ESP",
        CurrentValue = false,
        Flag = "esp_wood",
        Callback = function(value)
            state.visuals.Wood = value
            updateVisuals()
        end,
    })
    VisualsTab:CreateToggle({
        Name = "Metal ESP",
        CurrentValue = false,
        Flag = "esp_metal",
        Callback = function(value)
            state.visuals.Metal = value
            updateVisuals()
        end,
    })
    VisualsTab:CreateToggle({
        Name = "Fabric ESP",
        CurrentValue = false,
        Flag = "esp_fabric",
        Callback = function(value)
            state.visuals.Fabric = value
            updateVisuals()
        end,
    })
    VisualsTab:CreateToggle({
        Name = "Pumpkin ESP",
        CurrentValue = false,
        Flag = "esp_pumpkin",
        Callback = function(value)
            state.visuals.Pumpkin = value
            updateVisuals()
        end,
    })

    VisualsTab:CreateSection("Environment")
    VisualsTab:CreateToggle({
        Name = "Full Bright",
        CurrentValue = false,
        Flag = "full_bright",
        Callback = function(value)
            state.visuals.FullBright = value
            setFullBright(value)
        end,
    })
    VisualsTab:CreateSlider({
        Name = "Time of Day",
        Range = {0, 24},
        Increment = 0.5,
        CurrentValue = 12,
        Suffix = "h",
        Flag = "time_of_day",
        Callback = function(value)
            Lighting.ClockTime = value
            Lighting.TimeOfDay = tostring(value)
        end,
    })
end

createHud()
autoFarmLoop()

local function watchCharacter()
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        applyCharacterSettings()
    end)
end
watchCharacter()

print("Sirius AutoFarm loaded.")
