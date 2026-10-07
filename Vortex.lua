--[[
	=====================================================================
	 ProUI Library v3 - مكتبة واجهة احترافية (Roblox LocalScript / Module)
	 هذا الملف مكتبة فقط (بدون إنشاء نافذة تلقائي). مثال الاستخدام بآخر الملف.

	 الأنظمة:
	   Library.CreateWindow(config)                     نافذة
	   Window:CreateTab(name, emoji)                    تبويب (إيموجي مو آيكون)
	   Tab:CreateButton / Toggle / Slider / Textbox / Dropdown / ColorPicker
	   Tab:CreateNote(title, text, "Dark"|"Blue")       ملاحظة (تحتاج نافذة سليمة)
	   Tab:CreateLabel(text, opts)                      Label بالنص
	   Tab:CreateFoldout(name, buttons, open)           قائمة منسدلة للأزرار
	   Tab:CreateSelector({"A","B"}, cb)                أزرار اختيارات بالنص (كل خيار صفحة)
	   Library.CreateFloatButton(cfg)                   زر عايم (يسار) + إعداداته
	   Library.Notify(title,text,desc,duration,cb)      إشعار (شريط يتحرك + ضغط)
	   Library.NotifyImage(title,text,{ids},desc,dur,cb) إشعار + صور (حد أقصى 3)
	   Library.AddGradient({Target=...})                نظام التدرج المستقل
	   Library.SetLanguage("ar"/"en")
	=====================================================================
]]

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService       = game:GetService("GuiService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- تنظيف أي نسخة قديمة
pcall(function()
	if getgenv and getgenv().ProUILibrary and getgenv().ProUILibrary.Destroy then
		getgenv().ProUILibrary.Destroy()
	end
end)
local old = playerGui:FindFirstChild("ProUI_Main")
if old then old:Destroy() end

--============================================================
-- 1) ScreenGui + تتبع الاتصالات (ينظف نفسه عند الحذف)
--============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ProUI_Main"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local connections = {}
local function track(conn)
	connections[#connections + 1] = conn
	return conn
end
screenGui.Destroying:Connect(function()
	for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
	connections = {}
end)

local LIB_VERSION, MIN_WINDOW_VERSION = 3, 3
local WINDOW_SIG = {} -- بصمة فريدة: نافذة قديمة/مقلّدة ما تملكها

local Library = {}
-- لون الواجهة الحالي (الإشعارات تاخذ منه)
local themeState = { accent = Color3.fromRGB(46, 224, 150), base = Color3.fromRGB(120, 50, 220) }

--============================================================
-- 2) الألوان والثوابت
--============================================================
local COLOR_BLUE   = Color3.fromRGB(46, 116, 255)
local COLOR_GREEN  = Color3.fromRGB(46, 224, 150)
local COLOR_PURPLE = Color3.fromRGB(150, 70, 255)
local COLOR_RED    = Color3.fromRGB(225, 60, 70)
local COLOR_ORANGE = Color3.fromRGB(255, 150, 60)
local COLOR_PINK   = Color3.fromRGB(255, 110, 180)
local COLOR_YELLOW = Color3.fromRGB(240, 220, 80)
local COLOR_CYAN   = Color3.fromRGB(45, 195, 255)
local COLOR_SKY    = Color3.fromRGB(110, 185, 255)
local COLOR_TEAL   = Color3.fromRGB(45, 200, 185)
local COLOR_DARK   = Color3.fromRGB(38, 40, 46)
local COLOR_BLACK  = Color3.fromRGB(8, 8, 10)
local COLOR_GRAY   = Color3.fromRGB(120, 122, 132)
local COLOR_OFF    = Color3.fromRGB(60, 62, 72)
local WHITE        = Color3.new(1, 1, 1)

local NAMED_COLORS = {
	blue = COLOR_BLUE,          ["أزرق"] = COLOR_BLUE,
	green = COLOR_GREEN,        ["أخضر"] = COLOR_GREEN,
	purple = COLOR_PURPLE,      ["بنفسجي"] = COLOR_PURPLE,
	red = COLOR_RED,            ["أحمر"] = COLOR_RED,
	orange = COLOR_ORANGE,      ["برتقالي"] = COLOR_ORANGE,
	pink = COLOR_PINK,          ["وردي"] = COLOR_PINK,
	yellow = COLOR_YELLOW,      ["أصفر"] = COLOR_YELLOW,
	cyan = COLOR_CYAN,          ["سماوي"] = COLOR_CYAN,
	sky = COLOR_SKY,            skyblue = COLOR_SKY, ["sky blue"] = COLOR_SKY,
	teal = COLOR_TEAL,          turquoise = COLOR_TEAL, ["تركواز"] = COLOR_TEAL,
	white = WHITE,              ["أبيض"] = WHITE,
	black = COLOR_BLACK,        ["أسود"] = COLOR_BLACK,
	dark = COLOR_DARK,          iron = COLOR_DARK, gunmetal = COLOR_DARK, ["درك"] = COLOR_DARK, ["غامق"] = COLOR_DARK,
	gray = COLOR_GRAY,          ["رمادي"] = COLOR_GRAY,
}

-- أول قيمة موجودة من مفاتيح متعددة
local function pick(t, ...)
	for _, k in ipairs({ ... }) do
		if t[k] ~= nil then return t[k] end
	end
	return nil
end

local function resolveColor(value, fallback)
	if typeof(value) == "Color3" then return value end
	if type(value) == "string" then
		local c = NAMED_COLORS[value:lower()]
		if c then return c end
		local hex = value:gsub("#", "")
		if #hex == 6 and tonumber(hex, 16) then
			return Color3.fromRGB(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16))
		end
	end
	return fallback
end

local EASE_SOFT   = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local EASE_BOUNCE = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local EASE_FAST   = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local EASE_PRESS_DOWN = TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local EASE_PRESS_UP   = TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local EASE_CLOSE  = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

--============================================================
-- 3) اللغة
--============================================================
local STRINGS = {
	ar = {
		close_title = "تأكيد حذف السكربت",
		close_text = "هل تريد حذف السكربت نهائياً؟ لا يمكن التراجع بعدها.",
		yes = "نعم", no = "لا",
		open_text = "OPEN",
		search_placeholder = "بحث...",
		pick_start = "تأكيد", pick_cancel = "إلغاء",
		nearest_color = "أقرب اسم",
		notif_default = "إشعار",
		float_title = "إعدادات الزر",
		float_border = "لون الحاجز",
		float_name = "اسم الزر",
		float_size = "حجم الزر",
		float_func = "وظيفة الزر",
		float_func_hint = "افتح خانة الكود (فاضية = الوظيفة من السكربت)",
		float_delete = "حذف الزر",
		float_save = "حفظ",
		float_close = "إغلاق",
		float_code_title = "وظيفة الزر (كود Lua)",
		float_code_hint = "اكتب كود Lua هنا. لو تركته فاضي تشتغل الوظيفة من Callback بكود السكربت.",
		float_saved = "تم حفظ وظيفة الزر",
		float_code_err = "خطأ في كود الزر",
	},
	en = {
		close_title = "Confirm Script Deletion",
		close_text = "Delete the script permanently? This cannot be undone.",
		yes = "Yes", no = "No",
		open_text = "OPEN",
		search_placeholder = "Search...",
		pick_start = "Confirm", pick_cancel = "Cancel",
		nearest_color = "Nearest",
		notif_default = "Notification",
		float_title = "Button Settings",
		float_border = "Border color",
		float_name = "Button name",
		float_size = "Button size",
		float_func = "Button function",
		float_func_hint = "Open the code box (empty = use script Callback)",
		float_delete = "Delete button",
		float_save = "Save",
		float_close = "Close",
		float_code_title = "Button function (Lua code)",
		float_code_hint = "Write Lua code here. Leave empty to use the Callback from your script.",
		float_saved = "Button function saved",
		float_code_err = "Button code error",
	},
}
local currentLang = "ar"
local function T(key) return (STRINGS[currentLang] or STRINGS.ar)[key] or key end

