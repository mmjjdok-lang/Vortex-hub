-- [[ Library & UI Suite: Custom 586x339 Pro Edition ]]
-- Author: bode
-- Designed with Advanced Luau Animations, Single-Finger Dragging, Ripple Effects & Custom Systems.

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Clean up old instances if exist
if PlayerGui:FindFirstChild("ProCustomUI") then
    PlayerGui.ProCustomUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ProCustomUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- Main Theme Colors (Gothic Crimson & Neon/Purple Accent)
local ThemeColor = Color3.fromRGB(140, 0, 30)       -- Crimson Dark
local AccentColor = Color3.fromRGB(120, 40, 200)    -- Purple Accent
local BackgroundColor = Color3.fromRGB(15, 15, 20)  -- Dark Background

-- Main Frame (586x339)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 586, 0, 339)
MainFrame.Position = UDim2.new(0.5, -293, 0.5, -169.5)
MainFrame.BackgroundColor3 = BackgroundColor
MainFrame.BorderSizePixel = 0
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundTransparency = 1 -- Start transparent for Fade In animation
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = AccentColor
MainStroke.Thickness = 2
MainStroke.Transparency = 1
MainStroke.Parent = MainFrame

-- Right Top Badge (ID: 11400928550)
local IDLabel = Instance.new("TextLabel")
IDLabel.Size = UDim2.new(0, 120, 0, 20)
IDLabel.Position = UDim2.new(1, -130, 0, 10)
IDLabel.BackgroundTransparency = 1
IDLabel.Font = Enum.Font.Code
IDLabel.Text = "ID: 11400928550"
IDLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
IDLabel.TextSize = 12
IDLabel.TextXAlignment = Enum.TextXAlignment.Right
IDLabel.Parent = MainFrame

-- Single-Finger Dragging System with Heavy/Realistic Weight
local dragging = false
local dragInput, dragStart, startPos
local activeTouchObject = nil

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if not activeTouchObject then
            activeTouchObject = input
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if activeTouchObject == input then
                        dragging = false
                        activeTouchObject = nil
                    end
                end
            end)
        end
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == activeTouchObject then
        local delta = input.Position - dragStart
        -- Heavy & Smooth dragging damping
        local targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        TweenService:Create(MainFrame, TweenInfo.new(0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = targetPos}):Play()
    end
end)

-- Ripple Effect Function (قطرة الماء)
local function CreateRipple(parent, x, y)
    coroutine.wrap(function()
        local ripple = Instance.new("Frame")
        ripple.Name = "Ripple"
        ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ripple.BackgroundTransparency = 0.6
        ripple.AnchorPoint = Vector2.new(0.5, 0.5)
        ripple.Position = UDim2.new(0, x - parent.AbsolutePosition.X, 0, y - parent.AbsolutePosition.Y)
        ripple.Size = UDim2.new(0, 0, 0, 0)
        ripple.ZIndex = 10
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = ripple
        ripple.Parent = parent
        
        local maxSize = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 1.5
        local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        
        TweenService:Create(ripple, tweenInfo, {
            Size = UDim2.new(0, maxSize, 0, maxSize),
            BackgroundTransparency = 1
        }):Play()
        
        task.wait(0.4)
        ripple:Destroy()
    end)()
end

-- Particle Dots Effect under Outer Frame (تساقط النقاط تحت الإطار)
coroutine.wrap(function()
    while MainFrame and MainFrame.Parent do
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 4, 0, 4)
        dot.BackgroundColor3 = AccentColor
        dot.BackgroundTransparency = 0.3
        dot.Position = UDim2.new(math.random(5, 95)/100, 0, 1, 0)
        dot.BorderSizePixel = 0
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = dot
        dot.Parent = MainFrame
        
        local dropTween = TweenService:Create(dot, TweenInfo.new(1.5, Enum.EasingStyle.Linear), {
            Position = UDim2.new(dot.Position.X.Scale, 0, 1, math.random(20, 50)),
            BackgroundTransparency = 1
        })
        dropTween:Play()
        dropTween.Completed:Connect(function()
            dot:Destroy()
        end)
        
        task.wait(0.3)
    end
end)()

-- Fade In/Out Animation on Startup
local function ToggleUI(state)
    if state then
        MainFrame.Visible = true
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0.1}):Play()
        TweenService:Create(MainStroke, TweenInfo.new(0.3), {Transparency = 0}):Play()
    else
        local t1 = TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1})
        local t2 = TweenService:Create(MainStroke, TweenInfo.new(0.2), {Transparency = 1})
        t1:Play()
        t2:Play()
        t1.Completed:Wait()
        MainFrame.Visible = false
    end
