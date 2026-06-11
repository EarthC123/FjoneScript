local plrsrv = game:GetService("Players")
local replicated = game:GetService("ReplicatedStorage")
local userinputservice = game:GetService("UserInputService")
local plr = plrsrv.LocalPlayer
local localcharacter = plr.Character or plr.CharacterAdded:Wait()
local plrgui = plr:WaitForChild("PlayerGui")
local screengui = plrgui:FindFirstChild("ScreenGui")
local RunService = game:GetService("RunService")
local lighting=game:GetService("Lighting")
local proximitysrv = game:GetService("ProximityPromptService")

local RejectFolder=workspace:WaitForChild("Enemies")
local MachineFolder=workspace:WaitForChild("Interacts")
local ItemFolder=workspace:WaitForChild("Tools")
local PlayerFolder=workspace:WaitForChild("Characters")
local StuffingFolder=workspace:WaitForChild("Pickup"):WaitForChild("Stuffing")
local TrainpartFolder=MachineFolder:WaitForChild("ItemCollection")

local BuffHandler = require(replicated.Shared.Modules.BuffHandler)
local CharacterControl = require(plr.PlayerScripts.Client.CharacterController)
local MachineMinigameSession = require(plr.PlayerScripts.Client.Interface.UIController.GameUI.MinigameHandler.Sessions)
local BrokenMachineMinigame = require(plr.PlayerScripts.Client.Interface.UIController.GameUI.MinigameHandler.Minigames.Broken)
local DroneMachinrMinigame = require(plr.PlayerScripts.Client.Interface.UIController.GameUI.MinigameHandler.Minigames.Drone)
local SoundController = require(replicated.Shared.Modules.SoundController)
local rng = Random.new(tick())
local MinigamesData = require(replicated.Shared.GameData.Minigames)

-- esp
local STYLE_Machine = {
    FillTransparency=0.7,
    OutlineTransparency = 0.3,
    FillColor = Color3.fromRGB(110, 125, 255),
    OutlineColor = Color3.fromRGB(115, 0, 255)
}
local STYLE_Reject = {
    FillTransparency=0.7,
    OutlineTransparency = 0.3,
    FillColor = Color3.fromRGB(255, 50, 50),
    OutlineColor = Color3.fromRGB(255, 149, 0)
}
local STYLE_item = {
    FillTransparency=0.7,
    OutlineTransparency=0.3,
    FillColor = Color3.fromRGB(30, 144, 255)
}
local STYLE_Player = {
    FillTransparency=0.7,
    OutlineTransparency = 0.3,
    FillColor = Color3.fromRGB(0, 128, 0),
    OutlineColor = Color3.fromRGB(0, 100, 0)
}
local STYLE_Invisible = {
    FillTransparency=1,
    OutlineTransparency = 1
}
local STYLE_Trainpart = {
    FillTransparency=0.7,
    OutlineTransparency=0.3,
    FillColor = Color3.fromRGB(120, 215, 255),
    OutlineColor = Color3.fromRGB(33, 92, 255)
}
local STYLE_KEPLIE = {
    FillTransparency=0.7,
    OutlineTransparency=0.3,
    FillColor = Color3.fromRGB(37, 15, 148),
    OutlineColor = Color3.fromRGB(162, 146, 242)
}
local STYLE_EGGSPAWN = {
    FillTransparency=0.7,
    OutlineTransparency=0.3,
    FillColor = Color3.fromRGB(0, 255, 0),
    OutlineColor = Color3.fromRGB(0, 149, 0)
}

local function apply_highlight_style(highlighteffect, style)
    for property,value in pairs(style) do
        highlighteffect[property]=value
    end
end

local function itemblacklist(item)
    return false
end

local function fjonehighlight(entity, highlighteffect)
    local isHighlight = entity:FindFirstChild("FjoneHighlight")
	if isHighlight ~= nil then
	    return
	end
	highlighteffect.Parent = entity
	highlighteffect.Adornee = entity
	highlighteffect.Name = "FjoneHighlight"
