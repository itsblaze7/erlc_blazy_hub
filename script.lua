--[[
    ========================================================================
    BLAZY HUB // ERLC V1 — UI Script (Bug-Fixed Edition)
    ========================================================================
    Target Game: Emergency Response: Liberty County (ERLC)
    Version: 1.0.1
    Library: FluentPlus (Beta)
    Compatibility: Delta, Madium, Wave, Solara, Xeno
    ========================================================================
--]]

-- Prevent multiple instances from running concurrently
if _G.BlazyHubLoaded then
    warn("[BLAZY HUB]: Previous instance detected. Triggering cleanup...")
    if typeof(_G.BlazyHubUnload) == "function" then
        pcall(_G.BlazyHubUnload)
    end
    task.wait(0.3)
end

_G.BlazyHubLoaded = true

-- Core Roblox Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- Connection storage for clean unhooking on unload
local Connections = {}

--[[
    ========================================================================
    CONFIGURATION TABLE
    ========================================================================
    Maintains all UI state synchronized across controls.
--]]
local Config = {
    Combat = {
        SilentAim = false,
        ShowFOV = true,
        FOVRadius = 120,
        TargetBone = "Head",
        TeamCheck = true,
        WallCheck = true,
        NoRecoil = false,
        NoSpread = false,
        RapidFire = false,
        HitChance = 100,
        Aimbot = false,
        Smoothness = 1,
        VisibleCheck = false,
    },
    Visuals = {
        MasterESP = false,
        Boxes = true,
        Tracers = false,
        Names = true,
        Distance = true,
        HealthBars = true,
        RenderDistance = 1500,
        ShowCops = true,
        ShowCivilians = true,
        ShowCriminals = true,
        Fullbright = false,
        ATMESP = false,
        CustomFOV = 90,
    },
    Movement = {
        WalkSpeedModifier = false,
        SpeedValue = 28,
        CFrameSpeed = false,
        EnableFly = false,
        FlySpeed = 50,
        Noclip = false,
        InfiniteJump = false,
        InfiniteStamina = false,
        NoFallDamage = false,
    },
    Teleport = {
        SelectedPlayer = nil,
        Landmark = "Police Department",
        SafeStepTeleport = true,
        StepDistance = 20,
        StepDelay = 0.03,
    },
    AutoFarm = {
        AutoATMRobber = false,
        AutoEquipRFID = true,
        AutoDeposit = true,
        MinigameDelay = 0.18,
        AutoJob = false,
        JobType = "Mail Delivery",
        AutoJewelryStore = false,
        AutoXPFarm = false,
    },
    Settings = {
        UITransparency = 0.95,
        AcrylicBlur = true,
    }
}

--[[
    ========================================================================
    ICONS RESOLVER
    ========================================================================
    Safely resolves icons from executor environment or Icons.lua file.
--]]
local rawIcons = (typeof(Icons) == "table" and Icons)
    or (typeof(_G.Icons) == "table" and _G.Icons)
    or (typeof(getgenv) == "function" and typeof(getgenv().Icons) == "table" and getgenv().Icons)
    or {}

if not next(rawIcons) then
    pcall(function()
        if typeof(readfile) == "function" and typeof(isfile) == "function" and isfile("Icons.lua") then
            local fileContent = readfile("Icons.lua")
            local fn = loadstring(fileContent)
            if fn then
                local res = fn()
                if typeof(res) == "table" then
                    rawIcons = res
                end
            end
        end
    end)
end

local IconAliases = {
    Home = "lucide-home",
    Crosshair = "lucide-crosshair",
    Eye = "lucide-eye",
    Zap = "lucide-cloud-lightning",
    MapPin = "lucide-map-pin",
    DollarSign = "lucide-dollar-sign",
    Sliders = "lucide-sliders",
    Info = "lucide-info",
    Shield = "lucide-shield",
    User = "lucide-user",
    Crown = "lucide-crown",
    Warning = "lucide-alert-triangle",
    Combat = "lucide-crosshair",
    Visuals = "lucide-eye",
    Movement = "lucide-cloud-lightning",
    Teleport = "lucide-map-pin",
    AutoFarm = "lucide-dollar-sign",
    Settings = "lucide-sliders",
    Dashboard = "lucide-home",
}

local SafeIcons = setmetatable({}, {
    __index = function(_, key)
        if rawIcons[key] then
            return rawIcons[key]
        end
        local alias = IconAliases[key]
        if alias and rawIcons[alias] then
            return rawIcons[alias]
        end
        if typeof(key) == "string" and rawIcons["lucide-" .. key:lower()] then
            return rawIcons["lucide-" .. key:lower()]
        end
        return rawIcons["lucide-default"] or ""
    end
})

--[[
    ========================================================================
    LIBRARY INITIALIZATION (FluentPlus)
    ========================================================================
--]]
local Fluent, SaveManager, InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/discoart/FluentPlus/refs/heads/main/Beta.lua"))()

-- Bug 1 Fix: Do NOT reparent FluentPlus ScreenGui. Let FluentPlus handle its own parenting.
-- Ensure ResetOnSpawn is false and DisplayOrder is topmost to prevent focus loss.
if Fluent and Fluent.GUI then
    pcall(function()
        Fluent.GUI.ResetOnSpawn = false
        Fluent.GUI.DisplayOrder = 999999
    end)
end

