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

-- Generate effective sequence
function generateSequence()
	-- Return: List of tuples of (cel index, layer, frame) in the order to be copied
end

-- Generate the actual video
function export()
	---[[
    -- Create the new sprite
	local new_spr = Sprite(aspr.spec)
	
	---[[
	while #new_spr.layers < #aspr.layers do
		new_spr:newLayer()
	end
	--]]
	while #new_spr.frames < 21 do
		new_spr:newEmptyFrame()
	end
	
	-- Iterate through each cel
	-- TODO: Replace incrementing indices with the generated sequence tuple
	for f_num=1, 1 do
		-- Copy cel content
		local image = aspr.cels[1].image
		local new_cel = new_spr:newCel(new_spr.layers[1], 1, image, aspr.cels[1].position)
	end
	--]]
end


local d = Dialog("Arrange Sequences")

local sequence = {
    { name = "Walk", loop = 5 },
    { name = "Walkturn", loop = 1 },
}

d:button{id="gen", text="Export", onclick=function() export() end}
 :button{text="cancel"}
 :show()



