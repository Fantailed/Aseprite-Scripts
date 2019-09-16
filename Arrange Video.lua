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
local seq_num = 0
local sequences = {}

-- Add sequence by number
function AddSequence()
	-- Save entry changes between last + click and now
	local j = 1
	while d.data["tag_"..j] do
		sequences[j] = d.data["tag_"..j]
		j = j+1
	end

	d:close()
	d = Dialog("Arrange Sequences")
	
	-- Recreate old entries
	for i=1, #sequences do
		d:combobox{id="tag_"..i, label="Tag "..i..": ", option=sequences[i], options=tags}
	end
	-- Add new entry
	d:combobox{id="tag_"..#sequences+1, label="Tag "..#sequences+1 ..": ", options=tags}
	d:button{id="add", text="+", onclick=function() AddSequence() end}
	 :show()
end

-- Dialog widgets
d:label{id="help", label="", text="Arrange your tags"}
 :button{id="add", text="+", onclick=function() AddSequence() end}
 :show()