--[[
    ========================================================================
    CUSTOM THEME CONFIGURATION
    ========================================================================
    Blazy Obsidian: Dark charcoal background, neon red (#ff4444) accent
--]]
if Fluent and typeof(Fluent.AddTheme) == "function" then
    pcall(function()
        Fluent:AddTheme({
            Name = "Blazy Obsidian",
            Accent = Color3.fromRGB(255, 68, 68),
            AcrylicMain = Color3.fromRGB(10, 10, 12),
            AcrylicBorder = Color3.fromRGB(204, 34, 34),
            AcrylicGradient = ColorSequence.new(Color3.fromRGB(10, 10, 12), Color3.fromRGB(19, 19, 23)),
            AcrylicNoise = 0.95,
            TitleBarLine = Color3.fromRGB(204, 34, 34),
            Tab = Color3.fromRGB(144, 144, 160),
            Element = Color3.fromRGB(19, 19, 23),
            ElementBorder = Color3.fromRGB(30, 30, 35),
            InElementBorder = Color3.fromRGB(45, 45, 55),
            ElementTransparency = 0.85,
            ToggleSlider = Color3.fromRGB(60, 60, 70),
            ToggleToggled = Color3.fromRGB(255, 68, 68),
            SliderRail = Color3.fromRGB(40, 40, 50),
            DropdownFrame = Color3.fromRGB(30, 30, 38),
            DropdownHolder = Color3.fromRGB(19, 19, 23),
            DropdownBorder = Color3.fromRGB(40, 40, 50),
            DropdownOption = Color3.fromRGB(144, 144, 160),
            Keybind = Color3.fromRGB(40, 40, 50),
            Input = Color3.fromRGB(30, 30, 38),
            InputFocused = Color3.fromRGB(15, 15, 18),
            InputIndicator = Color3.fromRGB(255, 68, 68),
            Dialog = Color3.fromRGB(19, 19, 23),
            DialogHolder = Color3.fromRGB(10, 10, 12),
            DialogHolderLine = Color3.fromRGB(40, 40, 50),
            DialogButton = Color3.fromRGB(25, 25, 30),
            DialogButtonBorder = Color3.fromRGB(50, 50, 60),
            DialogBorder = Color3.fromRGB(204, 34, 34),
            DialogInput = Color3.fromRGB(25, 25, 30),
            DialogInputLine = Color3.fromRGB(60, 60, 70),
            Text = Color3.fromRGB(240, 240, 245),
            SubText = Color3.fromRGB(144, 144, 160),
            Hover = Color3.fromRGB(30, 30, 38),
            HoverChange = 0.08,
        })
    end)
end

--[[
    ========================================================================
    MAIN WINDOW CREATION
    ========================================================================
--]]
local WindowSize = UDim2.fromOffset(640, 520)
local Window = Fluent:CreateWindow({
    Title = "BLAZY HUB // ERLC V1",
    SubTitle = "ERLC V1",
    TabWidth = 160,
    Size = WindowSize,
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.Unknown -- Minimize handled exclusively by our controlled hooks
})

--[[
    ========================================================================
    SMOOTH UNLOAD & CLOSE ANIMATION (Bug 4 Fix)
    ========================================================================
--]]
local isUnloading = false
local realFluentDestroy = Fluent.Destroy
local realWindowDestroy = Window.Destroy

local function SmoothUnloadHub()
    if isUnloading or not _G.BlazyHubLoaded then return end
    isUnloading = true

    -- Disconnect all recorded listeners
    for name, conn in pairs(Connections) do
        if typeof(conn) == "RBXScriptConnection" then
            pcall(function() conn:Disconnect() end)
        end
    end
    table.clear(Connections)

    -- Tween the window out: BackgroundTransparency 0 -> 1, Size full -> 0x0 over 0.2s (Quad, In)
    pcall(function()
        if Window and Window.Root then
            Window.Root.ClipsDescendants = true
            local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            TweenService:Create(Window.Root, tweenInfo, {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(0, 0)
            }):Play()

            -- Fade descendant text, icons, and frames
            for _, desc in ipairs(Window.Root:GetDescendants()) do
                if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                    pcall(function()
                        TweenService:Create(desc, tweenInfo, { TextTransparency = 1 }):Play()
                    end)
                elseif desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
                    pcall(function()
                        TweenService:Create(desc, tweenInfo, { ImageTransparency = 1 }):Play()
                    end)
                elseif desc:IsA("Frame") or desc:IsA("ScrollingFrame") then
                    pcall(function()
                        TweenService:Create(desc, tweenInfo, { BackgroundTransparency = 1 }):Play()
                    end)
                end
            end
        end
    end)

    task.wait(0.25)

    -- Execute final library destroy
    if typeof(realFluentDestroy) == "function" then
        pcall(function() realFluentDestroy(Fluent) end)
    elseif typeof(realWindowDestroy) == "function" then
        pcall(function() realWindowDestroy(Window) end)
    end

    _G.BlazyHubLoaded = false
    _G.BlazyHubUnload = nil
    print("[BLAZY HUB]: Unloaded.")
end

_G.BlazyHubUnload = SmoothUnloadHub

-- Hook library destroy references to the smooth unload flow
Fluent.Destroy = SmoothUnloadHub
Window.Destroy = SmoothUnloadHub

-- Hook TitleBar Close button if available
pcall(function()
    if Window.TitleBar and Window.TitleBar.CloseButton and Window.TitleBar.CloseButton.Frame then
        Window.TitleBar.CloseButton.Frame.MouseButton1Click:Connect(function()
            SmoothUnloadHub()
        end)
    end
end)

--[[
    ========================================================================
    SMOOTH TITLE BAR DRAGGING (Bug 2 Fix)
    ========================================================================
    Only allow dragging from the title bar, tracked via UserInputService.InputChanged
--]]
pcall(function()
    if Window.TitleBar and Window.TitleBar.Frame then
        local isDragging = false
        local dragStart = nil
        local startPos = nil

        Connections.TitleBarDragStart = Window.TitleBar.Frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isDragging = true
                dragStart = input.Position
                startPos = Window.Root.Position

                local endConn
                endConn = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        isDragging = false
                        dragStart = nil
                        startPos = nil
                        if endConn then
                            endConn:Disconnect()
                        end
                    end
                end)
            end
        end)

        Connections.TitleBarDragMove = UserInputService.InputChanged:Connect(function(input)
            if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                if dragStart and startPos then
                    local delta = input.Position - dragStart
                    Window.Root.Position = UDim2.new(
                        startPos.X.Scale,
                        startPos.X.Offset + delta.X,
                        startPos.Y.Scale,
                        startPos.Y.Offset + delta.Y
                    )
                end
            end
        end)

        Connections.TitleBarDragEnd = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isDragging = false
                dragStart = nil
                startPos = nil
            end
        end)
    end
