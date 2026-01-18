--này là auto bật pvp nè 
local ToggleEnablePvp = Tabs.Player:AddToggle("ToggleEnablePvp", {Title="Enable PVP", Description="",Default=false })
ToggleEnablePvp:OnChanged(function(Value)
  _G.EnabledPvP=Value
end)
Options.ToggleEnablePvp:SetValue(false)
spawn(function()
  pcall(function()
      while wait() do
          if _G.EnabledPvP then
              if game:GetService("Players").LocalPlayer.PlayerGui.Main.PvpDisabled.Visible==true then
                  game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("EnablePvp")
              end
          end
      end
  end)
end)


--này là auto bật Haki Quang sát nè 
local KenModule = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local commE = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommE")
local KenEnabled = false
local autoKenRunning = false
local player = Players.LocalPlayer
local function HasTag(tagName)
    local char = player.Character
    if not char then return false end   
    local CollectionService = game:GetService("CollectionService")
    return CollectionService:HasTag(char, tagName)
end
local function StartKenLoop()
    if autoKenRunning then return end
    autoKenRunning = true  
    task.spawn(function()
        while KenEnabled do
            task.wait(0.1) 
            if HasTag("Ken") then
                local playerGui = player:FindFirstChild("PlayerGui")
                if playerGui then
                    local kenButton = playerGui:FindFirstChild("MobileContextButtons")
                        and playerGui.MobileContextButtons:FindFirstChild("ContextButtonFrame")
                        and playerGui.MobileContextButtons.ContextButtonFrame:FindFirstChild("BoundActionKen")                   
                    if kenButton and kenButton:GetAttribute("Selected") ~= true then
                        kenButton:SetAttribute("Selected", true)
                    end
                end              
                local success, observationManager = pcall(function()
                    return getrenv()._G.OM
                end)               
                if success and observationManager and not observationManager.active then
                    observationManager.radius = 0
                    if type(observationManager.setActive) == "function" then
                        observationManager:setActive(true)
                    end
                end
                pcall(function()
                    commE:FireServer("Ken", true)
                end)
            end
        end
        autoKenRunning = false
    end)   
    print("[Ken] Đã bật Auto Ken")
end
local function StopKenLoop()
    KenEnabled = false
    while autoKenRunning do
        task.wait(0.1)
    end   
    print("[Ken] Đã tắt Auto Ken")
end
function KenModule:SetState(state)
    if state == KenEnabled then return end  
    KenEnabled = state
    if state then
        StartKenLoop()
    else
        StopKenLoop()
    end
end
function KenModule:IsEnabled()
    return KenEnabled
end
function KenModule:GetRunningState()
    return autoKenRunning
end
player.CharacterAdded:Connect(function()
    if KenEnabled and not autoKenRunning then
        task.wait(1)
        StartKenLoop()
    end
end)
ReplicatedStorage.DescendantAdded:Connect(function(descendant)
    if descendant.Name == "CommE" and KenEnabled then
        StopKenLoop()
        task.wait(1)
        StartKenLoop()
    end
end)

return KenModule

--này là aimbot nè 

local SilentAimModule = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Character = player.Character or player.CharacterAdded:Wait()
local UserInputService = game:GetService("UserInputService")  
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera
local RS = game:GetService("ReplicatedStorage")
local commE = RS:WaitForChild("Remotes"):WaitForChild("CommE")
local MouseModule = RS:FindFirstChild("Mouse")

local Services = setmetatable({}, {
    __index = function(self, serviceName)
        local good, service = pcall(game.GetService, game, serviceName);
        if (good) then
            self[serviceName] = service
            return service;
        end
    end
});

-- Biến trạng thái CHÍNH
local SilentAimPlayersEnabled = false
local UserWantsplayerAim = false
local PredictionEnabled = false
local HighlightEnabled = false 
local AutoKen = false
local ZSkillorM1 = false
local autoKenRunning = false

local renderConnection = nil
local currentTool = nil
local playersaimbot = nil
local PlayersPosition = nil
local currentHighlight = nil
local Selectedplayer = nil
local MiniPlayerState = nil
local MiniPlayerCreated = false
local MiniPlayerGui = nil

local characterConnections = {}
local Skills = {"X"}
local Booms = {"TAP"}

local PredictionAmount = 0.1
local maxRange = 1000

-- ================= VSkillModule Integration =================
local lastTool = nil
local sharkZActive, vActive, cursedZActive = false, false, false
local dmgConn = nil
local rightTouchActive = false

local function clearVSkillConnections()
	if dmgConn then
		pcall(function() dmgConn:Disconnect() end)
		dmgConn = nil
	end
end

local function DisableSilentAimbot()
    SilentAimPlayersEnabled = false
end

local function EnableSilentAimbot()
    SilentAimPlayersEnabled = UserWantsplayerAim
