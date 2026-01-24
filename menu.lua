--====================================================
-- KHANHLY X PHUCMAX HUB | FULL FIX FINAL
-- WindUI RELEASE | Stable | No UI Freeze
--====================================================

repeat task.wait() until game:IsLoaded()

--================ LOAD WINDUI =================
local WindUI
local ok, ui = pcall(function()
    return loadstring(game:HttpGet(
        "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua",
        true
    ))()
end)

if not ok or not ui then
    error("Failed to load WindUI")
end
WindUI = ui

--================ SERVICES =================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local lp = Players.LocalPlayer

--================ CHARACTER =================
local char, hrp, hum
local function bindChar(c)
    char = c
    hrp = c:WaitForChild("HumanoidRootPart")
    hum = c:WaitForChild("Humanoid")
end
bindChar(lp.Character or lp.CharacterAdded:Wait())
lp.CharacterAdded:Connect(bindChar)

--================ WINDOW =================
local Window = WindUI:CreateWindow({
    Title = "PHUCMAX PRO",
    Icon = "rbxassetid://138311826892324",
    Author = "by thanhphuc",
    Folder = "phucmaxdepzai",
    Size = UDim2.fromOffset(580, 340),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 150,
    Background = "rbxassetid://120729878046622",
    BackgroundImageTransparency = 0.42,
    HideSearchBar = false,
    ScrollBarEnabled = false,
    User = { Enabled = true, Anonymous = false },
})

Window:EditOpenButton({
    Title = "OPEN PHUCMAX",
    Icon = "rbxassetid://138311826892324",
    CornerRadius = UDim.new(0,40),
    StrokeThickness = 1,
    Color = ColorSequence.new(
        Color3.fromHex("FF0F7B"),
        Color3.fromHex("F89B29")
    ),
    Draggable = true,
})

--================ TABS =================
local InfoTab = Window:Tab({ Title = "Info", Icon = "info" })
local MainTab = Window:Tab({ Title = "Main", Icon = "home" })
local FpsTab  = Window:Tab({ Title = "FPS", Icon = "zap" })

local Info = InfoTab:Section({ Title = "Information" })
local Main = MainTab:Section({ Title = "Main Functions" })
local FPS  = FpsTab:Section({ Title = "FPS Boost" })
--====================================================
-- FLY BUTTON
--====================================================
Info:Button({
    Title = "Copy link sever Discord",
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/PqWjzSVpuw")
        end
        WindUI:Notify({
            Title = "Discord",
            Content = "copied  link Discord!",
            Duration = 3,
            Type = "success"
        })
    end
})

Main:Button({
    Title = "fly to the hole ",
    Callback = function()
        loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/phucmax743874/Script/refs/heads/main/Flyphuc"
        ))()
    end
})

Main:Button({
    Title = "tele home",
    Callback = function()
        loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/phucmax743874/Script/refs/heads/main/Telehonee"
        ))()
    end
})



Main:Button({
    Title = "fly ",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/TurboLite/Script/refs/heads/main/Fly.lua"))()
    end
})


