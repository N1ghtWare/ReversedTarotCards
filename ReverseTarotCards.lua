local USE_DEBUG_RATE = true
local DISPLAY_DEBUG_MESSAGES = true

local SHOP_RATE = 8
if USE_DEBUG_RATE then SHOP_RATE = 100 end

local function PrintDebug(message)
	if DISPLAY_DEBUG_MESSAGES then sendDebugMessage(message) end
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
	collection_rows = { 1, 3 },
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
			"Creates up to 2 {C:blue}Pluto Planet{} cards",
			"(Must have room)",
		},
		undiscovered = undiscoveredText,
	},
	can_use = function(self, card)
		return true
	end,
	use = function(self, card, area, copier)
		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.4,
			func = function()
				play_sound("tarot1")
				return true
			end,
		}))

		local amountOfCardsToSpawn = 2 - (#G.consumeables.cards or 0)

		for _ = 1, amountOfCardsToSpawn do
			G.E_MANAGER:add_event(Event({
				trigger = "after",
				delay = 0.4,
				func = function()
					local _card = create_card("Planet", G.consumeables, false, false, false, false, "c_pluto")
					_card:add_to_deck()
					G.consumeables:emplace(_card)
					return true
				end,
			}))
		end
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
		},
		undiscovered = undiscoveredText,
	},
	can_use = function(self, card)
		if #G.hand.highlighted == 1 then return true end
	end,
	use = function(self, card, area, copier)
		local selectedCard = G.hand.highlighted[1]
		local suitPrefix = string.sub(selectedCard.base.suit, 1, 1) .. "_"
		local rankSuffix = GetRankSuffix(selectedCard.base.id, -2)

		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.4,
			func = function()
				play_sound("tarot1")
				selectedCard:flip()
				return true
			end,
		}))

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
		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.4,
			func = function()
				play_sound("tarot1")
				return true
			end,
		}))

		if G.GAME.used_jokers.j_credit_card then
			ease_dollars(math.random(1, 13), false)
		else
			local _card = create_card("Joker", G.jokers, false, "Common", false, false, "j_credit_card", false)
			_card:set_edition({ negative = true }, true)

			_card:start_materialize()
			_card:add_to_deck()
			G.jokers:emplace(_card)
		end
	end,
})
