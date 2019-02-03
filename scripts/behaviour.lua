-- AI character behaviour management
-- Handles memory, decision points
-- calls on npc_navigation.lua, sensorium.lua, and character.lua

dofile("scripts\\npc.lua")

-- BEHAVIOUR DESIGN
-- The final game will have distinct behaviour scripts to allow fine control of behaviours.
-- This version will instead set up the following Behaviours (from the doc):
 
-- Walk (Movement, Walk anim / Repeat, slow speed move to x,y location, stores a reference to a pathfinder result)
-- Run (Movement, Run anim / Repeat, fast speed move to x,y location, stores a reference to a pathfinder result)
-- Interact (Interaction, Interact anim / Single, returns result)
-- Idle (Idle, Idle anim / Repeat, triggers Decision Points, Pulls Stimuli)
-- Drag (Movement, Walk anim / Repeat, slow speed move to x,y location, stores a reference to a pathfinder result, moves other Character too)
-- Attack (Interaction, Attack anim / Single, store reference to target, triggers Being Attacked Response in target, Pushes Stimulus)
-- Being Attacked (Response, Flinch anim / Single, store reference to origin, calculate health deduction)

-- Structure of a Behaviour is:
-- Type (split update when behaviour run, replaced by different script updates)
-- Anim state triggered
-- Decision Point Frequency Base (modified by character stats)
-- Stimulus Push Range (0=do not push)
-- Stimulus Pull Range (modified by character stats, 0=do not pull)
-- (Optional) Location 
-- (Optional) Data

local behaviour_set = {}
current_behaviour = ""
current_anim = 0

-- The Behaviour Queue for this character
-- This contains the queued-up behaviours. We push (with table.insert) during a Decision, and pop when completed
-- the popped value (from table.remove) becomes our new current_behaviour.
-- if #behaviour_queue==0, we trigger a Decision Point by default
local behaviour_queue = {}

-- some Behaviours (eg Idle) allow characters to make Decisions during them. 
-- This ticker maintains the time (in seconds) until the next Decision.
local decision_ticker = 0.0

-- our base reluctance before we'll want to do anything. Characteristics can modify 
decision_reluctance = 4.0
Editor.setPropertyType("decision_reluctance", Editor.FLOAT_PROPERTY)

local Move_Type = 1
local Idle_Type = 2
local Interaction_Type = 3
local Response_Type = 4

local Anim_Walk = 1
local Anim_Idle = 2
local Anim_Run = 3
local Anim_Attack = 4
local Anim_Offhand = 5

function entity_log(output)
	local name = Engine.getEntityName(g_universe,this)
	Engine.logInfo(name .. ": " .. output)
end

function init()
	-- set up the available behaviour set
	entity_log("-- BEHAVIOUR SETUP --")
	behaviour_set = {
		Walk = { Type = Move_Type, Anim = Anim_Walk, Decision_Frequency = 0, Push_Range = 0, Pull_Range = 30, Location = nil, Data = nil},
		Run = { Type = Move_Type, Anim = Anim_Run, Decision_Frequency = 0, Push_Range = 0, Pull_Range = 10, Location = nil, Data = nil},
		Idle = { Type = Idle_Type, Anim = Anim_Idle, Decision_Frequency = 2.0, Push_Range = 0, Pull_Range = 30, Location = nil, Data = nil},
		Interact = { Type = Interact_Type, Anim = Anim_Offhand, Decision_Frequency = 0, Push_Range = 0, Pull_Range = 30, Location = nil, Data = nil},
--		Drag = { Type = Move_Type, Anim = Anim_Walk, Decision_Frequency = 0, Push_Range = 0, Pull_Range = 30, Location = nil, Data = nil},
		Attack = { Type = Interaction_Type, Anim = Anim_Attack, Decision_Frequency = 0, Push_Range = 0, Pull_Range = 30, Location = nil, Data = nil}
--		Attack_Response = { Type = Response_Type, Anim = Anim_Walk, Decision_Frequency = 0, Push_Range = 0, Pull_Range = 30, Location = nil, Data = nil},
	}

	-- set up default behaviour
	change_to_behaviour("Idle")

	entity_log("-- BEHAVIOUR SETUP END --")
end

