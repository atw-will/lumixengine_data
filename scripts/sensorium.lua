-- Character Sensorium 
-- Draws raycasts to entities within a given sensory radius, and maintains a list of those entities 
-- This version works in 360, the final version will operate based on head position/rotation and awareness arc

local maf = require("scripts\\maf\\maf")

-- position from which raycasts are made
viewpoint = -1
Editor.setPropertyType("viewpoint", Editor.ENTITY_PROPERTY) 

-- auditory observation range
audioRange = 0.0
Editor.setPropertyType("audioRange", Editor.FLOAT_PROPERTY)

-- visual observation range
visualRange = 0.0
Editor.setPropertyType("visualRange", Editor.FLOAT_PROPERTY)

showDebugLine = true
Editor.setPropertyType("showDebugLine", Editor.BOOLEAN_PROPERTY)

local visualRangeObjects = {}
local visualSensed = {}
local audioSensed = {}

function init()
    clear()


end

function update(time_delta)
	-- display a debug line from the character to every object it can sense
	if(showDebugLine) then
		-- local position = Engine.getEntityPosition(g_universe, this)

		if viewpoint~=-1 then
			startPos = Engine.getEntityPosition(g_universe,  viewpoint)
		else
			startPos = Engine.getEntityPosition(g_universe, this)
		end

		-- draw lines in blue to visual contacts
		for index,sensed in ipairs(visualSensed) do
			local targetPos = get_Vec3(sensed["pos"])
			Renderer.addDebugLine(g_scene_renderer,startPos,targetPos, 0x0000FFFF, 0)
		end
		
		-- draw lines in green to audio contacts
		for index,sensed in ipairs(audioSensed) do
			local targetPos = get_Vec3(sensed["pos"])
			Renderer.addDebugLine(g_scene_renderer,startPos,targetPos, 0x00FF00FF, 0)
		end
	end
end


function clear()
	count = #visualRangeObjects
	for i=0, count do visualRangeObjects[i]=nil end

	count = #visualSensed
	for i=0, count do visualSensed[i]=nil end

	count = #audioSensed
	for i=0, count do audioSensed[i]=nil end
end

function get_vector(arrayVersion)
	return maf.vector(arrayVersion[1],arrayVersion[2],arrayVersion[3])
end

function get_Vec3(vectorVersion)
	return {vectorVersion.x, vectorVersion.y, vectorVersion.z}
end

function get_range()

	currPos = get_vector(Engine.getEntityPosition(g_universe,  this))
	-- check all objects stemming from map_root and char_root 
	
	map_root = Engine.findByName(g_universe,-1,"map_root")
	if map_root == -1 then Engine.logInfo("map_root not found") end
	child = Engine.getFirstChild(g_universe, map_root)
	if child == -1 or child == nil then Engine.logInfo("No Children Found For map_root") end
	
	while child ~= nil and child ~= -1 do
		newPos = get_vector(Engine.getEntityPosition(g_universe, child))
		between = currPos - newPos;
		dist = between:length()

		if dist < visualRange then
			table.insert(visualRangeObjects, {entity=child, distance=dist, pos=newPos})
		end

		if dist < audioRange then
			table.insert(audioSensed, {entity=child, distance=dist, pos=newPos})
		end
		
		child = Engine.getNextSibling(g_universe, child)
	end
			
	char_root = Engine.findByName(g_universe,-1,"char_root")
	if char_root == -1 then Engine.logInfo("char_root not found") end
	child = Engine.getFirstChild(g_universe, char_root)
	if child == -1 or child == nil then Engine.logInfo("No Children Found For char_root") end

	while child ~= nil and child ~= -1 do
		newPos = get_vector(Engine.getEntityPosition(g_universe, child))
		between = currPos - newPos;
		dist = between:length()
		
		if dist < visualRange then
			store = {entity=child, distance=dist, pos=newPos}
			table.insert(visualRangeObjects, store)
		end

		if dist < audioRange then
			store = {entity=child, distance=dist, pos=newPos}
			table.insert(audioSensed, store)
		end

		child = Engine.getNextSibling(g_universe, child)
	end

end

function check_LOS()
	local startPos = maf.vector(0,0,0)

	if viewpoint~=-1 then
		startPos = get_vector(Engine.getEntityPosition(g_universe,  viewpoint))
		Engine.logInfo("Viewpoint Entity:" .. viewpoint)
	else
		startPos = get_vector(Engine.getEntityPosition(g_universe, this))
		Engine.logInfo("No Viewpoint Entity:" .. this)
	end

	for index,target in ipairs(visualRangeObjects) do
		position = target["pos"]
		entity = target["entity"]
		dirVec = position - startPos
		dirVec:normalize()
		Engine.logInfo("Entity:" .. entity .. " Position:".. position.x .. "," .. position.y .. "," .. position.z .. " Direction:" .. dirVec.x .. "," .. dirVec.y .. "," .. dirVec.z)
		
		is_hit, hit_entity, hit_position = Physics.raycast(g_scene_physics, get_Vec3(startPos), get_Vec3(dirVec),1)
		if is_hit then
			Engine.logInfo("Hit Entity " .. hit_entity)
			if hit_entity == entity then 
				Engine.logInfo("Hit the right thing! Wow!")
				table.insert(visualSensed,target)
			end
        end
	end
end

function observe()
    Engine.logInfo("observing...")
	clear()
	get_range()
	check_LOS()
end