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
local MachineMinigame = require(plr.PlayerScripts.Client.Interface.UIController.GameUI.MachineMinigame)

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
    FillTransparency=0.5,
    OutlineTransparency = 0,
    FillColor = Color3.fromRGB(255, 231, 135),
    OutlineColor = Color3.fromRGB(255, 231, 135)
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
    if machine.Name == "ItemCollection" then
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

local function onInit()
    for folder, rule in pairs(folder_rules) do
        for _, item in ipairs(folder:GetChildren()) do
		    rule.handler(item)
	    end
        folder.ChildAdded:Connect(rule.handler)
    end
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
local ori_getscore = MachineMinigame.GetMinigameScore

MachineMinigame.GetMinigameScore = function(self, ...)
    ori_getscore(self, ...)
    return "Perfect"
end

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