end)

--[[
    ========================================================================
    MINIMIZE / RESTORE ANIMATION (Bug 3 Fix)
    ========================================================================
    Smoothly tween size to a pill (220x44) with Back:Out easing over 0.35s
--]]
local isMinimized = false
local isAnimatingMinimize = false
local PillSize = UDim2.fromOffset(220, 44)

function Window:Minimize()
    if isAnimatingMinimize or isUnloading then return end
    isAnimatingMinimize = true
    isMinimized = not isMinimized

    if isMinimized then
        Window.Root.Visible = true
        Window.Root.ClipsDescendants = true
        local tween = TweenService:Create(
            Window.Root,
            TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Size = PillSize }
        )
        tween:Play()
        tween.Completed:Connect(function()
            isAnimatingMinimize = false
        end)
    else
        Window.Root.Visible = true
        local tween = TweenService:Create(
            Window.Root,
            TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Size = WindowSize }
        )
        tween:Play()
        tween.Completed:Connect(function()
            Window.Root.ClipsDescendants = false
            isAnimatingMinimize = false
        end)
    end
end

-- Wire title bar minimize button directly to animated Window:Minimize
pcall(function()
    if Window.TitleBar and Window.TitleBar.MinButton and Window.TitleBar.MinButton.Frame then
        Window.TitleBar.MinButton.Frame.MouseButton1Click:Connect(function()
            Window:Minimize()
        end)
    end
end)

--[[
    ========================================================================
    RIGHTCONTROL KEYBIND TOGGLE (Bug 5 Fix)
    ========================================================================
    Fade in / fade out with a single synchronized visibility state variable
--]]
local isMenuVisible = true
local isFadingMenu = false
local defaultWindowTransparency = Window.Root and Window.Root.BackgroundTransparency or 0

local function ToggleMenuVisibility()
    if isFadingMenu or isUnloading then return end
    isFadingMenu = true
    isMenuVisible = not isMenuVisible

    if isMenuVisible then
        Window.Root.Visible = true
        Window.Root.BackgroundTransparency = 1
        local fadeInTween = TweenService:Create(
            Window.Root,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundTransparency = defaultWindowTransparency }
        )
        fadeInTween:Play()
        fadeInTween.Completed:Connect(function()
            isFadingMenu = false
        end)
    else
        local fadeOutTween = TweenService:Create(
            Window.Root,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { BackgroundTransparency = 1 }
        )
        fadeOutTween:Play()
        task.delay(0.2, function()
            if not isMenuVisible then
                Window.Root.Visible = false
            end
            isFadingMenu = false
        end)
    end
end

Connections.ToggleKeybind = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        ToggleMenuVisibility()
    end
end)

--[[
    ========================================================================
    WIDGET TWEEN HELPERS
    ========================================================================
    Enhances toggles, sliders, and buttons with required micro-animations
--]]
local function enhanceToggle(toggleObj)
    if not toggleObj or typeof(toggleObj) ~= "table" then return toggleObj end
    local origSetValue = toggleObj.SetValue
    if typeof(origSetValue) == "function" then
        toggleObj.SetValue = function(self, val)
            origSetValue(self, val)
            pcall(function()
                local frame = self.Elements and self.Elements.Frame
                if frame then
                    local slider = frame:FindFirstChildWhichIsA("Frame")
                    if slider then
                        local circle = slider:FindFirstChildWhichIsA("ImageLabel")
                        if circle then
                            TweenService:Create(
                                circle,
                                TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                                { Position = UDim2.new(0, self.Value and 19 or 2, 0.5, 0) }
                            ):Play()
                        end
                    end
                end
            end)
        end
    end
    return toggleObj
end

local function enhanceSlider(sliderObj)
    if not sliderObj or typeof(sliderObj) ~= "table" then return sliderObj end
    pcall(function()
        local frame = sliderObj.Elements and sliderObj.Elements.Frame
        if frame then
            local inner = frame:FindFirstChildWhichIsA("Frame")
            if inner then
                local rail = inner:FindFirstChildWhichIsA("Frame")
                local dot = rail and rail:FindFirstChildWhichIsA("ImageLabel")
                if dot then
                    local baseSize = dot.Size
                    local hoveredSize = UDim2.fromOffset(math.floor(baseSize.X.Offset * 1.15), math.floor(baseSize.Y.Offset * 1.15))
                    frame.MouseEnter:Connect(function()
                        TweenService:Create(dot, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                            Size = hoveredSize
                        }):Play()
                    end)
                    frame.MouseLeave:Connect(function()
                        TweenService:Create(dot, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                            Size = baseSize
                        }):Play()
                    end)
                end
            end
        end
    end)
    return sliderObj
end

local function enhanceButton(btnObj)
    if not btnObj then return btnObj end
    pcall(function()
        local frame = btnObj.Frame or btnObj
        if frame and (frame:IsA("TextButton") or frame:IsA("GuiButton")) then
            local baseColor = frame.BackgroundColor3
            local hoverColor = Color3.fromRGB(
                math.min(255, math.floor(baseColor.R * 255 * 1.25 + 15)),
                math.min(255, math.floor(baseColor.G * 255 * 1.25 + 15)),
                math.min(255, math.floor(baseColor.B * 255 * 1.25 + 15))
            )
            frame.MouseEnter:Connect(function()
                TweenService:Create(frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundColor3 = hoverColor
                }):Play()
            end)
            frame.MouseLeave:Connect(function()
                TweenService:Create(frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundColor3 = baseColor
                }):Play()
            end)
        end
    end)
    return btnObj
