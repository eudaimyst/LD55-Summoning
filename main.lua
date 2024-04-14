display.setDefault("magTextureFilter", "nearest");
display.setDefault("background", 0, .25, .05)
local json = require "json"

--constants

local charScale = .5;
local waveSpawnTimer = 20; --seconds for how often waves spawn
local waveCount = 20
local unitData = {
	[1] = { attack = 20, hp = 80, attackSpeed = 0.5, moveSpeed = 1.2 },
	[2] = { attack = 10, hp = 40, attackSpeed = 1, moveSpeed = 0.92 },
	[3] = { attack = 11, hp = 40, attackSpeed = 1, moveSpeed = 0.93 },
	[4] = { attack = 12, hp = 40, attackSpeed = 1, moveSpeed = 0.94 },
	[5] = { attack = 13, hp = 40, attackSpeed = 1, moveSpeed = 0.95 },
	[6] = { attack = 14, hp = 40, attackSpeed = 1, moveSpeed = 0.96 },
	[7] = { attack = 15, hp = 40, attackSpeed = 1, moveSpeed = 0.97 },
	[8] = { attack = 16, hp = 40, attackSpeed = 1, moveSpeed = 0.98 },
	[9] = { attack = 17, hp = 40, attackSpeed = 1, moveSpeed = 0.99 },
	[10] = { attack = 18, hp = 40, attackSpeed = 1, moveSpeed = 1 },
	[11] = { attack = 20, hp = 60, attackSpeed = 1, moveSpeed = 1.4 },
	[12] = { attack = 10, hp = 40, attackSpeed = 1, moveSpeed = 0.9 },
	[13] = { attack = 0, hp = 100, attackSpeed = 0, moveSpeed = 0.3 }
}
local cardTypes = {

	jack = {
		frame = 5
	},
	queen = {
		frame = 3
	},
	king = {
		frame = 4
	},
	ace = {
		frame = 6
	},
	number = {
		frame = 1
	}
}
local suitBonuses = {
	[1] = 3, [2] = 4, [3] = 2, [4] = 1
}
--game variables
local gameOver = false
local largestScreenSide = "y"
local largestResolution = display.actualContentHeight
if display.actualContentWidth > display.actualContentHeight then
	largestScreenSide = "x"
	largestResolution = display.actualContentWidth
end

local characters = {}
local enemies = {}

local mouseMode = "pick"
local currentWave = 0
local gameTimer = 0
local waveTimer = 0

local oldSystemTime = 0 --used to calculate deltaTime
local deltaTime = 0

local waveData = {}
local function generateWaveData()

end
generateWaveData()

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
	sheetContentWidth = 125, -- width of original 1x size of entire sheet
	sheetContentHeight = 33 -- height of original 1x size of entire sheet
}
local deckFrames = {
	width = 160,
	height = 256,
	numFrames = 4,
	sheetContentWidth = 640, -- width of original 1x size of entire sheet
	sheetContentHeight = 256 -- height of original 1x size of entire sheet
}
local cardValues = { [1] = "A", [11] = "J", [12] = "Q", [13] = "K" }
for i = 2, 10 do
	cardValues[i] = tostring(i);
end

local cards = {}
local deckOrder = {}
local cardSlots = {}
local handCards = {}
local redCharacters = graphics.newImageSheet("assets/red_characters.png", characterFrames)
local blackCharacters = graphics.newImageSheet("assets/black_characters.png", characterFrames)
local suitSheet = graphics.newImageSheet("assets/suits.png", {
	width = 64,
	height = 64,
	numFrames = 4,
	sheetContentWidth = 256, -- width of original 1x size of entire sheet
	sheetContentHeight = 64 -- height of original 1x size of entire sheet
})
local enemySheet = graphics.newImageSheet("assets/enemies.png", {
	width = 64,
	height = 64,
	numFrames = 4,
	sheetContentWidth = 256, -- width of original 1x size of entire sheet
	sheetContentHeight = 64 -- height of original 1x size of entire sheet
})

local slotToPlace --set when a slot is selected, used to determine which card to place

local deckImages = graphics.newImageSheet("assets/deck_sheet.png", deckFrames)
local deck --assigned when deck is created