function update(time_delta)
	local behaviour = behaviour_set[current_behaviour]
	if(behaviour ~= nil) then
		if(behaviour.Pull_Range > 0) then
			-- we want to pull stimuli during this animation
			local sensorium = LuaScript.getEnvironment(g_scene_lua_script, this, Scripts.SENSORIUM_SCRIPT)
			if sensorium ~= nil and sensorium.pull_stimuli ~= nil then
					sensorium.pull_stimuli()
			end
		end

		pushRange = behaviour.Push_Range
		if(pushRange > 0) then
			-- let everyone in range know we Did The Thing
			entity_log("Pushing Stimulus")
			pushStimulus(pushRange)
		end
	end
	
	if(decision_ticker > 0.0) then
		decision_ticker = decision_ticker - time_delta
		if(decision_ticker <= 0.0) then
			entity_log("Decision Triggered")
			decision_ticker = 0.0 
			decide()
		end
	end

end

function decide()
	-- we need to choose our next Behaviour.
	-- Sometimes this is determined by our Intent, sometimes there's an automatic Intent that comes next
	entity_log("-- Deciding --")

	local character_script = LuaScript.getEnvironment(g_scene_lua_script, this, Scripts.CHARACTER_SCRIPT)

	if (character_script ~= nil and character_script.hasCharacteristic ~= nil and character_script.listDrives ~= nil and character_script.getDrive ~= nil) then
		
		local reluctance = decision_reluctance
		if(character_script.hasCharacteristic("Idle")) then
			reluctance = reluctance + 10
		end

		entity_log("Action Reluctance:" .. reluctance)

		-- assemble a list of the probabilities of picking an (above-reluctance) Drive
		local wanted = {}
		local total = 0
		local drives = character_script.listDrives()

		for k,v in ipairs(drives) do
			val = character_script.getDrive(v)
			if((character_script.hasCharacteristic("Gluttonous")== true) and (v=="Hunger")) then val = val + 20 end
			if(val > reluctance) then
				total = total + val
				table.insert(wanted, {total,v})
			end
		end

		entity_log("Total possibility:" .. total)

		-- pick a Drive from the list
		local pick = math.random(0,total)
		for k,v in ipairs(wanted) do
			if(pick < v[1]) then 
				-- this is our chosen Drive!
				entity_log("Pre-Obey")
				obeyDrive(v[2])
				entity_log("Post-Obey")
			end
		end
	else
		entity_log("Something wasn't found")
	end

	entity_log("behaviour starting: " .. current_behaviour)
	
	local behaviour = behaviour_set[current_behaviour]

	-- entity_log("behaviour type:" .. behaviour)
	if (behaviour.Decision_Frequency > 0) then decision_ticker = behaviour.Decision_Frequency end

	entity_log("Behaviour Timer:" .. behaviour.Decision_Frequency)

	entity_log("-- End Decision --")
end