end

--[[
    ========================================================================
    TABS CREATION (Strict Order)
    ========================================================================
    1. Dashboard   (Icons.Home)
    2. Combat      (Icons.Crosshair)
    3. Visuals     (Icons.Eye)
    4. Movement    (Icons.Zap)
    5. Teleport    (Icons.MapPin)
    6. Auto Farm   (Icons.DollarSign)
    7. Settings    (Icons.Sliders)
    8. Info        (Icons.Info)
--]]
local Tabs = {
    Dashboard = Window:AddTab({ Title = "Dashboard", Icon = SafeIcons.Home }),
    Combat    = Window:AddTab({ Title = "Combat", Icon = SafeIcons.Crosshair }),
    Visuals   = Window:AddTab({ Title = "Visuals", Icon = SafeIcons.Eye }),
    Movement  = Window:AddTab({ Title = "Movement", Icon = SafeIcons.Zap }),
    Teleport  = Window:AddTab({ Title = "Teleport", Icon = SafeIcons.MapPin }),
    AutoFarm  = Window:AddTab({ Title = "Auto Farm", Icon = SafeIcons.DollarSign }),
    Settings  = Window:AddTab({ Title = "Settings", Icon = SafeIcons.Sliders }),
    Info      = Window:AddTab({ Title = "Info", Icon = SafeIcons.Info }),
}

--[[
    ========================================================================
    TAB 1: DASHBOARD
    ========================================================================
--]]
do
    Tabs.Dashboard:AddParagraph({
        Title = "BLAZY HUB — ERLC Suite v1.0",
        Content = "Welcome to BLAZY HUB. Premium Emergency Response: Liberty County suite."
    })

    Tabs.Dashboard:AddParagraph({
        Title = "System Status",
        Content = "Status: UI Loaded | Backend: Pending Step 2"
    })

    local DashboardStatusSection = Tabs.Dashboard:AddSection("System Status")

    enhanceToggle(DashboardStatusSection:AddToggle("AntiCheatBypassToggle", {
        Title = "Anti-Cheat Bypass",
        Default = true,
        Callback = function(Value)
            print("[BLAZY HUB - Dashboard]: Anti-Cheat Bypass dummy set to", Value)
        end
    }))

    enhanceToggle(DashboardStatusSection:AddToggle("AutoExecuteToggle", {
        Title = "Auto-Execute on Join",
        Default = false,
        Callback = function(Value)
            print("[BLAZY HUB - Dashboard]: Auto-Execute on Join dummy set to", Value)
        end
    }))

    enhanceButton(DashboardStatusSection:AddButton({
        Title = "Rejoin Server",
        Callback = function()
            print("[BLAZY HUB - Dashboard]: Rejoin Server button clicked (dummy).")
        end
    }))
end

--[[
    ========================================================================
    TAB 2: COMBAT
    ========================================================================
--]]
do
    -- Silent Aim Section
    local SilentAimSection = Tabs.Combat:AddSection("Silent Aim")

    enhanceToggle(SilentAimSection:AddToggle("CombatSilentAim", {
        Title = "Enable Silent Aim",
        Default = Config.Combat.SilentAim,
        Callback = function(Value)
            Config.Combat.SilentAim = Value
            print("[BLAZY HUB - Combat]: Enable Silent Aim set to", Value)
        end
    }))

    enhanceToggle(SilentAimSection:AddToggle("CombatShowFOV", {
        Title = "Show FOV Circle",
        Default = Config.Combat.ShowFOV,
        Callback = function(Value)
            Config.Combat.ShowFOV = Value
            print("[BLAZY HUB - Combat]: Show FOV Circle set to", Value)
        end
    }))

    enhanceSlider(SilentAimSection:AddSlider("CombatFOVRadius", {
        Title = "FOV Radius",
        Min = 30,
        Max = 400,
        Default = Config.Combat.FOVRadius,
        Rounding = 0,
        Callback = function(Value)
            Config.Combat.FOVRadius = Value
            print("[BLAZY HUB - Combat]: FOV Radius set to", Value)
        end
    }))

    SilentAimSection:AddDropdown("CombatTargetBone", {
        Title = "Target Bone",
        Values = { "Head", "Torso", "HumanoidRootPart" },
        Default = Config.Combat.TargetBone,
        Callback = function(Value)
            Config.Combat.TargetBone = Value
            print("[BLAZY HUB - Combat]: Target Bone set to", Value)
        end
    })

    enhanceToggle(SilentAimSection:AddToggle("CombatTeamCheck", {
        Title = "Team Check",
        Default = Config.Combat.TeamCheck,
        Callback = function(Value)
            Config.Combat.TeamCheck = Value
            print("[BLAZY HUB - Combat]: Team Check set to", Value)
        end
    }))

    enhanceToggle(SilentAimSection:AddToggle("CombatWallCheck", {
        Title = "Wall Check",
        Default = Config.Combat.WallCheck,
        Callback = function(Value)
            Config.Combat.WallCheck = Value
            print("[BLAZY HUB - Combat]: Wall Check set to", Value)
        end
    }))

    -- Gun Modifications Section
    local GunModSection = Tabs.Combat:AddSection("Gun Modifications")

    enhanceToggle(GunModSection:AddToggle("CombatNoRecoil", {
        Title = "No Recoil",
        Default = Config.Combat.NoRecoil,
        Callback = function(Value)
            Config.Combat.NoRecoil = Value
            print("[BLAZY HUB - Combat]: No Recoil set to", Value)
        end
    }))

    enhanceToggle(GunModSection:AddToggle("CombatNoSpread", {
        Title = "No Spread",
        Default = Config.Combat.NoSpread,
        Callback = function(Value)
            Config.Combat.NoSpread = Value
            print("[BLAZY HUB - Combat]: No Spread set to", Value)
        end
    }))

    enhanceToggle(GunModSection:AddToggle("CombatRapidFire", {
        Title = "Rapid Fire",
        Default = Config.Combat.RapidFire,
        Callback = function(Value)
            Config.Combat.RapidFire = Value
            print("[BLAZY HUB - Combat]: Rapid Fire set to", Value)
        end
    }))

    enhanceSlider(GunModSection:AddSlider("CombatHitChance", {
        Title = "Hit Chance",
        Description = "Percentage of shots that register",
        Min = 1,
        Max = 100,
        Default = Config.Combat.HitChance,
        Rounding = 0,
        Callback = function(Value)
            Config.Combat.HitChance = Value
            print("[BLAZY HUB - Combat]: Hit Chance set to", Value .. "%")
        end
    }))

    -- Aimbot Section
    local AimbotSection = Tabs.Combat:AddSection("Aimbot")

    enhanceToggle(AimbotSection:AddToggle("CombatEnableAimbot", {
        Title = "Enable Aimbot",
        Default = Config.Combat.Aimbot,
        Callback = function(Value)
            Config.Combat.Aimbot = Value
            print("[BLAZY HUB - Combat]: Enable Aimbot set to", Value)
        end
    }))

    enhanceSlider(AimbotSection:AddSlider("CombatSmoothness", {
        Title = "Smoothness",
        Min = 1,
        Max = 15,
        Default = Config.Combat.Smoothness,
        Rounding = 0,
        Callback = function(Value)
            Config.Combat.Smoothness = Value
            print("[BLAZY HUB - Combat]: Smoothness set to", Value)
        end
    }))

    enhanceToggle(AimbotSection:AddToggle("CombatVisibleCheck", {
        Title = "Visible Check",
        Default = Config.Combat.VisibleCheck,
        Callback = function(Value)
            Config.Combat.VisibleCheck = Value
            print("[BLAZY HUB - Combat]: Visible Check set to", Value)
        end
    }))
