local USE_DEBUG_RATE = false
local DISPLAY_DEBUG_MESSAGES = true

local SHOP_RATE = 3
if USE_DEBUG_RATE then SHOP_RATE = 100 end

local function PrintDebug(message, ...)
	if DISPLAY_DEBUG_MESSAGES then print(message, ...) end
end

local possibleHands = {
	"Flush Five",
	"Flush House",
	"Five of a Kind",
	"Straight Flush",
	"Four of a Kind",
	"Full House",
	"Flush",
	"Straight",
	"Three of a Kind",
	"Two Pair",
	"Pair",
	"High Card",
}

local function GetMostPlayedHand()
	local mostPlayed = 0
	local handName = "High Card"

	for _, handInfo in pairs(G.GAME.hand_usage) do
		if handInfo.count > mostPlayed then
			mostPlayed = handInfo.count
			handName = handInfo.order
		end
	end

	PrintDebug(string.format("Found most played hand: %s", handName))
	return handName
end

local CARDS = {
	"rt_consumable_locked", -- undiscovered card
	"rt_high_priestess",
	"rt_strength",
	"rt_hermit",
}

local undiscoveredText = {
	name = "Not Discovered",
	text = { "Purchase or use", "this card in an", "unseedes run to", "learn what it does" },
}

-- setup atlases
for _, atlasKey in pairs(CARDS) do
	SMODS.Atlas({
		key = atlasKey,
		path = string.format("%s.png", atlasKey),
		px = 71,
		py = 95,
	})

	PrintDebug(string.format("Atlas for: %s created.", atlasKey))
end

SMODS.UndiscoveredSprite({
	key = "ReverseTarotCardsType",
	atlas = "rt_consumable_locked",
	pos = { x = 0, y = 0 },
})

SMODS.ConsumableType({
	key = "ReverseTarotCardsType",
	primary_colour = G.C.RED,
	secondary_colour = G.C.IMPORTANT,
	loc_txt = {
		collection = "Reverse Tarot Cards",
		name = "Reversed Tarot",
		undiscovered = undiscoveredText,
	},
	collection_rows = { 3, 1 },
	shop_rate = SHOP_RATE,
})

local valuesMap = {
	["A"] = 14,
	["K"] = 13,
	["Q"] = 12,
	["J"] = 11,
	["T"] = 10,
	["9"] = 9,
	["8"] = 8,
	["7"] = 7,
	["6"] = 6,
	["5"] = 5,
	["4"] = 4,
	["3"] = 3,
	["2"] = 2,
}

local suffixMap = {
	["14"] = "A",
	["13"] = "K",
	["12"] = "Q",
	["11"] = "J",
	["10"] = "T",
}

local function GetSuffixValue(inputSuffix)
	if not inputSuffix then return false end

	if not valuesMap[inputSuffix] then inputSuffix = suffixMap[inputSuffix] end
	return valuesMap[inputSuffix]
end

local function GetRankSuffix(currentSuffix, modifier)
	local goalSuffix = GetSuffixValue(tostring(currentSuffix)) + modifier

	-- 2 used
	if goalSuffix == 0 then
		goalSuffix = tostring(goalSuffix)
		goalSuffix = "13"

	-- 3 used
	elseif goalSuffix == 1 then
		goalSuffix = tostring(goalSuffix)
		goalSuffix = "14"
	end

	goalSuffix = tostring(goalSuffix)
	return suffixMap[goalSuffix] or tostring(valuesMap[goalSuffix])
end

-- cards
SMODS.Consumable({
	key = "rt_high_priestess",
	set = "ReverseTarotCardsType",
	atlas = "rt_high_priestess",
	loc_txt = {
		name = "Reversed High Priestess",
		text = {
			"Creates a {C:blue}Planet{} card for the most played {C:attention}poker hand{}",
			"{C:inactive}(Must have room)",
		},
		undiscovered = undiscoveredText,
	},
	can_use = function(self, card)
		return true
	end,
	use = function(self, card, area, copier)
		local actualTarotCard = copier or card

		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.4,
			func = function()
				play_sound("tarot1")
				actualTarotCard:juice_up(0.3, 0.5)
				return true
			end,
		}))

		-- smods has the power to add new play hand iirc, so better check the whole self.P_CENTERS and get the proper planet card id
		-- we'll give the high card if something goes wrong or the most played hand is not determined yet
		local mostPlayedHand = GetMostPlayedHand()
		local mostPlayedHandPlanetID = "c_pluto"

		for cardID, cardInfo in pairs(G.P_CENTERS) do
			if cardInfo.config and cardInfo.config.hand_type == mostPlayedHand then mostPlayedHandPlanetID = cardID end
		end

		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.4,
			func = function()
				actualTarotCard:juice_up(0.3, 0.5)
				local _card = create_card("Planet", G.consumeables, false, false, false, false, mostPlayedHandPlanetID)
				_card:add_to_deck()
				G.consumeables:emplace(_card)
				return true
			end,
		}))
	end,
})

SMODS.Consumable({
	key = "rt_strength",
	set = "ReverseTarotCardsType",
	atlas = "rt_strength",
	loc_txt = {
		name = "Reversed Strength",
		text = {
			"Decreases rank of a selected",
			"playing card by {C:attention}2{}",
			"{C:inactive}(example: Q -> 10, 2 -> K)",
		},
		undiscovered = undiscoveredText,
	},
	can_use = function(self, card)
		if #G.hand.highlighted == 1 then return true end
	end,
	use = function(self, card, area, copier)
		local actualTarotCard = copier or card

		local selectedCard = G.hand.highlighted[1]
		local suitPrefix = string.sub(selectedCard.base.suit, 1, 1) .. "_"
		local rankSuffix = GetRankSuffix(selectedCard.base.id, -2)

		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.4,
			func = function()
				play_sound("tarot1")
				selectedCard:flip()
				actualTarotCard:juice_up(0.3, 0.5)
				return true
			end,
		}))

		actualTarotCard:juice_up(0.3, 0.5)

		selectedCard:flip()
		selectedCard:set_base(G.P_CARDS[suitPrefix .. rankSuffix])
	end,
})

SMODS.Consumable({
	key = "rt_hermit",
	set = "ReverseTarotCardsType",
	atlas = "rt_hermit",
	loc_txt = {
		name = "Reversed Hermit",
		text = {
			"Creates a {C:dark_edition}Negative{} {C:attention}Credit Card{} Joker",
			"if a {C:attention}Credit Card{} is already present",
			"grants a random amount of money",
		},
		undiscovered = undiscoveredText,
	},
	can_use = function(self, card)
		return true
	end,
	use = function(self, card, area, copier)
		local actualTarotCard = copier or card

		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.4,
			func = function()
				play_sound("tarot1")
				actualTarotCard:juice_up(0.3, 0.5)
				return true
			end,
		}))

		if G.GAME.used_jokers.j_credit_card then
			ease_dollars(math.random(1, 13), false)
		else
			local _card = create_card("Joker", G.jokers, false, "Common", false, false, "j_credit_card", false)
			_card:set_edition({ negative = true }, true, true)

			_card:start_materialize()
			_card:add_to_deck()
			G.jokers:emplace(_card)
		end
	end,
})