--============================================================
-- 4) أدوات مساعدة
--============================================================
local function tween(obj, info, props)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function round(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius or UDim.new(0, 10)
	c.Parent = obj
	return c
end

local function stroke(obj, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0.5
	s.Parent = obj
	return s
end

local function newLabel(parent, text, font, size, color, pos, sz, align, z)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.Font = font
	l.TextSize = size
	l.TextColor3 = color
	l.TextXAlignment = align or Enum.TextXAlignment.Left
	l.Position = pos or UDim2.new()
	l.Size = sz or UDim2.new(1, 0, 1, 0)
	l.ZIndex = z or 8
	l.Parent = parent
	return l
end

local function isPointer(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

-- موضع المؤشر بإحداثيات الشاشة الكاملة (IgnoreGuiInset = true)
local function ptr(input)
	local p = input.Position
	local ok, inset = pcall(function() return GuiService:GetGuiInset() end)
	if ok and inset then return Vector2.new(p.X + inset.X, p.Y + inset.Y) end
	return Vector2.new(p.X, p.Y)
end

-- موزّع واحد لأحداث السحب (بدل اتصال لكل عنصر)
local moveHandlers, endHandlers = {}, {}
track(UserInputService.InputChanged:Connect(function(input)
	for i = 1, #moveHandlers do pcall(moveHandlers[i], input) end
end))
track(UserInputService.InputEnded:Connect(function(input)
	for i = 1, #endHandlers do pcall(endHandlers[i], input) end
end))

local function isMoveFor(active, input)
	if input.UserInputType == Enum.UserInputType.Touch then return input == active end
	return input.UserInputType == Enum.UserInputType.MouseMovement
		and active.UserInputType == Enum.UserInputType.MouseButton1
end
local function sameEnd(active, input)
	return input == active or (active.UserInputType == Enum.UserInputType.MouseButton1
		and input.UserInputType == Enum.UserInputType.MouseButton1)
end

local function createRipple(parentButton, pos)
	local absPos, absSize = parentButton.AbsolutePosition, parentButton.AbsoluteSize
	if absSize.X <= 0 or absSize.Y <= 0 then return end
	local ripple = Instance.new("Frame")
	ripple.BackgroundColor3 = WHITE
	ripple.BackgroundTransparency = 0.55
	ripple.BorderSizePixel = 0
	ripple.ZIndex = parentButton.ZIndex + 5
	ripple.AnchorPoint = Vector2.new(0.5, 0.5)
	round(ripple, UDim.new(1, 0))
	local relX, relY = 0.5, 0.5
	if pos then
		relX = (pos.X - absPos.X) / absSize.X
		relY = (pos.Y - absPos.Y) / absSize.Y
	end
	ripple.Position = UDim2.new(relX, 0, relY, 0)
	ripple.Size = UDim2.new(0, 0, 0, 0)
	ripple.Parent = parentButton
	local maxD = math.sqrt(absSize.X ^ 2 + absSize.Y ^ 2) * 2
	local t = tween(ripple, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, maxD, 0, maxD), BackgroundTransparency = 1,
	})
	t.Completed:Connect(function() ripple:Destroy() end)
end

-- تأثير الضغط: ينزل بسرعة ويرجع حتى لو رفعت إصبعك خارج الزر
local pendingReleases = {}
endHandlers[#endHandlers + 1] = function(input)
	if not isPointer(input) then return end
	for i = #pendingReleases, 1, -1 do
		local fn = pendingReleases[i]
		pendingReleases[i] = nil
		pcall(fn)
	end
end

local function applyPressEffect(button, shrink)
	shrink = shrink or 0.92
	button.ClipsDescendants = true
	local base, pressed = nil, false
	button.InputBegan:Connect(function(input)
		if not isPointer(input) or pressed then return end
		pressed = true
		base = button.Size
		tween(button, EASE_PRESS_DOWN, { Size = UDim2.new(
			base.X.Scale * shrink, base.X.Offset * shrink, base.Y.Scale * shrink, base.Y.Offset * shrink) })
		createRipple(button, ptr(input))
		pendingReleases[#pendingReleases + 1] = function()
			if not pressed then return end
			pressed = false
			if button.Parent then tween(button, EASE_PRESS_UP, { Size = base }) end
		end
	end)
end

-- سحب بإصبع واحد (سلايدر / منتقي ألوان)
local function makeSingleTouchDraggable(hitArea, onUpdate)
	local active = nil
	hitArea.InputBegan:Connect(function(input)
		if not isPointer(input) or active ~= nil then return end
		active = input
		onUpdate(ptr(input))
	end)
	moveHandlers[#moveHandlers + 1] = function(input)
		if not active or not isMoveFor(active, input) then return end
		onUpdate(ptr(input))
	end
	endHandlers[#endHandlers + 1] = function(input)
		if active and sameEnd(active, input) then active = nil end
	end
end

-- سحب أي Frame/زر. opts: Container, Threshold, OnDragFlag, CanDrag, OnBegin, OnEnd
local function makeFrameDraggable(handle, target, opts)
	opts = opts or {}
	local threshold = opts.Threshold or 0
	local active, startPtr, startAbs, dragged = nil, nil, nil, false

	handle.InputBegan:Connect(function(input)
		if not isPointer(input) or active ~= nil then return end
		if opts.CanDrag and not opts.CanDrag() then return end
		active, startPtr, startAbs, dragged = input, ptr(input), target.AbsolutePosition, false
		if opts.OnDragFlag then opts.OnDragFlag(false) end
	end)

	moveHandlers[#moveHandlers + 1] = function(input)
		if not active or not isMoveFor(active, input) then return end
		local p = ptr(input)
		local dx, dy = p.X - startPtr.X, p.Y - startPtr.Y
		if not dragged then
			if math.abs(dx) <= threshold and math.abs(dy) <= threshold then return end
			dragged = true
			if opts.OnDragFlag then opts.OnDragFlag(true) end
			if opts.OnBegin then opts.OnBegin() end
		end
		local size = target.AbsoluteSize
		local minX, minY, maxX, maxY
		local c = opts.Container
		if c then
			local cp, cs = c.AbsolutePosition, c.AbsoluteSize
			minX, minY = cp.X, cp.Y
			maxX, maxY = cp.X + cs.X - size.X, cp.Y + cs.Y - size.Y
		else
			local vs = screenGui.AbsoluteSize
			minX, minY = 0, 0
			maxX, maxY = vs.X - size.X, vs.Y - size.Y
		end
		local x = math.clamp(startAbs.X + dx, minX, math.max(maxX, minX))
		local y = math.clamp(startAbs.Y + dy, minY, math.max(maxY, minY))
		local anchor = target.AnchorPoint
		local parentAbs = target.Parent and target.Parent.AbsolutePosition or Vector2.new(0, 0)
		target.Position = UDim2.fromOffset(x - parentAbs.X + size.X * anchor.X, y - parentAbs.Y + size.Y * anchor.Y)
	end

	endHandlers[#endHandlers + 1] = function(input)
		if active and sameEnd(active, input) then
			local wasDragged = dragged
			active = nil
			if wasDragged and opts.OnEnd then opts.OnEnd() end
		end
	end

	return { WasDragged = function() return dragged end }
end

local function popOpen(frame, size)
	frame.Visible = true
	frame.Size = UDim2.new(0, 0, 0, 0)
	tween(frame, EASE_BOUNCE, { Size = size })
end
local function popClose(frame)
	local t = tween(frame, EASE_CLOSE, { Size = UDim2.new(0, 0, 0, 0) })
	t.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed then frame.Visible = false end
	end)
end

local function hexToColor3(hex)
	hex = hex:gsub("#", "")
	if #hex ~= 6 then return nil end
	local r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
	if not (r and g and b) then return nil end
	return Color3.fromRGB(r, g, b)
end

local function color3ToHex(c)
	return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

local function nearestColorName(c)
	local bestName, bestDist = "Custom", math.huge
	for name, col in pairs(NAMED_COLORS) do
		local d = (col.R - c.R) ^ 2 + (col.G - c.G) ^ 2 + (col.B - c.B) ^ 2
		if d < bestDist then bestDist, bestName = d, name end
	end
	return bestName:sub(1, 1):upper() .. bestName:sub(2)
end

local function toImage(id)
	if type(id) == "number" then return "rbxassetid://" .. tostring(id) end
	id = tostring(id)
	if id:match("^%d+$") then return "rbxassetid://" .. id end
	return id
end

--============================================================
-- 5) محرك التدرج (محرّك واحد لكل شيء = أداء أسرع)
--============================================================
local rotating, animated = {}, {}
local hbAcc = 0

local function lerpSeq(a, b, f)
	local kps = {}
	local bk = b.Keypoints
	for i, kp in ipairs(a.Keypoints) do
		local o = bk[i] or kp
		kps[#kps + 1] = ColorSequenceKeypoint.new(kp.Time, kp.Value:Lerp(o.Value, f))
	end
	return ColorSequence.new(kps)
end

track(RunService.Heartbeat:Connect(function(dt)
	for i = #rotating, 1, -1 do
		local r = rotating[i]
		if r.holder:IsDescendantOf(screenGui) then
			r.obj.Rotation = (r.obj.Rotation + r.speed * dt) % 360
		else
			table.remove(rotating, i)
		end
	end
	hbAcc = hbAcc + dt
	if hbAcc >= 0.04 then
		local step = hbAcc
		hbAcc = 0
		for i = #animated, 1, -1 do
			local a = animated[i]
			if a.grad:IsDescendantOf(screenGui) then
				a.t = a.t + step
				local phase = a.t / a.cycle
				local n = #a.seqs
				local idx = math.floor(phase) % n + 1
				local nxt = idx % n + 1
				local f = phase - math.floor(phase)
				f = f * f * (3 - 2 * f)
				a.grad.Color = lerpSeq(a.seqs[idx], a.seqs[nxt], f)
			else
				table.remove(animated, i)
			end
		end
	end
end))

local function animateGradient(gradient, seqs, cycle)
	animated[#animated + 1] = { grad = gradient, seqs = seqs, cycle = cycle or 4, t = 0 }
end

local function spinGradient(gradient, holder, speed)
	rotating[#rotating + 1] = { obj = gradient, holder = holder, speed = speed }
end

-- نظام التدرج المستقل (مناطق)
local GRAD_KIND = {
	OpenButton = "fill", OpenButtonBorder = "border",
	Window = "fill", WindowBorder = "border",
	ButtonBorders = "border", FloatButtonBorder = "border",
}
local gradSpecs, gradTargets = {}, {}

local function buildSeq(colors)
	if type(colors) ~= "table" then colors = { colors } end
	local list = {}
	for _, c in ipairs(colors) do list[#list + 1] = resolveColor(c, COLOR_GREEN) end
	if #list == 0 then list = { COLOR_GREEN, COLOR_PURPLE } end
	if #list == 1 then list[2] = list[1] end
	local kps, n = {}, #list
	for i = 1, n do kps[#kps + 1] = ColorSequenceKeypoint.new((i - 1) / n, list[i]) end
	kps[#kps + 1] = ColorSequenceKeypoint.new(1, list[1]) -- حلقة سلسة
	return ColorSequence.new(kps)
end

local function applyOne(spec, t)
	local inst = t.inst
	if not inst.Parent then return end
	local holder
	if t.kind == "border" then
		holder = Instance.new("UIStroke")
		holder.Color = WHITE
		holder.Thickness = spec.Thickness
		holder.Transparency = 1 - spec.Strength
		holder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	else
		holder = Instance.new("Frame")
		holder.BackgroundColor3 = WHITE
		holder.BackgroundTransparency = 1 - spec.Strength
		holder.BorderSizePixel = 0
		holder.Size = UDim2.new(1, 0, 1, 0)
		holder.ZIndex = inst.ZIndex
		round(holder, t.radius)
	end
	local g = Instance.new("UIGradient")
	g.Color = spec.Sequence
	g.Rotation = spec.Angle
	g.Parent = holder
	holder.Parent = inst
	spinGradient(g, holder, spec.Speed)
	spec.Applied[#spec.Applied + 1] = holder
end

local function registerTarget(name, inst, kind)
	local corner = inst:FindFirstChildOfClass("UICorner")
	local t = { inst = inst, kind = kind, radius = corner and corner.CornerRadius or UDim.new(0, 0) }
	gradTargets[name] = gradTargets[name] or {}
	table.insert(gradTargets[name], t)
	for _, spec in ipairs(gradSpecs) do
		if spec.Target == name then applyOne(spec, t) end
	end
end

local function unregisterTarget(inst)
	for _, list in pairs(gradTargets) do
		for i = #list, 1, -1 do
			if list[i].inst == inst then table.remove(list, i) end
		end
	end
end

--============================================================
-- 6) نظام الإشعارات (شريط يتحرك + ضغط + صور)
--============================================================
local notifRoot = Instance.new("Frame")
notifRoot.BackgroundTransparency = 1
notifRoot.AnchorPoint = Vector2.new(1, 1)
notifRoot.Position = UDim2.new(1, -18, 1, -18)
notifRoot.Size = UDim2.new(0, 270, 0, 0)
notifRoot.AutomaticSize = Enum.AutomaticSize.Y
notifRoot.ZIndex = 100
notifRoot.Parent = screenGui

local notifLayout = Instance.new("UIListLayout")
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
notifLayout.Padding = UDim.new(0, 10)
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.Parent = notifRoot

local notifCounter = 0

local function buildNotification(o)
	if not screenGui.Parent then return end
	local duration = math.max(tonumber(o.Duration) or 4, 0.5)
	local accentC = themeState.accent
	local bg = themeState.base:Lerp(Color3.new(0, 0, 0), 0.72)

	notifCounter = notifCounter + 1
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(0, 270, 0, 0)
	holder.AutomaticSize = Enum.AutomaticSize.Y
	holder.LayoutOrder = notifCounter
	holder.ZIndex = 101
	holder.Parent = notifRoot

	local card = Instance.new("TextButton")
	card.Text = ""
	card.AutoButtonColor = false
	card.BackgroundColor3 = bg
	card.BackgroundTransparency = 0.05
	card.BorderSizePixel = 0
	card.Size = UDim2.new(1, 0, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.ClipsDescendants = true
	card.Position = UDim2.new(0, 300, 0, 0)
	card.ZIndex = 101
	card.Parent = holder
	round(card, UDim.new(0, 12))
	stroke(card, accentC, 1.2, 0.35)

	local content = Instance.new("Frame")
	content.BackgroundTransparency = 1
	content.Size = UDim2.new(1, 0, 0, 0)
	content.AutomaticSize = Enum.AutomaticSize.Y
	content.ZIndex = 102
	content.Parent = card
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 14), UDim.new(0, 12)
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 18), UDim.new(0, 12)
	pad.Parent = content
	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0, 3)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Parent = content

	-- الشريط المتحرك (يروح = يروح الإشعار)
	local barBack = Instance.new("Frame")
	barBack.BackgroundColor3 = Color3.new(0, 0, 0)
	barBack.BackgroundTransparency = 0.6
	barBack.BorderSizePixel = 0
	barBack.Position = UDim2.new(0, 12, 0, 7)
	barBack.Size = UDim2.new(1, -24, 0, 3)
	barBack.ZIndex = 105
	barBack.Parent = card
	round(barBack, UDim.new(1, 0))
	local barFill = Instance.new("Frame")
	barFill.BackgroundColor3 = accentC
	barFill.BorderSizePixel = 0
	barFill.Size = UDim2.new(1, 0, 1, 0)
	barFill.ZIndex = 106
	barFill.Parent = barBack
	round(barFill, UDim.new(1, 0))

	local title = newLabel(content, tostring(o.Title or T("notif_default")), Enum.Font.GothamBold, 15, WHITE,
		UDim2.new(), UDim2.new(1, 0, 0, 18), Enum.TextXAlignment.Left, 102)
	title.LayoutOrder = 1

	local body = newLabel(content, tostring(o.Text or ""), Enum.Font.Gotham, 13, Color3.fromRGB(225, 225, 235),
		UDim2.new(), UDim2.new(1, 0, 0, 0), Enum.TextXAlignment.Left, 102)
	body.TextWrapped = true
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.LayoutOrder = 2

	if o.Desc and tostring(o.Desc) ~= "" then
		local d = newLabel(content, tostring(o.Desc), Enum.Font.Gotham, 11, Color3.fromRGB(165, 165, 180),
			UDim2.new(), UDim2.new(1, 0, 0, 0), Enum.TextXAlignment.Left, 102)
		d.TextWrapped = true
		d.AutomaticSize = Enum.AutomaticSize.Y
		d.LayoutOrder = 3
	end

	-- صور (الحد الأقصى 3) + إضاءة بلون الواجهة
	local imgs = o.Images
	if type(imgs) == "table" and #imgs > 0 then
		local row = Instance.new("Frame")
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 0, 84)
		row.LayoutOrder = 4
		row.ZIndex = 102
		row.Parent = content
		local rl = Instance.new("UIListLayout")
		rl.FillDirection = Enum.FillDirection.Horizontal
		rl.Padding = UDim.new(0, 14)
		rl.VerticalAlignment = Enum.VerticalAlignment.Center
		rl.SortOrder = Enum.SortOrder.LayoutOrder
		rl.Parent = row
		for i = 1, math.min(#imgs, 3) do
			local box = Instance.new("Frame")
			box.BackgroundTransparency = 1
			box.Size = UDim2.new(0, 60, 0, 60)
			box.LayoutOrder = i
			box.ZIndex = 102
			box.Parent = row

			local glow = Instance.new("ImageLabel")
			glow.BackgroundTransparency = 1
			glow.Image = "rbxassetid://5028857084"
			glow.ImageColor3 = accentC
			glow.ImageTransparency = 0.4
			glow.ScaleType = Enum.ScaleType.Slice
			glow.SliceCenter = Rect.new(24, 24, 276, 276)
			glow.AnchorPoint = Vector2.new(0.5, 0.5)
			glow.Position = UDim2.new(0.5, 0, 0.5, 0)
			glow.Size = UDim2.new(1, 24, 1, 24)
			glow.ZIndex = 102
			glow.Parent = box

			local img = Instance.new("ImageLabel")
			img.BackgroundColor3 = COLOR_DARK
			img.Image = toImage(imgs[i])
			img.ScaleType = Enum.ScaleType.Crop
			img.Size = UDim2.new(1, 0, 1, 0)
			img.ZIndex = 103
			img.Parent = box
			round(img, UDim.new(0, 10))
			stroke(img, accentC, 1.5, 0.15)
		end
	end

	local dismissed = false
	local barTween
	local function dismiss()
		if dismissed then return end
		dismissed = true
		if barTween then barTween:Cancel() end
		local t = tween(card, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Position = UDim2.new(0, 300, 0, 0) })
		t.Completed:Connect(function() holder:Destroy() end)
	end

	card.Activated:Connect(function()
		if dismissed then return end
		if o.Callback then
			local ok, err = pcall(o.Callback)
			if not ok then warn("[ProUI Notify Error]", err) end
		end
		dismiss()
	end)

	tween(card, EASE_BOUNCE, { Position = UDim2.new(0, 0, 0, 0) })
	barTween = TweenService:Create(barFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 1, 0) })
	barTween.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed then dismiss() end
	end)
	barTween:Play()
end

-- يقبل: (title, text, desc, duration, callback) بأي ترتيب للأرقام/الدوال/الجداول
-- أو جدول: {Title=, Text=, Desc=, Duration=, Images={...}, Callback=}
local function parseNotify(...)
	local args = table.pack(...)
	local start = (args[1] == Library) and 2 or 1
	local o, strings = {}, {}
	for i = start, args.n do
		local a = args[i]
		local ty = type(a)
		if ty == "table" and i == start and a[1] == nil then
			o.Title = pick(a, "Title", "Name")
			o.Text = pick(a, "Text", "Content", "Message")
			o.Desc = pick(a, "Desc", "Description")
			o.Duration = pick(a, "Duration", "Time")
			o.Callback = pick(a, "Callback", "OnClick", "Function", "Func")
			local im = pick(a, "Images", "Image", "Icons")
			if im ~= nil and type(im) ~= "table" then im = { im } end
			o.Images = im
		elseif ty == "table" then
			o.Images = a
		elseif ty == "function" then
			o.Callback = a
		elseif ty == "number" then
			o.Duration = a
		elseif a ~= nil then
			strings[#strings + 1] = tostring(a)
		end
	end
	o.Title = o.Title or strings[1]
	o.Text = o.Text or strings[2]
	o.Desc = o.Desc or strings[3]
	return o
end

--============================================================
-- 7) السبلاش الترحيبي
--============================================================
local function playIntroSplash(cfg, onDone)
	cfg = cfg or {}
	if cfg.Enabled == false then onDone() return end
	local text = cfg.Text or "Rwonom hub"
	local color = resolveColor(cfg.Color, COLOR_RED)
	local font = cfg.Font or Enum.Font.Creepster
	local pulses = tonumber(cfg.Pulses) or 2

	local logo = Instance.new("Frame")
	logo.AnchorPoint = Vector2.new(0.5, 0.5)
	logo.Position = UDim2.new(0.5, 0, 0.5, 0)
	logo.Size = UDim2.new(0, 0, 0, 0)
	logo.BackgroundColor3 = COLOR_BLACK
	logo.BackgroundTransparency = 1
	logo.Rotation = -180
	logo.ZIndex = 200
	logo.Parent = screenGui
	round(logo, UDim.new(0, 16))

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = font
	label.TextSize = 28
	label.TextColor3 = color
	label.TextTransparency = 1
	label.Size = UDim2.new(1, -10, 1, -10)
	label.Position = UDim2.new(0, 5, 0, 5)
	label.TextScaled = true
	label.ZIndex = 201
	label.Parent = logo

	task.spawn(function()
		tween(logo, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 170, 0, 170), Rotation = 0, BackgroundTransparency = 0,
		})
		tween(label, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 })
		task.wait(0.5)
		for _ = 1, pulses do
			tween(logo, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Size = UDim2.new(0, 184, 0, 184) })
			task.wait(0.25)
			tween(logo, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In), { Size = UDim2.new(0, 170, 0, 170) })
			task.wait(0.25)
		end
		-- الواجهة تفتح مع بداية الاختفاء (فورية)
		onDone()
		tween(logo, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0), Rotation = 180, BackgroundTransparency = 1,
		})
		tween(label, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 })
		task.wait(0.65)
		logo:Destroy()
	end)
