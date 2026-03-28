local map
local plrsrv = game:GetService("Players")
local plr = plrsrv.LocalPlayer
local localcharacter = plr.Character or plr.CharacterAdded:Wait()
local plrgui = plr:WaitForChild("PlayerGui")
local localroot = localcharacter:WaitForChild("HumanoidRootPart")
local panic=workspace:WaitForChild("Info"):WaitForChild("Panic")

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
		    if fakeElevator:FindFirstChild("Base") and fakeElevator.Base.CanCollide == false then
		        fakeElevator.Base.CanCollide = true
		    end
		    if fakeElevator:FindFirstChild("Door") and fakeElevator.Door:FindFirstChild("NoClip_Collider") then
		        fakeElevator.Door.NoClip_Collider:Destroy()
		    end
			--local center = getModelCenter(fakeElevator)
			--return center
			return fakeElevator:GetPivot()+Vector3.new(0,3,0)
		end
	end
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

print("Fjone: everything ok")
task.spawn(
function()
	while true do
		if getMap() then
			--fix when spoted, there is a chance still doing machine
			local monstersFolder = getMap():FindFirstChild("Monsters")
			local playerposition = localcharacter.HumanoidRootPart.Position
			local fakeElevatorCFrame = getFakeElevatorCFrame()
			local shoulddosafetp = false
			if monstersFolder then
				for _, monster in monstersFolder:GetChildren() do
					if monster:FindFirstChild("ChasingValue") and monster.ChasingValue.Value == localcharacter then
						forceStop()
						shoulddosafetp = true
					end
				end
			end
			--fix tp to elevator front when fall out of map
			if not clientinvalidposdetect(playerposition) then
			    print("x,y,z=",playerposition.X,playerposition.Y,playerposition.Z)
				shoulddosafetp = true
			end
			--tp away if the player gets too close to any sprout tantacle
			local dangerentity = getDangerEntityCFrames()
			for index, dangerEntityCFrame in ipairs(dangerentity) do
				local dangerDistance = howfar(plr, dangerEntityCFrame)
				if dangerDistance <=20 then
					print("dangerDistance[" .. index .. "]:", dangerDistance)
				end
				if dangerDistance <= 5 then
					shoulddosafetp = true
					break
				end
			end
			if not isPanic() and shoulddosafetp and fakeElevatorCFrame then
			    local fakeElevatorCFrameArray = {
                    ["center"]=fakeElevatorCFrame,
                    ["corner1"]=fakeElevatorCFrame + Vector3.new(13, 0, 15),
                    ["corner2"]=fakeElevatorCFrame + Vector3.new(13, 0, -15),
                    ["corner3"]=fakeElevatorCFrame + Vector3.new(-15, 0, 15),
                    ["corner4"]=fakeElevatorCFrame + Vector3.new(-15, 0, -15)
                }
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