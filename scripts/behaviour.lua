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
-- Stimulus Push Range (0=do not push)
-- Stimulus Pull Range (modified by character stats, 0=do not pull)
-- (Optional) Location 
-- (Optional) Data

local behaviour_set = {}
current_behaviour = ""
current_anim = 0

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
		Walk = { Type = Move_Type, Anim = Anim_Walk, Anim_End = false, Triggers_Decision = false, Push_Range = 0, Pull_Range = 30, Location = nil, Data = nil},
		Run = { Type = Move_Type, Anim = Anim_Run, Anim_End = false, Triggers_Decision = false, Push_Range = 0, Pull_Range = 10, Location = nil, Data = nil},
		Idle = { Type = Idle_Type, Anim = Anim_Idle, Anim_End = false, Triggers_Decision = false, Push_Range = 0, Pull_Range = 30, Location = nil, Data = nil},
		Interact = { Type = Interact_Type, Anim = Anim_Offhand, Anim_End = false, Triggers_Decision = false, Push_Range = 0, Pull_Range = 30, Location = nil, Data = nil},
--		Drag = { Type = Move_Type, Anim = Anim_Walk, Anim_End = false, Triggers_Decision = false, Push_Range = 0, Pull_Range = 30, Location = nil, Data = nil},
		Attack = { Type = Interaction_Type, Anim = Anim_Attack, Anim_End = false, Triggers_Decision = false, Push_Range = 0, Pull_Range = 30, Location = nil, Data = nil}
--		Attack_Response = { Type = Response_Type, Anim = Anim_Walk, Anim_End = false, Triggers_Decision = false, Push_Range = 0, Pull_Range = 30, Location = nil, Data = nil},
	}

-- set up default behaviour
change_to_behaviour("Idle")

Engine.logInfo("-- BEHAVIOUR SETUP END --")
end

function update(time_delta)
	
end

function change_to_behaviour(newBehaviourName)

local new_behaviour = behaviour_set[newBehaviourName]
if (new_behaviour == {} ) then return end
Engine.logInfo("Changing To Behavior:" .. newBehaviourName)
current_animation = new_behaviour.Anim
current_behaviour = newBehaviourName
end