end

local function hookTool(tool)
    currentTool = tool
    lastTool = tool.Name
    table.insert(characterConnections, tool.AncestryChanged:Connect(function(_, parent)
        if not parent then
            currentTool = nil
            lastTool = nil
            sharkZActive, vActive, cursedZActive = false, false, false
            rightTouchActive = false
            EnableSilentAimbot()
        end
    end))
end

local function isValidStopCondition()
    return (currentTool and currentTool.Name == "Shark Anchor" and sharkZActive)
        or (lastTool == "Dough-Dough" and vActive)
        or (currentTool and currentTool.Name == "Cursed Dual Katana" and cursedZActive)
end

-- Touch Control (Mobile)
UserInputService.TouchStarted:Connect(function(touch)
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    if touch.Position.X > camera.ViewportSize.X / 2 then
        rightTouchActive = true

        if isValidStopCondition() then
            DisableSilentAimbot()
        end
    end
end)

UserInputService.TouchEnded:Connect(function(touch)
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    if touch.Position.X > camera.ViewportSize.X / 2 then
        rightTouchActive = false

        EnableSilentAimbot()
        sharkZActive, vActive, cursedZActive = false, false, false
    end
end)

-- Damage Counter Watch
local function watchDamageCounter()
	clearVSkillConnections()

	task.spawn(function()
		while true do
			local gui = player:FindFirstChild("PlayerGui")
			if not gui then
				task.wait(1)
				continue
			end

			gui = gui:FindFirstChild("Main")
			if not gui then
				task.wait(1)
				continue
			end

			local dmgCounter = gui:FindFirstChild("DmgCounter")
			if not dmgCounter then
				task.wait(1)
				continue
			end

			local dmgTextLabel = dmgCounter:FindFirstChild("Text")
			if not dmgTextLabel then
				task.wait(1)
				continue
			end

			dmgConn = dmgTextLabel:GetPropertyChangedSignal("Text"):Connect(function()
				local dmgText = tonumber(dmgTextLabel.Text) or 0
				if dmgText > 0 and isValidStopCondition() and rightTouchActive then
					DisableSilentAimbot()
				elseif not rightTouchActive then
					EnableSilentAimbot()
				end
			end)
			table.insert(characterConnections, dmgConn)			
			break
		end
	end)
end

-- Skill Detection
if not getgenv().VSkillHooked then
    getgenv().VSkillHooked = true
    local old
	old = hookmetamethod(game, "__namecall", function(self, ...)
	    local method = getnamecallmethod()
	    local args = {...}
    
	    if (method == "InvokeServer" or method == "FireServer") then
	        local a1 = args[1]

	        if typeof(a1) == "string" and a1:upper() == "Z" then
	            if currentTool and currentTool.Name == "Shark Anchor" then
	                sharkZActive = true
	            end
	        end
        
	        if typeof(a1) == "string" and a1:upper() == "V" then
	            if lastTool == "Dough-Dough" then
	                vActive = true
	            end
	        end
        
	        if typeof(a1) == "string" and a1:upper() == "Z" then
	            if currentTool and currentTool.Name == "Cursed Dual Katana" then
	                cursedZActive = true
	            end
			end
	    end
	    return old(self, ...)
	end)
end
-- ================= END VSkillModule =================

-- Lấy HumanoidRootPart
local function getHRP(model)
	if not model or not model:FindFirstChild("HumanoidRootPart") then return nil end
	return model.HumanoidRootPart
end

-- Xóa connections cũ
local function clearConnections()
	for _, conn in ipairs(characterConnections) do
		pcall(function() conn:Disconnect() end)
	end
	characterConnections = {}
	clearVSkillConnections()
end

-- Tính toán vị trí dự đoán
local function getPredictedPosition(hrp)
	if not hrp then return nil end

	local humanoid = hrp.Parent:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return hrp.Position
	end

	if not PredictionEnabled or humanoid.WalkSpeed < 5 then
		return hrp.Position
	end

	return hrp.Position + (hrp.Velocity * PredictionAmount)
end

-- Kiểm tra đồng đội
local function isAllyWithMe(targetplayer)
	local myGui = player:FindFirstChild("PlayerGui")
	if not myGui then return false end

	local scrolling = myGui:FindFirstChild("Main")
		and myGui.Main:FindFirstChild("Allies")
		and myGui.Main.Allies:FindFirstChild("Container")
		and myGui.Main.Allies.Container.Allies:FindFirstChild("ScrollingFrame")

	if scrolling then
		for _, frame in pairs(scrolling:GetDescendants()) do
			if frame:IsA("ImageButton") and frame.Name == targetplayer.Name then
				return true
			end
		end
	end

	return false
end

