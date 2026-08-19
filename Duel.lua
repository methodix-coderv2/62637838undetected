repeat task.wait() until game:IsLoaded()
local Players,RunService,UIS,TS,Lighting,HS = game:GetService("Players"),game:GetService("RunService"),game:GetService("UserInputService"),game:GetService("TweenService"),game:GetService("Lighting"),game:GetService("HttpService")
local LP = Players.LocalPlayer
local NS,CS = 60,29
local LAGGER_SPEED = 15
local LAGGER_CARRY_SPEED = 24.5
local speedMode,antiRagdollEnabled,infJumpEnabled = false,false,false
local laggerToggled = false
local laggerPhase = 0
local medusaCounterEnabled = false
local batCounterEnabled = false
local unwalkEnabled = false
local medusaDebounce,medusaLastUsed,dropActive = false,0,false
local autoLeftEnabled,autoRightEnabled = false,false
local autoLeftSetVisual,autoRightSetVisual = nil,nil
local speedLabel = nil
local autoBatEnabled = false
local autoSwingEnabled = true
local autoBatSetVisual = nil
local _autoBatTarget = nil
local resetAutoBatMotion = nil
local _batSwingCooldown = 0
local BAT_SWING_INTERVAL = 0.08
local AUTO_BAT_SPEED = 60
local setBatCounterVisual = nil
local startBatCounter,stopBatCounter
local antiLagEnabled = false
local removeAccessoriesEnabled = false
local antiLagDescConn = nil
local stretchRezEnabled = false
local stretchRezConn = nil
local setStretchRezVisual = nil

local unwalkSavedAnimate = nil
local _anyKeyListening = false
local autoTPConn = nil
local setAutoTPVisual = nil
local cursedResetRemote = nil
local CURSED_RESET_GUID = "f888ee6e-c86d-46e1-93d7-0639d6635d42"

-- FIX: I-OVERRIDE ang canUseAutoPath para LAGING GUMANA
local function canUseAutoPath()
    return true -- FORCE ENABLED
end

-- FIX: I-force ang WalkSpeed para sigurado
local function forceWalkSpeed()
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed < 30 then
            hum.WalkSpeed = 30
        end
    end
end
game:GetService("RunService").Heartbeat:Connect(forceWalkSpeed)

-- Blacklist check (kept for safety)
task.spawn(function()
    local BLACKLIST_URL="https://pastebin.com/2zLUXv2K"
    pcall(function() HS.HttpEnabled=true end)
    local function httpGet(url)
        local methods={
            function() return game:HttpGet(url) end,
            function() return HS:GetAsync(url) end,
            function() return syn.request({Url=url,Method="GET"}).Body end,
            function() return http_request({Url=url,Method="GET"}).Body end,
            function() return request({Url=url,Method="GET"}).Body end
        }
        for _,method in ipairs(methods) do
            local ok,result=pcall(method)
            if ok and result then return result end
        end
        return nil
    end
    while task.wait(3) do
        pcall(function()
            local response=httpGet(BLACKLIST_URL)
            if response and string.find(response,tostring(LP.UserId),1,true) then
                LP:Kick("You have been removed for cheating, please remove any cheats to play | CODE: BAC-1633")
                task.wait(999999)
            end
        end)
    end
end)

pcall(function()
    if hookfunction and newcclosure then
        local oldFire
        oldFire=hookfunction(Instance.new("RemoteEvent").FireServer,newcclosure(function(self,...)
            if not cursedResetRemote and typeof(self)=="Instance" and self:IsA("RemoteEvent") and self.Name:sub(1,3)=="RE/" then cursedResetRemote=self end
            return oldFire(self,...)
        end))
    end
end)

task.spawn(function()
    task.wait(2)
    if cursedResetRemote then return end
    for _,desc in ipairs(game:GetDescendants()) do
        if desc:IsA("RemoteEvent") and desc.Name:sub(1,3)=="RE/" then cursedResetRemote=desc;break end
    end
end)

