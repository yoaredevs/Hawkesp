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
-- HELPERS
--==============================================================
local function newDrawing(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props or {}) do
        d[k] = v
    end
    d.Visible = false
    return d
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

function ESPObject:hideAll(_hard)
    for _, d in pairs(self.d) do d.Visible = false end
    for _, b in ipairs(self.bones) do b.Visible = false end
    if self.highlight then self.highlight.Enabled = false end
    self.invalidSince = nil
end

-- ANTI-FLICKER: só esconde de verdade se o estado invalido persistir
-- por GraceTime segundos seguidos. Assim respawn/parte faltando/lag
-- de 1 frame (ex: abrir a UI) nao apaga o ESP.
ESPObject.GraceTime = 0.18

function ESPObject:softHide(hard)
    if hard then
        self.invalidSince = nil
        for _, d in pairs(self.d) do d.Visible = false end
        for _, b in ipairs(self.bones) do b.Visible = false end
        if self.highlight then self.highlight.Enabled = false end
        return
    end
    local now = tick()
    if not self.invalidSince then
        self.invalidSince = now
        return
    end
    if now - self.invalidSince >= ESPObject.GraceTime then
        for _, d in pairs(self.d) do d.Visible = false end
        for _, b in ipairs(self.bones) do b.Visible = false end
        if self.highlight then self.highlight.Enabled = false end
    end
end

function ESPObject:markValid()
    self.invalidSince = nil
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
    if not char then return self:softHide() end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not hum or not root or not head or hum.Health <= 0 then return self:softHide() end
    if isFriendly(player) then return self:hideAll(true) end

    local origin = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local dist = origin and (origin.Position - root.Position).Magnitude
                or (Camera.CFrame.Position - root.Position).Magnitude
    if dist > ESP.MaxDistance then return self:softHide() end

    local minv, maxv = getBounds(char)
    if not minv then return self:softHide() end

    self:markValid()

    local visible = (not ESP.VisibleCheck) or canSee(char, head.Position)
    self:updateChams(char, visible)

    local sp, rawOnScreen = w2s(root.Position)
    local vpSize = Camera.ViewportSize
    local margin = 64
    local onScreen = rawOnScreen or (
        sp.Z > 0
        and sp.X > -margin and sp.X < vpSize.X + margin
        and sp.Y > -margin and sp.Y < vpSize.Y + margin
    )

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
    if not bx then return self:softHide() end

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
-- times alvo explicitos (chaves normalizadas). vazio = "qualquer inimigo"
local AimTargetTeams = {}

local TEAM_ALIASES = {
    prisoner = "inmates", prisoners = "inmates", inmate = "inmates",
    inmates  = "inmates", prisioneiro = "inmates", prisioneiros = "inmates",
    criminal = "criminals", criminals = "criminals", criminoso = "criminals",
    guard = "guards", guards = "guards", police = "guards", cop = "guards",
    policia = "guards", neutral = "neutral", neutro = "neutral",
}
local function normTeamName(team)
    local n = team and tostring(team) or "Neutral"
    n = n:lower():gsub("^%s+", ""):gsub("%s+$", "")
    return TEAM_ALIASES[n] or n
end

local function aimTeamOK(player)
    local pT = normTeamName(player.Team)
    -- se o usuario marcou times na lista, ela manda em tudo
    if next(AimTargetTeams) ~= nil then
        return AimTargetTeams[pT] == true
    end
    if not AIM.TeamCheck then return true end
    if player.Team == nil or LocalPlayer.Team == nil then return true end
    return pT ~= normTeamName(LocalPlayer.Team)
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

local AIM_RAY = RaycastParams.new()
AIM_RAY.FilterType = Enum.RaycastFilterType.Exclude
AIM_RAY.IgnoreWater = true

local function canSeeAim(char, targetPos)
    local ignore = { char }
    if LocalPlayer.Character then table.insert(ignore, LocalPlayer.Character) end
    AIM_RAY.FilterDescendantsInstances = ignore
    local origin = Camera.CFrame.Position
    local dir = targetPos - origin
    if dir.Magnitude < 0.05 then return true end
    local ok, hit = pcall(function()
        return Workspace:Raycast(origin, dir, AIM_RAY)
    end)
    if not ok then return true end
    return hit == nil
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
    if AIM.WallCheck and not canSeeAim(char, part.Position) then return false end
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
local lastEspWarn = 0
local AimManaged = false  -- true quando o bloco Aimbot novo controla a selecao de alvo
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
        if not AimManaged then
            if (not AIM.StickyTarget) or (not AimState.Target) or (not select(1, isValidTarget(AimState.Target))) then
                AimState.Target = getTarget()
            end
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
    if ESP.Refresh > 0 then
        if tick() - lastUpdate < ESP.Refresh then return end
        lastUpdate = tick()
    end

    for _, obj in pairs(Objects) do
        local ok, err = pcall(obj.Update, obj)
        if ok then
            obj.failStreak = 0
        else
            -- ANTI-FLICKER: um erro transitorio (frame pesado ao abrir a UI,
            -- respawn, parte trocando de parent) NAO deve apagar o ESP.
            obj.failStreak = (obj.failStreak or 0) + 1
            if obj.failStreak >= 12 then
                pcall(obj.hideAll, obj, true)
            end
            local now = tick()
            if not lastEspWarn or now - lastEspWarn > 3 then
                lastEspWarn = now
                warn("[Hawk] update error:", err)
            end
        end
    end
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

local TabESP  = Window:Tab({ Title = "ESP", Icon = "eye" })
local TabAim  = Window:Tab({ Title = "Aimbot", Icon = "crosshair" })
local TabRage = Window:Tab({ Title = "Rage", Icon = "flame" })
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


do
do

AimManaged = true

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

local VIM, VirtualUser
pcall(function() VIM = game:GetService("VirtualInputManager") end)
pcall(function() VirtualUser = game:GetService("VirtualUser") end)

local IsMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