end

-- Top Tabs & Pages System (نظام الاختيارات والصفحات في المنتصف)
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(0, 320, 0, 30)
TabBar.Position = UDim2.new(0.5, -160, 0, 10)
TabBar.BackgroundTransparency = 1
TabBar.Parent = MainFrame

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.FillDirection = Enum.FillDirection.Horizontal
TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 10)
TabListLayout.Parent = TabBar

local PagesFolder = Instance.new("Folder")
PagesFolder.Name = "PagesFolder"
PagesFolder.Parent = MainFrame

local function CreateTabAndPage(name, order)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0, 95, 0, 28)
    tabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    tabBtn.Text = name
    tabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.TextSize = 12
    tabBtn.LayoutOrder = order
    tabBtn.AutoButtonColor = false
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = tabBtn
    tabBtn.Parent = TabBar
    
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, -20, 1, -65)
    page.Position = UDim2.new(0, 10, 0, 50)
    page.BackgroundTransparency = 1
    page.Visible = (order == 1)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.ScrollBarThickness = 4
    page.Parent = PagesFolder
    
    local pageLayout = Instance.new("UIListLayout")
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Padding = UDim.new(0, 8)
    pageLayout.Parent = page
    
    tabBtn.MouseButton1Click:Connect(function(x, y)
        CreateRipple(tabBtn, x, y)
        for _, p in pairs(PagesFolder:GetChildren()) do
            p.Visible = (p.Name == name .. "Page")
        end
        for _, b in pairs(TabBar:GetChildren()) do
            if b:IsA("TextButton") then
                TweenService:Create(b, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 40)}):Play()
            end
        end
        TweenService:Create(tabBtn, TweenInfo.new(0.2), {BackgroundColor3 = AccentColor}):Play()
    end)
    
    if order == 1 then
        tabBtn.BackgroundColor3 = AccentColor
    end
    
    return page
end

local Page1 = CreateTabAndPage("Main Page", 1)
local Page2 = CreateTabAndPage("Features", 2)
local Page3 = CreateTabAndPage("Settings", 3)

-- Central Label System (نظام lebel في النص)
local function AddLabel(parent, textContent)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 25)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = textContent
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    lbl.Parent = parent
    return lbl
end

AddLabel(Page1, "مرحباً بك في الواجهة الاحترافية الأسطورية")

-- Button System with Borders (نظام زر BUTTON مع إطار متناسق كمثل Toggle)
local function AddButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamSemibold
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = AccentColor
    stroke.Thickness = 1.5
    stroke.Parent = btn
    
    btn.MouseButton1Click:Connect(function(x, y)
        CreateRipple(btn, x, y)
        if callback then callback() end
    end)
    
    btn.Parent = parent
    return btn
end

