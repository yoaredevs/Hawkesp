--[[
    ██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗    ███████╗███████╗██████╗
    ██║  ██║██╔══██╗██║    ██║██║ ██╔╝    ██╔════╝██╔════╝██╔══██╗
    ███████║███████║██║ █╗ ██║█████╔╝     █████╗  ███████╗██████╔╝
    ██╔══██║██╔══██║██║███╗██║██╔═██╗     ██╔══╝  ╚════██║██╔═══╝
    ██║  ██║██║  ██║╚███╔███╔╝██║  ██╗    ███████╗███████║██║
    ╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝    ╚══════╝╚══════╝╚═╝

    Full ESP Suite (Luau) — Drawing API + WindUI
    Features: 2D/Corner Box, Health Bar + Text, Name, Distance, Tool,
              Tracers, Skeleton, Chams (Highlight), Off-screen Arrows,
              FOV Circle, Team Check, Visibility Check, Rainbow mode.

    Usage: paste into your executor and run. Toggle UI with RightControl.
--]]

--==============================================================
-- SERVICES
--==============================================================
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local Workspace          = game:GetService("Workspace")
local CoreGui            = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

--==============================================================
-- ENV CHECKS
--==============================================================
if not Drawing or not Drawing.new then
    warn("[ESP] Your executor does not support the Drawing API. Aborting.")
    return
end

local gethui = gethui or function() return CoreGui end

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

    local usedBones = {}
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
                    usedBones[slot] = true
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

local FOVCircle = newDrawing("Circle", {
    Thickness = 1, NumSides = 64, Filled = false, Transparency = 1,
    Color = Color3.new(1, 1, 1), ZIndex = 1,
})

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
end

for _, p in ipairs(Players:GetPlayers()) do addPlayer(p) end
Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(removePlayer)

local lastUpdate = 0
local renderConn
renderConn = RunService.RenderStepped:Connect(function()
    Camera = Workspace.CurrentCamera

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

    if ESP.Refresh > 0 then
        if tick() - lastUpdate < ESP.Refresh then return end
        lastUpdate = tick()
    end

    for _, obj in pairs(Objects) do
        local ok, err = pcall(obj.Update, obj)
        if not ok then
            pcall(obj.hideAll, obj)
            warn("[ESP] update error:", err)
        end
    end
end)

local function unload()
    if renderConn then renderConn:Disconnect() end
    for player in pairs(Objects) do removePlayer(player) end
    pcall(function() FOVCircle:Remove() end)
end

local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

if not ok or not WindUI then
    warn("[ESP] Failed to load WindUI, ESP still running. Error:", WindUI)
    ESP.Enabled = true
    return
end

local Window = WindUI:CreateWindow({
    Title = "Hawk ESP",
    Icon = "eye",
    Author = "by Luan",
    Folder = "HawkESP",
    Size = UDim2.fromOffset(600, 470),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 190,
})

Window:EditOpenButton({
    Title = "Hawk ESP",
    Icon = "eye",
    CornerRadius = UDim.new(0, 14),
    Draggable = true,
})

local TabMain = Window:Tab({ Title = "Main", Icon = "eye" })
local TabBox = Window:Tab({ Title = "Box", Icon = "square" })
local TabText = Window:Tab({ Title = "Text", Icon = "type" })
local TabTracer = Window:Tab({ Title = "Tracers", Icon = "move-diagonal" })
local TabChams = Window:Tab({ Title = "Chams", Icon = "person-standing" })
local TabMisc = Window:Tab({ Title = "Misc", Icon = "settings" })
Window:SelectTab(1)

