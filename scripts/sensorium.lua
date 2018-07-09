-- Character Sensorium 
-- Draws raycasts to entities within a given sensory radius, and maintains a list of those entities 
-- This version works in 360, the final version will operate based on head position/rotation and awareness arc

-- position from which raycasts are made
viewpoint = -1
Editor.setPropertyType("viewpoint", Editor.ENTITY_PROPERTY) 

-- auditory observation range
audioRange = 0.0
Editor.setPropertyType("audioRange", Editor.FLOAT_PROPERTY)

-- visual observation range
visualRange = 0.0
Editor.setPropertyType("visualRange", Editor.FLOAT_PROPERTY)

local visualRangeObjects = {}
local visualSensed = {}
local audioSensed = {}

function init()
    
end

function get_range()

    visualSensed = {}
	visualRangeObjects = {}
	audioSensed = {}

	currPos = Engine.getEntityPosition(this)

	-- check all objects stemming from map_root and char_root 
	
	map_root = Engine.findByName(g_universe,-1,"map_root")
	child = Engine.getFirstChild(g_universe, map_root)
	while child ~= -1 do
		newPos = Engine.getEntityPosition(child)
		between = currPos - newPos
		dist = sqrt(between.x * between.x + between.y * between.y + between.z * between.z )
		if dist < visualRange then table.insert(visualRangeObjects, {entity=child, distance=dist, pos=newPos}) end
		if dist < audioRange then table.insert(audioSensed, {entity=child, distance=dist, pos=newPos}) end
	end
			
	char_root = Engine.findByName(g_universe,-1,"char_root")
	child = Engine.getFirstChild(g_universe, char_root)
	while child ~= -1 do
		newPos = Engine.getEntityPosition(child)
		between = currPos - newPos
		dist = sqrt(between.x * between.x + between.y * between.y + between.z * between.z )
		if dist < visualRange then table.insert(visualRangeObjects, {entity=child, distance=dist, pos=newPos}) end
		if dist < audioRange then table.insert(audioSensed, {entity=child, distance=dist, pos=newPos}) end
	end
end

function check_LOS()
	
	if viewpoint==-1 then
		startPos = Engine.getEntityPosition(viewpoint)
	else
		startPos = Engine.getEntityPosition(this)
	end

	for target in visualRangeObjects do
		dirVec = target[pos] - startPos
		is_hit, hit_entity, hit_position = Physics.raycast(g_scene_physics, startPos, dirVec)
		if is_hit and hit_entity == target[entity] then 
            visualSensed.insert(target)
        end
	end
end

function observe()
	get_range()
	check_LOS()
end