-- Kiểm tra kẻ thù
local function isEnemy(targetplayer)
	if not targetplayer or targetplayer == player then
		return false
	end

	local myTeam = player.Team
	local targetTeam = targetplayer.Team

	if myTeam and targetTeam then
		if myTeam.Name == "Pirates" and targetTeam.Name == "Marines" then
			return true
		elseif myTeam.Name == "Marines" and targetTeam.Name == "Pirates" then
			return true
		end

		if myTeam.Name == "Pirates" and targetTeam.Name == "Pirates" then
			if isAllyWithMe(targetplayer) then
				return false -- ally, not enemy
			end
			return true
		end

		if myTeam.Name == "Marines" and targetTeam.Name == "Marines" then
			return false
		end
	end

	return true
end

-- Tìm player gần nhất
local function getClosestplayer(lpHRP)
	if not lpHRP then return nil end
	
	local closest = nil
	local closestDist = math.huge
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl ~= player and isEnemy(pl) and pl.Character and pl.Character.Parent ~= nil then
			local hum = pl.Character:FindFirstChildWhichIsA("Humanoid")
			local hrp = getHRP(pl.Character)
			if hum and hum.Health > 0 and hrp then
				local dist = (hrp.Position - lpHRP.Position).Magnitude
				if dist <= maxRange and dist < closestDist then
					closestDist = dist
					closest = pl
				end
			end
		end
	end
	return closest
end

-- Kiểm tra skill ready
local function isSkillReadyForTool(toolName)
    if not toolName then return false end
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    local skillsFolder = playerGui:FindFirstChild("Main") and playerGui.Main:FindFirstChild("Skills")
    if not skillsFolder then return false end
    local toolFrame = skillsFolder:FindFirstChild(toolName)
    if not toolFrame then return false end

    for _, skillKey in ipairs({"Z","X","C","V"}) do
        local skill = toolFrame:FindFirstChild(skillKey)
        if skill and skill:FindFirstChild("Cooldown") and skill.Cooldown:IsA("Frame") then
            local cooldownSize = skill.Cooldown.Size.X.Scale
            if cooldownSize == 1.0 then
                return true
            end
        end
    end
    return false
end

local function isNotDoughValidCondition()
    return (currentTool and currentTool.Name == "Dough-Dough")
end

local function isNotValidCondition()
    return (currentTool and currentTool.Name == "Lightning-Lightning")
    or (currentTool and currentTool.Name == "Portal-Portal")
end

-- Main render loop cho aimbot player
local function startRenderLoop()
    if renderConnection then return end

    renderConnection = RunService.RenderStepped:Connect(function()
        local lpChar = player.Character
        if not lpChar then return end
        local lpHRP = lpChar:FindFirstChild("HumanoidRootPart")
        if not lpHRP then return end

        if not SilentAimPlayersEnabled then
            return
        end

        local lookTargetPos = nil

        if SilentAimPlayersEnabled then
            local targetplayer = Selectedplayer or getClosestplayer(lpHRP)
            if targetplayer and targetplayer ~= player and targetplayer.Character then
                playersaimbot = targetplayer.Name
                local hrp = getHRP(targetplayer.Character)
                PlayersPosition = getPredictedPosition(hrp)
                lookTargetPos = PlayersPosition
            else
                playersaimbot, PlayersPosition = nil, nil
            end
        end

        -- Tự động xoay character về hướng mục tiêu
        if currentTool and lookTargetPos and isSkillReadyForTool(currentTool.Name) and not isNotDoughValidCondition() then
	        local lookVector = (Vector3.new(lookTargetPos.X, lpHRP.Position.Y, lookTargetPos.Z) - lpHRP.Position).Unit
	            lpHRP.CFrame = CFrame.new(lpHRP.Position, lpHRP.Position + lookVector)
	    end
    end)
end

local function stopRenderLoop()
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end
end

local function isValidCondition()
    return (currentTool and currentTool.Name == "Buddy Sword")
end

-- Hook metatable để thay đổi vị trí nhắm
spawn(function()
    local ok, hookMeta = pcall(getrawmetatable, game)
    if ok and hookMeta then
        setreadonly(hookMeta, false)
        local OldHook
        OldHook = hookmetamethod(game, "__namecall", function(self, V1, V2, ...)
            local Method = (getnamecallmethod and getnamecallmethod():lower()) or ""

            if tostring(self) == "RemoteEvent" and Method == "fireserver" then
                if typeof(V1) == "Vector3" then
                    if SilentAimPlayersEnabled and PlayersPosition then
                        return OldHook(self, PlayersPosition, V2, ...)
                    end
				end				
				if type(V1) == "string" and table.find(Booms, V1) then
					if ZSkillorM1 then 
	                    if SilentAimPlayersEnabled and PlayersPosition then
	                        return OldHook(self, V1, PlayersPosition, nil, ...)
	                    end
					end
				end   
            elseif Method == "invokeserver" then  
	            if isValidCondition() then
	                if type(V1) == "string" and table.find(Skills, V1) then  
	                    if SilentAimPlayersEnabled and PlayersPosition then  
	                        return OldHook(self, V1, PlayersPosition, nil, ...)
	                    end  
	                end    
				end				
			end
            
            return OldHook(self, V1, V2, ...)
        end)
        setreadonly(hookMeta, true)
    end
end)