TabMain:Section({ Title = "Core" })
TabMain:Toggle({
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
TabMain:Toggle({
    Title = "Team Check",
    Desc = "Hide players on your team",
    Value = false,
    Callback = function(v) ESP.TeamCheck = v end,
})
TabMain:Toggle({
    Title = "Visibility Check",
    Desc = "Color by line of sight (visible / hidden)",
    Value = false,
    Callback = function(v) ESP.VisibleCheck = v end,
})
TabMain:Slider({
    Title = "Max Distance",
    Step = 25,
    Value = { Min = 50, Max = 5000, Default = 1000 },
    Callback = function(v) ESP.MaxDistance = v end,
})
TabMain:Section({ Title = "Visibility Colors" })
TabMain:Colorpicker({
    Title = "Visible Color",
    Default = ESP.VisibleColor,
    Callback = function(c) ESP.VisibleColor = c end,
})
TabMain:Colorpicker({
    Title = "Hidden Color",
    Default = ESP.HiddenColor,
    Callback = function(c) ESP.HiddenColor = c end,
})
TabMain:Section({ Title = "Performance" })
TabMain:Slider({
    Title = "Update Interval (s)",
    Desc = "0 = every frame. Raise it on low-end devices",
    Step = 0.01,
    Value = { Min = 0, Max = 0.2, Default = 0 },
    Callback = function(v) ESP.Refresh = v end,
})

TabBox:Section({ Title = "Box" })
TabBox:Toggle({ Title = "Enabled", Value = true, Callback = function(v) ESP.Box.Enabled = v end })
TabBox:Dropdown({
    Title = "Style",
    Values = { "Full", "Corner" },
    Value = "Full",
    Callback = function(v) ESP.Box.Style = v end,
})
TabBox:Toggle({ Title = "Outline", Value = true, Callback = function(v) ESP.Box.Outline = v end })
TabBox:Toggle({ Title = "Filled", Value = false, Callback = function(v) ESP.Box.Filled = v end })
TabBox:Slider({
    Title = "Fill Opacity", Step = 0.05,
    Value = { Min = 0, Max = 1, Default = 0.25 },
    Callback = function(v) ESP.Box.FillAlpha = v end,
})
TabBox:Slider({
    Title = "Thickness", Step = 1,
    Value = { Min = 1, Max = 5, Default = 1 },
    Callback = function(v) ESP.Box.Thickness = v end,
})
TabBox:Colorpicker({
    Title = "Box Color", Default = ESP.Box.Color,
    Callback = function(c) ESP.Box.Color = c end,
})
TabBox:Section({ Title = "Health Bar" })
TabBox:Toggle({ Title = "Health Bar", Value = true, Callback = function(v) ESP.Health.Enabled = v end })
TabBox:Toggle({ Title = "Health Text", Value = true, Callback = function(v) ESP.Health.Text = v end })
TabBox:Toggle({ Title = "Gradient (green → red)", Value = true, Callback = function(v) ESP.Health.Gradient = v end })
TabBox:Dropdown({
    Title = "Bar Position",
    Values = { "Left", "Right", "Bottom" },
    Value = "Left",
    Callback = function(v) ESP.Health.Side = v end,
})
TabBox:Colorpicker({
    Title = "Static Bar Color", Default = ESP.Health.Color,
    Callback = function(c) ESP.Health.Color = c end,
})

TabText:Section({ Title = "Name" })
TabText:Toggle({ Title = "Name", Value = true, Callback = function(v) ESP.Name.Enabled = v end })
TabText:Dropdown({
    Title = "Name Type",
    Values = { "Display", "Username", "Both" },
    Value = "Display",
    Callback = function(v) ESP.Name.Display = v end,
})
TabText:Slider({
    Title = "Name Size", Step = 1,
    Value = { Min = 9, Max = 24, Default = 13 },
    Callback = function(v) ESP.Name.Size = v end,
})
TabText:Colorpicker({
    Title = "Name Color", Default = ESP.Name.Color,
    Callback = function(c) ESP.Name.Color = c end,
})
TabText:Section({ Title = "Distance" })
TabText:Toggle({ Title = "Distance", Value = true, Callback = function(v) ESP.Distance.Enabled = v end })
TabText:Slider({
    Title = "Distance Size", Step = 1,
    Value = { Min = 9, Max = 24, Default = 12 },
    Callback = function(v) ESP.Distance.Size = v end,
})
TabText:Colorpicker({
    Title = "Distance Color", Default = ESP.Distance.Color,
    Callback = function(c) ESP.Distance.Color = c end,
})
TabText:Section({ Title = "Tool / Held Item" })
TabText:Toggle({ Title = "Show Tool", Value = false, Callback = function(v) ESP.Tool.Enabled = v end })
TabText:Colorpicker({
    Title = "Tool Color", Default = ESP.Tool.Color,
    Callback = function(c) ESP.Tool.Color = c end,
})

TabTracer:Section({ Title = "Tracer" })
TabTracer:Toggle({ Title = "Enabled", Value = true, Callback = function(v) ESP.Tracer.Enabled = v end })
TabTracer:Dropdown({
    Title = "Origin",
    Values = { "Bottom", "Center", "Top", "Mouse" },
    Value = "Bottom",
    Callback = function(v) ESP.Tracer.Origin = v end,
})
TabTracer:Dropdown({
    Title = "Target",
    Values = { "Bottom", "Center", "Head" },
    Value = "Bottom",
    Callback = function(v) ESP.Tracer.Target = v end,
})
TabTracer:Toggle({ Title = "Outline", Value = true, Callback = function(v) ESP.Tracer.Outline = v end })
TabTracer:Slider({
    Title = "Thickness", Step = 1,
    Value = { Min = 1, Max = 5, Default = 1 },
    Callback = function(v) ESP.Tracer.Thickness = v end,
})
TabTracer:Colorpicker({
    Title = "Tracer Color", Default = ESP.Tracer.Color,
    Callback = function(c) ESP.Tracer.Color = c end,
})
TabTracer:Section({ Title = "Off-screen Arrows" })
TabTracer:Toggle({ Title = "Enabled", Value = false, Callback = function(v) ESP.Arrows.Enabled = v end })
TabTracer:Slider({
    Title = "Radius", Step = 5,
    Value = { Min = 60, Max = 500, Default = 220 },
    Callback = function(v) ESP.Arrows.Radius = v end,
})
TabTracer:Slider({
    Title = "Arrow Size", Step = 1,
    Value = { Min = 8, Max = 40, Default = 18 },
    Callback = function(v) ESP.Arrows.Size = v end,
})
TabTracer:Colorpicker({
    Title = "Arrow Color", Default = ESP.Arrows.Color,
    Callback = function(c) ESP.Arrows.Color = c end,
})

TabChams:Section({ Title = "Chams (Highlight)" })
TabChams:Toggle({
    Title = "Enabled", Value = false,
    Callback = function(v)
        ESP.Chams.Enabled = v
        if not v then
            for _, obj in pairs(Objects) do
                if obj.highlight then obj.highlight.Enabled = false end
            end
        end
    end,
})
TabChams:Dropdown({
    Title = "Depth Mode",
    Values = { "AlwaysOnTop", "Occluded" },
    Value = "AlwaysOnTop",
    Callback = function(v) ESP.Chams.DepthMode = v end,
})
TabChams:Slider({
    Title = "Fill Opacity", Step = 0.05,
    Value = { Min = 0, Max = 1, Default = 0.5 },
    Callback = function(v) ESP.Chams.FillAlpha = v end,
})
TabChams:Colorpicker({
    Title = "Fill Color", Default = ESP.Chams.FillColor,
    Callback = function(c) ESP.Chams.FillColor = c end,
})
TabChams:Colorpicker({
    Title = "Outline Color", Default = ESP.Chams.OutlineColor,
    Callback = function(c) ESP.Chams.OutlineColor = c end,
})
TabChams:Section({ Title = "Skeleton" })
TabChams:Toggle({ Title = "Enabled", Value = false, Callback = function(v) ESP.Skeleton.Enabled = v end })
TabChams:Slider({
    Title = "Thickness", Step = 1,
    Value = { Min = 1, Max = 4, Default = 1 },
    Callback = function(v) ESP.Skeleton.Thickness = v end,
})
TabChams:Colorpicker({
    Title = "Skeleton Color", Default = ESP.Skeleton.Color,
    Callback = function(c) ESP.Skeleton.Color = c end,
})

TabMisc:Section({ Title = "FOV Circle" })
TabMisc:Toggle({ Title = "Enabled", Value = false, Callback = function(v) ESP.FOV.Enabled = v end })
TabMisc:Slider({
    Title = "Radius", Step = 5,
    Value = { Min = 20, Max = 600, Default = 120 },
    Callback = function(v) ESP.FOV.Radius = v end,
})
TabMisc:Toggle({ Title = "Filled", Value = false, Callback = function(v) ESP.FOV.Filled = v end })
TabMisc:Colorpicker({
    Title = "FOV Color", Default = ESP.FOV.Color,
    Callback = function(c) ESP.FOV.Color = c end,
})
TabMisc:Section({ Title = "Style" })
TabMisc:Toggle({
    Title = "Rainbow Mode",
    Desc = "Overrides every color",
    Value = false,
    Callback = function(v) ESP.Rainbow = v end,
})
TabMisc:Slider({
    Title = "Rainbow Speed", Step = 1,
    Value = { Min = 1, Max = 20, Default = 2 },
    Callback = function(v) ESP.RainbowSpeed = v end,
})
TabMisc:Section({ Title = "Script" })
TabMisc:Paragraph({
    Title = "Keybinds",
    Desc = "RightControl — toggle the UI\nRightShift — toggle ESP on/off",
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
TabMisc:Button({
    Title = "Unload Script",
    Desc = "Removes all drawings and closes the UI",
    Callback = function()
        unload()
        pcall(function() Window:Destroy() end)
    end,
})

UserInputService.InputBegan:Connect(function(input, gpe)
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
end)

WindUI:Notify({
    Title = "Hawk ESP loaded",
    Content = "RightControl = UI • RightShift = ESP",
    Duration = 5,
    Icon = "check",
})
