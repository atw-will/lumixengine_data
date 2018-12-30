-- AI character information
-- I've done this in a rather sub-optimal way, with one script instance per character
-- We could just as easily have all this in a single global table and reference it by entity as key
-- But this should be easier to understand

local Data = { 
	Attributes = {
				  Strength = {},
				  Speed = {}, 
				  Toughness = {},
				  Intelligence = {}
				  },
	Characteristics = {},
	Drives = {},
	Opinions = {}
}

-- Basic human biological needs are universal and not dependent on Characteristics 
local basic_needs = { Hunger=10.0 } -- we will add Sleep later. Rest will be based on activity rate

-- the counter table ticks down over time. 
-- When it reaches 0, the name of the counter is added as a Drive at the lowest level,
-- or otherwise the Drive is incremented
local counters = {}

function init()
	Engine.logInfo("-- CHARACTER SETUP --")
	generate_character()
	Engine.logInfo("-- CHARACTER SETUP END --")
end

function addCounter(name, time)
	counters[name] = time
end

function update(time_delta)

-- run all the counters
	for key, value in pairs(counters) do
		counters[key] = counters[key] - time_delta
		if counters[key] < 0.0 then
			-- add/increment the drive and drop the counter
			increaseDrive(key)
			counters[key] = nil
		end
	end

-- Basic human needs will always get re-added
	for need, time in pairs(basic_needs) do
		if(counters[need] == nil) then counters[need] = time end
	end
end

-- ----------------------------------------
-- ATTRIBUTES
-- Numerical values that affect actions taken in the game
-- Strength affects attack damage
-- Toughness affects damage mitigation
-- Intelligence affects senses
-- Speed affects running ability
-- All four can potentially be defences against Vectors 
-- ----------------------------------------
function setAttribute(attribute, value)
	Data["Attributes"][attribute] = value
end

function strength()
	return Data["Attributes"]["Strength"]
end

function speed()
	return Data["Attributes"]["Speed"]
end

function intelligence()
	return Data["Attributes"]["Intelligence"]
end

function toughness()
	return Data["Attributes"]["Toughness"]
end

-- ----------------------------------------
-- CHARACTERISTICS
-- Text flags which indicate specific things about the character
-- These do not affect Behaviours directly, although many create
-- Opinions and/or Drives. They can also affect Tests and Conversations.
-- ----------------------------------------
function setCharacteristic(newChar)
	Data["Characteristics"][newChar] = true
end

function hasCharacteristic(c)
	local characteristic = Data["Characteristics"][c]
	if(characteristic==nil) then
		return false
	else
		return characteristic
	end
end

function removeCharacteristic(c)
	Data["Characteristics"][c] = nil
end

-- get the characteristic set for this character 
-- (since the characteristics are a free set rather than a fixed flag list,
-- we need the ability to list them)
function listCharacteristics()
	local keyset={}
	local n=0

	for k,v in pairs(Data["Characteristics"]) do
		n=n+1
		keyset[n]=k
	end

	return keyset
end

-- ----------------------------------------
-- DRIVES
-- Drives are the character's desires, wants and needs.
-- Drives are the primary element that affects Behaviours.
-- They are usually generated either automatically over time (eg Hunger) or 
-- as a result of a Characteristic.
-- The value is used as a priority when choosing a Behaviour
-- ----------------------------------------
function increaseDrive(drive)
	if(Data["Drives"][drive] == nil) then
		Data["Drives"][drive] = 1
	else
		Data["Drives"][drive] = Data["Drives"][drive] + 1
	end
	Engine.logInfo("Increased Drive:" .. drive .. " to " .. Data["Drives"][drive])
end

function setDrive(drive, value)
	Data["Drives"][drive] = value
end

function getDrive(drive)
	local d = Data["Drives"][drive]
	if(d==nil) then
		return false
	else
		return d
	end
end

function removeDrive(c)
	Data["Characteristics"][c] = nil
end

-- get the drive set for this character 
-- (since the drives are a free set rather than a fixed flag list,
-- we need the ability to list them)
function listDrives()
	local keyset={}
	local n=0

	for k,v in pairs(Data["Drives"]) do
		n=n+1
		keyset[n]=k
	end

	return keyset
end

-- ----------------------------------------
-- OPINIONS
-- Opinions are emotional valences attached to specific and general things
-- For the purposes of this, there will be no general opinions, only specific entities
-- (but we can add that later pretty easily)
-- Opinions factor into Decision Points along with Drives, and also greatly affect Conversations
-- ----------------------------------------

function setOpinion(targetEntity, opinion)
	-- we actually index by the Entity, since that'll be unique per Character
	Data["Opinions"][targetEntity] = opinion
end

function removeOpinion(targetEntity)
	Data["Opinions"][targetEntity] = nil
end

function getOpinion(targetEntity)
	return Data["Opinions"][targetEntity]
end

-- we don't usually list opinions, so there's no function for that

-- ----------------------------------------
-- CHARACTER CREATION
-- This early version has a strictly limited set of Characteristics, Drives and Opinions
-- Attributes are set between 4 and 7. 
-- Each Characteristic has a specific chance of occurring. The final version will also allow for mutually incompatible etc.
-- (We do not include "Aware" or "Alerted" or any other contextual Characteristic, only the innate ones)
-- ----------------------------------------

function generate_character()
	
	-- Characteristics table! Add new Characteristics and their probabilities here
	local characteristics = {	{"Curious", 0.1}, 
								{"Loner", 0.1},
								{"Idle", 0.2},
								{"Gluttonous", 0.1},
								{"Sharp-Eyed", 0.1},
								{"Sharp-Eared", 0.1} }

	-- now randomly generate each attribute
	for k,v in pairs(Data.Attributes) do
		Data.Attributes[k] = math.random(4,7)
	end

	-- and randomly determine if each characteristic is present
	for i = 1,6 do
		char = characteristics[i]
		if(math.random() <= char[2]) then
			setCharacteristic(char[1])
		end
	end
end