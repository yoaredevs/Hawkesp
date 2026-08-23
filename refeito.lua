--[[
    ██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗    ███████╗███████╗██████╗
    ██║  ██║██╔══██╗██║    ██║██║ ██╔╝    ██╔════╝██╔════╝██╔══██╗
    ███████║███████║██║ █╗ ██║█████╔╝     █████╗  ███████╗██████╔╝
    ██╔══██║██╔══██║██║███╗██║██╔═██╗     ██╔══╝  ╚════██║██╔═══╝
    ██║  ██║██║  ██║╚███╔███╔╝██║  ██╗    ███████╗███████║██║
    ╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝    ╚══════╝╚══════╝╚═╝

    Hawk ESP + Aim Assist (Luau) — Drawing API + WindUI
    Developer: yoaredevs

    Built for PRISON LIFE (place 155615604).

    Tabs:
      ESP        — box, health, name, distance, tool, tracers, arrows, skeleton, chams
      Aim Assist — aimbot, silent aim, mobile aim button, triggerbot, prediction, FOV
      Teleport   — map locations, gun givers, players, custom waypoints
      Misc       — themes, rainbow, sky/atmosphere, player, keybinds, performance, unload

    Toggle UI with RightControl.
--]]

--==============================================================
-- SERVICES
--==============================================================
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local Workspace          = game:GetService("Workspace")
local CoreGui            = game:GetService("CoreGui")
local StarterGui         = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

--==============================================================
-- ENV CHECKS
--==============================================================
if not Drawing or not Drawing.new then
    warn("[Hawk] Your executor does not support the Drawing API. Aborting.")
    return
end

--==============================================================
-- GAME LOCK: PRISON LIFE
--==============================================================
local PRISON_LIFE_PLACE_ID = 155615604
local IsPrisonLife = (game.PlaceId == PRISON_LIFE_PLACE_ID)

local gethui  = gethui or function() return CoreGui end
local mouse1press   = rawget(getfenv(), "mouse1press")
local mouse1release = rawget(getfenv(), "mouse1release")
local mousemoverel  = rawget(getfenv(), "mousemoverel")

--==============================================================
-- SETTINGS
--==============================================================
local ESP = {
    Enabled        = false,
    TeamCheck      = false,
    VisibleCheck   = false,
    MaxDistance    = 1000,
    Rainbow        = false,
    RainbowSpeed   = 2,
    Refresh        = 0,

    Box = {
        Enabled   = true,
        Style     = "Full",
        Filled    = false,
        FillAlpha = 0.25,
        Outline   = true,
        Thickness = 1,
        Color     = Color3.fromRGB(255, 255, 255),
    },

    Health = {
        Enabled  = true,
        Text     = true,
        Side     = "Left",
        Gradient = true,
        Color    = Color3.fromRGB(0, 255, 100),
    },

    Name = {
        Enabled  = true,
        Display  = "Display",
        Size     = 13,
        Font     = 2,
        Outline  = true,
        Color    = Color3.fromRGB(255, 255, 255),
    },

    Distance = {
        Enabled = true,
        Size    = 12,
        Color   = Color3.fromRGB(200, 200, 200),
    },

    Tool = {
        Enabled = false,
        Size    = 12,
        Color   = Color3.fromRGB(190, 190, 255),
    },

    Tracer = {
        Enabled   = true,
        Origin    = "Bottom",
        Target    = "Bottom",
        Thickness = 1,
        Outline   = true,
        Color     = Color3.fromRGB(255, 80, 80),
    },

    Skeleton = {
        Enabled   = false,
        Thickness = 1,
        Color     = Color3.fromRGB(255, 255, 255),
    },

    Chams = {
        Enabled      = false,
        FillColor    = Color3.fromRGB(255, 60, 60),
        OutlineColor = Color3.fromRGB(255, 255, 255),
        FillAlpha    = 0.5,
        DepthMode    = "AlwaysOnTop",
    },

    Arrows = {
        Enabled = false,
        Radius  = 220,
        Size    = 18,
        Color   = Color3.fromRGB(255, 170, 0),
    },

    FOV = {
        Enabled      = false,
        Radius       = 120,
        Sides        = 64,
        Thickness    = 1,
        Filled       = false,
        Transparency = 0.15,
        Color        = Color3.fromRGB(255, 255, 255),
    },

    VisibleColor = Color3.fromRGB(0, 255, 120),
    HiddenColor  = Color3.fromRGB(255, 70, 70),
}

--==============================================================
-- AIM ASSIST SETTINGS
--==============================================================
local AIM = {
    Enabled        = false,
    Mode           = "Camera",          -- Camera | Silent | Assist (mouse nudge)
    TargetPart     = "Head",            -- Head | UpperTorso | HumanoidRootPart | Nearest
    Selection      = "Closest to Mouse",-- Closest to Mouse | Closest Distance | Lowest Health
    Smoothness     = 0.18,              -- 0 = instant, 1 = super slow
    UseFOV         = true,
    FOVRadius      = 120,
    StickyTarget   = true,              -- keep the same target while holding the key
    AutoShoot      = false,
    TeamCheck      = true,
    WallCheck      = false,
    AliveOnly      = true,
    MaxDistance    = 1500,
    Keybind        = Enum.UserInputType.MouseButton2,
    KeybindName    = "MouseButton2",
    HoldMode       = true,              -- true = hold, false = toggle
    ShowTargetLine = false,
    TargetLineColor= Color3.fromRGB(0, 255, 170),
    HighlightTarget= false,
    HighlightColor = Color3.fromRGB(0, 200, 255),

    Prediction = {
        Enabled  = false,
        Factor   = 0.135,
        Vertical = 0,
    },

    Trigger = {
        Enabled   = false,
        Delay     = 0.05,
        HoldTime  = 0.03,
        RequireLOS= true,
        TeamCheck = true,
        Key       = nil,               -- nil = always active while Trigger.Enabled
    },
}

local AimState = {
    Active   = false,
    Toggled  = false,
    Target   = nil,
    LastShot = 0,
    Highlight= nil,
}

--==============================================================
-- HUB OVERLAP FIX
-- Drawing API renders above every ScreenGui, so ESP/FOV ends up on top of
-- the WindUI window. We track the window rect and hide whatever overlaps it.
--==============================================================
local UIState = {
    Open    = true,          -- WindUI window currently open
    Mode    = "Behind Hub",  -- "Off" | "Behind Hub" | "Hide All"
    Padding = 6,
}
local getHubRect = function() return nil end -- reassigned once the window exists

--==============================================================
-- HELPERS
--==============================================================
local DrawRegistry = setmetatable({}, { __mode = "k" }) -- drawing -> class name

local function newDrawing(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props or {}) do
        d[k] = v
    end
    d.Visible = false
    DrawRegistry[d] = class
    return d
end

local function boundsOf(d, class)
    if class == "Square" then
        local p, s = d.Position, d.Size
        return p.X, p.Y, s.X, s.Y
    elseif class == "Line" then
        local a, b = d.From, d.To
        return math.min(a.X, b.X), math.min(a.Y, b.Y), math.abs(a.X - b.X), math.abs(a.Y - b.Y)
    elseif class == "Circle" then
        local p, r = d.Position, d.Radius
        return p.X - r, p.Y - r, r * 2, r * 2
    elseif class == "Triangle" then
        local a, b, c = d.PointA, d.PointB, d.PointC
        local x = math.min(a.X, b.X, c.X)
        local y = math.min(a.Y, b.Y, c.Y)
        return x, y, math.max(a.X, b.X, c.X) - x, math.max(a.Y, b.Y, c.Y) - y
    elseif class == "Text" then
        local p = d.Position
        local w = 40
        pcall(function() w = math.max(d.TextBounds.X, 8) end)
        local h = tonumber(d.Size) or 12
        if d.Center then return p.X - w / 2, p.Y, w, h end
        return p.X, p.Y, w, h
    end
    return nil
end

local function clipOne(d, rect, hideAll)
    if not d.Visible then return end
    if hideAll then d.Visible = false return end
    local class = DrawRegistry[d]
    local x, y, w, h = boundsOf(d, class)
    if not x then return end
    if x < rect.X + rect.W and rect.X < x + w and y < rect.Y + rect.H and rect.Y < y + h then
        d.Visible = false
    end
end

-- Called every frame, after everything else has positioned its drawings.
local function applyHubClip()
    if UIState.Mode == "Off" then return end
    local hideAll = (UIState.Mode == "Hide All")
    local rect = getHubRect()
    if not rect then return end
    for d in pairs(DrawRegistry) do
        if not pcall(clipOne, d, rect, hideAll) then
            DrawRegistry[d] = nil
        end
    end
end

local function w2s(pos)
    local v, on = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), on, v.Z
end

local function rainbow()
    return Color3.fromHSV((tick() * ESP.RainbowSpeed * 0.1) % 1, 1, 1)
end

local function colorOf(default, player, isVisible)
    if ESP.Rainbow then return rainbow() end
    if ESP.VisibleCheck then
        return isVisible and ESP.VisibleColor or ESP.HiddenColor
    end
    return default
end

local function isFriendly(player)
    if not ESP.TeamCheck then return false end
    return player.Team ~= nil and player.Team == LocalPlayer.Team
end

local function getBounds(char)
    local minv, maxv
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            local cf, size = part.CFrame, part.Size * 0.5
            local p = cf.Position
            local sx = math.abs(cf.RightVector.X) * size.X
                     + math.abs(cf.UpVector.X) * size.Y
                     + math.abs(cf.LookVector.X) * size.Z
            local sy = math.abs(cf.RightVector.Y) * size.X
                     + math.abs(cf.UpVector.Y) * size.Y
                     + math.abs(cf.LookVector.Y) * size.Z
            local sz = math.abs(cf.RightVector.Z) * size.X
                     + math.abs(cf.UpVector.Z) * size.Y
                     + math.abs(cf.LookVector.Z) * size.Z
            local lo = Vector3.new(p.X - sx, p.Y - sy, p.Z - sz)
            local hi = Vector3.new(p.X + sx, p.Y + sy, p.Z + sz)
            minv = minv and Vector3.new(math.min(minv.X, lo.X), math.min(minv.Y, lo.Y), math.min(minv.Z, lo.Z)) or lo
            maxv = maxv and Vector3.new(math.max(maxv.X, hi.X), math.max(maxv.Y, hi.Y), math.max(maxv.Z, hi.Z)) or hi
        end
    end
    return minv, maxv
end

local function projectBox(minv, maxv)
    local corners = {
        Vector3.new(minv.X, minv.Y, minv.Z), Vector3.new(minv.X, minv.Y, maxv.Z),
        Vector3.new(minv.X, maxv.Y, minv.Z), Vector3.new(minv.X, maxv.Y, maxv.Z),
        Vector3.new(maxv.X, minv.Y, minv.Z), Vector3.new(maxv.X, minv.Y, maxv.Z),
        Vector3.new(maxv.X, maxv.Y, minv.Z), Vector3.new(maxv.X, maxv.Y, maxv.Z),
    }
    local x1, y1 = math.huge, math.huge
    local x2, y2 = -math.huge, -math.huge
    local anyOn = false
    for _, c in ipairs(corners) do
        local sp, on = w2s(c)
        if on then anyOn = true end
        x1, y1 = math.min(x1, sp.X), math.min(y1, sp.Y)
        x2, y2 = math.max(x2, sp.X), math.max(y2, sp.Y)
    end
    if not anyOn then return nil end
    return x1, y1, x2 - x1, y2 - y1
end

local RAY_PARAMS = RaycastParams.new()
RAY_PARAMS.FilterType = Enum.RaycastFilterType.Exclude

local function canSee(char, targetPos)
    local ignore = { char }
    if LocalPlayer.Character then table.insert(ignore, LocalPlayer.Character) end
    RAY_PARAMS.FilterDescendantsInstances = ignore
    local origin = Camera.CFrame.Position
    local dir = targetPos - origin
    local hit = Workspace:Raycast(origin, dir, RAY_PARAMS)
    return hit == nil
end

local SKELETON_R15 = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
local SKELETON_R6 = {
    {"Head","Torso"},
    {"Torso","Left Arm"},{"Torso","Right Arm"},
    {"Torso","Left Leg"},{"Torso","Right Leg"},
}

local Objects = {}

--==============================================================
-- ESP OBJECT
--==============================================================
local ESPObject = {}
ESPObject.__index = ESPObject

