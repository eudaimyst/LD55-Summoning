
display.setDefault("magTextureFilter", "nearest");
local json = require "json"

local mouseMode = "pick"

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
local deckFrames = {
    width = 160,
    height = 256,
    numFrames = 4,
    sheetContentWidth = 640,  -- width of original 1x size of entire sheet
    sheetContentHeight = 256 -- height of original 1x size of entire sheet
}
local cards = {}
local discardedCards = {}
local deckOrder = {}
local cardSlots = {}
local handCards = {}
local redCharacters = graphics.newImageSheet("assets/red_characters.png", characterFrames)
local blackCharacters = graphics.newImageSheet("assets/black_characters.png", characterFrames)

local slotToPlace --set when a slot is selected, used to determine which card to place

local deckImages = graphics.newImageSheet("assets/deck_sheet.png", deckFrames)
local deck --assigned when deck is created

local cardTypes = {
    jack = {
		frame = 3
	},
    queen = {
		frame = 4
	},
    king = {
		frame = 5
    },
    ace = {
		frame = 6
	},
    number = {
		frame = 1
	}
}

local function generateCards()
    local rank, suit = 1, 1
    for i = 1, 52 do
        local card = {
            rank = rank,
            suit = suit
        }
        if (rank == 13) then
            suit = suit + 1
            rank = 0
        end
        rank = rank + 1
        cards[#cards + 1] = card
    end
end

local function shuffleCards()
    for i = 1, #cards do
        local cardPicked = false
        while cardPicked == false do
            local pickedCard = math.random(1, #cards)
            for j = 1, #deckOrder do
                if deckOrder[j] == pickedCard then
                    cardPicked = true
                end
            end
            if cardPicked == false then
                print(i, pickedCard)
                deckOrder[i] = pickedCard
                cardPicked = true
            else
                cardPicked = false
            end
        end
    end
    print(json.prettify(deckOrder))
end

generateCards()
shuffleCards()

local function displayHandCard(slot)
    if cardSlots[slot].card == nil then
        if handCards[slot] ~= nil then
            local card = display.newGroup()
            card.x, card.y = cardSlots[slot].x, cardSlots[slot].y
            card.bg = display.newImageRect("assets/blank_card.png", 50, 80)
            card.number = display.newText(handCards[slot].rank, 10, 0, native.systemFont, 16)
            card.number:setFillColor(0, 0, 0);
            card.suit = display.newText(handCards[slot].suit, -10, 0, native.systemFont, 16)
            card.suit:setFillColor(0, 0, 0);
            card:insert(card.bg)
            card:insert(card.number)
            card:insert(card.suit)
            cardSlots[slot].card = card
        end
    else
        if handCards[slot] == nil then
            print("removing " .. slot)
            cardSlots[slot].card:removeSelf()
        end
    end
end

local function displayCardSlots()
    for i = 1, 3 do
        cardSlots[i] = display.newImageRect("assets/empty_slot.png", 50, 80)
        cardSlots[i].x = 50 + (60 * i)
        cardSlots[i].y = display.actualContentHeight - 120
		cardSlots[i].slotNumber = i
        cardSlots[i].tap = function(self, event)
			if mouseMode == "pick" then
                if handCards[i] ~= nil then
                    slotToPlace = i
					mouseMode = "place"
				end
			end
		end
        cardSlots[i]:addEventListener("tap", cardSlots[i])
    end
    cardSlots.update = function(self)
		print("refreshing hand")
        for i = 1, 3 do
			displayHandCard(i)
		end
	end
end
displayCardSlots()

local function drawCard() --when deck is tapped
    if deck == nil then
        print("unable to draw card with no deck")
        return
    else
        if mouseMode == "pick" then
            if #handCards > 2 then
                print("unable to draw card, hand is full")
            else
				for i = 1, 3 do
					if handCards[i] == nil then
                		handCards[i] = cards[deckOrder[#deckOrder]]
                		deckOrder[#deckOrder] = nil
						print("handcards: \n", json.prettify(handCards))
                        print("deckorder: \n", json.prettify(deckOrder))
						cardSlots:update()
						break
					end
				end
            end
        end
    end
    deck.count:update()
	cardSlots:update()
end

local function displayDeck()
    deck = display.newImageRect(deckImages, 1, 50, 80)
    deck.x = 35
    deck.y = display.actualContentHeight - 120
    deck.count = display.newText(#deckOrder, 100, 200, native.systemFont, 16)
    deck.count.y = deck.y + 50
    deck.count.x = deck.x
    deck.count.update = function(self)
		self.text = #deckOrder
	end
	deck:addEventListener( "tap", drawCard )
end
displayDeck()

local function createCharacter(rank, suit, x, y)
    local char = {
        rank = rank,
        suit = suit,
        x = x,
        y = y,
        rect = display.newRect(x, y, 10, 10)
    }
    if rank == 1 then
        char.cardType = cardTypes.ace
    elseif rank == 11 then
        char.cardType = cardTypes.jack
    elseif rank == 12 then
        char.cardType = cardTypes.queen
    elseif rank == 13 then
        char.cardType = cardTypes.king
    else
        char.cardType = cardTypes.number
    end
	if char.cardType == cardTypes.number then
        char.frame = math.random(1, 2)
	else
		char.frame = char.cardType.frame
	end
    local paint = {
        type = "image",
        frame = char.frame
    }
    if suit == 1 or suit == 2 then
        paint.sheet = redCharacters
    else
        paint.sheet = blackCharacters
    end
    char.rect.width = characterFrames.frames[char.frame].width * .5
    char.rect.height = characterFrames.frames[char.frame].height * .5
    char.rect.fill = paint
    char.tick = function(self)
    end
end

local function mouseClick(x, y)
	if mouseMode == "place" then
        if slotToPlace then --else out of cards in the deck order
            local card = handCards[slotToPlace]
            print("placing: " .. slotToPlace)
			print(json.prettify(handCards))
            createCharacter(card.rank, card.suit, x, y)
			handCards[slotToPlace] = nil
			cardSlots:update()
            mouseMode = "pick"
			cardSlots[slotToPlace].card = nil
			slotToPlace = nil
		end
	end
end

local function onMouseEvent( event )
    if event.type == "down" then
        if event.isPrimaryButtonDown then
			mouseClick(event.x, event.y)
        end
    end
end
                              
-- Add the mouse event listener.
Runtime:addEventListener( "mouse", onMouseEvent )