local AB = {
    AutoLock      = false,   -- trava sozinho, sem segurar nada
    UseKeybind    = false,   -- lock só enquanto a tecla está pressionada
    HoldMode      = true,
    Key           = Enum.KeyCode.E,
    GunOnly       = false,
    ArrestedCheck = true,
    PauseOnUI     = true,
    AutoFire      = false,
    FireMethod    = "Auto",
    FireRate      = 0.12,
    -- times permitidos (multi-seleção). vazio = qualquer um
    Teams         = {},
}

--------------------------------------------------------------
-- helpers Prison Life
--------------------------------------------------------------
local function plEquippedTool()
    local ch = LocalPlayer.Character
    if not ch then return nil end
    for _, t in ipairs(ch:GetChildren()) do
        if t:IsA("Tool") then return t end
    end
    return nil
end

local function plIsArrested(player)
    local ch = player.Character
    if not ch then return false end
    if ch:FindFirstChild("Handcuffs") or ch:FindFirstChild("HandcuffsHolder") then return true end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 and hum.WalkSpeed == 0 and player.Team
       and tostring(player.Team) == "Inmates" then return true end
    return false
end

-- a checagem de time vive em aimTeamOK / AimTargetTeams (fonte unica)
local function teamAllowed(player)
    return aimTeamOK(player)
end

--------------------------------------------------------------
-- filtro em cima do isValidTarget base (que já faz distância,
-- vida, team check e wall check)
--------------------------------------------------------------
local baseIsValid = isValidTarget
isValidTarget = function(player)
    if AB.ArrestedCheck and plIsArrested(player) then return false end
    return baseIsValid(player)
end

--------------------------------------------------------------
-- seleção de alvo ancorada no centro da tela
-- (no touch o Mouse.X/Y não acompanha o dedo e escolhia errado)
--------------------------------------------------------------
local function pickTarget()
    if not IsMobile then return getTarget() end
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local vp = cam.ViewportSize
    local anchor = Vector2.new(vp.X / 2, vp.Y / 2)

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

--------------------------------------------------------------
-- disparo (mouse1press não existe em executor mobile)
--------------------------------------------------------------
local LastFire = 0

local function fireVirtual()
    local cam = Workspace.CurrentCamera
    if not cam then return false end
    local vp = cam.ViewportSize
    local x, y = vp.X / 2, vp.Y / 2
    if VIM then
        local ok = pcall(function()
            VIM:SendMouseButtonEvent(x, y, 0, true,  game, 1)
            task.wait(0.03)
            VIM:SendMouseButtonEvent(x, y, 0, false, game, 1)
        end)
        if ok then return true end
    end
    if VirtualUser then
        local ok = pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:Button1Down(Vector2.new(x, y), cam.CFrame)
            task.wait(0.03)
            VirtualUser:Button1Up(Vector2.new(x, y), cam.CFrame)
        end)
        if ok then return true end
    end
    return false
end

local function firePLRemote(target)
    local tool = plEquippedTool()
    if not tool or not target or not target.Character then return false end
    local head = target.Character:FindFirstChild("Head")
        or target.Character:FindFirstChild("HumanoidRootPart")
    if not head then return false end
    local kl = tool:FindFirstChild("KnifeLocal")
    local beam = kl and kl:FindFirstChild("CreateBeam")
    local remote = beam and beam:FindFirstChild("Remote")
    if not remote then return false end
    local cam = Workspace.CurrentCamera
    local origin = cam and cam.CFrame.Position or head.Position
    return (pcall(function()
        remote:FireServer(1, {{
            Hit       = head,
            Distance  = (origin - head.Position).Magnitude,
            Cframe    = CFrame.new(origin, head.Position),
            RayObject = Ray.new(origin, (head.Position - origin).Unit),
        }}, "AH2")
    end))
end

local function doFire(target)
    if tick() - LastFire < AB.FireRate then return end
    LastFire = tick()
    task.spawn(function()
        if AB.FireMethod == "PL Remote" then firePLRemote(target); return end
        if AB.FireMethod == "VirtualInput" then fireVirtual(); return end
        if mouse1press and mouse1release then
            pcall(mouse1press); task.wait(0.03); pcall(mouse1release); return
        end
        if fireVirtual() then return end
        firePLRemote(target)
    end)
end

--------------------------------------------------------------
-- UI — lock
--------------------------------------------------------------
TabAim:Toggle({
    Title = "Auto Lock",
    Desc = "Trava sozinho no alvo dentro do FOV — sem segurar nada",
    Value = false,
    Callback = function(v)
        AB.AutoLock = v
        if v then
            AIM.Enabled = true
            AimState.Active = true
            AimState.Target = pickTarget()
        else
            AimState.Active = false
            AimState.Toggled = false
            AimState.Target = nil
        end
    end,
})
TabAim:Toggle({
    Title = "Usar Keybind (em vez do Auto Lock)",
    Desc = "Trava só enquanto a tecla está pressionada",
    Value = false,
    Callback = function(v)
        AB.UseKeybind = v
        AimState.Active = false
        AimState.Toggled = false
    end,
})
TabAim:Keybind({
    Title = "Aim Key",
    Value = "E",
    Callback = function(key)
        local kc = Enum.KeyCode[key]
        if kc then AB.Key = kc
        elseif Enum.UserInputType[key] then AB.Key = Enum.UserInputType[key] end
    end,
})
TabAim:Toggle({
    Title = "Keybind = Hold",
    Desc = "On = segurar • Off = liga/desliga",
    Value = true,
    Callback = function(v) AB.HoldMode = v; AimState.Toggled = false end,
})

TabAim:Section({ Title = "Mira" })
TabAim:Dropdown({
    Title = "Target Part",
    Values = { "Head", "UpperTorso", "Torso", "HumanoidRootPart", "Nearest" },
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
    Title = "Smoothness", Step = 0.01,
    Desc = "0 = cravado (snap). Maior = arrasto mais suave/legit",
    Value = { Min = 0, Max = 1, Default = 0 },
    Callback = function(v) AIM.Smoothness = v end,
})
TabAim:Slider({
    Title = "Max Distance", Step = 25,
    Value = { Min = 50, Max = 5000, Default = 1500 },
    Callback = function(v) AIM.MaxDistance = v end,
})
TabAim:Toggle({
    Title = "Sticky Target",
    Desc = "Mantém o mesmo alvo até ele ficar inválido",
    Value = true,
    Callback = function(v) AIM.StickyTarget = v end,
})

