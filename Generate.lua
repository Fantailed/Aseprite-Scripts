--
-- Created by IntelliJ IDEA.
-- User: ari
-- Date: 9/16/19
-- Time: 4:54 PM
-- To change this template use File | Settings | File Templates.
--
local aspr = app.activeSprite

local tag_names = {}
local tag_name_to_index = {}
for i=1, #aspr.tags do
    tag_names[#tag_names+1] = aspr.tags[i].name
    tag_name_to_index[aspr.tags[i].name] = i
end

-- Copy a layer from the original into the new for a given frame
function layerCopy(newSprite, layer, frameNumber)
    local cel = layer:cel(frameNumber)


end

-- Copy a tag from the original into the new
function tagCopy(newSprite, tag)
    for frame = tag.fromFrame.frameNumber, tag.toFrame.frameNumber, 1 do
        newSprite:newFrame(frame)
        for i = 1, #aspr.layers do
            layerCopy(newSprite, aspr.layers[i], frame)
        end
    end
end

local tag_sequence = {
    { name = "Walk", loop = 1 },
    { name = "Walkturn", loop = 1 },
}

-- Return mapping of (layer, frame) tuple to cel index
function LF2celIDX(sprite)
	local map = {}
	for i=1, #sprite.cels do
		local l = sprite.cels[i].layer.stackIndex
		local f = sprite.cels[i].frame.frameNumber
		map[l] = {}
		map[l][f] = i
		--print("MAP: "..i..", "..l..", "..f)
	end
	return map
end

-- Generate effective sequence
function generateSequence()
	-- Return: List of tuples of (cel index, layer, frame) in the order to be copied
	--print("seq: "..tag_sequence)
	---[[
	local cel_map = LF2celIDX(aspr)
	print(#cel_map[1])
	for l=1, #cel_map do
		for f=1, #cel_map[l] do
			print("Map["..l.."]["..f.."]: "..cel_map[l][f])
		end
	end
	local cel_seq = {}
	frame_dst = 0
	for seq_num, tag in ipairs(tag_sequence) do
		local tag_idx = tag_name_to_index[tag.name]
		for loop=1, tag.loop do
			-- Copy tag content
			local tag = aspr.tags[tag_idx]
			local from = tag.fromFrame.frameNumber - 1
			local tag_length = (tag.toFrame.frameNumber - from)
			print("Tag length"..tag_length)
			if tag.aniDir == 0 then								-- Forward
				for l=1, #aspr.layers do
					for f=1, tag_length do
						-- Add entry for cel if exists
						-- print("l: "..l..", f: "..(from+f))
						if cel_map[l][from + f] then
							print("Hit")
							table.insert(cel_seq, {idx=cel_map[l][from + f], layer=l, frame=frame_dst+f})
						end
					end
				end
				frame_dst = frame_dst + tag_length
			elseif tag.aniDir == 1 then							-- Reverse
				-- TODO: implement
			elseif tag.aniDir == 2 then 						-- Ping-Pong
				-- TODO: implement
			end
		end
	end
	return cel_seq
end

-- Generate the actual video
function export()
    -- Create the new sprite
	local new_spr = Sprite(aspr.spec)
	
	local cel_seq = generateSequence()
	for i=1, #cel_seq do
		print("Cel seq info: "..cel_seq[i].idx..", "..cel_seq[i].layer..", "..cel_seq[i].frame)
	end
	
	-- Match required layer- and frame-dimensionality
	while #new_spr.layers < #aspr.layers do
		new_spr:newLayer()
	end
	while #new_spr.frames < frame_dst do
		new_spr:newEmptyFrame()
	end
	
	-- Iterate through each cel
	-- TODO: Replace incrementing indices with the generated sequence tuple
	for i, cel in ipairs(cel_seq) do
		-- Copy cel content
		local image = aspr.cels[cel.idx].image
		local new_cel = new_spr:newCel(new_spr.layers[cel.layer], cel.frame, image, aspr.cels[1].position)
	end
	--]]
end


local d = Dialog("Arrange Sequences")

d:button{id="gen", text="Export", onclick=function() export() end}
 :button{text="cancel"}
 :show()



