local plrsrv = game:GetService("Players")
local replicated = game:GetService("ReplicatedStorage")
local userinputservice = game:GetService("UserInputService")
local plr = plrsrv.LocalPlayer
local localcharacter = plr.Character or plr.CharacterAdded:Wait()
local plrgui = plr:WaitForChild("PlayerGui")
local screengui = plrgui:FindFirstChild("ScreenGui")
local RunService = game:GetService("RunService")
local lighting=game:GetService("Lighting")

local RejectFolder=workspace:WaitForChild("Enemies")
local MachineFolder=workspace:WaitForChild("Interacts")
local ItemFolder=workspace:WaitForChild("Tools")
local PlayerFolder=workspace:WaitForChild("Characters")
local StuffingFolder=workspace:WaitForChild("Pickup"):WaitForChild("Stuffing")

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
	        highlighteffect.FillTransparency=0.7
	        highlighteffect.OutlineTransparency = 0.3
	        highlighteffect.FillColor = Color3.fromRGB(255, 50, 50)
	        highlighteffect.OutlineColor = Color3.fromRGB(255, 149, 0)
	    end
	)
	highlighteffect:GetPropertyChangedSignal("DepthMode"):Connect(
	    function()
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
            highlighteffect.FillTransparency=1
	        highlighteffect.OutlineTransparency = 1
            return
        end
	    highlighteffect.FillTransparency=0.7
	    highlighteffect.OutlineTransparency = 0.3
	    highlighteffect.FillColor = Color3.fromRGB(110, 125, 255)
	    highlighteffect.OutlineColor = Color3.fromRGB(115, 0, 255)
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
    local highlighteffect=Instance.new("Highlight")
    highlighteffect.FillTransparency=0.7
    highlighteffect.OutlineTransparency=0.1
	highlighteffect.FillColor = Color3.fromRGB(30, 144, 255)
    fjonehighlight(stuffing, highlighteffect)
end

--workspace.Interacts.ItemCollection:GetChildren()[13]

local function highlightItem(item)
    if itemblacklist(item) == true then
        return
    end
    local highlighteffect=Instance.new("Highlight")
    highlighteffect.FillTransparency=0.7
    highlighteffect.OutlineTransparency=0.1
	highlighteffect.FillColor = Color3.fromRGB(30, 144, 255)
    fjonehighlight(item, highlighteffect)
end

local function highlightPlayer(player)
    if player == localcharacter then
        return
    end
    local highlighteffect=Instance.new("Highlight")
    highlighteffect.FillTransparency=0.7
	highlighteffect.OutlineTransparency = 0.3
	highlighteffect.FillColor = Color3.fromRGB(0, 128, 0)
	highlighteffect.OutlineColor = Color3.fromRGB(0, 100, 0)
    fjonehighlight(player, highlighteffect)
end


local function Fjone_highlightFolder(dir)
	local list = dir:GetChildren()
	local highlightfunc = nil
	if dir==RejectFolder then
	    highlightfunc=highlightReject
	elseif dir==MachineFolder then
	    highlightfunc=highlightMachine
	elseif dir==ItemFolder then
	    highlightfunc=highlightItem
	elseif dir==PlayerFolder then
	    highlightfunc=highlightPlayer
	elseif dir==StuffingFolder then
	    highlightfunc=highlightStuffing
	end
	for itemidx in list do
		highlightfunc(list[itemidx])
	end
end

local function onInit()
    Fjone_highlightFolder(RejectFolder)
    Fjone_highlightFolder(MachineFolder)
    Fjone_highlightFolder(ItemFolder)
    Fjone_highlightFolder(PlayerFolder)
    Fjone_highlightFolder(StuffingFolder)
    RejectFolder.ChildAdded:Connect(highlightReject)
    MachineFolder.ChildAdded:Connect(highlightMachine)
    ItemFolder.ChildAdded:Connect(highlightItem)
    PlayerFolder.ChildAdded:Connect(highlightPlayer)
    StuffingFolder.ChildAdded:Connect(highlightStuffing)
end

onInit()

--infinite stamina