-- Mouse hook (nếu cần)
if not isNotValidCondition() then
	if MouseModule and typeof(MouseModule) == "Instance" then
        local ok2, okResult = pcall(function()
            return require(MouseModule)
        end)

        if ok2 and okResult then  
            if type(okResult) == "table" then  
                Mouse = okResult  
            else  
                Mouse = nil  
            end  
        else  
            Mouse = nil  
        end  

        RunService.Heartbeat:Connect(function()  	        
		    if not ZSkillorM1 or (not SilentAimPlayersEnabled) then
		        return
		    end
		
            if Mouse and ZSkillorM1 and SilentAimPlayersEnabled then  
                local targetCFrame = nil  

                if PlayersPosition then  
                    targetCFrame = CFrame.new(PlayersPosition)  
                end  

                if targetCFrame then  
                    pcall(function()  
                        if type(Mouse) == "table" then  
                            Mouse.Hit = targetCFrame  
                            Mouse.Target = nil  
                        end  
                    end)  

                    if MouseModule then  
                        local ok, MouseData = pcall(require, MouseModule)  
                        if ok and type(MouseData) == "table" then  
                            MouseData.Hit = targetCFrame  
                            MouseData.Target = nil  
                        end  
                    end  
                end  
            end  
        end)
    end
end

-- Auto Ken function
local HasTag = function(tagName)
  local char = player.Character
  if (not char) then return false; end
  return Services.CollectionService:HasTag(char, tagName);
end

local function startAutoKenLoop()
    if autoKenRunning then return end
    autoKenRunning = true

    task.spawn(function()
        while AutoKen do
            task.wait(0.1)

            if HasTag("Ken") then
                local playerGui = player:FindFirstChild("PlayerGui")
                if playerGui then
                    local kenButton = playerGui:FindFirstChild("MobileContextButtons")
                    and playerGui.MobileContextButtons.ContextButtonFrame:FindFirstChild("BoundActionKen")

                    if kenButton and kenButton:GetAttribute("Selected") ~= true then
                        kenButton:SetAttribute("Selected", true)
                    end
                end

                local observationManager = getrenv()._G.OM
                if observationManager and not observationManager.active then
                    observationManager.radius = 0
                    observationManager:setActive(true)
                    commE:FireServer("Ken", true)
                end
            end
        end
        autoKenRunning = false
    end)
end

-- Character management
local function onCharacterAdded(char)
    clearConnections()

    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") then
            hookTool(child)
        end
    end

    table.insert(characterConnections, char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then hookTool(child) end
    end))

    table.insert(characterConnections, char.ChildRemoved:Connect(function(child)
        if child == currentTool then
            currentTool = nil
        end
    end))

    watchDamageCounter()
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then onCharacterAdded(player.Character) end

-- ================= PUBLIC API CHO WINDUI =================
function SilentAimModule:SetAutoKen(state)
    AutoKen = state

    if state then
        startAutoKenLoop()
    end
end

function SilentAimModule:SetZSkillorM1(state)
    ZSkillorM1 = state
end

function SilentAimModule:Pause()
	SilentAimPlayersEnabled = false
    stopRenderLoop()
end

function SilentAimModule:Restore()
	SilentAimPlayersEnabled = UserWantsplayerAim
    if UserWantsplayerAim then
        startRenderLoop()
    end
end

function SilentAimModule:IsplayerAimEnabled()
    return SilentAimPlayersEnabled
end

function SilentAimModule:SetDistanceLimit(num)
	if typeof(num) == "number" then
		maxRange = num
	end
end

function SilentAimModule:SetSelectedPlayer(playerName)
	if not playerName or playerName == "" then
		Selectedplayer = nil
		return
	end

	local found = Players:FindFirstChild(playerName)
	if found then
		Selectedplayer = found
	end
end

function SilentAimModule:GetSelectedPlayer()
	return Selectedplayer and Selectedplayer.Name or "None"
end

function SilentAimModule:SetPrediction(state)
	PredictionEnabled = state
end

function SilentAimModule:SetPredictionAmount(num)
	if typeof(num) == "number" then
		PredictionAmount = num
	end
end

-- QUAN TRỌNG: Function chính để tích hợp với WindUI Toggle
function SilentAimModule:SetPlayerSilentAim(state)
    UserWantsplayerAim = state
    SilentAimPlayersEnabled = state

    if state then
        startRenderLoop()
        print("[Aimbot] Đã bật Auto Farm")
    else
        stopRenderLoop()
        print("[Aimbot] Đã tắt Auto Farm")
    end