end

--[[
    ========================================================================
    TAB 3: VISUALS
    ========================================================================
--]]
do
    -- ESP Section
    local ESPSection = Tabs.Visuals:AddSection("ESP")

    enhanceToggle(ESPSection:AddToggle("VisualsMasterESP", {
        Title = "Master ESP",
        Default = Config.Visuals.MasterESP,
        Callback = function(Value)
            Config.Visuals.MasterESP = Value
            print("[BLAZY HUB - Visuals]: Master ESP set to", Value)
        end
    }))

    enhanceToggle(ESPSection:AddToggle("VisualsBoxes", {
        Title = "Boxes",
        Default = Config.Visuals.Boxes,
        Callback = function(Value)
            Config.Visuals.Boxes = Value
            print("[BLAZY HUB - Visuals]: Boxes ESP set to", Value)
        end
    }))

    enhanceToggle(ESPSection:AddToggle("VisualsTracers", {
        Title = "Tracers",
        Default = Config.Visuals.Tracers,
        Callback = function(Value)
            Config.Visuals.Tracers = Value
            print("[BLAZY HUB - Visuals]: Tracers ESP set to", Value)
        end
    }))

    enhanceToggle(ESPSection:AddToggle("VisualsNames", {
        Title = "Names",
        Default = Config.Visuals.Names,
        Callback = function(Value)
            Config.Visuals.Names = Value
            print("[BLAZY HUB - Visuals]: Names ESP set to", Value)
        end
    }))

    enhanceToggle(ESPSection:AddToggle("VisualsDistance", {
        Title = "Distance",
        Default = Config.Visuals.Distance,
        Callback = function(Value)
            Config.Visuals.Distance = Value
            print("[BLAZY HUB - Visuals]: Distance ESP set to", Value)
        end
    }))

    enhanceToggle(ESPSection:AddToggle("VisualsHealthBars", {
        Title = "Health Bars",
        Default = Config.Visuals.HealthBars,
        Callback = function(Value)
            Config.Visuals.HealthBars = Value
            print("[BLAZY HUB - Visuals]: Health Bars ESP set to", Value)
        end
    }))

    enhanceSlider(ESPSection:AddSlider("VisualsRenderDistance", {
        Title = "Render Distance",
        Description = "Render distance in studs",
        Min = 200,
        Max = 4000,
        Default = Config.Visuals.RenderDistance,
        Rounding = 0,
        Callback = function(Value)
            Config.Visuals.RenderDistance = Value
            print("[BLAZY HUB - Visuals]: Render Distance set to", Value .. " studs")
        end
    }))

    -- Team Filter Section
    local TeamFilterSection = Tabs.Visuals:AddSection("Team Filter")

    enhanceToggle(TeamFilterSection:AddToggle("VisualsShowCops", {
        Title = "Show Cops",
        Default = Config.Visuals.ShowCops,
        Callback = function(Value)
            Config.Visuals.ShowCops = Value
            print("[BLAZY HUB - Visuals]: Show Cops set to", Value)
        end
    }))

    enhanceToggle(TeamFilterSection:AddToggle("VisualsShowCivilians", {
        Title = "Show Civilians",
        Default = Config.Visuals.ShowCivilians,
        Callback = function(Value)
            Config.Visuals.ShowCivilians = Value
            print("[BLAZY HUB - Visuals]: Show Civilians set to", Value)
        end
    }))

    enhanceToggle(TeamFilterSection:AddToggle("VisualsShowCriminals", {
        Title = "Show Criminals",
        Default = Config.Visuals.ShowCriminals,
        Callback = function(Value)
            Config.Visuals.ShowCriminals = Value
            print("[BLAZY HUB - Visuals]: Show Criminals set to", Value)
        end
    }))

    -- World Section
    local WorldSection = Tabs.Visuals:AddSection("World")

    enhanceToggle(WorldSection:AddToggle("VisualsFullbright", {
        Title = "Fullbright",
        Default = Config.Visuals.Fullbright,
        Callback = function(Value)
            Config.Visuals.Fullbright = Value
            print("[BLAZY HUB - Visuals]: Fullbright set to", Value)
        end
    }))

    enhanceToggle(WorldSection:AddToggle("VisualsATMESP", {
        Title = "ATM ESP",
        Default = Config.Visuals.ATMESP,
        Callback = function(Value)
            Config.Visuals.ATMESP = Value
            print("[BLAZY HUB - Visuals]: ATM ESP set to", Value)
        end
    }))

    enhanceSlider(WorldSection:AddSlider("VisualsCustomFOV", {
        Title = "Custom FOV",
        Description = "Field of view angle",
        Min = 70,
        Max = 120,
        Default = Config.Visuals.CustomFOV,
        Rounding = 0,
        Callback = function(Value)
            Config.Visuals.CustomFOV = Value
            print("[BLAZY HUB - Visuals]: Custom FOV set to", Value .. "°")
        end
    }))