end

--workspace.Enemies.RejectZorro.RejectHighlight
local function highlightReject(rejects)
    local highlighteffect=rejects:WaitForChild("RejectHighlight")
    highlighteffect:GetPropertyChangedSignal("OutlineTransparency"):Connect(
        function ()
	        apply_highlight_style(highlighteffect, STYLE_Reject)
	    end
	)
	highlighteffect:GetPropertyChangedSignal("DepthMode"):Connect(
	    function ()
	        highlighteffect.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
	    end
	)
end

--workspace.Interacts.Machine.Light.SurfaceGui.Progress.Gradient
--Offset.Y==1
local function waitForPath(root, path)
    local current = root
    for _, name in ipairs(path) do
        current = current:WaitForChild(name)
    end
    return current
end

local function highlightMachine(machine)
    if machine.Name == "ItemCollection" or machine.Name == "ExplosionPrefab" then
        return
    end
    local highlighteffect=machine:WaitForChild("Highlight")
    local isComplete=false
    local function Machinehighlighteffect()
        if isComplete then
            apply_highlight_style(highlighteffect, STYLE_Invisible)
            return
        end
	    apply_highlight_style(highlighteffect, STYLE_Machine)
    end
    highlighteffect:GetPropertyChangedSignal("OutlineTransparency"):Connect(
        function ()
            Machinehighlighteffect()
	    end
	)
    Machinehighlighteffect()
    local gradient = waitForPath(machine, {
        "Light",
        "SurfaceGui",
        "Progress",
        "Gradient",
    })
    gradient:GetPropertyChangedSignal("Offset"):Connect(
        function ()
            if gradient.Offset.Y>=1 then
                isComplete=true
                Machinehighlighteffect()
            end
	    end
	)
end

--workspace.Pickup.Stuffing:GetChildren()[2]
local function highlightStuffing(stuffing)
    local prompt = stuffing:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        prompt.MaxActivationDistance = 7
        prompt.HoldDuration = 0
    end
    local highlighteffect=Instance.new("Highlight")
    apply_highlight_style(highlighteffect, STYLE_item)
    fjonehighlight(stuffing, highlighteffect)
end

local function highlightItem(item)
    if itemblacklist(item) == true then
        return
    end
    local highlighteffect=Instance.new("Highlight")
    apply_highlight_style(highlighteffect, STYLE_item)
    fjonehighlight(item, highlighteffect)
end

local function highlightPlayer(player)
    if player == localcharacter then
        return
    end
    local highlighteffect=Instance.new("Highlight")
    apply_highlight_style(highlighteffect, STYLE_Player)
    fjonehighlight(player, highlighteffect)
end

--workspace.Interacts.ItemCollection:GetChildren()[13]
local function highlightTrainpart(trainpart)
    local highlighteffect=Instance.new("Highlight")
    apply_highlight_style(highlighteffect, STYLE_Trainpart)
    fjonehighlight(trainpart, highlighteffect)
end

local function highlightKeplie(keplie)
    print("Fjone:highlight ",keplie.Name)
    local highlighteffect=Instance.new("Highlight")
    apply_highlight_style(highlighteffect, STYLE_KEPLIE)
    fjonehighlight(keplie, highlighteffect)
end

local function highlightEggSpawn(egginteract)
    egginteract.Transparency = 0
    local highlighteffect=Instance.new("Highlight")
    apply_highlight_style(highlighteffect, STYLE_EGGSPAWN)
    fjonehighlight(egginteract, highlighteffect)
end


local folder_rules = {
    [RejectFolder] = {
        handler = highlightReject
    },
    [MachineFolder] = {
        handler = highlightMachine
    },
    [ItemFolder] = {
        handler = highlightItem
    },
    [PlayerFolder] = {
        handler = highlightPlayer
    },
    [StuffingFolder] = {
        handler = highlightStuffing
    },
    [TrainpartFolder] = {
        handler = highlightTrainpart
    }
}

