local map
local plrsrv = game:GetService("Players")
local plr = plrsrv.LocalPlayer
local starterGui = game:GetService("StarterGui")
local localcharacter = plr.Character or plr.CharacterAdded:Wait()
local plrgui = plr:WaitForChild("PlayerGui")
local localroot = localcharacter:WaitForChild("HumanoidRootPart")
local panic=workspace:WaitForChild("Info"):WaitForChild("Panic")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local fjonestart = false

--workspace.Info.Panic
function isPanic()
    return panic.Value
end

function howfar(cframe1, cframe2)
    if cframe1 == plr then
        return (cframe1.Character.HumanoidRootPart.Position - cframe2.Position).Magnitude
    else
        return (cframe1.Position - cframe2.Position).Magnitude
    end
end

function getMap()
	if map and map.Parent then
		return map
	end
	map = workspace.CurrentRoom:FindFirstChildWhichIsA("Model");
	return map
end

function forceStop()
	local decoding = localcharacter.Decoding.Value
	if decoding ~= nil then
		decoding.Stats.StopInteracting:FireServer("Stop")
	end
	return not plrgui.ScreenGui.Menu.StopGenerator.Visible
end

-- Function to get model center
function getModelCenter(model)
	if not model or not model:IsA("Model") then return nil end

	local parts = {}
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			table.insert(parts, part)
		end
	end
	if #parts == 0 then return nil end

	local totalPosition = Vector3.zero
	for _, part in pairs(parts) do
		totalPosition = totalPosition + part.Position
	end
	return totalPosition / #parts
end

-- Function to get Fake Elevator Position
--workspace.CurrentRoom.StoryboardMap.FreeArea.FakeElevator.Base
--workspace.CurrentRoom.AquariumMap.FreeArea.FakeElevator.Door.NoClip_Collider
function getFakeElevatorCFrame()
	local freeArea = getMap():FindFirstChild("FreeArea")
	if freeArea then
		local fakeElevator = freeArea:FindFirstChild("FakeElevator")
		if fakeElevator and fakeElevator:IsA("Model") then
		    --[[
		    --unable finnaly notice new fake elevator change, so remove this.
		    if fakeElevator:FindFirstChild("Base") and fakeElevator.Base.CanCollide == false then
		        fakeElevator.Base.CanCollide = true
		    end
		    if fakeElevator:FindFirstChild("Door") and fakeElevator.Door:FindFirstChild("NoClip_Collider") and fakeElevator.Door.NoClip_Collider.CanCollide == true then
		        --fakeElevator.Door.NoClip_Collider.CFrame += Vector3.new(0,-27,0)
		        fakeElevator.Door.NoClip_Collider.CanTouch=false
		        fakeElevator.Door.NoClip_Collider.CanCollide=false
		    end
			--local center = getModelCenter(fakeElevator)
			--return center
			--]]
			return fakeElevator:GetPivot()+Vector3.new(0,3,0)
		end
	end
	return nil
end

function clientinvalidposdetect(playerposition)
	if not playerposition or typeof(playerposition) ~= "Vector3" then
		return false
	end
	--print("x,y,z=",playerposition.X,playerposition.Y,playerposition.Z)
	if playerposition.Magnitude > 2000 then
	    print("2000 fail")
		return false
	end
	--y<=50 will trigger tp, normal y is 100
	if playerposition.Y < 80 then
		print("playerposition.Y=",playerposition.Y)
		return false
	end
	if playerposition.X ~= playerposition.X or (playerposition.Y ~= playerposition.Y or playerposition.Z ~= playerposition.Z) then
		return false
	end
	local v8 = playerposition.X
	if math.abs(v8) ~= (1 / 0) then
		local v9 = playerposition.Y
		if math.abs(v9) ~= (1 / 0) then
			local v10 = playerposition.Z
			if math.abs(v10) ~= (1 / 0) then
				return true
			end
		end
	end
	print("final")
	return false
end

function teleportplr(cf)
	workspace.Gravity = 0
	localroot.AssemblyLinearVelocity = Vector3.zero
	localcharacter:PivotTo(cf)
	workspace.Gravity = 196.2