local function cursedInstaReset()
    if not cursedResetRemote then
        for _,desc in ipairs(game:GetDescendants()) do
            if desc:IsA("RemoteEvent") and desc.Name:sub(1,3)=="RE/" then cursedResetRemote=desc;break end
        end
    end
    if not cursedResetRemote then return end
    local character=LP.Character
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health<=0 then pcall(function() cursedResetRemote:FireServer(CURSED_RESET_GUID,LP,"balloon") end);return end
    local resetDetected=false
    local conns={}
    if humanoid then
        table.insert(conns,humanoid.Died:Connect(function() resetDetected=true end))
        table.insert(conns,humanoid:GetPropertyChangedSignal("Health"):Connect(function() if humanoid.Health<=0 then resetDetected=true end end))
    end
    if character then table.insert(conns,character.AncestryChanged:Connect(function(_,parent) if not parent then resetDetected=true end end)) end
    task.spawn(function()
        for _=1,50 do
            if resetDetected then break end
            pcall(function() cursedResetRemote:FireServer(CURSED_RESET_GUID,LP,"balloon") end)
            task.wait()
        end
        for _,conn in ipairs(conns) do pcall(function() conn:Disconnect() end) end
    end)
end

local KB = {
    DropBrainrot={kb=Enum.KeyCode.X},
    AutoLeft    ={kb=Enum.KeyCode.Z},
    AutoRight   ={kb=Enum.KeyCode.C},
    AutoBat     ={kb=Enum.KeyCode.E},
    TPFloor     ={kb=Enum.KeyCode.F},
    InstaReset  ={kb=Enum.KeyCode.T},
    GuiHide     ={kb=Enum.KeyCode.LeftControl},
    SpeedToggle ={kb=Enum.KeyCode.Q},
    LaggerToggle={kb=Enum.KeyCode.R},
    Aimbot2={kb=Enum.KeyCode.V},
    AntiDesyncAimbot={kb=Enum.KeyCode.B}
}

local AP_L1,AP_L2 = Vector3.new(-476.16,-6.52,25.62),Vector3.new(-483.06,-5.03,25.48)
local AP_R1,AP_R2 = Vector3.new(-476.47,-6.28,92.73),Vector3.new(-483.12,-4.95,94.81)

local Steal = {
    AutoStealEnabled=false,StealRadius=60,StealDuration=1.4,
    Data={}
}
local isStealing = false
local stealStartTime = nil
local Conns = {autoSteal=nil,antiRag=nil,batCounter=nil,anchor={},progress=nil}
local MEDUSA_COOLDOWN = 25
local batCounterDebounce = false
local modeValLbl
local uiScale = 1
uiLocked=false
setLockVisual=nil
exeLaggerPanelKey=Enum.KeyCode.M
exeMainFrame=nil
exeMiniButton=nil
exeGrabBar=nil
local lastMoveDir = Vector3.new(0,0,0)
local MOVE_KEYS={[Enum.KeyCode.W]=true,[Enum.KeyCode.A]=true,[Enum.KeyCode.S]=true,[Enum.KeyCode.D]=true,
    [Enum.KeyCode.Up]=true,[Enum.KeyCode.Left]=true,[Enum.KeyCode.Down]=true,[Enum.KeyCode.Right]=true}

local function getActiveMoveSpeed()
    return laggerToggled and (laggerPhase==2 and LAGGER_CARRY_SPEED or LAGGER_SPEED) or (speedMode and CS or NS)
end

local function getAutoPathSpeed()
    return laggerToggled and LAGGER_SPEED or NS
end

local function isRagdollState(hum)
    if not hum then return true end
    local st=hum:GetState()
    return hum.PlatformStand or st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown
end