end

--[[
    ========================================================================
    TAB 4: MOVEMENT
    ========================================================================
--]]
do
    -- Speed Section
    local SpeedSection = Tabs.Movement:AddSection("Speed")

    enhanceToggle(SpeedSection:AddToggle("MovementWalkSpeedMod", {
        Title = "WalkSpeed Modifier",
        Default = Config.Movement.WalkSpeedModifier,
        Callback = function(Value)
            Config.Movement.WalkSpeedModifier = Value
            print("[BLAZY HUB - Movement]: WalkSpeed Modifier set to", Value)
        end
    }))

    enhanceSlider(SpeedSection:AddSlider("MovementSpeedValue", {
        Title = "Speed Value",
        Description = "Speed in studs/s",
        Min = 16,
        Max = 120,
        Default = Config.Movement.SpeedValue,
        Rounding = 0,
        Callback = function(Value)
            Config.Movement.SpeedValue = Value
            print("[BLAZY HUB - Movement]: Speed Value set to", Value .. " studs/s")
        end
    }))

    enhanceToggle(SpeedSection:AddToggle("MovementCFrameSpeed", {
        Title = "CFrame Speed (Safe)",
        Default = Config.Movement.CFrameSpeed,
        Callback = function(Value)
            Config.Movement.CFrameSpeed = Value
            print("[BLAZY HUB - Movement]: CFrame Speed (Safe) set to", Value)
        end
    }))

    -- Flight Section
    local FlightSection = Tabs.Movement:AddSection("Flight")

    enhanceToggle(FlightSection:AddToggle("MovementEnableFly", {
        Title = "Enable Fly",
        Default = Config.Movement.EnableFly,
        Callback = function(Value)
            Config.Movement.EnableFly = Value
            print("[BLAZY HUB - Movement]: Enable Fly set to", Value)
        end
    }))

    enhanceSlider(FlightSection:AddSlider("MovementFlySpeed", {
        Title = "Fly Speed",
        Min = 20,
        Max = 150,
        Default = Config.Movement.FlySpeed,
        Rounding = 0,
        Callback = function(Value)
            Config.Movement.FlySpeed = Value
            print("[BLAZY HUB - Movement]: Fly Speed set to", Value)
        end
    }))

    -- Physics Section
    local PhysicsSection = Tabs.Movement:AddSection("Physics")

    enhanceToggle(PhysicsSection:AddToggle("MovementNoclip", {
        Title = "Noclip",
        Default = Config.Movement.Noclip,
        Callback = function(Value)
            Config.Movement.Noclip = Value
            print("[BLAZY HUB - Movement]: Noclip set to", Value)
        end
    }))

    enhanceToggle(PhysicsSection:AddToggle("MovementInfiniteJump", {
        Title = "Infinite Jump",
        Default = Config.Movement.InfiniteJump,
        Callback = function(Value)
            Config.Movement.InfiniteJump = Value
            print("[BLAZY HUB - Movement]: Infinite Jump set to", Value)
        end
    }))

    enhanceToggle(PhysicsSection:AddToggle("MovementInfiniteStamina", {
        Title = "Infinite Stamina",
        Default = Config.Movement.InfiniteStamina,
        Callback = function(Value)
            Config.Movement.InfiniteStamina = Value
            print("[BLAZY HUB - Movement]: Infinite Stamina set to", Value)
        end
    }))

    enhanceToggle(PhysicsSection:AddToggle("MovementNoFallDamage", {
        Title = "No Fall Damage",
        Default = Config.Movement.NoFallDamage,
        Callback = function(Value)
            Config.Movement.NoFallDamage = Value
            print("[BLAZY HUB - Movement]: No Fall Damage set to", Value)
        end
    }))
end