end

--============================================================
-- 8) واجهة المكتبة العامة
--============================================================
Library.Version = LIB_VERSION
Library.PlaySplash = playIntroSplash
Library.FloatButtons = {}

function Library.SetLanguage(code)
	if STRINGS[code] then currentLang = code end
end

Library.Notify = function(...)
	buildNotification(parseNotify(...))
end
Library.NotifyImage = Library.Notify -- (title, text, {صور}, desc, duration, callback)

local function isWindowValid(win)
	return win ~= nil and win._sig == WINDOW_SIG
		and (win.Version or 0) >= MIN_WINDOW_VERSION
		and screenGui.Parent ~= nil
end

-- Library.AddGradient({Target=, Colors=, Speed=, Strength=, Thickness=, Angle=})
-- Target: OpenButton | OpenButtonBorder | Window | WindowBorder | ButtonBorders | FloatButtonBorder
-- كل استدعاء = تدرج جديد فوق القديم (مرتين = تدرجين)
Library.AddGradient = function(...)
	local args = { ... }
	if args[1] == Library then table.remove(args, 1) end
	local cfg = args[1] or {}
	local target = tostring(pick(cfg, "Target", "Area", "Zone") or "WindowBorder")
	local kind = GRAD_KIND[target]
	if not kind then
		warn("[ProUI] منطقة تدرج غير معروفة:", target)
		return nil
	end
	local spec = {
		Target = target,
		Sequence = buildSeq(pick(cfg, "Colors", "Color")),
		Speed = tonumber(pick(cfg, "Speed")) or 60,
		Strength = math.clamp(tonumber(pick(cfg, "Strength", "Power")) or (kind == "fill" and 0.35 or 1), 0, 1),
		Thickness = tonumber(pick(cfg, "Thickness")) or 2,
		Angle = tonumber(pick(cfg, "Angle")) or 0,
		Applied = {},
	}
	table.insert(gradSpecs, spec)
	for _, t in ipairs(gradTargets[target] or {}) do applyOne(spec, t) end
	return {
		Destroy = function()
			for _, h in ipairs(spec.Applied) do h:Destroy() end
			local i = table.find(gradSpecs, spec)
			if i then table.remove(gradSpecs, i) end
		end,
	}
end
Library.Gradient = { Add = Library.AddGradient }

Library.Destroy = function()
	pcall(function()
		if getgenv and getgenv().ProUILibrary == Library then getgenv().ProUILibrary = nil end
	end)
	if screenGui.Parent then screenGui:Destroy() end
end