do
    local AF = {
        on = false,
        tier = "Rare",
        speed = 1000,
        homeCF = nil
    }

    --================ UI =================
    Main:Dropdown({
        Title = "Select Object Tier",
        Values = { "Rare", "Legendary", "Mythical", "Cosmic", "Secret", "Celestial" },
        Default = "Rare",
        Callback = function(v)
            AF.tier = v
        end
    })

    Main:Toggle({
        Title = "Auto Farm Object",
        Default = false,
        Callback = function(v)
            AF.on = v
            if v and hrp then
                AF.homeCF = hrp.CFrame
            end
        end
    })

    --================ SAFE SPAWN TRACK =================
    local spawnedAt = {}
    workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("Model") or obj:IsA("BasePart") then
            spawnedAt[obj] = tick()
        end
    end)

    local function safeToCollect(obj)
        local t = spawnedAt[obj]
        return t and (tick() - t > 1.2)
    end

    --================ OBJECT CHECK =================
    local function hasScanUI(obj)
        for _,v in ipairs(obj:GetDescendants()) do
            if v:IsA("TextLabel") then
                local t = v.Text:lower()
                if t:find("quét") or t:find("scan") or t:match("%ds") or t:match("%d+:%d+") then
                    return true
                end
            end
        end
        return false
    end

    local function isFarmObject(obj)
        if not (obj:IsA("Model") or obj:IsA("BasePart")) then return false end
        if not obj.Name:lower():find(AF.tier:lower()) then return false end

        local pp = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
        if not pp or not pp.Enabled then return false end
        if not hasScanUI(obj) then return false end
        if not safeToCollect(obj) then return false end

        return true
    end

    local function getPart(obj)
        if obj:IsA("BasePart") then return obj end
        return obj:FindFirstChildWhichIsA("BasePart", true)
    end

    --================ WAVE CHECK =================
    local function waveNear(radius)
        if not hrp then return false end
        for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                local n = v.Name:lower()
                if (n:find("wave") or n:find("tsunami")) then
                    if (v.Position - hrp.Position).Magnitude <= radius then
                        return true
                    end
                end
            end
        end
        return false
    end

    local function waitWavePass()
        while AF.on and waveNear(15) do task.wait(0.1) end
        task.wait(0.3)
    end

    --================ FLY NOCLIP =================
    local RS = game:GetService("RunService")

    local function flyTo(pos)
        local bv = Instance.new("BodyVelocity", hrp)
        bv.MaxForce = Vector3.new(1e9,1e9,1e9)
        bv.Parent = hrp

        local noclip = RS.Stepped:Connect(function()
            for _,p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = false
                end
            end
        end)

        while AF.on and (hrp.Position - pos).Magnitude > 3 do
            bv.Velocity = (pos - hrp.Position).Unit * AF.speed
            task.wait()
        end

        noclip:Disconnect()
        bv:Destroy()
    end

    local function holdPrompt(pp)
        pp:InputHoldBegin()
        task.wait(pp.HoldDuration + 0.1)
        pp:InputHoldEnd()
    end

    --================ MAIN LOOP =================
    task.spawn(function()
        while true do
            task.wait(0.2)
            if not AF.on or not hrp or not hum or hum.Health <= 0 then continue end

            for _,obj in ipairs(workspace:GetDescendants()) do
                if not AF.on then break end
                if isFarmObject(obj) then
                    local part = getPart(obj)
                    local pp = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if not part or not pp then continue end

                    local checkR = (part.Position - hrp.Position).Magnitude + 15
                    if waveNear(checkR) then
                        if AF.homeCF then hrp.CFrame = AF.homeCF end
                        waitWavePass()
                    end

                    flyTo(part.Position + Vector3.new(0,0,-2))
                    holdPrompt(pp)

                    task.wait(0.4) -- anti crash
                    if waveNear(15) then
                        if AF.homeCF then hrp.CFrame = AF.homeCF end
                        waitWavePass()
                    end
                end
            end
        end
    end)
end



--====================================================
-- CAMERA ZOOM / FOV (SIÊU XA - SIÊU RỘNG)
--====================================================
do
    local cam = workspace.CurrentCamera
    local zoomEnabled = false

    local DEFAULT_FOV = cam.FieldOfView
    local DEFAULT_MIN = lp.CameraMinZoomDistance
    local DEFAULT_MAX = lp.CameraMaxZoomDistance

    local selectedFOV = 70

    -- list FOV (nhỏ -> to)
    -- nhỏ = zoom gần | lớn = góc rộng nhìn xa
    local fovList = {
        "10","20","30","40","50","70",
        "90","120","150","180","220","260"
    }

    Main:Dropdown({
        Title = "Camera Zoom / FOV",
        Values = fovList,
        Default = "70",
        Callback = function(v)
            selectedFOV = tonumber(v)
            if zoomEnabled and cam then
                cam.FieldOfView = selectedFOV
            end
        end
    })

    Main:Toggle({
        Title = "Camera Zoom (Ultra)",
        Default = false,
        Callback = function(v)
            zoomEnabled = v
            if v then
                -- mở khóa zoom tuyệt đối
                lp.CameraMinZoomDistance = 0.1
                lp.CameraMaxZoomDistance = 1e6

                cam.FieldOfView = selectedFOV
            else
                -- khôi phục
                cam.FieldOfView = DEFAULT_FOV
                lp.CameraMinZoomDistance = DEFAULT_MIN
                lp.CameraMaxZoomDistance = DEFAULT_MAX
            end
        end
    })

    -- đảm bảo không reset khi chết
    lp.CharacterAdded:Connect(function()
        task.wait(0.3)
        if zoomEnabled and cam then
            lp.CameraMinZoomDistance = 0.1
            lp.CameraMaxZoomDistance = 1e6
            cam.FieldOfView = selectedFOV
        end
    end)