TabAim:Section({ Title = "FOV" })
TabAim:Toggle({
    Title = "Use FOV Limit",
    Desc = "Só trava alvos dentro do círculo",
    Value = true,
    Callback = function(v) AIM.UseFOV = v end,
})
TabAim:Slider({
    Title = "FOV Radius", Step = 5,
    Value = { Min = 20, Max = 900, Default = 150 },
    Callback = function(v) AIM.FOVRadius = v end,
})
TabAim:Toggle({
    Title = "Show FOV Circle",
    Value = true,
    Callback = function(v) AIM.ShowFOV = v end,
})
TabAim:Colorpicker({
    Title = "FOV / Line Color",
    Default = AIM.TargetLineColor,
    Callback = function(c) AIM.TargetLineColor = c end,
})

TabAim:Section({ Title = "Filtros" })
TabAim:Toggle({
    Title = "Wall Check",
    Desc = "Ignora quem está atrás de parede",
    Value = true,
    Callback = function(v) AIM.WallCheck = v end,
})
TabAim:Toggle({
    Title = "Team Check",
    Desc = "Ignora jogadores do seu próprio time",
    Value = true,
    Callback = function(v) AIM.TeamCheck = v end,
})
TabAim:Toggle({
    Title = "Alive Only",
    Value = true,
    Callback = function(v) AIM.AliveOnly = v end,
})
TabAim:Toggle({
    Title = "Ignorar Presos / Algemados",
    Value = true,
    Callback = function(v) AB.ArrestedCheck = v end,
})
TabAim:Toggle({
    Title = "Só Com Arma Equipada",
    Desc = "Pausa o lock quando você está de mão vazia",
    Value = false,
    Callback = function(v) AB.GunOnly = v end,
})
TabAim:Toggle({
    Title = "Pausar Com a UI Aberta",
    Value = true,
    Callback = function(v) AB.PauseOnUI = v end,
})

--------------------------------------------------------------
-- Times — MULTI-SELEÇÃO
--------------------------------------------------------------
TabAim:Section({ Title = "Target Teams (multi)" })

local function liveTeamNames()
    local seen, list = {}, {}
    for _, t in ipairs({ "Guards", "Inmates", "Criminals", "Neutral" }) do
        seen[t] = true; table.insert(list, t)
    end
    local ts = game:FindFirstChildOfClass("Teams")
    if ts then
        for _, t in ipairs(ts:GetChildren()) do
            if t:IsA("Team") and not seen[t.Name] then
                seen[t.Name] = true; table.insert(list, t.Name)
            end
        end
    end
    return list
end

local function applyTeams(selection)
    AimTargetTeams = {}
    AB.Teams = AimTargetTeams
    if type(selection) == "table" then
        for k, v in pairs(selection) do
            if v == true then AimTargetTeams[normTeamName(k)] = true
            elseif type(v) == "string" then AimTargetTeams[normTeamName(v)] = true end
        end
    elseif type(selection) == "string" and selection ~= "" then
        AimTargetTeams[normTeamName(selection)] = true
    end
    -- alvo atual pode não pertencer mais aos times marcados
    if AimState.Target and not teamAllowed(AimState.Target) then
        AimState.Target = nil
    end
end