function ESPObject.new(player)
    local self = setmetatable({}, ESPObject)
    self.Player = player

    self.d = {
        boxOutline  = newDrawing("Square", { Thickness = 3, Filled = false, Color = Color3.new(0,0,0), ZIndex = 1 }),
        box         = newDrawing("Square", { Thickness = 1, Filled = false, ZIndex = 2 }),
        boxFill     = newDrawing("Square", { Thickness = 1, Filled = true, ZIndex = 0, Transparency = 0.25 }),
        hpOutline   = newDrawing("Line", { Thickness = 3, Color = Color3.new(0,0,0), ZIndex = 1 }),
        hp          = newDrawing("Line", { Thickness = 1, ZIndex = 2 }),
        hpText      = newDrawing("Text", { Size = 11, Center = false, Outline = true, Font = 2, ZIndex = 3 }),
        name        = newDrawing("Text", { Size = 13, Center = true, Outline = true, Font = 2, ZIndex = 3 }),
        dist        = newDrawing("Text", { Size = 12, Center = true, Outline = true, Font = 2, ZIndex = 3 }),
        tool        = newDrawing("Text", { Size = 12, Center = true, Outline = true, Font = 2, ZIndex = 3 }),
        tracerOut   = newDrawing("Line", { Thickness = 3, Color = Color3.new(0,0,0), ZIndex = 1 }),
        tracer      = newDrawing("Line", { Thickness = 1, ZIndex = 2 }),
        arrow       = newDrawing("Triangle", { Thickness = 1, Filled = true, ZIndex = 3 }),
    }

    self.bones = {}
    for i = 1, 16 do
        self.bones[i] = newDrawing("Line", { Thickness = 1, ZIndex = 2 })
    end

    self.highlight = nil
    return self
end

function ESPObject:hideAll()
    for _, d in pairs(self.d) do d.Visible = false end
    for _, b in ipairs(self.bones) do b.Visible = false end
    if self.highlight then self.highlight.Enabled = false end
end

function ESPObject:destroy()
    for _, d in pairs(self.d) do pcall(function() d:Remove() end) end
    for _, b in ipairs(self.bones) do pcall(function() b:Remove() end) end
    if self.highlight then pcall(function() self.highlight:Destroy() end) end
end

function ESPObject:updateChams(char, visible)
    if not ESP.Chams.Enabled then
        if self.highlight then self.highlight.Enabled = false end
        return
    end
    if not self.highlight or not self.highlight.Parent then
        local hl = Instance.new("Highlight")
        hl.Name = "ESP_" .. self.Player.Name
        hl.Adornee = char
        hl.Parent = gethui()
        self.highlight = hl
    end
    local hl = self.highlight
    hl.Adornee = char
    hl.Enabled = true
    hl.FillColor = ESP.Rainbow and rainbow() or (ESP.VisibleCheck and (visible and ESP.VisibleColor or ESP.HiddenColor) or ESP.Chams.FillColor)
    hl.OutlineColor = ESP.Chams.OutlineColor
    hl.FillTransparency = 1 - ESP.Chams.FillAlpha
    hl.OutlineTransparency = 0
    hl.DepthMode = (ESP.Chams.DepthMode == "AlwaysOnTop")
        and Enum.HighlightDepthMode.AlwaysOnTop
        or Enum.HighlightDepthMode.Occluded
end

function ESPObject:Update()
    local d = self.d
    local player = self.Player

    if not ESP.Enabled or not player.Parent then return self:hideAll() end

    local char = player.Character
    if not char then return self:hideAll() end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not hum or not root or not head or hum.Health <= 0 then return self:hideAll() end
    if isFriendly(player) then return self:hideAll() end

    local origin = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local dist = origin and (origin.Position - root.Position).Magnitude
                or (Camera.CFrame.Position - root.Position).Magnitude
    if dist > ESP.MaxDistance then return self:hideAll() end

    local minv, maxv = getBounds(char)
    if not minv then return self:hideAll() end

    local visible = (not ESP.VisibleCheck) or canSee(char, head.Position)
    self:updateChams(char, visible)

    local _, onScreen = w2s(root.Position)

    if not onScreen then
        for k, obj in pairs(d) do
            if k ~= "arrow" then obj.Visible = false end
        end
        for _, b in ipairs(self.bones) do b.Visible = false end

        if ESP.Arrows.Enabled then
            local vp = Camera.ViewportSize
            local center = Vector2.new(vp.X / 2, vp.Y / 2)
            local cf = Camera.CFrame
            local rel = cf:PointToObjectSpace(root.Position)
            local dir = Vector2.new(rel.X, rel.Z).Unit
            local angle = math.atan2(dir.Y, -dir.X) - math.rad(90)
            local pos = center + Vector2.new(math.cos(angle), math.sin(angle)) * ESP.Arrows.Radius
            local s = ESP.Arrows.Size
            d.arrow.PointA = pos + Vector2.new(math.cos(angle), math.sin(angle)) * s
            d.arrow.PointB = pos + Vector2.new(math.cos(angle + 2.3), math.sin(angle + 2.3)) * s
            d.arrow.PointC = pos + Vector2.new(math.cos(angle - 2.3), math.sin(angle - 2.3)) * s
            d.arrow.Color = ESP.Rainbow and rainbow() or ESP.Arrows.Color
            d.arrow.Visible = true
        else
            d.arrow.Visible = false
        end
        return
    end
    d.arrow.Visible = false

    local bx, by, bw, bh = projectBox(minv, maxv)
    if not bx then return self:hideAll() end

    if ESP.Box.Enabled and ESP.Box.Style == "Full" then
        local col = colorOf(ESP.Box.Color, player, visible)
        d.box.Position = Vector2.new(bx, by)
        d.box.Size = Vector2.new(bw, bh)
        d.box.Color = col
        d.box.Thickness = ESP.Box.Thickness
        d.box.Visible = true

        d.boxOutline.Position = d.box.Position
        d.boxOutline.Size = d.box.Size
        d.boxOutline.Thickness = ESP.Box.Thickness + 2
        d.boxOutline.Visible = ESP.Box.Outline

        d.boxFill.Position = d.box.Position
        d.boxFill.Size = d.box.Size
        d.boxFill.Color = col
        d.boxFill.Transparency = ESP.Box.FillAlpha
        d.boxFill.Visible = ESP.Box.Filled
    else
        d.box.Visible = false
        d.boxOutline.Visible = false
        d.boxFill.Visible = ESP.Box.Enabled and ESP.Box.Filled
        if d.boxFill.Visible then
            d.boxFill.Position = Vector2.new(bx, by)
            d.boxFill.Size = Vector2.new(bw, bh)
            d.boxFill.Color = colorOf(ESP.Box.Color, player, visible)
            d.boxFill.Transparency = ESP.Box.FillAlpha
        end
    end

    if ESP.Box.Enabled and ESP.Box.Style == "Corner" then
        local col = colorOf(ESP.Box.Color, player, visible)
        local lx, ly = bw * 0.28, bh * 0.18
        local pts = {
            {Vector2.new(bx, by), Vector2.new(bx + lx, by)},
            {Vector2.new(bx, by), Vector2.new(bx, by + ly)},
            {Vector2.new(bx + bw, by), Vector2.new(bx + bw - lx, by)},
            {Vector2.new(bx + bw, by), Vector2.new(bx + bw, by + ly)},
            {Vector2.new(bx, by + bh), Vector2.new(bx + lx, by + bh)},
            {Vector2.new(bx, by + bh), Vector2.new(bx, by + bh - ly)},
            {Vector2.new(bx + bw, by + bh), Vector2.new(bx + bw - lx, by + bh)},
            {Vector2.new(bx + bw, by + bh), Vector2.new(bx + bw, by + bh - ly)},
        }
        for i = 1, 8 do
            local line = self.bones[i]
            line.From = pts[i][1]
            line.To = pts[i][2]
            line.Color = col
            line.Thickness = ESP.Box.Thickness
            line.Visible = true
        end
    elseif not ESP.Skeleton.Enabled then
        for i = 1, 8 do self.bones[i].Visible = false end
    end

    if ESP.Skeleton.Enabled then
        local set = char:FindFirstChild("UpperTorso") and SKELETON_R15 or SKELETON_R6
        local slot = (ESP.Box.Style == "Corner" and ESP.Box.Enabled) and 9 or 1
        for _, pair in ipairs(set) do
            local a, b = char:FindFirstChild(pair[1]), char:FindFirstChild(pair[2])
            if a and b and slot <= #self.bones then
                local pa, oa = w2s(a.Position)
                local pb, ob = w2s(b.Position)
                local line = self.bones[slot]
                if oa and ob then
                    line.From = pa
                    line.To = pb
                    line.Color = colorOf(ESP.Skeleton.Color, player, visible)
                    line.Thickness = ESP.Skeleton.Thickness
                    line.Visible = true
                end
                slot += 1
            end
        end
        for i = slot, #self.bones do
            if not (ESP.Box.Style == "Corner" and ESP.Box.Enabled and i <= 8) then
                self.bones[i].Visible = false
            end
        end
    else
        local from = (ESP.Box.Style == "Corner" and ESP.Box.Enabled) and 9 or 1
        for i = from, #self.bones do self.bones[i].Visible = false end
    end

    if ESP.Health.Enabled then
        local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        local hpColor = ESP.Health.Gradient
            and Color3.fromRGB(math.floor(255 * (1 - pct)), math.floor(255 * pct), 60)
            or ESP.Health.Color

        local from, to, outFrom, outTo
        if ESP.Health.Side == "Bottom" then
            from = Vector2.new(bx, by + bh + 4)
            to = Vector2.new(bx + bw * pct, by + bh + 4)
            outFrom = Vector2.new(bx - 1, by + bh + 4)
            outTo = Vector2.new(bx + bw + 1, by + bh + 4)
        else
            local x = (ESP.Health.Side == "Right") and (bx + bw + 5) or (bx - 5)
            from = Vector2.new(x, by + bh)
            to = Vector2.new(x, by + bh - bh * pct)
            outFrom = Vector2.new(x, by + bh + 1)
            outTo = Vector2.new(x, by - 1)
        end

        d.hpOutline.From, d.hpOutline.To = outFrom, outTo
        d.hpOutline.Visible = true
        d.hp.From, d.hp.To = from, to
        d.hp.Color = hpColor
        d.hp.Thickness = 1
        d.hp.Visible = true

        if ESP.Health.Text then
            d.hpText.Text = tostring(math.floor(hum.Health)) .. "/" .. tostring(math.floor(hum.MaxHealth))
            d.hpText.Color = hpColor
            d.hpText.Position = (ESP.Health.Side == "Bottom")
                and Vector2.new(bx, by + bh + 7)
                or Vector2.new(to.X + ((ESP.Health.Side == "Right") and 4 or -34), to.Y - 6)
            d.hpText.Visible = true
        else
            d.hpText.Visible = false
        end
    else
        d.hp.Visible, d.hpOutline.Visible, d.hpText.Visible = false, false, false
    end

    if ESP.Name.Enabled then
        local txt
        if ESP.Name.Display == "Username" then
            txt = player.Name
        elseif ESP.Name.Display == "Both" then
            txt = string.format("%s (@%s)", player.DisplayName, player.Name)
        else
            txt = player.DisplayName
        end
        d.name.Text = txt
        d.name.Size = ESP.Name.Size
        d.name.Outline = ESP.Name.Outline
        d.name.Color = colorOf(ESP.Name.Color, player, visible)
        d.name.Position = Vector2.new(bx + bw / 2, by - ESP.Name.Size - 3)
        d.name.Visible = true
    else
        d.name.Visible = false
    end

    local below = by + bh + (ESP.Health.Side == "Bottom" and ESP.Health.Enabled and 16 or 3)
    if ESP.Distance.Enabled then
        d.dist.Text = string.format("[%dm]", math.floor(dist))
        d.dist.Size = ESP.Distance.Size
        d.dist.Color = ESP.Rainbow and rainbow() or ESP.Distance.Color
        d.dist.Position = Vector2.new(bx + bw / 2, below)
        d.dist.Visible = true
        below += ESP.Distance.Size + 1
    else
        d.dist.Visible = false
    end

    if ESP.Tool.Enabled then
        local tool = char:FindFirstChildOfClass("Tool")
        d.tool.Text = tool and tool.Name or "None"
        d.tool.Size = ESP.Tool.Size
        d.tool.Color = ESP.Rainbow and rainbow() or ESP.Tool.Color
        d.tool.Position = Vector2.new(bx + bw / 2, below)
        d.tool.Visible = true
    else
        d.tool.Visible = false
    end

    if ESP.Tracer.Enabled then
        local vp = Camera.ViewportSize
        local from
        if ESP.Tracer.Origin == "Mouse" then
            from = Vector2.new(Mouse.X, Mouse.Y)
        elseif ESP.Tracer.Origin == "Center" then
            from = Vector2.new(vp.X / 2, vp.Y / 2)
        elseif ESP.Tracer.Origin == "Top" then
            from = Vector2.new(vp.X / 2, 0)
        else
            from = Vector2.new(vp.X / 2, vp.Y)
        end

        local to
        if ESP.Tracer.Target == "Head" then
            to = select(1, w2s(head.Position))
        elseif ESP.Tracer.Target == "Center" then
            to = Vector2.new(bx + bw / 2, by + bh / 2)
        else
            to = Vector2.new(bx + bw / 2, by + bh)
        end

        local col = colorOf(ESP.Tracer.Color, player, visible)
        d.tracerOut.From, d.tracerOut.To = from, to
        d.tracerOut.Thickness = ESP.Tracer.Thickness + 2
        d.tracerOut.Visible = ESP.Tracer.Outline

        d.tracer.From, d.tracer.To = from, to
        d.tracer.Color = col
        d.tracer.Thickness = ESP.Tracer.Thickness
        d.tracer.Visible = true
    else
        d.tracer.Visible, d.tracerOut.Visible = false, false
    end