end


--====================================================
-- AUTO UPGRADE SPEED
--====================================================
do
    local on = false
    local mode = 1
    local remote = ReplicatedStorage.RemoteFunctions.UpgradeSpeed

    Main:Toggle({
        Title = "Auto Upgrade Speed",
        Default = false,
        Callback = function(v)
            on = v
            if not on then return end

            task.spawn(function()
                while on do
                    pcall(function()
                        remote:InvokeServer(mode)
                    end)
                    task.wait(0.3)
                end
            end)
        end
    })

    Main:Dropdown({
        Title = "Speed Upgrade Mode",
        Values = { "1", "10" },
        Default = "1",
        Callback = function(v)
            mode = tonumber(v)
        end
    })
end

--====================================================
-- SHIFT LOCK (FIXED)
--====================================================
do
    local on = false
    local conn

    Main:Toggle({
        Title = "Shift Lock",
        Default = false,
        Callback = function(v)
            on = v
            if on then
                hum.AutoRotate = false
                hum.CameraOffset = Vector3.new(1.5,0,0)

                if conn then conn:Disconnect() end
                conn = RunService.RenderStepped:Connect(function()
                    if not on or hum.Health <= 0 then return end
                    local cam = workspace.CurrentCamera
                    if not cam then return end
                    local lv = cam.CFrame.LookVector
                    local f = Vector3.new(lv.X,0,lv.Z)
                    if f.Magnitude > 0 then
                        f = f.Unit
                        hrp.CFrame = CFrame.new(hrp.Position)
                            * CFrame.Angles(0, math.atan2(-f.X,-f.Z), 0)
                    end
                end)
            else
                if conn then conn:Disconnect() conn = nil end
                hum.AutoRotate = true
                hum.CameraOffset = Vector3.zero
            end
        end
    })
end

--====================================================
-- AUTO REBIRTH
--====================================================
do
    local on = false
    local remote = ReplicatedStorage.RemoteFunctions.Rebirth

    Main:Toggle({
        Title = "Auto Rebirth",
        Default = false,
        Callback = function(v)
            on = v
            if not on then return end

            task.spawn(function()
                while on do
                    pcall(function()
                        remote:InvokeServer()
                    end)
                    task.wait(0.6)
                end
            end)
        end
    })
end

--====================================================
-- AUTO SPIN (0.4s)
--====================================================
do
    local on = false
    local remote = ReplicatedStorage:WaitForChild("Packages")
        :WaitForChild("Net")
        :WaitForChild("RF/WheelSpin.Roll")

    Main:Toggle({
        Title = "Auto Spin",
        Default = false,
        Callback = function(v)
            on = v
            if not on then return end
            task.spawn(function()
                while on do
                    pcall(function()
                        remote:InvokeServer()
                    end)
                    task.wait(0.1)
                end
            end)
        end
    })
end