-- Custom Button System (زر تخصيص مع زر عايم على اليسار ونافذة منبثقة للخصائص)
local function AddCustomButton(parent, text, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 35)
    container.BackgroundTransparency = 1
    
    -- Main Custom Button
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -40, 1, 0)
    btn.Position = UDim2.new(0, 40, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamSemibold
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = AccentColor
    stroke.Thickness = 1.5
    stroke.Parent = btn
    
    btn.MouseButton1Click:Connect(function(x, y)
        CreateRipple(btn, x, y)
        if callback then callback() end
    end)
    btn.Parent = container
    
    -- Small Floating Left Button (زر عايم ممتد من أعلى لأسفل بحاجز بنفسجي)
    local floatBtn = Instance.new("TextButton")
    floatBtn.Size = UDim2.new(0, 32, 1, -4)
    floatBtn.Position = UDim2.new(0, 2, 0, 2)
    floatBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    floatBtn.BackgroundTransparency = 0.3
    floatBtn.Text = "⚙"
    floatBtn.TextColor3 = AccentColor
    floatBtn.Font = Enum.Font.GothamBold
    floatBtn.TextSize = 14
    floatBtn.AutoButtonColor = false
    
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 4)
    fc.Parent = floatBtn
    
    local fstroke = Instance.new("UIStroke")
    fstroke.Color = AccentColor
    fstroke.Thickness = 1
    fstroke.Parent = floatBtn
    
    -- Floating Settings Sub-Panel (النافذة التي يفتحها الزر العايم)
    local subPanel = Instance.new("Frame")
    subPanel.Size = UDim2.new(0, 180, 0, 110)
    subPanel.Position = UDim2.new(0, 40, 1, 5)
    subPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
    subPanel.Visible = false
    subPanel.ZIndex = 5
    
    local sc = Instance.new("UICorner")
    sc.CornerRadius = UDim.new(0, 6)
    sc.Parent = subPanel
    
    local sstroke = Instance.new("UIStroke")
    sstroke.Color = AccentColor
    sstroke.Thickness = 1
    sstroke.Parent = subPanel
    
    local spLayout = Instance.new("UIListLayout")
    spLayout.SortOrder = Enum.SortOrder.LayoutOrder
    spLayout.Padding = UDim.new(0, 5)
    spLayout.Parent = subPanel
    
    -- SubPanel Title/Content
    local subLbl = Instance.new("TextLabel")
    subLbl.Size = UDim2.new(1, 0, 0, 25)
    subLbl.BackgroundTransparency = 1
    subLbl.Text = "تخصيص: " .. text
    subLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    subLbl.Font = Enum.Font.GothamBold
    subLbl.TextSize = 11
    subLbl.Parent = subPanel
    
    floatBtn.MouseButton1Click:Connect(function()
        subPanel.Visible = not subPanel.Visible
    end)
    
    floatBtn.Parent = container
    subPanel.Parent = container
    container.Parent = parent
    return container
end

-- Toggle System (نظام Toggle)
local function AddToggle(parent, text, defaultState, callback)
    local toggled = defaultState or false
    
    local container = Instance.new("TextButton")
    container.Size = UDim2.new(1, 0, 0, 35)
    container.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    container.AutoButtonColor = false
    container.Text = ""
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = container
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = AccentColor
    stroke.Thickness = 1.5
    stroke.Parent = container
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = container
    
    local switch = Instance.new("Frame")
    switch.Size = UDim2.new(0, 40, 0, 20)
    switch.Position = UDim2.new(1, -48, 0.5, -10)
    switch.BackgroundColor3 = toggled and AccentColor or Color3.fromRGB(50, 50, 60)
    
    local sc = Instance.new("UICorner")
    sc.CornerRadius = UDim.new(1, 0)
    sc.Parent = switch
    
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 16, 0, 16)
    circle.Position = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    
    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(1, 0)
    cc.Parent = circle
    circle.Parent = switch
    switch.Parent = container
    
    container.MouseButton1Click:Connect(function(x, y)
        CreateRipple(container, x, y)
        toggled = not toggled
        TweenService:Create(switch, TweenInfo.new(0.2), {BackgroundColor3 = toggled and AccentColor or Color3.fromRGB(50, 50, 60)}):Play()
        TweenService:Create(circle, TweenInfo.new(0.2), {Position = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
        if callback then callback(toggled) end
    end)
    
    container.Parent = parent
    return container
end

-- Slider System (نظام Slider السلس والسريع وغير المتجمد)
local function AddSlider(parent, text, min, max, default, callback)
    local val = default or min
    local draggingSlider = false
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 50)
    container.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = container
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = AccentColor
    stroke.Thickness = 1.5
    stroke.Parent = container
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 22)
    lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold
    lbl.Text = text .. ": " .. tostring(val)
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = container
    
    local sliderBar = Instance.new("Frame")
    sliderBar.Size = UDim2.new(1, -24, 0, 6)
    sliderBar.Position = UDim2.new(0, 12, 0, 32)
    sliderBar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    
    local sbc = Instance.new("UICorner")
    sbc.CornerRadius = UDim.new(1, 0)
    sbc.Parent = sliderBar
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((val - min)/(max - min), 0, 1, 0)
    fill.BackgroundColor3 = AccentColor
    
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(1, 0)
    fc.Parent = fill
    fill.Parent = sliderBar
    sliderBar.Parent = container
    
    local function updateValue(input)
        local pos = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
        val = math.floor(min + ((max - min) * pos))
        lbl.Text = text .. ": " .. tostring(val)
        fill.Size = UDim2.new(pos, 0, 1, 0)
        if callback then callback(val) end
    end
    
    sliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = true
            updateValue(input)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateValue(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = false
        end
    end)
    
    container.Parent = parent
    return container
end