end

--==============================================================
-- SHARED DRAWINGS
--==============================================================
local FOVCircle = newDrawing("Circle", {
    Thickness = 1, NumSides = 64, Filled = false, Transparency = 1,
    Color = Color3.new(1, 1, 1), ZIndex = 1,
})

local AimFOVCircle = newDrawing("Circle", {
    Thickness = 1, NumSides = 72, Filled = false, Transparency = 1,
    Color = Color3.fromRGB(0, 255, 170), ZIndex = 1,
})

local AimLine = newDrawing("Line", { Thickness = 1, ZIndex = 3 })

local function addPlayer(player)
    if player == LocalPlayer then return end
    if Objects[player] then return end
    Objects[player] = ESPObject.new(player)
end

local function removePlayer(player)
    local obj = Objects[player]
    if obj then
        obj:destroy()
        Objects[player] = nil
    end
    if AimState.Target == player then AimState.Target = nil end
end

for _, p in ipairs(Players:GetPlayers()) do addPlayer(p) end
Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(removePlayer)

--==============================================================
-- AIM ASSIST CORE
--==============================================================
local function aimTeamOK(player)
    if not AIM.TeamCheck then return true end
    return not (player.Team ~= nil and player.Team == LocalPlayer.Team)
end

local function getAimPart(char)
    if AIM.TargetPart == "Nearest" then
        local best, bestDist
        local mousePos = Vector2.new(Mouse.X, Mouse.Y)
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                local sp, on = w2s(part.Position)
                if on then
                    local dd = (sp - mousePos).Magnitude
                    if not bestDist or dd < bestDist then
                        best, bestDist = part, dd
                    end
                end
            end
        end
        return best or char:FindFirstChild("HumanoidRootPart")
    end
    return char:FindFirstChild(AIM.TargetPart)
        or char:FindFirstChild("Head")
        or char:FindFirstChild("HumanoidRootPart")
end

local function predictPosition(part)
    if not AIM.Prediction.Enabled then return part.Position end
    local vel = part.AssemblyLinearVelocity or part.Velocity
    return part.Position
        + vel * AIM.Prediction.Factor
        + Vector3.new(0, AIM.Prediction.Vertical, 0)
end

local function isValidTarget(player)
    if player == LocalPlayer then return false end
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    if AIM.AliveOnly and hum.Health <= 0 then return false end
    if not aimTeamOK(player) then return false end

    local origin = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local dist = origin and (origin.Position - root.Position).Magnitude
                or (Camera.CFrame.Position - root.Position).Magnitude
    if dist > AIM.MaxDistance then return false end

    local part = getAimPart(char)
    if not part then return false end
    if AIM.WallCheck and not canSee(char, part.Position) then return false end
    return true, part, hum, dist
end

local function getTarget()
    local vp = Camera.ViewportSize
    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
    local center = Vector2.new(vp.X / 2, vp.Y / 2)
    local anchor = (AIM.Mode == "Camera") and center or mousePos

    local best, bestScore
    for _, player in ipairs(Players:GetPlayers()) do
        local ok, part, hum, dist = isValidTarget(player)
        if ok then
            local sp, on = w2s(part.Position)
            if on then
                local screenDist = (sp - anchor).Magnitude
                if (not AIM.UseFOV) or screenDist <= AIM.FOVRadius then
                    local score
                    if AIM.Selection == "Closest Distance" then
                        score = dist
                    elseif AIM.Selection == "Lowest Health" then
                        score = hum.Health
                    else
                        score = screenDist
                    end
                    if not bestScore or score < bestScore then
                        best, bestScore = player, score
                    end
                end
            end
        end
    end
    return best
end

local function setTargetHighlight(player)
    if not AIM.HighlightTarget or not player then
        if AimState.Highlight then AimState.Highlight.Enabled = false end
        return
    end
    if not AimState.Highlight or not AimState.Highlight.Parent then
        local hl = Instance.new("Highlight")
        hl.Name = "HawkAimTarget"
        hl.Parent = gethui()
        AimState.Highlight = hl
    end
    local hl = AimState.Highlight
    hl.Adornee = player.Character
    hl.Enabled = true
    hl.FillTransparency = 0.7
    hl.OutlineTransparency = 0
    hl.FillColor = AIM.HighlightColor
    hl.OutlineColor = AIM.HighlightColor
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
end

local function aimAt(worldPos, dt)
    if AIM.Mode == "Silent" then return end

    if AIM.Mode == "Assist" and mousemoverel then
        local sp, on = w2s(worldPos)
        if not on then return end
        local vp = Camera.ViewportSize
        local center = Vector2.new(vp.X / 2, vp.Y / 2)
        local delta = (sp - center)
        local factor = 1 - math.clamp(AIM.Smoothness, 0, 0.98)
        mousemoverel(delta.X * factor, delta.Y * factor)
        return
    end

    local goal = CFrame.new(Camera.CFrame.Position, worldPos)
    if AIM.Smoothness <= 0.01 then
        Camera.CFrame = goal
    else
        local alpha = math.clamp((dt or 1 / 60) / math.max(AIM.Smoothness, 0.001), 0, 1)
        Camera.CFrame = Camera.CFrame:Lerp(goal, alpha)
    end
end

local function fireTrigger()
    if not AIM.Trigger.Enabled then return end
    if not mouse1press or not mouse1release then return end
    if tick() - AimState.LastShot < AIM.Trigger.Delay + AIM.Trigger.HoldTime then return end

    local hitPlayer
    local target = Mouse.Target
    if target then
        local char = target:FindFirstAncestorOfClass("Model")
        if char then
            hitPlayer = Players:GetPlayerFromCharacter(char)
        end
    end
    if not hitPlayer or hitPlayer == LocalPlayer then return end
    if AIM.Trigger.TeamCheck and hitPlayer.Team ~= nil and hitPlayer.Team == LocalPlayer.Team then return end

    local hum = hitPlayer.Character and hitPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    if AIM.Trigger.RequireLOS and not canSee(hitPlayer.Character, target.Position) then return end

    AimState.LastShot = tick()
    task.spawn(function()
        task.wait(AIM.Trigger.Delay)
        pcall(mouse1press)
        task.wait(AIM.Trigger.HoldTime)
        pcall(mouse1release)
    end)
end

-- Silent aim hook (works on games that use raycasts / Mouse.Hit)
local silentHookInstalled = false
local function installSilentAim()
    if silentHookInstalled then return end
    if not hookmetamethod or not getnamecallmethod then return end
    silentHookInstalled = true

    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller or not checkcaller() then
            if AIM.Enabled and AIM.Mode == "Silent" and AimState.Active and AimState.Target then
                local char = AimState.Target.Character
                local part = char and getAimPart(char)
                if part then
                    local pos = predictPosition(part)
                    if method == "Raycast" and self == Workspace then
                        local origin = ({...})[1]
                        if typeof(origin) == "Vector3" then
                            return oldNamecall(self, origin, (pos - origin), select(3, ...))
                        end
                    end
                end
            end
        end
        return oldNamecall(self, ...)
    end)

    if hookfunction and Mouse then
        pcall(function()
            local mt = getrawmetatable(game)
            if setreadonly then setreadonly(mt, false) end
            local oldIndex = mt.__index
            mt.__index = newcclosure(function(self, key)
                if AIM.Enabled and AIM.Mode == "Silent" and AimState.Active and AimState.Target
                   and self == Mouse and (key == "Hit" or key == "Target") then
                    local char = AimState.Target.Character
                    local part = char and getAimPart(char)
                    if part then
                        if key == "Hit" then
                            return CFrame.new(predictPosition(part))
                        else
                            return part
                        end
                    end
                end
                return oldIndex(self, key)
            end)
            if setreadonly then setreadonly(mt, true) end
        end)
    end
end

--==============================================================
-- MAIN LOOP
--==============================================================
local lastUpdate = 0
local renderConn
renderConn = RunService.RenderStepped:Connect(function(dt)
    Camera = Workspace.CurrentCamera

    -- ESP FOV circle
    if ESP.FOV.Enabled then
        local vp = Camera.ViewportSize
        FOVCircle.Position = Vector2.new(vp.X / 2, vp.Y / 2)
        FOVCircle.Radius = ESP.FOV.Radius
        FOVCircle.NumSides = ESP.FOV.Sides
        FOVCircle.Thickness = ESP.FOV.Thickness
        FOVCircle.Filled = ESP.FOV.Filled
        FOVCircle.Transparency = ESP.FOV.Filled and ESP.FOV.Transparency or 1
        FOVCircle.Color = ESP.Rainbow and rainbow() or ESP.FOV.Color
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    -- Aim FOV circle
    if AIM.Enabled and AIM.UseFOV and AIM.ShowFOV ~= false then
        local vp = Camera.ViewportSize
        AimFOVCircle.Position = (AIM.Mode == "Camera")
            and Vector2.new(vp.X / 2, vp.Y / 2)
            or Vector2.new(Mouse.X, Mouse.Y)
        AimFOVCircle.Radius = AIM.FOVRadius
        AimFOVCircle.Color = ESP.Rainbow and rainbow() or AIM.TargetLineColor
        AimFOVCircle.Visible = true
    else
        AimFOVCircle.Visible = false
    end

    -- Aim assist
    if AIM.Enabled and AimState.Active then
        if (not AIM.StickyTarget) or (not AimState.Target) or (not select(1, isValidTarget(AimState.Target))) then
            AimState.Target = getTarget()
        end
        local target = AimState.Target
        if target and target.Character then
            local part = getAimPart(target.Character)
            if part then
                local pos = predictPosition(part)
                aimAt(pos, dt)
                setTargetHighlight(target)
                if AIM.ShowTargetLine then
                    local sp, on = w2s(pos)
                    local vp = Camera.ViewportSize
                    if on then
                        AimLine.From = Vector2.new(vp.X / 2, vp.Y)
                        AimLine.To = sp
                        AimLine.Color = ESP.Rainbow and rainbow() or AIM.TargetLineColor
                        AimLine.Visible = true
                    else
                        AimLine.Visible = false
                    end
                else
                    AimLine.Visible = false
                end
                if AIM.AutoShoot and mouse1press and mouse1release then
                    if tick() - AimState.LastShot > 0.12 then
                        AimState.LastShot = tick()
                        task.spawn(function()
                            pcall(mouse1press)
                            task.wait(0.03)
                            pcall(mouse1release)
                        end)
                    end
                end
            end
        else
            AimLine.Visible = false
            setTargetHighlight(nil)
        end
    else
        AimState.Target = AIM.StickyTarget and nil or AimState.Target
        AimLine.Visible = false
        setTargetHighlight(nil)
    end

    -- Triggerbot
    if AIM.Trigger.Enabled then
        pcall(fireTrigger)
    end

    -- ESP update throttle
    local doUpdate = true
    if ESP.Refresh > 0 then
        if tick() - lastUpdate < ESP.Refresh then
            doUpdate = false
        else
            lastUpdate = tick()
        end
    end

    if doUpdate then
        for _, obj in pairs(Objects) do
            local ok, err = pcall(obj.Update, obj)
            if not ok then
                pcall(obj.hideAll, obj)
                warn("[Hawk] update error:", err)
            end
        end
    end

    -- last step: nothing may sit on top of the hub window
    applyHubClip()
end)

--==============================================================
-- INPUT (aim keybind)
--==============================================================
local function inputMatchesKeybind(input)
    if typeof(AIM.Keybind) == "EnumItem" then
        if AIM.Keybind.EnumType == Enum.UserInputType then
            return input.UserInputType == AIM.Keybind
        else
            return input.KeyCode == AIM.Keybind
        end
    end
    return false