--============================================================
-- 9) مصنع العناصر (يُستخدم في التبويبات / القوائم المنسدلة / الخيارات / إعدادات الزر)
--    ctx = { accent=Color3, window=Window|nil, popupDelta=function(+1/-1)|nil }
--============================================================
local makeElements
makeElements = function(container, ctx)
	local E = {}
	local order = 0
	local accent = ctx.accent or COLOR_GREEN

	local function place(inst)
		order = order + 1
		inst.LayoutOrder = order
		inst.Parent = container
		return inst
	end

	local function newRow(height)
		local row = Instance.new("Frame")
		row.BackgroundColor3 = WHITE
		row.BackgroundTransparency = 0.93
		row.BorderSizePixel = 0
		row.Size = UDim2.new(1, 0, 0, height)
		row.ZIndex = 7
		round(row, UDim.new(0, 10))
		return row
	end

	local function safe(cb, tag, ...)
		if not cb then return end
		local ok, err = pcall(cb, ...)
		if not ok then warn("[ProUI " .. tag .. " Error]", err) end
	end

	local function popup(d)
		if ctx.popupDelta then ctx.popupDelta(d) end
	end

	----------------------------------------------------------
	function E:CreateButton(name, desc, callback)
		if type(name) == "table" then
			local o = name
			name, desc, callback = pick(o, "Name", "Title", "Text"), pick(o, "Desc", "Description"), pick(o, "Callback", "Function", "Func")
		elseif type(desc) == "function" then
			callback, desc = desc, nil
		end
		name = tostring(name or "Button")
		desc = (desc ~= nil and tostring(desc) ~= "") and tostring(desc) or nil

		local wrap = newRow(desc and 52 or 36)
		wrap.BackgroundTransparency = 0.9
		stroke(wrap, accent, 1, 0.75)
		local grad = Instance.new("UIGradient")
		grad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, COLOR_GREEN), ColorSequenceKeypoint.new(1, COLOR_PURPLE) })
		grad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.85), NumberSequenceKeypoint.new(1, 0.85) })
		grad.Parent = wrap
		place(wrap)
		registerTarget("ButtonBorders", wrap, "border")

		local btn = Instance.new("TextButton")
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.BackgroundTransparency = 1
		btn.Size = UDim2.new(1, 0, 1, 0)
		btn.ZIndex = 8
		btn.Parent = wrap

		local nameLbl = newLabel(wrap, name, Enum.Font.GothamMedium, 14, WHITE,
			UDim2.new(0, 12, 0, desc and 6 or 9), UDim2.new(1, -24, 0, 18), Enum.TextXAlignment.Left, 8)
		nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
		local descLbl
		if desc then
			descLbl = newLabel(wrap, desc, Enum.Font.Gotham, 11, Color3.fromRGB(210, 210, 220),
				UDim2.new(0, 12, 0, 26), UDim2.new(1, -24, 0, 18), Enum.TextXAlignment.Left, 8)
			descLbl.TextTruncate = Enum.TextTruncate.AtEnd
		end

		applyPressEffect(btn, 0.95)
		btn.Activated:Connect(function() safe(callback, "Button") end)

		local api = { Instance = wrap }
		api.Fire = function() safe(callback, "Button") end
		api.SetText = function(_, t) nameLbl.Text = tostring(t) end
		api.SetDesc = function(_, t) if descLbl then descLbl.Text = tostring(t) end end
		api.Destroy = function() wrap:Destroy() end
		return api
	end

	----------------------------------------------------------
	function E:CreateToggle(name, desc, default, callback)
		if type(name) == "table" then
			local o = name
			name, desc = pick(o, "Name", "Title", "Text"), pick(o, "Desc", "Description")
			default, callback = pick(o, "Default", "Value", "State"), pick(o, "Callback", "Function", "Func")
		elseif type(desc) == "function" then
			callback, default, desc = desc, false, nil
		elseif type(desc) == "boolean" then
			callback, default, desc = default, desc, nil
		end
		name = tostring(name or "Toggle")
		desc = (desc ~= nil and tostring(desc) ~= "") and tostring(desc) or nil
		local state = default and true or false

		local row = newRow(desc and 52 or 40)
		place(row)
		newLabel(row, name, Enum.Font.Gotham, 14, WHITE,
			UDim2.new(0, 12, 0, desc and 6 or 11), UDim2.new(1, -70, 0, 18), Enum.TextXAlignment.Left, 8).TextTruncate = Enum.TextTruncate.AtEnd
		if desc then
			newLabel(row, desc, Enum.Font.Gotham, 11, Color3.fromRGB(210, 210, 220),
				UDim2.new(0, 12, 0, 26), UDim2.new(1, -70, 0, 18), Enum.TextXAlignment.Left, 8).TextTruncate = Enum.TextTruncate.AtEnd
		end

		local pill = Instance.new("TextButton")
		pill.Text = ""
		pill.AutoButtonColor = false
		pill.BackgroundColor3 = COLOR_OFF
		pill.Size = UDim2.new(0, 46, 0, 24)
		pill.AnchorPoint = Vector2.new(1, 0.5)
		pill.Position = UDim2.new(1, -12, 0.5, 0)
		pill.ZIndex = 8
		pill.Parent = row
		round(pill, UDim.new(1, 0))

		local knob = Instance.new("Frame")
		knob.BackgroundColor3 = WHITE
		knob.Size = UDim2.new(0, 18, 0, 18)
		knob.AnchorPoint = Vector2.new(0, 0.5)
		knob.Position = UDim2.new(0, 3, 0.5, 0)
		knob.ZIndex = 9
		knob.Parent = pill
		round(knob, UDim.new(1, 0))

		local function visual(animatedFlag)
			local col = state and accent or COLOR_OFF
			local pos = state and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
			if animatedFlag then
				tween(pill, EASE_SOFT, { BackgroundColor3 = col })
				tween(knob, EASE_BOUNCE, { Position = pos })
			else
				pill.BackgroundColor3 = col
				knob.Position = pos
			end
		end
		visual(false)

		pill.Activated:Connect(function()
			state = not state
			visual(true)
			safe(callback, "Toggle", state)
		end)
		applyPressEffect(pill, 0.9)

		return {
			Instance = row,
			Set = function(_, v, silent)
				state = v and true or false
				visual(true)
				if not silent then safe(callback, "Toggle", state) end
			end,
			Get = function() return state end,
		}
	end

	----------------------------------------------------------
	function E:CreateSlider(name, min, max, default, speed, callback)
		if type(name) == "table" then
			local o = name
			local v = pick(o, "Value")
			if type(v) == "table" then
				min, max, default = pick(v, "Min", "min"), pick(v, "Max", "max"), pick(v, "Default", "default")
			else
				min, max, default = pick(o, "Min"), pick(o, "Max"), pick(o, "Default", "Value")
			end
			speed, callback = pick(o, "Speed", "Step", "Increment"), pick(o, "Callback", "Function", "Func")
			name = pick(o, "Name", "Title", "Text")
		elseif type(speed) == "function" then
			callback, speed = speed, 1
		end
		name = tostring(name or "Slider")
		min, max, speed = tonumber(min) or 0, tonumber(max) or 100, tonumber(speed) or 1
		if speed <= 0 then speed = 1 end
		default = math.clamp(tonumber(default) or min, min, max)

		local function fmt(v)
			if speed >= 1 then return tostring(math.floor(v + 0.5)) end
			return string.format("%g", math.floor(v / speed + 0.5) * speed)
		end

		local row = newRow(54)
		place(row)
		newLabel(row, name, Enum.Font.Gotham, 14, WHITE, UDim2.new(0, 12, 0, 6), UDim2.new(1, -80, 0, 18), Enum.TextXAlignment.Left, 8)
		local valueLabel = newLabel(row, fmt(default), Enum.Font.GothamBold, 13, accent,
			UDim2.new(1, -66, 0, 6), UDim2.new(0, 54, 0, 18), Enum.TextXAlignment.Right, 8)

		local track_ = Instance.new("Frame")
		track_.BackgroundColor3 = WHITE
		track_.BackgroundTransparency = 0.85
		track_.Position = UDim2.new(0, 12, 0, 32)
		track_.Size = UDim2.new(1, -24, 0, 8)
		track_.ZIndex = 8
		track_.Parent = row
		round(track_, UDim.new(1, 0))

		local fill = Instance.new("Frame")
		fill.BackgroundColor3 = COLOR_GREEN
		fill.BorderSizePixel = 0
		fill.Size = UDim2.new(0, 0, 1, 0)
		fill.ZIndex = 9
		fill.Parent = track_
		round(fill, UDim.new(1, 0))
		local fillGrad = Instance.new("UIGradient")
		fillGrad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, COLOR_GREEN), ColorSequenceKeypoint.new(1, COLOR_PURPLE) })
		fillGrad.Parent = fill

		local knob = Instance.new("Frame")
		knob.BackgroundColor3 = WHITE
		knob.Size = UDim2.new(0, 16, 0, 16)
		knob.AnchorPoint = Vector2.new(0.5, 0.5)
		knob.Position = UDim2.new(0, 0, 0.5, 0)
		knob.ZIndex = 10
		knob.Parent = track_
		round(knob, UDim.new(1, 0))
		stroke(knob, COLOR_PURPLE, 1.5, 0)

		local value = default
		local function updateVisual(v, animatedFlag)
			local rel = (v - min) / math.max(max - min, 1e-6)
			if animatedFlag then
				tween(fill, EASE_FAST, { Size = UDim2.new(rel, 0, 1, 0) })
				tween(knob, EASE_FAST, { Position = UDim2.new(rel, 0, 0.5, 0) })
			else
				fill.Size = UDim2.new(rel, 0, 1, 0)
				knob.Position = UDim2.new(rel, 0, 0.5, 0)
			end
			valueLabel.Text = fmt(v)
		end
		updateVisual(default, false)

		makeSingleTouchDraggable(track_, function(p)
			local rel = math.clamp((p.X - track_.AbsolutePosition.X) / math.max(track_.AbsoluteSize.X, 1), 0, 1)
			local raw = min + (max - min) * rel
			local nv = math.clamp(math.floor(raw / speed + 0.5) * speed, min, max)
			if nv == value then return end
			value = nv
			updateVisual(value, true)
			safe(callback, "Slider", value)
		end)

		return {
			Instance = row,
			Set = function(_, v) value = math.clamp(tonumber(v) or min, min, max); updateVisual(value, true) end,
			Get = function() return value end,
		}
	end

	----------------------------------------------------------
	function E:CreateTextbox(name, placeholder, kind, callback)
		if type(name) == "table" then
			local o = name
			name, placeholder = pick(o, "Name", "Title", "Text"), pick(o, "Placeholder", "Default", "Desc")
			kind, callback = pick(o, "Type", "Kind"), pick(o, "Callback", "Function", "Func")
			if pick(o, "Numeric", "Number") then kind = "number" end
		elseif type(kind) == "function" then
			callback, kind = kind, "text"
		end
		name = tostring(name or "Textbox")
		placeholder = placeholder ~= nil and tostring(placeholder) or ""
		kind = tostring(kind or "text"):lower()

		local row = newRow(56)
		place(row)
		newLabel(row, name, Enum.Font.Gotham, 14, WHITE, UDim2.new(0, 12, 0, 6), UDim2.new(1, -24, 0, 18), Enum.TextXAlignment.Left, 8)

		local box = Instance.new("TextBox")
		box.PlaceholderText = placeholder
		box.Text = ""
		box.Font = Enum.Font.Gotham
		box.TextSize = 13
		box.TextColor3 = WHITE
		box.PlaceholderColor3 = Color3.fromRGB(170, 170, 180)
		box.BackgroundColor3 = WHITE
		box.BackgroundTransparency = 0.9
		box.ClearTextOnFocus = false
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.Position = UDim2.new(0, 12, 0, 26)
		box.Size = UDim2.new(1, -24, 0, 24)
		box.ZIndex = 8
		box.Parent = row
		round(box, UDim.new(0, 8))
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 8)
		pad.Parent = box

		if kind == "number" then
			box:GetPropertyChangedSignal("Text"):Connect(function()
				local filtered = box.Text:gsub("[^%d%.%-]", "")
				if filtered ~= box.Text then box.Text = filtered end
			end)
		end

		box.FocusLost:Connect(function(enterPressed)
			if not callback then return end
			local val = box.Text
			if kind == "number" then val = tonumber(val) or 0 end
			safe(callback, "Textbox", val, enterPressed)
		end)

		return {
			Instance = row,
			Set = function(_, v) box.Text = tostring(v) end,
			Get = function() return box.Text end,
		}
	end

	----------------------------------------------------------
	function E:CreateDropdown(name, options, callback)
		local default
		if type(name) == "table" then
			local o = name
			name, options, callback = pick(o, "Name", "Title", "Text"), pick(o, "Options", "Values", "List"), pick(o, "Callback", "Function", "Func")
			default = pick(o, "Default", "Value")
		end
		name = tostring(name or "Dropdown")
		options = type(options) == "table" and options or {}
		local selected = default ~= nil and tostring(default) or (options[1] ~= nil and tostring(options[1]) or nil)

		local wrap = Instance.new("Frame")
		wrap.BackgroundTransparency = 1
		wrap.Size = UDim2.new(1, 0, 0, 40)
		wrap.ClipsDescendants = true
		wrap.ZIndex = 7
		place(wrap)

		local header = Instance.new("TextButton")
		header.Text = ""
		header.AutoButtonColor = false
		header.BackgroundColor3 = WHITE
		header.BackgroundTransparency = 0.93
		header.Size = UDim2.new(1, 0, 0, 40)
		header.ZIndex = 7
		header.Parent = wrap
		round(header, UDim.new(0, 10))

		newLabel(header, name, Enum.Font.Gotham, 14, WHITE, UDim2.new(0, 12, 0, 0), UDim2.new(0.5, 0, 1, 0), Enum.TextXAlignment.Left, 8)
		local valueLabel = newLabel(header, (selected or "—") .. "  ▾", Enum.Font.GothamMedium, 13, accent,
			UDim2.new(0.45, 0, 0, 0), UDim2.new(0.55, -12, 1, 0), Enum.TextXAlignment.Right, 8)

		local list = Instance.new("Frame")
		list.BackgroundTransparency = 1
		list.Position = UDim2.new(0, 0, 0, 44)
		list.Size = UDim2.new(1, 0, 0, 0)
		list.ZIndex = 7
		list.Parent = wrap
		local listLayout = Instance.new("UIListLayout")
		listLayout.Padding = UDim.new(0, 4)
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Parent = list

		local expanded = false
		local function setExpanded(v)
			expanded = v
			local h = v and (#options * 32) or 0
			tween(wrap, EASE_SOFT, { Size = UDim2.new(1, 0, 0, 40 + (v and (4 + h) or 0)) })
			tween(list, EASE_SOFT, { Size = UDim2.new(1, 0, 0, h) })
		end
		header.Activated:Connect(function() setExpanded(not expanded) end)
		applyPressEffect(header, 0.97)

		for i, opt in ipairs(options) do
			local optText = tostring(opt)
			local optBtn = Instance.new("TextButton")
			optBtn.Text = optText
			optBtn.Font = Enum.Font.Gotham
			optBtn.TextSize = 13
			optBtn.TextColor3 = WHITE
			optBtn.AutoButtonColor = false
			optBtn.BackgroundColor3 = WHITE
			optBtn.BackgroundTransparency = 0.92
			optBtn.Size = UDim2.new(1, 0, 0, 28)
			optBtn.LayoutOrder = i
			optBtn.ZIndex = 8
			optBtn.Parent = list
			round(optBtn, UDim.new(0, 8))
			applyPressEffect(optBtn, 0.96)
			optBtn.Activated:Connect(function()
				selected = optText
				valueLabel.Text = optText .. "  ▾"
				setExpanded(false)
				safe(callback, "Dropdown", optText)
			end)
		end

		return {
			Instance = wrap,
			Get = function() return selected end,
			Set = function(_, v, silent)
				selected = tostring(v)
				valueLabel.Text = selected .. "  ▾"
				if not silent then safe(callback, "Dropdown", selected) end
			end,
		}
	end

	----------------------------------------------------------
	function E:CreateColorPicker(name, defaultColor, callback)
		if type(name) == "table" then
			local o = name
			name, defaultColor, callback = pick(o, "Name", "Title", "Text"), pick(o, "Default", "Color", "Value"), pick(o, "Callback", "Function", "Func")
		end
		name = tostring(name or "Color")
		defaultColor = resolveColor(defaultColor, COLOR_GREEN)

		local row = newRow(40)
		place(row)
		newLabel(row, name, Enum.Font.Gotham, 14, WHITE, UDim2.new(0, 12, 0, 0), UDim2.new(1, -60, 1, 0), Enum.TextXAlignment.Left, 8)

		local swatch = Instance.new("TextButton")
		swatch.Text = ""
		swatch.AutoButtonColor = false
		swatch.BackgroundColor3 = defaultColor
		swatch.Size = UDim2.new(0, 34, 0, 22)
		swatch.AnchorPoint = Vector2.new(1, 0.5)
		swatch.Position = UDim2.new(1, -12, 0.5, 0)
		swatch.ZIndex = 8
		swatch.Parent = row
		round(swatch, UDim.new(0, 6))
		stroke(swatch, WHITE, 1, 0.5)
		applyPressEffect(swatch, 0.9)

		local current = defaultColor
		local h, s, v = Color3.toHSV(current)
		local POPUP_W, POPUP_H = 250, 250
		local pop, built, isOpen = nil, false, false
		local svBox, svKnob, hueKnob, hexBox, nameLbl

		local function currentColor() return Color3.fromHSV(h, s, v) end
		local function refreshUI()
			svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			hexBox.Text = color3ToHex(currentColor())
			nameLbl.Text = T("nearest_color") .. ": " .. nearestColorName(currentColor())
		end

		local function closePicker()
			if not isOpen then return end
			isOpen = false
			popup(-1)
			popClose(pop)
		end

		-- يُبنى عند أول فتح فقط (تحميل أسرع)
		local function build()
			built = true
			pop = Instance.new("Frame")
			pop.BackgroundColor3 = COLOR_DARK
			pop.AnchorPoint = Vector2.new(0.5, 0.5)
			pop.Position = UDim2.new(0.5, 0, 0.5, 0)
			pop.Size = UDim2.new(0, POPUP_W, 0, POPUP_H)
			pop.Active = true
			pop.Visible = false
			pop.ZIndex = 200
			pop.Parent = screenGui
			round(pop, UDim.new(0, 14))
			stroke(pop, COLOR_PURPLE, 1, 0.3)

			local handle = Instance.new("Frame")
			handle.BackgroundColor3 = WHITE
			handle.BackgroundTransparency = 0.93
			handle.Size = UDim2.new(1, 0, 0, 22)
			handle.ZIndex = 61
			handle.Parent = pop
			round(handle, UDim.new(0, 14))
			local grip = newLabel(handle, "⋮⋮⋮⋮⋮⋮", Enum.Font.GothamBold, 12, Color3.fromRGB(180, 180, 190),
				UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0, 60, 0, 16), Enum.TextXAlignment.Center, 62)
			grip.AnchorPoint = Vector2.new(0.5, 0.5)
			grip.Rotation = 90
			makeFrameDraggable(handle, pop, {})

			svBox = Instance.new("Frame")
			svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			svBox.Position = UDim2.new(0, 14, 0, 34)
			svBox.Size = UDim2.new(0, 170, 0, 150)
			svBox.ZIndex = 61
			svBox.Parent = pop
			round(svBox, UDim.new(0, 8))

			local satOverlay = Instance.new("Frame")
			satOverlay.BackgroundColor3 = WHITE
			satOverlay.BorderSizePixel = 0
			satOverlay.Size = UDim2.new(1, 0, 1, 0)
			satOverlay.ZIndex = 62
			satOverlay.Parent = svBox
			round(satOverlay, UDim.new(0, 8))
			local satGrad = Instance.new("UIGradient")
			satGrad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
			satGrad.Parent = satOverlay

			local valOverlay = Instance.new("Frame")
			valOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
			valOverlay.BorderSizePixel = 0
			valOverlay.Size = UDim2.new(1, 0, 1, 0)
			valOverlay.ZIndex = 63
			valOverlay.Parent = svBox
			round(valOverlay, UDim.new(0, 8))
			local valGrad = Instance.new("UIGradient")
			valGrad.Rotation = 90
			valGrad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
			valGrad.Parent = valOverlay

			svKnob = Instance.new("Frame")
			svKnob.BackgroundColor3 = WHITE
			svKnob.Size = UDim2.new(0, 12, 0, 12)
			svKnob.AnchorPoint = Vector2.new(0.5, 0.5)
			svKnob.Position = UDim2.new(s, 0, 1 - v, 0)
			svKnob.ZIndex = 64
			svKnob.Parent = svBox
			round(svKnob, UDim.new(1, 0))
			stroke(svKnob, Color3.new(0, 0, 0), 1.5, 0)

			local hueStrip = Instance.new("Frame")
			hueStrip.BackgroundColor3 = WHITE
			hueStrip.Position = UDim2.new(0, 194, 0, 34)
			hueStrip.Size = UDim2.new(0, 20, 0, 150)
			hueStrip.ZIndex = 61
			hueStrip.Parent = pop
			round(hueStrip, UDim.new(0, 8))
			local hueGrad = Instance.new("UIGradient")
			hueGrad.Rotation = 90
			hueGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)), ColorSequenceKeypoint.new(1 / 6, Color3.fromHSV(1 / 6, 1, 1)),
				ColorSequenceKeypoint.new(2 / 6, Color3.fromHSV(2 / 6, 1, 1)), ColorSequenceKeypoint.new(3 / 6, Color3.fromHSV(3 / 6, 1, 1)),
				ColorSequenceKeypoint.new(4 / 6, Color3.fromHSV(4 / 6, 1, 1)), ColorSequenceKeypoint.new(5 / 6, Color3.fromHSV(5 / 6, 1, 1)),
				ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
			})
			hueGrad.Parent = hueStrip

			hueKnob = Instance.new("Frame")
			hueKnob.BackgroundColor3 = WHITE
			hueKnob.Size = UDim2.new(1, 4, 0, 4)
			hueKnob.AnchorPoint = Vector2.new(0.5, 0.5)
			hueKnob.Position = UDim2.new(0.5, 0, h, 0)
			hueKnob.ZIndex = 62
			hueKnob.Parent = hueStrip
			round(hueKnob, UDim.new(0, 2))

			hexBox = Instance.new("TextBox")
			hexBox.Text = color3ToHex(current)
			hexBox.Font = Enum.Font.Code
			hexBox.TextSize = 13
			hexBox.TextColor3 = WHITE
			hexBox.BackgroundColor3 = WHITE
			hexBox.BackgroundTransparency = 0.9
			hexBox.ClearTextOnFocus = false
			hexBox.Position = UDim2.new(0, 14, 0, 192)
			hexBox.Size = UDim2.new(0, 100, 0, 24)
			hexBox.ZIndex = 61
			hexBox.Parent = pop
			round(hexBox, UDim.new(0, 6))

			nameLbl = newLabel(pop, T("nearest_color") .. ": " .. nearestColorName(current), Enum.Font.Gotham, 11,
				Color3.fromRGB(200, 200, 210), UDim2.new(0, 120, 0, 192), UDim2.new(0, 116, 0, 24), Enum.TextXAlignment.Left, 61)

			local startBtn = Instance.new("TextButton")
			startBtn.Text = T("pick_start")
			startBtn.Font = Enum.Font.GothamBold
			startBtn.TextSize = 13
			startBtn.TextColor3 = WHITE
			startBtn.AutoButtonColor = false
			startBtn.BackgroundColor3 = COLOR_GREEN
			startBtn.Position = UDim2.new(0, 14, 1, -42)
			startBtn.Size = UDim2.new(0, 100, 0, 28)
			startBtn.ZIndex = 61
			startBtn.Parent = pop
			round(startBtn, UDim.new(0, 8))
			applyPressEffect(startBtn, 0.9)

			local cancelBtn = Instance.new("TextButton")
			cancelBtn.Text = T("pick_cancel")
			cancelBtn.Font = Enum.Font.GothamBold
			cancelBtn.TextSize = 13
			cancelBtn.TextColor3 = WHITE
			cancelBtn.AutoButtonColor = false
			cancelBtn.BackgroundColor3 = COLOR_OFF
			cancelBtn.Position = UDim2.new(1, -114, 1, -42)
			cancelBtn.Size = UDim2.new(0, 100, 0, 28)
			cancelBtn.ZIndex = 61
			cancelBtn.Parent = pop
			round(cancelBtn, UDim.new(0, 8))
			applyPressEffect(cancelBtn, 0.9)

			makeSingleTouchDraggable(svBox, function(p)
				local pos, size = svBox.AbsolutePosition, svBox.AbsoluteSize
				s = math.clamp((p.X - pos.X) / math.max(size.X, 1), 0, 1)
				v = math.clamp(1 - (p.Y - pos.Y) / math.max(size.Y, 1), 0, 1)
				svKnob.Position = UDim2.new(s, 0, 1 - v, 0)
				refreshUI()
			end)
			makeSingleTouchDraggable(hueStrip, function(p)
				local pos, size = hueStrip.AbsolutePosition, hueStrip.AbsoluteSize
				h = math.clamp((p.Y - pos.Y) / math.max(size.Y, 1), 0, 1)
				hueKnob.Position = UDim2.new(0.5, 0, h, 0)
				refreshUI()
			end)

			hexBox.FocusLost:Connect(function()
				local c = hexToColor3(hexBox.Text)
				if c then
					h, s, v = Color3.toHSV(c)
					svKnob.Position = UDim2.new(s, 0, 1 - v, 0)
					hueKnob.Position = UDim2.new(0.5, 0, h, 0)
				end
				refreshUI()
			end)

			cancelBtn.Activated:Connect(closePicker)
			startBtn.Activated:Connect(function()
				current = currentColor()
				swatch.BackgroundColor3 = current
				closePicker()
				safe(callback, "ColorPicker", current)
			end)
		end

		swatch.Activated:Connect(function()
			if isOpen then return end
			if not built then build() end
			h, s, v = Color3.toHSV(current)
			svKnob.Position = UDim2.new(s, 0, 1 - v, 0)
			hueKnob.Position = UDim2.new(0.5, 0, h, 0)
			refreshUI()
			isOpen = true
			popup(1)
			pop.Position = UDim2.new(0.5, 0, 0.5, 0)
			popOpen(pop, UDim2.new(0, POPUP_W, 0, POPUP_H))
		end)

		return {
			Instance = row,
			Get = function() return current end,
			Set = function(_, c)
				current = resolveColor(c, current)
				swatch.BackgroundColor3 = current
			end,
		}
	end

	----------------------------------------------------------
	-- ملاحظة: Dark (درك) أو Blue (أزرق) — تحتاج نافذة سليمة بنفس إصدار المكتبة
	function E:CreateNote(title, text, style)
		if type(title) == "table" then
			local o = title
			title, text, style = pick(o, "Title", "Name"), pick(o, "Text", "Content", "Desc"), pick(o, "Style", "Type", "Color")
		end
		if not isWindowValid(ctx.window) then
			warn("[ProUI] Note: تحتاج نافذة صحيحة وحديثة، لم يتم إنشاء الملاحظة.")
			return nil
		end
		local st = tostring(style or "Dark"):lower()
		local isBlue = (st == "blue" or st == "أزرق")

		local box = Instance.new("Frame")
		box.BackgroundColor3 = isBlue and COLOR_BLUE or COLOR_DARK
		box.BackgroundTransparency = 0.12
		box.BorderSizePixel = 0
		box.Size = UDim2.new(1, 0, 0, 0)
		box.AutomaticSize = Enum.AutomaticSize.Y
		box.ZIndex = 7
		place(box)
		round(box, UDim.new(0, 10))
		stroke(box, isBlue and COLOR_SKY or COLOR_GRAY, 1, 0.5)

		local pad = Instance.new("UIPadding")
		pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 12), UDim.new(0, 12)
		pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 10), UDim.new(0, 10)
		pad.Parent = box
		local lay = Instance.new("UIListLayout")
		lay.Padding = UDim.new(0, 3)
		lay.SortOrder = Enum.SortOrder.LayoutOrder
		lay.Parent = box

		if title and tostring(title) ~= "" then
			local tl = newLabel(box, tostring(title), Enum.Font.GothamBold, 14, WHITE, UDim2.new(), UDim2.new(1, 0, 0, 0), Enum.TextXAlignment.Left, 8)
			tl.TextWrapped = true
			tl.AutomaticSize = Enum.AutomaticSize.Y
			tl.LayoutOrder = 1
		end
		local bl = newLabel(box, tostring(text or ""), Enum.Font.Gotham, 12, Color3.fromRGB(225, 225, 235), UDim2.new(), UDim2.new(1, 0, 0, 0), Enum.TextXAlignment.Left, 8)
		bl.TextWrapped = true
		bl.AutomaticSize = Enum.AutomaticSize.Y
		bl.LayoutOrder = 2

		return { Instance = box, SetText = function(_, t) bl.Text = tostring(t) end }
	end

	----------------------------------------------------------
	-- Label بالنص (opts: Color, TextSize, Bold)
	function E:CreateLabel(text, opts)
		if type(text) == "table" then
			opts = text
			text = pick(opts, "Text", "Name", "Title")
		end
		opts = type(opts) == "table" and opts or {}
		local lbl = newLabel(nil, tostring(text or ""), opts.Bold and Enum.Font.GothamBold or Enum.Font.GothamMedium,
			tonumber(pick(opts, "TextSize", "FontSize")) or 14, resolveColor(opts.Color, WHITE),
			UDim2.new(), UDim2.new(1, 0, 0, 0), Enum.TextXAlignment.Center, 8)
		lbl.TextWrapped = true
		lbl.AutomaticSize = Enum.AutomaticSize.Y
		local pad = Instance.new("UIPadding")
		pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 4), UDim.new(0, 4)
		pad.Parent = lbl
		place(lbl)
		return { Instance = lbl, Set = function(_, t) lbl.Text = tostring(t) end, Get = function() return lbl.Text end }
	end

	----------------------------------------------------------
	-- قائمة منسدلة للأزرار: تقفلها = الأزرار تختفي، تفتحها = ترجع
	function E:CreateFoldout(name, items, defaultOpen)
		if type(name) == "table" then
			local o = name
			name, items, defaultOpen = pick(o, "Name", "Title", "Text"), pick(o, "Buttons", "Items", "Options"), pick(o, "Open", "Default", "Expanded")
		elseif type(items) == "boolean" then
			defaultOpen, items = items, nil
		end
		name = tostring(name or "Group")

		local wrap = Instance.new("Frame")
		wrap.BackgroundTransparency = 1
		wrap.Size = UDim2.new(1, 0, 0, 40)
		wrap.ClipsDescendants = true
		wrap.ZIndex = 7
		place(wrap)

		local header = Instance.new("TextButton")
		header.Text = ""
		header.AutoButtonColor = false
		header.BackgroundColor3 = WHITE
		header.BackgroundTransparency = 0.9
		header.Size = UDim2.new(1, 0, 0, 40)
		header.ZIndex = 8
		header.Parent = wrap
		round(header, UDim.new(0, 10))
		stroke(header, accent, 1, 0.75)
		newLabel(header, name, Enum.Font.GothamMedium, 14, WHITE, UDim2.new(0, 12, 0, 0), UDim2.new(1, -44, 1, 0), Enum.TextXAlignment.Left, 9)
		local arrow = newLabel(header, "▸", Enum.Font.GothamBold, 15, accent, UDim2.new(1, -34, 0, 0), UDim2.new(0, 22, 1, 0), Enum.TextXAlignment.Center, 9)
		applyPressEffect(header, 0.97)

		local content = Instance.new("Frame")
		content.BackgroundTransparency = 1
		content.Position = UDim2.new(0, 0, 0, 46)
		content.Size = UDim2.new(1, 0, 0, 0)
		content.ClipsDescendants = true
		content.ZIndex = 7
		content.Parent = wrap
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 10)
		pad.Parent = content
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 8)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = content

		local E2 = makeElements(content, ctx)
		local open = defaultOpen == true

		local function refresh(animatedFlag)
			local ch = layout.AbsoluteContentSize.Y
			local contentH = open and ch or 0
			local wrapH = 40 + ((open and ch > 0) and (6 + ch) or 0)
			if animatedFlag then
				tween(content, EASE_SOFT, { Size = UDim2.new(1, 0, 0, contentH) })
				tween(wrap, EASE_SOFT, { Size = UDim2.new(1, 0, 0, wrapH) })
			else
				content.Size = UDim2.new(1, 0, 0, contentH)
				wrap.Size = UDim2.new(1, 0, 0, wrapH)
			end
			arrow.Text = open and "▾" or "▸"
		end
		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() refresh(false) end)
		header.Activated:Connect(function()
			open = not open
			refresh(true)
		end)

		if type(items) == "table" then
			for _, it in ipairs(items) do
				if type(it) == "table" then E2:CreateButton(it) end
			end
		end
		refresh(false)

		E2.Instance = wrap
		E2.AddButton = function(_, ...) return E2:CreateButton(...) end
		E2.SetOpen = function(_, v) open = v and true or false; refresh(true) end
		E2.Open = function() open = true; refresh(true) end
		E2.Close = function() open = false; refresh(true) end
		E2.IsOpen = function() return open end
		return E2
	end

	----------------------------------------------------------
	-- أزرار اختيارات بالنص: كل خيار له صفحة أزرار خاصة فيه
	-- local sel = Tab:CreateSelector({"عام","متقدم"}, function(name) end)
	-- sel.Pages["عام"]:CreateButton(...)   أو   sel:Page("عام"):CreateButton(...)
	function E:CreateSelector(options, callback)
		if type(options) == "table" and options.Options then
			local o = options
			options, callback = o.Options, pick(o, "Callback", "Function", "Func")
		end
		options = type(options) == "table" and options or {}
		if #options == 0 then options = { "1" } end

		local bar = Instance.new("Frame")
		bar.BackgroundColor3 = WHITE
		bar.BackgroundTransparency = 0.93
		bar.BorderSizePixel = 0
		bar.Size = UDim2.new(1, 0, 0, 36)
		bar.ZIndex = 7
		place(bar)
		round(bar, UDim.new(0, 10))
		local barLayout = Instance.new("UIListLayout")
		barLayout.FillDirection = Enum.FillDirection.Horizontal
		barLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		barLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		barLayout.Padding = UDim.new(0, 6)
		barLayout.SortOrder = Enum.SortOrder.LayoutOrder
		barLayout.Parent = bar

		local buttons, frames, pages = {}, {}, {}
		local current

		local function select_(optName, silent)
			if not frames[optName] then return end
			current = optName
			for n, b in pairs(buttons) do
				local on = (n == optName)
				tween(b, EASE_SOFT, { BackgroundTransparency = on and 0.65 or 1, TextColor3 = on and WHITE or Color3.fromRGB(190, 190, 200) })
				frames[n].Visible = on
			end
			if not silent then safe(callback, "Selector", optName) end
		end

		for i, opt in ipairs(options) do
			local optName = tostring(opt)
			local b = Instance.new("TextButton")
			b.Text = optName
			b.Font = Enum.Font.GothamMedium
			b.TextSize = 13
			b.TextColor3 = Color3.fromRGB(190, 190, 200)
			b.AutoButtonColor = false
			b.BackgroundColor3 = accent
			b.BackgroundTransparency = 1
			b.AutomaticSize = Enum.AutomaticSize.X
			b.Size = UDim2.new(0, 0, 0, 26)
			b.LayoutOrder = i
			b.ZIndex = 8
			b.Parent = bar
			round(b, UDim.new(0, 8))
			local bp = Instance.new("UIPadding")
			bp.PaddingLeft, bp.PaddingRight = UDim.new(0, 14), UDim.new(0, 14)
			bp.Parent = b
			b.Activated:Connect(function() select_(optName) end)
			buttons[optName] = b

			local f = Instance.new("Frame")
			f.BackgroundTransparency = 1
			f.Size = UDim2.new(1, 0, 0, 0)
			f.AutomaticSize = Enum.AutomaticSize.Y
			f.Visible = false
			f.ZIndex = 7
			place(f)
			local fl = Instance.new("UIListLayout")
			fl.Padding = UDim.new(0, 10)
			fl.SortOrder = Enum.SortOrder.LayoutOrder
			fl.Parent = f
			frames[optName] = f
			pages[optName] = makeElements(f, ctx)
		end

		select_(tostring(options[1]), true)

		return {
			Instance = bar,
			Pages = pages,
			Page = function(_, n) return pages[tostring(n)] end,
			Select = function(_, n) select_(tostring(n)) end,
			Get = function() return current end,
		}
	end

	-- أسماء بديلة
	E.Button, E.Toggle, E.Slider = E.CreateButton, E.CreateToggle, E.CreateSlider
	E.Input, E.Textbox, E.Dropdown = E.CreateTextbox, E.CreateTextbox, E.CreateDropdown
	E.Colorpicker, E.ColorPicker = E.CreateColorPicker, E.CreateColorPicker
	E.Note, E.Label, E.Foldout, E.Selector = E.CreateNote, E.CreateLabel, E.CreateFoldout, E.CreateSelector
	E.CreateButtonList, E.CreateButtonDropdown, E.ButtonList = E.CreateFoldout, E.CreateFoldout, E.CreateFoldout
	return E