end

--有些时候玩家会在操作机器时被tp走，但却并没有停止提取，这就很糟，假设那个时候正好sprout的触手在那个机器旁，这样就一定会受伤
--workspace.CurrentRoom.GiftShop.Generators:GetChildren()[6].Stats.ActivePlayer==localplayer。
--workspace.InGamePlayers.sysadmin05fjone.Decoding==generator
--如果玩家在decoding，但是却和目标电机的距离过远，就一定是假传送(待办)

--另一种可能性：依旧是电机那里生成了触手，然后我检测到了进行了传送，但是只是把人送假电梯，真身还在被打。。，所以所有的safetp都应该同时做一次forcestop。(done)

--get all sprout tantacle cframes
function getDangerEntityCFrames()
	local cframes = {}
	local currentMap = getMap()
	if not currentMap then
		return cframes
	end

	local freeArea = currentMap:FindFirstChild("FreeArea")
	if not freeArea then
		return cframes
	end

	for _, sproutTantacle in ipairs(freeArea:GetChildren()) do
		if sproutTantacle.Name == "SproutTendril" and sproutTantacle:IsA("Model") then
			table.insert(cframes, sproutTantacle:GetPivot())
		end
	end
	for _,BassieRange in ipairs(workspace:GetChildren()) do
	    if BassieRange:IsA("Model") and (BassieRange.Name=="Small_Vines_Thick_Wheels" or BassieRange.Name=="HugeSpike_Circular_Attack") then
	        table.insert(cframes, BassieRange:GetPivot())
	    end
	end
	return cframes
end

local function dot(ax, ay, bx, by)
    return ax * bx + ay * by
end

local function pointInParallelogram(p, A, B, D)
    local APx, APy = p.X - A.X, p.Z - A.Z
    local ABx, ABy = B.X - A.X, B.Z - A.Z
    local ADx, ADy = D.X - A.X, D.Z - A.Z

    local dotAB = dot(APx, APy, ABx, ABy)
    local dotAD = dot(APx, APy, ADx, ADy)

    return dotAB >= 0 and dotAB <= dot(ABx, ABy, ABx, ABy)
        and dotAD >= 0 and dotAD <= dot(ADx, ADy, ADx, ADy)
end

local function isplayerinfake(plrposition, fakecframeArray)
    if fakecframeArray and plrposition then
        return pointInParallelogram(plrposition, fakecframeArray["corner1"].Position, fakecframeArray["corner2"].Position, fakecframeArray["corner3"].Position)
    else
        return false
    end
end

--workspace.CurrentRoom.EasterMap2.Generators:GetChildren()[9].Stats.Connie.Value == true
local function BooAllMachine(generatorfolder)
    for _, generator in generatorfolder:GetChildren() do
        local statsfolder = generator:FindFirstChild("Stats")
        local booconnie = statsfolder and statsfolder:FindFirstChild("Connie")
        booconnie.Value = true
    end
end

--workspace.CurrentRoom.EasterMap2.Monsters.ConnieMonster.Wandering.Value == true
local function DeBooAllMachine(generatorfolder, connie)
    local isghost = false
    if connie then
        local wandering = connie:FindFirstChild("Wandering")
        if not wandering.Value then
            isghost = true
        end
    end
    for _, generator in generatorfolder:GetChildren() do
        if isghost and howfar(generator:GetPivot(), connie:GetPivot()) <=10 then
            print("Fjone: connie is booing, leave one alone")
            continue
        end
        local statsfolder = generator:FindFirstChild("Stats")
        local connieboo = statsfolder and statsfolder:FindFirstChild("Connie")
        connieboo.Value = false
    end
end

