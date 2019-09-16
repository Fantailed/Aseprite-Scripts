-- This script arranges your sprite for you to create small videos consisting of a sequence of tags

local aspr = app.activeSprite

if not aspr then
	app.alert("There is no sprite to arrange")
	return
end

local d = Dialog("Arrange Sequences")

-- Build list of available tags
local tags = {}
local tag_name_to_index = {}
for i=1, #aspr.tags do
	tags[#tags+1] = aspr.tags[i].name
	tag_name_to_index[string.lower(aspr.tags[i].name)] = i
end

-- Sequences
local sequences = {}

-- Save entry changes between clicks and create new dialog
function commitChanges()
	local i = 1
	while d.data["tag_"..i] do
		sequences[i] = d.data["tag_"..i]
		i = i+1
	end
end

-- Close current dialog and create a new copy that can still be changed
function recreateEntries()
	d:close()
	d = Dialog("Arrange Sequences")
	for i=1, #sequences do
		d:combobox{id="tag_"..i, label="Tag "..i..": ", option=sequences[i], options=tags}
		 :button{id="rm_"..i, text="-", onclick=function() rmSequence(i) end}
	end
end

-- Add sequence to the end of the list
function addSequence()
	commitChanges()
	recreateEntries()
	d:combobox{id="tag_"..#sequences+1, label="Tag "..#sequences+1 ..": ", options=tags}
	 :button{id="rm_"..#sequences+1, text="-", onclick=function() rmSequence(#sequences+1) end}
	 :button{id="add", text="+", onclick=function() addSequence() end}
	 :show()
end

-- Remove sequence from anywhere in the list
function rmSequence(nr)
	-- Commit previous additions if applicable
	commitChanges()
	-- Delete entries and adjust list
	table.remove(sequences, nr)
	while d.data["tag_"..nr] do
		d.data["tag_"..nr] = d.data["tag_"..nr+1]
		nr = nr+1
	end
	-- Recreate panel without that dialog
	recreateEntries()
	d:button{id="add", text="+", onclick=function() addSequence() end}
	 :show()
end

-- Dialog widgets
d:label{id="help", label="", text="Arrange your tags"}
 :button{id="add", text="+", onclick=function() addSequence() end}
 :show()






