-- Dropdown Menu System (نظام القائمة المنسدلة للأزرار)
local function AddDropdown(parent, title, options, callback)
    local opened = false
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 35)
    container.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    container.ClipsDescendants = true
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = container
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = AccentColor
    stroke.Thickness = 1.5
    stroke.Parent = container
    
    local mainBtn = Instance.new("TextButton")
    mainBtn.Size = UDim2.new(1, 0, 0, 35)
    mainBtn.BackgroundTransparency = 1
    mainBtn.Font = Enum.Font.GothamSemibold
    mainBtn.Text = "  " .. title .. " [ ▼ ]"
    mainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    mainBtn.TextSize = 13
    mainBtn.TextXAlignment = Enum.TextXAlignment.Left
    mainBtn.Parent = container
    
    local listHolder = Instance.new("Frame")
    listHolder.Size = UDim2.new(1, 0, 0, #options * 32)
    listHolder.Position = UDim2.new(0, 0, 0, 35)
    listHolder.BackgroundTransparency = 1
    
    local lhLayout = Instance.new("UIListLayout")
    lhLayout.SortOrder = Enum.SortOrder.LayoutOrder
    lhLayout.Padding = UDim.new(0, 4)
    lhLayout.Parent = listHolder
    
    for _, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, -10, 0, 28)
        optBtn.Position = UDim2.new(0, 5, 0, 0)
        optBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        optBtn.Font = Enum.Font.Gotham
        optBtn.Text = opt
        optBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        optBtn.TextSize = 12
        
        local oc = Instance.new("UICorner")
        oc.CornerRadius = UDim.new(0, 4)
        oc.Parent = optBtn
        
        optBtn.MouseButton1Click:Connect(function()
            mainBtn.Text = "  " .. title .. " (" .. opt .. ") [ ▼ ]"
            if callback then callback(opt) end
        end)
        optBtn.Parent = listHolder
    end
    
    listHolder.Parent = container
    
    mainBtn.MouseButton1Click:Connect(function()
        opened = not opened
        local targetHeight = opened and (35 + (#options * 32) + 5) or 35
        TweenService:Create(container, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, targetHeight)}):Play()
        mainBtn.Text = opened and ("  " .. title .. " [ ▲ ]") or ("  " .. title .. " [ ▼ ]")
    end)
    
    container.Parent = parent
    return container
end

-- Advanced Notification System (نظام الإشعارات المتقدم مع الشريط المتحرك، الصور، وإضاءة الحواف)
local NotificationHolder = Instance.new("Frame")
NotificationHolder.Name = "NotificationHolder"
NotificationHolder.Size = UDim2.new(0, 250, 1, -20)
NotificationHolder.Position = UDim2.new(1, -260, 0, 10)
NotificationHolder.BackgroundTransparency = 1
NotificationHolder.Parent = ScreenGui

local notifLayout = Instance.new("UIListLayout")
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.Padding = UDim.new(0, 8)
notifLayout.Parent = NotificationHolder