--====================================================
-- AUTO COIN ULTRA v5 (GLOBAL RANGE + INVISIBLE)
--====================================================
do
    local on = false

    local GLOBAL_RANGE = 999999999      -- 🔥 diện rộng toàn map
    local SNAP_OFFSET  = 50             -- kéo nhanh về gần người
    local FOOT_OFFSET  = -3             -- vị trí chân để ăn xu
    local HITBOX_SCALE = 12              -- hitbox cực lớn
    local INVISIBLE    = true            -- tàng hình xu (client)

    local spawnConn

    local function isCoin(v)
        if not v:IsA("BasePart") then return false end
        local n = v.Name:lower()
        return n:find("coin") or n:find("cash") or n:find("gold")
    end

    -- kéo xu về người theo 2 tầng (xa -> gần -> ăn)
    local function pullCoin(obj)
        if not on or not hrp or not hum or hum.Health <= 0 then return end

        pcall(function()
            obj.CanCollide = false
            obj.CastShadow = false

            if INVISIBLE then
                obj.LocalTransparencyModifier = 1
            end

            -- phóng to hitbox
            local originalSize = obj.Size
            obj.Size = originalSize * HITBOX_SCALE

            -- ===== TẦNG 1: SNAP SIÊU XA (dịch thẳng về gần người) =====
            obj.CFrame = hrp.CFrame * CFrame.new(0, SNAP_OFFSET, 0)

            -- ===== TẦNG 2: THẢ CHÂN ĐỂ TRIGGER TOUCH =====
            task.delay(0.01, function()
                if obj and obj.Parent then
                    obj.CFrame = hrp.CFrame * CFrame.new(0, FOOT_OFFSET, 0)
                end
            end)

            -- trả size (phòng trường hợp xu chưa bị server xóa ngay)
            task.delay(0.08, function()
                if obj and obj.Parent then
                    obj.Size = originalSize
                end
            end)
        end)
    end

    Main:Toggle({
        Title = "Auto Farm Coin ",
        Default = false,
        Callback = function(v)
            on = v

            if on then
                -- 🔥 quét TOÀN MAP, không giới hạn
                task.spawn(function()
                    while on and hrp and hum and hum.Health > 0 do
                        for _,obj in ipairs(workspace:GetDescendants()) do
                            if not on then break end
                            if isCoin(obj) then
                                pullCoin(obj)
                            end
                        end
                        task.wait(0.15)
                    end
                end)

                -- 🔥 xu spawn ra là hút NGAY
                if spawnConn then spawnConn:Disconnect() end
                spawnConn = workspace.DescendantAdded:Connect(function(obj)
                    if on and isCoin(obj) then
                        pullCoin(obj)
                    end
                end)
            else
                if spawnConn then
                    spawnConn:Disconnect()
                    spawnConn = nil
                end
            end
        end
    })
end