task.spawn(
function()
	while true do
		if fjonestart and getMap() then
			--fix when spoted, there is a chance still doing machine
			local monstersFolder = getMap():FindFirstChild("Monsters")
			local GeneratorFolder = getMap():FindFirstChild("Generators")
			local playerposition = localcharacter.HumanoidRootPart.Position
			local fakeElevatorCFrame = getFakeElevatorCFrame()
			local fakeElevatorCFrameArray = nil
			local shoulddosafetp = false
			local isSeen = false
			local mylittleconnie = nil
			
			if fakeElevatorCFrame then
			    fakeElevatorCFrameArray = {
                    ["center"]=fakeElevatorCFrame,
                    ["corner1"]=fakeElevatorCFrame + Vector3.new(13, 0, 15),
                    ["corner2"]=fakeElevatorCFrame + Vector3.new(13, 0, -15),
                    ["corner3"]=fakeElevatorCFrame + Vector3.new(-15, 0, 15),
                    ["corner4"]=fakeElevatorCFrame + Vector3.new(-15, 0, -15)
                }
            end
			--boxten function again! :D so remove this force tp
			if monstersFolder then
				for _, monster in monstersFolder:GetChildren() do
				    -- if have connie, should be careful
				    if monster.Name=="ConnieMonster" then
				        mylittleconnie = monster
				    end
					if monster:FindFirstChild("ChasingValue") and monster.ChasingValue.Value == localcharacter then
					    isSeen = true
						task.wait(0.1)
						if not isplayerinfake(playerposition,fakeElevatorCFrameArray) then
							print("Fjone: not in fake")
							shoulddosafetp = true
						else
							print("Fjone: in fake")
							shoulddosafetp = false
						end
						forceStop()
					end
				end
			end

			-- ghost all machine if seen
			if isSeen then
			    BooAllMachine(GeneratorFolder)
			else
			    DeBooAllMachine(GeneratorFolder, mylittleconnie)
			end
			
			--fix tp to elevator front when fall out of map
			if not clientinvalidposdetect(playerposition) then
			    print("x,y,z=",playerposition.X,playerposition.Y,playerposition.Z)
				shoulddosafetp = true
			end
			--tp away if the player gets too close to any sprout tentacles or bassie spikes
			local dangerentity = getDangerEntityCFrames()
			for index, dangerEntityCFrame in ipairs(dangerentity) do
				local dangerDistance = howfar(plr, dangerEntityCFrame)
				if dangerDistance <=20 then
					print("dangerDistance[" .. index .. "]:", dangerDistance)
				end
				if dangerDistance <= 12 then
					shoulddosafetp = true
					break
				end
			end
			if not isPanic() and shoulddosafetp and fakeElevatorCFrame then
                for _, corner in pairs(fakeElevatorCFrameArray) do
                    local isSafe = true
                    for _, entity in pairs(dangerentity) do
                        if howfar(corner, entity)<=10 then
                        -- position too close to danger is invalid
                            isSafe=false
                            break
                        end
                    end
                    if isSafe then
                        teleportplr(corner)
                        forceStop()
                        break
                    end
                end
            end
		end
		task.wait(1/15)
	end
end
)


-- (Auto Struggle) Thx to Ali_hhjjj from riddance club 
loadstring(game:HttpGet("https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/refs/heads/main/auto%20struggle.lua"))()


-- UI
pcall(function()
    fjonestart=false
    plrgui.FjoneToggleUI:Destroy()
end)

local fjoneui = Instance.new("ScreenGui", plrgui)
fjoneui.Name = "FjoneToggleUI"
fjoneui.ResetOnSpawn = false