local Map_Rules = {
    --workspace.Map.Segments.Segment[2].KeplieHold.KeplieRoot.Keplie1
    --["Segments"] = {
    --    matchstr = "^Keplie%d+$",
    --    handler = highlightKeplie
    --},
    --workspace.Map.Interact.EggSpawn.InterractPart
    ["Interact"] = {
        matchstr = "^InteractPart$",
        handler = highlightEggSpawn
    }
}

local function handlemap(mapfolder)
    for foldername, rule in pairs(Map_Rules) do
        local function applyrule(obj)
            if string.match(obj.Name, rule.matchstr) then
                print("Fjone: Founded ", obj.Name)
                rule.handler(obj)
            end
        end
        local subfolder = mapfolder:WaitForChild(foldername)
        for _,obj in ipairs(subfolder:GetDescendants()) do
            applyrule(obj)
        end
        subfolder.DescendantAdded:Connect(applyrule)
    end
end

local function onInit()
    for folder, rule in pairs(folder_rules) do
        for _, item in ipairs(folder:GetChildren()) do
		    rule.handler(item)
	    end
        folder.ChildAdded:Connect(rule.handler)
    end
    local MapFolder=workspace:WaitForChild("Map")
    handlemap(MapFolder)
    workspace.ChildAdded:Connect(function(addedfolder)
        local function doifmap()
            if addedfolder.Name == "Map" then
                print("Fjone:Map added")
                handlemap(addedfolder)
            end
        end
        doifmap()
        addedfolder:GetPropertyChangedSignal("Name"):Connect(doifmap)
    end)
end

onInit()

-- infinite stamina
local ori_IsActive = BuffHandler.IsActive

BuffHandler.IsActive = function(self, buffname)
    if buffname == "InfiniteStamina" then
        return true
    end
    return ori_IsActive(self, buffname)
end

-- skillcheck Always Success
local targetAngleRange = { 135, 315 }
BrokenMachineMinigame.Start=function(session)
	local minigameGui = plrgui:FindFirstChild("GameUI")
	if minigameGui then
		minigameGui = minigameGui:FindFirstChild("PlushieMinigame")
	end
	if minigameGui then
		local rootFrame = minigameGui:FindFirstChild("Root")
		if rootFrame then
			local payload = session.payload or {}
			local targetAngle = payload.targetAngle or rng:NextInteger(targetAngleRange[1], targetAngleRange[2])
			local result="Perfect"
			SoundController.PlaySound("SFX.Machine.Minigame" .. result, false)
			print("Fjone:", session.sessionId, result, targetAngle)
			MachineMinigameSession.Submit(session.sessionId, {
				["success"] = result == "Perfect" and true or result == "Okay",
				["data"] = {
					["response"] = result,
					["endAngle"] = targetAngle
				}
			})
		end
	end
end

local droneConfig = (MinigamesData.Data and MinigamesData.Data.Drone or {}).Config or {}
local basePeriod = droneConfig.BasePeriod or 2.6
local perfectHoldThreshold = droneConfig.PerfectHoldThreshold or 0.8
local goodHoldThreshold = droneConfig.GoodHoldThreshold or 0.1
DroneMachinrMinigame.Start=function(session)
	local function step(state, dt)
		local holdFraction = perfectHoldThreshold
		local resolvedResult = perfectHoldThreshold <= holdFraction and "Perfect" or (goodHoldThreshold <= holdFraction and "Good" or "OK")
		MachineMinigameSession.Respond(state.session.sessionId, resolvedResult, {
			["holdFraction"] = holdFraction
		})
	end
	local droneState = {
		["session"] = session,
	}
	session.trove:Add(RunService.RenderStepped:Connect(function(dt)
		-- upvalues: (ref) step, (copy) droneState
		-- [[ func_23 | 5 instrs | line_defined=614 ]]
		step(droneState, dt)
	end))
	return true
end

