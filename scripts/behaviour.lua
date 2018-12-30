-- AI character behaviour management
-- Handles memory, decision points
-- calls on npc_navigation.lua, sensorium.lua, and character.lua

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
-- Anim set triggered, anim end class (repeat, single)
-- Triggers Decision Points? (Y/N)
-- Decision Point Frequency Base (modified by character stats)
-- Stimulus Push Range (0=do not push)
-- Stimulus Pull Range (modified by character stats, 0=do not pull)
-- (Optional) Location 
-- (Optional) Data

local behaviour_set = {}
current_behaviour = ""
current_anim = 0
local decision_ticker = 0.0

-- our base reluctance before we'll want to do anything. Characteristics can modify 
decision_reluctance = 25.0
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

function init()
	-- set up the available behaviour set
Engine.logInfo("-- BEHAVIOUR SETUP --")
	behaviour_set = {
		Walk = { Type = Move_Type, Anim = Anim_Walk, Anim_End = false, Triggers_Decision = false, Decision_Frequency = 0, Push_Range = 0, Pull_Range = 30, Location = nil, Data = nil},
		Run = { Type = Move_Type, Anim = Anim_Run, Anim_End = false, Triggers_Decision = false, Decision_Frequency = 0, Push_Range = 0, Pull_Range = 10, Location = nil, Data = nil},
		Idle = { Type = Idle_Type, Anim = Anim_Idle, Anim_End = false, Triggers_Decision = true, Decision_Frequency = 0.5, Push_Range = 0, Pull_Range = 30, Location = nil, Data = nil},
		Interact = { Type = Interact_Type, Anim = Anim_Offhand, Anim_End = false, Triggers_Decision = false, Decision_Frequency = 0, Push_Range = 0, Pull_Range = 30, Location = nil, Data = nil},
--		Drag = { Type = Move_Type, Anim = Anim_Walk, Anim_End = false, Triggers_Decision = false, Push_Range = 0, Pull_Range = 30, Location = nil, Data = nil},
		Attack = { Type = Interaction_Type, Anim = Anim_Attack, Anim_End = false, Triggers_Decision = false, Decision_Frequency = 0, Push_Range = 0, Pull_Range = 30, Location = nil, Data = nil}
--		Attack_Response = { Type = Response_Type, Anim = Anim_Walk, Anim_End = false, Triggers_Decision = false, Push_Range = 0, Pull_Range = 30, Location = nil, Data = nil},
	}

-- set up default behaviour
change_to_behaviour("Idle")

Engine.logInfo("-- BEHAVIOUR SETUP END --")
end

function update(time_delta)
	local behaviour = behaviour_set[current_behaviour]
	if(behaviour ~= nil) then
		if(behaviour.Pull_Range > 0) then
			-- we want to pull stimuli during this animation
			local env = LuaScript.getEnvironment(g_scene_lua_script, this, 1);
			if env ~= nil and env.pull_stimuli ~= nil then
					--Engine.logInfo("-- Pulling Stimuli --")
					env.pull_stimuli()
			end
		end

		pushRange = behaviour.Push_Range
		if(pushRange > 0) then
			-- let everyone in range know we Did The Thing
			pushStimulus(pushRange)
		end
	end
	
	if(decision_ticker > 0.0) then
		decision_ticker = decision_ticker - time_delta
		if(decision_ticker <= 0.0) then
			decision_ticker = 0.0 
			decide()
		end
	end

end

function end_anim()
	-- this is called from the animation controller when we complete a branch animation state
	-- Normally we return to Idle, unless our current Behaviour is set to "Make Decision On End"
	if(behaviour_set[current_behaviour].TriggersDecision) then
		decide()
	else
		change_to_behaviour("Idle")
	end
end

function decide()
	-- we need to choose our next Behaviour.
	-- Sometimes this is determined by our Intent, sometimes there's an automatic Intent that comes next
	Engine.logInfo("-- Deciding --")

	local character_script = LuaScript.getEnvironment(g_scene_lua_script, this, 1);
	if (character_script ~= nil and character_script.hasCharacteristic ~= nil and character_script.listDrives ~= nil and character_script.getDrive ~= nil) then
		
		local reluctance = decision_reluctance
		if(character_script.hasCharacteristic("Idle")) then
			reluctance = reluctance + 10
		end

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

		-- pick a Drive from the list
		local pick = math.random(0,total)
		for k,v in ipairs(wanted) do
			if(pick < v[1]) then 
				-- this is our chosen Drive!
				if(v[2] == "Idle") then 
					change_to_behaviour("Idle")
				else
					obeyDrive(v[2])
				end
			end
		end
	end

	local behaviour = behaviour_set[current_behaviour]
	if behaviour.Triggers_Decision then decision_ticker = behaviour.Decision_Frequency end

	Engine.logInfo("-- End Decision --")
end

function obeyDrive(drive)
	-- this function connects Drives to Behaviours
	Engine.logInfo("-- Obeying Drive " .. drive .. "--")
end

function pushStimulus(range)
	currPos = get_vector(Engine.getEntityPosition(g_universe,  this))

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
		
		if dist < range then
			local env = LuaScript.getEnvironment(g_scene_lua_script, child, 1);
			if env ~= nil and env.pull_stimuli ~= nil then
				env.push_stimulus(this, currPos)
			end
		end

		child = Engine.getNextSibling(g_universe, child)
	end
end

function change_to_behaviour(newBehaviourName)

local new_behaviour = behaviour_set[newBehaviourName]
if (new_behaviour == nil ) then return end
Engine.logInfo("Changing To Behavior:" .. newBehaviourName)
current_anim = new_behaviour.Anim
current_behaviour = newBehaviourName
if new_behaviour.Triggers_Decision then decision_ticker = new_behaviour.Decision_Frequency end
end

