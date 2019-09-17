local aspr = app.activeSprite

local tag_names = {}
local tag_name_to_index = {}
for i=1, #aspr.tags do
    tag_names[#tag_names+1] = aspr.tags[i].name
    tag_name_to_index[aspr.tags[i].name] = i
end

local tag_sequence = {
    { name = "Idle", loop = 2 },
    { name = "Walk", loop = 2 },
    { name = "Walkturn", loop = 1 },
	{ name = "WalkBack", loop = 2 }
}

local frame_dst = 0					-- Destination frame to be copied to
local cel_map = LF2celIDX(aspr)		-- Lookup table for cels
local cel_seq = {}					-- Sequence of cels to be copied and destination

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

-- Generate effective sequence
function generateSequence()
	-- Return: List of tuples of (cel index, layer, frame) in the order to be copied
	for seq_num, tag in ipairs(tag_sequence) do
		local tag_idx = tag_name_to_index[tag.name]
		for loop=1, tag.loop do
			copyTagContent(tag_idx)
		end
	end
end

-- Generate the actual video
function export()
    -- Create the new sprite
	local new_spr = Sprite(aspr.spec)
	
	-- Calculate required copy operations and cel arrangement for new sprite
	generateSequence()
	
	---[[ Debug Output
	print("Cel sequence: ")
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
		local new_cel = new_spr:newCel(new_spr.layers[cel.layer], cel.frame, image, aspr.cels[1].position)
	end
	d:close()
end


local d = Dialog("Arrange Clip")

d:button{id="gen", text="Export", onclick=function() export() end}
 :button{text="cancel"}
 :show()



