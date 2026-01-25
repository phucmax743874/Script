

repeat task.wait() until game:IsLoaded()

---------------- SERVICES ----------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer

---------------- CONFIG ----------------
local PLAYER_SPEED = 500
local WAVE_ABORT_RADIUS = 20
local MIN_TIMELEFT = 10

-- prompt handling
local PROMPT_WAIT_MAX = 1.2   -- fast but reliable
local HOLD_TIMEOUT   = 3.5    -- max hold time before fail

---------------- STATE ----------------
local State = {
    Tier = "Common",
    SavedPos = nil,
    Busy = false,
    Token = 0,
    Ignored = {}, -- ignore already picked targets (instances)
}

---------------- CHARACTER ----------------
local Character, HRP, Humanoid

local function BindCharacter(c)
    Character = c
    Humanoid = c:WaitForChild("Humanoid")
    HRP = c:WaitForChild("HumanoidRootPart")

    State.Token += 1
    State.Busy = false
end

if lp.Character then BindCharacter(lp.Character) end
lp.CharacterAdded:Connect(BindCharacter)

---------------- NOCLIP ----------------
local function SetNoclip(on)
    if not Character then return end
    for _,v in ipairs(Character:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = not on
        end
    end
end

---------------- WAVES ----------------
local function IsWave(v)
    return v:IsA("BasePart") and v.Name:lower():find("wave")
end

local function WaveTooClose(radius)
    if not HRP then return false end
    for _,v in ipairs(workspace:GetDescendants()) do
        if IsWave(v) then
            if (v.Position - HRP.Position).Magnitude <= radius then
                return true
            end
        end
    end
    return false
end

---------------- FLY (FAST + SNAP) ----------------
local function FlyTo(pos, token)
    if not HRP then return false end

    SetNoclip(true)
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e6,1e6,1e6)
    bv.Parent = HRP

    while (HRP.Position - pos).Magnitude > 3 do
        if State.Token ~= token then
            bv:Destroy()
            SetNoclip(false)
            return false
        end
        local dir = (pos - HRP.Position)
        bv.Velocity = (dir.Magnitude > 0) and (dir.Unit * PLAYER_SPEED) or Vector3.zero
        RunService.RenderStepped:Wait()
    end

    bv:Destroy()
    -- snap super close for prompt
    HRP.CFrame = CFrame.new(pos + Vector3.new(0, 1.5, 0))
    HRP.Velocity = Vector3.zero
    SetNoclip(false)
    return true
end

