-- INTERACTION POINTS
-- These are the objects that can be Interacted with in order to relieve a Drive

function get_entity_type()
	return "IPoint"
end

-- There are two specific elements at state here - the Interaction Type, and the amount it reduces the Drive
-- Both are Properties

-- Interaction type list:
-- 0: Null interaction (can be used for objects which become interactions later)
-- 1: Food (fridges etc)
-- 2: Rest (beds, etc)
-- 3: Warn (telephone)

interactionType = 0
Editor.setPropertyType("interactionType", Editor.FLOAT_PROPERTY) 

function getInteractionType()
	return interactionType
end

-- interaction drive reduction
-- -1 = completely reduce

driveReduction = -1
Editor.setPropertyType("driveReduction", Editor.FLOAT_PROPERTY)

function getDriveReduction()
	return driveReduction
end

function interact(entity)
-- There are two kinds of IPoint - Relievers and Doers. 
-- Relievers reduce a Drive, and Doers change the current game state in some significant way
	local drive = ""
	if(interactionType == 1) then
		drive = "Hunger"
	elseif(interactionType == 2) then
		drive = "Rest"
	elseif(interactionType == 3) then
		-- Todo: GAME OVER!
	end

	if(drive~="") then
		local env = LuaScript.getEnvironment(g_scene_lua_script, entity, 1)
		if(env ~= nil and env.changeDrive ~= nil and env.getDrive ~= nil) then
			value = env.getDrive(drive)
			if(drive_reduction == -1) then
				-- reduce drive to zero
				value = env.getDrive(drive)
				env.changeDrive(drive,-value)
			else
				env.changeDrive(drive,-driveReduction)
			end
		end
	end
end