end

--============================================================
-- 10) الزر العايم (Float Button) - يسار الشاشة + إعداداته
--============================================================
local floatCount = 0

Library.CreateFloatButton = function(...)
	local args = { ... }
	if args[1] == Library then table.remove(args, 1) end
	local cfg = args[1]
	if type(cfg) ~= "table" then cfg = { Name = cfg, Callback = args[2] } end
	if not screenGui.Parent then return nil end

	floatCount = floatCount + 1
	local idx = floatCount
	local btnName = tostring(pick(cfg, "Name", "Text", "Title") or "Button")
	local borderColor = resolveColor(pick(cfg, "Color", "BorderColor"), COLOR_PURPLE)
	local widthIn = pick(cfg, "Width", "Size")
	local width = math.clamp(type(widthIn) == "number" and widthIn or 92, 60, 240)
	local callback = pick(cfg, "Callback", "Function", "Func")
	local code = tostring(pick(cfg, "Code") or "")
	local function heightFor(w) return math.max(26, math.floor(w * 0.4)) end

	local fb = Instance.new("TextButton")
	fb.Name = "FloatButton"
	fb.Text = ""
	fb.AutoButtonColor = false
	fb.BackgroundColor3 = Color3.new(0, 0, 0)
	fb.BackgroundTransparency = 0.82 -- شفاف
	fb.Size = UDim2.new(0, width, 0, heightFor(width))
	fb.Position = pick(cfg, "Position") or UDim2.new(0, 14, 0.5, (idx - 1) * 54 - 20)
	fb.ZIndex = 20
	fb.Parent = screenGui
	round(fb, UDim.new(0, 10))
	local fbStroke = stroke(fb, borderColor, 2, 0.05)
	applyPressEffect(fb, 0.92)
	registerTarget("FloatButtonBorder", fb, "border")

	local nameLbl = newLabel(fb, btnName, Enum.Font.GothamBold, 13, WHITE,
		UDim2.new(0, 28, 0, 0), UDim2.new(1, -34, 1, 0), Enum.TextXAlignment.Center, 22)
	nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

	-- زر صغير يسار: يفتح إعدادات الزر
	local gear = Instance.new("TextButton")
	gear.Text = "⚙"
	gear.Font = Enum.Font.GothamBold
	gear.TextSize = 13
	gear.TextColor3 = WHITE
	gear.AutoButtonColor = false
	gear.BackgroundColor3 = WHITE
	gear.BackgroundTransparency = 0.85
	gear.AnchorPoint = Vector2.new(0, 0.5)
	gear.Position = UDim2.new(0, 5, 0.5, 0)
	gear.Size = UDim2.new(0, 20, 0, 20)
	gear.ZIndex = 23
	gear.Parent = fb
	round(gear, UDim.new(1, 0))

	local api = { Instance = fb }
	local panel, funcPanel

	-- تشغيل الوظيفة: Callback من السكربت ثم الكود المكتوب بالخانة (لو موجود)
	local function runCode()
		if code == "" then return end
		local loader = loadstring
		if not loader then
			warn("[ProUI FloatButton] loadstring غير متوفر في هذا المنفذ")
			return
		end
		local fn, err = loader(code)
		if not fn then
			warn("[ProUI FloatButton] " .. T("float_code_err") .. ":", err)
			Library.Notify(T("float_code_err"), tostring(err), nil, 4)
			return
		end
		local ok, e = pcall(fn)
		if not ok then warn("[ProUI FloatButton] " .. T("float_code_err") .. ":", e) end
	end
	local function fire()
		if callback then
			local ok, err = pcall(callback)
			if not ok then warn("[ProUI FloatButton Error]", err) end
		end
		runCode()
	end

	local wasDragged = false
	makeFrameDraggable(fb, fb, { Threshold = 6, OnDragFlag = function(v) wasDragged = v end })
	fb.Activated:Connect(function()
		if not wasDragged then fire() end
	end)

	-- لوحة الوظيفة (خانة الكود)
	local function buildFuncPanel()
		funcPanel = Instance.new("Frame")
		funcPanel.BackgroundColor3 = COLOR_DARK
		funcPanel.AnchorPoint = Vector2.new(0.5, 0.5)
		funcPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
		funcPanel.Size = UDim2.new(0, 300, 0, 250)
		funcPanel.Active = true
		funcPanel.Visible = false
		funcPanel.ZIndex = 160
		funcPanel.Parent = screenGui
		round(funcPanel, UDim.new(0, 14))
		stroke(funcPanel, COLOR_PURPLE, 1.2, 0.3)

		local handle = Instance.new("Frame")
		handle.BackgroundColor3 = WHITE
		handle.BackgroundTransparency = 0.93
		handle.Size = UDim2.new(1, 0, 0, 26)
		handle.ZIndex = 161
		handle.Parent = funcPanel
		round(handle, UDim.new(0, 14))
		newLabel(handle, T("float_code_title"), Enum.Font.GothamBold, 13, WHITE, UDim2.new(0, 12, 0, 0), UDim2.new(1, -24, 1, 0), Enum.TextXAlignment.Left, 162)
		makeFrameDraggable(handle, funcPanel, {})

		local hint = newLabel(funcPanel, T("float_code_hint"), Enum.Font.Gotham, 11, Color3.fromRGB(180, 180, 195),
			UDim2.new(0, 12, 0, 32), UDim2.new(1, -24, 0, 28), Enum.TextXAlignment.Left, 161)
		hint.TextWrapped = true
		hint.TextYAlignment = Enum.TextYAlignment.Top

		local box = Instance.new("TextBox")
		box.Text = code
		box.PlaceholderText = "print('Hello')"
		box.PlaceholderColor3 = Color3.fromRGB(130, 130, 145)
		box.Font = Enum.Font.Code
		box.TextSize = 12
		box.TextColor3 = WHITE
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.TextYAlignment = Enum.TextYAlignment.Top
		box.MultiLine = true
		box.TextWrapped = true
		box.ClearTextOnFocus = false
		box.BackgroundColor3 = Color3.new(0, 0, 0)
		box.BackgroundTransparency = 0.5
		box.Position = UDim2.new(0, 12, 0, 64)
		box.Size = UDim2.new(1, -24, 1, -112)
		box.ZIndex = 161
		box.Parent = funcPanel
		round(box, UDim.new(0, 8))
		local bp = Instance.new("UIPadding")
		bp.PaddingLeft, bp.PaddingTop, bp.PaddingRight = UDim.new(0, 8), UDim.new(0, 6), UDim.new(0, 8)
		bp.Parent = box

		local save = Instance.new("TextButton")
		save.Text = T("float_save")
		save.Font = Enum.Font.GothamBold
		save.TextSize = 13
		save.TextColor3 = WHITE
		save.AutoButtonColor = false
		save.BackgroundColor3 = COLOR_GREEN
		save.Position = UDim2.new(0, 12, 1, -40)
		save.Size = UDim2.new(0.5, -18, 0, 30)
		save.ZIndex = 161
		save.Parent = funcPanel
		round(save, UDim.new(0, 8))
		applyPressEffect(save, 0.9)

		local close = Instance.new("TextButton")
		close.Text = T("float_close")
		close.Font = Enum.Font.GothamBold
		close.TextSize = 13
		close.TextColor3 = WHITE
		close.AutoButtonColor = false
		close.BackgroundColor3 = COLOR_OFF
		close.Position = UDim2.new(0.5, 6, 1, -40)
		close.Size = UDim2.new(0.5, -18, 0, 30)
		close.ZIndex = 161
		close.Parent = funcPanel
		round(close, UDim.new(0, 8))
		applyPressEffect(close, 0.9)

		save.Activated:Connect(function()
			code = box.Text
			Library.Notify(btnName, T("float_saved"), nil, 2.5)
		end)
		close.Activated:Connect(function() popClose(funcPanel) end)
	end

	-- لوحة الإعدادات (مثل لوحة الألوان بس بدون ألوان ثابتة)
	local function buildPanel()
		panel = Instance.new("Frame")
		panel.BackgroundColor3 = COLOR_DARK
		panel.AnchorPoint = Vector2.new(0.5, 0.5)
		panel.Position = UDim2.new(0.5, 0, 0.5, 0)
		panel.Size = UDim2.new(0, 290, 0, 310)
		panel.Active = true
		panel.Visible = false
		panel.ZIndex = 150
		panel.Parent = screenGui
		round(panel, UDim.new(0, 14))
		stroke(panel, COLOR_PURPLE, 1.2, 0.3)

		local handle = Instance.new("Frame")
		handle.BackgroundColor3 = WHITE
		handle.BackgroundTransparency = 0.93
		handle.Size = UDim2.new(1, 0, 0, 32)
		handle.ZIndex = 151
		handle.Parent = panel
		round(handle, UDim.new(0, 14))
		newLabel(handle, T("float_title"), Enum.Font.GothamBold, 14, WHITE, UDim2.new(0, 14, 0, 0), UDim2.new(1, -60, 1, 0), Enum.TextXAlignment.Left, 152)
		makeFrameDraggable(handle, panel, {})

		local closeX = Instance.new("TextButton")
		closeX.Text = "✕"
		closeX.Font = Enum.Font.GothamBold
		closeX.TextSize = 13
		closeX.TextColor3 = WHITE
		closeX.AutoButtonColor = false
		closeX.BackgroundColor3 = COLOR_RED
		closeX.AnchorPoint = Vector2.new(1, 0.5)
		closeX.Position = UDim2.new(1, -8, 0.5, 0)
		closeX.Size = UDim2.new(0, 22, 0, 22)
		closeX.ZIndex = 153
		closeX.Parent = handle
		round(closeX, UDim.new(1, 0))
		applyPressEffect(closeX, 0.85)
		closeX.Activated:Connect(function() popClose(panel) end)

		local scroll = Instance.new("ScrollingFrame")
		scroll.BackgroundTransparency = 1
		scroll.BorderSizePixel = 0
		scroll.Position = UDim2.new(0, 10, 0, 40)
		scroll.Size = UDim2.new(1, -20, 1, -48)
		scroll.ScrollBarThickness = 3
		scroll.ScrollBarImageColor3 = COLOR_PURPLE
		scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.ZIndex = 151
		scroll.Parent = panel
		local sl = Instance.new("UIListLayout")
		sl.Padding = UDim.new(0, 8)
		sl.SortOrder = Enum.SortOrder.LayoutOrder
		sl.Parent = scroll

		local EF = makeElements(scroll, { accent = COLOR_PURPLE })
		EF:CreateColorPicker(T("float_border"), borderColor, function(c)
			borderColor = c
			fbStroke.Color = c
		end)
		local nameBox = EF:CreateTextbox(T("float_name"), btnName, "text", function(v)
			if v ~= "" then
				btnName = tostring(v)
				nameLbl.Text = btnName
			end
		end)
		nameBox:Set(btnName)
		EF:CreateSlider(T("float_size"), 60, 240, width, 2, function(v)
			width = v
			fb.Size = UDim2.new(0, width, 0, heightFor(width))
		end)
		EF:CreateButton(T("float_func"), T("float_func_hint"), function()
			if not funcPanel then buildFuncPanel() end
			popOpen(funcPanel, UDim2.new(0, 300, 0, 250))
		end)
		EF:CreateButton(T("float_delete"), nil, function() api.Destroy() end)
	end

	gear.Activated:Connect(function()
		if not panel then buildPanel() end
		if panel.Visible then popClose(panel) else popOpen(panel, UDim2.new(0, 290, 0, 310)) end
	end)
	applyPressEffect(gear, 0.85)

	api.Fire = fire
	api.SetName = function(_, n) btnName = tostring(n); nameLbl.Text = btnName end
	api.SetColor = function(_, c) borderColor = resolveColor(c, borderColor); fbStroke.Color = borderColor end
	api.SetSize = function(_, w) width = math.clamp(tonumber(w) or width, 60, 240); fb.Size = UDim2.new(0, width, 0, heightFor(width)) end
	api.SetCallback = function(_, f) callback = f end
	api.SetCode = function(_, c) code = tostring(c or "") end
	api.Destroy = function()
		unregisterTarget(fb)
		if panel then panel:Destroy() end
		if funcPanel then funcPanel:Destroy() end
		fb:Destroy()
		for i, o in ipairs(Library.FloatButtons) do
			if o == api then table.remove(Library.FloatButtons, i) break end
		end
	end
	Library.FloatButtons[#Library.FloatButtons + 1] = api
	return api
end

--============================================================
-- 11) إنشاء النافذة
--============================================================
local ELEMENT_KINDS = { "Button", "Toggle", "Slider", "Textbox", "Dropdown", "ColorPicker", "Note", "Label", "Foldout", "Selector" }

