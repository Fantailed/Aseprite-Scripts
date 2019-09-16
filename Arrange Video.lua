-- This script arranges your sprite for you to create small videos consisting of a sequence of tags

--[[ Struct for passing the arguments from the UI to the backend
     name (String of the name of the animation)
     loop (Amount of times the animation should be played)
     etc...
--]]

local aspr = app.activeSprite

if not aspr then
	app.alert("There is no sprite to arrange")
	return
end

local d = Dialog("Arrange Sequences")

-- Build list of available tags
local tag_names = {}
local tag_name_to_index = {}
for i=1, #aspr.tags do
	tag_names[#tag_names+1] = aspr.tags[i].name
	tag_name_to_index[string.lower(aspr.tags[i].name)] = i
end

-- Sequences struct consisting of the name of the tag and a number of loops
local tag_sequence = {}

-- Save entry changes between clicks and create new dialog
function commitChanges()
	local i = 1
	while d.data["tag_"..i] do
		tag_sequence[i].tag = d.data["tag_"..i]
		tag_sequence[i].loop = d.data["loop_"..i]
		i = i+1
	end
end

-- Create new dialogue from saved sequence
function recreateEntries()
	d:close()
	d = Dialog("Arrange Sequences")
	d:separator("Arrange your tags")

	if #tag_sequence == 0 then
		d:button{id="add_"..1, label="Add Tag: ", text="+", onclick=function() addSequence() end}
	else
		for i=1, #tag_sequence do
			d:combobox{id="tag_"..i, label="Tag "..i..": ", option=tag_sequence[i].tag, options=tag_names}
			 :number{id="loop_"..i, label="Loops: ", text=tostring(tag_sequence[i].loop), decimals=0}
			 :button{id="rm_"..i, text="-", onclick=function() rmSequence(i) end}
			 :button{id="add_"..i, text="+", onclick=function() addSequence(i) end}
		end
	end

	d:separator()
	 :button{id="export", text="Export"}
	 :show()
end

-- Add sequence to the end of the list
function addSequence(nr)
	nr = nr or 1
	-- Accept current state of dialog before moving on
	commitChanges()
	-- Add entries and adjust list
	if nr >= #tag_sequence then
		table.insert(tag_sequence, {tag=tag_names[1], loop="1"})
	else
		table.insert(tag_sequence, nr+1, {tag=tag_names[1], loop="1"})
	end
	recreateEntries()
end

-- Remove sequence from anywhere in the list
function rmSequence(nr)
	nr = nr or #sequence
	-- Accept current state of dialog before moving on
	commitChanges()
	-- Delete entries and adjust list
	table.remove(tag_sequence, nr)
	-- Recreate panel without that dialog
	recreateEntries()
end

-- Dialog widgets
d:separator("Arrange your tags")
 :button{id="add", label="Add Tag: ", text="+", onclick=function() addSequence() end}
 :show()






