end

local inputBegan = UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if AIM.Enabled and inputMatchesKeybind(input) then
        if AIM.HoldMode then
            AimState.Active = true
        else
            AimState.Toggled = not AimState.Toggled
            AimState.Active = AimState.Toggled
        end
        if AimState.Active then AimState.Target = getTarget() end
    end
end)

local inputEnded = UserInputService.InputEnded:Connect(function(input)
    if AIM.Enabled and AIM.HoldMode and inputMatchesKeybind(input) then
        AimState.Active = false
        AimState.Target = nil
    end
end)

--==============================================================
-- UNLOAD
--==============================================================
local extraConns = {}
local function unload()
    if renderConn then renderConn:Disconnect() end
    if inputBegan then inputBegan:Disconnect() end
    if inputEnded then inputEnded:Disconnect() end
    for _, c in ipairs(extraConns) do pcall(function() c:Disconnect() end) end
    for player in pairs(Objects) do removePlayer(player) end
    pcall(function() FOVCircle:Remove() end)
    pcall(function() AimFOVCircle:Remove() end)
    pcall(function() AimLine:Remove() end)
    if AimState.Highlight then pcall(function() AimState.Highlight:Destroy() end) end
end

--==============================================================
-- WINDUI
--==============================================================
local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

if not ok or not WindUI then
    warn("[Hawk] Failed to load WindUI, script still running. Error:", WindUI)
    ESP.Enabled = true
    return
end

--==============================================================
-- CUSTOM THEMES
--==============================================================
local CustomThemes = {
    {
        Name = "Hawk",
        Accent = "#1b1f2a",
        Dialog = "#141821",
        Outline = "#3a4358",
        Text = "#e8ecf5",
        Placeholder = "#8892a6",
        Background = "#0d1017",
        Button = "#232a38",
        Icon = "#ff7b3d",
    },
    {
        Name = "Midnight",
        Accent = "#161a2e",
        Dialog = "#10142a",
        Outline = "#2f3763",
        Text = "#dfe4ff",
        Placeholder = "#7f88b8",
        Background = "#080a18",
        Button = "#1e2444",
        Icon = "#6c7bff",
    },
    {
        Name = "Blood",
        Accent = "#251114",
        Dialog = "#1c0d10",
        Outline = "#5c2229",
        Text = "#ffe7e9",
        Placeholder = "#b38288",
        Background = "#120709",
        Button = "#331519",
        Icon = "#ff3b4e",
    },
    {
        Name = "Neon",
        Accent = "#101a19",
        Dialog = "#0b1413",
        Outline = "#1f5f55",
        Text = "#dcfff7",
        Placeholder = "#69a99e",
        Background = "#060d0c",
        Button = "#12241f",
        Icon = "#00ffc8",
    },
    {
        Name = "Cyberpunk",
        Accent = "#1a1030",
        Dialog = "#140b26",
        Outline = "#5a2ea6",
        Text = "#f2e4ff",
        Placeholder = "#a98fd1",
        Background = "#0b0618",
        Button = "#25164a",
        Icon = "#ff00d4",
    },
    {
        Name = "Ocean",
        Accent = "#0e1e2b",
        Dialog = "#0a1722",
        Outline = "#1f4a6b",
        Text = "#dff1ff",
        Placeholder = "#7ba6c4",
        Background = "#050e16",
        Button = "#13293b",
        Icon = "#2fa8ff",
    },
    {
        Name = "Sakura",
        Accent = "#2a1a22",
        Dialog = "#20131a",
        Outline = "#6b3a4d",
        Text = "#ffe9f1",
        Placeholder = "#c290a4",
        Background = "#160b11",
        Button = "#38222c",
        Icon = "#ff86b3",
    },
    {
        Name = "Matrix",
        Accent = "#0d1a0d",
        Dialog = "#09140a",
        Outline = "#1f5c25",
        Text = "#d8ffd8",
        Placeholder = "#6fa872",
        Background = "#040b05",
        Button = "#112016",
        Icon = "#33ff55",
    },
    {
        Name = "Gold",
        Accent = "#231d10",
        Dialog = "#1b160b",
        Outline = "#6b5620",
        Text = "#fff6dd",
        Placeholder = "#c2ab77",
        Background = "#120e06",
        Button = "#2e2614",
        Icon = "#ffc63d",
    },
    {
        Name = "Monochrome",
        Accent = "#1c1c1c",
        Dialog = "#151515",
        Outline = "#3d3d3d",
        Text = "#f0f0f0",
        Placeholder = "#8a8a8a",
        Background = "#0b0b0b",
        Button = "#242424",
        Icon = "#ffffff",
    },
    {
        Name = "Ice",
        Accent = "#dfe9f3",
        Dialog = "#eef4fa",
        Outline = "#b6c9dc",
        Text = "#1b2733",
        Placeholder = "#6b7d8f",
        Background = "#f7fbff",
        Button = "#d3e2f0",
        Icon = "#0b84ff",
    },
    {
        Name = "Sunset",
        Accent = "#2b1512",
        Dialog = "#21100e",
        Outline = "#743a2a",
        Text = "#ffeade",
        Placeholder = "#c99a84",
        Background = "#160907",
        Button = "#3a1d17",
        Icon = "#ff7a29",
    },
}

local ThemeNames = {}
for _, t in ipairs(CustomThemes) do
    pcall(function() WindUI:AddTheme(t) end)
    table.insert(ThemeNames, t.Name)
end
-- built-in WindUI themes
for _, n in ipairs({ "Dark", "Light", "Rose", "Indigo", "Plant", "Crimson" }) do
    table.insert(ThemeNames, n)
end
pcall(function() WindUI:SetTheme("Hawk") end)

--==============================================================
-- WINDOW
--==============================================================
local Window = WindUI:CreateWindow({
    Title = "Hawk ESP",
    Icon = "eye",
    Author = "by yoaredevs",
    Folder = "HawkESP",
    Size = UDim2.fromOffset(620, 490),
    Transparent = true,
    Theme = "Hawk",
    SideBarWidth = 190,
})

Window:EditOpenButton({
    Title = "Hawk ESP",
    Icon = "eye",
    CornerRadius = UDim.new(0, 14),
    Draggable = true,
})

--==============================================================
-- HUB RECT (so drawings never cover the window)
--==============================================================
pcall(function() Window:OnOpen(function() UIState.Open = true end) end)
pcall(function() Window:OnClose(function() UIState.Open = false end) end)

getHubRect = function()
    if UIState.Mode == "Off" then return nil end

    local main = Window and Window.UIElements and Window.UIElements.Main
    if not main then return nil end
    if Window.Closed == true then return nil end
    if not UIState.Open then return nil end
    if main.Visible == false then return nil end

    local pos, size = main.AbsolutePosition, main.AbsoluteSize
    if size.X <= 1 or size.Y <= 1 then return nil end

    -- Drawing coords include the topbar inset; WindUI uses IgnoreGuiInset,
    -- but add the offset back if some executor's gui does not.
    local offY = 0
    pcall(function()
        local sg = main:FindFirstAncestorWhichIsA("ScreenGui")
        if sg and not sg.IgnoreGuiInset then
            offY = game:GetService("GuiService"):GetGuiInset().Y
        end
    end)

    local pad = UIState.Padding
    return {
        X = pos.X - pad,
        Y = pos.Y + offY - pad,
        W = size.X + pad * 2,
        H = size.Y + pad * 2,
    }
end

local TabESP  = Window:Tab({ Title = "ESP", Icon = "eye" })
local TabAim  = Window:Tab({ Title = "Aim Assist", Icon = "crosshair" })
local TabTP   = Window:Tab({ Title = "Teleport", Icon = "map-pin" })
local TabMisc = Window:Tab({ Title = "Misc", Icon = "settings" })
Window:SelectTab(1)

--==============================================================
-- TAB: ESP (everything visual)
--==============================================================
TabESP:Section({ Title = "Core" })
TabESP:Toggle({
    Title = "Enable ESP",
    Desc = "Master switch for every visual",
    Value = false,
    Callback = function(v)
        ESP.Enabled = v
        if not v then
            for _, obj in pairs(Objects) do obj:hideAll() end
        end
    end,
})
TabESP:Toggle({
    Title = "Team Check",
    Desc = "Hide players on your team",
    Value = false,
    Callback = function(v) ESP.TeamCheck = v end,
})
TabESP:Toggle({
    Title = "Visibility Check",
    Desc = "Color by line of sight (visible / hidden)",
    Value = false,
    Callback = function(v) ESP.VisibleCheck = v end,
})
TabESP:Slider({
    Title = "Max Distance",
    Step = 25,
    Value = { Min = 50, Max = 5000, Default = 1000 },
    Callback = function(v) ESP.MaxDistance = v end,
})
TabESP:Colorpicker({
    Title = "Visible Color",
    Default = ESP.VisibleColor,
    Callback = function(c) ESP.VisibleColor = c end,
})
TabESP:Colorpicker({
    Title = "Hidden Color",
    Default = ESP.HiddenColor,
    Callback = function(c) ESP.HiddenColor = c end,
})

TabESP:Section({ Title = "Box" })
TabESP:Toggle({ Title = "Box", Value = true, Callback = function(v) ESP.Box.Enabled = v end })
TabESP:Dropdown({
    Title = "Box Style",
    Values = { "Full", "Corner" },
    Value = "Full",
    Callback = function(v) ESP.Box.Style = v end,
})
TabESP:Toggle({ Title = "Box Outline", Value = true, Callback = function(v) ESP.Box.Outline = v end })
TabESP:Toggle({ Title = "Box Filled", Value = false, Callback = function(v) ESP.Box.Filled = v end })
TabESP:Slider({
    Title = "Box Fill Opacity", Step = 0.05,
    Value = { Min = 0, Max = 1, Default = 0.25 },
    Callback = function(v) ESP.Box.FillAlpha = v end,
})
TabESP:Slider({
    Title = "Box Thickness", Step = 1,
    Value = { Min = 1, Max = 5, Default = 1 },
    Callback = function(v) ESP.Box.Thickness = v end,
})
TabESP:Colorpicker({
    Title = "Box Color", Default = ESP.Box.Color,
    Callback = function(c) ESP.Box.Color = c end,
})

TabESP:Section({ Title = "Health Bar" })
TabESP:Toggle({ Title = "Health Bar", Value = true, Callback = function(v) ESP.Health.Enabled = v end })
TabESP:Toggle({ Title = "Health Text", Value = true, Callback = function(v) ESP.Health.Text = v end })
TabESP:Toggle({ Title = "Gradient (green -> red)", Value = true, Callback = function(v) ESP.Health.Gradient = v end })
TabESP:Dropdown({
    Title = "Bar Position",
    Values = { "Left", "Right", "Bottom" },
    Value = "Left",
    Callback = function(v) ESP.Health.Side = v end,
})
TabESP:Colorpicker({
    Title = "Static Bar Color", Default = ESP.Health.Color,
    Callback = function(c) ESP.Health.Color = c end,
})

TabESP:Section({ Title = "Name / Distance / Tool" })
TabESP:Toggle({ Title = "Name", Value = true, Callback = function(v) ESP.Name.Enabled = v end })
TabESP:Dropdown({
    Title = "Name Type",
    Values = { "Display", "Username", "Both" },
    Value = "Display",
    Callback = function(v) ESP.Name.Display = v end,
})
TabESP:Slider({
    Title = "Name Size", Step = 1,
    Value = { Min = 9, Max = 24, Default = 13 },
    Callback = function(v) ESP.Name.Size = v end,
})
TabESP:Colorpicker({
    Title = "Name Color", Default = ESP.Name.Color,
    Callback = function(c) ESP.Name.Color = c end,
})
TabESP:Toggle({ Title = "Distance", Value = true, Callback = function(v) ESP.Distance.Enabled = v end })
TabESP:Slider({
    Title = "Distance Size", Step = 1,
    Value = { Min = 9, Max = 24, Default = 12 },
    Callback = function(v) ESP.Distance.Size = v end,
})
TabESP:Colorpicker({
    Title = "Distance Color", Default = ESP.Distance.Color,
    Callback = function(c) ESP.Distance.Color = c end,
})
TabESP:Toggle({ Title = "Show Tool", Value = false, Callback = function(v) ESP.Tool.Enabled = v end })
TabESP:Colorpicker({
    Title = "Tool Color", Default = ESP.Tool.Color,
    Callback = function(c) ESP.Tool.Color = c end,
})