-- Library.CreateButton(tab, ...) وما شابه
for _, kind in ipairs(ELEMENT_KINDS) do
	Library["Create" .. kind] = function(tab, ...)
		if tab == Library then
			local realTab = ...
			return realTab["Create" .. kind](realTab, select(2, ...))
		end
		return tab["Create" .. kind](tab, ...)
	end
end

function Library.CreateWindow(config, ...)
	if config == Library then config = ... end
	config = config or {}
	local title    = config.Title or "الواجهة الاحترافية"
	local subTitle = config.SubTitle or ""
	local hasTheme = config.Theme ~= nil
	local baseColor = resolveColor(config.Theme, COLOR_GREEN)
	local lum = 0.299 * baseColor.R + 0.587 * baseColor.G + 0.114 * baseColor.B
	local accent = lum < 0.3 and baseColor:Lerp(WHITE, 0.55) or baseColor
	local sizeX = (config.Size and config.Size.X) or 586
	local sizeY = (config.Size and config.Size.Y) or 339
	local vs = screenGui.AbsoluteSize
	if vs.X > 0 then sizeX = math.min(sizeX, vs.X - 24) end
	if vs.Y > 0 then sizeY = math.min(sizeY, vs.Y - 24) end

	-- لون الإشعارات = لون الواجهة
	themeState.accent = accent
	themeState.base = hasTheme and baseColor or Color3.fromRGB(120, 50, 220)

	local Window = { Tabs = {}, Version = LIB_VERSION, _sig = WINDOW_SIG }

	----------------------------------------------------------
	-- زر OPEN (افتراضي أو مخصص)
	----------------------------------------------------------
	local openCfg = config.OpenButton or {}
	local openButton

	if openCfg.Instance then
		openButton = openCfg.Instance
		if not openButton.Parent then openButton.Parent = screenGui end
	else
		openButton = Instance.new("TextButton")
		openButton.Name = "OpenButton"
		openButton.Text = ""
		openButton.AutoButtonColor = false
		openButton.Size = openCfg.Size or UDim2.new(0, 110, 0, 42)
		openButton.AnchorPoint = Vector2.new(0.5, 0)
		openButton.Position = UDim2.new(0.5, 0, 0, 24)
		openButton.BackgroundColor3 = resolveColor(openCfg.Color, COLOR_BLUE)
		openButton.BorderSizePixel = 0
		openButton.ZIndex = 10
		openButton.Parent = screenGui
		round(openButton, UDim.new(1, 0))
		stroke(openButton, WHITE, 1.2, 0.7)

		local openGradient = Instance.new("UIGradient")
		openGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, COLOR_BLUE), ColorSequenceKeypoint.new(0.5, COLOR_GREEN), ColorSequenceKeypoint.new(1, COLOR_PURPLE),
		})
		openGradient.Parent = openButton
		spinGradient(openGradient, openButton, 66)

		local openLbl = newLabel(openButton, (openCfg.Icon and (openCfg.Icon .. "  ") or "") .. (openCfg.Text or T("open_text")),
			Enum.Font.GothamBold, 16, WHITE, UDim2.new(), UDim2.new(1, 0, 1, 0), Enum.TextXAlignment.Center, 12)
		openLbl.Name = "Label"
	end
	local openBaseSize = openButton.Size
	applyPressEffect(openButton, 0.9)
	registerTarget("OpenButton", openButton, "fill")
	registerTarget("OpenButtonBorder", openButton, "border")

	local openBtnDragged = false
	makeFrameDraggable(openButton, openButton, {
		Threshold = 6,
		OnDragFlag = function(v) openBtnDragged = v end,
	})

	----------------------------------------------------------
	-- الواجهة الرئيسية
	----------------------------------------------------------
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, sizeX, 0, sizeY)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.BackgroundColor3 = baseColor
	mainFrame.BackgroundTransparency = hasTheme and 0.2 or 0.55
	mainFrame.BorderSizePixel = 0
	mainFrame.ClipsDescendants = true
	mainFrame.Visible = false
	mainFrame.ZIndex = 5
	mainFrame.Parent = screenGui
	round(mainFrame, UDim.new(0, 18))
	local mainStroke = stroke(mainFrame, accent, 1.5, 0.4)
	registerTarget("Window", mainFrame, "fill")
	registerTarget("WindowBorder", mainFrame, "border")

	local glow = Instance.new("ImageLabel")
	glow.BackgroundTransparency = 1
	glow.Image = "rbxassetid://5028857084"
	glow.ImageColor3 = accent
	glow.ImageTransparency = 0.55
	glow.ScaleType = Enum.ScaleType.Slice
	glow.SliceCenter = Rect.new(24, 24, 276, 276)
	glow.Size = UDim2.new(1, 80, 1, 80)
	glow.Position = UDim2.new(0.5, 0, 0.5, 0)
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.ZIndex = 4
	glow.Parent = mainFrame

	local bgGradient = Instance.new("UIGradient")
	bgGradient.Rotation = 45
	bgGradient.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, hasTheme and 0 or 0.25), NumberSequenceKeypoint.new(1, hasTheme and 0 or 0.25) })
	bgGradient.Parent = mainFrame

	if hasTheme then
		animateGradient(bgGradient, {
			ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(215, 215, 215)) }),
			ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(225, 225, 225)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)) }),
			ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(245, 245, 245)), ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 220, 220)) }),
		}, 4.5)
	else
		animateGradient(bgGradient, {
			ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 50, 220)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 40, 170)), ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 70, 255)) }),
			ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 80, 255)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(110, 50, 200)), ColorSequenceKeypoint.new(1, Color3.fromRGB(130, 60, 230)) }),
			ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 60, 235)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 45, 185)), ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 90, 255)) }),
		}, 4.5)
	end

	----------------------------------------------------------
	-- شريط العنوان
	----------------------------------------------------------
	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, subTitle ~= "" and 54 or 46)
	topBar.BackgroundColor3 = WHITE
	topBar.BackgroundTransparency = 0.94
	topBar.BorderSizePixel = 0
	topBar.ZIndex = 6
	topBar.Parent = mainFrame
	round(topBar, UDim.new(0, 18))

	local topBarFix = Instance.new("Frame")
	topBarFix.BackgroundColor3 = topBar.BackgroundColor3
	topBarFix.BackgroundTransparency = topBar.BackgroundTransparency
	topBarFix.BorderSizePixel = 0
	topBarFix.Size = UDim2.new(1, 0, 0, 18)
	topBarFix.Position = UDim2.new(0, 0, 1, -18)
	topBarFix.ZIndex = 6
	topBarFix.Parent = topBar

	local titleLabel = newLabel(topBar, title, Enum.Font.GothamBold, 18, WHITE,
		UDim2.new(0, 18, 0, 4), UDim2.new(1, -132, 0, 22), Enum.TextXAlignment.Left, 7)
	titleLabel.TextTruncate = Enum.TextTruncate.AtEnd

	local subLabel = nil
	if subTitle ~= "" then
		subLabel = newLabel(topBar, subTitle, Enum.Font.Gotham, 12, Color3.fromRGB(200, 200, 210),
			UDim2.new(0, 18, 0, 26), UDim2.new(1, -132, 0, 16), Enum.TextXAlignment.Left, 7)
		subLabel.TextTruncate = Enum.TextTruncate.AtEnd
	end

	local function makeTitleBarButton(text, color, xOffset)
		local b = Instance.new("TextButton")
		b.Text = text
		b.Font = Enum.Font.GothamBold
		b.TextSize = 15
		b.TextColor3 = WHITE
		b.AutoButtonColor = false
		b.BackgroundColor3 = color
		b.Size = UDim2.new(0, 26, 0, 26)
		b.Position = UDim2.new(1, xOffset, 0, 10)
		b.ZIndex = 7
		b.Parent = topBar
		round(b, UDim.new(1, 0))
		applyPressEffect(b, 0.85)
		return b
	end
	local deleteButton   = makeTitleBarButton("✕", COLOR_RED, -34)
	local minimizeButton = makeTitleBarButton("▾", COLOR_OFF, -66)
	local hideButton     = makeTitleBarButton("–", COLOR_OFF, -98)

	----------------------------------------------------------
	-- الجسم: Sidebar + الصفحات
	----------------------------------------------------------
	local body = Instance.new("Frame")
	body.BackgroundTransparency = 1
	body.Size = UDim2.new(1, -24, 1, -(topBar.Size.Y.Offset + 12))
	body.Position = UDim2.new(0, 12, 0, topBar.Size.Y.Offset + 4)
	body.ZIndex = 6
	body.Parent = mainFrame

	local sidebar = Instance.new("Frame")
	sidebar.BackgroundColor3 = WHITE
	sidebar.BackgroundTransparency = 0.95
	sidebar.Size = UDim2.new(0, 128, 1, 0)
	sidebar.ZIndex = 6
	sidebar.Parent = body
	round(sidebar, UDim.new(0, 12))

	local sidebarPad = Instance.new("UIPadding")
	sidebarPad.PaddingTop, sidebarPad.PaddingLeft, sidebarPad.PaddingRight = UDim.new(0, 8), UDim.new(0, 8), UDim.new(0, 8)
	sidebarPad.Parent = sidebar

	local searchBox = Instance.new("TextBox")
	searchBox.PlaceholderText = T("search_placeholder")
	searchBox.Text = ""
	searchBox.Font = Enum.Font.Gotham
	searchBox.TextSize = 12
	searchBox.TextColor3 = WHITE
	searchBox.PlaceholderColor3 = Color3.fromRGB(160, 160, 170)
	searchBox.BackgroundColor3 = WHITE
	searchBox.BackgroundTransparency = 0.9
	searchBox.ClearTextOnFocus = false
	searchBox.Size = UDim2.new(1, 0, 0, 26)
	searchBox.ZIndex = 7
	searchBox.Parent = sidebar
	round(searchBox, UDim.new(0, 8))
	local sbPad = Instance.new("UIPadding")
	sbPad.PaddingLeft = UDim.new(0, 8)
	sbPad.Parent = searchBox

	local tabListWrap = Instance.new("ScrollingFrame")
	tabListWrap.BackgroundTransparency = 1
	tabListWrap.BorderSizePixel = 0
	tabListWrap.ScrollBarThickness = 0
	tabListWrap.CanvasSize = UDim2.new(0, 0, 0, 0)
	tabListWrap.AutomaticCanvasSize = Enum.AutomaticSize.Y
	tabListWrap.Size = UDim2.new(1, 0, 1, -32)
	tabListWrap.Position = UDim2.new(0, 0, 0, 32)
	tabListWrap.ZIndex = 6
	tabListWrap.Parent = sidebar

	local sidebarLayout = Instance.new("UIListLayout")
	sidebarLayout.Padding = UDim.new(0, 6)
	sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sidebarLayout.Parent = tabListWrap

	local pagesHolder = Instance.new("Frame")
	pagesHolder.BackgroundTransparency = 1
	pagesHolder.Size = UDim2.new(1, -138, 1, 0)
	pagesHolder.Position = UDim2.new(0, 138, 0, 0)
	pagesHolder.ZIndex = 6
	pagesHolder.Parent = body

	local allTabButtons = {}
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local q = searchBox.Text:lower()
		for _, entry in ipairs(allTabButtons) do
			entry.button.Visible = q == "" or entry.name:lower():find(q, 1, true) ~= nil
		end
	end)

	----------------------------------------------------------
	-- نافذة تأكيد الحذف
	----------------------------------------------------------
	local openPopupCount = 0 -- >0 = نافذة منبثقة مفتوحة، نجمّد سحب الواجهة

	local confirmOverlay = Instance.new("Frame")
	confirmOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
	confirmOverlay.BackgroundTransparency = 1
	confirmOverlay.Size = UDim2.new(1, 0, 1, 0)
	confirmOverlay.Active = true
	confirmOverlay.Visible = false
	confirmOverlay.ZIndex = 50
	confirmOverlay.Parent = mainFrame

	local confirmBox = Instance.new("Frame")
	confirmBox.BackgroundColor3 = COLOR_DARK
	confirmBox.AnchorPoint = Vector2.new(0.5, 0.5)
	confirmBox.Position = UDim2.new(0.5, 0, 0.5, 0)
	confirmBox.Size = UDim2.new(0, 240, 0, 120)
	confirmBox.ZIndex = 51
	confirmBox.Parent = confirmOverlay
	round(confirmBox, UDim.new(0, 14))
	stroke(confirmBox, COLOR_RED, 1, 0.3)

	newLabel(confirmBox, T("close_title"), Enum.Font.GothamBold, 15, WHITE,
		UDim2.new(0, 0, 0, 14), UDim2.new(1, 0, 0, 20), Enum.TextXAlignment.Center, 52)
	local confirmText = newLabel(confirmBox, T("close_text"), Enum.Font.Gotham, 13, Color3.fromRGB(210, 210, 220),
		UDim2.new(0, 12, 0, 38), UDim2.new(1, -24, 0, 34), Enum.TextXAlignment.Center, 52)
	confirmText.TextWrapped = true

	local function makeConfirmButton(text, color, pos)
		local b = Instance.new("TextButton")
		b.Text = text
		b.Font = Enum.Font.GothamBold
		b.TextSize = 13
		b.TextColor3 = WHITE
		b.AutoButtonColor = false
		b.BackgroundColor3 = color
		b.Size = UDim2.new(0, 100, 0, 30)
		b.Position = pos
		b.ZIndex = 52
		b.Parent = confirmBox
		round(b, UDim.new(0, 8))
		applyPressEffect(b, 0.9)
		return b
	end
	local yesBtn = makeConfirmButton(T("yes"), COLOR_RED, UDim2.new(0, 12, 1, -42))
	local noBtn  = makeConfirmButton(T("no"), COLOR_OFF, UDim2.new(1, -112, 1, -42))

	----------------------------------------------------------
	-- فتح / إخفاء / تصغير / حذف
	----------------------------------------------------------
	local isOpen, isMinimized = false, false
	local fullHeight, collapsedHeight = sizeY, topBar.Size.Y.Offset
	local function logicalHeight() return isMinimized and collapsedHeight or fullHeight end

	local function openUI()
		if isOpen then return end
		isOpen = true
		tween(openButton, EASE_FAST, { Size = UDim2.new(0, 0, 0, 0) })
		task.delay(0.15, function() if isOpen then openButton.Visible = false end end)

		mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		mainFrame.Size = UDim2.new(0, 0, 0, 0)
		mainFrame.Rotation = -6
		mainFrame.Visible = true
		mainStroke.Transparency = 1
		glow.ImageTransparency = 1

		tween(mainFrame, EASE_BOUNCE, { Size = UDim2.new(0, sizeX, 0, logicalHeight()), Rotation = 0 })
		tween(mainStroke, EASE_SOFT, { Transparency = 0.4 })
		tween(glow, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { ImageTransparency = 0.55 })
	end

	local function hideUI()
		if not isOpen then return end
		isOpen = false
		local t = tween(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Size = UDim2.new(0, 0, 0, 0), Rotation = 8 })
		tween(glow, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { ImageTransparency = 1 })
		t.Completed:Connect(function()
			if isOpen then return end
			mainFrame.Visible = false
			mainFrame.Rotation = 0
			openButton.Visible = true
			openButton.Size = UDim2.new(0, 0, 0, 0)
			tween(openButton, EASE_BOUNCE, { Size = openBaseSize })
		end)
	end

	local function toggleMinimize()
		isMinimized = not isMinimized
		if isMinimized then
			if subLabel then subLabel.Visible = false end
			titleLabel.TextXAlignment = Enum.TextXAlignment.Center
			tween(titleLabel, EASE_SOFT, { Position = UDim2.new(0, 0, 0, 4), Size = UDim2.new(1, 0, 0, 22) })
			local t = tween(mainFrame, EASE_SOFT, { Size = UDim2.new(0, sizeX, 0, collapsedHeight) })
			t.Completed:Connect(function() if isMinimized then body.Visible = false end end)
		else
			body.Visible = true
			tween(mainFrame, EASE_SOFT, { Size = UDim2.new(0, sizeX, 0, fullHeight) })
			titleLabel.TextXAlignment = Enum.TextXAlignment.Left
			tween(titleLabel, EASE_SOFT, { Position = UDim2.new(0, 18, 0, 4), Size = UDim2.new(1, -132, 0, 22) })
			if subLabel then subLabel.Visible = true end
		end
	end

	local function deleteEverything()
		Library.Destroy()
	end

	local function askDeleteConfirmation()
		openPopupCount = openPopupCount + 1
		confirmOverlay.Visible = true
		confirmOverlay.BackgroundTransparency = 1
		confirmBox.Size = UDim2.new(0, 0, 0, 0)
		tween(confirmOverlay, EASE_FAST, { BackgroundTransparency = 0.45 })
		tween(confirmBox, EASE_BOUNCE, { Size = UDim2.new(0, 240, 0, 120) })
	end

	local function hideConfirmation()
		openPopupCount = math.max(openPopupCount - 1, 0)
		tween(confirmOverlay, EASE_FAST, { BackgroundTransparency = 1 })
		local t = tween(confirmBox, EASE_CLOSE, { Size = UDim2.new(0, 0, 0, 0) })
		t.Completed:Connect(function(state)
			if state == Enum.PlaybackState.Completed then confirmOverlay.Visible = false end
		end)
	end

	yesBtn.Activated:Connect(function() hideConfirmation(); deleteEverything() end)
	noBtn.Activated:Connect(hideConfirmation)
	openButton.Activated:Connect(function() if not openBtnDragged then openUI() end end)
	hideButton.Activated:Connect(hideUI)
	minimizeButton.Activated:Connect(toggleMinimize)
	deleteButton.Activated:Connect(askDeleteConfirmation)

	----------------------------------------------------------
	-- سحب النافذة بإصبع واحد (يتجمّد لما تكون نافذة منبثقة مفتوحة)
	----------------------------------------------------------
	local windowDragging = false
	makeFrameDraggable(topBar, mainFrame, {
		CanDrag = function() return openPopupCount == 0 end,
		OnBegin = function()
			windowDragging = true
			tween(mainFrame, EASE_FAST, { Size = UDim2.new(0, sizeX - 8, 0, logicalHeight() - 6) })
		end,
		OnEnd = function()
			if windowDragging then
				windowDragging = false
				tween(mainFrame, EASE_BOUNCE, { Size = UDim2.new(0, sizeX, 0, logicalHeight()) })
			end
		end,
	})

	----------------------------------------------------------
	-- التبويبات
	----------------------------------------------------------
	local ctx = {
		accent = accent,
		window = Window,
		popupDelta = function(d) openPopupCount = math.max(openPopupCount + d, 0) end,
	}
	local activeTabButton, activeTabLabel, activeTabPage, activeTabBar = nil, nil, nil, nil
	local tabCount = 0

	-- Window:CreateTab("الرئيسية", "🏠")  أو  Window:CreateTab({Name="الرئيسية", Emoji="🏠"})
	function Window:CreateTab(name, emoji)
		if type(name) == "table" then
			local o = name
			emoji = pick(o, "Emoji", "Icon")
			name = pick(o, "Name", "Title")
		end
		name = tostring(name or "Tab")
		emoji = (emoji ~= nil and tostring(emoji) ~= "") and tostring(emoji) or nil
		tabCount = tabCount + 1

		local tabButton = Instance.new("TextButton")
		tabButton.Text = ""
		tabButton.AutoButtonColor = false
		tabButton.BackgroundColor3 = WHITE
		tabButton.BackgroundTransparency = 1
		tabButton.Size = UDim2.new(1, 0, 0, 34)
		tabButton.LayoutOrder = tabCount
		tabButton.ZIndex = 7
		tabButton.Parent = tabListWrap
		round(tabButton, UDim.new(0, 9))
		table.insert(allTabButtons, { button = tabButton, name = name })

		local textX = 12
		if emoji then
			newLabel(tabButton, emoji, Enum.Font.GothamMedium, 16, WHITE,
				UDim2.new(0, 6, 0, 0), UDim2.new(0, 26, 1, 0), Enum.TextXAlignment.Center, 8)
			textX = 34
		end
		local nameLbl = newLabel(tabButton, name, Enum.Font.GothamMedium, 14, Color3.fromRGB(200, 200, 210),
			UDim2.new(0, textX, 0, 0), UDim2.new(1, -(textX + 6), 1, 0), Enum.TextXAlignment.Left, 8)
		nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

		local activeBar = Instance.new("Frame")
		activeBar.BackgroundColor3 = accent
		activeBar.BorderSizePixel = 0
		activeBar.Size = UDim2.new(0, 3, 0.6, 0)
		activeBar.Position = UDim2.new(0, 0, 0.2, 0)
		activeBar.Visible = false
		activeBar.ZIndex = 8
		activeBar.Parent = tabButton
		round(activeBar, UDim.new(1, 0))
		applyPressEffect(tabButton, 0.96)

		local page = Instance.new("ScrollingFrame")
		page.BackgroundTransparency = 1
		page.BorderSizePixel = 0
		page.Size = UDim2.new(1, 0, 1, 0)
		page.ScrollBarThickness = 3
		page.ScrollBarImageColor3 = accent
		page.CanvasSize = UDim2.new(0, 0, 0, 0)
		page.AutomaticCanvasSize = Enum.AutomaticSize.Y
		page.Visible = false
		page.ZIndex = 6
		page.Parent = pagesHolder

		local pageLayout = Instance.new("UIListLayout")
		pageLayout.Padding = UDim.new(0, 10)
		pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		pageLayout.Parent = page
		local pagePad = Instance.new("UIPadding")
		pagePad.PaddingRight = UDim.new(0, 6)
		pagePad.PaddingBottom = UDim.new(0, 6)
		pagePad.Parent = page

		local Tab = makeElements(page, ctx)
		Tab.Page = page

		local function selectThisTab()
			if activeTabButton == tabButton then return end
			if activeTabButton then
				tween(activeTabButton, EASE_SOFT, { BackgroundTransparency = 1 })
				tween(activeTabLabel, EASE_SOFT, { TextColor3 = Color3.fromRGB(200, 200, 210) })
			end
			if activeTabBar then activeTabBar.Visible = false end
			if activeTabPage then activeTabPage.Visible = false end
			activeTabButton, activeTabLabel, activeTabPage, activeTabBar = tabButton, nameLbl, page, activeBar
			tween(tabButton, EASE_SOFT, { BackgroundTransparency = 0.9 })
			tween(nameLbl, EASE_SOFT, { TextColor3 = WHITE })
			activeBar.Visible = true
			page.Visible = true
		end
		tabButton.Activated:Connect(selectThisTab)
		Tab.Select = selectThisTab
		if not activeTabButton then selectThisTab() end

		Window.Tabs[name] = Tab
		return Tab
	end
	Window.Tab = Window.CreateTab

	-- إنشاء عنصر داخل تبويب باسمه:
	--   Window:CreateButton("اسم التبويب", "اسم الزر", "وصف", function() end)
	--   Window:CreateFoldout({Tab="اسم التبويب", Name="قائمة", Buttons={...}})
	for _, kind in ipairs(ELEMENT_KINDS) do
		Window["Create" .. kind] = function(self, tab, ...)
			local args = { ... }
			if type(tab) == "table" and not tab.Page then
				local o = tab
				tab = pick(o, "Tab", "TabName")
				args = { o }
			end
			local target = (type(tab) == "table" and tab.Page) and tab or Window.Tabs[tostring(tab)]
			if not target then
				warn("[ProUI] التبويب غير موجود:", tostring(tab), "- أنشئه أولاً بـ Window:CreateTab")
				return nil
			end
			return target["Create" .. kind](target, table.unpack(args))
		end
	end

	Window.Open, Window.Close, Window.Minimize, Window.Delete = openUI, hideUI, toggleMinimize, deleteEverything
	Window.AddGradient = function(_, cfg) return Library.AddGradient(cfg) end
	Window.Notify = function(_, ...) return Library.Notify(...) end
	Window.NotifyImage = Window.Notify
	Window.CreateFloatButton = function(_, ...) return Library.CreateFloatButton(...) end
	Library.ActiveWindow = Window

	----------------------------------------------------------
	-- سبلاش ترحيبي ثم فتح الواجهة
	----------------------------------------------------------
	openButton.Visible = false
	Library.PlaySplash(config.Splash, function() openUI() end)

	return Window