function obeyDrive(drive)
	-- this function connects Drives to Behaviours
	entity_log("-- Obeying Drive " .. drive .. "--")

	-- most of these fundamentally do the same thing - search the sensory memory for something that would work with it
	-- later versions will have two kinds of memory, sense memory and associative memory

	local sensorium_script = LuaScript.getEnvironment(g_scene_lua_script, this, Scripts.SENSORIUM_SCRIPT)
	local sense_memory = nil;
	if(sensorium_script ~= nil and sensorium_script.get_sense_memory ~=nil) then
		sense_memory = sensorium_script.get_sense_memory()
		if(sense_memory~=nil) then entity_log("Memories exist!") end
	end

	if(drive=="Hunger") then
		-- search sensory memory for food source
		if(sense_memory~=nil) then
			for k,v in ipairs(sense_memory) do
				-- if(v[")
			end
		end
	elseif(drive=="Contact") then
		-- search sensory memory for a person to talk to
	elseif(drive=="Curiosity") then
		-- choose 4-5 locations with no sensory information
	elseif(drive=="Investigation") then
		-- search sensory memory for items flagged "Strange", otherwise do same as Curiosity
	elseif(drive=="WarnTheWorld") then
		-- search sensory memory for Exit Points
	elseif(drive=="Escape") then
		-- move away from drive subject
	end

	entity_log("Drive Set")
	
end

function pushStimulus(range)
	entity_log("Pushing Stimuli to all entities in sight")
	currPos = get_vector(Engine.getEntityPosition(g_universe,  this))

	char_root = Engine.findByName(g_universe,-1,"char_root")
	if char_root == -1 then Engine.logInfo("char_root not found") end
	child = Engine.getFirstChild(g_universe, char_root)
	if child == -1 or child == nil then Engine.logInfo("No Children Found For char_root") end

	while child ~= nil and child ~= -1 do
		-- get the collider child of the character
		colldier_child = Engine.findByName(g_universe, child, "Collider")
		newPos = get_vector(Engine.getEntityPosition(g_universe, colldier_child))
		between = currPos - newPos
		dist = between:length()
		
		if dist < range then
			local sensorium = LuaScript.getEnvironment(g_scene_lua_script, child, Scripts.SENSORIUM_SCRIPT)
			if sensorium ~= nil and sensorium.pull_stimuli ~= nil then
				sensorium.push_stimulus(this, currPos)
			end
		end

		child = Engine.getNextSibling(g_universe, child)
	end
end

-- -----------------------------------------------------------------------------------
-- ADDING BEHAVIOURS 
-- -----------------------------------------------------------------------------------

function start_behaviour(newBehaviourName)
	current_behaviour = newBehaviourName
	local new_behaviour = behaviour_set[newBehaviourName]
	current_anim = new_behaviour.Anim
	
	-- start decision ticker (if needed)
	if (new_behaviour.Decision_Frequency > 0) then decision_ticker = new_behaviour.Decision_Frequency end
end

-- dump queue, force change to behaviour (use for reactions etc)
function change_to_behaviour(newBehaviourName)
	-- sanity check new behaviour
	local new_behaviour = behaviour_set[newBehaviourName]
	if (new_behaviour == nil ) then return end

	entity_log("Force Changing To Behavior:" .. newBehaviourName)

	-- dump old queue
	behaviour_queue = {}

	-- set new behaviour
	start_behaviour(newBehaviourName)
end

function queue_behaviour(newBehaviourName)
	-- if we don't currently have a behaviour, we need to start this one immediately
	-- otherwise we add it to our behaviour queue
	entity_log("Queueing Behaviour")
	if current_behaviour == nil then
		start_behaviour(newBehaviourName)
	else
		table.insert(behaviour_queue,newBehaviourName)
	end
end

-- -----------------------------------------------------------------------------------
-- ENDING BEHAVIOURS 
-- -----------------------------------------------------------------------------------

-- The animation controller is implemented as a network of possible animation state nodes
-- This can call a function when we enter or leave a node
-- Since we can set an animation to not repeat, we can use that leaving call to trigger a function here
-- This lets us know that animation is done and we can complete our action. 

function end_anim()
	entity_log("Ending Animation")
	-- (TODO) call the conclusion function for our behaviour

	end_behaviour()
end

-- Navigation calls onPathFinished on an entity which completes its path
-- This means we have concluded a Movement-type behaviour and should move to the next one.

function onPathFinished()
	entity_log("Ending Navigation")
	end_behaviour()
end

function end_behaviour()
	-- Switch on the Behaviour Type to determine what happens now
	local behaviour = behaviour_set[current_behaviour]

	if(behaviour.Type == Move_Type) then
		-- we need to make sure we've stopped
		Navigation.cancelNavigation(this)
	elseif(behaviour.Type == Idle_Type) then
		-- nothing special
	elseif(behaviour.Type == Interaction_Type) then
		-- trigger Interaction result depending on target
		targetEntity = behaviour.Data
		-- we determine what kind of target entity it is based on its parent
		parent = Engine.getParent(g_universe,targetEntity)
		parent_name = Engine.getEntityName(g_universe,targetEntity)
		if(parent_name == "object_root") then 
			-- this is an object for interacting with, so we call its Interact function with our Entity id
			-- (Example: The fridge calls changeDrive on the character script on this entity to reduce our Hunger.)
			local entityScript = LuaScript.getEnvironment(g_scene_lua_script, targetEntity, Scripts.ENTITY_SCRIPT)
			if(entityScript ~ nil and entityScript.interact ~= nil) then
				entityScript.interact(this)
			end
		end
	elseif(behaviour.Type == Response_Type) then
		-- The response updates us immediately, so once we're done with the response anim there's nothing more to do but move on to decide()
	end

	-- and move on to the next one
	next_behaviour()
end

function next_behaviour()
	entity_log("Moving To Next Behaviour")
	-- clear current Behaviour
	current_behaviour = nil
	-- Check to see if we have a queued behaviour
	if(#behaviour_queue > 0) then
		b = table.remove(behaviour_queue,1)
		start_behaviour(b)
	else
		decide()
	end
end