--[[
    ========================================================================
    TAB 5: TELEPORT
    ========================================================================
--]]
do
    -- Player list helper
    local function getPlayerList()
        local playerNames = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                table.insert(playerNames, player.Name)
            end
        end
        if #playerNames == 0 then
            table.insert(playerNames, "None")
        end
        return playerNames
    end

    -- Player Teleport Section
    local PlayerTeleportSection = Tabs.Teleport:AddSection("Player Teleport")

    local initialPlayers = getPlayerList()
    local PlayerDropdown = PlayerTeleportSection:AddDropdown("TeleportSelectPlayer", {
        Title = "Select Player",
        Values = initialPlayers,
        Default = initialPlayers[1] or "None",
        Callback = function(Value)
            Config.Teleport.SelectedPlayer = Value
            print("[BLAZY HUB - Teleport]: Selected Player set to", tostring(Value))
        end
    })

    enhanceButton(PlayerTeleportSection:AddButton({
        Title = "Refresh Player List",
        Callback = function()
            local updatedList = getPlayerList()
            PlayerDropdown:SetValues(updatedList)
            print("[BLAZY HUB - Teleport]: Player list refreshed (" .. #updatedList .. " entries).")
        end
    }))

    enhanceButton(PlayerTeleportSection:AddButton({
        Title = "Teleport to Player",
        Callback = function()
            print("[BLAZY HUB - Teleport]: Teleport to Player clicked for target:", tostring(Config.Teleport.SelectedPlayer))
        end
    }))

    enhanceButton(PlayerTeleportSection:AddButton({
        Title = "Teleport Behind Player",
        Callback = function()
            print("[BLAZY HUB - Teleport]: Teleport Behind Player clicked for target:", tostring(Config.Teleport.SelectedPlayer))
        end
    }))

    -- Location Teleport Section
    local LocationTeleportSection = Tabs.Teleport:AddSection("Location Teleport")

    LocationTeleportSection:AddDropdown("TeleportLandmark", {
        Title = "Landmark",
        Values = {
            "Police Department",
            "Sheriff Office",
            "Hospital / EMS",
            "Bank & Vault",
            "Gun Shop",
            "Car Dealership",
            "Fire Department",
            "Mafia Compound"
        },
        Default = Config.Teleport.Landmark,
        Callback = function(Value)
            Config.Teleport.Landmark = Value
            print("[BLAZY HUB - Teleport]: Selected Landmark set to", Value)
        end
    })

    enhanceButton(LocationTeleportSection:AddButton({
        Title = "Teleport to Landmark",
        Callback = function()
            print("[BLAZY HUB - Teleport]: Teleport to Landmark clicked for location:", tostring(Config.Teleport.Landmark))
        end
    }))

    -- Safety Section
    local SafetySection = Tabs.Teleport:AddSection("Safety")

    enhanceToggle(SafetySection:AddToggle("TeleportSafeStep", {
        Title = "Safe Step Teleport",
        Default = Config.Teleport.SafeStepTeleport,
        Callback = function(Value)
            Config.Teleport.SafeStepTeleport = Value
            print("[BLAZY HUB - Teleport]: Safe Step Teleport set to", Value)
        end
    }))

    enhanceSlider(SafetySection:AddSlider("TeleportStepDistance", {
        Title = "Step Distance",
        Min = 5,
        Max = 50,
        Default = Config.Teleport.StepDistance,
        Rounding = 0,
        Callback = function(Value)
            Config.Teleport.StepDistance = Value
            print("[BLAZY HUB - Teleport]: Step Distance set to", Value)
        end
    }))

    enhanceSlider(SafetySection:AddSlider("TeleportStepDelay", {
        Title = "Step Delay",
        Description = "Delay between steps in seconds",
        Min = 0.01,
        Max = 0.20,
        Default = Config.Teleport.StepDelay,
        Rounding = 2,
        Callback = function(Value)
            Config.Teleport.StepDelay = Value
            print("[BLAZY HUB - Teleport]: Step Delay set to", Value .. "s")
        end
    }))
end

--[[
    ========================================================================
    TAB 6: AUTO FARM
    ========================================================================
--]]
do
    -- ATM Robbery Section
    local ATMSection = Tabs.AutoFarm:AddSection("ATM Robbery")

    enhanceToggle(ATMSection:AddToggle("AutoFarmATMRobber", {
        Title = "Auto ATM Robber",
        Default = Config.AutoFarm.AutoATMRobber,
        Callback = function(Value)
            Config.AutoFarm.AutoATMRobber = Value
            print("[BLAZY HUB - AutoFarm]: Auto ATM Robber set to", Value)
        end
    }))

    enhanceToggle(ATMSection:AddToggle("AutoFarmEquipRFID", {
        Title = "Auto Equip RFID",
        Default = Config.AutoFarm.AutoEquipRFID,
        Callback = function(Value)
            Config.AutoFarm.AutoEquipRFID = Value
            print("[BLAZY HUB - AutoFarm]: Auto Equip RFID set to", Value)
        end
    }))

    enhanceToggle(ATMSection:AddToggle("AutoFarmDepositBank", {
        Title = "Auto Deposit to Bank",
        Default = Config.AutoFarm.AutoDeposit,
        Callback = function(Value)
            Config.AutoFarm.AutoDeposit = Value
            print("[BLAZY HUB - AutoFarm]: Auto Deposit to Bank set to", Value)
        end
    }))

    enhanceSlider(ATMSection:AddSlider("AutoFarmMinigameDelay", {
        Title = "Minigame Delay",
        Description = "Delay for minigame solver in seconds",
        Min = 0.10,
        Max = 0.40,
        Default = Config.AutoFarm.MinigameDelay,
        Rounding = 2,
        Callback = function(Value)
            Config.AutoFarm.MinigameDelay = Value
            print("[BLAZY HUB - AutoFarm]: Minigame Delay set to", Value .. "s")
        end
    }))

    -- Jobs Section
    local JobsSection = Tabs.AutoFarm:AddSection("Jobs")

    enhanceToggle(JobsSection:AddToggle("AutoFarmAutoJob", {
        Title = "Auto Job (Mail / Sanitation)",
        Default = Config.AutoFarm.AutoJob,
        Callback = function(Value)
            Config.AutoFarm.AutoJob = Value
            print("[BLAZY HUB - AutoFarm]: Auto Job set to", Value)
        end
    }))

    JobsSection:AddDropdown("AutoFarmJobType", {
        Title = "Job Type",
        Values = { "Mail Delivery", "Sanitation", "Package Handler" },
        Default = Config.AutoFarm.JobType,
        Callback = function(Value)
            Config.AutoFarm.JobType = Value
            print("[BLAZY HUB - AutoFarm]: Job Type set to", Value)
        end
    })

    -- Misc Farming Section
    local MiscFarmSection = Tabs.AutoFarm:AddSection("Misc Farming")

    enhanceToggle(MiscFarmSection:AddToggle("AutoFarmJewelryStore", {
        Title = "Auto Jewelry Store",
        Default = Config.AutoFarm.AutoJewelryStore,
        Callback = function(Value)
            Config.AutoFarm.AutoJewelryStore = Value
            print("[BLAZY HUB - AutoFarm]: Auto Jewelry Store set to", Value)
        end
    }))

    enhanceToggle(MiscFarmSection:AddToggle("AutoFarmXPFarm", {
        Title = "Auto XP Farm",
        Default = Config.AutoFarm.AutoXPFarm,
        Callback = function(Value)
            Config.AutoFarm.AutoXPFarm = Value
            print("[BLAZY HUB - AutoFarm]: Auto XP Farm set to", Value)
        end
    }))
end

--[[
    ========================================================================
    TAB 7: SETTINGS
    ========================================================================
--]]
do
    -- UI Section
    local UISection = Tabs.Settings:AddSection("UI")

    enhanceSlider(UISection:AddSlider("SettingsUITransparency", {
        Title = "UI Transparency",
        Min = 0,
        Max = 1,
        Default = Config.Settings.UITransparency,
        Rounding = 2,
        Callback = function(Value)
            Config.Settings.UITransparency = Value
            if Fluent and typeof(Fluent.SetWindowTransparency) == "function" then
                pcall(function()
                    Fluent:SetWindowTransparency(Value)
                end)
            end
            print("[BLAZY HUB - Settings]: UI Transparency set to", Value)
        end
    }))

    enhanceToggle(UISection:AddToggle("SettingsAcrylicBlur", {
        Title = "Acrylic Blur",
        Default = Config.Settings.AcrylicBlur,
        Callback = function(Value)
            Config.Settings.AcrylicBlur = Value
            if Fluent and typeof(Fluent.ToggleAcrylic) == "function" then
                pcall(function()
                    Fluent:ToggleAcrylic(Value)
                end)
            end
            print("[BLAZY HUB - Settings]: Acrylic Blur set to", Value)
        end
    }))

    enhanceButton(UISection:AddButton({
        Title = "Reset UI Position",
        Callback = function()
            if Window and Window.Root then
                Window.Root.Position = UDim2.fromScale(0.5, 0.5)
                Window.Root.AnchorPoint = Vector2.new(0.5, 0.5)
                print("[BLAZY HUB - Settings]: UI Position centered.")
            end
        end
    }))

    -- Hub Section
    local HubSection = Tabs.Settings:AddSection("Hub")

    enhanceButton(HubSection:AddButton({
        Title = "Save Config",
        Callback = function()
            print("[BLAZY HUB - Settings]: Save Config clicked (dummy).")
        end
    }))

    enhanceButton(HubSection:AddButton({
        Title = "Load Config",
        Callback = function()
            print("[BLAZY HUB - Settings]: Load Config clicked (dummy).")
        end
    }))

    enhanceButton(HubSection:AddButton({
        Title = "Unload BLAZY HUB",
        Callback = function()
            SmoothUnloadHub()
        end
    }))

    -- Info Section inside Settings
    local SettingsInfoSection = Tabs.Settings:AddSection("Info")

    SettingsInfoSection:AddParagraph({
        Title = "BLAZY HUB ERLC V1",
        Content = "UI Skeleton — Step 1 Complete"
    })

    SettingsInfoSection:AddParagraph({
        Title = "Backend Status",
        Content = "Backend features pending Step 2."
    })
end

--[[
    ========================================================================
    TAB 8: INFO
    ========================================================================
--]]
do
    Tabs.Info:AddParagraph({
        Title = "BLAZY HUB",
        Content = "Emergency Response: Liberty County Suite"
    })

    Tabs.Info:AddParagraph({
        Title = "Version",
        Content = "1.0.0"
    })

    Tabs.Info:AddParagraph({
        Title = "Executor Compatibility",
        Content = "Delta, Madium, Wave, Solara, Xeno"
    })

    Tabs.Info:AddParagraph({
        Title = "Keybind Information",
        Content = "Press RightControl to toggle the menu."
    })

    enhanceButton(Tabs.Info:AddButton({
        Title = "Copy Discord Invite",
        Callback = function()
            local inviteUrl = "https://discord.gg/blazy"
            if typeof(setclipboard) == "function" then
                pcall(function()
                    setclipboard(inviteUrl)
                end)
            end
            print("[BLAZY HUB - Info]: Copied Discord invite to clipboard: " .. inviteUrl)
        end
    }))

    enhanceButton(Tabs.Info:AddButton({
        Title = "Join Discord",
        Callback = function()
            print("[BLAZY HUB - Info]: Join Discord clicked (dummy).")
        end
    }))
end

--[[
    ========================================================================
    POST-INITIALIZATION & SMOOTH ENTRANCE
    ========================================================================
--]]
-- Select default tab
Window:SelectTab(1)

-- Window open entrance: fade in BackgroundTransparency from 1 to 0 over 0.3s (do NOT scale from 0x0)
pcall(function()
    if Window and Window.Root then
        local targetTrans = Window.Root.BackgroundTransparency
        Window.Root.BackgroundTransparency = 1
        Window.Root.Visible = true
        TweenService:Create(
            Window.Root,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundTransparency = targetTrans }
        ):Play()
    end
end)

-- Send welcome notification
Fluent:Notify({
    Title = "BLAZY HUB // ERLC V1",
    Content = "BLAZY HUB ERLC V1 loaded. Press RightControl to toggle.",
    Duration = 6
})

print("[BLAZY HUB]: Successfully initialized.")