---------------- BRAINROT ----------------
local function GetBrainrotsByTier(tier)
    local root = workspace:FindFirstChild("ActiveBrainrots")
    local folder = root and root:FindFirstChild(tier)
    if not folder then return {} end

    local t = {}
    for _,br in ipairs(folder:GetChildren()) do
        if br:IsA("Model") and br.Name == "RenderedBrainrot" then
            local tl = br:GetAttribute("TimeLeft") or 0
            if tl >= MIN_TIMELEFT then
                t[#t+1] = br
            end
        end
    end
    return t
end

local function GetPos(br)
    if not br then return nil end
    local p = br.PrimaryPart or br:FindFirstChildWhichIsA("BasePart", true)
    return p and p.Position
end

-- BEST TARGET: prefer highest Value, then nearest (TimeLeft already filtered)
local function GetBestTarget()
    if not HRP then return nil end

    local best, bestScore = nil, -math.huge
    for _,br in ipairs(GetBrainrotsByTier(State.Tier)) do
        if not State.Ignored[br] then
            local pos = GetPos(br)
            if pos then
                local dist = (pos - HRP.Position).Magnitude
                local value = br:GetAttribute("Value") or br:GetAttribute("Money") or br:GetAttribute("Cash") or 0

                -- score: value dominates, distance breaks ties (fast + stable)
                local score = (value * 100000) + (10000 - dist)

                if score > bestScore then
                    bestScore = score
                    best = br
                end
            end
        end
    end
    return best
end

---------------- PROMPT HELPERS ----------------
local function FindPrompt(br)
    if not br then return nil end
    return br:FindFirstChildWhichIsA("ProximityPrompt", true)
end

local function InPromptRange(pp)
    if not pp or not HRP then return false end
    local parent = pp.Parent
    if parent and parent:IsA("BasePart") then
        local dist = (parent.Position - HRP.Position).Magnitude
        local maxDist = pp.MaxActivationDistance or 10
        return dist <= (maxDist + 1.5)
    end

    -- fallback: find any BasePart near prompt
    local part = pp.Parent and pp.Parent:FindFirstChildWhichIsA("BasePart", true)
    if part then
        local dist = (part.Position - HRP.Position).Magnitude
        local maxDist = pp.MaxActivationDistance or 10
        return dist <= (maxDist + 1.5)
    end
    return false
end

---------------- PICK CORE (FAST + RELIABLE) ----------------
local function PickOne()
    if State.Busy or not State.SavedPos or not HRP then return end
    State.Busy = true

    task.spawn(function()
        State.Token += 1
        local token = State.Token

        -- LOCK ONE TARGET
        local target = GetBestTarget()
        if not target then
            State.Busy = false
            return
        end

        local targetPos = GetPos(target)
        if not targetPos then
            State.Busy = false
            return
        end

        -- fly straight to target
        if not FlyTo(targetPos, token) then
            State.Busy = false
            return
        end

        -- find prompt quickly + ensure range
        local pp
        local t0 = tick()
        while tick() - t0 < PROMPT_WAIT_MAX do
            if State.Token ~= token then State.Busy=false return end
            if WaveTooClose(WAVE_ABORT_RADIUS) then break end

            -- keep snapping onto target to guarantee prompt range
            local pNow = GetPos(target)
            if pNow then
                HRP.CFrame = CFrame.new(pNow + Vector3.new(0,1.5,0))
                HRP.Velocity = Vector3.zero
            end

            pp = FindPrompt(target)
            if pp and pp.Enabled ~= false and InPromptRange(pp) then
                break
            end
            task.wait(0.03)
        end

        -- wave too close -> abort + return
        if WaveTooClose(WAVE_ABORT_RADIUS) then
            FlyTo(State.SavedPos, token)
            State.Busy = false
            return
        end

        if not pp then
            -- no prompt -> just return
            FlyTo(State.SavedPos, token)
            State.Busy = false
            return
        end

        -- HOLD ONCE (no spam begin/end)
        pcall(function() pp:InputHoldBegin() end)

        local picked = false
        local holdStart = tick()

        while tick() - holdStart < HOLD_TIMEOUT do
            if State.Token ~= token then break end
            if WaveTooClose(WAVE_ABORT_RADIUS) then break end

            -- ✅ SUCCESS ONLY IF THE TARGET is attached to Character (picked up)
            if Character and target:IsDescendantOf(Character) then
                picked = true
                break
            end

            -- also treat "target disappeared" as success
            if not GetPos(target) or not target.Parent then
                picked = true
                break
            end

            -- keep position tight so hold stays valid
            local pNow = GetPos(target)
            if pNow then
                HRP.CFrame = CFrame.new(pNow + Vector3.new(0,1.5,0))
                HRP.Velocity = Vector3.zero
            end

            task.wait(0.05)
        end

        pcall(function() pp:InputHoldEnd() end)

        -- mark ignored ONLY if picked success
        if picked then
            State.Ignored[target] = true
        end

        -- always return to saved position
        FlyTo(State.SavedPos, token)
        State.Busy = false
    end)
end

--====================================================
-- UI (DRAGGABLE TOGGLE + PANEL)
--====================================================
pcall(function() lp.PlayerGui:FindFirstChild("PHUCMAX_FAST_UI"):Destroy() end)

local gui = Instance.new("ScreenGui", lp.PlayerGui)
gui.Name = "PHUCMAX_FAST_UI"
gui.ResetOnSpawn = false

local function MakeDraggable(frame)
    local dragging = false
    local dragStart, startPos

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local toggle = Instance.new("TextButton", gui)
toggle.Size = UDim2.fromOffset(52,52)
toggle.Position = UDim2.new(0,15,0.5,-26)
toggle.Text = "PM"
toggle.Font = Enum.Font.GothamBlack
toggle.TextSize = 16
toggle.BackgroundColor3 = Color3.fromRGB(25,25,30)
toggle.TextColor3 = Color3.fromRGB(0,255,220)
Instance.new("UICorner", toggle).CornerRadius = UDim.new(1,0)

local panel = Instance.new("Frame", gui)
panel.Size = UDim2.fromOffset(250,190)
panel.Position = UDim2.new(0,80,0.5,-95)
panel.BackgroundColor3 = Color3.fromRGB(18,18,22)
Instance.new("UICorner", panel).CornerRadius = UDim.new(0,14)

MakeDraggable(toggle)
MakeDraggable(panel)

local title = Instance.new("TextLabel", panel)
title.Size = UDim2.new(1,0,0,28)
title.BackgroundTransparency = 1
title.Text = "PHUCMAX | pick up brainrot fast"
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextColor3 = Color3.fromRGB(220,220,220)

local status = Instance.new("TextLabel", panel)
status.Position = UDim2.new(0,0,0,28)
status.Size = UDim2.new(1,0,0,18)
status.BackgroundTransparency = 1
status.Text = "READY"
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextColor3 = Color3.fromRGB(160,160,170)

local saveBtn = Instance.new("TextButton", panel)
saveBtn.Size = UDim2.new(0.9,0,0,32)
saveBtn.Position = UDim2.new(0.05,0,0,52)
saveBtn.Text = "Save Position"
saveBtn.Font = Enum.Font.GothamBold
saveBtn.TextSize = 13
saveBtn.BackgroundColor3 = Color3.fromRGB(80,120,255)
saveBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", saveBtn)

local pickBtn = Instance.new("TextButton", panel)
pickBtn.Size = UDim2.new(0.9,0,0,38)
pickBtn.Position = UDim2.new(0.05,0,0,90)
pickBtn.Text = "Pick 1 Brainrot"
pickBtn.Font = Enum.Font.GothamBlack
pickBtn.TextSize = 14
pickBtn.BackgroundColor3 = Color3.fromRGB(0,200,170)
pickBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", pickBtn)

local tierBtn = Instance.new("TextButton", panel)
tierBtn.Size = UDim2.new(0.9,0,0,28)
tierBtn.Position = UDim2.new(0.05,0,1,-36)
tierBtn.Text = "Tier: Common"
tierBtn.Font = Enum.Font.Gotham
tierBtn.TextSize = 12
tierBtn.BackgroundColor3 = Color3.fromRGB(40,40,50)
tierBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", tierBtn)

local tiers = {"Common","Rare","Legendary","Mythical","Cosmic","Secret","Celestial"}
local ti = 1

toggle.MouseButton1Click:Connect(function()
    panel.Visible = not panel.Visible
end)

saveBtn.MouseButton1Click:Connect(function()
    if HRP then
        State.SavedPos = HRP.Position
        status.Text = "SAVED"
        task.delay(0.6, function()
            if status then status.Text = State.Busy and "BUSY..." or "READY" end
        end)
    end
end)

pickBtn.MouseButton1Click:Connect(function()
    if not State.SavedPos then
        status.Text = "SAVE POSITION FIRST"
        task.delay(0.8, function()
            if status then status.Text = "READY" end
        end)
        return
    end
    if State.Busy then return end
    status.Text = "BUSY..."
    PickOne()
    task.spawn(function()
        while State.Busy do task.wait(0.08) end
        if status then status.Text = "READY" end
    end)
end)

tierBtn.MouseButton1Click:Connect(function()
    ti = ti % #tiers + 1
    State.Tier = tiers[ti]
    tierBtn.Text = "Tier: "..State.Tier
end)