TabESP:Section({ Title = "Tracers" })
TabESP:Toggle({ Title = "Tracer", Value = true, Callback = function(v) ESP.Tracer.Enabled = v end })
TabESP:Dropdown({
    Title = "Tracer Origin",
    Values = { "Bottom", "Center", "Top", "Mouse" },
    Value = "Bottom",
    Callback = function(v) ESP.Tracer.Origin = v end,
})
TabESP:Dropdown({
    Title = "Tracer Target",
    Values = { "Bottom", "Center", "Head" },
    Value = "Bottom",
    Callback = function(v) ESP.Tracer.Target = v end,
})
TabESP:Toggle({ Title = "Tracer Outline", Value = true, Callback = function(v) ESP.Tracer.Outline = v end })
TabESP:Slider({
    Title = "Tracer Thickness", Step = 1,
    Value = { Min = 1, Max = 5, Default = 1 },
    Callback = function(v) ESP.Tracer.Thickness = v end,
})
TabESP:Colorpicker({
    Title = "Tracer Color", Default = ESP.Tracer.Color,
    Callback = function(c) ESP.Tracer.Color = c end,
})

TabESP:Section({ Title = "Off-screen Arrows" })
TabESP:Toggle({ Title = "Arrows", Value = false, Callback = function(v) ESP.Arrows.Enabled = v end })
TabESP:Slider({
    Title = "Arrow Radius", Step = 5,
    Value = { Min = 60, Max = 500, Default = 220 },
    Callback = function(v) ESP.Arrows.Radius = v end,
})
TabESP:Slider({
    Title = "Arrow Size", Step = 1,
    Value = { Min = 8, Max = 40, Default = 18 },
    Callback = function(v) ESP.Arrows.Size = v end,
})
TabESP:Colorpicker({
    Title = "Arrow Color", Default = ESP.Arrows.Color,
    Callback = function(c) ESP.Arrows.Color = c end,
})

TabESP:Section({ Title = "Chams" })
TabESP:Toggle({
    Title = "Chams", Value = false,
    Callback = function(v)
        ESP.Chams.Enabled = v
        if not v then
            for _, obj in pairs(Objects) do
                if obj.highlight then obj.highlight.Enabled = false end
            end
        end
    end,
})
TabESP:Dropdown({
    Title = "Depth Mode",
    Values = { "AlwaysOnTop", "Occluded" },
    Value = "AlwaysOnTop",
    Callback = function(v) ESP.Chams.DepthMode = v end,
})
TabESP:Slider({
    Title = "Chams Fill Opacity", Step = 0.05,
    Value = { Min = 0, Max = 1, Default = 0.5 },
    Callback = function(v) ESP.Chams.FillAlpha = v end,
})
TabESP:Colorpicker({
    Title = "Chams Fill Color", Default = ESP.Chams.FillColor,
    Callback = function(c) ESP.Chams.FillColor = c end,
})
TabESP:Colorpicker({
    Title = "Chams Outline Color", Default = ESP.Chams.OutlineColor,
    Callback = function(c) ESP.Chams.OutlineColor = c end,
})

TabESP:Section({ Title = "Skeleton" })
TabESP:Toggle({ Title = "Skeleton", Value = false, Callback = function(v) ESP.Skeleton.Enabled = v end })
TabESP:Slider({
    Title = "Skeleton Thickness", Step = 1,
    Value = { Min = 1, Max = 4, Default = 1 },
    Callback = function(v) ESP.Skeleton.Thickness = v end,
})
TabESP:Colorpicker({
    Title = "Skeleton Color", Default = ESP.Skeleton.Color,
    Callback = function(c) ESP.Skeleton.Color = c end,
})

TabESP:Section({ Title = "ESP FOV Circle" })
TabESP:Toggle({ Title = "FOV Circle", Value = false, Callback = function(v) ESP.FOV.Enabled = v end })
TabESP:Slider({
    Title = "FOV Radius", Step = 5,
    Value = { Min = 20, Max = 600, Default = 120 },
    Callback = function(v) ESP.FOV.Radius = v end,
})
TabESP:Toggle({ Title = "FOV Filled", Value = false, Callback = function(v) ESP.FOV.Filled = v end })
TabESP:Colorpicker({
    Title = "FOV Color", Default = ESP.FOV.Color,
    Callback = function(c) ESP.FOV.Color = c end,
})

--==============================================================
-- TAB: AIM ASSIST
--==============================================================
TabAim:Section({ Title = "Aimbot" })
TabAim:Toggle({
    Title = "Enable Aim Assist",
    Desc = "Master switch for aim features",
    Value = false,
    Callback = function(v)
        AIM.Enabled = v
        if not v then
            AimState.Active = false
            AimState.Toggled = false
            AimState.Target = nil
            AimLine.Visible = false
            AimFOVCircle.Visible = false
            setTargetHighlight(nil)
        end
    end,
})
TabAim:Dropdown({
    Title = "Mode",
    Desc = "Camera = snap camera • Silent = hook shots • Assist = soft mouse pull",
    Values = { "Camera", "Silent", "Assist" },
    Value = "Camera",
    Callback = function(v)
        AIM.Mode = v
        if v == "Silent" then
            installSilentAim()
            if not silentHookInstalled then
                WindUI:Notify({ Title = "Hawk", Content = "Executor has no hook support for Silent Aim.", Duration = 4, Icon = "triangle-alert" })
            end
        end
    end,
})
TabAim:Dropdown({
    Title = "Target Part",
    Values = { "Head", "UpperTorso", "HumanoidRootPart", "Nearest" },
    Value = "Head",
    Callback = function(v) AIM.TargetPart = v end,
})
TabAim:Dropdown({
    Title = "Target Selection",
    Values = { "Closest to Mouse", "Closest Distance", "Lowest Health" },
    Value = "Closest to Mouse",
    Callback = function(v) AIM.Selection = v end,
})
TabAim:Slider({
    Title = "Smoothness",
    Desc = "0 = instant snap, higher = slower drag",
    Step = 0.01,
    Value = { Min = 0, Max = 1, Default = 0.18 },
    Callback = function(v) AIM.Smoothness = v end,
})
TabAim:Slider({
    Title = "Max Distance", Step = 25,
    Value = { Min = 50, Max = 5000, Default = 1500 },
    Callback = function(v) AIM.MaxDistance = v end,
})
TabAim:Toggle({ Title = "Sticky Target", Desc = "Keep locking the same player while held", Value = true, Callback = function(v) AIM.StickyTarget = v end })
TabAim:Toggle({ Title = "Team Check", Value = true, Callback = function(v) AIM.TeamCheck = v end })
TabAim:Toggle({ Title = "Wall Check", Desc = "Ignore targets behind walls", Value = false, Callback = function(v) AIM.WallCheck = v end })
TabAim:Toggle({ Title = "Alive Only", Value = true, Callback = function(v) AIM.AliveOnly = v end })
TabAim:Toggle({ Title = "Auto Shoot", Desc = "Clicks while locked (needs executor mouse funcs)", Value = false, Callback = function(v) AIM.AutoShoot = v end })

TabAim:Section({ Title = "Keybind" })
TabAim:Keybind({
    Title = "Aim Key",
    Value = "MouseButton2",
    Callback = function(key)
        local kc = Enum.KeyCode[key]
        if kc then
            AIM.Keybind = kc
        elseif Enum.UserInputType[key] then
            AIM.Keybind = Enum.UserInputType[key]
        end
        AIM.KeybindName = key
    end,
})
TabAim:Toggle({
    Title = "Hold Mode",
    Desc = "On = hold the key • Off = toggle",
    Value = true,
    Callback = function(v)
        AIM.HoldMode = v
        AimState.Active = false
        AimState.Toggled = false
    end,
})

TabAim:Section({ Title = "FOV" })
TabAim:Toggle({ Title = "Use FOV Limit", Value = true, Callback = function(v) AIM.UseFOV = v end })
TabAim:Slider({
    Title = "FOV Radius", Step = 5,
    Value = { Min = 20, Max = 800, Default = 120 },
    Callback = function(v) AIM.FOVRadius = v end,
})
TabAim:Colorpicker({
    Title = "FOV / Line Color", Default = AIM.TargetLineColor,
    Callback = function(c) AIM.TargetLineColor = c end,
})

TabAim:Section({ Title = "Prediction" })
TabAim:Toggle({ Title = "Enable Prediction", Value = false, Callback = function(v) AIM.Prediction.Enabled = v end })
TabAim:Slider({
    Title = "Prediction Factor", Step = 0.005,
    Value = { Min = 0, Max = 0.5, Default = 0.135 },
    Callback = function(v) AIM.Prediction.Factor = v end,
})
TabAim:Slider({
    Title = "Vertical Offset", Step = 0.1,
    Value = { Min = -5, Max = 5, Default = 0 },
    Callback = function(v) AIM.Prediction.Vertical = v end,
})

TabAim:Section({ Title = "Triggerbot" })
TabAim:Toggle({
    Title = "Enable Triggerbot",
    Desc = "Auto-fires when your crosshair is on an enemy",
    Value = false,
    Callback = function(v)
        AIM.Trigger.Enabled = v
        if v and not mouse1press then
            WindUI:Notify({ Title = "Hawk", Content = "Executor does not expose mouse1press.", Duration = 4, Icon = "triangle-alert" })
        end
    end,
})
TabAim:Slider({
    Title = "Trigger Delay (s)", Step = 0.01,
    Value = { Min = 0, Max = 1, Default = 0.05 },
    Callback = function(v) AIM.Trigger.Delay = v end,
})
TabAim:Slider({
    Title = "Click Hold (s)", Step = 0.01,
    Value = { Min = 0.01, Max = 0.5, Default = 0.03 },
    Callback = function(v) AIM.Trigger.HoldTime = v end,
})
TabAim:Toggle({ Title = "Trigger Wall Check", Value = true, Callback = function(v) AIM.Trigger.RequireLOS = v end })
TabAim:Toggle({ Title = "Trigger Team Check", Value = true, Callback = function(v) AIM.Trigger.TeamCheck = v end })

TabAim:Section({ Title = "Target Visuals" })
TabAim:Toggle({ Title = "Target Line", Value = false, Callback = function(v) AIM.ShowTargetLine = v end })
TabAim:Toggle({ Title = "Highlight Target", Value = false, Callback = function(v) AIM.HighlightTarget = v end })
TabAim:Colorpicker({
    Title = "Highlight Color", Default = AIM.HighlightColor,
    Callback = function(c) AIM.HighlightColor = c end,
})
local TargetParagraph = TabAim:Paragraph({
    Title = "Current Target",
    Desc = "None",
})
task.spawn(function()
    while task.wait(0.25) do
        local name = AimState.Target and AimState.Target.Name or "None"
        pcall(function()
            TargetParagraph:SetDesc(AIM.Enabled
                and ("Target: " .. name .. "  |  Locked: " .. tostring(AimState.Active))
                or "Aim Assist disabled")
        end)
    end
end)

do
--==============================================================
-- PRISON LIFE — MOBILE AIMBOT
--==============================================================
TabAim:Section({ Title = "Mobile Aimbot (locked)" })

local MOBILE = {
    AlwaysOn      = false,
    GunOnly       = false,
    ArrestedCheck = true,

    -- wall check
    WallCheck     = true,
    MultiPartLOS  = true,   -- tries Head / Torso / Root instead of a single ray
    SeeThroughGlass = true, -- ignores transparent / non-collidable parts (bars, windows)
    UnlockNoLOS   = true,   -- drops the target when line of sight is lost
    LOSGrace      = 0.35,   -- seconds of tolerance before dropping

    -- fov
    FOVBase       = 150,
    DynamicFOV    = false,
    FOVNearRadius = 320,    -- radius used when the target is close
    FOVFarRadius  = 90,     -- radius used at FarStuds and beyond
    NearStuds     = 40,
    FarStuds      = 350,

    -- smoothness
    SmoothX       = 0.10,
    SmoothY       = 0.14,
    AdaptiveSmooth= true,   -- farther target = softer tracking
    SnapFirst     = false,  -- first frame of a new lock is instant
    MaxDegPerSec  = 0,      -- 0 = unlimited

    -- teams
    TeamMode      = "Enemies Only", -- Everyone | Enemies Only | Selected Teams
    TeamList      = {},             -- multi-select of team names
    IgnoreFriends = false,

    -- target
    Priority      = "Closest to Crosshair",
    PartByDistance= false,
    CloseStuds    = 60,     -- below this = Head, above = Torso
    AutoSwitch    = true,
    ReTargetDelay = 0.10,
    Throttle      = 0.05,   -- seconds between target searches
}

local MobileState = { LastSearch = 0, LastLoss = 0, LastTarget = nil, NewLock = false }