end

return SilentAimModule

 -- này là auto bật v4 nè 
 
local RaceV4Module = {}

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Player = Players.LocalPlayer
local RaceV4Enabled = false
local raceLoop = nil

local function ActivateRaceV4()
    VirtualInputManager:SendKeyEvent(true, "Y", false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, "Y", false, game)
end

local function StartRaceV4Loop()
    if raceLoop then return end
    
    raceLoop = task.spawn(function()
        while RaceV4Enabled do
            task.wait(0.2)
            pcall(function()
                local Char = Player.Character
                if Char then
                    local Energy = Char:FindFirstChild("RaceEnergy")
                    if Energy and Energy.Value == 1 then
                        ActivateRaceV4()
                    end
                end
            end)
        end
    end)
    
    print("[Race V4] Đã bật Auto Race V4")
end

local function StopRaceV4Loop()
    RaceV4Enabled = false
    if raceLoop then
        task.cancel(raceLoop)
        raceLoop = nil
    end
    
    print("[Race V4] Đã tắt Auto Race V4")
end

function RaceV4Module:SetState(state)
    if state then
        RaceV4Enabled = true
        StartRaceV4Loop()
    else
        StopRaceV4Loop()
    end
end

function RaceV4Module:IsEnabled()
    return RaceV4Enabled
end

Player.CharacterAdded:Connect(function()
    if RaceV4Enabled then
        StopRaceV4Loop()
        task.wait(1)
        StartRaceV4Loop()
    end
end)

return RaceV4Module


này là flash attack nè 

local FlashAttackModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Player = Players.LocalPlayer
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Net = Modules:WaitForChild("Net")
local RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
local RegisterHit = Net:WaitForChild("RE/RegisterHit")
local ShootGunEvent = Net:WaitForChild("RE/ShootGunEvent")
local GunValidator = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Validator2")

-- Biến trạng thái
local FlashAttackEnabled = false
local attackConnection = nil
local fastAttackInstance = nil

-- Biến tối ưu
local lastScanTime = 0
local cachedBladeHits = {}
local lastAttackTime = 0

local Config = {
    AttackDistance = 150,
    AttackMobs = true,
    AttackPlayers = true,
    AttackCooldown = 0.01,
    ComboResetTime = 0.01,
    MaxCombo = 3,
    HitboxLimbs = {"RightLowerArm", "RightUpperArm", "LeftLowerArm", "LeftUpperArm", "RightHand", "LeftHand"},
    AutoClickEnabled = true,
    OptimizedScanInterval = 0.01 -- Giảm tần suất quét
}

-- FastAttack Class
local FastAttack = {}
FastAttack.__index = FastAttack

function FastAttack.new()
    local self = setmetatable({
        Debounce = 0,
        ComboDebounce = 0,
        ShootDebounce = 0,
        M1Combo = 0,
        EnemyRootPart = nil,
        Connections = {},
        Overheat = {Dragonstorm = {MaxOverheat = 3, Cooldown = 0, TotalOverheat = 0, Distance = 350, Shooting = false}},
        ShootsPerTarget = {["Dual Flintlock"] = 2},
        SpecialShoots = {["Skull Guitar"] = "TAP", ["Bazooka"] = "Position", ["Cannon"] = "Position", ["Dragonstorm"] = "Overheat"}
    }, FastAttack)
    
    pcall(function()
        self.CombatFlags = require(Modules.Flags).COMBAT_REMOTE_THREAD
        self.ShootFunction = getupvalue(require(ReplicatedStorage.Controllers.CombatController).Attack, 9)
        local LocalScript = Player:WaitForChild("PlayerScripts"):FindFirstChildOfClass("LocalScript")
        if LocalScript and getsenv then
            self.HitFunction = getsenv(LocalScript)._G.SendHitsToServer
        end
    end)
    
    return self
end

function FastAttack:IsEntityAlive(entity)
    local humanoid = entity and entity:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health > 0
end

function FastAttack:CheckStun(Character, Humanoid, ToolTip)
    local Stun = Character:FindFirstChild("Stun")
    local Busy = Character:FindFirstChild("Busy")
    if Humanoid.Sit and (ToolTip == "Sword" or ToolTip == "Melee" or ToolTip == "Blox Fruit") then
        return false
    elseif Stun and Stun.Value > 0 or Busy and Busy.Value then
        return false
    end
    return true
end