local function ShowNotification(title, message, duration, imagesList)
    duration = duration or 4
    
    local notifBox = Instance.new("TextButton")
    notifBox.Size = UDim2.new(1, 0, 0, imagesList and #imagesList > 0 and 110 or 70)
    notifBox.BackgroundColor3 = BackgroundColor
    notifBox.AutoButtonColor = false
    notifBox.Text = ""
    notifBox.BackgroundTransparency = 1
    
    local nc = Instance.new("UICorner")
    nc.CornerRadius = UDim.new(0, 8)
    nc.Parent = notifBox
    
    local nStroke = Instance.new("UIStroke")
    nStroke.Color = AccentColor
    nStroke.Thickness = 1.5
    nStroke.Parent = notifBox
    
    -- Title & Desc
    local tLbl = Instance.new("TextLabel")
    tLbl.Size = UDim2.new(1, -16, 0, 20)
    tLbl.Position = UDim2.new(0, 8, 0, 6)
    tLbl.BackgroundTransparency = 1
    tLbl.Font = Enum.Font.GothamBold
    tLbl.Text = title
    tLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    tLbl.TextSize = 13
    tLbl.TextXAlignment = Enum.TextXAlignment.Left
    tLbl.Parent = notifBox
    
    local mLbl = Instance.new("TextLabel")
    mLbl.Size = UDim2.new(1, -16, 0, 20)
    mLbl.Position = UDim2.new(0, 8, 0, 26)
    mLbl.BackgroundTransparency = 1
    mLbl.Font = Enum.Font.Gotham
    mLbl.Text = message
    mLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    mLbl.TextSize = 11
    mLbl.TextXAlignment = Enum.TextXAlignment.Left
    mLbl.Parent = notifBox
    
    -- Images with Glowing Edge Border
    if imagesList and #imagesList > 0 then
        local imgHolder = Instance.new("Frame")
        imgHolder.Size = UDim2.new(1, -16, 0, 40)
        imgHolder.Position = UDim2.new(0, 8, 0, 55)
        imgHolder.BackgroundTransparency = 1
        
        local ihLayout = Instance.new("UIListLayout")
        ihLayout.FillDirection = Enum.FillDirection.Horizontal
        ihLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ihLayout.Padding = UDim.new(0, 8)
        ihLayout.Parent = imgHolder
        
        for _, imgId in ipairs(imagesList) do
            local imgBox = Instance.new("ImageLabel")
            imgBox.Size = UDim2.new(0, 40, 0, 40)
            imgBox.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            imgBox.Image = "rbxassetid://" .. tostring(imgId)
            
            local ic = Instance.new("UICorner")
            ic.CornerRadius = UDim.new(0, 6)
            ic.Parent = imgBox
            
            -- Glowing Edge Effect matching UI Color
            local istroke = Instance.new("UIStroke")
            istroke.Color = AccentColor
            istroke.Thickness = 1.5
            istroke.Parent = imgBox
            
            imgBox.Parent = imgHolder
        end
        imgHolder.Parent = notifBox
    end
    
    -- Progress Bar (شريط يتحرك بمرور الوقت)
    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(1, 0, 0, 3)
    progressBar.Position = UDim2.new(0, 0, 1, -3)
    progressBar.BackgroundColor3 = AccentColor
    progressBar.BorderSizePixel = 0
    progressBar.Parent = notifBox
    
    -- Entry Animation
    TweenService:Create(notifBox, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0.1}):Play()
    TweenService:Create(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 3)}):Play()
    
    -- Dismiss on click
    notifBox.MouseButton1Click:Connect(function()
        local outT = TweenService:Create(notifBox, TweenInfo.new(0.2), {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0)})
        outT:Play()
        outT.Completed:Connect(function() notifBox:Destroy() end)
    end)
    
    notifBox.Parent = NotificationHolder
    
    -- Auto Dismiss after duration
    coroutine.wrap(function()
        task.wait(duration)
        if notifBox and notifBox.Parent then
            local outT = TweenService:Create(notifBox, TweenInfo.new(0.2), {BackgroundTransparency = 1})
            outT:Play()
            outT.Completed:Connect(function() notifBox:Destroy() end)
        end
    end)()
end

-- ==================== بناء محتوى الصفحات وأمثلة الاستخدام ====================

-- الصفحة الرئيسية (Page 1)
AddButton(Page1, "تشغيل الوظيفة الأساسية", function()
    ShowNotification("إشعار تفاعلي", "تم تنفيذ الوظيفة بنجاح عبر الزر القياسي!", 3, {6023426915})
end)

AddCustomButton(Page1, "زر مخصص متقدم", function()
    ShowNotification("زر عايم", "تم الضغط على الزر المخصص بنجاح.", 3)
end)

AddToggle(Page1, "تفعيل الحماية المتقدمة", true, function(state)
    ShowNotification("الحالة تغيرت", "حالة التوجل أصبحت: " .. tostring(state), 2)
end)

-- صفحة المميزات (Page 2)
AddSlider(Page2, "سرعة الحركة (Speed)", 1, 100, 50, function(v)
    -- القيمة المتغيرة للسلايدر
end)

AddDropdown(Page2, "قائمة الأسلحة المنسدلة", {"السكين (Knife)", "المسدس (Gun)", "الحقيبة (Bag)"}, function(selected)
    ShowNotification("اخترت عنصراً", "تم اختيار: " .. selected, 2)
end)

-- صفحة الإعدادات (Page 3)
AddLabel(Page3, "إعدادات النظام المتقدمة")
AddButton(Page3, "إخفاء/إظهار الواجهة", function()
    ToggleUI(false)
    task.wait(2)
    ToggleUI(true)
end)

-- Startup Greeting Notification
task.spawn(function()
    task.wait(0.5)
    ToggleUI(true)
    ShowNotification("نظام الواجهة جاهز", "تم تحميل السكربت بنجاح بواسطة bode. استمتع بالتجربة!", 4)
end)