-- PL helpers ---------------------------------------------------
local function plHoldingGun()
    local ch = LocalPlayer.Character
    if not ch then return false end
    for _, t in ipairs(ch:GetChildren()) do
        if t:IsA("Tool") then return true, t.Name end
    end
    return false
end

local function plIsArrested(player)
    local ch = player.Character
    if not ch then return false end
    if ch:FindFirstChild("Handcuffs") or ch:FindFirstChild("HandcuffsHolder") then return true end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if hum and hum.WalkSpeed == 0 and hum.Health > 0 and player.Team
       and tostring(player.Team) == "Inmates" then return true end
    return false
end

-- TEAMS --------------------------------------------------------
local function teamNameOf(player)
    return player.Team and tostring(player.Team) or "Neutral"
end

local function listTeamNames()
    local names, seen = {}, {}
    for _, t in ipairs(game:GetService("Teams"):GetTeams()) do
        if not seen[t.Name] then seen[t.Name] = true; table.insert(names, t.Name) end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        local n = teamNameOf(p)
        if not seen[n] then seen[n] = true; table.insert(names, n) end
    end
    if not seen["Neutral"] then table.insert(names, "Neutral") end
    table.sort(names)
    return names
end

local FriendCache = {}
local function isFriendOfMine(player)
    local c = FriendCache[player.UserId]
    if c ~= nil then return c end
    local ok, res = pcall(function() return LocalPlayer:IsFriendsWith(player.UserId) end)
    res = ok and res or false
    FriendCache[player.UserId] = res
    return res
end

local function mobileTeamOK(player)
    if MOBILE.IgnoreFriends and isFriendOfMine(player) then return false end
    local mode = MOBILE.TeamMode
    if mode == "Everyone" then return true end
    if mode == "Enemies Only" then
        return not (player.Team ~= nil and player.Team == LocalPlayer.Team)
    end
    -- Selected Teams
    if #MOBILE.TeamList == 0 then return true end
    local n = teamNameOf(player)
    for _, t in ipairs(MOBILE.TeamList) do
        if t == n then return true end
    end
    return false
end

-- WALL CHECK ---------------------------------------------------
local MOB_RAY = RaycastParams.new()
MOB_RAY.FilterType = Enum.RaycastFilterType.Exclude

local function rayClear(origin, target, char)
    local ignore = { char }
    if LocalPlayer.Character then table.insert(ignore, LocalPlayer.Character) end
    for _ = 1, 6 do
        MOB_RAY.FilterDescendantsInstances = ignore
        local hit = Workspace:Raycast(origin, target - origin, MOB_RAY)
        if not hit then return true end
        local inst = hit.Instance
        -- glass, bars and other see-through geometry should not block the lock
        if MOBILE.SeeThroughGlass and inst:IsA("BasePart")
           and (inst.Transparency >= 0.5 or not inst.CanCollide) then
            table.insert(ignore, inst)
        else
            return false
        end
    end
    return false
end

local LOS_PARTS = { "Head", "UpperTorso", "Torso", "HumanoidRootPart" }
local function mobileCanSee(char, part)
    if not char then return false end
    local origin = Camera.CFrame.Position
    if not MOBILE.MultiPartLOS then
        return rayClear(origin, part.Position, char)
    end
    if rayClear(origin, part.Position, char) then return true end
    for _, name in ipairs(LOS_PARTS) do
        local p = char:FindFirstChild(name)
        if p and p ~= part and rayClear(origin, p.Position, char) then return true end
    end
    return false
end

-- FOV ----------------------------------------------------------
local function effectiveFOV(dist)
    if not MOBILE.DynamicFOV or not dist then return MOBILE.FOVBase end
    local a = math.clamp((dist - MOBILE.NearStuds) / math.max(MOBILE.FarStuds - MOBILE.NearStuds, 1), 0, 1)
    return MOBILE.FOVNearRadius + (MOBILE.FOVFarRadius - MOBILE.FOVNearRadius) * a
end

-- part choice by distance --------------------------------------
local baseAimPart = getAimPart
getAimPart = function(char)
    if MOBILE.AlwaysOn and MOBILE.PartByDistance then
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local ref = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
        if ref then
            local d = root and (root.Position - ref.Position).Magnitude
                    or (Camera.CFrame.Position - ref.Position).Magnitude
            if d <= MOBILE.CloseStuds then
                return char:FindFirstChild("Head") or ref
            end
            return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or ref
        end
    end
    return baseAimPart(char)
end

-- extra target filter layered on top of the base aim logic
local baseIsValid = isValidTarget
isValidTarget = function(player)
    local ok, part, hum, dist = baseIsValid(player)
    if not ok then return false end
    if MOBILE.ArrestedCheck and plIsArrested(player) then return false end
    if MOBILE.AlwaysOn then
        if not mobileTeamOK(player) then return false end
        if MOBILE.WallCheck and not mobileCanSee(player.Character, part) then return false end
    end
    return ok, part, hum, dist
end

-- TARGET SEARCH ------------------------------------------------
local function aimingAtMe(player)
    local ch = player.Character
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp or not myRoot then return 0 end
    local dir = (myRoot.Position - hrp.Position)
    if dir.Magnitude < 0.1 then return 1 end
    return hrp.CFrame.LookVector:Dot(dir.Unit)
end

local baseGetTarget = getTarget
getTarget = function()
    if not MOBILE.AlwaysOn then return baseGetTarget() end

    local vp = Camera.ViewportSize
    local anchor = Vector2.new(vp.X / 2, vp.Y / 2)
    local best, bestScore, bestFOV

    for _, player in ipairs(Players:GetPlayers()) do
        local ok, part, hum, dist = isValidTarget(player)
        if ok then
            local sp, on = w2s(part.Position)
            if on then
                local screenDist = (sp - anchor).Magnitude
                local radius = effectiveFOV(dist)
                if (not AIM.UseFOV) or screenDist <= radius then
                    local score
                    if MOBILE.Priority == "Closest Distance" then
                        score = dist
                    elseif MOBILE.Priority == "Lowest Health" then
                        score = hum.Health
                    elseif MOBILE.Priority == "Aiming At Me" then
                        score = -aimingAtMe(player) * 1000 + screenDist
                    else
                        score = screenDist
                    end
                    if not bestScore or score < bestScore then
                        best, bestScore, bestFOV = player, score, radius
                    end
                end
            end
        end
    end

    if bestFOV then AIM.FOVRadius = bestFOV end
    return best
end

-- SMOOTHNESS ---------------------------------------------------
local baseAimAt = aimAt
local function angDelta(a, b)
    return (b - a + math.pi) % (math.pi * 2) - math.pi
end

aimAt = function(worldPos, dt)
    if not MOBILE.AlwaysOn then return baseAimAt(worldPos, dt) end
    if AIM.Mode == "Silent" then return end
    dt = dt or 1 / 60

    local cam = Camera.CFrame
    local goal = CFrame.new(cam.Position, worldPos)
    local cPitch, cYaw = cam:ToEulerAnglesYXZ()
    local gPitch, gYaw = goal:ToEulerAnglesYXZ()

    local sx, sy = MOBILE.SmoothX, MOBILE.SmoothY
    if MOBILE.AdaptiveSmooth then
        local d = (worldPos - cam.Position).Magnitude
        local f = 1 + math.clamp(d / 300, 0, 1.5) -- far = slower
        sx, sy = sx * f, sy * f
    end
    if MOBILE.SnapFirst and MobileState.NewLock then
        sx, sy = 0, 0
        MobileState.NewLock = false
    end

    local ax = (sx <= 0.01) and 1 or math.clamp(dt / math.max(sx, 0.001), 0, 1)
    local ay = (sy <= 0.01) and 1 or math.clamp(dt / math.max(sy, 0.001), 0, 1)

    local dYaw = angDelta(cYaw, gYaw) * ax
    local dPitch = angDelta(cPitch, gPitch) * ay

    if MOBILE.MaxDegPerSec > 0 then
        local cap = math.rad(MOBILE.MaxDegPerSec) * dt
        dYaw = math.clamp(dYaw, -cap, cap)
        dPitch = math.clamp(dPitch, -cap, cap)
    end

    Camera.CFrame = CFrame.new(cam.Position)
        * CFrame.fromEulerAnglesYXZ(cPitch + dPitch, cYaw + dYaw, 0)
end

TabAim:Toggle({
    Title = "Aimbot Always On",
    Desc = "Locked on — no button, no keybind. Snaps to the closest target inside the FOV",
    Value = false,
    Callback = function(v)
        MOBILE.AlwaysOn = v
        if v then
            AIM.Enabled = true
            AimState.Active = true
            AimState.Target = getTarget()
        else
            AimState.Active = false
            AimState.Toggled = false
            AimState.Target = nil
        end
    end,
})
TabAim:Toggle({
    Title = "Only With Weapon Equipped",
    Desc = "Pauses the lock while your hands are empty",
    Value = false,
    Callback = function(v) MOBILE.GunOnly = v end,
})
TabAim:Toggle({
    Title = "Ignore Arrested Players",
    Value = true,
    Callback = function(v) MOBILE.ArrestedCheck = v end,
})

--------------------------------------------------------------
-- WALL CHECK
--------------------------------------------------------------
TabAim:Section({ Title = "Mobile — Wall Check" })
TabAim:Toggle({
    Title = "Wall Check",
    Desc = "Only locks targets with a clear line of sight",
    Value = true,
    Callback = function(v)
        MOBILE.WallCheck = v
        MobileState.LastLoss = 0
    end,
})
TabAim:Toggle({
    Title = "Multi-Part LOS",
    Desc = "Tries Head / Torso / Root instead of a single ray — far fewer false blocks",
    Value = true,
    Callback = function(v) MOBILE.MultiPartLOS = v end,
})
TabAim:Toggle({
    Title = "See Through Glass / Bars",
    Desc = "Ignores transparent or non-collidable parts (cell bars, windows)",
    Value = true,
    Callback = function(v) MOBILE.SeeThroughGlass = v end,
})
TabAim:Toggle({
    Title = "Unlock When LOS Is Lost",
    Desc = "Drops the target when he goes behind a wall. Off = keeps tracking through cover",
    Value = true,
    Callback = function(v)
        MOBILE.UnlockNoLOS = v
        MobileState.LastLoss = 0
    end,
})
TabAim:Slider({
    Title = "LOS Grace (s)", Step = 0.05,
    Desc = "Tolerance before dropping a target that got blocked — avoids flicker behind poles",
    Value = { Min = 0, Max = 2, Default = 0.35 },
    Callback = function(v) MOBILE.LOSGrace = v end,
})

--------------------------------------------------------------
-- TEAM CHECK
--------------------------------------------------------------
TabAim:Section({ Title = "Mobile — Team Check" })
TabAim:Dropdown({
    Title = "Team Mode",
    Desc = "Everyone = no filter | Enemies Only = skips your own team | Selected Teams = list below",
    Values = { "Everyone", "Enemies Only", "Selected Teams" },
    Value = "Enemies Only",
    Callback = function(v)
        MOBILE.TeamMode = v
        AimState.Target = nil
    end,
})
local TeamDropdown = TabAim:Dropdown({
    Title = "Selected Teams",
    Desc = "Only used when Team Mode is 'Selected Teams'",
    Multi = true,
    AllowNone = true,
    Values = listTeamNames(),
    Value = {},
    Callback = function(v)
        local list = {}
        if type(v) == "table" then
            for k, val in pairs(v) do
                if val == true then
                    table.insert(list, k)
                elseif type(val) == "string" then
                    table.insert(list, val)
                end
            end
        end
        MOBILE.TeamList = list
        AimState.Target = nil
    end,
})
-- keeps the team list in sync when teams appear / players join
task.spawn(function()
    local last = table.concat(listTeamNames(), ",")
    while task.wait(3) do
        local names = listTeamNames()
        local now = table.concat(names, ",")
        if now ~= last then
            last = now
            pcall(function() TeamDropdown:Refresh(names) end)
        end
    end
end)
TabAim:Toggle({
    Title = "Ignore Friends",
    Desc = "Never locks anyone on your Roblox friends list",
    Value = false,
    Callback = function(v)
        MOBILE.IgnoreFriends = v
        AimState.Target = nil
    end,
})