local castle = display.newImageRect("assets/castle.png", 30, 30)
castle.hp = 1000
castle.dead = false
castle.x, castle.y = display.actualContentWidth / 2, display.actualContentHeight / 2

local waveTimerText = display.newText({
	text = "next wave: 0",
	x = 160,
	y = display.screenOriginY + 14,
	width = 100,
	font = native.systemFont,
	fontSize = 10,
	align = "left" -- Alignment parameter
})
local currentWaveText = display.newText({
	text = "current wave: 0",
	x = 60,
	y = display.screenOriginY + 14,
	width = 100,
	font = native.systemFont,
	fontSize = 10,
	align = "left" -- Alignment parameter
})



local function displayMessage(text, ms)
	local messageText = display.newText(text, display.contentCenterX, display.contentCenterY, native.systemFont, 14)
	timer.performWithDelay(ms, function() messageText:removeSelf() end);
end

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
			card.number = display.newText(cardValues[handCards[slot].rank], 9, 0, native.systemFont, 16)
			card.number:setFillColor(0, 0, 0);
			card.suit = display.newRect(-7, 0, 16, 16)
			local paint = {
				type = "image",
				frame = handCards[slot].suit,
				sheet = suitSheet
			}
			card.suit.fill = paint
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

local function drawCard(event) --when deck is tapped
	if (event.phase == "began") then
		if deck == nil then
			print("unable to draw card with no deck")
			return
		else
			local cardDrawn = false
			for i = 1, 3 do
				if handCards[i] == nil then
					cardDrawn = true
					handCards[i] = cards[deckOrder[#deckOrder]]
					deckOrder[#deckOrder] = nil
					print("handcards: \n", json.prettify(handCards))
					print("deckorder: \n", json.prettify(deckOrder))
					cardSlots:update()
					break
				end
			end
			if not cardDrawn then
				print("unable to draw card, hand is full")
			end
		end
		deck.count:update()
		cardSlots:update()
	end
end

local function displayDeck()
	deck = display.newImageRect(deckImages, 1, 50, 80)
	deck.x = 35
	deck.y = display.actualContentHeight - 90
	deck.count = display.newText(#deckOrder, 100, 200, native.systemFont, 16)
	deck.count.y = deck.y + 50
	deck.count.x = deck.x
	deck.count.update = function(self)
		self.text = #deckOrder
	end
	deck:addEventListener("touch", drawCard)
end
displayDeck()

local function moveUnit(unit, target) --called from units on tick function
	local targetVector = { x = target.x - unit.x, y = target.y - unit.y }
	local mag = math.abs(math.sqrt(math.pow(targetVector.x, 2) + math.pow(targetVector.y, 2)))
	local unitVector = { x = targetVector.x / mag, y = targetVector.y / mag }
	unit.x = unit.x + unitVector.x * deltaTime * unit.moveSpeed * 10
	unit.y = unit.y + unitVector.y * deltaTime * unit.moveSpeed * 10
end

local function getDistance(unit, target) --called from units on tick function
	local targetVector = { x = target.x - unit.x, y = target.y - unit.y }
	local mag = math.abs(math.sqrt(math.pow(targetVector.x, 2) + math.pow(targetVector.y, 2)))
	return mag
end

local function killUnit(unit)
	unit.alpha = 0
	unit.dead = true
end

local function doAttack(unit, target) --called from units on tick function
	unit.timeSinceAttack = 0
	local function dealDamage()
		local bonusSuitDamage = 0
		if target.suit == suitBonuses[unit.suit] then bonusSuitDamage = unit.attack * .2 end
		target.hp = target.hp - (unit.attack + bonusSuitDamage)
		if target.hp <= 0 then
			killUnit(target)
		end
		print("dealing " .. unit.attack .. " damage, new hp:" .. target.hp .. ", bonus: " .. bonusSuitDamage)
	end
	transition.moveTo(unit,
		{
			x = target.x,
			y = target.y,
			transition = easing.continuousLoop,
			onComplete = dealDamage,
			time = 200 * unit.attackSpeed
		})
end

local function findTarget(unit, targetList)
	local shortestMag = 9999
	local closestTarget = nil
	for i = 1, #targetList do
		local target = targetList[i]
		local targetVector = { x = target.x - unit.x, y = target.y - unit.y }
		local mag = math.abs(math.sqrt(math.pow(targetVector.x, 2) + math.pow(targetVector.y, 2)))
		if mag < shortestMag and target.dead == false then
			shortestMag = mag
			closestTarget = target
		end
	end
	return closestTarget
end

local function createCharacter(rank, suit, x, y)
	local char = display.newGroup()
	char:scale(charScale, charScale);
	char.x = x
	char.y = y
	char.rank = rank
	char.suit = suit
	char.attackRange = 9
	char.attackRate = 1
	char.timeSinceAttack = 0
	char.dead = false
	for k, v in pairs(unitData[rank]) do
		print(k, v)
		char[k] = v
	end
	char.maxHP = char.hp
	print(char.maxHP, char.hp)
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
	local frameWidth = characterFrames.frames[char.frame].width
	local frameHeight = characterFrames.frames[char.frame].height
	char.hpBG = display.newRect(char, 0, frameHeight / 2 + 2, frameWidth, 4)
	char.hpBG:setFillColor(0, .15, 0)
	char.hpBar = display.newRect(char, 0, frameHeight / 2 + 2, frameWidth, 4)
	char.hpBar:setFillColor(0, 1, 0)
	char.hpBar.update = function(self)
		char.hpBar.xScale = char.hp / char.maxHP
		char.hpBar.x = (-frameWidth / 2) * (1 - char.hpBar.xScale)
	end
	char.image = display.newRect(char, 0, 0, 10, 10)
	char.image.width = frameWidth
	char.image.height = frameHeight
	char.image.fill = paint
	char.tick = function(self)
		if self.dead == true then
			return
		end
		self.timeSinceAttack = self.timeSinceAttack + deltaTime
		if self.target and self.target.dead == false then
			if getDistance(self, self.target) < self.attackRange then
				if self.timeSinceAttack > self.attackRate then
					doAttack(self, self.target)
				end
			else --do not move if within attack range of target
				moveUnit(self, self.target)
			end
		else
			local nearestTarget = findTarget(self, enemies)
			if nearestTarget then
				self.target = nearestTarget
			end
		end
	end
	characters[#characters + 1] = char
end

local function displayCardSlots()
	for i = 1, 3 do
		cardSlots[i] = display.newImageRect("assets/empty_slot.png", 50, 80)
		cardSlots[i].x = 50 + (60 * i)
		cardSlots[i].y = display.actualContentHeight - 90
		cardSlots[i].slotNumber = i
		cardSlots[i].touch = function(self, event)
			if self.card == nil then
				return
			end
			if event.phase == "began" then
				if handCards[i] ~= nil then
					slotToPlace = i
					self.alpha = .01 --hacky dumbness
					self:scale(4, 4) --hacky dumbness
					self.card:scale(.5, .5)
				end
			end
			if event.phase == "moved" then
				self.x = event.x --hacky dumbness
				self.y = event.y --hacky dumbness
				self.card.x = event.x
				self.card.y = event.y
			end
			if event.phase == "ended" then
				self.x = 50 + (60 * i)
				self.y = display.actualContentHeight - 90
				self.alpha = 1
				self:scale(.25, .25)
				--^^reverts the hackiness
				if slotToPlace then
					local card = handCards[slotToPlace]
					print("placing: " .. slotToPlace)
					print(json.prettify(handCards))
					createCharacter(card.rank, card.suit, event.x, event.y)
					handCards[slotToPlace] = nil
					cardSlots:update()
					cardSlots[slotToPlace].card = nil
					slotToPlace = nil
				end
			end
		end
		cardSlots[i]:addEventListener("touch", cardSlots[i])
	end
	cardSlots.update = function(self)
		print("refreshing hand")
		for i = 1, 3 do
			displayHandCard(i)
		end
	end
end
displayCardSlots()

local function createEnemy(level, suit, x, y)
	local enemy = display.newGroup()
	enemy.suit = suit
	enemy.x, enemy.y = x, y
	enemy.target = castle
	enemy.moveSpeed = 1
	enemy.attackSpeed = .8
	enemy.attackRange = 10
	enemy.attackRate = 1
	enemy.attack = 10
	enemy.timeSinceAttack = 0
	enemy.hp = 15
	enemy.dead = false

	local paint = {
		type = "image",
		frame = suit,
		sheet = enemySheet
	}
	enemy.image = display.newRect(enemy, 0, 0, 10, 10)
	enemy.image.fill = paint
	enemy.tick = function(self)
		if self.dead == true then
			return
		end
		self.timeSinceAttack = self.timeSinceAttack + deltaTime
		if self.target then
			if self.target.dead == false then
				if getDistance(self, self.target) < self.attackRange then
					if self.timeSinceAttack > self.attackRate then
						doAttack(self, self.target)
					end
				else
					moveUnit(self, self.target)
				end
			end
		end
		local distanceToCastle = getDistance(self, castle)
		local nearestTarget = findTarget(self, characters)
		if nearestTarget then
			if getDistance(self, nearestTarget) < distanceToCastle then
				self.target = nearestTarget
			else
				self.target = castle
			end
		else
			self.target = castle
		end
	end
	enemies[#enemies + 1] = enemy
end

local function spawnWave(enemyCount, side, suit)
	print("new wave: " .. enemyCount, side, suit)
	local randomSide, randomSuit = false, false
	if side == nil then
		randomSide = true
	end
	if suit == nil then
		randomSuit = true
	end
	for i = 1, enemyCount do
		if randomSide then
			side = math.random(1, 4); print("random side")
		end
		if randomSuit then
			suit = math.random(1, 4); print("random suit")
		end
		local offsetX = math.random(display.contentCenterX - largestResolution / 2,
			display.contentCenterX + largestResolution / 2)
		local offsetY = math.random(display.contentCenterY - largestResolution / 2,
			display.contentCenterY + largestResolution / 2)
		if side == 1 then
			createEnemy(1, suit, offsetX, castle.y + largestResolution / 2) --south
		elseif side == 2 then
			createEnemy(1, suit, offsetX, castle.y + -largestResolution / 2) --north
		elseif side == 3 then
			createEnemy(1, suit, castle.x + largestResolution / 2, offsetY) --east
		elseif side == 4 then
			createEnemy(1, suit, castle.x - largestResolution / 2, offsetY) --west
		end
	end
end

local function onFrame(event)
	if gameOver then
		return
	end
	if castle.hp <= 0 then
		displayMessage("You have failed to save the castle", 999999999)
		gameOver = true
	end
	local oldGameTimer = gameTimer
	deltaTime = (system.getTimer() - oldSystemTime) / 1000
	oldSystemTime = system.getTimer()
	gameTimer = math.floor(system.getTimer() / 1000)
	if oldGameTimer ~= gameTimer then
		waveTimer = currentWave * waveSpawnTimer + 5 - gameTimer
		print(gameTimer)
		waveTimerText.text = "next wave: " .. waveTimer
		if waveTimer < 1 then
			currentWave = currentWave + 1
			if currentWave == 5 then
				spawnWave(currentWave + 4, 2, 1)
				displayMessage("wave 5: hearts from the North", 3000)
			elseif currentWave == 10 then
				spawnWave(currentWave + 4, 4, 2)
				displayMessage("wave 10: diamonds from the West", 3000)
			elseif currentWave == 15 then
				displayMessage("wave 15: clubs from the East", 3000)
				spawnWave(currentWave + 4, 3, 4)
			elseif currentWave == 20 then
				spawnWave(currentWave + 4, 1, 3)
				displayMessage("final wave: spades from the South", 3000)
			elseif currentWave == 21 then
				displayMessage("Congratulations! You saved the castle", 10000)
			elseif currentWave > 21 then
			else
				spawnWave(currentWave + 4)
				displayMessage("wave " .. currentWave, 3000)
			end
			currentWaveText.text = "current wave: " .. currentWave
		end
	end
	for i = 1, #enemies do
		enemies[i]:tick()
	end
	for i = 1, #characters do
		characters[i]:tick()
	end
end
-- Add the mouse event listener.
Runtime:addEventListener("enterFrame", onFrame)
