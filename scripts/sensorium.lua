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

-- determine if we show the observation lines when we see something
showAudioDebugLine = true
Editor.setPropertyType("showAudioDebugLine", Editor.BOOLEAN_PROPERTY)

showVisualDebugLine = true
Editor.setPropertyType("showVisualDebugLine", Editor.BOOLEAN_PROPERTY)

showMemoryDebugLine = true
Editor.setPropertyType("showMemoryDebugLine", Editor.BOOLEAN_PROPERTY)

-- these tables contain the sensory data and are cleared every time there is a sense event
-- format : {entity, distance, position} in array format 
local visualRangeObjects = {}
local visualSensed = {}
local audioSensed = {}

-- this table contains the sensory memory and is updated but not cleared when there is a sense event
-- format : {entity, position, age} keyed by entity id
local memorySense = {}

function init()
    clear_memory()
	clear_senses()
end

function update(time_delta)
	-- age all the memories

	for key,memory in pairs(memorySense) do
		Engine.logInfo("Ageing Memory:" .. key)
		memory["age"] = memory["age"] + time_delta
		Engine.logInfo("Memory " .. key .. " aged to " .. memory["age"])
	end

	-- display a debug line from the character to every object it can sense
	if viewpoint~=-1 then
		startPos = Engine.getEntityPosition(g_universe,  viewpoint)
	else
		startPos = Engine.getEntityPosition(g_universe, this)
	end

	if(showVisualDebugLine) then
		-- draw lines in red to visual contacts
		for index,sensed in ipairs(visualSensed) do
			local targetPos = get_Vec3(sensed["position"])
			Renderer.addDebugLine(g_scene_renderer,startPos,targetPos, 0xFFFF0000, 0)
		end
	end	

	if(showAudioDebugLine) then
		-- draw lines in blue to audio contacts
		for index,sensed in ipairs(audioSensed) do
			local targetPos = get_Vec3(sensed["position"])
			-- colour is ARGB
			Renderer.addDebugLine(g_scene_renderer,startPos,targetPos, 0xFF0000FF, 0)
		end
	end

	if(showMemoryDebugLine) then
		for index,memory in pairs(memorySense) do
			local targetPos = get_Vec3(memory["position"])
			Renderer.addDebugLine(g_scene_renderer, startPos, targetPos, 0xFF00FF00, 0)
		end
	end
end


function clear_senses()
	count = #visualRangeObjects
	for i=0, count do visualRangeObjects[i]=nil end

	count = #visualSensed
	for i=0, count do visualSensed[i]=nil end

	count = #audioSensed
	for i=0, count do audioSensed[i]=nil end
end

function clear_memory()
	for key,memory in pairs(memorySense) do memorySense[key] = {} end
end

function get_vector(arrayVersion)
	return maf.vector(arrayVersion[1],arrayVersion[2],arrayVersion[3])
end

function get_Vec3(vectorVersion)
	return {vectorVersion.x, vectorVersion.y, vectorVersion.z}
end

function pull_get_range()

	currPos = get_vector(Engine.getEntityPosition(g_universe,  this))
	-- check all objects stemming from object_root and char_root 
	
	object_root = Engine.findByName(g_universe,-1,"object_root")
	if object_root == -1 then Engine.logInfo("object_root not found") end
	child = Engine.getFirstChild(g_universe, object_root)
	if child == -1 or child == nil then Engine.logInfo("No Children Found For object_root") end
	
	while child ~= nil and child ~= -1 do
		newPos = get_vector(Engine.getEntityPosition(g_universe, child))
		between = currPos - newPos;
		dist = between:length()

		if dist < visualRange then
			table.insert(visualRangeObjects, {entity=child, distance=dist, position=newPos})
		end

		if dist < audioRange then
			table.insert(audioSensed, {entity=child, distance=dist, position=newPos})
		end
		
		child = Engine.getNextSibling(g_universe, child)
	end
			
	char_root = Engine.findByName(g_universe,-1,"char_root")
	if char_root == -1 then Engine.logInfo("char_root not found") end
	child = Engine.getFirstChild(g_universe, char_root)
	if child == -1 or child == nil then Engine.logInfo("No Children Found For char_root") end

	while child ~= nil and child ~= -1 do
		-- get the collider child of the character
		colldier_child = Engine.findByName(g_universe, child, "Collider")
		newPos = get_vector(Engine.getEntityPosition(g_universe, colldier_child))
		between = currPos - newPos;
		dist = between:length()
		
		if dist < visualRange then
			store = {entity=child, distance=dist, position=newPos}
			table.insert(visualRangeObjects, store)
		end

		if dist < audioRange then
			store = {entity=child, distance=dist, position=newPos}
			table.insert(audioSensed, store)
		end

		child = Engine.getNextSibling(g_universe, child)
	end

end

function pull_check_LOS()
	local startPos = maf.vector(0,0,0)

	if viewpoint~=-1 then
		startPos = get_vector(Engine.getEntityPosition(g_universe,  viewpoint))
	else
		startPos = get_vector(Engine.getEntityPosition(g_universe, this))
	end

	for index,target in ipairs(visualRangeObjects) do
		position = target["position"]
		entity = Engine.findByName(g_universe, target["entity"], "Collider")
		if (entity==-1) then
			entity = target["entity"]
		end
		dirVec = position - startPos
		dirVec:normalize()
				
		is_hit, hit_entity, hit_position = Physics.raycast(g_scene_physics, get_Vec3(startPos), get_Vec3(dirVec),0)
		if is_hit then
			this_entity = Engine.findByName(g_universe, this, "Collider")
			if (hit_entity == entity) and not (hit_entity == this_entity) then 
				table.insert(visualSensed,target)
			end
        end
	end
end

function update_memory()
	for index,target in ipairs(visualSensed,target) do
		entity = target["entity"]
		position = target["position"]
		if memorySense[entity] == nil then
			Engine.logInfo("Making Memory:" .. entity)
			entry = {entity = entity, position = position, age = 0.0}
			memorySense[entity] = entry
		else
			Engine.logInfo("Updating Memory:" .. entity)
			memorySense[entity].position = position
			memorySense[entity].age = 0.0
		end
	end
end

function pull_stimuli()
	clear_senses()
	pull_get_range()
	pull_check_LOS()
	update_memory()
end

function push_stimulus(entity, position)
	if memorySense[entity] == {} then
		entry = {entity = entity, position = position, age = 0.0}
		memorySense[entity] = entry
	else
		memorySense[entity].position = position
		memorySense[entity].age = 0.0
	end
end