--------------------------------------------------------------
-- TARGET SELECTION
--------------------------------------------------------------
TabAim:Section({ Title = "Mobile — Targeting" })
TabAim:Dropdown({
    Title = "Priority",
    Desc = "How the next target is picked",
    Values = { "Closest to Crosshair", "Closest Distance", "Lowest Health", "Aiming At Me" },
    Value = "Closest to Crosshair",
    Callback = function(v)
        MOBILE.Priority = v
        AimState.Target = nil
    end,
})
TabAim:Toggle({
    Title = "Auto Switch Target",
    Desc = "Drops the lock when the target leaves the FOV and grabs the next one",
    Value = true,
    Callback = function(v) MOBILE.AutoSwitch = v end,
})
TabAim:Toggle({
    Title = "Part By Distance",
    Desc = "Head when close, Torso when far — more reliable hits at range",
    Value = false,
    Callback = function(v) MOBILE.PartByDistance = v end,
})
TabAim:Slider({
    Title = "Head Range (studs)", Step = 5,
    Desc = "Below this distance it aims at the Head",
    Value = { Min = 10, Max = 300, Default = 60 },
    Callback = function(v) MOBILE.CloseStuds = v end,
})
TabAim:Slider({
    Title = "Re-Target Delay (s)", Step = 0.01,
    Desc = "Wait before locking someone new after losing a target",
    Value = { Min = 0, Max = 1, Default = 0.10 },
    Callback = function(v) MOBILE.ReTargetDelay = v end,
})
TabAim:Slider({
    Title = "Search Throttle (s)", Step = 0.01,
    Desc = "Time between target searches. Raise it if your phone drops FPS",
    Value = { Min = 0, Max = 0.5, Default = 0.05 },
    Callback = function(v) MOBILE.Throttle = v end,
})

--------------------------------------------------------------
-- FOV
--------------------------------------------------------------
TabAim:Section({ Title = "Mobile — FOV" })
TabAim:Slider({
    Title = "Mobile FOV Radius", Step = 5,
    Desc = "Used while Aimbot Always On is active",
    Value = { Min = 20, Max = 900, Default = 150 },
    Callback = function(v)
        MOBILE.FOVBase = v
        if not MOBILE.DynamicFOV then AIM.FOVRadius = v end
    end,
})
TabAim:Toggle({
    Title = "Dynamic FOV",
    Desc = "Wide circle up close, tight circle at range",
    Value = false,
    Callback = function(v)
        MOBILE.DynamicFOV = v
        if not v then AIM.FOVRadius = MOBILE.FOVBase end
    end,
})
TabAim:Slider({
    Title = "FOV Near Radius", Step = 5,
    Value = { Min = 20, Max = 900, Default = 320 },
    Callback = function(v) MOBILE.FOVNearRadius = v end,
})
TabAim:Slider({
    Title = "FOV Far Radius", Step = 5,
    Value = { Min = 10, Max = 900, Default = 90 },
    Callback = function(v) MOBILE.FOVFarRadius = v end,
})
TabAim:Slider({
    Title = "Near Distance (studs)", Step = 5,
    Value = { Min = 5, Max = 300, Default = 40 },
    Callback = function(v) MOBILE.NearStuds = v end,
})
TabAim:Slider({
    Title = "Far Distance (studs)", Step = 10,
    Value = { Min = 50, Max = 2000, Default = 350 },
    Callback = function(v) MOBILE.FarStuds = v end,
})

--------------------------------------------------------------
-- SMOOTHNESS
--------------------------------------------------------------
TabAim:Section({ Title = "Mobile — Smoothness" })
TabAim:Slider({
    Title = "Smooth Horizontal (X)", Step = 0.01,
    Desc = "0 = instant snap. Higher = softer / more legit",
    Value = { Min = 0, Max = 1, Default = 0.10 },
    Callback = function(v) MOBILE.SmoothX = v end,
})
TabAim:Slider({
    Title = "Smooth Vertical (Y)", Step = 0.01,
    Value = { Min = 0, Max = 1, Default = 0.14 },
    Callback = function(v) MOBILE.SmoothY = v end,
})
TabAim:Toggle({
    Title = "Adaptive Smoothness",
    Desc = "Farther target = softer tracking",
    Value = true,
    Callback = function(v) MOBILE.AdaptiveSmooth = v end,
})
TabAim:Toggle({
    Title = "Snap On New Lock",
    Desc = "First frame of a new target is instant, then it smooths",
    Value = false,
    Callback = function(v) MOBILE.SnapFirst = v end,
})
TabAim:Slider({
    Title = "Max Turn Speed (deg/s)", Step = 10,
    Desc = "0 = unlimited. Caps how fast the camera can rotate",
    Value = { Min = 0, Max = 1080, Default = 0 },
    Callback = function(v) MOBILE.MaxDegPerSec = v end,
})

-- the lock itself: forced every frame, nothing to hold
table.insert(extraConns, RunService.RenderStepped:Connect(function()
    if not MOBILE.AlwaysOn then return end
    if not AIM.Enabled then
        AimState.Active = false
        return
    end
    if MOBILE.GunOnly and not plHoldingGun() then
        AimState.Active = false
        AimState.Target = nil
        return
    end
    AimState.Active = true

    local now = tick()
    local target = AimState.Target

    -- drop a target that died, left, changed team or went behind a wall
    if target then
        local ok, part = isValidTarget(target)
        if not ok then
            if MOBILE.WallCheck and MOBILE.UnlockNoLOS and MOBILE.LOSGrace > 0 then
                if MobileState.LastLoss == 0 then MobileState.LastLoss = now end
                if now - MobileState.LastLoss >= MOBILE.LOSGrace then
                    AimState.Target = nil
                    MobileState.LastLoss = 0
                end
            else
                AimState.Target = nil
                MobileState.LastLoss = 0
            end
        else
            MobileState.LastLoss = 0
            -- target left the FOV
            if MOBILE.AutoSwitch and AIM.UseFOV and part then
                local sp, on = w2s(part.Position)
                local vp = Camera.ViewportSize
                if not on or (sp - Vector2.new(vp.X / 2, vp.Y / 2)).Magnitude > AIM.FOVRadius * 1.15 then
                    AimState.Target = nil
                end
            end
        end
    end

    -- throttled search
    if not AimState.Target and now - MobileState.LastSearch >= math.max(MOBILE.Throttle, MOBILE.ReTargetDelay) then
        MobileState.LastSearch = now
        local found = getTarget()
        if found then
            AimState.Target = found
            if found ~= MobileState.LastTarget then
                MobileState.NewLock = true
                MobileState.LastTarget = found
            end
        end
    end
end))

TabAim:Section({ Title = "Aimbot FOV" })
AIM.ShowFOV = true
TabAim:Toggle({
    Title = "Use FOV Limit",
    Desc = "Only lock targets inside the circle",
    Value = true,
    Callback = function(v) AIM.UseFOV = v end,
})
TabAim:Slider({
    Title = "FOV Radius", Step = 5,
    Desc = "Small = precise, big = grabs anyone on screen",
    Value = { Min = 20, Max = 900, Default = 150 },
    Callback = function(v) AIM.FOVRadius = v end,
})
TabAim:Toggle({
    Title = "Show FOV Circle",
    Value = true,
    Callback = function(v) AIM.ShowFOV = v end,
})
TabAim:Colorpicker({
    Title = "FOV Circle Color",
    Default = AIM.TargetLineColor,
    Callback = function(c) AIM.TargetLineColor = c end,
})
TabAim:Slider({
    Title = "Lock Smoothness", Step = 0.01,
    Desc = "0 = instant snap (cravado). Higher = smoother/legit",
    Value = { Min = 0, Max = 1, Default = 0 },
    Callback = function(v) AIM.Smoothness = v end,
})
AIM.Smoothness = 0
AIM.FOVRadius = 150


TabAim:Section({ Title = "Prison Life Teams" })
local PLTeamPriority = "Any"
TabAim:Dropdown({
    Title = "Target Team",
    Desc = "Only lock players from this team",
    Values = { "Any", "Guards", "Inmates", "Criminals", "Neutral" },
    Value = "Any",
    Callback = function(v) PLTeamPriority = v end,
})
local baseIsValid2 = isValidTarget
isValidTarget = function(player)
    if PLTeamPriority ~= "Any" then
        local t = player.Team and tostring(player.Team) or "Neutral"
        if t ~= PLTeamPriority then return false end
    end
    return baseIsValid2(player)
end

--==============================================================
-- TAB: TELEPORT (Prison Life)
--==============================================================
local function getRoot()
    local ch = LocalPlayer.Character
    return ch and (ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart)
end

local LastPos
local function tpTo(pos)
    local root = getRoot()
    if not root then
        WindUI:Notify({ Title = "Hawk", Content = "No character.", Duration = 3, Icon = "triangle-alert" })
        return false
    end
    LastPos = root.CFrame
    root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    return true
end

TabTP:Section({ Title = "Map Locations" })

-- fixed Prison Life landmarks (approximate, tweak with waypoints if needed)
local PLPlaces = {
    ["Prison Yard"]       = Vector3.new(816, 98, 2280),
    ["Cafeteria"]         = Vector3.new(886, 98, 2149),
    ["Cells"]             = Vector3.new(920, 98, 2318),
    ["Guard Armory"]      = Vector3.new(838, 98, 2296),
    ["Prison Entrance"]    = Vector3.new(786, 98, 2200),
    ["Criminal Base"]     = Vector3.new(-943, 96, 2135),
    ["Criminal Base Roof"] = Vector3.new(-943, 130, 2135),
}

-- anything the map itself exposes (spawns are exact, no guessing)
local function collectSpawns()
    local list = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") then
            local label = "Spawn: " .. obj.Name
            local n = 2
            while list[label] do label = "Spawn: " .. obj.Name .. " #" .. n; n = n + 1 end
            list[label] = obj.Position
        end
    end
    return list
end

local PlaceMap = {}
local function rebuildPlaces()
    PlaceMap = {}
    for k, v in pairs(PLPlaces) do PlaceMap[k] = v end
    for k, v in pairs(collectSpawns()) do PlaceMap[k] = v end
    local names = {}
    for k in pairs(PlaceMap) do table.insert(names, k) end
    table.sort(names)
    return names
end