--[[ more stealthy drone machine auto skill check
local basePumpingFraction = droneConfig.BasePumpingFraction or 0.6

local function applyServerState(state, serverData)
	if typeof(serverData) ~= "table" then
		return
	end
	if typeof(serverData.period) == "number" and serverData.period > 0 then
		state.period = serverData.period
		state.session.state.period = serverData.period
		if state.machine then
			state.machine:SetAttribute("DronePeriod", serverData.period)
		end
	end
	if typeof(serverData.pumpingFraction) == "number" then
		state.pumpingFraction = math.clamp(serverData.pumpingFraction, 0.05, 0.95)
		state.session.state.pumpingFraction = state.pumpingFraction
	end
	if typeof(serverData.randomizePumpingFraction) == "boolean" then
		state.randomizePumpingFraction = serverData.randomizePumpingFraction
	end
	if typeof(serverData.pumpingFractionMin) == "number" then
		state.pumpingFractionMin = math.clamp(serverData.pumpingFractionMin, 0.05, 0.95)
	end
	if typeof(serverData.pumpingFractionMax) == "number" then
		state.pumpingFractionMax = math.clamp(serverData.pumpingFractionMax, 0.05, 0.95)
	end
end

DroneMachinrMinigame.Start=function(session)
	local payload = session.payload
	local machineInstance
	if typeof(payload) == "table" then
		machineInstance = payload.machine
	end

	local droneState = {
		session = session,
		machine = machineInstance,
		period = basePeriod,
		pumpingFraction = basePumpingFraction,
		randomizePumpingFraction = false,
		pumpingFractionMin = droneConfig.PumpingFractionMin or 0.45,
		pumpingFractionMax = droneConfig.PumpingFractionMax or 0.75,
		segments = {},
		scrollPx = 0,
		nextSpawnScrollLeft = nil,
		nextKind = "Pumping",
		currentSegment = nil,
		holdActive = false,
		pressPrev = false,
		ignoreUntilRelease = false,
		pendingLeak = nil,
		running = true
	}

	session.state.period = droneState.period
	session.state.pumpingFraction = droneState.pumpingFraction

	function session.state._onUpdate(updateData)
		applyServerState(droneState, updateData)
	end

	if machineInstance then
		machineInstance:SetAttribute("DronePeriod", droneState.period)
	end

	local function getEstimatedReportInterval()
		local period = math.max(droneState.period, 0.05)
		local pumpingFraction = math.clamp(droneState.pumpingFraction, 0.05, 0.95)
		return period * pumpingFraction + period * (1 - pumpingFraction)
	end

	session.trove:Add(function()
		droneState.running = false
	end)

	task.spawn(function()
		while droneState.running and not session.completed do
			task.wait(getEstimatedReportInterval())
			if not droneState.running or session.completed then
				break
			end
			MachineMinigameSession.Respond(session.sessionId, "Perfect", {
				holdFraction = perfectHoldThreshold
			})
		end
	end)

	return true
end

DroneMachinrMinigame.OnUpdate=function(session, updateData)
	local onUpdateFn = session.state and session.state._onUpdate
	if typeof(onUpdateFn) == "function" then
		onUpdateFn(updateData)
	end
end
--]]

-- auto collect Stuffing
local function interactWithPrompt(prompt)
    if not prompt.Parent or prompt.Enabled == false then
        return
    end
    if prompt.HoldDuration == 0 then
        prompt:InputHoldBegin()
        task.wait()
        prompt:InputHoldEnd()
        return
    end
    prompt:InputHoldBegin()
    task.wait(prompt.HoldDuration)
    if prompt.Parent and prompt.Enabled then
        prompt:InputHoldEnd()
    end
end

local function isStuffingPrompt(prompt)
    return prompt:IsDescendantOf(StuffingFolder)
end

proximitysrv.PromptShown:Connect(function(prompt)
    if prompt.HoldDuration ~= 0 then
        prompt.HoldDuration = 0
    end
    if isStuffingPrompt(prompt) == false then
        return
    end
    task.spawn(function()
        interactWithPrompt(prompt)
    end)
end)

--proximitysrv.PromptHidden:Connect(function(prompt)
--end)