local function CreateToggle(config)
    config = config or {}

    local Text = config.Text or "Toggle"
    local Default = config.Default or false
    local Position = config.Position or UDim2.fromScale(0.8, 0.5)
    local Size = config.Size or UDim2.fromScale(0.25, 0.12)
    local Callback = config.Callback or function() end

    local CornerRadius = config.CornerRadius or 0.08
    local SwitchCornerRadius = config.SwitchCornerRadius or 1
    local state = Default
    
    local function createUiGradient(parent)
        local UIGradient= Instance.new("UIGradient", parent)
        UIGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(
                0,
                Color3.fromRGB(140, 140, 140)
            ),
            ColorSequenceKeypoint.new(
                1,
                Color3.fromRGB(81, 81, 81)
            )
        })
        UIGradient.Rotation = 90
    end
    
    --with border
    local MainBorder = Instance.new("Frame")
    MainBorder.Parent = fjoneui
    MainBorder.AnchorPoint = Vector2.new(0.5, 0.5)
    MainBorder.Position = Position
    MainBorder.Size = Size
    MainBorder.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    MainBorder.BorderSizePixel = 0
    Instance.new("UICorner", MainBorder).CornerRadius = UDim.new(CornerRadius, 0)
    
    local Main = Instance.new("Frame")
    Main.Parent = MainBorder
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.Position = UDim2.fromScale(0.5, 0.5)
    Main.Size = UDim2.fromScale(0.93, 0.78)
    Main.BackgroundColor3 = Color3.fromRGB(112, 112, 112)
    Main.BorderSizePixel = 0
    Instance.new("UICorner", Main).CornerRadius = UDim.new(CornerRadius, 0)
    createUiGradient(Main)

    local Label = Instance.new("TextLabel")
    Label.Parent = Main
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.fromScale(0.05, 0)
    Label.Size = UDim2.fromScale(0.6, 1)
    Label.Text = Text
    Label.Font = Enum.Font.GothamBold
    Label.TextScaled = true
    Label.TextColor3 = Color3.fromRGB(255,255,255)
    
    --with border
    local SwitchBorder = Instance.new("Frame")
    SwitchBorder.Parent = Main
    SwitchBorder.Size = UDim2.fromScale(0.25, 0.55)
    SwitchBorder.Position = UDim2.fromScale(0.7, 0.225)
    SwitchBorder.BackgroundColor3 = Color3.fromRGB(0,0,0)
    SwitchBorder.BorderSizePixel = 0
    Instance.new("UICorner", SwitchBorder).CornerRadius = UDim.new(1,0)

    --background
    local Switch = Instance.new("Frame")
    Switch.Parent = SwitchBorder
    Switch.Size = UDim2.fromScale(0.8, 0.7)
    Switch.AnchorPoint = Vector2.new(0.5, 0.5)
    Switch.Position = UDim2.fromScale(0.5, 0.5)
    Switch.BackgroundColor3 = Color3.fromRGB(112,112,112)
    Switch.BorderSizePixel = 0

    Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)
    createUiGradient(Switch)

    --knob
    local Knob = Instance.new("Frame")
    Knob.Parent = Switch
    Knob.Size = UDim2.fromScale(0.4, 0.9)
    Knob.Position = state and UDim2.fromScale(0.6,0.05) or UDim2.fromScale(0.03,0.05)
    Knob.BackgroundColor3 = state and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
    Knob.BorderSizePixel = 0

    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1,0)

    --button
    local Button = Instance.new("TextButton")
    Button.Parent = Switch
    Button.Size = UDim2.fromScale(1,1)
    Button.BackgroundTransparency = 1
    Button.Text = ""

    Button.MouseButton1Click:Connect(function()
        state = not state

        TweenService:Create(Knob, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
            Position = state and UDim2.fromScale(0.6,0.05) or UDim2.fromScale(0.03,0.05),
            BackgroundColor3 = state and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
        }):Play()

        Callback(state)
    end)

    --dragable
    local dragging = false
    local dragStart
    local frameStart

    Main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            frameStart = MainBorder.Position
        end
    end)

    Main.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - dragStart
            MainBorder.Position = UDim2.new(
                frameStart.X.Scale,
                frameStart.X.Offset + delta.X,
                frameStart.Y.Scale,
                frameStart.Y.Offset + delta.Y
            )
        end
    end)

    return {
        Set = function(v)
            state = v
            Knob.Position = v and UDim2.fromScale(0.42,0.1) or UDim2.fromScale(0.03,0.1)
            Knob.BackgroundColor3 = v and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
        end,
        Get = function()
            return state
        end,
        Destroy = function()
            Main:Destroy()
        end
    }
end

local autoToggle = CreateToggle({
    Text = "Fjone\nAutofarm Fix",
    Default = fjonestart,
    Position = UDim2.fromScale(0.78, 0.55),
    Size = UDim2.fromScale(0.18, 0.12),
    CornerRadius = 0.3,

    Callback = function(on)
        print("Fjone AutofarmFix:", on)
        fjonestart= on
    end
})

print("Fjone: everything ok")