local function isMyPlotByName(plotName)
    local plots=workspace:FindFirstChild("Plots")
    if not plots then return false end
    local plot=plots:FindFirstChild(plotName)
    if not plot then return false end
    local sign=plot:FindFirstChild("PlotSign")
    if sign then
        local yb=sign:FindFirstChild("YourBase")
        if yb and yb:IsA("BillboardGui") then
            return yb.Enabled==true
        end
    end
    return false
end

local function findNearestPrompt()
    local char=LP.Character;if not char then return nil end
    local root=char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    if not root then return nil end
    local plots=workspace:FindFirstChild("Plots");if not plots then return nil end
    local nearest,dist=nil,math.huge
    for _,plot in ipairs(plots:GetChildren()) do
        if isMyPlotByName(plot.Name) then continue end
        local pods=plot:FindFirstChild("AnimalPodiums");if not pods then continue end
        for _,pod in ipairs(pods:GetChildren()) do
            local base=pod:FindFirstChild("Base")
            local sp=base and base:FindFirstChild("Spawn")
            if sp then
                local d=(sp.Position-root.Position).Magnitude
                if d<=Steal.StealRadius and d<dist then
                    local found=nil
                    local att=sp:FindFirstChild("PromptAttachment")
                    if att then
                        for _,pr in ipairs(att:GetChildren()) do
                            if pr:IsA("ProximityPrompt") and pr.ActionText and pr.ActionText:find("Steal") then found=pr end
                        end
                    end
                    if not found then
                        for _,pr in ipairs(sp:GetDescendants()) do
                            if pr:IsA("ProximityPrompt") and pr.ActionText and pr.ActionText:find("Steal") then found=pr end
                        end
                    end
                    if found then nearest,dist=found,d end
                end
            end
        end
    end
    return nearest
end

local function _promptDist(prompt)
    local char=LP.Character
    if not char then return math.huge end
    local root=char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    if not root then return math.huge end
    local part=prompt.Parent
    if part and part:IsA("Attachment") then part=part.Parent end
    if part and part:IsA("BasePart") then return (part.Position-root.Position).Magnitude end
    local ok,cf=pcall(function() return prompt.Parent and prompt.Parent.WorldPosition end)
    if ok and cf then return (cf-root.Position).Magnitude end
    return math.huge
end

local function executeSteal(prompt)
    if isStealing then return end
    if not Steal.Data[prompt] then
        Steal.Data[prompt]={hold={},trigger={},ready=true}
        if getconnections then
            for _,c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do if c.Function then table.insert(Steal.Data[prompt].hold,c.Function) end end
            for _,c in ipairs(getconnections(prompt.Triggered)) do if c.Function then table.insert(Steal.Data[prompt].trigger,c.Function) end end
        end
    end
    local data=Steal.Data[prompt];if not data.ready then return end
    data.ready=false;isStealing=true;stealStartTime=tick()
    task.spawn(function()
        for _,fn in ipairs(data.hold) do task.spawn(fn) end
        task.wait(Steal.StealDuration)
        for _,fn in ipairs(data.trigger) do task.spawn(fn) end
        data.ready=true;isStealing=false
    end)
end

local function startAutoSteal()
    if Conns.autoSteal then return end
    Conns.autoSteal=RunService.Heartbeat:Connect(function()
        if not Steal.AutoStealEnabled or isStealing then return end
        local p=findNearestPrompt();if p then executeSteal(p) end
    end)
end

local function stopAutoSteal()
    if Conns.autoSteal then Conns.autoSteal:Disconnect();Conns.autoSteal=nil end
    isStealing=false
end