-- Hàm quét tối ưu với cache
function FastAttack:GetBladeHits(Character, Distance)
    -- Sử dụng cache nếu chưa hết thời gian
    if tick() - lastScanTime < Config.OptimizedScanInterval and #cachedBladeHits > 0 then
        return cachedBladeHits
    end
    
    local Position = Character:GetPivot().Position
    local BladeHits = {}
    Distance = Distance or Config.AttackDistance
    
    local function ProcessTargets(Folder, CanAttack)
        for _, Enemy in ipairs(Folder:GetChildren()) do
            if Enemy ~= Character and self:IsEntityAlive(Enemy) then
                local BasePart = Enemy:FindFirstChild("HumanoidRootPart") -- Ưu tiên RootPart để giảm tính toán
                if BasePart and (Position - BasePart.Position).Magnitude <= Distance then
                    if not self.EnemyRootPart then
                        self.EnemyRootPart = BasePart
                    else
                        table.insert(BladeHits, {Enemy, BasePart})
                    end
                end
            end
        end
    end
    
    if Config.AttackMobs then ProcessTargets(Workspace.Enemies) end
    if Config.AttackPlayers then ProcessTargets(Workspace.Characters, true) end
    
    -- Cache kết quả
    lastScanTime = tick()
    cachedBladeHits = BladeHits
    
    return BladeHits
end

function FastAttack:GetClosestEnemy(Character, Distance)
    local BladeHits = self:GetBladeHits(Character, Distance)
    local Closest, MinDistance = nil, math.huge
    
    for _, Hit in ipairs(BladeHits) do
        local Magnitude = (Character:GetPivot().Position - Hit[2].Position).Magnitude
        if Magnitude < MinDistance then
            MinDistance = Magnitude
            Closest = Hit[2]
        end
    end
    return Closest
end

function FastAttack:GetCombo()
    local Combo = (tick() - self.ComboDebounce) <= Config.ComboResetTime and self.M1Combo or 0
    Combo = Combo >= Config.MaxCombo and 1 or Combo + 1
    self.ComboDebounce = tick()
    self.M1Combo = Combo
    return Combo
end

function FastAttack:ShootInTarget(TargetPosition)
    local Character = Player.Character
    if not self:IsEntityAlive(Character) then return end
    
    local Equipped = Character:FindFirstChildOfClass("Tool")
    if not Equipped or Equipped.ToolTip ~= "Gun" then return end
    
    local Cooldown = Equipped:FindFirstChild("Cooldown") and Equipped.Cooldown.Value or 0.3
    if (tick() - self.ShootDebounce) < Cooldown then return end
    
    local ShootType = self.SpecialShoots[Equipped.Name] or "Normal"
    if ShootType == "Position" or (ShootType == "TAP" and Equipped:FindFirstChild("RemoteEvent")) then
        Equipped:SetAttribute("LocalTotalShots", (Equipped:GetAttribute("LocalTotalShots") or 0) + 1)
        GunValidator:FireServer(self:GetValidator2())
        
        if ShootType == "TAP" then
            Equipped.RemoteEvent:FireServer("TAP", TargetPosition)
        else
            ShootGunEvent:FireServer(TargetPosition)
        end
        self.ShootDebounce = tick()
    else
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        self.ShootDebounce = tick()
    end
end

function FastAttack:GetValidator2()
    local v1 = getupvalue(self.ShootFunction, 15)
    local v2 = getupvalue(self.ShootFunction, 13)
    local v3 = getupvalue(self.ShootFunction, 16)
    local v4 = getupvalue(self.ShootFunction, 17)
    local v5 = getupvalue(self.ShootFunction, 14)
    local v6 = getupvalue(self.ShootFunction, 12)
    local v7 = getupvalue(self.ShootFunction, 18)
    
    local v8 = v6 * v2
    local v9 = (v5 * v2 + v6 * v1) % v3
    v9 = (v9 * v3 + v8) % v4
    v5 = math.floor(v9 / v3)
    v6 = v9 - v5 * v3
    v7 = v7 + 1
    
    setupvalue(self.ShootFunction, 15, v1)
    setupvalue(self.ShootFunction, 13, v2)
    setupvalue(self.ShootFunction, 16, v3)
    setupvalue(self.ShootFunction, 17, v4)
    setupvalue(self.ShootFunction, 14, v5)
    setupvalue(self.ShootFunction, 12, v6)
    setupvalue(self.ShootFunction, 18, v7)
    
    return math.floor(v9 / v4 * 16777215), v7
end

function FastAttack:UseNormalClick(Character, Humanoid, Cooldown)
    self.EnemyRootPart = nil
    local BladeHits = self:GetBladeHits(Character)
    
    if self.EnemyRootPart then
        RegisterAttack:FireServer(Cooldown)
        if self.CombatFlags and self.HitFunction then
            self.HitFunction(self.EnemyRootPart, BladeHits)
        else
            RegisterHit:FireServer(self.EnemyRootPart, BladeHits)
        end
    end
end