end

-- نسخة احتياطية عالمية: تقدر توصل للمكتبة من أي تنفيذ ثاني:
--     local Library = getgenv().ProUILibrary
pcall(function()
	if getgenv then getgenv().ProUILibrary = Library end
end)

-- ⚠️ أي كود تكتبه تحت "return Library" بنفس الملف ما يشتغل أبداً.
-- اكتب كود النافذة بتنفيذ (Execute) ثاني، أو استخدم getgenv().ProUILibrary.
return Library

--[[
	=====================================================================
	 مثال استخدام (بتنفيذ ثاني بعد تشغيل المكتبة):
	=====================================================================

	local Library = getgenv().ProUILibrary

	local Window = Library.CreateWindow({
		Title = "الواجهة الاحترافية", SubTitle = "v3",
		Theme = "Green",
		OpenButton = { Text = "OPEN", Color = "Blue" },
		Splash = { Text = "Rwonom hub", Color = "Red" },
	})

	-- تبويب (الإيموجي بالمعامل الثاني)
	local Main = Window:CreateTab("الرئيسية", "🏠")

	Main:CreateLabel("مرحباً بك", { Bold = true, TextSize = 16 })

	Main:CreateNote("تنبيه", "ملاحظة بلون درك", "Dark")
	Main:CreateNote("معلومة", "ملاحظة بلون أزرق", "Blue")

	-- قائمة منسدلة للأزرار (اقفلها وافتحها)
	local group = Main:CreateFoldout("أزرار الحماية", {
		{ Name = "زر 1", Desc = "وصف", Callback = function() print(1) end },
		{ Name = "زر 2", Callback = function() print(2) end },
	}, true)
	group:AddButton("زر 3", nil, function() print(3) end)

	-- خيارات بالنص: كل خيار له صفحة أزرار
	local sel = Main:CreateSelector({ "عام", "متقدم" }, function(name) print(name) end)
	sel.Pages["عام"]:CreateButton("زر بصفحة عام", function() end)
	sel.Pages["متقدم"]:CreateToggle("خيار متقدم", false, function(v) end)

	-- زر عايم (يسار الشاشة) — الوظيفة من السكربت أو من خانة الكود بإعداداته (⚙)
	Library.CreateFloatButton({ Name = "Fly", Callback = function() print("fly") end })

	-- إشعار عادي (اضغط عليه = يشتغل الـ callback ويختفي)
	Library.Notify("تم", "تم الضغط", "وصف صغير", 4, function() print("clicked") end)

	-- إشعار بصور (حد أقصى 3)
	Library.NotifyImage("صور", "إشعار فيه صور", { 6034287594, 6031094678, 6031280882 }, "وصف", 5)

	-- تدرجين فوق بعض على حواف الواجهة
	Library.AddGradient({ Target = "WindowBorder", Colors = {"blue","purple"}, Speed = 90, Strength = 1 })
	Library.AddGradient({ Target = "WindowBorder", Colors = {"green","cyan"}, Speed = -50, Strength = 0.6 })
	Library.AddGradient({ Target = "FloatButtonBorder", Colors = {"red","orange"}, Speed = 120 })
]]