local TeamDropdown = TabAim:Dropdown({
    Title = "Times Alvo",
    Desc = "Marque um ou vários. Nenhum marcado = qualquer time",
    Values = liveTeamNames(),
    Value = {},
    Multi = true,
    AllowNone = true,
    Callback = applyTeams,
})
TabAim:Button({
    Title = "Recarregar Lista de Times",
    Callback = function()
        local names = liveTeamNames()
        pcall(function() TeamDropdown:Refresh(names) end)
        WindUI:Notify({ Title = "Hawk", Content = #names .. " times encontrados.", Duration = 3, Icon = "refresh-cw" })
    end,
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
    local lastDesc
    while task.wait(0.5) do
        local name = AimState.Target and AimState.Target.Name or "None"
        local desc = AIM.Enabled
            and ("Target: " .. name .. "  |  Locked: " .. tostring(AimState.Active))
            or "Aim Assist disabled"
        if desc ~= lastDesc then
            lastDesc = desc
            pcall(function() TargetParagraph:SetDesc(desc) end)
        end
    end
end)

--==============================================================
-- TAB: RAGE
--==============================================================
TabRage:Section({ Title = "Triggerbot" })
TabRage:Toggle({
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
TabRage:Slider({
    Title = "Trigger Delay (s)", Step = 0.01,
    Value = { Min = 0, Max = 1, Default = 0.05 },
    Callback = function(v) AIM.Trigger.Delay = v end,
})
TabRage:Slider({
    Title = "Click Hold (s)", Step = 0.01,
    Value = { Min = 0.01, Max = 0.5, Default = 0.03 },
    Callback = function(v) AIM.Trigger.HoldTime = v end,
})
TabRage:Toggle({ Title = "Trigger Wall Check", Value = true, Callback = function(v) AIM.Trigger.RequireLOS = v end })
TabRage:Toggle({ Title = "Trigger Team Check", Value = true, Callback = function(v) AIM.Trigger.TeamCheck = v end })

TabRage:Section({ Title = "Auto Shoot" })
TabRage:Toggle({
    Title = "Auto Shoot",
    Desc = "Atira sozinho enquanto o aimbot está travado no alvo",
    Value = false,
    Callback = function(v)
        AB.AutoFire = v
        if v and not (VIM or VirtualUser or mouse1press) then
            WindUI:Notify({ Title = "Hawk", Content = "Sem VirtualInputManager nem mouse1press — só o modo PL Remote funciona.", Duration = 5, Icon = "triangle-alert" })
        end
    end,
})
TabRage:Dropdown({
    Title = "Fire Method",
    Values = { "Auto", "VirtualInput", "PL Remote" },
    Value = "Auto",
    Callback = function(v) AB.FireMethod = v end,
})
TabRage:Slider({
    Title = "Fire Rate (s)", Step = 0.01,
    Value = { Min = 0.05, Max = 1, Default = 0.12 },
    Callback = function(v) AB.FireRate = v end,
})

--------------------------------------------------------------
-- keybind
--------------------------------------------------------------
local KeyHeld = false
local function matchesKey(input)
    if typeof(AB.Key) ~= "EnumItem" then return false end
    if AB.Key.EnumType == Enum.UserInputType then
        return input.UserInputType == AB.Key
    end
    return input.KeyCode == AB.Key
end

table.insert(extraConns, UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe or not AB.UseKeybind or not matchesKey(input) then return end
    if AB.HoldMode then KeyHeld = true else KeyHeld = not KeyHeld end
    if KeyHeld then AimState.Target = pickTarget() end
end))
table.insert(extraConns, UserInputService.InputEnded:Connect(function(input)
    if not AB.UseKeybind or not AB.HoldMode or not matchesKey(input) then return end
    KeyHeld = false
end))

--------------------------------------------------------------
-- loop do lock
--------------------------------------------------------------
local function uiOpen()
    if not AB.PauseOnUI then return false end
    local ok, res = pcall(function()
        return Window and Window.UIElements and Window.UIElements.Main
           and Window.UIElements.Main.Visible
    end)
    return ok and res == true
end

table.insert(extraConns, RunService.RenderStepped:Connect(function()
    local want = AB.UseKeybind and KeyHeld or (not AB.UseKeybind and AB.AutoLock)
    if not want then
        if AB.AutoLock or AB.UseKeybind then
            AimState.Active = false
            AimState.Target = nil
        end
        return
    end
    if not AIM.Enabled or uiOpen() then
        AimState.Active = false
        return
    end
    if AB.GunOnly and not plEquippedTool() then
        AimState.Active = false
        AimState.Target = nil
        return
    end

    AimState.Active = true
    local t = AimState.Target
    if (not AIM.StickyTarget) or (not t) or (not t.Parent)
       or (not select(1, isValidTarget(t))) then
        AimState.Target = pickTarget()
    end

    if AB.AutoFire and AimState.Target then
        doFire(AimState.Target)
    end
end))

table.insert(extraConns, LocalPlayer.CharacterAdded:Connect(function()
    AimState.Target = nil
    KeyHeld = false
end))

AIM.ShowFOV    = true
AIM.Smoothness = 0
AIM.FOVRadius  = 150
AIM.WallCheck  = true
AIM.TeamCheck  = true
if IsMobile then AIM.Mode = "Camera" end

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

TabTP:Section({ Title = "Arrest (Guards)" })

--[[ ARREST ALL
     Prison Life usa a RemoteFunction Workspace.Remote.arrest.
     Assinatura: arrest:InvokeServer(<Torso do criminoso>)  (o jogo eh R6).
     So funciona se o LocalPlayer estiver no time Guards e vivo.
     Em alguns servidores privados esse remote esta patcheado/removido. ]]
local Arrest = {
    Running = false,
    Stop = false,
    Interval = 1.2,
    Jitter = 0.35,
    Approach = 0.28,
    Distance = 3,
    MaxPerCycle = 30,
    ReturnHome = true,
    SkipJailed = true,
    Cooldown = {},
}

local function arrestRemote()
    local remotes = Workspace:FindFirstChild("Remote")
    local r = remotes and remotes:FindFirstChild("arrest")
    if r and r:IsA("RemoteFunction") then return r end
    return nil
end

local function teamNamed(name)
    local ts = game:FindFirstChildOfClass("Teams")
    if not ts then return nil end
    for _, t in ipairs(ts:GetChildren()) do
        if tostring(t.Name):lower() == name then return t end
    end
    return nil
end

local function isGuard()
    local t = LocalPlayer.Team
    return t ~= nil and tostring(t.Name):lower():find("guard") ~= nil
end

local function localAlive()
    local ch = LocalPlayer.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    return hum ~= nil and hum.Health > 0
end

-- criminoso valido: vivo, com Torso, e (opcional) sem algemas/nao preso
local function arrestTargets()
    local out = {}
    local crimTeam = teamNamed("criminals")
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Team and crimTeam and p.Team == crimTeam then
            local ch = p.Character
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            local torso = ch and (ch:FindFirstChild("Torso") or ch:FindFirstChild("UpperTorso"))
            if hum and hum.Health > 0 and torso then
                local jailed = false
                if Arrest.SkipJailed and ch then
                    if ch:FindFirstChild("HandCuffs") or ch:FindFirstChild("Handcuffs") then jailed = true end
                    for _, d in ipairs(ch:GetChildren()) do
                        local n = tostring(d.Name):lower()
                        if n:find("cuff") or n == "arrested" then
                            jailed = true
                            break
                        end
                    end
                end
                local cd = Arrest.Cooldown[p]
                if cd and tick() - cd < 6 then jailed = true end
                if not jailed then table.insert(out, p) end
            end
        end
    end
    return out
end

local function doArrest(target)
    local remote = arrestRemote()
    if not remote then return false, "remote missing" end
    local ch = target.Character
    local torso = ch and (ch:FindFirstChild("Torso") or ch:FindFirstChild("UpperTorso"))
    if not torso then return false, "no torso" end
    local ok, err = pcall(function() return remote:InvokeServer(torso) end)
    if ok then Arrest.Cooldown[target] = tick() end
    return ok, err
end

local function arrestLoop()
    if Arrest.Running then return end
    if not isGuard() then
        WindUI:Notify({ Title = "Hawk", Content = "You must be on the Guards team to arrest.", Duration = 4, Icon = "triangle-alert" })
        return
    end
    if not arrestRemote() then
        WindUI:Notify({ Title = "Hawk", Content = "arrest remote not found (patched server?).", Duration = 4, Icon = "triangle-alert" })
        return
    end

    Arrest.Running = true
    Arrest.Stop = false
    task.spawn(function()
        local home = getRoot() and getRoot().CFrame
        local done, fails = 0, 0
        local list = arrestTargets()

        WindUI:Notify({ Title = "Hawk", Content = "Arrest All: " .. #list .. " criminals queued.", Duration = 3, Icon = "play" })

        for _, target in ipairs(list) do
            if Arrest.Stop then break end
            if done >= Arrest.MaxPerCycle then break end
            if not localAlive() then
                WindUI:Notify({ Title = "Hawk", Content = "Stopped: you died.", Duration = 3, Icon = "triangle-alert" })
                break
            end
            if not isGuard() then
                WindUI:Notify({ Title = "Hawk", Content = "Stopped: you are no longer a Guard.", Duration = 3, Icon = "triangle-alert" })
                break
            end

            local ch = target.Character
            local troot = ch and (ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Torso"))
            if troot then
                -- chega perto por tras, espera assentar, depois prende
                pcall(function()
                    local root = getRoot()
                    if root then
                        root.CFrame = CFrame.new(
                            troot.Position - troot.CFrame.LookVector * Arrest.Distance + Vector3.new(0, 1, 0),
                            troot.Position
                        )
                    end
                end)
                task.wait(Arrest.Approach)

                local ok = doArrest(target)
                if ok then done = done + 1 else fails = fails + 1 end

                -- intervalo + jitter aleatorio (anti-kick / anti-ban)
                local wait = Arrest.Interval + (math.random() * 2 - 1) * Arrest.Jitter
                if wait < 0.35 then wait = 0.35 end
                local t0 = tick()
                while tick() - t0 < wait do
                    if Arrest.Stop then break end
                    task.wait(0.05)
                end
            end
        end

        if Arrest.ReturnHome and home then
            task.wait(0.15)
            pcall(function()
                local root = getRoot()
                if root then root.CFrame = home end
            end)
        end

        Arrest.Running = false
        WindUI:Notify({
            Title = "Hawk",
            Content = "Arrest All finished. Arrested: " .. done .. (fails > 0 and ("  |  failed: " .. fails) or ""),
            Duration = 4,
            Icon = "check",
        })
    end)
end

TabTP:Button({
    Title = "Arrest All Criminals",
    Desc = "Teleports to every Criminal and arrests them, one by one, with a delay",
    Callback = arrestLoop,
})
TabTP:Button({
    Title = "Stop Arrest All",
    Desc = "Cancels the running arrest cycle",
    Callback = function()
        if not Arrest.Running then
            WindUI:Notify({ Title = "Hawk", Content = "Arrest All is not running.", Duration = 3, Icon = "info" })
            return
        end
        Arrest.Stop = true
        WindUI:Notify({ Title = "Hawk", Content = "Stopping after the current target...", Duration = 3, Icon = "square" })
    end,
})
TabTP:Button({
    Title = "Arrest Nearest Criminal",
    Desc = "Single arrest, no teleport loop",
    Callback = function()
        if not isGuard() then
            WindUI:Notify({ Title = "Hawk", Content = "You must be on the Guards team.", Duration = 4, Icon = "triangle-alert" })
            return
        end
        task.spawn(function()
            local root = getRoot()
            if not root then return end
            local best, bestD
            for _, p in ipairs(arrestTargets()) do
                local ch = p.Character
                local tr = ch and (ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Torso"))
                if tr then
                    local d = (tr.Position - root.Position).Magnitude
                    if not bestD or d < bestD then best, bestD = p, d end
                end
            end
            if not best then
                WindUI:Notify({ Title = "Hawk", Content = "No arrestable criminal found.", Duration = 3, Icon = "info" })
                return
            end
            local ch = best.Character
            local tr = ch and (ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Torso"))
            local home = root.CFrame
            if tr then
                pcall(function()
                    root.CFrame = CFrame.new(tr.Position - tr.CFrame.LookVector * Arrest.Distance + Vector3.new(0, 1, 0), tr.Position)
                end)
                task.wait(Arrest.Approach)
                local ok = doArrest(best)
                task.wait(0.15)
                if Arrest.ReturnHome then
                    pcall(function()
                        local r = getRoot()
                        if r then r.CFrame = home end
                    end)
                end
                WindUI:Notify({
                    Title = "Hawk",
                    Content = ok and ("Arrested " .. best.Name) or ("Failed on " .. best.Name),
                    Duration = 3,
                    Icon = ok and "check" or "triangle-alert",
                })
            end
        end)
    end,
})
TabTP:Slider({
    Title = "Arrest Interval (s)",
    Desc = "Delay between arrests. Lower = faster but riskier (kick / ban)",
    Step = 0.1,
    Value = { Min = 0.4, Max = 6, Default = 1.2 },
    Callback = function(v) Arrest.Interval = v end,
})
TabTP:Slider({
    Title = "Interval Jitter (s)",
    Desc = "Random variation added to the interval so the timing is not robotic",
    Step = 0.05,
    Value = { Min = 0, Max = 1.5, Default = 0.35 },
    Callback = function(v) Arrest.Jitter = v end,
})
TabTP:Slider({
    Title = "Approach Delay (s)",
    Desc = "Time to settle next to the target before firing the arrest",
    Step = 0.02,
    Value = { Min = 0.1, Max = 1, Default = 0.28 },
    Callback = function(v) Arrest.Approach = v end,
})
TabTP:Slider({
    Title = "Arrest Distance (studs)",
    Step = 0.5,
    Value = { Min = 1, Max = 8, Default = 3 },
    Callback = function(v) Arrest.Distance = v end,
})
TabTP:Slider({
    Title = "Max Per Cycle",
    Desc = "Stops after this many arrests in one run",
    Step = 1,
    Value = { Min = 1, Max = 40, Default = 30 },
    Callback = function(v) Arrest.MaxPerCycle = math.floor(v) end,
})
TabTP:Toggle({
    Title = "Skip Already Cuffed",
    Value = true,
    Callback = function(v) Arrest.SkipJailed = v end,
})
TabTP:Toggle({
    Title = "Return To Start",
    Desc = "Teleports back to where you were when the cycle ends",
    Value = true,
    Callback = function(v) Arrest.ReturnHome = v end,
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
local TechOriginal = Lighting.Technology

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
local Applying = false          -- evita recursão no Changed
local LoopGen  = 0              -- corrige o loop que morria e nunca voltava
local SuppressConns = {}        -- vigia os Sky/Atmosphere do jogo

--------------------------------------------------------------
-- Atmosphere só funciona com Technology moderna. Prison Life
-- roda em Legacy/Compatibility, então TODO Atmosphere aplicado
-- era simplesmente ignorado — parecia "o jogo resetando".
--------------------------------------------------------------
local function ensureTechnology()
    if Lighting.Technology == Enum.Technology.Legacy
       or Lighting.Technology == Enum.Technology.Compatibility then
        pcall(function() Lighting.Technology = Enum.Technology.ShadowMap end)
    end
end

--------------------------------------------------------------
-- suprime instâncias do jogo e continua suprimindo se ele
-- tentar reparentar (era o furo do `obj.Parent = nil` único)
--------------------------------------------------------------
local function suppress(obj)
    if SuppressConns[obj] then
        pcall(function() obj.Parent = nil end)
        return
    end
    SuppressConns[obj] = obj.AncestryChanged:Connect(function(_, parent)
        if parent == Lighting and Want.Active and Want.Force then
            task.defer(function() pcall(function() obj.Parent = nil end) end)
        end
    end)
    pcall(function() obj.Parent = nil end)
end

local function unsuppressAll()
    for obj, conn in pairs(SuppressConns) do
        pcall(function() conn:Disconnect() end)
        SuppressConns[obj] = nil
    end
end

local function ensureSky()
    if not HawkSky or not HawkSky.Parent then
        HawkSky = Instance.new("Sky")
        HawkSky.Name = "HawkSky"
        HawkSky.Parent = Lighting
    end
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") and obj ~= HawkSky then suppress(obj) end
    end
    return HawkSky
end

local function ensureAtmo()
    ensureTechnology()
    if not HawkAtmo or not HawkAtmo.Parent then
        HawkAtmo = Instance.new("Atmosphere")
        HawkAtmo.Name = "HawkAtmosphere"
        HawkAtmo.Parent = Lighting
    end
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Atmosphere") and obj ~= HawkAtmo then suppress(obj) end
    end
    return HawkAtmo
end

local function applyNow()
    Applying = true
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
    Applying = false
end

--------------------------------------------------------------
-- enforcement: sinal instantâneo + loop de segurança
--------------------------------------------------------------
local function startLoop()
    Want.Active = true
    LoopGen = LoopGen + 1
    local gen = LoopGen
    task.spawn(function()
        while Want.Active and gen == LoopGen do
            if Want.Force then pcall(applyNow) end
            task.wait(0.2)
        end
    end)
end

-- devolve a propriedade no mesmo frame em que o jogo mexe nela
table.insert(extraConns, Lighting.Changed:Connect(function(prop)
    if Applying or not Want.Active or not Want.Force then return end
    local wanted = Want.Lighting[prop]
    if wanted == nil then return end
    Applying = true
    pcall(function() Lighting[prop] = wanted end)
    Applying = false
end))

-- jogo injetando Sky/Atmosphere de volta, ou apagando os nossos
table.insert(extraConns, Lighting.ChildAdded:Connect(function(obj)
    if not Want.Active or not Want.Force then return end
    if obj:IsA("Sky") and Want.UseSky and obj ~= HawkSky then
        task.defer(function() pcall(applyNow) end)
    elseif obj:IsA("Atmosphere") and Want.UseAtmo and obj ~= HawkAtmo then
        task.defer(function() pcall(applyNow) end)
    end
end))
table.insert(extraConns, Lighting.ChildRemoved:Connect(function(obj)
    if not Want.Active or not Want.Force then return end
    if obj == HawkSky or obj == HawkAtmomosphere"
        HawkAtmo.Parent = Lighting
    end
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Atmosphere") and obj ~= HawkAtmo then suppress(obj) end
    end
    return HawkAtmo
end

local function applyNow()
    Applying = true
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
    Applying = false
end

--------------------------------------------------------------
-- enforcement: sinal instantâneo + loop de segurança
--------------------------------------------------------------
local function startLoop()
    Want.Active = true
    LoopGen = LoopGen + 1
    local gen = LoopGen
    task.spawn(function()
        while Want.Active and gen == LoopGen do
            if Want.Force then pcall(applyNow) end
            task.wait(0.2)
        end
    end)
end

-- devolve a propriedade no mesmo frame em que o jogo mexe nela
table.insert(extraConns, Lighting.Changed:Connect(function(prop)
    if Applying or not Want.Active or not Want.Force then return end
    local wanted = Want.Lighting[prop]
    if wanted == nil then return end
    Applying = true
    pcall(function() Lighting[prop] = wanted end)
    Applying = false
end))

-- jogo injetando Sky/Atmosphere de volta, ou apagando os nossos
table.insert(extraConns, Lighting.ChildAdded:Connect(function(obj)
    if not Want.Active or not Want.Force then return end
    if obj:IsA("Sky") and Want.UseSky and obj ~= HawkSky then
        task.defer(function() pcall(applyNow) end)
    elseif obj:IsA("Atmosphere") and Want.UseAtmo and obj ~= HawkAtmo then
        task.defer(function() pcall(applyNow) end)
    end
end))
table.insert(extraConns, Lighting.ChildRemoved:Connect(function(obj)
    if not Want.Active or not Want.Force then return end
    if obj == HawkSky or obj == HawkAtmo then
        task.defer(function() pcall(applyNow) end)
    end
end))

local function setL(prop, value)
    Want.Lighting[prop] = value
    startLoop()
    Applying = true
    pcall(function() Lighting[prop] = value end)
    Applying = false
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
local function clearAtmo()
    Want.UseAtmo = false
    Want.Atmo = {}
    if HawkAtmo then pcall(function() HawkAtmo:Destroy() end) HawkAtmo = nil end
end

local function restoreSky()
    Want.Active = false
    LoopGen = LoopGen + 1
    Want.UseSky, Want.UseAtmo = false, false
    Want.Lighting, Want.Sky, Want.Atmo = {}, {}, {}
    if HawkSky then pcall(function() HawkSky:Destroy() end) HawkSky = nil end
    if HawkAtmo then pcall(function() HawkAtmo:Destroy() end) HawkAtmo = nil end
    unsuppressAll()
    for _, obj in ipairs(SkyBackup) do
        pcall(function() if obj.Parent ~= Lighting then obj.Parent = Lighting end end)
    end
    if CloudsBackup then
        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        pcall(function() if CloudsBackup.Parent ~= terrain then CloudsBackup.Parent = terrain end end)
    end
    Applying = true
    for prop, value in pairs(SkyOriginal) do
        pcall(function() Lighting[prop] = value end)
    end
    pcall(function() Lighting.Technology = TechOriginal end)
    Applying = false
end

--------------------------------------------------------------
-- UI
--------------------------------------------------------------
TabMisc:Toggle({
    Title = "Force Sky (anti-reset)",
    Desc = "Reaplica na hora em que o jogo tenta sobrescrever. Deixe LIGADO",
    Value = true,
    Callback = function(v)
        Want.Force = v
        if v and Want.Active then startLoop(); applyNow() end
    end,
})
TabMisc:Toggle({
    Title = "Modern Lighting (fix Atmosphere)",
    Desc = "Prison Life usa Legacy, onde Atmosphere não tem efeito nenhum",
    Value = true,
    Callback = function(v)
        if v then ensureTechnology()
        else pcall(function() Lighting.Technology = TechOriginal end) end
    end,
})

local SkyPresets = {
    ["Clear Blue"]     = "rbxassetid://12064107693",
    ["Sunset"]         = "rbxassetid://12064532555",
    ["Night / Stars"]  = "rbxassetid://12064505864",
    ["Purple Nebula"]  = "rbxassetid://12064646099",
    ["Space"]          = "rbxassetid://12064659510",
    ["Aesthetic Pink"] = "rbxassetid://12064681963",
    ["Storm / Gray"]   = "rbxassetid://12064722327",
}
local SkyPresetNames = { "Default (restore)" }
for name in pairs(SkyPresets) do table.insert(SkyPresetNames, name) end
table.sort(SkyPresetNames)

local function facesOf(id)
    return {
        SkyboxUp = id, SkyboxDn = id, SkyboxLf = id,
        SkyboxRt = id, SkyboxFt = id, SkyboxBk = id,
    }
end

TabMisc:Dropdown({
    Title = "Skybox Preset",
    Values = SkyPresetNames,
    Value = "Default (restore)",
    Callback = function(v)
        local id = SkyPresets[v]
        if not id then
            restoreSky()
            WindUI:Notify({ Title = "Hawk", Content = "Sky restaurado.", Duration = 2, Icon = "undo-2" })
            return
        end
        local props = facesOf(id)
        props.StarCount = 3000
        props.CelestialBodiesShown = true
        setSky(props)
        WindUI:Notify({ Title = "Hawk", Content = v .. " aplicado.", Duration = 2, Icon = "cloud-sun" })
    end,
})
TabMisc:Input({
    Title = "Custom Skybox ID",
    Placeholder = "ex: 12064107693",
    Callback = function(txt)
        local id = tostring(txt):match("%d+")
        if not id then
            WindUI:Notify({ Title = "Hawk", Content = "ID inválido.", Duration = 3, Icon = "triangle-alert" })
            return
        end
        setSky(facesOf("rbxassetid://" .. id))
    end,
})
TabMisc:Toggle({
    Title = "Show Sun / Moon",
    Value = true,
    Callback = function(v) setSky({ CelestialBodiesShown = v }) end,
})
TabMisc:Slider({
    Title = "Star Count", Step = 500,
    Value = { Min = 0, Max = 8000, Default = 3000 },
    Callback = function(v) setSky({ StarCount = v }) end,
})

TabMisc:Section({ Title = "Lighting" })
TabMisc:Slider({
    Title = "Time of Day", Step = 0.1,
    Value = { Min = 0, Max = 24, Default = math.floor(Lighting.ClockTime * 10) / 10 },
    Callback = function(v) setL("ClockTime", v) end,
})
TabMisc:Slider({
    Title = "Brightness", Step = 0.1,
    Value = { Min = 0, Max = 10, Default = math.clamp(Lighting.Brightness, 0, 10) },
    Callback = function(v) setL("Brightness", v) end,
})
TabMisc:Slider({
    Title = "Exposure", Step = 0.05,
    Value = { Min = -3, Max = 3, Default = 0 },
    Callback = function(v) setL("ExposureCompensation", v) end,
})
TabMisc:Colorpicker({
    Title = "Ambient Color",
    Default = Lighting.OutdoorAmbient,
    Callback = function(c) setL("Ambient", c); setL("OutdoorAmbient", c) end,
})
TabMisc:Toggle({
    Title = "Fullbright",
    Value = false,
    Callback = function(v)
        if v then
            setL("Brightness", 3)
            setL("ClockTime", 12)
            setL("GlobalShadows", false)
            setL("Ambient", Color3.fromRGB(178, 178, 178))
            setL("OutdoorAmbient", Color3.fromRGB(178, 178, 178))
            setL("EnvironmentDiffuseScale", 1)
            setL("EnvironmentSpecularScale", 1)
        else
            for _, p in ipairs({ "Brightness", "GlobalShadows", "Ambient",
                "OutdoorAmbient", "EnvironmentDiffuseScale", "EnvironmentSpecularScale" }) do
                Want.Lighting[p] = nil
                Applying = true
                pcall(function() Lighting[p] = SkyOriginal[p] end)
                Applying = false
            end
        end
    end,
})

TabMisc:Section({ Title = "Fog / Atmosphere" })
TabMisc:Toggle({
    Title = "No Fog",
    Value = false,
    Callback = function(v)
        if v then
            setL("FogEnd", 1e6)
            setL("FogStart", 1e6)
            setAtmo({ Density = 0, Haze = 0, Glare = 0 })
        else
            Want.Lighting.FogEnd, Want.Lighting.FogStart = nil, nil
            clearAtmo()
            Applying = true
            pcall(function()
                Lighting.FogEnd = SkyOriginal.FogEnd
                Lighting.FogStart = SkyOriginal.FogStart
            end)
            Applying = false
        end
    end,
})
TabMisc:Slider({
    Title = "Fog Distance", Step = 50,
    Value = { Min = 0, Max = 5000, Default = math.clamp(Lighting.FogEnd, 0, 5000) },
    Callback = function(v) setL("FogEnd", v) end,
})
TabMisc:Colorpicker({
    Title = "Fog Color",
    Default = Lighting.FogColor,
    Callback = function(c) setL("FogColor", c) end,
})
TabMisc:Slider({
    Title = "Atmosphere Density", Step = 0.01,
    Value = { Min = 0, Max = 1, Default = 0.3 },
    Callback = function(v) setAtmo({ Density = v }) end,
})
TabMisc:Slider({
    Title = "Atmosphere Haze", Step = 0.1,
    Value = { Min = 0, Max = 10, Default = 0 },
    Callback = function(v) setAtmo({ Haze = v }) end,
})
TabMisc:Slider({
    Title = "Atmosphere Glare", Step = 0.1,
    Value = { Min = 0, Max = 10, Default = 0 },
    Callback = function(v) setAtmo({ Glare = v }) end,
})
TabMisc:Colorpicker({
    Title = "Atmosphere Color",
    Default = Color3.fromRGB(199, 170, 107),
    Callback = function(c) setAtmo({ Color = c }) end,
})
TabMisc:Toggle({
    Title = "Remove Clouds",
    Value = false,
    Callback = function(v)
        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        if not terrain then return end
        if v then
            local c = terrain:FindFirstChildOfClass("Clouds")
            if c then CloudsBackup = c; pcall(function() c.Parent = nil end) end
        elseif CloudsBackup then
            pcall(function() CloudsBackup.Parent = terrain end)
        end
    end,
})

TabMisc:Section({ Title = "Sky Quick Presets" })
local function applyMood(mood)
    if mood == "Midnight" then
        setSky(facesOf(SkyPresets["Night / Stars"]))
        setSky({ StarCount = 5000, CelestialBodiesShown = true })
        setL("ClockTime", 0); setL("Brightness", 1)
        setL("OutdoorAmbient", Color3.fromRGB(40, 45, 70))
        setAtmo({ Density = 0.35, Haze = 1, Color = Color3.fromRGB(60, 70, 120) })
    elseif mood == "Golden Sunset" then
        setSky(facesOf(SkyPresets["Sunset"]))
        setL("ClockTime", 17.5); setL("Brightness", 2.5)
        setL("OutdoorAmbient", Color3.fromRGB(120, 90, 70))
        setAtmo({ Density = 0.4, Haze = 3, Glare = 1, Color = Color3.fromRGB(220, 160, 90) })
    elseif mood == "Deep Space" then
        setSky(facesOf(SkyPresets["Space"]))
        setSky({ CelestialBodiesShown = false, StarCount = 8000 })
        setL("ClockTime", 0); setL("Brightness", 1.5)
        setL("OutdoorAmbient", Color3.fromRGB(30, 30, 45))
        setAtmo({ Density = 0, Haze = 0 })
    elseif mood == "Toxic Green" then
        setL("ClockTime", 6); setL("Brightness", 2)
        setL("FogColor", Color3.fromRGB(60, 120, 60))
        setL("OutdoorAmbient", Color3.fromRGB(80, 140, 80))
        setAtmo({ Density = 0.5, Haze = 5, Color = Color3.fromRGB(90, 200, 90) })
    end
    WindUI:Notify({ Title = "Hawk", Content = mood .. " aplicado.", Duration = 3, Icon = "cloud-sun" })
end
TabMisc:Dropdown({
    Title = "Atmosphere Mood",
    Values = { "Midnight", "Golden Sunset", "Deep Space", "Toxic Green" },
    Value = "Midnight",
    Callback = applyMood,
})
TabMisc:Button({
    Title = "Re-apply Now",
    Callback = function() if Want.Active then startLoop(); applyNow() end end,
})
TabMisc:Button({
    Title = "Restore Original Sky",
    Callback = function()
        restoreSky()
        WindUI:Notify({ Title = "Hawk", Content = "Sky restaurado.", Duration = 3, Icon = "undo-2" })
    end,
})

do
    local _old = unload
    unload = function()
        pcall(restoreSky)
        _old()
    end
end

end -- fim sky/atmosphere

TabMisc:Section({ Title = "Script" })
TabMisc:Paragraph({
    Title = "Keybinds",
    Desc = "RightControl — toggle the UI\nRightShift — toggle ESP on/off\nAim key — set in the Aim Assist tab",
})
TabMisc:Paragraph({
    Title = "Credits",
    Desc = "Hawk ESP + Aim Assist\nDeveloped by yoaredevs",
})
TabMisc:Button({
    Title = "Copy Discord / Credits",
    Callback = function()
        if setclipboard then setclipboard("Hawk ESP + Aim Assist — by yoaredevs") end
        WindUI:Notify({ Title = "Hawk ESP", Content = "Credits copied.", Duration = 3, Icon = "copy" })
    end,
})
TabMisc:Button({
    Title = "Unload Script",
    Desc = "Removes all drawings and closes the UI",
    Callback = function()
        unload()
        pcall(function() Window:Destroy() end)
    end,
})

--==============================================================
-- GLOBAL KEYBINDS
--==============================================================
table.insert(extraConns, UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        ESP.Enabled = not ESP.Enabled
        if not ESP.Enabled then
            for _, obj in pairs(Objects) do obj:hideAll() end
        end
        WindUI:Notify({
            Title = "Hawk ESP",
            Content = ESP.Enabled and "ESP enabled" or "ESP disabled",
            Duration = 2,
            Icon = "eye",
        })
    end
end))

WindUI:Notify({
    Title = "Hawk ESP loaded",
    Content = "by yoaredevs • RightControl = UI • RightShift = ESP",
    Duration = 5,
    Icon = "check" ,
} )