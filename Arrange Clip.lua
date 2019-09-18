--[[ 
	DESCRIPTION
	
	This script re-arranges your sprite for you to create small clips out of the tagged animations you have.
	Just define which tags you want to be played one after the other and how many times each of them should be looped.
	Upon pressing "Generate", it will create a new .aseprite file with all the frames to be played put in explicitly.
	
	IMPLEMENTATION DETAILS
	
	User tag options and struct for passing the arguments from the UI to the backend:
		- name (String of the name of the animation)
		- loop (Amount of times the animation should be played)
		- etc...
	
	Cel sequence struct:
		- idx (index of cel in source sprite)
		- layer (the layer the cel should be copied to in the new sprite)
		- frame (the frame the cel should be copied to in the new sprite)
--]]

local aspr = app.activeSprite

if not aspr then
	app.alert("There is no sprite to arrange")
	return
end

-- Build list of available tags
local tag_names = {}				-- String names of tags in current document
local tag_name_to_index = {}		-- Lookup table for tags
for i=1, #aspr.tags do
	tag_names[#tag_names+1] = aspr.tags[i].name
	tag_name_to_index[aspr.tags[i].name] = i
end

local tag_sequence = {}				-- User-defined sequence of tags and their options
local frame_dst = 0					-- Current destination frame to be copied to
local cel_seq = {}					-- Sequence of cels to be copied and destination

-- =========================== BACKEND FUNCTIONS ==========================

-- Return: mapping of "layer-frame" string to cel index
function LF2celIDX(sprite)
	local map = {}
	for i=1, #sprite.cels do
		local l = sprite.cels[i].layer.stackIndex
		local f = sprite.cels[i].frame.frameNumber
		map[l.."-"..f] = i
	end
	return map
end

local cel_map = LF2celIDX(aspr)		-- Lookup table for cels

function copyForward(from, tag_length)
	for l=1, #aspr.layers do
		for f=1, tag_length do
			-- Add entry for cel if exists
			if cel_map[l.."-"..(from + f)] then
				table.insert(cel_seq, {idx=cel_map[l.."-"..(from + f)], layer=l, frame=frame_dst+f})
			end
		end
	end
	frame_dst = frame_dst + tag_length
end

function copyBackward(from, tag_length)
	for l=1, #aspr.layers do
		for f=tag_length, 1, -1 do
			-- Add entry for cel if exists
			if cel_map[l.."-"..(from + f)] then
				table.insert(cel_seq, {idx=cel_map[l.."-"..(from + f)], layer=l, frame=frame_dst + (tag_length - f)})
			end
		end
	end
	frame_dst = frame_dst + tag_length
end

-- Copy tag content according to animation direction
function copyTagContent(tag_idx)
	local tag = aspr.tags[tag_idx]
	local from = tag.fromFrame.frameNumber - 1
	local tag_length = (tag.toFrame.frameNumber - from)
	if tag.aniDir == 0 then								-- Forward
		copyForward(from, tag_length)
	elseif tag.aniDir == 1 then							-- Reverse
		copyBackward(from, tag_length)
	elseif tag.aniDir == 2 then 						-- Ping-Pong
		copyForward(from, tag_length)
		copyBackward(from, tag_length)
		frame_dst = frame_dst - 1
	end
end

-- Calculate effective sequence
-- Populates cel_seq, a list of tuples of (src cel index, dst cel layer, dst cel frame) in the order to be copied
function calcSequence()
	for seq_num, tag in ipairs(tag_sequence) do
		local tag_idx = tag_name_to_index[tag.name]
		for loop=1, tag.loop do
			copyTagContent(tag_idx)
		end
	end
end

-- Generate the actual output sprite
function generate()
	commitChanges()
    -- Create the new sprite
	local new_spr = Sprite(aspr.spec)
	
	-- Calculate required copy operations and cel arrangement for new sprite
	calcSequence()
	
	---[[ DEBUG OUTPUT
	print("--- Tag Sequence: ---")
	for k, v in ipairs(tag_sequence) do
		print("Tag name: "..v.name.."; Loops: "..v.loop)
	end
	--]]
	--[[
	print("--- Cel Sequence: ---")
	for i=1, #cel_seq do
		print("Source cel index: "..cel_seq[i].idx.."; Destination layer: "..cel_seq[i].layer.."; Destination frame: "..cel_seq[i].frame)
	end
	--]]
	
	-- Match required layer- and frame-dimensionality
	while #new_spr.layers < #aspr.layers do
		new_spr:newLayer()
	end
	while #new_spr.frames < frame_dst do
		new_spr:newEmptyFrame()
	end
	
	-- Iterate through calculated copy sequence
	for i, cel in ipairs(cel_seq) do
		-- Copy cel content
		local image = aspr.cels[cel.idx].image
		local new_cel = new_spr:newCel(new_spr.layers[cel.layer], cel.frame, image, aspr.cels[cel.idx].position)
		local dur = aspr.cels[cel.idx].frame.duration
		new_spr.frames[cel.frame].duration = dur
	end
end

-- ============================ USER INTERFACE ============================

-- Save entry changes between clicks and create new dialog
function commitChanges()
	d:close()
	local i = 1
	while d.data["tag_"..i] do
		tag_sequence[i].name = d.data["tag_"..i]
		tag_sequence[i].loop = d.data["loop_"..i]
		i = i+1
	end
end

-- Create new dialogue from saved sequence
function recreateEntries()
	d:close()
	d = Dialog("Arrange Clips")
	d:separator("Select your tags")

	if #tag_sequence == 0 then
		d:button{id="add_"..1, label="Add Tag: ", text="+", onclick=function() addSequence() end}
	else
		for i=1, #tag_sequence do
			d:combobox{id="tag_"..i, label="Tag "..i..": ", option=tag_sequence[i].name, options=tag_names}
			 :number{id="loop_"..i, label="Loops: ", text=tostring(tag_sequence[i].loop), decimals=0}
			 :button{id="rm_"..i, text="-", onclick=function() rmSequence(i) end}
			 :button{id="add_"..i, text="+", onclick=function() addSequence(i) end}
		end
	end

	d:separator()
	 :button{id="generate", text="&Generate", onclick=function() generate() end}
	 :button{id="cancel", text="&Cancel"}
	 :show()
end

-- Add sequence to the end of the list
function addSequence(nr)
	nr = nr or 1
	-- Accept current state of dialog before moving on
	commitChanges()
	-- Add entries and adjust list
	if nr >= #tag_sequence then
		table.insert(tag_sequence, {name=tag_names[1], loop="1"})
	else
		table.insert(tag_sequence, nr+1, {name=tag_names[1], loop="1"})
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
d = Dialog("Arrange Clips")
d:separator("Select your tags")
 :button{id="add", label="Add Tag: ", text="+", onclick=function() addSequence() end}
 :button{id="cancel", text="&Cancel"}
 :show()