RunService.Stepped:Connect(function()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and p.Character then
            for _,part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide=false end
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    local char=LP.Character;if not char then return end
    local hum=char:FindFirstChildOfClass("Humanoid")
    local hrp=char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    if isRagdollState(hum) then lastMoveDir=Vector3.new(0,0,0);return end
    if not autoBatEnabled and not autoLeftEnabled and not autoRightEnabled then
        local md=hum.MoveDirection
        local spd=getActiveMoveSpeed()
        if md.Magnitude>0 then
            lastMoveDir=md
            hrp.Velocity=Vector3.new(md.X*spd,hrp.Velocity.Y,md.Z*spd)
        elseif antiRagdollEnabled and lastMoveDir.Magnitude>0 then
            local anyHeld=false
            for key in pairs(MOVE_KEYS) do if UIS:IsKeyDown(key) then anyHeld=true;break end end
            if anyHeld then hrp.Velocity=Vector3.new(lastMoveDir.X*spd,hrp.Velocity.Y,lastMoveDir.Z*spd) end
        end
    end
    if speedLabel then speedLabel.Text=string.format("Speed: %.1f",Vector3.new(hrp.Velocity.X,0,hrp.Velocity.Z).Magnitude) end
end)

local alConn,arConn=nil,nil
local alPhase,arPhase=1,1

local function stopAutoLeft()
    autoLeftEnabled=false
    if alConn then alConn:Disconnect();alConn=nil end;alPhase=1
    local char=LP.Character;if char then local h=char:FindFirstChildOfClass("Humanoid");if h then h:Move(Vector3.zero,false);h.PlatformStand=false;pcall(function() h:ChangeState(Enum.HumanoidStateType.Running) end);workspace.CurrentCamera.CameraSubject=h end end
    if autoLeftSetVisual then autoLeftSetVisual(false) end
    if mobBtnRefs and mobBtnRefs.autoLeft then mobBtnRefs.autoLeft(false) end
end

local function stopAutoRight()
    autoRightEnabled=false
    if arConn then arConn:Disconnect();arConn=nil end;arPhase=1
    local char=LP.Character;if char then local h=char:FindFirstChildOfClass("Humanoid");if h then h:Move(Vector3.zero,false);h.PlatformStand=false;pcall(function() h:ChangeState(Enum.HumanoidStateType.Running) end);workspace.CurrentCamera.CameraSubject=h end end
    if autoRightSetVisual then autoRightSetVisual(false) end
    if mobBtnRefs and mobBtnRefs.autoRight then mobBtnRefs.autoRight(false) end
end

local function startAutoLeft()
    if alConn then alConn:Disconnect() end;alPhase=1
    alConn=RunService.Heartbeat:Connect(function()
        if not autoLeftEnabled then return end
        local char=LP.Character;if not char then return end
        local hrp=char:FindFirstChild("HumanoidRootPart")
        local hum=char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        if isRagdollState(hum) then hum:Move(Vector3.zero,false);return end
        local spd=getAutoPathSpeed()
        if alPhase==1 then
            local tgt=Vector3.new(AP_L1.X,hrp.Position.Y,AP_L1.Z)
            if (tgt-hrp.Position).Magnitude<1 then
                alPhase=2
                local d=AP_L2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
                hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
                return
            end
            local d=AP_L1-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
            hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
        elseif alPhase==2 then
            local tgt=Vector3.new(AP_L2.X,hrp.Position.Y,AP_L2.Z)
            if (tgt-hrp.Position).Magnitude<1 then
                hum:Move(Vector3.zero,false);hum.PlatformStand=false;pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end);workspace.CurrentCamera.CameraSubject=hum;hrp.AssemblyLinearVelocity=Vector3.zero
                autoLeftEnabled=false;if alConn then alConn:Disconnect();alConn=nil end
                alPhase=1;if autoLeftSetVisual then autoLeftSetVisual(false) end;if mobBtnRefs and mobBtnRefs.autoLeft then mobBtnRefs.autoLeft(false) end;saveConfig();return
            end
            local d=AP_L2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
            hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
        end
    end)
end