function FastAttack:UseFruitM1(Character, Equipped, Combo)
    local Targets = self:GetBladeHits(Character)
    if not Targets[1] then return end
    
    local Direction = (Targets[1][2].Position - Character:GetPivot().Position).Unit
    Equipped.LeftClickRemote:FireServer(Direction, Combo)
end

function FastAttack:Attack()
    if not FlashAttackEnabled or (tick() - self.Debounce) < Config.AttackCooldown then return end
    local Character = Player.Character
    if not Character or not self:IsEntityAlive(Character) then return end
    
    local Humanoid = Character.Humanoid
    local Equipped = Character:FindFirstChildOfClass("Tool")
    if not Equipped then return end
    
    local ToolTip = Equipped.ToolTip
    if not table.find({"Melee", "Blox Fruit", "Sword", "Gun"}, ToolTip) then return end
    
    local Cooldown = Equipped:FindFirstChild("Cooldown") and Equipped.Cooldown.Value or Config.AttackCooldown
    if not self:CheckStun(Character, Humanoid, ToolTip) then return end
    
    local Combo = self:GetCombo()
    Cooldown = Cooldown + (Combo >= Config.MaxCombo and 0.05 or 0)
    self.Debounce = Combo >= Config.MaxCombo and ToolTip ~= "Gun" and (tick() + 0.05) or tick()
    
    if ToolTip == "Blox Fruit" and Equipped:FindFirstChild("LeftClickRemote") then
        self:UseFruitM1(Character, Equipped, Combo)
    elseif ToolTip == "Gun" then
        local Target = self:GetClosestEnemy(Character, 120)
        if Target then
            self:ShootInTarget(Target.Position)
        end
    else
        self:UseNormalClick(Character, Humanoid, Cooldown)
    end
end

-- Flash Attack chính (đã tối ưu)
local function GetBladeHits()
    -- Sử dụng cache để tránh quét liên tục
    if tick() - lastScanTime < Config.OptimizedScanInterval and #cachedBladeHits > 0 then
        return cachedBladeHits
    end
    
    local targets = {}
    local playerPos = Player.Character and Player.Character:GetPivot().Position
    
    if not playerPos then return targets end
    
    local function ProcessFolder(folder)
        for _, v in pairs(folder:GetChildren()) do
            if v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                local distance = (v.HumanoidRootPart.Position - playerPos).Magnitude
                if distance < 60 then
                    table.insert(targets, v)
                end
            end
        end
    end
    
    if Config.AttackMobs then ProcessFolder(Workspace.Enemies) end
    if Config.AttackPlayers then ProcessFolder(Workspace.Characters) end
    
    lastScanTime = tick()
    cachedBladeHits = targets
    return targets
end

local function AttackAll()
    if not FlashAttackEnabled or tick() - lastAttackTime < 0.1 then return end
    lastAttackTime = tick()
    
    local character = Player.Character
    if not character then return end

    local equippedWeapon = character:FindFirstChild("EquippedWeapon")
    if not equippedWeapon then return end

    local enemies = GetBladeHits()
    if #enemies > 0 then
        RegisterAttack:FireServer(-math.huge)
        
        local args = {nil, {}}
        for i, v in pairs(enemies) do
            if not args[1] then
                args[1] = v.Head
            end
            args[2][i] = {v, v.HumanoidRootPart}
        end
        
        RegisterHit:FireServer(unpack(args))
    end
end

-- Fast Attack 2 (đã tối ưu)
local Funcs = {}

function GetAllBladeHits()
    -- Sử dụng cache chung
    if tick() - lastScanTime < Config.OptimizedScanInterval and #cachedBladeHits > 0 then
        return cachedBladeHits
    end
    return GetBladeHits() -- Dùng hàm chung đã được tối ưu
end

function Getplayerhit()
    local bladehits = {}
    local playerPos = Player.Character and Player.Character:GetPivot().Position
    
    if not playerPos then return bladehits end
    
    for _, v in pairs(Workspace.Characters:GetChildren()) do
        if v.Name ~= Player.Name and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
            local distance = (v.HumanoidRootPart.Position - playerPos).Magnitude
            if distance <= 65 then
                table.insert(bladehits, v)
            end
        end
    end
    return bladehits
end

function Funcs:Attack()
    if not FlashAttackEnabled or tick() - lastAttackTime < 0.1 then return end
    
    local bladehits = GetAllBladeHits()
    local playerHits = Getplayerhit()
    
    -- Gộp kết quả
    for _, v in pairs(playerHits) do
        table.insert(bladehits, v)
    end
    
    if #bladehits == 0 then return end
    
    local args = {
        [1] = nil,
        [2] = {},
        [4] = "078da341"
    }
    
    for r, v in pairs(bladehits) do
        RegisterAttack:FireServer(0)
        if not args[1] then
            args[1] = v.Head
        end
        args[2][r] = {
            [1] = v,
            [2] = v.HumanoidRootPart
        }
    end
    RegisterHit:FireServer(unpack(args))