--====================================================
-- FIX LAG ULTRA MEGA | LEVEL 1 -> 6 (CUMULATIVE)
-- POWER x100 | NO INVISIBLE | NO GAME BREAK
--====================================================
do
    local Players = game:GetService("Players")
    local Lighting = game:GetService("Lighting")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    local Terrain = Workspace:FindFirstChildOfClass("Terrain")
    local lp = Players.LocalPlayer

    --------------------------------------------------
    -- UTILS
    --------------------------------------------------
    local function forAllDescendants(fn)
        for _,v in ipairs(Workspace:GetDescendants()) do
            pcall(fn, v)
        end
    end

    local function isCharacterPart(v)
        local m = v
        while m do
            if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") then
                return true
            end
            m = m.Parent
        end
        return false
    end

    --------------------------------------------------
    -- LEVEL 1 : LIGHTING + BASIC MATERIAL
    --------------------------------------------------
    local function Level1()
        -- Lighting core
        Lighting.GlobalShadows = false
        Lighting.FogStart = 1e9
        Lighting.FogEnd   = 1e9
        Lighting.ClockTime = 12
        Lighting.Brightness = 1.1
        Lighting.OutdoorAmbient = Color3.new(1,1,1)

        -- Remove post effects
        for _,v in ipairs(Lighting:GetChildren()) do
            if v:IsA("BloomEffect")
            or v:IsA("ColorCorrectionEffect")
            or v:IsA("SunRaysEffect")
            or v:IsA("DepthOfFieldEffect") then
                v.Enabled = false
            end
        end

        -- Terrain water base
        if Terrain then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
        end

        -- BasePart basic optimize
        forAllDescendants(function(v)
            if v:IsA("BasePart") then
                v.CastShadow = false
                v.Reflectance = 0
                v.Material = Enum.Material.SmoothPlastic
            end
        end)
    end

    --------------------------------------------------
    -- LEVEL 2 : EFFECTS / PARTICLE / TRAIL
    --------------------------------------------------
    local function Level2()
        forAllDescendants(function(v)
            if v:IsA("ParticleEmitter") then
                v.Enabled = false
                v.Rate = 0
            elseif v:IsA("Trail") or v:IsA("Beam") then
                v.Enabled = false
            elseif v:IsA("Fire") or v:IsA("Smoke") then
                v.Enabled = false
            end
        end)
    end

    --------------------------------------------------
    -- LEVEL 3 : COLOR / WATER / EXPLOSION
    --------------------------------------------------
    local function Level3()
        if Terrain then
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 0.5
        end

        forAllDescendants(function(v)
            if v:IsA("BasePart") then
                local c = v.Color
                local g = (c.R + c.G + c.B) / 3
                v.Color = Color3.new(
                    g*0.7 + c.R*0.3,
                    g*0.7 + c.G*0.3,
                    g*0.7 + c.B*0.3
                )
            elseif v:IsA("Explosion") then
                v.BlastPressure = 1
                v.BlastRadius = 1
            end
        end)
    end

    --------------------------------------------------
    -- LEVEL 4 : DECAL / TEXTURE / LIGHT
    --------------------------------------------------
    local function Level4()
        forAllDescendants(function(v)
            if v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = math.clamp(v.Transparency + 0.5, 0, 0.9)
            elseif v:IsA("PointLight")
            or v:IsA("SpotLight")
            or v:IsA("SurfaceLight") then
                v.Enabled = false
            end
        end)
    end

    --------------------------------------------------
    -- LEVEL 5 : MODEL / TREE / MAP DETAIL
    --------------------------------------------------
    local function Level5()
        forAllDescendants(function(v)
            if v:IsA("Model") and not isCharacterPart(v) then
                local name = v.Name:lower()
                if name:find("tree")
                or name:find("leaf")
                or name:find("bush")
                or name:find("plant")
                or name:find("foliage")
                or name:find("grass") then
                    v:Destroy()
                end
            elseif v:IsA("BasePart") then
                v.Material = Enum.Material.Plastic
            end
        end)

        Lighting.Brightness = 1
    end

    --------------------------------------------------
    -- LEVEL 6 : REALTIME ANTI-LAG (CỰC ĐẠI)
    --------------------------------------------------
    local realtimeConn
    local function Level6()
        if Terrain then
            Terrain.WaterTransparency = 0.85
        end

        -- optimize existing mạnh hơn nữa
        forAllDescendants(function(v)
            if v:IsA("BasePart") then
                v.CastShadow = false
                v.Reflectance = 0
            elseif v:IsA("ParticleEmitter") then
                v.Enabled = false
                v.Rate = 0
            end
        end)

        -- realtime optimize object spawn
        if realtimeConn then realtimeConn:Disconnect() end
        realtimeConn = Workspace.DescendantAdded:Connect(function(v)
            task.wait()
            pcall(function()
                if v:IsA("BasePart") then
                    v.CastShadow = false
                    v.Material = Enum.Material.Plastic
                    v.Reflectance = 0
                elseif v:IsA("ParticleEmitter")
                or v:IsA("Trail")
                or v:IsA("Beam") then
                    v.Enabled = false
                elseif v:IsA("Decal") or v:IsA("Texture") then
                    v.Transparency = 0.9
                end
            end)
        end)
    end

    --------------------------------------------------
    -- APPLY (CUMULATIVE)
    --------------------------------------------------
    local function ApplyFix(level)
        if level >= 1 then Level1() end
        if level >= 2 then Level2() end
        if level >= 3 then Level3() end
        if level >= 4 then Level4() end
        if level >= 5 then Level5() end
        if level >= 6 then Level6() end
    end

    --------------------------------------------------
    -- UI BUTTONS
    --------------------------------------------------
    for i = 1, 6 do
        FPS:Button({
            Title = "Fix Lag "..i,
            Callback = function()
                ApplyFix(i)
                WindUI:Notify({
                    Title = "Fix Lag ULTRA",
                    Content = "fix lag on "..i.." ✓",
                    Duration = 3,
                    Type = "success"
                })
            end
        })
    end
end