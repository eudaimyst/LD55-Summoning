
display.setDefault("magTextureFilter", "nearest");

local characterFrames = {
	frames = {
		{
			x = 1,
			y = 1,
			width = 17,
			height = 33
		},
		{
			x = 18,
			y = 1,
			width = 17,
			height = 33
		},
		{
			x = 35,
			y = 1,
			width = 18,
			height = 33
		},
		{
			x = 53,
			y = 1,
			width = 24,
			height = 33
		},
		{
			x = 77,
			y = 1,
			width = 31,
			height = 33
		},
		{
			x = 108,
			y = 1,
			width = 17,
			height = 33
		}
	},
	sheetContentWidth = 125,  -- width of original 1x size of entire sheet
	sheetContentHeight = 33  -- height of original 1x size of entire sheet
}
local redCharacters = graphics.newImageSheet("assets/red_characters.png", characterFrames)
local blackCharacters = graphics.newImageSheet("assets/black_characters.png", characterFrames)	

local rankFrames = {}
for i = 1, 10 do
    rankFrames[i] = 1
end
rankFrames[1] = 6
rankFrames[11] = 3
rankFrames[12] = 4
rankFrames[13] = 5

local function createCharacter(rank, suit, x, y)
    local rect = display.newRect(x, y, 100, 160)

    -- Set the fill (paint) to use frame #2 from the image sheet
    local frame = rankFrames[rank]
	if frame == 1 then
		frame = math.random(1, 2)
	end
    local paint = {
        type = "image",
        frame = frame
    }
    if suit == 1 or suit == 2 then
        paint.sheet = redCharacters
    else
        paint.sheet = blackCharacters
    end
    rect.width = characterFrames.frames[frame].width * .5
    rect.height = characterFrames.frames[frame].height * .5
    rect.fill = paint
end

local function onMouseEvent( event )
    if event.type == "down" then
        if event.isPrimaryButtonDown then
            print("Left mouse button clicked.")

			createCharacter(math.random(1,13), math.random(1,4), event.x, event.y)
        elseif event.isSecondaryButtonDown then
            print( "Right mouse button clicked.")        
        end
    end
end
                              
-- Add the mouse event listener.
Runtime:addEventListener( "mouse", onMouseEvent )