end

-- API chính (đã tối ưu)
function FlashAttackModule:Start()
    if FlashAttackEnabled then return end
    
    FlashAttackEnabled = true
    
    -- Reset cache
    lastScanTime = 0
    cachedBladeHits = {}
    lastAttackTime = 0
    
    -- Khởi tạo FastAttack instance
    fastAttackInstance = FastAttack.new()
    
    -- Bắt đầu các loop tấn công với tần suất được kiểm soát
    attackConnection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        
        -- Chỉ cho phép tấn công mỗi 0.1s để giảm tải
        if currentTime - lastAttackTime >= 0.1 then
            if fastAttackInstance then
                fastAttackInstance:Attack()
            end
            AttackAll()
            Funcs:Attack()
            lastAttackTime = currentTime
        end
    end)
    
    -- Hook functions (giữ nguyên logic)
    for _, v in pairs(getgc(true)) do
        if typeof(v) == "function" and iscclosure(v) then
            local name = debug.getinfo(v).name
            if name == "Attack" or name == "attack" or name == "RegisterHit" then
                hookfunction(v, function(...)
                    if fastAttackEnabled and fastAttackInstance then
                        fastAttackInstance:Attack()
                    end
                    return v(...)
                end)
            end
        end
    end
    
    print("[Flash Attack] Đã bật Flash Attack (Đã tối ưu)")
end

function FlashAttackModule:Stop()
    if not FlashAttackEnabled then return end
    
    FlashAttackEnabled = false
    
    -- Ngắt kết nối
    if attackConnection then
        attackConnection:Disconnect()
        attackConnection = nil
    end
    
    -- Dọn dẹp instance
    if fastAttackInstance then
        for _, conn in ipairs(fastAttackInstance.Connections) do
            pcall(function() conn:Disconnect() end)
        end
        fastAttackInstance = nil
    end
    
    -- Clear cache
    cachedBladeHits = {}
    
    print("[Flash Attack] Đã tắt Flash Attack")
end

function FlashAttackModule:SetState(state)
    if state then
        self:Start()
    else
        self:Stop()
    end
end

function FlashAttackModule:IsEnabled()
    return FlashAttackEnabled
end

return FlashAttackModule

--này là auto bật haki vũ Trang nè 

local BusoModule = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local commF_ = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
local AutoHakiBusoEnabled = false
local busoLoop = nil
local function StartBusoLoop()
    if busoLoop then 
        task.cancel(busoLoop)
        busoLoop = nil
    end
    
    busoLoop = task.spawn(function()
        while AutoHakiBusoEnabled do
            pcall(function()
                local player = Players.LocalPlayer
                local character = player.Character
                
                if character and not character:FindFirstChild("HasBuso") then
                    local args = {[1] = "Buso"}
                    commF_:InvokeServer(unpack(args))
                end
            end)
            task.wait(1)
        end
    end)
    
    print("[Buso] Đã bật Auto Haki Buso")
end

local function StopBusoLoop()
    AutoHakiBusoEnabled = false
    if busoLoop then
        task.cancel(busoLoop)
        busoLoop = nil
    end
    
    print("[Buso] Đã tắt Auto Haki Buso")
end

function BusoModule:SetState(state)
    if state then
        AutoHakiBusoEnabled = true
        StartBusoLoop()
    else
        StopBusoLoop()
    end
end

function BusoModule:IsEnabled()
    return AutoHakiBusoEnabled
end

Players.LocalPlayer.CharacterAdded:Connect(function()
    if AutoHakiBusoEnabled then
        StopBusoLoop()
        task.wait(2)
        StartBusoLoop()
    end
end)
ReplicatedStorage.DescendantAdded:Connect(function(descendant)
    if descendant.Name == "CommF_" and AutoHakiBusoEnabled then
        StopBusoLoop()
        task.wait(1)
        StartBusoLoop()
    end
end)

return BusoModule


--- dữ liệu bounty của player 
"Bounty : "..game:GetService("Players").LocalPlayer.leaderstats["Bounty/Honor"].Value.."\n"..

--chọn team

-- AUTO SELECT TEAM (Blox Fruits)

getgenv().team = "Marines" 
-- đổi thành "Pirates" nếu muốn

repeat wait() until game:IsLoaded() 
    and game.Players.LocalPlayer:FindFirstChild("DataLoaded")

-- Chỉ chạy khi đang ở màn hình chọn phe
if game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("Main (minimal)") then
    repeat
        task.wait()
        local Remotes = game.ReplicatedStorage:WaitForChild("Remotes")
        Remotes.CommF_:InvokeServer("SetTeam", getgenv().team)
        task.wait(3)
    until not game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("Main (minimal)")
end