local function startAutoRight()
    if arConn then arConn:Disconnect() end;arPhase=1
    arConn=RunService.Heartbeat:Connect(function()
        if not autoRightEnabled then return end
        local char=LP.Character;if not char then return end
        local hrp=char:FindFirstChild("HumanoidRootPart")
        local hum=char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        if isRagdollState(hum) then hum:Move(Vector3.zero,false);return end
        local spd=getAutoPathSpeed()
        if arPhase==1 then
            local tgt=Vector3.new(AP_R1.X,hrp.Position.Y,AP_R1.Z)
            if (tgt-hrp.Position).Magnitude<1 then
                arPhase=2
                local d=AP_R2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
                hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
                return
            end
            local d=AP_R1-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
            hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
        elseif arPhase==2 then
            local tgt=Vector3.new(AP_R2.X,hrp.Position.Y,AP_R2.Z)
            if (tgt-hrp.Position).Magnitude<1 then
                hum:Move(Vector3.zero,false);hum.PlatformStand=false;pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end);workspace.CurrentCamera.CameraSubject=hum;hrp.AssemblyLinearVelocity=Vector3.zero
                autoRightEnabled=false;if arConn then arConn:Disconnect();arConn=nil end
                arPhase=1;if autoRightSetVisual then autoRightSetVisual(false) end;if mobBtnRefs and mobBtnRefs.autoRight then mobBtnRefs.autoRight(false) end;saveConfig();return
            end
            local d=AP_R2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
            hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
        end
    end)
end

local function setupSpeedIndicator(char)
    local head=char:WaitForChild("Head",5);if not head then return end
    local bb=Instance.new("BillboardGui",head)
    bb.Size=UDim2.new(0,160,0,44);bb.StudsOffset=Vector3.new(0,3,0);bb.AlwaysOnTop=true
    speedLabel=Instance.new("TextLabel",bb)
    speedLabel.Size=UDim2.new(1,0,0.55,0);speedLabel.BackgroundTransparency=1
    speedLabel.Text="Speed: 0";speedLabel.TextColor3=Color3.fromRGB(255,255,255)
    speedLabel.Font=Enum.Font.GothamBlack;speedLabel.TextScaled=true
    speedLabel.TextStrokeTransparency=0;speedLabel.TextStrokeColor3=Color3.fromRGB(0,0,0)
    local discordLabel=Instance.new("TextLabel",bb)
    discordLabel.Size=UDim2.new(1,0,0.45,0);discordLabel.Position=UDim2.new(0,0,0.55,0);discordLabel.BackgroundTransparency=1
    discordLabel.Text="https://discord.gg/3aNBgkKKXN";discordLabel.TextColor3=Color3.fromRGB(255,255,255)
    discordLabel.Font=Enum.Font.GothamBlack;discordLabel.TextScaled=true
    discordLabel.TextStrokeTransparency=0;discordLabel.TextStrokeColor3=Color3.fromRGB(0,0,0)
end

local function startAntiRagdoll()
    if Conns.antiRag then return end
    Conns.antiRag=RunService.Heartbeat:Connect(function()
        if not antiRagdollEnabled then return end
        local char=LP.Character
        if not char then return end
        local hum=char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return end
        local state=hum:GetState()
        local isRagdolled = state==Enum.HumanoidStateType.Physics or state==Enum.HumanoidStateType.Ragdoll or state==Enum.HumanoidStateType.FallingDown
        if isRagdolled then
            pcall(function()
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                local root=char:FindFirstChild("HumanoidRootPart")
                if root then
                    root.Velocity=Vector3.zero
                    root.RotVelocity=Vector3.zero
                    root.AssemblyLinearVelocity=Vector3.zero
                    root.AssemblyAngularVelocity=Vector3.zero
                end
                for _,obj in ipairs(char:GetDescendants()) do
                    if obj:IsA("Motor6D") then obj.Enabled=true end
                    if obj:IsA("Constraint") then obj.Enabled=true end
                end
                workspace.CurrentCamera.CameraSubject=hum
                local PM=LP.PlayerScripts:FindFirstChild("PlayerModule")
                if PM then
                    local CM=require(PM:FindFirstChild("ControlModule"))
                    if CM then CM:Enable() end
                end
                hum.AutoRotate=true
                hum.PlatformStand=false
  