local PlaceDropdown = TabTP:Dropdown({
    Title = "Teleport To",
    Desc = "Prison Life landmarks + every spawn found in the map",
    Values = rebuildPlaces(),
    Value = "Prison Yard",
    Callback = function(v)
        local pos = PlaceMap[v]
        if pos and tpTo(pos) then
            WindUI:Notify({ Title = "Hawk", Content = "Teleported: " .. v, Duration = 2, Icon = "map-pin" })
        end
    end,
})
TabTP:Button({
    Title = "Rescan Map Locations",
    Callback = function()
        local names = rebuildPlaces()
        pcall(function() PlaceDropdown:Refresh(names) end)
        WindUI:Notify({ Title = "Hawk", Content = #names .. " locations found.", Duration = 3, Icon = "refresh-cw" })
    end,
})

TabTP:Section({ Title = "Guns / Items" })

local function getGivers()
    local out = {}
    local items = Workspace:FindFirstChild("Prison_ITEMS")
    local giver = items and items:FindFirstChild("giver")
    if not giver then return out end
    for _, g in ipairs(giver:GetChildren()) do
        local pickup = g:FindFirstChild("ITEMPICKUP")
        if pickup and pickup:IsA("BasePart") then out[g.Name] = pickup end
    end
    return out
end

local Givers = getGivers()
local function giverNames()
    local n = {}
    for k in pairs(Givers) do table.insert(n, k) end
    table.sort(n)
    if #n == 0 then n = { "none found — press Rescan" } end
    return n
end

local GunDropdown = TabTP:Dropdown({
    Title = "Teleport to Gun",
    Desc = "Reads workspace.Prison_ITEMS.giver, so it lists whatever this server has",
    Values = giverNames(),
    Value = giverNames()[1],
    Callback = function(v)
        local pickup = Givers[v]
        if not pickup or not pickup.Parent then
            WindUI:Notify({ Title = "Hawk", Content = "Giver not found — rescan.", Duration = 3, Icon = "triangle-alert" })
            return
        end
        tpTo(pickup.Position)
    end,
})
TabTP:Button({
    Title = "Rescan Givers",
    Callback = function()
        Givers = getGivers()
        pcall(function() GunDropdown:Refresh(giverNames()) end)
        local c = 0; for _ in pairs(Givers) do c = c + 1 end
        WindUI:Notify({ Title = "Hawk", Content = c .. " givers found.", Duration = 3, Icon = "refresh-cw" })
    end,
})
TabTP:Button({
    Title = "Grab All Guns",
    Desc = "Teleports through every giver, then returns you",
    Callback = function()
        local root = getRoot()
        if not root then return end
        local back = root.CFrame
        task.spawn(function()
            for name, pickup in pairs(Givers) do
                if pickup.Parent then
                    root.CFrame = CFrame.new(pickup.Position + Vector3.new(0, 2, 0))
                    task.wait(0.35)
                end
            end
            task.wait(0.2)
            local r = getRoot()
            if r then r.CFrame = back end
            WindUI:Notify({ Title = "Hawk", Content = "Done grabbing guns.", Duration = 3, Icon = "check" })
        end)
    end,
})
local ExpandedPickups = {}
TabTP:Toggle({
    Title = "Big Pickup Hitbox",
    Desc = "Enlarges item pickups so you grab them from far away",
    Value = false,
    Callback = function(v)
        if v then
            for name, pickup in pairs(getGivers()) do
                if not ExpandedPickups[pickup] then
                    ExpandedPickups[pickup] = { pickup.Size, pickup.CanCollide, pickup.Transparency }
                end
                pcall(function()
                    pickup.Size = Vector3.new(60, 60, 60)
                    pickup.CanCollide = false
                    pickup.Transparency = 0.9
                end)
            end
        else
            for pickup, old in pairs(ExpandedPickups) do
                pcall(function()
                    pickup.Size = old[1]
                    pickup.CanCollide = old[2]
                    pickup.Transparency = old[3]
                end)
            end
            ExpandedPickups = {}
        end
    end,
})

TabTP:Section({ Title = "Players" })
local function playerNames()
    local n = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(n, p.Name .. " [" .. (p.Team and tostring(p.Team) or "Neutral") .. "]")
        end
    end
    if #n == 0 then n = { "no other players" } end
    table.sort(n)
    return n
end
local PlayerDropdown = TabTP:Dropdown({
    Title = "Teleport to Player",
    Values = playerNames(),
    Value = playerNames()[1],
    Callback = function(v)
        local name = tostring(v):match("^(%S+)")
        local target = name and Players:FindFirstChild(name)
        local root = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if root then
            tpTo(root.Position + Vector3.new(0, 0, 3))
        else
            WindUI:Notify({ Title = "Hawk", Content = "Player has no character.", Duration = 3, Icon = "triangle-alert" })
        end
    end,
})
TabTP:Button({
    Title = "Refresh Player List",
    Callback = function() pcall(function() PlayerDropdown:Refresh(playerNames()) end) end,
})
TabTP:Toggle({
    Title = "Aim Target Teleport",
    Desc = "Teleport behind whoever the aimbot is locked on (hold the aim button)",
    Value = false,
    Callback = function(v)
        if not v then return end
        task.spawn(function()
            local t = AimState.Target
            local root = t and t.Character and t.Character:FindFirstChild("HumanoidRootPart")
            if root then tpTo(root.Position - root.CFrame.LookVector * 3) end
        end)
    end,
})

TabTP:Section({ Title = "Waypoints" })
local Waypoints = {}
local WaypointName = "spot 1"
local WaypointDropdown
local function waypointNames()
    local n = {}
    for k in pairs(Waypoints) do table.insert(n, k) end
    table.sort(n)
    if #n == 0 then n = { "no waypoints" } end
    return n
end
TabTP:Input({
    Title = "Waypoint Name",
    Placeholder = "spot 1",
    Callback = function(txt) if txt and txt ~= "" then WaypointName = txt end end,
})
TabTP:Button({
    Title = "Save Current Position",
    Callback = function()
        local root = getRoot()
        if not root then return end
        Waypoints[WaypointName] = root.Position
        pcall(function() WaypointDropdown:Refresh(waypointNames()) end)
        WindUI:Notify({ Title = "Hawk", Content = "Saved: " .. WaypointName, Duration = 3, Icon = "bookmark" })
    end,
})
WaypointDropdown = TabTP:Dropdown({
    Title = "Go To Waypoint",
    Values = waypointNames(),
    Value = waypointNames()[1],
    Callback = function(v)
        local pos = Waypoints[v]
        if pos then tpTo(pos) end
    end,
})
TabTP:Button({
    Title = "Back to Last Position",
    Desc = "Undo the last teleport",
    Callback = function()
        local root = getRoot()
        if root and LastPos then
            local here = root.CFrame
            root.CFrame = LastPos
            LastPos = here
        end
    end,
})

end

--==============================================================
-- TAB: MISC
--==============================================================
TabMisc:Section({ Title = "Themes" })
TabMisc:Dropdown({
    Title = "UI Theme",
    Desc = "12 custom themes + WindUI defaults",
    Values = ThemeNames,
    Value = "Hawk",
    Callback = function(v)
        pcall(function() WindUI:SetTheme(v) end)
    end,
})
TabMisc:Toggle({
    Title = "Transparent Window",
    Value = true,
    Callback = function(v) pcall(function() Window:ToggleTransparency(v) end) end,
})

TabMisc:Section({ Title = "Style" })
TabMisc:Toggle({
    Title = "Rainbow Mode",
    Desc = "Overrides every ESP color",
    Value = false,
    Callback = function(v) ESP.Rainbow = v end,
})
TabMisc:Slider({
    Title = "Rainbow Speed", Step = 1,
    Value = { Min = 1, Max = 20, Default = 2 },
    Callback = function(v) ESP.RainbowSpeed = v end,
})

TabMisc:Section({ Title = "Performance" })
TabMisc:Slider({
    Title = "Update Interval (s)",
    Desc = "0 = every frame. Raise it on low-end devices",
    Step = 0.01,
    Value = { Min = 0, Max = 0.2, Default = 0 },
    Callback = function(v) ESP.Refresh = v end,
})
TabMisc:Button({
    Title = "Rebuild ESP Objects",
    Desc = "Fixes drawings after a big respawn / map change",
    Callback = function()
        for player in pairs(Objects) do removePlayer(player) end
        for _, p in ipairs(Players:GetPlayers()) do addPlayer(p) end
        WindUI:Notify({ Title = "Hawk ESP", Content = "ESP objects rebuilt.", Duration = 3, Icon = "refresh-cw" })
    end,
})

TabMisc:Section({ Title = "Player" })
local WalkSpeedEnabled, WalkSpeedValue = false, 16
local JumpEnabled, JumpValue = false, 50
TabMisc:Toggle({ Title = "Custom WalkSpeed", Value = false, Callback = function(v) WalkSpeedEnabled = v end })
TabMisc:Slider({
    Title = "WalkSpeed", Step = 1,
    Value = { Min = 16, Max = 200, Default = 16 },
    Callback = function(v) WalkSpeedValue = v end,
})
TabMisc:Toggle({ Title = "Custom JumpPower", Value = false, Callback = function(v) JumpEnabled = v end })
TabMisc:Slider({
    Title = "JumpPower", Step = 1,
    Value = { Min = 50, Max = 300, Default = 50 },
    Callback = function(v) JumpValue = v end,
})
TabMisc:Button({
    Title = "Reset Character",
    Callback = function()
        local ch = LocalPlayer.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end,
})
table.insert(extraConns, RunService.Stepped:Connect(function()
    local ch = LocalPlayer.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if WalkSpeedEnabled then hum.WalkSpeed = WalkSpeedValue end
    if JumpEnabled then
        hum.UseJumpPower = true
        hum.JumpPower = JumpValue
    end
end))

--==============================================================
-- SKY / ATMOSPHERE (works in any game)
--==============================================================
do
TabMisc:Section({ Title = "Sky / Atmosphere" })

local Lighting = game:GetService("Lighting")

local SkyOriginal = {
    ClockTime            = Lighting.ClockTime,
    Brightness           = Lighting.Brightness,
    FogEnd               = Lighting.FogEnd,
    FogStart             = Lighting.FogStart,
    FogColor             = Lighting.FogColor,
    Ambient              = Lighting.Ambient,
    OutdoorAmbient       = Lighting.OutdoorAmbient,
    ExposureCompensation = Lighting.ExposureCompensation,
    GlobalShadows        = Lighting.GlobalShadows,
    EnvironmentDiffuseScale  = Lighting.EnvironmentDiffuseScale,
    EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
}

-- original sky/atmosphere/clouds instances, kept aside so we can put them back
local SkyBackup = {}
for _, obj in ipairs(Lighting:GetChildren()) do
    if obj:IsA("Sky") or obj:IsA("Atmosphere") then
        table.insert(SkyBackup, obj)
    end
end
local CloudsBackup
do
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then CloudsBackup = terrain:FindFirstChildOfClass("Clouds") end
end

--------------------------------------------------------------------
-- Desired state + enforcement.
-- Prison Life (and most games) keep re-writing Lighting and re-adding
-- their own Sky, which is why a one-shot change gets reverted. So every
-- change is stored here and re-applied on a loop until you restore.
--------------------------------------------------------------------
local Want = {
    Active   = false,
    Force    = true,
    Lighting = {},
    Sky      = {},
    Atmo     = {},
    UseSky   = false,
    UseAtmo  = false,
}

local HawkSky, HawkAtmo

local function ensureSky()
    if not HawkSky or not HawkSky.Parent then
        HawkSky = Instance.new("Sky")
        HawkSky.Name = "HawkSky"
        HawkSky.Parent = Lighting
    end
    -- the game's own Sky always wins if it stays in Lighting
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") and obj ~= HawkSky then
            pcall(function() obj.Parent = nil end)
        end
    end
    return HawkSky
end

local function ensureAtmo()
    if not HawkAtmo or not HawkAtmo.Parent then
        HawkAtmo = Instance.new("Atmosphere")
        HawkAtmo.Name = "HawkAtmosphere"
        HawkAtmo.Parent = Lighting
    end
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Atmosphere") and obj ~= HawkAtmo then
            pcall(function() obj.Parent = nil end)
        end
    end
    return HawkAtmo
end

local function applyNow()
    for prop, value in pairs(Want.Lighting) do
        pcall(function() Lighting[prop] = value end)
    end
    if Want.UseSky then
        local sky = ensureSky()
        for prop, value in pairs(Want.Sky) do
            pcall(function() sky[prop] = value end)
        end
    end
    if Want.UseAtmo then
        local atmo = ensureAtmo()
        for prop, value in pairs(Want.Atmo) do
            pcall(function() atmo[prop] = value end)
        end
    end
end

local skyLoop
local function startLoop()
    Want.Active = true
    if skyLoop then return end
    skyLoop = task.spawn(function()
        while Want.Active do
            if Want.Force then pcall(applyNow) end
            task.wait(0.2)
        end
        skyLoop = nil
    end)
end

-- instant re-apply when the game injects its own sky/atmosphere back
table.insert(extraConns, Lighting.ChildAdded:Connect(function(obj)
    if not Want.Active or not Want.Force then return end
    if obj:IsA("Sky") and Want.UseSky and obj ~= HawkSky then
        task.defer(function() pcall(applyNow) end)
    elseif obj:IsA("Atmosphere") and Want.UseAtmo and obj ~= HawkAtmo then
        task.defer(function() pcall(applyNow) end)
    end
end))

local function setL(prop, value)
    Want.Lighting[prop] = value
    startLoop()
    pcall(function() Lighting[prop] = value end)
end
local function setSky(props)
    Want.UseSky = true
    for k, v in pairs(props) do Want.Sky[k] = v end
    startLoop()
    applyNow()
end
local function setAtmo(props)
    Want.UseAtmo = true
    for k, v in pairs(props) do Want.Atmo[k] = v end
    startLoop()
    applyNow()
end

local function restoreSky()
    Want.Active = false
    Want.UseSky, Want.UseAtmo = false, false
    Want.Lighting, Want.Sky, Want.Atmo = {}, {}, {}
    if HawkSky then pcall(function() HawkSky:Destroy() end) HawkSky = nil end
    if HawkAtmo then pcall(function() HawkAtmo:Destroy() end) HawkAtmo = nil end
    for _, obj in ipairs(SkyBackup) do
        pcall(function() if obj.Parent ~= Lighting then obj.Parent = Lighting end end)
    end
    if CloudsBackup then
        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        pcall(function() if CloudsBackup.Parent ~= terrain then CloudsBackup.Parent = terrain end end)
    end
    for prop, value in pairs(SkyOriginal) do
        pcall(function() Lighting[prop] = value end)
    end
end

--------------------------------------------------------------------
-- UI
--------------------------------------------------------------------
TabMisc:Toggle({
    Title = "Force Sky (anti-reset)",
    Desc = "Keeps re-applying your sky so the game can't overwrite it. Leave this ON",
    Value = true,
    Callback = function(v)
        Want.Force = v
        if v and Want.Active then applyNow() end
    end,
})

local SkyPresets = {
    ["Clear Blue"]     = "rbxassetid://12064107693",
    ["Sunset"]         = "rbxassetid://12064532555",
    ["Night / Stars"]  = "rbxassetid://12064505864",
    ["Purple Nebula"]  = "rbxassetid://12064646099",
    ["Space"]          = "rbxassetid://12064659510",
    ["Aesthetic Pink"] = "rbxassetid://12064681963",
    ["Storm / Gray"]   = "rbxass