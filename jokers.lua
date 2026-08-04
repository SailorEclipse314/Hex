-- ============================================================
-- Hex -- Jokers
-- Every SMODS.Joker, plus the support systems built purely for
-- them: the Perkeo/Blueprint/Brainstorm copy-chain handling and
-- start_dissolve/calculate_joker hooks, the shop-reroll toggle_shop
-- hook, the hand-selection-limit-raising can_play/can_discard hooks,
-- the click-to-select highlighting system (for Curse/Vessel-style
-- Jokers), and the Huge-LQG eligible-jokers helper (also called
-- from consumables.lua). Everything that is a deck/seal/edition/
-- enhancement/poker hand/voucher lives in content.lua instead, and
-- everything that is a Consumable lives in consumables.lua.
--
-- Loaded from main.lua via SMODS.load_file, so it runs AFTER
-- main.lua's own top-level code -- every shared helper this file
-- calls (big, hex_to_plain_number, hex_format_points,
-- hex_format_dollars, HEX_POLY_DEFAULT_HAND_LIMIT,
-- HEX_IMMORTAL_STICKER_KEY, the custom Rarities, etc.) is already a
-- defined global by the time this file's own top-level code runs.
-- Loaded before consumables.lua, since hex_huge_lqg_eligible_jokers
-- (defined below) needs to already be a defined global by the time
-- consumables.lua's own top-level code runs.
-- ============================================================

local mod = SMODS.current_mod


local function hex_in_pool(self)
    return hex_owns_showman() or #SMODS.find_card(self.key) == 0
end


-- Dragon Fruit: gives $6 every hand played, decaying by $1 after each
-- hand (applied on context.after, which fires once per hand AFTER
-- joker_main -- so the hand that just resolved still got the un-decayed
-- amount, and only the *next* hand sees the lower value). Self-destructs
-- once the gain hits 0. Guarded with `not context.blueprint` on the
-- decrement/destroy so a Blueprint copy doesn't double-decay or
-- prematurely destroy the original card.
SMODS.Joker{
    key = "dragon_fruit",

    loc_txt = {
        name = "Dragon Fruit",
        text = {
            "Gives {C:money}+$#1#{} every time",
            "a hand is played, the gain",
            "goes down by {C:money}$1{} after",
            "each hand is played",
            "{C:inactive}(Destroyed at {}{C:money}+$0{}{C:inactive}){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 0, y = 1 },
    in_pool = hex_in_pool,
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = false,

    config = {
        extra = {
            dollars = big(6),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars } }
    end,

    calculate = function(self, card, context)
        if context.joker_main and card.ability.extra.dollars > 0 then
            return {
                dollars = card.ability.extra.dollars,
                colour = G.C.MONEY,
            }
        end

        if context.after and not context.blueprint then
            card.ability.extra.dollars = big(0):max(card.ability.extra.dollars:sub(1))

            if card.ability.extra.dollars <= 0 then
                G.E_MANAGER:add_event(Event({
                    trigger = "after",
                    delay = 0.3,
                    func = function()
                        card:start_dissolve()
                        return true
                    end
                }))
            end
        end
    end,
}

-- Snowball: +3 Mult, growing by +3 more at the end of every round.
-- Dedupe against G.GAME.round with a per-card stamp, same technique
-- Overflow/Black Seal use elsewhere in this file for context.end_of_round
-- firing multiple times per card in this Steamodded build.
SMODS.Joker{
    key = "snowball",

    loc_txt = {
        name = "Snowball",
        text = {
            "Gains {C:mult}+#2#{} Mult",
            "at the end of round",
            "{C:inactive}(Currently {}{C:mult}+#1#{}{C:inactive} Mult){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 0, y = 1 },
    in_pool = hex_in_pool,
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            mult = big(0),
            mult_gain = big(2),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, card.ability.extra.mult_gain } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                mult = card.ability.extra.mult,
            }
        end

        if context.end_of_round
        and not context.blueprint
        and card.hex_snowball_last_round ~= G.GAME.round then

            card.hex_snowball_last_round = G.GAME.round
            card.ability.extra.mult = card.ability.extra.mult:add(card.ability.extra.mult_gain)

            return {
                message = localize("k_upgrade_ex"),
                colour = G.C.MULT,
            }
        end
    end,
}






-- The Single: X3 Chips when the played hand IS a High Card (not just
-- "contains" one -- every hand technically contains a high card, so
-- this uses context.scoring_name to match only when High Card is the
-- actual scored hand).
SMODS.Joker{
    key = "the_single",

    loc_txt = {
        name = "The Single",
        text = {
            "Gives {X:chips,C:white}X#1#{} Chips when",
            "playing a {C:attention}High Card{}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 },
    in_pool = hex_in_pool,

    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            x_chips = big(3)
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.x_chips } }
    end,


    calculate = function(self, card, context)
        if context.joker_main and context.scoring_name == "High Card" then
            return {
                x_chips = card.ability.extra.x_chips,
                colour = G.C.CHIPS,
            }
        end
    end,
}

-- Devilish Joker: +0.66 Xmult if the played hand is exactly a Three of
-- a Kind made of 6s. Checks context.scoring_name == "Three of a Kind"
-- first (so a Full House containing three 6s doesn't count), then
-- verifies every card in that scoring group is a 6 via card.base.value.
SMODS.Joker{
    key = "devilish_joker",

    loc_txt = {
        name = "Devilish Joker",
        text = {
            "Gives {X:mult,C:white}X#1#{} Mult if",
            "played hand is a",
            "{C:attention}Three of a Kind{} of {C:attention}6s{}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 },
    in_pool = hex_in_pool,
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
   
    config = {
        extra = {
            x_mult = big(6.66)
        }
    },


    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.x_mult } }
    end,

    calculate = function(self, card, context)
        if context.joker_main and context.scoring_name == "Three of a Kind" then
            -- context.poker_hands[key] is a list of card GROUPINGS, not a
            -- flat list of cards -- the actual scoring cards are at [1].
            local groups = context.poker_hands["Three of a Kind"]
            local trip_cards = groups and groups[1]
            local all_sixes = trip_cards and #trip_cards > 0

            if all_sixes then
                for _, c in ipairs(trip_cards) do
                    if not (c.base and c.base.value == "6") then
                        all_sixes = false
                        break
                    end
                end
            end

            if all_sixes then
                return {
                    Xmult = card.ability.extra.x_mult,
                    colour = G.C.MULT,
                }
            end
        end
    end,
}






-- Queer Joker: +69 Chips if the played hand is not a Straight.
SMODS.Joker{
    key = "queer_joker",

    loc_txt = {
        name = "Queer Joker",
        text = {
            "Gives {C:chips}+#1#{} Chips if",
            "played hand does not",
            "contain a {C:attention}Straight{}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 0, y = 1 },
    in_pool = hex_in_pool,
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            chips = big(69)
        }
    },


    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,


    calculate = function(self, card, context)
        if context.joker_main and not next(context.poker_hands["Straight"]) then
            return {
                chips = card.ability.extra.chips,
                colour = G.C.CHIPS,
            }
        end
    end,
}

-- Casual Joker: +10 Mult if the played hand is not a Pair.
SMODS.Joker{
    key = "casual_joker",

    loc_txt = {
        name = "Casual Joker",
        text = {
            "Gives {C:mult}+#1#{} Mult if",
            "played hand does not",
            "contain a {C:attention}Pair{}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 0, y = 1 },
    in_pool = hex_in_pool,
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            mult = big(10)
        }
    },


    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,

    calculate = function(self, card, context)
        if context.joker_main and not context.scoring_name == "Pair" then
            return {
                mult = card.ability.extra.mult,
                colour = G.C.MULT,
            }
        end
    end,
}

-- Jester: flat +10 Mult, -30 Chips, every hand.
SMODS.Joker{
    key = "jester",

    loc_txt = {
        name = "Jester",
        text = {
            "Gives {C:mult}+#1#{} Mult",
            "but {C:chips}-30{} Chips",
        }
    },

    atlas = "HexJokers",
    pos = { x = 0, y = 1 },
    in_pool = hex_in_pool,
    rarity = 1,
    cost = 1,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            mult = big(10)
        }
    },


    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                mult = card.ability.extra.mult,
                chips = -30,
                colour = G.C.MULT,
            }
        end
    end,
}

-- Face Value: each scored card gives Mult equal to its rank value
-- (2-10 = face value, Jack/Queen/King = 10, Ace = 11) -- the same
-- rank-value mapping vanilla uses for base Chips, just applied to Mult
-- here instead. Looked up off card.base.value (the same field The Seal
-- of Aces above already checks), not an assumed numeric card field.
local HEX_FACE_VALUE_RANK_TO_MULT = {
    ["Ace"] = 11,
    ["King"] = 10,
    ["Queen"] = 10,
    ["Jack"] = 10,
    ["10"] = 10,
    ["9"] = 9,
    ["8"] = 8,
    ["7"] = 7,
    ["6"] = 6,
    ["5"] = 5,
    ["4"] = 4,
    ["3"] = 3,
    ["2"] = 2,
}

SMODS.Joker{
    key = "face_value",

    loc_txt = {
        name = "Face Value",
        text = {
            "Played cards give {C:mult}Mult{}",
            "equal to their {C:attention}rank{}",
            "{C:inactive}(King, Queen, Jack give {}{C:mult}10{}{C:inactive}){}",
            "{C:inactive}(Ace gives {}{C:mult}11{}{C:inactive}){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 },
    in_pool = hex_in_pool,
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local rank_mult = HEX_FACE_VALUE_RANK_TO_MULT[context.other_card.base.value]

            if rank_mult then
                return {
                    mult = rank_mult,
                    card = context.other_card,
                    colour = G.C.MULT,
                }
            end
        end
    end,
}








-- Summoning: while owned, The Soul (c_soul) and this mod's own Heart
-- card (c_<prefix>_heart) are 3 times more likely to appear in Arcana/
-- Spectral packs. Multiplies each center's own soul_rate field directly
-- -- the same field Legendary Soul/Mythic Heart vouchers and the Quasar
-- consumable already multiply elsewhere in this mod (see HEX_SOUL_
-- CENTER_KEY/HEX_HEART_CENTER_KEY, defined in content.lua) -- rather
-- than touching any global probability table.
--
-- Unlike the vouchers/consumable (which multiply permanently, once),
-- this Joker's bonus needs to turn off if it's sold, and multiple
-- copies need to stack multiplicatively (3x, 9x, 27x, ...) rather than
-- additively. add_to_deck/remove_from_deck -- the same lifecycle pair
-- Open Market/Endless Abyss use elsewhere in this file -- multiplies
-- soul_rate by 3 on the way in and divides it back by 3 on the way out,
-- so selling a copy cleanly undoes exactly what that copy added, no
-- matter how many other copies (or the permanent voucher/consumable
-- bonuses) are also currently multiplying the same field.
local function hex_summoning_soul_heart_centers()
    return G.P_CENTERS[HEX_SOUL_CENTER_KEY], G.P_CENTERS[HEX_HEART_CENTER_KEY]
end

SMODS.Joker{
    key = "summoning",

    loc_txt = {
        name = "Summoning",
        text = {
            "{C:attention}X3{} the chance for",
            "{C:legendary}The Soul{} and {C:mythic}Heart{}",
            "to appear in {C:tarot}Arcana{} and",
            "{C:spectral}Spectral{} packs",
        }
    },

    atlas = "HexJokers",
    pos = { x = 1, y = 0 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 3,             -- rare
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = false, -- the effect lives in the lifecycle hooks below, not in calculate, so a Blueprint copy has nothing to mimic
    eternal_compat = true,

    add_to_deck = function(self, card, from_debuff)
        local soul_center, heart_center = hex_summoning_soul_heart_centers()

        if soul_center and soul_center.soul_rate then
            soul_center.soul_rate = soul_center.soul_rate * 3
        end

        if heart_center and heart_center.soul_rate then
            heart_center.soul_rate = heart_center.soul_rate * 3
        end
    end,

    remove_from_deck = function(self, card, from_debuff)
        local soul_center, heart_center = hex_summoning_soul_heart_centers()

        if soul_center and soul_center.soul_rate then
            soul_center.soul_rate = soul_center.soul_rate / 3
        end

        if heart_center and heart_center.soul_rate then
            heart_center.soul_rate = heart_center.soul_rate / 3
        end
    end,
}













SMODS.Joker{
    key = "hatsune_miku",

    loc_txt = {
        name = "Hatsune Miku",
        text = {
            "Gains {C:chips}+#2#{} Chips for",
            "every {C:attention}3{} or {C:attention}9{} triggered",
            "{C:inactive}(Currently {}{C:chips}+#1#{}{C:inactive} Chips){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 2 },

    rarity = 1,
    in_pool = hex_in_pool,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            chips = big(0),
            chips_gain = big(15),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.chips_gain } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                chips = card.ability.extra.chips,
            }
        end

        -- Every triggered card counts (retriggering counts, same as
        -- Lemniscate above), gated on rank rather than enhancement.
        if context.individual and context.cardarea == G.play and not context.blueprint then
            local rank = context.other_card.base and context.other_card.base.value

            if rank == "3" or rank == "9" then
                card.ability.extra.chips = card.ability.extra.chips:add(card.ability.extra.chips_gain)

                return {
                    message = localize("k_upgrade_ex"),
                    colour = G.C.CHIPS,
                }
            end
        end
    end,
}

-- Cubed Joker: +0.1 Xchips permanently for every 8 cards scored
-- (counting each individual scoring event, so a retriggered card
-- counts toward the total more than once -- same convention as
-- vanilla's own per-scored-card permanent-growth jokers).
SMODS.Joker{
    key = "cubed_joker",

    loc_txt = {
        name = "Cubed Joker",
        text = {
            "This Joker gains {X:chips,C:white}X#1#{} Chips",
            "for every {C:attention}8{} cards scored",
            "{C:inactive}(Currently {}{X:chips,C:white}X#2#{}{C:inactive} Chips){}",
            "{C:inactive}(#3#/8 cards scored){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 },
    in_pool = hex_in_pool,
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            xchips = big(1),
            xchips_gain = big(0.1),
            card_count = 0,
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.xchips_gain,
                card.ability.extra.xchips,
                card.ability.extra.card_count,
            }
        }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                x_chips = card.ability.extra.xchips,
            }
        end

        if context.individual and context.cardarea == G.play and not context.blueprint then
            card.ability.extra.card_count = card.ability.extra.card_count + 1

            if card.ability.extra.card_count >= 8 then
                card.ability.extra.card_count = card.ability.extra.card_count - 8
                card.ability.extra.xchips = card.ability.extra.xchips:add(card.ability.extra.xchips_gain)

                return {
                    message = localize("k_upgrade_ex"),
                    colour = G.C.CHIPS,
                }
            end
        end
    end,
}




-- Counts every playing card in the whole deck (hand/deck-pile/discard/
-- play, anywhere -- using G.playing_cards, the same master registry
-- Diamond Card's own hex_count_diamond_cards helper uses elsewhere in
-- this file) that currently carries ANY Seal (Red/Blue/Gold/Purple, or
-- any custom seal this mod or another adds, like Orange/Green/Pink/
-- Black above) -- just checked via the plain c.seal field being
-- non-nil, not any specific seal key.
function hex_count_sealed_cards()
    if not G.playing_cards then return 0 end

    local count = 0
    for _, c in ipairs(G.playing_cards) do
        if c.seal then
            count = count + 1
        end
    end

    return count
end

SMODS.Joker{
    key = "stamp_collection",

    loc_txt = {
        name = "Stamp Collection",
        text = {
            "Gives {X:mult,C:white}X#1#{} Mult for every",
            "playing card with a {C:attention}Seal{}",
            "in your {C:attention}full deck{}",
            "{C:inactive}(Currently {}{X:mult,C:white}X#2#{}{C:inactive} Mult){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 2,             -- uncommon
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            Xmult_gain = big(0.25),
        }
    },

    -- Live, fully dynamic -- same "derived from current deck state every
    -- time it's read" approach Juno/Andromeda-style Jokers elsewhere in
    -- this file use, rather than a permanent stacking counter. Rises and
    -- falls immediately as sealed cards are added/removed/stripped.
    loc_vars = function(self, info_queue, card)
        local count = hex_count_sealed_cards()
        local xmult = big(1):add(card.ability.extra.Xmult_gain:mul(big(count)))

        return { vars = { card.ability.extra.Xmult_gain, xmult } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            local count = hex_count_sealed_cards()
            local xmult = big(1):add(card.ability.extra.Xmult_gain:mul(big(count)))

            return {
                Xmult = xmult,
                colour = G.C.MULT,
            }
        end
    end,
}





SMODS.Joker{
    key = "pokemon_card",

    loc_txt = {
        name = "Pokémon Card",
        text = {
            "Each {C:attention}Common{} Joker you have",
            "gives {X:chips,C:white}X#1#{} Chips",
        }
    },

    atlas = "HexJokers",
    pos = { x = 1, y = 0 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 3,             -- rare
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            per_common_x_chips = big(1.75),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.per_common_x_chips } }
    end,

    -- Mirrors vanilla Baseball Card's own real mechanic exactly: fires
    -- once per OTHER owned Joker via context.other_joker (not once for
    -- this card's own joker_main), checking THAT joker's rarity, and
    -- returning Xchip_mod -- the per-other-joker Chips-multiplier key,
    -- parallel to Xmult_mod -- so each qualifying Joker gets its own
    -- juice_up and its own multiplicative application, in Joker-row
    -- order, rather than one lump sum applied from Pokémon Card's own
    -- position.
    calculate = function(self, card, context)
        if context.other_joker
        and context.other_joker.config.center.rarity == 1
        and card ~= context.other_joker then

            G.E_MANAGER:add_event(Event({
                func = function()
                    context.other_joker:juice_up(0.5, 0.5)
                    return true
                end
            }))

            return {
                message = "X" .. tostring(card.ability.extra.per_common_x_chips),
                Xchip_mod = card.ability.extra.per_common_x_chips,
                colour = G.C.CHIPS,
            }
        end
    end,
}




-- Reverb: retriggers Aces, 10s, 9s, 8s, 7s, and 6s. Same
-- context.repetition + context.cardarea == G.play shape as Encore
-- above, gated on rank instead of enhancement key.
local HEX_REVERB_RANKS = {
    ["Ace"] = true,
    ["10"] = true,
    ["9"] = true,
    ["8"] = true,
    ["7"] = true,
    ["6"] = true,
}

SMODS.Joker{
    key = "reverb",

    loc_txt = {
        name = "Reverb",
        text = {
            "Retrigger played {C:attention}Aces{}, {C:attention}10s{}, {C:attention}9s{},",
            "{C:attention}8s{}, {C:attention}7s{}, and {C:attention}6s{}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 },
    in_pool = hex_in_pool,
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play and not context.blueprint then
            if HEX_REVERB_RANKS[context.other_card.base.value] then
                return {
                    repetitions = 1,
                    card = context.other_card,
                }
            end
        end
    end,
}


-- Totem: +10 Hex points at the end of a Boss Blind. Same
-- end_of_round + G.GAME.blind.boss + per-card round-stamp dedupe that
-- Overflow uses elsewhere in this file.
SMODS.Joker{
    key = "totem",

    loc_txt = {
        name = "Totem",
        text = {
            "Gives {C:purple}+10{} Hex points",
            "at the end of a {C:attention}Boss Blind{}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 },
    in_pool = hex_in_pool,
    rarity = 2,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,

    config = {
        extra = {
            last_round = nil,
        }
    },

    calculate = function(self, card, context)
        if context.end_of_round
        and G.GAME.blind
        and G.GAME.blind.boss
        and not context.blueprint
        and card.ability.extra.last_round ~= G.GAME.round then

            card.ability.extra.last_round = G.GAME.round

            G.GAME.hex_points = (G.GAME.hex_points or big(0)):add(big(10))

            return {
                message = "+10 Hex",
                colour = G.C.HEX_ORPLE or G.C.PURPLE,
            }
        end
    end,
}

-- Lazily counts folders under Mods/ (love.filesystem's save-directory
-- namespace, which already covers Mods/ without needing an explicit
-- mount), memoized after the first successful read since installed
-- mods don't change mid-session. Filters to actual directories only,
-- so a stray file dropped in Mods/ doesn't get counted. Wrapped in
-- pcall so a filesystem hiccup degrades to "0 extra mods" instead of
-- crashing the joker.
local hex_installed_mod_count = nil

local function hex_count_installed_mods()
    if hex_installed_mod_count then
        return hex_installed_mod_count
    end

    local count = 0
    local ok, items = pcall(love.filesystem.getDirectoryItems, "Mods")

    if ok and items then
        for _, item in ipairs(items) do
            local info = love.filesystem.getInfo("Mods/" .. item, "directory")
            if info then
                count = count + 1
            end
        end
    end

    hex_installed_mod_count = count
    return count
end

SMODS.Joker{
    key = "main_lua",

    loc_txt = {
        name = "main.lua",
        text = {
            "Gives {X:mult,C:white}X0.1{} Mult for",
            "every {C:attention}mod{} you have installed",
            "{C:inactive}(Currently {}{X:mult,C:white}X#1#{}{C:inactive} Mult){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 1, y = 0 },
    in_pool = hex_in_pool,
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    loc_vars = function(self, info_queue, card)
        local mod_count = hex_count_installed_mods()
        return { vars = { 1 + 0.1 * mod_count } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            local mod_count = hex_count_installed_mods()

            return {
                Xmult = 1 + 0.1 * mod_count,
                colour = G.C.MULT,
            }
        end
    end,
}

-- Necromancer: +0.2 Xchips permanently for every Spectral card used.
-- Same Card:use_consumeable hook pattern as Scientist above -- an
-- independent hook (different local name), so it stacks fine alongside
-- that one rather than replacing it.
SMODS.Joker{
    key = "necromancer",

    loc_txt = {
        name = "Necromancer",
        text = {
            "This Joker gains {X:chips,C:white}X#1#{} Chips",
            "for every {C:attention}Spectral{} card used",
            "{C:inactive}(Currently {}{X:chips,C:white}X#2#{}{C:inactive} Chips){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 },
    in_pool = hex_in_pool,
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            xchips = big(1),
            xchips_gain = big(0.2),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xchips_gain, card.ability.extra.xchips } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                x_chips = card.ability.extra.xchips,
            }
        end
    end,
}

local hex_old_use_consumeable_necromancer = Card.use_consumeable

function Card:use_consumeable(area, copier)
    if self.ability and self.ability.set == "Spectral" and not copier then
        if G.jokers and G.jokers.cards then
            for _, j in ipairs(G.jokers.cards) do
                if j.config and j.config.center
                and j.config.center.key == ("j_" .. mod.prefix .. "_necromancer") then

                    j.ability.extra.xchips = j.ability.extra.xchips:add(j.ability.extra.xchips_gain)

                    card_eval_status_text(j, "extra", nil, nil, nil, {
                        message = localize("k_upgrade_ex"),
                        colour = G.C.CHIPS,
                    })
                end
            end
        end
    end

    return hex_old_use_consumeable_necromancer(self, area, copier)
end

-- Roadrunner: +$5 when skipping a Blind (context.skip_blind is the
-- same flag vanilla Red Card uses for its own "blind skipped" trigger).
SMODS.Joker{
    key = "roadrunner",

    loc_txt = {
        name = "Roadrunner",
        text = {
            "Gives {C:money}+$#1#{} when",
            "{C:attention}skipping{} a Blind",
        }
    },

    atlas = "HexJokers",
    pos = { x = 0, y = 1 },
    in_pool = hex_in_pool,
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            money = big(5),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.money } }
    end,
    

    calculate = function(self, card, context)
        if context.skip_blind and not context.blueprint then
            return {
                dollars = card.ability.extra.money,
                colour = G.C.MONEY,
            }
        end
    end,
}

-- Hoarder: +50 Chips for every consumable slot currently occupied
-- (i.e. #G.consumeables.cards, not the total slot count).
SMODS.Joker{
    key = "hoarder",

    loc_txt = {
        name = "Hoarder",
        text = {
            "Gives {C:chips}+#1#{} Chips for every",
            "{C:attention}Consumable{} slot in use",
        }
    },

    atlas = "HexJokers",
    pos = { x = 0, y = 1 },
    in_pool = hex_in_pool,
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            chips = big(50),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,


    calculate = function(self, card, context)
        if context.joker_main then
            local used = (G.consumeables and #G.consumeables.cards) or 0

            if used > 0 then
                return {
                    chips = big(used):mul(card.ability.extra.chips),
                    colour = G.C.CHIPS,
                }
            end
        end
    end,
}

-- Overtime: costs $5 and gives +3 Hex points, both at the end of round.
-- Same end_of_round + per-card round-stamp dedupe used by
-- Snowball/Totem/Scientist/Streak above (context.end_of_round firing
-- multiple times per card in this build). Hex points are applied via
-- direct state mutation (not a native scoring field), same as Totem.
SMODS.Joker{
    key = "overtime",

    loc_txt = {
        name = "Overtime",
        text = {
            "Costs {C:money}$5{} at the end of",
            "round, but gives {C:purple}+3{}",
            "{C:purple}Hex points{} at the end of round",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 },
    in_pool = hex_in_pool,
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,


    calculate = function(self, card, context)
        if context.end_of_round
        and not context.blueprint
        and card.hex_overtime_last_round ~= G.GAME.round then

            card.hex_overtime_last_round = G.GAME.round

            G.GAME.hex_points = (G.GAME.hex_points or big(0)):add(big(3))

            return {
                dollars = -5,
                colour = G.C.MONEY,
            }
        end
    end,
}


SMODS.Joker{
    key = "open_market",

    loc_txt = {
        name = "Open Market",
        text = {
            "Gives {C:attention}+1{} shop slot",
        }
    },

    atlas = "HexJokers",
    pos = { x = 1, y = 0 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 3,             -- rare
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,

    -- Same add_to_deck/remove_from_deck lifecycle pair Endless Abyss
    -- uses elsewhere in this file for its own persistent Joker-slot
    -- bonus -- applied exactly once no matter how the card enters/
    -- leaves your Jokers (bought, created via Life/Manifest-style
    -- summon, sold, destroyed, etc.), rather than needing a per-frame
    -- poll. G.GAME.shop.joker_max is the same field Overstock Deck's
    -- own apply() hook bumps directly for its +2 shop slot bonus.
    add_to_deck = function(self, card, from_debuff)
        G.GAME.shop.joker_max = (G.GAME.shop.joker_max or 0) + 1
    end,

    remove_from_deck = function(self, card, from_debuff)
        G.GAME.shop.joker_max = (G.GAME.shop.joker_max or 0) - 1
    end,
}


SMODS.Joker{
    key = "russian_roulette",

    loc_txt = {
        name = "Russian Roulette",
        text = {
            "Gives {X:mult,C:white}X#1#{} Mult",
            "At the start of a {C:attention}Boss Blind{},",
            "{C:green}#2# in 6{} chance to destroy",
            "all other Jokers",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 2,             -- uncommon
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            Xmult = big(3),
            last_round = nil,
        }
    },

    loc_vars = function(self, info_queue, card)
        local prob_mod = (G.GAME and G.GAME.probabilities and G.GAME.probabilities.normal) or 1
        return { vars = { card.ability.extra.Xmult, prob_mod } }
    end,

    calculate = function(self, card, context)
        -- Always applies, every hand, unconditionally.
        if context.joker_main then
            return {
                Xmult = card.ability.extra.Xmult,
                colour = G.C.MULT,
            }
        end

        -- Rolled exactly once per Boss Blind (deduped via last_round,
        -- same per-card round-stamp technique Overflow/Totem use
        -- elsewhere in this file) -- and can roll again on every future
        -- Boss Blind, not just the first one encountered.
        if context.first_hand_drawn
        and G.GAME.blind
        and G.GAME.blind.boss
        and not context.blueprint
        and card.ability.extra.last_round ~= G.GAME.round then

            card.ability.extra.last_round = G.GAME.round

            local prob_mod = (G.GAME and G.GAME.probabilities and G.GAME.probabilities.normal) or 1
            local chance = math.min(1, (1 / 6) * prob_mod)

            if pseudorandom(pseudoseed(mod.prefix .. "_russian_roulette")) < chance then
                -- Destroys every other eligible Joker -- reuses
                -- hex_huge_lqg_eligible_jokers so Eternal and Immortal
                -- Jokers are protected, same as Andromeda/Exile's own
                -- destroy effects elsewhere in this file.
                local eligible = hex_huge_lqg_eligible_jokers()

                for _, j in ipairs(eligible) do
                    if j ~= card then
                        G.E_MANAGER:add_event(Event({
                            trigger = "after",
                            delay = 0.1,
                            func = function()
                                j:start_dissolve()
                                return true
                            end
                        }))
                    end
                end

                return {
                    message = "BANG!",
                    colour = G.C.RED,
                }
            end
        end
    end,
}

-- Sharp Card: X4 Chips if the played hand type hasn't been played yet
-- this round. Tracked with our own round-scoped set (reset whenever
-- G.GAME.round changes) rather than any vanilla per-round counter,
-- since we can't verify a specific field name for that in this build.
-- The check-and-mark step only runs once per actual hand played
-- (stamped via G.GAME.current_round.hands_left, which decrements
-- exactly once per hand played), not once per Sharp Card owned --
-- otherwise a second copy would see the first copy's own mark and
-- wrongly treat a genuinely-new hand as already played.
SMODS.Joker{
    key = "sharp_card",

    loc_txt = {
        name = "Sharp Card",
        text = {
            "Gives {X:chips,C:white}X#1#{} Chips if the",
            "played hand hasn't been",
            "played yet this round",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 },
    in_pool = hex_in_pool,
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            x_chips = big(4),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.x_chips } }
    end,

    calculate = function(self, card, context)
        if context.before then
            G.GAME.hex_sharp_card_hands = G.GAME.hex_sharp_card_hands or {}

            if G.GAME.hex_sharp_card_round ~= G.GAME.round then
                G.GAME.hex_sharp_card_round = G.GAME.round
                G.GAME.hex_sharp_card_hands = {}
            end

            if G.GAME.hex_sharp_card_last_hands_left ~= G.GAME.current_round.hands_left then
                G.GAME.hex_sharp_card_last_hands_left = G.GAME.current_round.hands_left

                local hand_name = context.scoring_name
                G.GAME.hex_sharp_card_is_new_hand = hand_name and not G.GAME.hex_sharp_card_hands[hand_name]

                if hand_name then
                    G.GAME.hex_sharp_card_hands[hand_name] = true
                end
            end
        end

        if context.joker_main and G.GAME.hex_sharp_card_is_new_hand then
            return {
                x_chips = card.ability.extra.x_chips,
                colour = G.C.CHIPS,
            }
        end
    end,
}



SMODS.Joker{
    key = "big_find",

    loc_txt = {
        name = "Big Find",
        text = {
            "Booster Packs have",
            "{C:attention}+1{} more option",
            "{C:inactive}(Stacks with multiple copies{}",
            "{C:inactive}and other ways to get{}",
            "{C:inactive}more options){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 1, y = 0 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 3,             -- rare
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = false, -- the effect lives in the lifecycle hooks below, feeding the same shared G.GAME.hex_bigbox_bonus pool Big Box voucher/Card:open already read from
    eternal_compat = true,

    -- Feeds directly into the same G.GAME.hex_bigbox_bonus counter Big
    -- Box voucher bumps elsewhere in this file -- that field is already
    -- summed together with Wormhole's own bonus inside the Card:open
    -- wrap and applied to every Booster pack opened (Arcana, Celestial,
    -- Spectral, Standard, Buffoon, and this mod's own Star/Galaxy packs
    -- alike), so no separate wrap is needed here. Same add_to_deck/
    -- remove_from_deck lifecycle pair Open Market/Endless Abyss use
    -- elsewhere in this file -- applied exactly once no matter how the
    -- card enters/leaves your Jokers, and naturally stacks with itself
    -- since each copy bumps the shared pool independently.
    add_to_deck = function(self, card, from_debuff)
        G.GAME.hex_bigbox_bonus = (G.GAME.hex_bigbox_bonus or 0) + 1
    end,

    remove_from_deck = function(self, card, from_debuff)
        G.GAME.hex_bigbox_bonus = (G.GAME.hex_bigbox_bonus or 0) - 1
    end,
}



SMODS.Joker{
    key = "middle_finger",

    loc_txt = {
        name = "Middle Finger",
        text = {
            "If played hand contains a",
            "{C:attention}Straight{}, retriggers the",
            "{C:attention}middle{} card {C:attention}5{} extra times,",
            "but {C:red}no other cards score{}",
        }
    },

    config = {
        extra = {
            retriggers = 5,
        }
    },

    atlas = "HexJokers",
    pos = { x = 0, y = 1 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 1,              -- common
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.retriggers } }
    end,

    calculate = function(self, card, context)
        if context.before then
            card.ability.extra.middle_card = nil
            card.ability.extra.debuffed = nil

            local groups = context.poker_hands and context.poker_hands["Straight"]

            -- G.play.cards is the actual left-to-right position the
            -- player arranged before playing -- context.poker_hands'
            -- group list is built for hand-TYPE detection and isn't
            -- guaranteed to preserve that order, so for "3rd card as
            -- arranged" specifically, G.play.cards is the one to trust.
            if groups and #G.play.cards == 5 then
                local middle = G.play.cards[3]
                card.ability.extra.middle_card = middle
                card.ability.extra.debuffed = {}

                for _, c in ipairs(G.play.cards) do
                    if c ~= middle then
                        if SMODS.debuff_card then
                            SMODS.debuff_card(c, true, "hex_middle_finger")
                        elseif c.set_debuff then
                            c:set_debuff(true)
                        else
                            c.debuff = true
                        end
                        table.insert(card.ability.extra.debuffed, c)
                    end
                end
            end

            return
        end

        if context.after then
            if card.ability.extra.debuffed then
                for _, c in ipairs(card.ability.extra.debuffed) do
                    if SMODS.debuff_card then
                        SMODS.debuff_card(c, false, "hex_middle_finger")
                    elseif c.set_debuff then
                        c:set_debuff(false)
                    else
                        c.debuff = nil
                    end
                end
            end

            card.ability.extra.middle_card = nil
            card.ability.extra.debuffed = nil
            return
        end

        if context.repetition and context.cardarea == G.play and not context.blueprint then
            if context.other_card == card.ability.extra.middle_card then
                return {
                    message = localize("k_again_ex"),
                    repetitions = card.ability.extra.retriggers,
                    card = context.other_card,
                }
            end
        end
    end,
}


SMODS.Joker{
    key = "infestation",

    loc_txt = {
        name = "Infestation",
        text = {
            "Gives {C:purple}+1{} {C:purple}Hex point{}",
            "at the {C:attention}end of round{}",
            "Gain {C:purple}+1{} more per {C:attention}10{}",
            "Jokers {C:purple}hexed{} since owning this",
            "{C:inactive}(Currently {}+#1#{C:inactive} Hex points){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 1, y = 0 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 3,             -- rare
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = false, -- the counter lives on this specific card, and the increment hook targets Infestation by key -- a Blueprint copy wouldn't track its own count
    eternal_compat = true,

    config = {
        extra = {
            hexed_count = big(0),
        }
    },

    loc_vars = function(self, info_queue, card)
        local count = card.ability.extra.hexed_count or big(0)
        local gain = big(1):add(count:div(big(10)):floor())

        return { vars = { gain } }
    end,

    calculate = function(self, card, context)
        if context.end_of_round
        and not context.blueprint
        and card.hex_infestation_last_round ~= G.GAME.round then

            card.hex_infestation_last_round = G.GAME.round

            local count = card.ability.extra.hexed_count or big(0)
            local gain = big(1):add(count:div(big(10)):floor())

            G.GAME.hex_points = (G.GAME.hex_points or big(0)):add(gain)

            return {
                message = "+" .. tostring(gain) .. " Hex",
                colour = G.C.HEX_ORPLE,
            }
        end
    end,
}


-- Soul Candle: +7 Chips for every Hex point currently owned. Hex
-- points are an OmegaNum (big()) value in this mod, so the multiply
-- goes through the big-number API rather than plain Lua arithmetic.
SMODS.Joker{
    key = "soul_candle",

    loc_txt = {
        name = "Soul Candle",
        text = {
            "Gives {C:chips}+7{} Chips for",
            "every {C:purple}Hex point{} owned",
            "{C:inactive}(Currently {}{C:chips}+#1#{}{C:inactive} Chips){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 1, y = 0 },
    in_pool = hex_in_pool,
    rarity = 3,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    -- Shows the current live chip bonus (hex_points x 7) in the
    -- card's own text, computed the same way calculate() below applies
    -- it. Guards G.GAME being nil since loc_vars can also be called
    -- from the collection screen outside of a run.
    loc_vars = function(self, info_queue, card)
        local hex_points = (G.GAME and G.GAME.hex_points) or big(0)
        return { vars = { hex_points:mul(big(7)) } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            local hex_points = G.GAME.hex_points or big(0)

            if hex_points:gt(big(0)) then
                return {
                    chips = hex_points:mul(big(7)),
                    colour = G.C.CHIPS,
                }
            end
        end
    end,
}



SMODS.Joker{
    key = "planetarium",

    loc_txt = {
        name = "Planetarium",
        text = {
            "Creates a random",
            "{C:planet}Planet{} card every",
            "time you {C:red}discard{}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 0, y = 1 },

    rarity = 1,
    in_pool = hex_in_pool,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            last_discard_id = 0,
        }
    },

    calculate = function(self, card, context)
        if context.discard
        and not context.blueprint
        and card.ability.extra.last_discard_id ~= G.GAME.hex_discard_action_id then

            card.ability.extra.last_discard_id = G.GAME.hex_discard_action_id

            if G.consumeables and #G.consumeables.cards < G.consumeables.config.card_limit then
                G.E_MANAGER:add_event(Event({
                    trigger = "after",
                    delay = 0.2,
                    func = function()
                        local new_card = SMODS.create_card({
                            set = "Planet",
                            area = G.consumeables,
                        })

                        G.consumeables:emplace(new_card)
                        return true
                    end
                }))

                return {
                    message = "Planet",
                    colour = G.C.SECONDARY_SET.Planet,
                }
            end
        end
    end,
}







-- Scientist: +35 Chips at the end of round if no Tarot card was used
-- that round; using a Tarot resets the stored gain to 0 immediately.
-- Tarot usage is detected by wrapping Card:use_consumeable (the base
-- game's own "use this consumable" method) rather than a calculate
-- context flag, since there isn't a built-in context hook for
-- consumable use -- same monkey-patch approach this file already uses
-- for Card.start_dissolve above. Test this against your installed
-- build the way this file's other comments flag build-specific quirks;
-- if Card:use_consumeable doesn't fire the way expected, that's the
-- spot to adjust.
SMODS.Joker{
    key = "scientist",

    loc_txt = {
        name = "Scientist",
        text = {
            "Gains {C:chips}+#2#{} Chips at the",
            "end of round if you haven't",
            "used a {C:tarot}Tarot{} card that round",
            "{C:inactive}(Resets to {}{C:chips}+0{}{C:inactive} if you{}",
            "{C:inactive}use a {}{C:tarot}Tarot{}{C:inactive} card){}",
            "{C:inactive}(Currently {}{C:chips}+#1#{}{C:inactive} Chips){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 0, y = 1 },
    in_pool = hex_in_pool,
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            chips = big(0),
            chips_gain = big(35)
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.chips_gain } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                chips = card.ability.extra.chips,
            }
        end

        if context.end_of_round
        and not context.blueprint
        and card.hex_scientist_last_round ~= G.GAME.round then

            card.hex_scientist_last_round = G.GAME.round

            if not G.GAME.hex_scientist_tarot_used_this_round then
                card.ability.extra.chips = card.ability.extra.chips:add(card.ability.extra.chips_gain)

                return {
                    message = localize("k_upgrade_ex"),
                    colour = G.C.CHIPS,
                }
            end 

            -- reset the flag for next round regardless of which branch fired
            G.GAME.hex_scientist_tarot_used_this_round = false
        end
    end,
}

-- Hook for Scientist above: fires whenever ANY Tarot card is used
-- (built-in or custom), zeroing out every Scientist's stored gain
-- immediately and flagging the round so its end-of-round check above
-- skips the +35 gain this round too.
local hex_old_use_consumeable = Card.use_consumeable

function Card:use_consumeable(area, copier)
    if self.ability and self.ability.set == "Tarot" and not copier then
        G.GAME.hex_scientist_tarot_used_this_round = true

        if G.jokers and G.jokers.cards then
            for _, j in ipairs(G.jokers.cards) do
                if j.config and j.config.center
                and j.config.center.key == ("j_" .. mod.prefix .. "_scientist") then
                    j.ability.extra.chips = big(0)
                end
            end
        end
    end

    return hex_old_use_consumeable(self, area, copier)
end

-- Snapshot of the discard button press itself: how many cards were
-- selected, and a unique id for the action. Bartender checks these
-- instead of context.full_hand's size, since that field wasn't
-- reliably reflecting the whole discard batch per calculate call in
-- this installed build (it was firing once per discarded card instead
-- of once per discard action). Same "hook the real G.FUNCS handler"
-- approach the can_play/can_discard overrides above already use.
local hex_old_discard_from_highlighted = G.FUNCS.discard_cards_from_highlighted

G.FUNCS.discard_cards_from_highlighted = function(e, ...)
    G.GAME.hex_last_discard_count = (G.hand and G.hand.highlighted and #G.hand.highlighted) or 0
    G.GAME.hex_discard_action_id = (G.GAME.hex_discard_action_id or 0) + 1

    return hex_old_discard_from_highlighted(e, ...)
end





-- Baguette: starts at +10 Mult / +70 Chips, loses 2 Mult and 14 Chips at
-- the end of every round (5 rounds of decay brings both to exactly 0),
-- then destroys itself. Deduped with the same context.end_of_round +
-- per-card round-stamp technique Winning Streak uses elsewhere in this
-- file, so this only decays once per round even with retriggers/multiple
-- end-of-round passes.
SMODS.Joker{
    key = "baguette",

    loc_txt = {
        name = "Baguette",
        text = {
            "Gives {C:mult}+#1#{} Mult and",
            "{C:chips}+#2#{} Chips",
            "Loses {C:mult}2{} Mult and",
            "{C:chips}14{} Chips every round",
        }
    },

    atlas = "HexJokers",
    pos = { x = 0, y = 1 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 1,             -- common
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            mult = big(10),
            chips = big(70),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, card.ability.extra.chips } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                mult = card.ability.extra.mult,
                chips = card.ability.extra.chips,
            }
        end

        if context.end_of_round
        and not context.blueprint
        and card.hex_baguette_last_round ~= G.GAME.round then

            card.hex_baguette_last_round = G.GAME.round

            card.ability.extra.mult = card.ability.extra.mult:sub(big(2))
            if card.ability.extra.mult:lt(big(0)) then
                card.ability.extra.mult = big(0)
            end

            card.ability.extra.chips = card.ability.extra.chips:sub(big(14))
            if card.ability.extra.chips:lt(big(0)) then
                card.ability.extra.chips = big(0)
            end

            if card.ability.extra.mult:eq(big(0)) and card.ability.extra.chips:eq(big(0)) then
                -- Tracked globally, not on this card -- so Kasane Teto's
                -- own count stays correct even if it's picked up after
                -- this Baguette (or several) already burned out, the
                -- same "global run counter, read by whoever cares" shape
                -- G.GAME.hex_points uses elsewhere in this file.
                G.GAME.hex_baguette_destroyed = (G.GAME.hex_baguette_destroyed or 0) + 1

                G.E_MANAGER:add_event(Event({
                    trigger = "after",
                    delay = 0.3,
                    func = function()
                        card:start_dissolve()
                        return true
                    end
                }))

                return {
                    message = "Destroyed!",
                    colour = G.C.RED,
                }
            end

            return {
                message = "-2/14",
                colour = G.C.RED,
            }
        end
    end,
}

-- Kasane Teto: +30 Mult for every Baguette destroyed this run so far,
-- computed live off G.GAME.hex_baguette_destroyed (Baguette's own global
-- counter above) rather than an incrementally-grown local stat -- so the
-- total is correct regardless of when Kasane Teto was bought relative to
-- any Baguette's destruction.
SMODS.Joker{
    key = "kasane_teto",

    loc_txt = {
        name = "Kasane Teto",
        text = {
            "Gains {C:mult}+#2#{} Mult for every",
            "{C:attention}Baguette{} destroyed this run",
            "{C:inactive}(Currently {}{C:mult}+#1#{}{C:inactive} Mult){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 0, y = 2 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 2,             -- uncommon
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            mult_per_baguette = big(30),
        }
    },

    loc_vars = function(self, info_queue, card)
        local destroyed = (G.GAME and G.GAME.hex_baguette_destroyed) or 0
        local current_mult = card.ability.extra.mult_per_baguette:mul(big(destroyed))

        return { vars = { current_mult, card.ability.extra.mult_per_baguette } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            local destroyed = (G.GAME and G.GAME.hex_baguette_destroyed) or 0

            if destroyed > 0 then
                return {
                    mult = card.ability.extra.mult_per_baguette:mul(big(destroyed)),
                    colour = G.C.MULT,
                }
            end
        end
    end,
}



SMODS.Joker{
    key = "gambler_joker",

    loc_txt = {
        name = "Gambler Joker",
        text = {
            "When this Joker is sold,",
            "{C:green}#1# in 5{} chance to create",
            "a random {C:legendary,E:1}Legendary{} Joker",
        }
    },

    atlas = "HexJokers",
    pos = { x = 1, y = 0 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 3,             -- rare
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,

    -- Same "X in 5" display convention Sadprint uses -- prob_mod is
    -- G.GAME.probabilities.normal, the same global multiplier Oops! All
    -- 6s doubles (and stacks further with multiple copies), so the
    -- tooltip always matches the real odds rolled below.
    loc_vars = function(self, info_queue, card)
        local prob_mod = (G.GAME and G.GAME.probabilities and G.GAME.probabilities.normal) or 1
        return { vars = { 1 * prob_mod } }
    end,

    calculate = function(self, card, context)
        -- context.card is whichever Joker is actually being sold -- gated
        -- to context.card == card so this only fires on Gambler Joker's
        -- own sale, same pattern Sadprint uses elsewhere in this file.
        if context.selling_card and context.card == card then
            local prob_mod = (G.GAME and G.GAME.probabilities and G.GAME.probabilities.normal) or 1
            local chance = math.min(1, (1 / 5) * prob_mod)

            if pseudorandom(pseudoseed(mod.prefix .. "_gambler_joker")) < chance then
                -- Pool-scan + math.random (not pseudorandom_element) since
                -- some Legendary Jokers -- from this or other mods -- may
                -- set in_pool = false, which pseudorandom_element would
                -- otherwise filter out. Same Showman/uniqueness check
                -- Andromeda's own Legendary grant uses elsewhere in this
                -- file, so this respects "no duplicate Legendaries"
                -- unless Showman is owned.
                local showman_owned = hex_owns_showman()

                local legendaries = {}
                for _, center in pairs(G.P_CENTERS) do
                    if center.set == "Joker"
                    and center.rarity == 4
                    and (showman_owned or #SMODS.find_card(center.key) == 0) then
                        legendaries[#legendaries + 1] = center
                    end
                end

                if #legendaries > 0 then
                    local chosen = legendaries[math.random(#legendaries)]

                    G.E_MANAGER:add_event(Event({
                        trigger = "after",
                        delay = 0.2,
                        func = function()
                            local new_card = SMODS.create_card({
                                set = "Joker",
                                key = chosen.key,
                                area = G.jokers
                            })

                            G.jokers:emplace(new_card)
                            new_card:add_to_deck()

                            card_eval_status_text(new_card, "extra", nil, nil, nil, {
                                message = "JACKPOT!",
                                colour = G.C.LEGENDARY,
                            })

                            return true
                        end
                    }))
                end
            end
        end
    end,
}

-- Lucky Number 7: makes every Lucky-enhanced 7 always trigger its
-- effect(s), instead of rolling the normal 1 in 5 (Mult) / 1 in 15
-- (money) odds. Lucky Card's actual roll lives in vanilla's own
-- Card:get_chip_mult / Card:get_p_dollars (not in a center.calculate
-- function), so both are wrapped directly here -- for a Lucky-enhanced
-- 7 while this Joker is owned, the success branch is taken
-- unconditionally (mirroring vanilla's own success path exactly, just
-- without the pseudorandom() roll gating it); everything else --
-- non-7 Lucky cards, non-Lucky cards, Lucky 7s without this Joker
-- owned -- falls through to the original function untouched.
local function hex_lucky_number_7_owned()
    if not (G.jokers and G.jokers.cards) then return false end

    for _, j in ipairs(G.jokers.cards) do
        if j.config and j.config.center
        and j.config.center.key == ("j_" .. mod.prefix .. "_lucky_number_7") then
            return true
        end
    end

    return false
end

local hex_old_get_chip_mult = Card.get_chip_mult

function Card:get_chip_mult()
    if not self.debuff
    and self.ability and self.ability.set ~= 'Joker'
    and self.ability.effect == "Lucky Card"
    and self.base and self.base.value == "7"
    and hex_lucky_number_7_owned() then
        self.lucky_trigger = true
        return self.ability.mult
    end

    return hex_old_get_chip_mult(self)
end

local hex_old_get_p_dollars = Card.get_p_dollars

function Card:get_p_dollars()
    if not self.debuff
    and self.ability and self.ability.effect == "Lucky Card"
    and self.base and self.base.value == "7"
    and hex_lucky_number_7_owned() then
        local ret = 0

        if self.seal == 'Gold' then
            ret = ret + 3
        end

        if self.ability.p_dollars > 0 then
            self.lucky_trigger = true
            ret = ret + self.ability.p_dollars
        end

        if ret > 0 then 
            G.GAME.dollar_buffer = (G.GAME.dollar_buffer or 0) + ret
            G.E_MANAGER:add_event(Event({ func = (function() G.GAME.dollar_buffer = 0; return true end) }))
        end

        return ret
    end

    return hex_old_get_p_dollars(self)
end

SMODS.Joker{
    key = "lucky_number_7",

    loc_txt = {
        name = "Lucky Number 7",
        text = {
            "{C:attention}Lucky{} {C:attention}7s{} always succeed",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 2,             -- uncommon
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = false, -- the effect lives in the m_lucky wrap above, not in calculate(), so a copy wouldn't do anything extra
    eternal_compat = true,
}




SMODS.Joker{
    key = "scavenger",

    loc_txt = {
        name = "Scavenger",
        text = {
            "Gives a {C:attention}random Tag{}",
            "at the {C:attention}end of round{}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 2,             -- uncommon
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    calculate = function(self, card, context)
        -- Same per-card round-stamp dedupe technique Baguette/
        -- Accumulation use elsewhere in this file, so this only fires
        -- once per round even with retriggers or multiple end-of-round
        -- passes.
        if context.end_of_round
        and not context.blueprint
        and card.hex_scavenger_last_round ~= G.GAME.round then

            card.hex_scavenger_last_round = G.GAME.round

            -- pseudorandom_element over G.P_CENTER_POOLS.Tag -- the same
            -- pool-table shape SMODS.Rank/SMODS.Suit use for their own
            -- "random rank/suit respecting in_pool" pattern -- picks a
            -- random registered Tag (vanilla or modded), then grants it
            -- via add_tag(Tag(key)), the same API Bellatrix's own Double
            -- Tag grant uses elsewhere in this file.
            local pool = G.P_CENTER_POOLS.Tag
            if pool and #pool > 0 then
                local chosen = pseudorandom_element(pool, pseudoseed(mod.prefix .. "_scavenger"))
                add_tag(Tag(chosen.key))

                return {
                    message = "+Tag!",
                    colour = G.C.MULT,
                }
            end
        end
    end,
}



-- Employee Discount: -$1 to every Joker's cost (shop price AND, as a
-- direct consequence, sell value -- same "discount affects the
-- underlying cost field, so it reduces sell price too" behavior
-- vanilla's own Clearance Sale/Liquidation vouchers have), floored so
-- it can never drop below $1. Wraps Card:set_cost directly -- the same
-- vanilla function Clearance Sale/Liquidation hook into for their own
-- discount_percent -- rather than touching center.cost, since cost is
-- computed fresh (editions, Inflation, other discounts) every time
-- set_cost runs, and this needs to apply after all of that, gated
-- strictly to card.ability.set == "Joker" so playing cards, packs, and
-- vouchers are untouched.
local function hex_employee_discount_owned()
    if not (G.jokers and G.jokers.cards) then return false end

    for _, j in ipairs(G.jokers.cards) do
        if j.config and j.config.center
        and j.config.center.key == ("j_" .. mod.prefix .. "_employee_discount") then
            return true
        end
    end

    return false
end

local hex_old_set_cost_employee_discount = Card.set_cost

function Card:set_cost(...)
    hex_old_set_cost_employee_discount(self, ...)

    if self.ability and self.ability.set == "Joker" and hex_employee_discount_owned() then
        self.cost = math.max(1, self.cost - 1)
    end
end

SMODS.Joker{
    key = "employee_discount",

    loc_txt = {
        name = "Employee Discount",
        text = {
            "All {C:attention}Jokers{} cost {C:money}$1{} less",
            "{C:inactive}(Minimum $1){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 2,             -- uncommon
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = false, -- the effect lives in the Card:set_cost wrap above, gated on ownership directly, not in calculate() -- a Blueprint copy wouldn't do anything extra
    eternal_compat = true,
}


SMODS.Joker{
    key = "compound_interest",

    loc_txt = {
        name = "Compound Interest",
        text = {
            "Gives an extra {C:money}+$1{} when",
            "at the end of a",
            "Blind for every {C:purple}2{} {C:purple}Hex points{}",
            "{C:inactive}(Currently {}{C:money}+$#1#{}{C:inactive}){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 1, y = 0 },
    in_pool = hex_in_pool,
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,

    loc_vars = function(self, info_queue, card)
        local hex_points = (G.GAME and G.GAME.hex_points) or big(0)
        local bonus = hex_points:div(big(2)):floor()

        return { vars = { hex_to_plain_number(bonus) } }
    end,

    -- This is what evaluate_round actually calls (G.jokers.cards[i]:
    -- calculate_dollar_bonus()) to build the cash-out row for each
    -- joker -- not the normal calculate() function. Returns a plain
    -- number rather than a big() object, since evaluate_round's own
    -- handling (dollars:add(big(type(ret)=="number" and ret or
    -- ret.dollars or 0))) only safely handles a plain number or a
    -- {dollars = <plain number>} table here, not a raw big object.
    calc_dollar_bonus = function(self)
        local hex_points = (G.GAME and G.GAME.hex_points) or big(0)
        local bonus = hex_points:div(big(2)):floor()

        if bonus:gt(big(0)) then
            return hex_to_plain_number(bonus)
        end
    end,
}






-- Miner: +0.1 Xchips when a Stone card is triggered. Same enhancement
-- check pattern as your Bonus Joker above (context.other_card's
-- enhancement key), just checking m_stone instead of m_bonus. Counts
-- every trigger (retriggers included), same as your growth jokers.
SMODS.Joker{
    key = "miner",

    loc_txt = {
        name = "Steve the Minor",
        text = {
            "This Joker gains {X:chips,C:white}X#1#{} Chips",
            "when a {C:attention}Stone{} card is triggered",
            "{C:inactive}(Currently {}{X:chips,C:white}X#2#{}{C:inactive} Chips){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 4, y = 1 },
    in_pool = hex_in_pool,

    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            xchips = big(1),
            xchips_gain = big(0.1),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xchips_gain, card.ability.extra.xchips } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                x_chips = card.ability.extra.xchips,
            }
        end

        if context.individual and context.cardarea == G.play and not context.blueprint then
            local key = context.other_card.config and context.other_card.config.center
                and context.other_card.config.center.key

            if key == "m_stone" then
                card.ability.extra.xchips = card.ability.extra.xchips:add(card.ability.extra.xchips_gain)

                return {
                    message = localize("k_upgrade_ex"),
                    colour = G.C.CHIPS,
                }
            end
        end
    end,
}




SMODS.Joker{
    key = "organ_harvesting",

    loc_txt = {
        name = "Organ Harvesting",
        text = {
            "Gains {X:mult,C:white}X#3#{} Mult and",
            "{X:chips,C:white}X#4#{} Chips when",
            "{C:attention}selling{} a Joker",
            "{C:inactive}(Currently {}{X:mult,C:white}X#1#{}{C:inactive} Mult){}",
            "{C:inactive}{}{X:chips,C:white}X#2#{}{C:inactive} Chips){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 1, y = 0 },
    in_pool = hex_in_pool,

    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            Xmult = big(1),
            Xmult_gain = big(0.1),
            xchips = big(1),
            xchips_gain = big(0.1),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult, card.ability.extra.xchips, card.ability.extra.Xmult_gain, card.ability.extra.xchips_gain } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                Xmult = card.ability.extra.Xmult,
                x_chips = card.ability.extra.xchips,
            }
        end

        -- Same context.selling_card + context.card.ability.set == "Joker"
        -- check your own trash_bin joker above uses, just without its
        -- rarity == 3 restriction since this should fire on any Joker sold.
        if context.selling_card
        and context.card.ability
        and context.card.ability.set == "Joker" then

            card.ability.extra.Xmult = card.ability.extra.Xmult:add(card.ability.extra.Xmult_gain)
            card.ability.extra.xchips = card.ability.extra.xchips:add(card.ability.extra.xchips_gain)

            return {
                message = localize("k_upgrade_ex"),
                colour = G.C.MULT,
            }
        end
    end,
}


-- Cake: X3 Chips, decreasing by 0.25 every shop reroll. Uses
-- context.reroll_shop -- a documented flag used by vanilla's own Flash
-- Card ("+2 Mult per reroll in the shop"), just applied in the
-- opposite direction here. Clamped at 0 so it can't go negative and
-- invert the sign of your chip total.
SMODS.Joker{
    key = "cake",

    loc_txt = {
        name = "Cake",
        text = {
            "Gives {X:chips,C:white}X#1#{} Chips,",
            "decreases by {X:chips,C:white}0.25{} every",
            "time you {C:attention}reroll{} in the shop",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 },
    in_pool = hex_in_pool,

    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = false,

    config = {
        extra = {
            xchips = big(3),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { math.max(1, card.ability.extra.xchips) } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                x_chips = big(1):max(card.ability.extra.xchips),
                colour = G.C.CHIPS,
            }
        end

        if context.reroll_shop and not context.blueprint then
            card.ability.extra.xchips = (card.ability.extra.xchips):sub(0.25)

            if card.ability.extra.xchips <= 1 then
                card.ability.extra.xchips = 1

                G.E_MANAGER:add_event(Event({
                    trigger = "after",
                    delay = 0.3,
                    func = function()
                        card:start_dissolve()
                        return true
                    end
                }))
            end

            return {
                message = "-0.25",
                colour = G.C.CHIPS,
            }
        end
    end,
}



SMODS.Joker{
    key = "sadprint",

    loc_txt = {
        name = "Sadprint",
        text = {
            "When this Joker is sold,",
            "{C:green}#1# in 5{} chance to create",
            "a {C:blue}Blueprint{} Joker",
        }
    },

    atlas = "HexJokers",
    pos = { x = 1, y = 0 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 3,             -- rare
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,

    loc_vars = function(self, info_queue, card)
        local prob_mod = (G.GAME and G.GAME.probabilities and G.GAME.probabilities.normal) or 1
        return { vars = { 3 * prob_mod } }
    end,

    calculate = function(self, card, context)
        -- context.card is whichever Joker is actually being sold (same
        -- field Trash Bin's own sell-detection reads elsewhere in this
        -- file) -- gated to context.card == card so this only fires on
        -- Sadprint's own sale, not any other Joker's.
        if context.selling_card and context.card == card then
            local prob_mod = (G.GAME and G.GAME.probabilities and G.GAME.probabilities.normal) or 1
            local chance = math.min(1, (3 / 5) * prob_mod)

            if pseudorandom(pseudoseed(mod.prefix .. "_sadprint")) < chance then
                G.E_MANAGER:add_event(Event({
                    trigger = "after",
                    delay = 0.2,
                    func = function()
                        local new_card = SMODS.create_card({
                            set = "Joker",
                            key = "j_blueprint",
                            area = G.jokers
                        })

                        G.jokers:emplace(new_card)
                        new_card:add_to_deck()

                        card_eval_status_text(new_card, "extra", nil, nil, nil, {
                            message = "Blueprint!",
                            colour = G.C.BLUE,
                        })

                        return true
                    end
                }))
            end
        end
    end,
}


SMODS.Joker{
    key = "diversity",

    loc_txt = {
        name = "Diversity",
        text = {
            "Gives {X:mult,C:white}X#1#{} Mult if",
            "played hand contains",
            "{C:attention}5{} different ranks",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 2,             -- uncommon
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            Xmult = big(3),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult } }
    end,

    calculate = function(self, card, context)
        -- Resets the tracked rank set at the start of every hand's
        -- scoring pass -- same context.before reset timing Blackjack's
        -- own rank-sum accumulator uses above. Guarded with
        -- not context.blueprint so a Blueprint copy doesn't reset/
        -- re-accumulate its own separate set.
        if context.before and not context.blueprint then
            card.ability.extra.ranks_seen = {}
            card.ability.extra.rank_count = 0
        end

        -- Adds each scoring card's rank (base.value) to a set, counting
        -- only the first time a given rank is seen this hand -- so
        -- retriggers on the same card don't inflate the count, but two
        -- different scoring cards that happen to share a rank correctly
        -- only count once between them.
        if context.individual and context.cardarea == G.play and not context.blueprint then
            local rank = context.other_card.base and context.other_card.base.value

            if rank and card.ability.extra.ranks_seen and not card.ability.extra.ranks_seen[rank] then
                card.ability.extra.ranks_seen[rank] = true
                card.ability.extra.rank_count = (card.ability.extra.rank_count or 0) + 1
            end
        end

        -- By the time joker_main fires, every scoring card for this
        -- hand has already been counted above.
        if context.joker_main and (card.ability.extra.rank_count or 0) >= 5 then
            return {
                Xmult = card.ability.extra.Xmult,
                colour = G.C.MULT,
            }
        end
    end,
}

-- Bartender: $3 when you discard exactly one card. Fires at most once
-- per discard action (dedupe via hex_discard_action_id, stamped per
-- card so multiple Bartenders each still fire once), gated on the
-- pre-discard highlighted count captured above rather than
-- context.full_hand.
SMODS.Joker{
    key = "bartender",

    loc_txt = {
        name = "Bartender",
        text = {
            "Gives {C:money}+$#1#{} when you",
            "discard {C:attention}exactly one{} card",
        }
    },

    atlas = "HexJokers",
    pos = { x = 0, y = 1 },
    in_pool = hex_in_pool,
    rarity = 1,
    cost = 3,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            last_discard_id = 0,
            money = big(3),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.money } }
    end,

    calculate = function(self, card, context)
        if context.discard
        and not context.blueprint
        and (G.GAME.hex_last_discard_count or 0) == 1
        and card.ability.extra.last_discard_id ~= G.GAME.hex_discard_action_id then

            card.ability.extra.last_discard_id = G.GAME.hex_discard_action_id

            return {
                dollars = card.ability.extra.money,
                colour = G.C.MONEY,
            }
        end
    end,
}



SMODS.Joker{
    key = "slot_machine",

    loc_txt = {
        name = "Slot Machine",
        text = {
            "{C:green}#1# in 4{} chance to give",
            "{X:chips,C:white}X#2#{} Chips",
            "every hand played",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 2,             -- uncommon
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            x_chips = big(6),
        }
    },

    -- Same "#1# in N" display convention Crystal's own tooltip uses
    -- elsewhere in this file -- numerator scales with
    -- G.GAME.probabilities.normal, denominator stays fixed at 4.
    loc_vars = function(self, info_queue, card)
        local prob_mod = (G.GAME and G.GAME.probabilities and G.GAME.probabilities.normal) or 1
        return { vars = { prob_mod, card.ability.extra.x_chips } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            local prob_mod = (G.GAME and G.GAME.probabilities and G.GAME.probabilities.normal) or 1
            local chance = math.min(1, (1 / 4) * prob_mod)

            if pseudorandom(pseudoseed(mod.prefix .. "_slot_machine")) < chance then
                return {
                    x_chips = card.ability.extra.x_chips,
                    colour = G.C.CHIPS,
                }
            end
        end
    end,
}



local function hex_card_has_suit(c, suit)
    if not (c and c.base) then return false end
    return c.base.suit == suit
        or (SMODS.smeared_check and SMODS.smeared_check(c, suit))
end



SMODS.Joker{
    key = "scarlet_amber",

    loc_txt = {
        name = "Scarlet Amber",
        text = {
            "Each played {C:hearts}Heart{} or",
            "{C:diamonds}Diamond{} card gives",
            "{C:chips}+#1#{} Chips when scored",
        }
    },

    atlas = "HexJokers",
    pos = { x = 0, y = 1 },
    in_pool = hex_in_pool,
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            chips = big(20),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,

    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            if hex_card_has_suit(context.other_card, "Hearts") or hex_card_has_suit(context.other_card, "Diamonds") then
                return {
                    chips = card.ability.extra.chips,
                    card = context.other_card,
                    colour = G.C.CHIPS,
                }
            end
        end
    end,
}



SMODS.Joker{
    key = "teal_ink",

    loc_txt = {
        name = "Teal Ink",
        text = {
            "Each played {C:clubs}Club{} or",
            "{C:spades}Spade{} card gives",
            "{C:mult}+#1#{} Mult when scored",
        }
    },

    atlas = "HexJokers",
    pos = { x = 0, y = 1 },
    in_pool = hex_in_pool,
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            mult = big(2),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,

    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            if hex_card_has_suit(context.other_card, "Clubs") or hex_card_has_suit(context.other_card, "Spades") then
                return {
                    mult = card.ability.extra.mult,
                    card = context.other_card,
                    colour = G.C.MULT,
                }
            end
        end
    end,
}


-- Prime Lime: X1.5 Mult per played card whose rank is prime (2, 3, 5, 7,
-- Ace counted as 1). Fires per scoring card via context.individual +
-- cardarea == G.play, so each qualifying card stacks its own X1.5
-- multiplicatively, same pattern as Scarlet Amber/Teal Ink.
local hex_prime_ranks = {
    ["2"] = true,
    ["3"] = true,
    ["5"] = true,
    ["7"] = true,
    ["Ace"] = true,
}

SMODS.Joker{
    key = "prime_lime",

    loc_txt = {
        name = "Prime Lime",
        text = {
            "Gives {X:mult,C:white}X#1#{} Mult per",
            "played {C:attention}Prime{} card",
            "{C:inactive}(2, 3, 5, 7, Ace){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 1, y = 0 },
    in_pool = hex_in_pool,
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            x_mult = big(1.5),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.x_mult } }
    end,

    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            if context.other_card.base and hex_prime_ranks[context.other_card.base.value] then
                return {
                    x_mult = card.ability.extra.x_mult,
                    card = context.other_card,
                    colour = G.C.MULT,
                }
            end
        end
    end,
}




-- Lucky Duckie: X1.75 Chips per played card whose rank is 3, 7, or 9.
-- Same per-card individual-scoring pattern as Prime Lime.
local hex_lucky_ranks = {
    ["3"] = true,
    ["7"] = true,
    ["9"] = true,
}

SMODS.Joker{
    key = "lucky_duckie",

    loc_txt = {
        name = "Lucky Duckie",
        text = {
            "Gives {X:chips,C:white}X#1#{} Chips per",
            "played {C:attention}Lucky Number{} card",
            "{C:inactive}(3, 7, 9){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 1, y = 0 },
    in_pool = hex_in_pool,
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            x_chips = big(1.75),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.x_chips } }
    end,

    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            if context.other_card.base and hex_lucky_ranks[context.other_card.base.value] then
                return {
                    x_chips = card.ability.extra.x_chips,
                    card = context.other_card,
                    colour = G.C.CHIPS,
                }
            end
        end
    end,
}






-- Resonance: computed live off G.GAME.hex_points every time it's
-- needed (loc_vars display + the actual retrigger count below), same
-- "derived from current run state, not a stored counter" approach
-- Boykisser's own hex_points-based Xmult uses elsewhere in this file.
-- floor(hex_points / 20) gives the retrigger count (50 points floors
-- down to 2, same as 20/40 do to 1/2), capped at 10 so it can't scale
-- forever (hit at 200+ Hex points).
local function hex_resonance_retriggers()
    local hex_points = (G.GAME and G.GAME.hex_points) or big(0)
    local raw = hex_to_plain_number(hex_points:div(big(20)):floor())

    return math.min(10, math.max(0, math.floor(raw)))
end

SMODS.Joker{
    key = "resonance",

    loc_txt = {
        name = "Resonance",
        text = {
            "Retrigger each played card",
            "once for every {C:purple}20{} {C:purple}Hex points{}",
            "you have {C:inactive}(rounded down){}",
            "{C:inactive}(Max of #1# retriggers){}",
            "{C:inactive}(Currently {}#2#{C:inactive} retriggers){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 2,             -- uncommon
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    loc_vars = function(self, info_queue, card)
        return { vars = { 10, hex_resonance_retriggers() } }
    end,

    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play and not context.blueprint then
            local retriggers = hex_resonance_retriggers()

            if retriggers > 0 then
                return {
                    repetitions = retriggers,
                    card = context.other_card,
                }
            end
        end
    end,
}








-- Shared by all four "society" Jokers below: checks the plain and flush
-- variant of a custom poker hand independently via context.poker_hands
-- (keyed by mod.prefix .. "_<key>", confirmed from the crash log's own
-- poker_hands dump) rather than context.scoring_name -- the flush
-- variant always out-scores the plain one, so scoring_name alone would
-- never read as the plain hand's name once the flush condition is also
-- met. Since every flush variant's evaluate() condition is strictly a
-- superset of its plain variant's, both entries populate together
-- whenever the flush case applies, so returning both bonuses in the
-- same table is safe -- there's no case where only the flush key alone
-- is populated.
local function hex_society_hand_bonus(context, hand_key, flush_key, Xmult, x_chips)
    if not context.joker_main then return end

    local ret = nil

    if next(context.poker_hands[mod.prefix .. "_" .. hand_key]) then
        ret = ret or {}
        ret.Xmult = Xmult
        ret.colour = G.C.MULT
    end

    if next(context.poker_hands[mod.prefix .. "_" .. flush_key]) then
        ret = ret or {}
        ret.x_chips = x_chips
        ret.colour = G.C.CHIPS
    end

    return ret
end

SMODS.Joker{
    key = "the_assembly",

    loc_txt = {
        name = "The Assembly",
        text = {
            "Gives {X:mult,C:white}X#1#{} Mult if",
            "played hand is a {C:attention}Three Pair{}",
            "Also gives {X:chips,C:white}X#2#{} Chips if",
            "it's a {C:attention}Flush Three Pair{}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 1, y = 0 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 3,             -- rare
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            Xmult = big(5),
            x_chips = big(3),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult, card.ability.extra.x_chips } }
    end,

    calculate = function(self, card, context)
        return hex_society_hand_bonus(context, "three_pair", "flush_three_pair",
            card.ability.extra.Xmult, card.ability.extra.x_chips)
    end,
}

SMODS.Joker{
    key = "the_legion",

    loc_txt = {
        name = "The Legion",
        text = {
            "Gives {X:mult,C:white}X#1#{} Mult if",
            "played hand is a {C:attention}Four Pair{}",
            "Also gives {X:chips,C:white}X#2#{} Chips if",
            "it's a {C:attention}Flush Four Pair{}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 1, y = 0 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 3,             -- rare
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            Xmult = big(6),
            x_chips = big(4),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult, card.ability.extra.x_chips } }
    end,

    calculate = function(self, card, context)
        return hex_society_hand_bonus(context, "four_pair", "flush_four_pair",
            card.ability.extra.Xmult, card.ability.extra.x_chips)
    end,
}

SMODS.Joker{
    key = "the_union",

    loc_txt = {
        name = "The Union",
        text = {
            "Gives {X:mult,C:white}X#1#{} Mult if",
            "played hand is a",
            "{C:attention}Dual Three of a Kind{}",
            "Also gives {X:chips,C:white}X#2#{} Chips if",
            "it's a {C:attention}Flush Dual Three of a Kind{}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 1, y = 0 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 3,             -- rare
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            Xmult = big(5),
            x_chips = big(4),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult, card.ability.extra.x_chips } }
    end,

    calculate = function(self, card, context)
        return hex_society_hand_bonus(context, "dual_three_of_a_kind", "flush_dual_three_of_a_kind",
            card.ability.extra.Xmult, card.ability.extra.x_chips)
    end,
}

SMODS.Joker{
    key = "the_nation",

    loc_txt = {
        name = "The Nation",
        text = {
            "Gives {X:mult,C:white}X#1#{} Mult if",
            "played hand is a {C:attention}Grand House{}",
            "Also gives {X:chips,C:white}X#2#{} Chips if",
            "it's a {C:attention}Flush Grand House{}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 1, y = 0 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 3,             -- rare
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            Xmult = big(10),
            x_chips = big(7),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult, card.ability.extra.x_chips } }
    end,

    calculate = function(self, card, context)
        return hex_society_hand_bonus(context, "grand_house", "flush_grand_house",
            card.ability.extra.Xmult, card.ability.extra.x_chips)
    end,
}





SMODS.Joker{
    key = "mandelbrot_set",

    loc_txt = {
        name = "Mandelbrot Set",
        text = {
            "{C:attention}+2{} card selection limit",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 }, -- placeholder art slot

    rarity = 2,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = false, -- matches Polydactyly: this is a passive "owned" state check, not a calculate effect, so Blueprint copying it wouldn't do anything meaningful
    eternal_compat = true,
}




-- Counts currently-owned Jokers (G.jokers.cards, including this card
-- itself if it happens to carry a matching edition) with the given
-- edition key set -- same "foil"/"holo"/"polychrome" field names
-- Barnard's Star already uses elsewhere in this file for j.edition.
local function hex_count_edition_jokers(edition_key)
    if not (G.jokers and G.jokers.cards) then return 0 end

    local count = 0
    for _, j in ipairs(G.jokers.cards) do
        if j.edition and j.edition[edition_key] then
            count = count + 1
        end
    end

    return count
end

SMODS.Joker{
    key = "edition_joker",

    loc_txt = {
        name = "Edition Joker",
        text = {
            "Gives {C:chips}+#1#{} Chips per {C:dark_edition}Foil{}",
            "Joker, {C:mult}+#2#{} Mult per",
            "{C:dark_edition}Holographic{} Joker, and",
            "{X:mult,C:white}+#3#{} Xmult per",
            "{C:dark_edition}Polychrome{} Joker you own",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 2,             -- uncommon 
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            chips_per_foil = big(50),
            mult_per_holo = big(10),
            xmult_per_poly = big(0.5),
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.chips_per_foil,
                card.ability.extra.mult_per_holo,
                card.ability.extra.xmult_per_poly,
            }
        }
    end,

    -- Live, fully dynamic -- same "derived from current state every time
    -- it scores" approach Stamp Collection/Boykisser use elsewhere in
    -- this file, rather than a permanent stacking counter. Rises and
    -- falls immediately as Jokers with these editions are bought, sold,
    -- destroyed, or re-edition'd.
    calculate = function(self, card, context)
        if context.joker_main then
            local foil_count = hex_count_edition_jokers("foil")
            local holo_count = hex_count_edition_jokers("holo")
            local poly_count = hex_count_edition_jokers("polychrome")

            local chips = card.ability.extra.chips_per_foil:mul(big(foil_count))
            local mult = card.ability.extra.mult_per_holo:mul(big(holo_count))
            local xmult = big(1):add(card.ability.extra.xmult_per_poly:mul(big(poly_count)))

            return {
                chips = chips,
                mult = mult,
                Xmult = xmult,
                colour = G.C.MULT,
            }
        end
    end,
}


-- Trans Pride: +0.1 Xchips and +0.1 Xmult for every time a PLAYING
-- CARD you own has its edition, suit, rank, enhancement, or seal
-- changed, since this specific card was added to your Jokers.
-- change_count lives on THIS card's own ability.extra (same per-
-- instance-tracking approach Infestation's hexed_count uses elsewhere
-- in this file), incremented for every currently-owned copy
-- independently -- so multiple copies each track their own total
-- starting from their own add_to_deck moment, same as Infestation.
--
-- Wraps Card:set_edition, Card:set_ability (enhancements),
-- Card:set_seal, and Card:set_base (suit/rank -- vanilla sets a card's
-- identity as one base object covering both together, not as separate
-- setters). CHANGED: each wrap now passes the card being modified into
-- hex_trans_pride_tick, which only counts it if it's an owned playing
-- card -- shop rerolls, pack contents, and Joker edition/ability
-- changes no longer tick the counter.
local function hex_is_owned_playing_card(target_card)
    if not (G.playing_cards and target_card) then return false end

    for _, c in ipairs(G.playing_cards) do
        if c == target_card then
            return true
        end
    end

    return false
end

local function hex_trans_pride_tick(target_card)
    if not hex_is_owned_playing_card(target_card) then return end
    if not (G.jokers and G.jokers.cards) then return end

    for _, j in ipairs(G.jokers.cards) do
        if j.config and j.config.center
        and j.config.center.key == ("j_" .. mod.prefix .. "_trans_pride") then

            j.ability.extra.change_count = (j.ability.extra.change_count or big(0)):add(big(1))
        end
    end
end

local hex_old_set_edition_trans_pride = Card.set_edition
function Card:set_edition(...)
    hex_trans_pride_tick(self)
    return hex_old_set_edition_trans_pride(self, ...)
end

-- set_ability's second arg is `initial` -- true when a card's ability
-- is just being (re)established (card/joker creation, shop reroll/
-- dedupe swaps) rather than an actual gameplay change. Skipped so
-- creation noise doesn't tick the counter even on the rare chance a
-- playing card is somehow re-initialized outside G.playing_cards.
local hex_old_set_ability_trans_pride = Card.set_ability
function Card:set_ability(center, initial, ...)
    if not initial then
        hex_trans_pride_tick(self)
    end
    return hex_old_set_ability_trans_pride(self, center, initial, ...)
end

local hex_old_set_seal_trans_pride = Card.set_seal
function Card:set_seal(...)
    hex_trans_pride_tick(self)
    return hex_old_set_seal_trans_pride(self, ...)
end

local hex_old_set_base_trans_pride = Card.set_base
function Card:set_base(...)
    hex_trans_pride_tick(self)
    return hex_old_set_base_trans_pride(self, ...)
end

SMODS.Joker{
    key = "trans_pride",

    loc_txt = {
        name = "Trans Pride",
        text = {
            "Gives {X:chips,C:white}X#1#{} Chips and",
            "{X:mult,C:white}X#1#{} Mult for every time",
            "a card {C:attention}you own{}'s {C:attention}Edition{}, {C:attention}Suit{},",
            "{C:attention}Rank{}, {C:attention}Enhancement{}, or {C:attention}Seal{} changes",
            "since owning this",
            "{C:inactive}(Currently {}{X:purple,C:white}X#2#{}{C:inactive} Chips and Mult){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 8, y = 0 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 3,             -- rare
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true, -- change_count is per-instance and targeted by key in the wraps above -- a Blueprint copy wouldn't track its own count
    eternal_compat = true,

    config = {
        extra = {
            per_change = big(0.1),
            change_count = big(0),
        }
    },

    add_to_deck = function(self, card, from_debuff)
        card.ability.extra.change_count = big(0)
    end,

    loc_vars = function(self, info_queue, card)
        local count = card.ability.extra.change_count or big(0)
        local stat = big(1):add(card.ability.extra.per_change:mul(count))

        return { vars = { card.ability.extra.per_change, stat } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            local count = card.ability.extra.change_count or big(0)
            local stat = big(1):add(card.ability.extra.per_change:mul(count))

            return {
                x_chips = stat,
                Xmult = stat,
                colour = G.C.MULT,
            }
        end
    end,
}




-- The Death Card: X3 Chips and X3 Mult for every played Ace of Spades.
-- Fires per scoring card via context.individual + cardarea == G.play, so
-- multiple Aces of Spades in the same hand each apply their own X3/X3
-- multiplicatively (stacking naturally through the normal scoring loop,
-- same as any other per-card Xchips/Xmult joker).
SMODS.Joker{
    key = "the_death_card",

    loc_txt = {
        name = "The Death Card",
        text = {
            "Gives {X:chips,C:white}X#1#{} Chips and",
            "{X:mult,C:white}X#1#{} Mult for every",
            "played {C:spades}Ace of Spades{}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 1, y = 0 },
    in_pool = hex_in_pool,
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            x_chips = big(3),
            Xmult = big(3),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.x_chips } }
    end,

    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            if context.other_card.base
            and context.other_card.base.value == "Ace"
            and hex_card_has_suit(context.other_card, "Spades") then

                return {
                    x_chips = card.ability.extra.x_chips,
                    Xmult = card.ability.extra.Xmult,
                    card = context.other_card,
                    colour = G.C.CHIPS,
                }
            end
        end
    end,
}



SMODS.Joker{
    key = "second_sight",

    loc_txt = {
        name = "Second Sight",
        text = {
            "Creates a {C:tarot}Tarot{} card if",
            "the played hand is a single",
            "scoring {C:attention}2{}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 0, y = 1 },
    in_pool = hex_in_pool,
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    calculate = function(self, card, context)
        if context.before
        and next(context.poker_hands["High Card"])
        and #context.full_hand == 1
        and context.full_hand[1].base.value == "2"
        and not context.blueprint then

            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.2,
                func = function()
                    if G.consumeables and #G.consumeables.cards < G.consumeables.config.card_limit then
                        local tarot_card = SMODS.create_card({
                            set = "Tarot",
                            area = G.consumeables,
                        })
                        G.consumeables:emplace(tarot_card)
                    end
                    return true
                end
            }))

            return {
                message = "+Tarot",
                colour = G.C.SECONDARY_SET.Tarot,
            }
        end
    end,
}


-- Blackjack: X2 Mult and X3 Chips if the played hand's scoring cards'
-- rank values add up to exactly 21. Uses the same rank-value mapping
-- Face Value's own per-card Mult reads off base.value elsewhere in this
-- file (Ace = 11, King/Queen/Jack = 10, number cards = face value).
local HEX_BLACKJACK_RANK_VALUES = {
    ["Ace"] = 11,
    ["King"] = 10,
    ["Queen"] = 10,
    ["Jack"] = 10,
    ["10"] = 10,
    ["9"] = 9,
    ["8"] = 8,
    ["7"] = 7,
    ["6"] = 6,
    ["5"] = 5,
    ["4"] = 4,
    ["3"] = 3,
    ["2"] = 2,
}

SMODS.Joker{
    key = "blackjack",

    loc_txt = {
        name = "Blackjack",
        text = {
            "{X:mult,C:white}X#1#{} Mult and",
            "{X:chips,C:white}X#2#{} Chips if played",
            "hand's scoring cards add",
            "up to {C:attention}exactly 21{}",
            "{C:inactive}(Ace=11, King/Queen/Jack=10){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 2,             -- 1 common, 2 uncommon, 3 rare, 4 legendary
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            Xmult = big(2),
            x_chips = big(3),
            hand_rank_sum = 0,
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult, card.ability.extra.x_chips } }
    end,

    calculate = function(self, card, context)
        -- Resets the running rank total at the start of every hand's
        -- scoring pass. context.before fires once per hand, ahead of
        -- both the per-card context.individual triggers below and this
        -- joker's own context.joker_main further down -- same ordering
        -- Sharp Card's own context.before reset relies on elsewhere in
        -- this file. Guarded with not context.blueprint so a Blueprint
        -- copy sitting next to this doesn't reset/re-accumulate its own
        -- separate count.
        if context.before and not context.blueprint then
            card.ability.extra.hand_rank_sum = 0
        end

        -- Adds up every scoring card's rank value as it's scored, using
        -- the same base.value rank lookup Face Value's own per-card
        -- Mult reads elsewhere in this file. Retriggered cards count
        -- more than once, same convention this file's other per-card
        -- accumulators (Cubed Joker, Hatsune Miku) already use.
        if context.individual and context.cardarea == G.play and not context.blueprint then
            local rank_value = context.other_card.base and HEX_BLACKJACK_RANK_VALUES[context.other_card.base.value]

            if rank_value then
                card.ability.extra.hand_rank_sum = (card.ability.extra.hand_rank_sum or 0) + rank_value
            end
        end

        -- By the time joker_main fires, every scoring card for this
        -- hand has already been counted above.
        if context.joker_main and card.ability.extra.hand_rank_sum == 21 then
            return {
                x_chips = card.ability.extra.x_chips,
                Xmult = card.ability.extra.Xmult,
                colour = G.C.MULT,
            }
        end
    end,
}



SMODS.Joker{
    key = "receipt",

    loc_txt = {
        name = "Receipt",
        text = {
            "Gives {C:money}+$1{} every time",
            "you open a {C:attention}Booster Pack{}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 0, y = 1 },
    in_pool = hex_in_pool,
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    calculate = function(self, card, context)
        if context.open_booster and not context.blueprint then
            return {
                dollars = big(1),
                colour = G.C.MONEY,
            }
        end
    end,
}






-- Encore: retriggers Bonus and Mult enhancement cards once more.
-- Standard vanilla retrigger-joker shape (context.repetition +
-- context.cardarea == G.play, returning repetitions alongside the
-- specific context.other_card), same pattern Orange/Green Seal use
-- above in content.lua, just gated on the card's enhancement key
-- instead of applying to every card unconditionally.
SMODS.Joker{
    key = "encore",

    loc_txt = {
        name = "Encore",
        text = {
            "retigger played",
            "{C:attention}Bonus{} and {C:attention}Mult{} cards",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 },
    in_pool = hex_in_pool,
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play and not context.blueprint then
            local key = context.other_card.config and context.other_card.config.center
                and context.other_card.config.center.key

            if key == "m_bonus" or key == "m_mult" then
                return {
                    repetitions = 1,
                    card = context.other_card,
                }
            end
        end
    end,
}

-- File-scope, unsaved table tracking which cards scored this hand, keyed
-- per Dead Weight card. Deliberately kept OUTSIDE card.ability/
-- card.config (which the save serializer walks) -- the previous version
-- stored this inside card.ability.extra with live Card objects as table
-- keys, which put real Card references into the save graph and produced
-- genuine cycles (Card -> area -> cards list -> same Card), crashing on
-- save with "Cycle detected in table". A plain local here is never
-- reached by the save code, so it's safe to hold live Card references.
local hex_dead_weight_scored = {}

SMODS.Joker{
    key = "dead_weight",

    loc_txt = {
        name = "Dead Weight",
        text = {
            "Gives {C:mult}+#1#{} Mult for every",
            "{C:attention}unscored{} card in play",
        }
    },

    atlas = "HexJokers",
    pos = { x = 0, y = 1 },
    in_pool = hex_in_pool,
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            mult_per_card = big(6),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult_per_card } }
    end,

    calculate = function(self, card, context)
        if context.before then
            hex_dead_weight_scored[card] = {}
        end

        if context.individual and context.cardarea == G.play and not context.blueprint then
            hex_dead_weight_scored[card] = hex_dead_weight_scored[card] or {}
            hex_dead_weight_scored[card][context.other_card] = true
        end

        if context.joker_main then
            local scored = hex_dead_weight_scored[card] or {}
            local unscored = 0

            for _, c in ipairs(G.play.cards) do
                if not scored[c] then
                    unscored = unscored + 1
                end
            end

            if unscored > 0 then
                return {
                    mult = big(unscored):mul(card.ability.extra.mult_per_card),
                    colour = G.C.MULT,
                }
            end
        end
    end,

    -- Cleans up this card's entry in the tracking table when it leaves
    -- play (sold/destroyed), so stale entries don't just accumulate for
    -- the rest of the run.
    remove_from_deck = function(self, card, from_debuff)
        hex_dead_weight_scored[card] = nil
    end,
}


SMODS.Joker{
    key = "wild_joker",

    loc_txt = {
        name = "Wild Joker",
        text = {
            "Retigger played {C:attention}Wild{} cards",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 },
    in_pool = hex_in_pool,
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play and not context.blueprint then
            local key = context.other_card.config and context.other_card.config.center
                and context.other_card.config.center.key

            if key == "m_wild" then
                return {
                    repetitions = 1,
                    card = context.other_card,
                }
            end
        end
    end,
}


-- Landlord: X4 Mult while money is in debt, and raises the debt ceiling
-- to -$30 while owned. bankrupt_at isn't set once on pickup -- it's
-- recomputed fresh every frame from whichever debt-granting sources are
-- currently owned (this joker, plus vanilla's own Credit Card at -$20),
-- the same "poll in Game:update" approach Wall Clock/Taxes Due already
-- use elsewhere in this file. Recomputing from scratch each frame (vs.
-- incrementally raising/lowering it) means add/remove/sell order can
-- never leave it stuck at the wrong value, and multiple debt sources
-- correctly stack to whichever is most generous (lowest).
local HEX_LANDLORD_DEBT_LIMIT = -30

local function hex_landlord_calc_bankrupt_at()
    local floor = 0

    if G.jokers and G.jokers.cards then
        for _, j in ipairs(G.jokers.cards) do
            if j.config and j.config.center then
                local key = j.config.center.key

                if key == "j_credit_card" then
                    floor = math.min(floor, -20)
                elseif key == ("j_" .. mod.prefix .. "_landlord") then
                    floor = math.min(floor, HEX_LANDLORD_DEBT_LIMIT)
                end
            end
        end
    end

    return floor
end

local hex_old_update_landlord = Game.update

function Game:update(dt)
    hex_old_update_landlord(self, dt)

    if G.jokers and G.jokers.cards and G.GAME then
        G.GAME.bankrupt_at = hex_landlord_calc_bankrupt_at()
    end
end

SMODS.Joker{
    key = "landlord",

    loc_txt = {
        name = "Landlord",
        text = {
            "{X:mult,C:white}X#1#{} Mult if your",
            "{C:money}money{} is {C:attention}in debt{}",
            "Allows money to go up to",
            "{C:money}-$#2#{}{} in debt",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 2,             -- 1 common, 2 uncommon, 3 rare, 4 legendary
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            Xmult = big(4),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult, -HEX_LANDLORD_DEBT_LIMIT } }
    end,

    calculate = function(self, card, context)
        if context.joker_main and G.GAME.dollars:lt(big(0)) then
            return {
                Xmult = card.ability.extra.Xmult,
                colour = G.C.MULT,
            }
        end
    end,
}






-- Bulletproof: makes Glass Cards' break roll always fail, AND updates
-- Glass's own tooltip to display "0 in 4" while owned. Both hooks wrap
-- Glass's own center functions directly (the same functions Crystal's
-- "#1# in 2" tooltip pattern elsewhere in this file relies on for its
-- own probability display) rather than guessing at internals:
--   - calculate() is wrapped to strip the `remove` result on the
--     destroy_card pass, so the card physically never breaks.
--   - loc_vars() is wrapped to zero out the numerator it feeds into
--     Glass's "#1# in 4" text, so the tooltip reads "0 in 4" too.
-- Both wraps happen lazily on the first Game:update tick rather than at
-- file load, since G.P_CENTERS.m_glass may not exist yet at the point
-- this file's top-level code runs.
local function hex_bulletproof_owned()
    if not (G.jokers and G.jokers.cards) then return false end

    for _, j in ipairs(G.jokers.cards) do
        if j.config and j.config.center
        and j.config.center.key == ("j_" .. mod.prefix .. "_bulletproof") then
            return true
        end
    end

    return false
end

local hex_glass_calculate_wrapped = false

local function hex_wrap_glass_calculate()
    if hex_glass_calculate_wrapped then return end
    if not (G.P_CENTERS and G.P_CENTERS.m_glass and G.P_CENTERS.m_glass.calculate) then return end

    local hex_old_glass_calculate = G.P_CENTERS.m_glass.calculate

    G.P_CENTERS.m_glass.calculate = function(self, card, context)
        local ret = hex_old_glass_calculate(self, card, context)

        if ret and ret.remove and context.destroy_card and hex_bulletproof_owned() then
            ret.remove = nil -- card survives -- 0 in 4 chance to break while owned
        end

        return ret
    end

    hex_glass_calculate_wrapped = true
end




local hex_old_update_bulletproof = Game.update

function Game:update(dt)
    hex_old_update_bulletproof(self, dt)
    hex_wrap_glass_calculate()
end

SMODS.Joker{
    key = "bulletproof",

    loc_txt = {
        name = "Bulletproof",
        text = {
            "{C:attention}Glass Cards{} never break",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 2,             -- 1 common, 2 uncommon, 3 rare, 4 legendary
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,

}


-- 01101010: destroys itself the instant you're holding more than 3
-- Jokers (this one included) -- checked every frame via Game:update
-- rather than only during calculate()'s context.joker_main, since the
-- old version only re-checked the count when a hand was actually
-- played, so it never reacted to just picking up a 4th Joker. Guarded
-- with hex_01101010_dissolving so it only calls start_dissolve() once
-- per card, instead of every single frame while the dissolve animation
-- is still playing out.
local hex_01101010_dissolving = {}

local hex_old_update_01101010 = Game.update

function Game:update(dt)
    hex_old_update_01101010(self, dt)

    if G.jokers and G.jokers.cards and #G.jokers.cards > 3 then
        for _, j in ipairs(G.jokers.cards) do
            if j.config and j.config.center
            and j.config.center.key == ("j_" .. mod.prefix .. "_01101010")
            and not hex_01101010_dissolving[j] then

                hex_01101010_dissolving[j] = true
                HEX_01101010_SHOULD_CRASH = true 

                card_eval_status_text(j, "extra", nil, nil, nil, {
                    message = "Destroyed!",
                    colour = G.C.RED,
                })

                j:start_dissolve()
            end
        end
    end
end


SMODS.Joker{
    key = "01101010",

    loc_txt = {
        name = "01101010",
        text = {
            "Gives {C:mult}+100{} Mult",
            "{C:red}Crashs{} the game if you have",
            "more than {C:attention}3{} Jokers",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 2,             -- 1 common, 2 uncommon, 3 rare, 4 legendary
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = false,

    config = {
        extra = {
            mult = big(100),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,


    calculate = function(self, card, context)
        if context.joker_main then

            return {
                mult = card.ability.extra.mult,
                colour = G.C.MULT,
            }
        end
    end,
}

-- Winning Streak: +7 Mult permanently for every Blind won in exactly one hand;
-- resets to 0 the moment a Blind takes more than one hand to win.
-- Hands played this round are counted at context.joker_main (fires
-- once per hand played), checked/reset at context.end_of_round (once
-- per round, deduped with the same per-card round-stamp technique used
-- by Overflow/Snowball/Totem/Scientist above).
SMODS.Joker{
    key = "streak",

    loc_txt = {
        name = "Winning Streak",
        text = {
            "Gains {C:mult}+#2#{} Mult for every",
            "Blind won in {C:attention}one hand{},",
            "resets if it isn't",
            "{C:inactive}(Currently {}{C:mult}+#1#{}{C:inactive} Mult){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 0, y = 1 },
    in_pool = hex_in_pool,
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            mult = big(0),
            hands_this_round = 0,
            mult_gain = big(7),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, card.ability.extra.mult_gain } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            card.ability.extra.hands_this_round = (card.ability.extra.hands_this_round or 0) + 1

            return {
                mult = card.ability.extra.mult,
            }
        end

        if context.end_of_round
        and not context.blueprint
        and card.hex_streak_last_round ~= G.GAME.round then

            card.hex_streak_last_round = G.GAME.round

            if (card.ability.extra.hands_this_round or 0) == 1 then
                card.ability.extra.mult = (card.ability.extra.mult):add(card.ability.extra.mult_gain)
            else
                card.ability.extra.mult = big(0)
            end

            card.ability.extra.hands_this_round = 0

            return {
                message = localize("k_upgrade_ex"),
                colour = G.C.MULT,
            }
        end
    end,
}






SMODS.Joker{
    key = "leftovers",

    loc_txt = {
        name = "Leftovers",
        text = {
            "Cards {C:attention}held in hand{}",
            "give {C:chips}+10{} Chips",
        }
    },

    atlas = "HexJokers",
    pos = { x = 0, y = 1 },
    in_pool = hex_in_pool,
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    calculate = function(self, card, context)
        -- context.individual + cardarea == G.hand fires twice: once
        -- during the normal held-card scoring pass (what we want), and
        -- again during the End of Round held-card re-evaluation (same
        -- Card Evaluation steps, reused) -- excluding
        -- context.end_of_round is what keeps this to the one, correctly
        -- timed trigger per hand played.
        if context.individual
        and context.cardarea == G.hand
        and not context.end_of_round
        and not context.blueprint then

            return {
                chips = big(10),
                card = context.other_card,
                colour = G.C.CHIPS,
            }
        end
    end,
}

SMODS.Joker{
    key = "chameleon",

    loc_txt = {
        name = "Chameleon",
        text = {
            "Played {C:attention}Aces{} become",
            "{C:attention}Wild Cards{}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 },

    rarity = 2,
    in_pool = hex_in_pool,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,

    calculate = function(self, card, context)
        if context.individual
        and context.cardarea == G.play
        and not context.blueprint
        and context.other_card.base.value == "Ace"
        and not (context.other_card.config and context.other_card.config.center
            and context.other_card.config.center.key == "m_wild") then
            -- only re-apply if it isn't already Wild, so retriggers on
            -- the same Ace don't spam the upgrade popup

            context.other_card:set_ability(G.P_CENTERS.m_wild, nil, true)

            return {
                message = localize("k_upgrade_ex"),
                colour = G.C.SECONDARY_SET.Enhanced,
            }
        end
    end,
}


-- Wall Clock: +10 Chips and +1 Mult every 10 real-world seconds since
-- this card was acquired. Chains onto Game:update the same way the
-- Absolute rarity's rainbow-color effect already does in main.lua
-- (captures the previous Game.update, calls it first, then does its
-- own thing) -- this is a second, independent hook on top of that one,
-- so both run every frame without conflicting.
local hex_old_update_wall_clock = Game.update

function Game:update(dt)
    hex_old_update_wall_clock(self, dt)

    if G.jokers and G.jokers.cards then
        for _, j in ipairs(G.jokers.cards) do
            if j.config and j.config.center
            and j.config.center.key == ("j_" .. mod.prefix .. "_wall_clock") then

                -- Lazily starts from 0 the first frame this specific
                -- card is seen, which is effectively "since it was
                -- created" -- no separate on-acquire hook needed.
                j.ability.extra.elapsed = (j.ability.extra.elapsed or 0) + dt

                while j.ability.extra.elapsed >= 10 do
                    j.ability.extra.elapsed = j.ability.extra.elapsed - 10
                    j.ability.extra.chips = (j.ability.extra.chips or 0):add(big(20))
                    j.ability.extra.mult = (j.ability.extra.mult or 0):add(big(2))
                end
            end
        end
    end
end

SMODS.Joker{
    key = "wall_clock",

    loc_txt = {
        name = "Wall Clock",
        text = {
            "Every {C:attention}10 seconds{} since",
            "gaining this Joker, it gains",
            "{C:chips}+20{} Chips and {C:mult}+2{} Mult",
            "{C:inactive}(Currently {}{C:chips}+#1#{}{C:inactive} Chips){}",
            "{C:inactive}({}{C:mult}+#2#{}{C:inactive} Mult){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 1, y = 0 },

    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            chips = big(0),
            mult = big(0),
            elapsed = 0,
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.mult } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                chips = card.ability.extra.chips,
                mult = card.ability.extra.mult,
            }
        end
    end,
}


SMODS.Joker{
    key = "warehouse",

    loc_txt = {
        name = "Warehouse",
        text = {
            "Gives {C:attention}+1{} Booster Pack slot",
        }
    },

    atlas = "HexJokers",
    pos = { x = 1, y = 0 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 3,             -- rare
    cost = 10,
    unlocked = true,
    discovered = true,
    blueprint_compat = false, -- the effect lives in the lifecycle hooks below, not calculate()
    eternal_compat = true,

    -- Same SMODS.change_booster_limit call Overstock Plus Plus's own
    -- redeem() uses elsewhere in this file, just applied through
    -- add_to_deck/remove_from_deck instead of a one-shot voucher
    -- redeem, since a Joker is owned continuously rather than redeemed
    -- once. Applied exactly once no matter how the card enters/leaves
    -- your Jokers (bought, created via Life/Manifest-style summon,
    -- sold, destroyed, etc.), and correctly reverses if sold.
    add_to_deck = function(self, card, from_debuff)
        SMODS.change_booster_limit(1)
    end,

    remove_from_deck = function(self, card, from_debuff)
        SMODS.change_booster_limit(-1)
    end,
}




SMODS.Joker{
    key = "musa_acuminata",

    loc_txt = {
        name = "Musa Acuminata",
        text = {
            "This Joker {C:purple}^#1#{}",
            "Mult",
        }
    },

    atlas = "HexJokers",
    pos = { x = 4, y = 0 },

    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            e_mult = big(2),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.e_mult } }
    end,

    -- Only appears after Cavendish breaks
    in_pool = function(self)
        return (hex_owns_showman() or #SMODS.find_card(self.key) == 0)
            and G.GAME and G.GAME.cavendish_broken
    end,

    calculate = function(self, card, context)

        if context.joker_main then
            return {
                e_mult = card.ability.extra.e_mult,
                colour = G.C.PURPLE
            }

        end
    end
}


-- Cavendish also receives context.selling_card + context.card during its
-- own sale, exactly like Trash Bin's sell-detection elsewhere in this
-- file. This stamps a short-lived flag right when that happens -- BEFORE
-- start_dissolve's own hook below runs -- so that hook can tell "sold"
-- apart from "actually destroyed" instead of treating both the same way.
-- Same wrap-by-name technique the Certificate/Perkeo overrides above
-- already use.
local hex_old_calculate_joker_cavendish = Card.calculate_joker

function Card:calculate_joker(context)
    if self.ability and self.ability.name == 'Cavendish'
    and context.selling_card
    and context.card == self then
        self.hex_cavendish_being_sold = true
    end

    return hex_old_calculate_joker_cavendish(self, context)
end


local old_start_dissolve = Card.start_dissolve

function Card.start_dissolve(self, ...)

    if self.config
    and self.config.center
    and self.config.center.key == "j_cavendish"
    and not self.hex_cavendish_being_sold then
        G.GAME.cavendish_broken = true
    end

    self.hex_cavendish_being_sold = nil -- clear either way, so a future genuine destroy isn't wrongly suppressed

    -- (rest of the existing Immortal-sticker block stays exactly the same)
    if self.ability
    and self.ability[HEX_IMMORTAL_STICKER_KEY]
    and not G.HEX_ABSOLUTE_SUMMONING then
        return
    end

    return old_start_dissolve(self, ...)
end
-- Perkeo: exclude Ritual and Star consumables from the pool Perkeo can
-- copy at end of round, without restricting either from being copied by
-- any other copy source in the game (Blueprint, other copy effects,
-- etc.) -- this only touches Perkeo's own hardcoded behaviour. Vanilla
-- hardcodes Perkeo's (and Triboulet/Yorick/Chicot/Canio's) end-of-round
-- effects by name inside the shared Card:calculate_joker function, so we
-- wrap that function, intercept only the Perkeo branch ourselves, and
-- forward every other case (including every other legendary Joker)
-- straight through to the original, untouched.
--
-- Any future custom ConsumableType this mod adds that should likewise be
-- off-limits to Perkeo just needs its set key added to this table.
local HEX_PERKEO_BLOCKED_SETS = {
    ritual = true,
    star = true,
    galaxy = true,
    nebula = true,
    astral = true,
    cosmic = true,
    black_hole = true,
}
local hex_old_calculate_joker = Card.calculate_joker

function Card:calculate_joker(context)
    if self.ability and self.ability.name == 'Perkeo' then
        -- Vanilla's own "copy a random consumable" behaviour is fully
        -- suppressed here -- our filtered version runs separately, on
        -- actual shop exit, via the end_shop hook below. This branch
        -- just has to exist so vanilla's unfiltered version never also
        -- fires and creates a second, unfiltered copy alongside ours.
        return
    end

    local ret = hex_old_calculate_joker(self, context)

    return ret
end


-- Vanilla Perkeo is suppressed in Card:calculate_joker above, which also
-- takes Blueprint/Brainstorm copies of it out of play -- their copy path
-- runs through that same suppressed calculate. So the copy chain has to
-- be resolved by hand here: Blueprint acts as the Joker to its right,
-- Brainstorm as the leftmost Joker, and either can point at another
-- copier, forming a chain.
HEX_PERKEO_KEY = "j_perkeo"
HEX_BLUEPRINT_KEY = "j_blueprint"
HEX_BRAINSTORM_KEY = "j_brainstorm"

local function hex_joker_center_key(c)
    return (c and c.config and c.config.center and c.config.center.key) or nil
end

-- Follows the Blueprint/Brainstorm chain starting at slot `i` and returns
-- the Joker that slot ends up actually performing. Returns nil if the
-- chain dead-ends (a Blueprint in the rightmost slot) or loops back on
-- itself (a Brainstorm in slot 1), matching vanilla's "does nothing" in
-- both of those cases.
local function hex_resolve_copy_chain(i)
    local cards = G.jokers and G.jokers.cards
    if not cards then return nil end

    local seen = {}
    local idx = i

    -- A chain can't be longer than the number of Jokers, so this doubles
    -- as the loop guard.
    for _ = 1, #cards do
        local c = cards[idx]
        if not c or seen[idx] then return nil end
        seen[idx] = true

        local key = hex_joker_center_key(c)

        if key == HEX_BLUEPRINT_KEY then
            idx = idx + 1
        elseif key == HEX_BRAINSTORM_KEY then
            idx = 1
        else
            return c
        end
    end

    return nil
end

-- Every Joker slot that should fire Perkeo this shop exit: Perkeo itself,
-- plus any copier resolving to it. Returns the ACTING cards (the Blueprint
-- rather than the Perkeo), so the "Duplicated!" text appears on the card
-- that did the work, the way vanilla copies do.
function hex_perkeo_trigger_cards()
    local out = {}
    local cards = G.jokers and G.jokers.cards
    if not cards then return out end

    for i, c in ipairs(cards) do
        local key = hex_joker_center_key(c)
        local target

        if key == HEX_BLUEPRINT_KEY or key == HEX_BRAINSTORM_KEY then
            target = hex_resolve_copy_chain(i)

            -- Respect the copied Joker's own blueprint_compat flag rather
            -- than assuming, so this stays correct if that ever changes.
            if target and not (target.config and target.config.center
                and target.config.center.blueprint_compat) then
                target = nil
            end
        else
            target = c
        end

        if target and hex_joker_center_key(target) == HEX_PERKEO_KEY then
            out[#out + 1] = c
        end
    end

    return out
end

local hex_old_toggle_shop = G.FUNCS.toggle_shop

G.FUNCS.toggle_shop = function(e)
    for _, source in ipairs(hex_perkeo_trigger_cards()) do
        if G.consumeables and G.consumeables.cards[1] then

            -- Same eligible-pool filter as before: excludes
            -- Ritual/Star/Galaxy-set consumables. Recomputed per trigger,
            -- so with two effective Perkeos the second one can roll the
            -- copy the first one just made.
            local eligible = {}
            for _, c in ipairs(G.consumeables.cards) do
                local blocked = c.ability
                    and HEX_PERKEO_BLOCKED_SETS[c.ability.set]
                if not blocked then
                    eligible[#eligible + 1] = c
                end
            end

            if eligible[1] then
                G.E_MANAGER:add_event(Event({
                    func = function()
                        local card = copy_card(pseudorandom_element(eligible, pseudoseed('perkeo')), nil)
                        card:set_edition({negative = true}, true)
                        card:add_to_deck()
                        G.consumeables:emplace(card)
                        return true
                    end
                }))
                card_eval_status_text(source, 'extra', nil, nil, nil, {message = localize('k_duplicated_ex')})
            end
        end
    end

    return hex_old_toggle_shop(e)
end

SMODS.Joker{
    key = "accumulation_joker",

    loc_txt = {
        name = "Accumulation Joker",
        text = {
            "Gains {X:mult,C:white}X#3#{} Mult after",
            "every {C:attention}Small{} and {C:attention}Big Blind{}",
            "Gains {X:chips,C:white}X#4#{} Chips after",
            "every {C:attention}Boss Blind{}",
            "{C:inactive}(Currently {}{X:mult,C:white}X#1#{}{C:inactive} Mult){}",
            "{C:inactive}({}{X:chips,C:white}X#2#{}{C:inactive} Chips){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 1, y = 0 },
    in_pool = hex_in_pool,

    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            Xmult = big(1),
            Xmult_gain = big(0.25),
            x_chips = big(1),
            x_chips_gain = big(0.5),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult, card.ability.extra.x_chips, card.ability.extra.Xmult_gain, card.ability.extra.x_chips_gain } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                Xmult = card.ability.extra.Xmult,
                x_chips = card.ability.extra.xchips,
            }
        end

        if context.end_of_round
        and not context.blueprint
        and card.hex_accumulation_last_round ~= G.GAME.round then

            card.hex_accumulation_last_round = G.GAME.round

            if G.GAME.blind and G.GAME.blind.boss then
                card.ability.extra.x_chips = card.ability.extra.x_chips:add(card.ability.extra.x_chips_gain)

                return {
                    message = localize("k_upgrade_ex"),
                    colour = G.C.CHIPS,
                }
            else
                card.ability.extra.Xmult = card.ability.extra.Xmult:add(card.ability.extra.Xmult_gain)

                return {
                    message = localize("k_upgrade_ex"),
                    colour = G.C.MULT,
                }
            end
        end
    end,
}


SMODS.Joker{
    key = "ace_of_seals",

    loc_txt = {
        name = "Ace of Seals",
        text = {
            "Played {C:attention}Aces{} are given",
            "a {C:attention}random Seal{}",
            "{C:inactive}(Red, Gold, Blue, Purple){}"
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_SEALS.Gold
        info_queue[#info_queue + 1] = G.P_SEALS.Red
        info_queue[#info_queue + 1] = G.P_SEALS.Blue
        info_queue[#info_queue + 1] = G.P_SEALS.Purple
        return { vars = {} }
    end,

    atlas = "HexJokers",
    pos = { x = 6, y = 0 }, -- next open frame in the atlas, adjust if taken
    in_pool = hex_in_pool,
    rarity = 2,   -- uncommon
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,

    calculate = function(self, card, context)
        if context.individual
        and context.cardarea == G.play
        and not context.blueprint
        and context.other_card.base.value == "Ace"
        and not context.other_card.seal then -- only seal it on the first trigger; retriggers see the seal already applied and skip

            local seals = { "Gold", "Red", "Blue", "Purple"}
            local chosen_seal = pseudorandom_element(seals, pseudoseed("the_seal_of_aces"))

            context.other_card:set_seal(chosen_seal, true)

            return {
                message = localize("k_upgrade_ex"),
                colour = G.C.SEAL,
            }
        end
    end,
}




-- Joker Archive: +0.15 Xmult for every DIFFERENT Joker owned at any
-- point this run -- not just currently owned. G.GAME.hex_joker_archive_seen
-- is a persistent run-scoped set (key -> true), polled and filled in
-- every Game:update tick from G.jokers.cards, same lazy per-frame
-- technique Landlord/Bulletproof/Iron Joker use elsewhere in this file.
-- Once a key is marked true it's never cleared, so selling/destroying a
-- Joker doesn't undo its contribution -- exactly "owned this run", not
-- "currently owned". Plain Lua table/boolean, so it saves/loads fine
-- the same way G.GAME.used_vouchers and other persistent hex_* run
-- state already do elsewhere in this file.
local function hex_track_joker_archive()
    if not (G.jokers and G.jokers.cards) then return end

    G.GAME.hex_joker_archive_seen = G.GAME.hex_joker_archive_seen or {}

    for _, j in ipairs(G.jokers.cards) do
        if j.config and j.config.center and j.config.center.key then
            G.GAME.hex_joker_archive_seen[j.config.center.key] = true
        end
    end
end

local hex_old_update_joker_archive = Game.update

function Game:update(dt)
    hex_old_update_joker_archive(self, dt)
    hex_track_joker_archive()
end

local function hex_count_joker_archive_seen()
    local seen = G.GAME and G.GAME.hex_joker_archive_seen
    if not seen then return 0 end

    local count = 0
    for _ in pairs(seen) do
        count = count + 1
    end

    return count
end

SMODS.Joker{
    key = "joker_archive",

    loc_txt = {
        name = "Joker Archive",
        text = {
            "Gives {X:mult,C:white}X#1#{} Mult for every",
            "{C:attention}different Joker{} you've",
            "owned {C:attention}this run{}",
            "{C:inactive}(Currently {}{X:mult,C:white}X#2#{}{C:inactive} Mult){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 1, y = 0 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 3,             -- rare
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            per_joker_xmult = big(0.15),
        }
    },

    loc_vars = function(self, info_queue, card)
        local count = hex_count_joker_archive_seen()
        local xmult = big(1):add(card.ability.extra.per_joker_xmult:mul(big(count)))

        return { vars = { card.ability.extra.per_joker_xmult, xmult } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            local count = hex_count_joker_archive_seen()
            local xmult = big(1):add(card.ability.extra.per_joker_xmult:mul(big(count)))

            return {
                Xmult = xmult,
                colour = G.C.MULT,
            }
        end
    end,
}





SMODS.Joker{
    key = "deep_pockets",

    loc_txt = {
        name = "Deep Pockets",
        text = {
            "Gives {X:chips,C:white}X#1#{} Chips if",
            "you have {C:money}$100{} or more",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 2,            
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            x_chips = big(5),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.x_chips } }
    end,

    calculate = function(self, card, context)
        if context.joker_main and G.GAME.dollars:gte(big(100)) then
            return {
                x_chips = card.ability.extra.x_chips,
                colour = G.C.CHIPS,
            }
        end
    end,
}







-- Checks the live balance every frame instead of hooking a specific
-- money-modifying function. ease_dollars turned out not to be the only
-- path money can change through -- the round-eval cash-out payout
-- doesn't route through it -- so rather than chase down every possible
-- source of a dollar change, this just polls G.GAME.dollars directly,
-- the same way Wall Clock's timer already hooks Game:update above.
local hex_taxes_due_prefix = mod.prefix
local hex_old_update_taxes_due = Game.update

function Game:update(dt)
    hex_old_update_taxes_due(self, dt)

    if G.jokers and G.jokers.cards and G.GAME and G.GAME.dollars then
        local dollars = to_big(G.GAME.dollars)

        if dollars:gt(big(25)) then
            for _, j in ipairs(G.jokers.cards) do
                if j.config and j.config.center
                and j.config.center.key == ("j_" .. hex_taxes_due_prefix .. "_taxes_due")
                and not j.getting_sliced then

                    j.getting_sliced = true

                    card_eval_status_text(j, "extra", nil, nil, nil, {
                        message = "Destroyed!",
                        colour = G.C.RED,
                    })

                    G.E_MANAGER:add_event(Event({
                        trigger = "after",
                        delay = 0.3,
                        func = function()
                            j:start_dissolve()
                            return true
                        end
                    }))
                end
            end
        end
    end
end

SMODS.Joker{
    key = "taxes_due",

    loc_txt = {
        name = "Taxes Due",
        text = {
            "Gives {X:chips,C:white}X3{} Chips,",
            "but money can't",
            "go above {C:money}$25{}",
            "{C:inactive}(Destroyed if it does){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 },
    in_pool = hex_in_pool,

    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            x_chips = big(3),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.x_chips } }
    end,


    calculate = function(self, card, context)
        if context.joker_main then
            return {
                x_chips = card.ability.extra.x_chips,
                colour = G.C.CHIPS,
            }
        end
    end,
}


-- 9 Lives: +1 Hex point for every 9 scored. Same rank-check pattern as
-- Hatsune Miku/Miner above, applied to G.GAME.hex_points directly
-- (the same way Totem/9 Lives-style hex-point jokers mutate it) instead
-- of a joker stat.
SMODS.Joker{
    key = "nine_lives",

    loc_txt = {
        name = "9 Lives",
        text = {
            "Gives {C:purple}+1{} {C:purple}Hex point{}",
            "for every {C:attention}9{} that is scored",
        }
    },

    atlas = "HexJokers",
    pos = { x = 1, y = 0 },

    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    calculate = function(self, card, context)
        if context.individual
        and context.cardarea == G.play
        and not context.blueprint
        and context.other_card.base
        and context.other_card.base.value == "9" then

            G.GAME.hex_points = (G.GAME.hex_points or big(0)):add(big(1))

            return {
                message = "+1 Hex",
                colour = G.C.HEX_ORPLE,
            }
        end
    end,
}

-- Number-card ranks only -- excludes Jack/Queen/King/Ace, same "2".."10"
-- string-digit convention hex_lucky_ranks uses elsewhere in this file
-- for its own rank checks (base.value stores digits for number cards,
-- full words like "Jack"/"Ace" for face cards).
local HEX_NUMBER_CARD_RANKS = {
    ["2"] = true, ["3"] = true, ["4"] = true, ["5"] = true, ["6"] = true,
    ["7"] = true, ["8"] = true, ["9"] = true, ["10"] = true,
}

SMODS.Joker{
    key = "four_leaf_clover",

    loc_txt = {
        name = "4-Leaf Clover",
        text = {
            "Played {C:attention}number cards{}",
            "become {C:attention}Lucky Cards{}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 2,             -- uncommon
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,

    -- Same conversion pattern Chameleon (Ace -> Wild Card) uses
    -- elsewhere in this file: context.individual + context.cardarea ==
    -- G.play, only re-applying if the card isn't already Lucky so
    -- retriggers on the same card don't spam the upgrade popup.
    calculate = function(self, card, context)
        if context.individual
        and context.cardarea == G.play
        and not context.blueprint
        and context.other_card.base
        and HEX_NUMBER_CARD_RANKS[context.other_card.base.value]
        and not (context.other_card.config and context.other_card.config.center
            and context.other_card.config.center.key == "m_lucky") then

            context.other_card:set_ability(G.P_CENTERS.m_lucky, nil, true)

            return {
                message = localize("k_upgrade_ex"),
                colour = G.C.SECONDARY_SET.Enhanced,
            }
        end
    end,
}


-- Refund: +$1 when a Joker is successfully hexed. Hooks
-- G.FUNCS.hex_sacrifice directly (calculate() has no context flag for
-- this custom mechanic) and checks that card.hex_being_hexed newly
-- became true as a result of the call, since hex_sacrifice's own
-- guards (Eternal, the Absolute joker, already-mid-hex) mean not every
-- call actually succeeds.

SMODS.Joker{
    key = "refund",

    loc_txt = {
        name = "Refund",
        text = {
            "Gives {C:money}+$1{} when",
            "{C:purple}hexing{} a Joker",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 },

    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
}







SMODS.Joker{
    key = "tradeoff",

    loc_txt = {
        name = "Tradeoff",
        text = {
            "Gives {C:chips}+1000{} Chips",
            "but gives {X:mult,C:white}X0.75{} Mult",
        }
    },

    atlas = "HexJokers",
    pos = { x = 1, y = 0 },
    in_pool = hex_in_pool,
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                chips = 1000,
                Xmult = 0.75,
            }
        end
    end,
}


-- Iron Joker: while owned, every Steel card's held-in-hand Mult
-- multiplier is boosted from vanilla's X1.5 to X3. Rather than hooking
-- an unverified internal getter, this directly overwrites the field
-- vanilla's own Steel Card actually reads -- h_x_mult, confirmed as a
-- real scoring-stat field by this mod's own HEX_ENTROPY_SCORE_PATTERNS
-- list ("^h_x_mult$") elsewhere in this file, and matching m_steel's
-- own config = {h_x_mult = 1.5} exactly. Polled every frame (same
-- Game:update technique Landlord/Bulletproof use elsewhere in this
-- file) over G.playing_cards -- the master full-deck registry Diamond
-- Card's own helper uses -- so this covers Steel cards you already own
-- AND any created after buying Iron Joker, and correctly reverts back
-- to 1.5 the instant Iron Joker is sold or destroyed.
local function hex_iron_joker_owned()
    if not (G.jokers and G.jokers.cards) then return false end

    for _, j in ipairs(G.jokers.cards) do
        if j.config and j.config.center
        and j.config.center.key == ("j_" .. mod.prefix .. "_iron_joker") then
            return true
        end
    end

    return false
end

local function hex_apply_iron_joker_steel_boost()
    if not G.playing_cards then return end

    local boosted = hex_iron_joker_owned()

    for _, c in ipairs(G.playing_cards) do
        if c.ability and c.config and c.config.center
        and c.config.center.key == "m_steel" then
            c.ability.h_x_mult = boosted and 3 or 1.5
        end
    end
end

local hex_old_update_iron_joker = Game.update

function Game:update(dt)
    hex_old_update_iron_joker(self, dt)
    hex_apply_iron_joker_steel_boost()
end

SMODS.Joker{
    key = "iron_joker",

    loc_txt = {
        name = "Iron Joker",
        text = {
            "{C:attention}Steel{} cards give",
            "{X:mult,C:white}X3{} Mult instead of",
            "{X:mult,C:white}X1.5{} Mult",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 2,             -- uncommon
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = false, -- the effect lives in the Game:update poll above, gated on ownership directly, not in calculate()
    eternal_compat = true,
}




SMODS.Joker{
    key = "hypergrowth",

    loc_txt = {
        name = "Hypergrowth",
        text = {
            "Gives {C:purple}^#1#{} Mult and Chips",
        }
    },

    atlas = "HexJokers",
    pos = { x = 1, y = 0 },
    in_pool = hex_in_pool,
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,


    config = {
        extra = {
            e_chips = big(1.1),
            e_mult = big(1.1),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.e_chips } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                e_mult = card.ability.extra.e_mult,
                e_chips = card.ability.extra.e_chips,
            }
        end
    end,
}






SMODS.Joker{
    key = "blacksmith",

    loc_txt = {
        name = "Blacksmith",
        text = {
            "This Joker gains {X:mult,C:white}X#2#{} Mult",
            "for every {C:attention}Steel{} card",
            "triggered in your played hand",
            "{C:inactive}(Currently {}{X:mult,C:white}X#1#{}{C:inactive} Mult){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 1 }, -- placeholder frame, move to an unused atlas slot before shipping
    in_pool = hex_in_pool,
    rarity = 2,             -- uncommon
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            Xmult = big(1),
            Xmult_gain = big(0.25),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult, card.ability.extra.Xmult_gain } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                Xmult = card.ability.extra.Xmult,
                colour = G.C.MULT,
            }
        end

        -- Every scored card carrying the Steel enhancement -- checked
        -- via context.other_card.config.center.key, same as Bonus
        -- Joker's own m_bonus check elsewhere in this file. Retriggered
        -- Steel cards count more than once, same convention this file's
        -- other per-card accumulators use.
        if context.individual and context.cardarea == G.play and not context.blueprint then
            if context.other_card.config.center.key == "m_steel" then
                card.ability.extra.Xmult = card.ability.extra.Xmult:add(card.ability.extra.Xmult_gain)

                return {
                    message = localize("k_upgrade_ex"),
                    colour = G.C.MULT,
                }
            end
        end
    end,
}



SMODS.Joker{
    key = "bonus_joker",
    loc_txt = {
        name = "Bonus Joker",
        text = {
            "This Joker gains {X:mult,C:white}X#2#{} Mult",
            "every bonus card scored",
            "{C:inactive}(Currently {}{X:mult,C:white}X#1#{}{C:inactive} Mult)"
        }
    },
    config = { extra = { Xmult = big(1), Xmult_gain = big(0.2) } },
    atlas = "HexJokers",
    pos = { x = 3, y = 1 }, -- second frame in the atlas (sprite to the right)
    in_pool = hex_in_pool,
    rarity = 2,             -- 1 common, 2 uncommon, 3 rare, 4 legendary
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    

    calculate = function(self, card, context)
        -- Apply the current Xmult when this joker scores
        if context.joker_main then
            return {
                Xmult = card.ability.extra.Xmult,
            }
        end

        -- Grow permanently whenever a scored card has the Bonus enhancement
        if context.individual and context.cardarea == G.play and not context.blueprint then
            if context.other_card.config.center.key == "m_bonus" then
                card.ability.extra.Xmult = card.ability.extra.Xmult:add(card.ability.extra.Xmult_gain) 
                return {
                    message = localize("k_upgrade_ex"),
                    colour = G.C.MULT,
                }
            end
        end
    end,

    -- Fills the #1# placeholder in the description text with the current Xmult
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult, card.ability.extra.Xmult_gain } }
    end,
}









SMODS.Joker{
    key = "trash_bin",

    loc_txt = {
        name = "Trash bin",
        text = {
            "Gains times {X:mult,C:white}X1.5{} Mult",
            "when selling a {C:rare}Rare{} Joker", 
            "{C:inactive}(Currently {}{X:mult,C:white}X#1#{}{C:inactive} Mult){}"
        }
    },

    atlas = "HexJokers",
    pos = { x = 8, y = 0 },

    rarity = 3,
    cost = 8,
    in_pool = hex_in_pool,


    unlocked = true,
    discovered = true,

    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            xmult = big(1)
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.xmult
            }
        }
    end,

    calculate = function(self, card, context)

        -- Apply the multiplier
        if context.joker_main then
            return {
                Xmult_mod = card.ability.extra.xmult,
                message = "X" .. tostring(card.ability.extra.xmult) .. " Mult"
            }
        end


        -- Detect selling a rare Joker
        if context.selling_card
        and context.card.ability
        and context.card.ability.set == "Joker"
        and context.card.config.center.rarity == 3
        and not context.blueprint then

            card.ability.extra.xmult =
                card.ability.extra.xmult:mul(big(1.5))

            return {
                message = "X" .. tostring(card.ability.extra.xmult),
                colour = G.C.MULT
            }
        end
    end
}

SMODS.Joker{
    key = "the_monolith",

    loc_txt = {
        name = "The Monolith",
        text = {
            "Gain {C:purple}+1{} additional",
            "{C:purple}Hex{} point whenever",
            "a joker is {C:purple}Hexed{}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 8, y = 0 },

    rarity = 3,
    in_pool = hex_in_pool,


    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
}


SMODS.Joker{
    key = "boykisser",

    loc_txt = {
        name = "Boykisser",
        text = {
            "Gains {X:mult,C:white}X1{} Mult for every",
            "{C:purple}6{} {C:purple}Hex points{} owned",
            "{C:inactive}(Currently {}{X:mult,C:white}X#1#{}{C:inactive} Mult){}",
            "{C:red}Destroys itself{} if played",
            "hand is a {C:attention}Straight{}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 4, y = 8 },
    soul_pos = { x = 0, y = 9 },

    rarity = 4,
    in_pool = hex_in_pool,
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    -- Shows the current live Xmult (1 + floor(hex_points / 6)) in the
    -- card's own text, computed the same way calculate() below applies
    -- it. Guards G.GAME being nil since loc_vars can also be called
    -- from the collection screen outside of a run.
    loc_vars = function(self, info_queue, card)
        local hex_points = (G.GAME and G.GAME.hex_points) or big(0)
        local bonus = hex_points:div(big(6)):floor()
        local xmult = big(1):add(bonus)

        return { vars = { xmult } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            local hex_points = G.GAME.hex_points or big(0)
            local bonus = hex_points:div(big(6)):floor()
            local xmult = big(1):add(bonus)

            return {
                Xmult = xmult,
            }
        end

        -- Self-destructs if a Straight is played. context.before fires
        -- before context.joker_main in the same scoring pass, so this
        -- hand's own Xmult still applies (via the joker_main branch
        -- above) before the deferred dissolve actually removes the
        -- card -- same "still contributes to the hand that kills it,
        -- then it's gone" pattern Dragon Fruit uses.
        if context.before and next(context.poker_hands["Straight"]) and not context.blueprint then
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.3,
                func = function()
                    card:start_dissolve()
                    return true
                end
            }))

            return {
                message = "Destroyed!",
                colour = G.C.RED,
            }
        end
    end,
}


-- Sheaf: creates 1 random Star card at the end of every round, via
-- hex_get_star_centers() + explicit-key SMODS.create_card, same pattern
-- Local Void uses for Black Hole cards (Star cards are this mod's own
-- custom ConsumableType, shop_rate = 0, never naturally generated).
-- blueprint_compat = true, with the same natural/Blueprint dual-stamp
-- split Schwarzschild Radius uses -- Blueprint's copy call reuses this
-- card's own `card` object (context.blueprint = <depth>, shared
-- ability.extra table), so a single dedupe stamp would let only one
-- firing (natural or first Blueprint) go through per round regardless
-- of how many Blueprints are stacked.
local function hex_sheaf_create_star_card()
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.2,
        func = function()
            if G.consumeables and #G.consumeables.cards < G.consumeables.config.card_limit then
                local stars = hex_get_star_centers()

                if #stars > 0 then
                    local chosen = stars[math.random(#stars)]

                    local new_card = SMODS.create_card({
                        key = chosen.key,
                        area = G.consumeables
                    })

                    G.consumeables:emplace(new_card)
                end
            end
            return true
        end
    }))
end


-- Builds the eligible pool fresh each time (Rare-or-lower Jokers, i.e.
-- rarity <= 3, so Legendary and any higher custom rarities are excluded)
-- and creates one as a Negative copy. Same rarity-filtered pool pattern
-- Andromeda/Big Crunch already use elsewhere in this file, respecting
-- Showman for duplicates. No card_limit check, matching Proxima
-- Centauri's own reasoning -- Negative Jokers don't count against the
-- Joker slot limit in vanilla, so there's nothing to gate on.
local function hex_fermi_method_create_joker()
    local showman_owned = hex_owns_showman()

    local pool = {}
    for _, center in pairs(G.P_CENTERS) do
        if center.set == "Joker"
        and type(center.rarity) == "number"
        and center.rarity <= 3 -- Rare (3) or lower
        and (showman_owned or #SMODS.find_card(center.key) == 0) then
            pool[#pool + 1] = center
        end
    end

    if #pool == 0 then return end

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.2,
        func = function()
            local chosen = pool[math.random(#pool)]

            local new_card = SMODS.create_card({
                set = "Joker",
                key = chosen.key,
                area = G.jokers
            })

            new_card:set_edition({ negative = true }, true)

            G.jokers:emplace(new_card)
            new_card:add_to_deck()

            card_eval_status_text(new_card, "extra", nil, nil, nil, {
                message = "FERMI!",
                colour = G.C.LEGENDARY,
            })

            return true
        end
    }))
end

SMODS.Joker{
    key = "fermi_method",

    loc_txt = {
        name = "Fermi Method",
        text = {
            "Creates a random",
            "{C:dark_edition}Negative{} Joker of",
            "{C:attention}Rare{} rarity or lower",
            "at the end of every round",
        }
    },

    atlas = "HexJokers",
    pos = { x = 4, y = 8 }, -- placeholder art slot, same as other undrawn Legendary Jokers
    soul_pos = { x = 2, y = 9 }, -- placeholder Soul-card art slot

    rarity = 4, -- Legendary
    in_pool = hex_in_pool,
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            last_round = nil,
            last_round_blueprint = {},
        }
    },

    calculate = function(self, card, context)
        if not context.end_of_round then return end

        if context.blueprint then
            if type(card.ability.extra.last_round_blueprint) ~= "table" then
                card.ability.extra.last_round_blueprint = {}
            end

            local bp_card = context.blueprint_card
            local bp_key = bp_card and (bp_card.sort_id or bp_card) or "unknown"

            if card.ability.extra.last_round_blueprint[bp_key] ~= G.GAME.round then
                card.ability.extra.last_round_blueprint[bp_key] = G.GAME.round
                hex_fermi_method_create_joker()

                return {
                    message = "+1 Negative",
                    colour = G.C.LEGENDARY,
                }
            end
        else
            if card.ability.extra.last_round ~= G.GAME.round then
                card.ability.extra.last_round = G.GAME.round
                hex_fermi_method_create_joker()

                return {
                    message = "+1 Negative",
                    colour = G.C.LEGENDARY,
                }
            end
        end
    end,
}


-- Bernoulli Numbers: retriggers the joker immediately to this Joker's
-- own left (its actual neighbor, not just "whatever's in the first
-- slot") 3 extra times. Same retrigger_joker_check/retrigger_joker
-- context Cryptid's Chad uses, gated behind SMODS's optional_features.
-- retrigger_joker flag (added above in main.lua) -- without that flag
-- enabled, this context never fires at all.
local function hex_joker_left_neighbor(card)
    if not (G.jokers and G.jokers.cards) then return nil end

    for i, j in ipairs(G.jokers.cards) do
        if j == card then
            return G.jokers.cards[i - 1] -- nil if this joker is already leftmost (i == 1)
        end
    end

    return nil
end



local function hex_joker_rightmost(card)
    if not (G.jokers and G.jokers.cards) then return nil end

    local rightmost = G.jokers.cards[#G.jokers.cards]

    if rightmost == card then
        return nil
    end

    return rightmost
end


SMODS.Joker{
    key = "bernoulli_numbers",

    loc_txt = {
        name = "Bernoulli Numbers",
        text = {
            "Retriggers the {C:attention}rightmost{}",
            "Joker {C:attention}3{} extra times",
        }
    },

    config = {
        extra = { retriggers = 3 },
    },

    atlas = "HexJokers", 
    
    pos = { x = 4, y = 8 }, -- placeholder art slot
    soul_pos = { x = 2, y = 9 }, -- placeholder Soul-card art slot
    
    in_pool = hex_in_pool,
    rarity = 4,             -- 1 common, 2 uncommon, 3 rare, 4 legendary
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.retriggers } }
    end,

    calculate = function(self, card, context)
        if context.retrigger_joker_check
        and not context.retrigger_joker
        and context.other_card ~= card then

        

            local rightmost = hex_joker_rightmost(card)

            if rightmost and context.other_card == rightmost then
                return {
                    message = localize("k_again_ex"),
                    repetitions = card.ability.extra.retriggers,
                    card = card,
                }
            end
        end
    end,
}



-- Turning Machine: at the end of every Boss Blind, gives one random
-- currently-owned Joker without an existing edition the Negative
-- edition. Same end_of_round + G.GAME.blind.boss + per-round dedupe
-- stamp Totem uses elsewhere in this file, so it only fires once per
-- round even though end_of_round gets evaluated more than once during
-- round-end scoring. Eligibility check mirrors hex_count_edition_jokers'
-- own "j.edition" read elsewhere in this file -- a Joker with any
-- edition already on it (Foil/Holo/Poly/Negative/etc) is skipped, so
-- this can never waste itself overwriting an edition that's already
-- there, and can never stack Negative onto the same Joker twice.
local function hex_turning_machine_eligible_jokers()
    if not (G.jokers and G.jokers.cards) then return {} end

    local pool = {}
    for _, j in ipairs(G.jokers.cards) do
        if not j.edition then
            pool[#pool + 1] = j
        end
    end

    return pool
end

SMODS.Joker{
    key = "turning_machine",

    loc_txt = {
        name = "Turning Machine",
        text = {
            "Gives {C:attention}1{} random Joker",
            "without an {C:dark_edition}Edition{}",
            "the {C:dark_edition}Negative{} Edition",
            "at the end of every {C:attention}Boss Blind{}",
        }
    },

    config = {
        extra = {
            last_round = nil,
        }
    },

    atlas = "HexJokers",
    pos = { x = 4, y = 8 }, -- placeholder art slot
    soul_pos = { x = 2, y = 9 },    
    in_pool = hex_in_pool,
    rarity = 4,             -- 1 common, 2 uncommon, 3 rare, 4 legendary
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = false, -- the effect lives entirely in this specific card's own dedupe stamp/random pick, not in a per-scoring calculate a Blueprint copy could meaningfully mirror
    eternal_compat = true,

    calculate = function(self, card, context)
        if context.end_of_round
        and G.GAME.blind
        and G.GAME.blind.boss
        and not context.blueprint
        and card.ability.extra.last_round ~= G.GAME.round then

            card.ability.extra.last_round = G.GAME.round

            local pool = hex_turning_machine_eligible_jokers()

            if #pool > 0 then
                local chosen = pool[math.random(#pool)]
                chosen:set_edition({ negative = true }, true)

                return {
                    message = "Negative!",
                    colour = G.C.LEGENDARY,
                    card = chosen,
                }
            end
        end
    end,
}

SMODS.Joker{
    key = "coupon",

    loc_txt = {
        name = "Coupon",
        text = {
            "Rerolls in the shop",
            "always cost {C:money}$1{}"
        }
    },

    rarity = 4,
    in_pool = hex_in_pool,

    atlas = "HexJokers",
    pos = { x = 4, y = 8 }, 
    soul_pos = { x = 2, y = 9 }, -- placeholder art slot, same as other undrawn Mythic+ jokers

    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
}



-- Dirac Equation: when a Blind is selected, destroys your leftmost
-- destroyable Joker (skipping Eternal/Immortal/Absolute via
-- hex_huge_lqg_eligible_jokers, same as Huge LQG elsewhere in this
-- file -- and skipping itself, so it can't destroy itself if it
-- happens to be leftmost) and gives double that Joker's Hex-point
-- worth. Uses the real hex_compute_sacrifice_gain(card)/
-- hex_sacrifice_values pair from consumables.lua -- the same shared
-- rarity->Hex-value calculation the manual Hex sacrifice button and
-- Huge LQG both already go through -- rather than a separate table, so
-- this automatically stays in sync with Laniakea/Cursed Deck/Monolith/
-- Magic Studies bonuses the same way those two do. Deduped per round
-- via last_round, same defensive stamp Russian Roulette uses elsewhere
-- even for nominally one-shot-per-round contexts.
--
-- NOTE: this does NOT go through G.FUNCS.hex_sacrifice itself, so it
-- does not trigger that button's own +$1-per-hex refund wrap -- that
-- refund is specifically tied to the manual sacrifice action, not
-- every source of Hex-point-for-destroying-a-Joker in the mod. Say the
-- word if you want Dirac Equation to trigger that refund too.
local function hex_dirac_leftmost_target(card)
    local eligible = hex_huge_lqg_eligible_jokers()

    for _, j in ipairs(eligible) do
        if j ~= card then
            return j
        end
    end

    return nil
end

SMODS.Joker{
    key = "dirac_equation",

    loc_txt = {
        name = "Dirac Equation",
        text = {
            "Destroys your {C:attention}leftmost{} Joker",
            "when {C:attention}Blind{} is selected,",
            "gives {C:purple}double{} its",
            "{C:purple}Hex point{} worth",
        }
    },

    config = {
        extra = {
            last_round = nil,
        }
    },

    atlas = "HexJokers",
    pos = { x = 4, y = 8 }, 
    soul_pos = { x = 2, y = 9 },
    in_pool = hex_in_pool,
    rarity = 4,             -- 1 common, 2 uncommon, 3 rare, 4 legendary
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = false, -- the effect explicitly excludes context.blueprint below (same as Huge LQG's own boss-blind destroy roll), so a Blueprint copy would have nothing to trigger
    eternal_compat = true,

    calculate = function(self, card, context)
        if context.setting_blind
        and not context.blueprint
        and card.ability.extra.last_round ~= G.GAME.round then

            card.ability.extra.last_round = G.GAME.round

            local target = hex_dirac_leftmost_target(card)

            if target and not target.hex_being_hexed then
                local gain = hex_compute_sacrifice_gain(target):mul(big(2))

                if gain:gt(big(0)) then
                    target.hex_being_hexed = true

                    G.GAME.hex_points = (G.GAME.hex_points or big(0)):add(gain)

                    G.E_MANAGER:add_event(Event({
                        trigger = "after",
                        delay = 0.1,
                        func = function()
                            target:start_dissolve()
                            return true
                        end
                    }))

                    return {
                        message = "+" .. tostring(gain) .. " Hex",
                        colour = G.C.HEX_ORPLE,
                    }
                end
            end
        end
    end,
}


-- Schrödinger's Cat: retriggers two targets once each -- G.jokers.
-- cards[1] (the literal leftmost Joker overall, same absolute-slot
-- targeting Chad uses) and this Joker's own adjacent right neighbor
-- (same relative-position lookup Bernoulli Numbers uses for its own
-- left neighbor, mirrored to the other direction). Uses the same
-- retrigger_joker_check/retrigger_joker context Bernoulli Numbers
-- uses, gated behind the same optional_features.retrigger_joker flag
-- already enabled in main.lua -- no further setup needed there.
local function hex_joker_right_neighbor(card)
    if not (G.jokers and G.jokers.cards) then return nil end

    for i, j in ipairs(G.jokers.cards) do
        if j == card then
            return G.jokers.cards[i + 1] -- nil if this joker is already rightmost
        end
    end

    return nil
end

SMODS.Joker{
    key = "schrodingers_cat",

    loc_txt = {
        name = "Schrödinger's Cat",
        text = {
            "Retriggers your {C:attention}leftmost{} Joker",
            "and the Joker to the",
            "{C:attention}right{} of this Joker",
            "{C:attention}1{} extra time each",
        }
    },

    config = {
        extra = { retriggers = 1 },
    },

    atlas = "HexJokers",
    pos = { x = 4, y = 8 }, -- placeholder art slot
    soul_pos = { x = 2, y = 9 }, -- placeholder Soul-card art slot
    in_pool = hex_in_pool,
    rarity = 4,             -- 1 common, 2 uncommon, 3 rare, 4 legendary
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.retriggers } }
    end,

    calculate = function(self, card, context)
        if context.retrigger_joker_check
        and not context.retrigger_joker
        and context.other_card ~= card then

            local leftmost = G.jokers and G.jokers.cards and G.jokers.cards[1]
            local right_neighbor = hex_joker_right_neighbor(card)

            if (leftmost and context.other_card == leftmost)
            or (right_neighbor and context.other_card == right_neighbor) then

                return {
                    message = localize("k_again_ex"),
                    repetitions = card.ability.extra.retriggers,
                    card = card,
                }
            end
        end
    end,
}


SMODS.Joker{
    key = "sheaf",

    loc_txt = {
        name = "Sheaf",
        text = {
            "Creates a random {C:star}Star{}",
            "card at the end of every round",
        }
    },

    atlas = "HexJokers",
    pos = { x = 4, y = 8 }, -- placeholder art slot
    soul_pos = { x = 2, y = 9 }, -- placeholder Soul-card art slot

    rarity = 4,
    in_pool = hex_in_pool,
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            last_round = nil,
            last_round_blueprint = {},
        }
    },

    calculate = function(self, card, context)
        if not context.end_of_round then return end

        if context.blueprint then
            if type(card.ability.extra.last_round_blueprint) ~= "table" then
                card.ability.extra.last_round_blueprint = {}
            end

            local bp_card = context.blueprint_card
            local bp_key = bp_card and (bp_card.sort_id or bp_card) or "unknown"

            if card.ability.extra.last_round_blueprint[bp_key] ~= G.GAME.round then
                card.ability.extra.last_round_blueprint[bp_key] = G.GAME.round
                hex_sheaf_create_star_card()

                return {
                    message = "+1 Star",
                    colour = G.C.STAR,
                }
            end
        else
            if card.ability.extra.last_round ~= G.GAME.round then
                card.ability.extra.last_round = G.GAME.round
                hex_sheaf_create_star_card()

                return {
                    message = "+1 Star",
                    colour = G.C.STAR,
                }
            end
        end
    end,
}

-- Monad: gains +0.1 Xchips and +0.1 Xmult permanently -- well, not
-- permanently stored, but live-recomputed every scoring -- for every
-- Hex point currently owned. Hex points are a big() OmegaNum value in
-- this mod (see Soul Candle/Boykisser above), so the multiply goes
-- through the big-number API. Base is 1 (so 0 Hex points = no bonus),
-- same "1 + bonus" shape Boykisser uses for its own Xmult.
SMODS.Joker{
    key = "monad",

    loc_txt = {
        name = "Monad",
        text = {
            "Gains {X:chips,C:white}X#2#{} Chips and",
            "{X:mult,C:white}X#2#{} Mult for every",
            "{C:purple}Hex point{} owned",
            "{C:inactive}(Currently {}{X:chips,C:white}X#1#{}{C:inactive} Chips,{}",
            "{C:inactive}{}{X:mult,C:white}X#1#{}{C:inactive} Mult){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 4, y = 8 }, -- placeholder art slot
    soul_pos = { x = 2, y = 9 }, -- placeholder Soul-card art slot, same as Boykisser above

    rarity = 4,
    in_pool = hex_in_pool,
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            Xmult_gain = big(0.1),
        }
    },

    -- Shows the current live Xchips/Xmult (1 + hex_points x 0.1) in the
    -- card's own text, computed the same way calculate() below applies
    -- it. Guards G.GAME being nil since loc_vars can also be called
    -- from the collection screen outside of a run.
    loc_vars = function(self, info_queue, card)
        local hex_points = (G.GAME and G.GAME.hex_points) or big(0)
        local bonus = hex_points:mul(big(card.ability.extra.Xmult_gain))
        local xstat = big(1):add(bonus)

        return { vars = { xstat, card.ability.extra.Xmult_gain } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            local hex_points = G.GAME.hex_points or big(0)
            local bonus = hex_points:mul(big(card.ability.extra.Xmult_gain))
            local xstat = big(1):add(bonus)

            return {
                x_chips = xstat,
                Xmult = xstat,
            }
        end
    end,
}

-- Schwarzschild Radius: creates 2 Negative (vanilla) Black Hole spectral
-- cards at the end of every round -- the actual base-game c_black_hole
-- card that levels up every poker hand. blueprint_compat = true, so a
-- Blueprint immediately to this Joker's left also triggers its own
-- separate set of 2. Blueprint's copy call reuses this card's own
-- `card` object (context.blueprint = true, same shared card.ability.extra
-- table) rather than a distinct copy, so a single last_round stamp would
-- have the natural firing and the Blueprint-copied firing block each
-- other (whichever runs first marks the round and the other sees it as
-- already-fired). Using two separate stamps -- last_round for the
-- natural path, last_round_blueprint for the Blueprint-copied path --
-- lets each dedupe against end_of_round's own multiple-fires-per-card
-- quirk independently, so both still fire exactly once per round.
local function hex_schwarzschild_create_black_holes()
    for i = 1, 2 do
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.2 * i,
            func = function()
                if G.consumeables then
                    local new_card = SMODS.create_card({
                        key = "c_black_hole",
                        area = G.consumeables
                    })

                    new_card:set_edition({ negative = true }, true)

                    G.consumeables:emplace(new_card)
                end
                return true
            end
        }))
    end
end

SMODS.Joker{
    key = "schwarzschild_radius",

    loc_txt = {
        name = "Schwarzschild Radius",
        text = {
            "Creates {C:attention}2{} {C:dark_edition}Negative{}",
            "{C:attention}Black Hole{} cards at",
            "the end of every round",
        }
    },

    atlas = "HexJokers",
    pos = { x = 4, y = 8 }, -- placeholder art slot
    soul_pos = { x = 2, y = 9 }, -- placeholder Soul-card art slot, same as Boykisser/Monad above

    rarity = 4,
    in_pool = hex_in_pool,
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            last_round = nil,
            last_round_blueprint = {},
        }
    },

    calculate = function(self, card, context)
        if not context.end_of_round then return end

        if context.blueprint then

            if type(card.ability.extra.last_round_blueprint) ~= "table" then
                card.ability.extra.last_round_blueprint = {}
            end

            local bp_card = context.blueprint_card
            local bp_key = bp_card and (bp_card.sort_id or bp_card) or "unknown"

            if card.ability.extra.last_round_blueprint[bp_key] ~= G.GAME.round then
                card.ability.extra.last_round_blueprint[bp_key] = G.GAME.round
                hex_schwarzschild_create_black_holes()

                return {
                    message = "+2 Negative",
                    colour = G.C.SECONDARY_SET.Spectral,
                }
            end
        else
            if card.ability.extra.last_round ~= G.GAME.round then
                card.ability.extra.last_round = G.GAME.round
                hex_schwarzschild_create_black_holes()

                return {
                    message = "+2 Negative",
                    colour = G.C.SECONDARY_SET.Spectral,
                }
            end
        end
    end,
}





SMODS.Joker{
    key = "green_screen",
    loc_txt = {
        name = "Green Screen",
        text = {
            "This Joker gains {X:mult,C:white}X#1#{} Mult",
            "every time a",
            "{C:attention}Full House{} is played",
            "{C:inactive}(Currently {}{X:mult,C:white}X#2#{}{C:inactive} Mult){}"
        }
    },
    config = { extra = { Xmult = big(1), Xmult_gain = big(1) } },
    atlas = "HexJokers",
    pos = { x = 0, y = 0 }, -- first frame in the atlas
    rarity = 4,             -- 1 common, 2 uncommon, 3 rare, 4 legendary
    in_pool = hex_in_pool,
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    calculate = function(self, card, context)
        -- Apply the current Xmult when this joker scores
        if context.joker_main then
            return {
                Xmult = card.ability.extra.Xmult,
            }
        end

        -- Grow permanently whenever a Full House is played
        if context.before and next(context.poker_hands["Full House"]) and not context.blueprint then
            card.ability.extra.Xmult = card.ability.extra.Xmult + card.ability.extra.Xmult_gain
            return {
                message = localize("k_upgrade_ex"),
                colour = G.C.MULT,
            }
        end
    end,

    -- Fills the #1# placeholder in the description text with the current Xmult
    loc_vars = function(self, info_queue, card)
        return { vars = {card.ability.extra.Xmult_gain, card.ability.extra.Xmult } }
    end,
}












SMODS.Joker{
    key = "lemniscate",

    loc_txt = {
        name = "Lemniscate",
        text = {
            "Raises Mult to the power of {C:purple}^#1#{}",
            "Gains {C:purple}+#2#{} power",
            "for every card triggered",
        }
    },

    atlas = "HexJokers",
    pos = {x = 2, y = 0},
    soul_pos = { x = 7, y = 9 },
    rarity = "hex_mythic",
    in_pool = function(self)
        return false
    end,
    cost = 200,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            exponent = big(1),
            exponent_gain = big(0.01)
        }
    },


    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.exponent or big(1),
                card.ability.extra.exponent_gain or big(0.01),
            }
        }
    end,

    calculate = function(self, card, context)

        -- Count every triggered card (retriggering counts)
        if context.individual and context.cardarea == G.play then

            card.ability.extra.exponent =
                (card.ability.extra.exponent or big(1))
                :add(card.ability.extra.exponent_gain or big(0.01))

            return {
                message = "Upgrade",
                colour = G.C.PURPLE
            }

        end

        if context.joker_main and not context.blueprint then

            local exponent = card.ability.extra.exponent or big(1)

            local exponent_display = hex_to_plain_number(exponent)

            return {
                e_mult = exponent,
                colour = G.C.PURPLE
            }

        end
    end
}


SMODS.Joker{
    key = "set_theory",

    loc_txt = {
        name = "Set Theory",
        text = {
            "Gives {C:mult}^#1#{} Mult and",
            "{C:chips}^#1#{} Chips",
            "Gains {C:attention}#2#{} power for",
            "every {C:attention}Booster Pack{} opened",
        }
    },

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot, same as other undrawn Mythic+ jokers
    rarity = "hex_mythic",
    in_pool = function(self) return false end, -- hidden/unlock-only, matching Overflow/Coupon/Final Form Jimbo above
    cost = 200,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    -- e_mult/e_chips is the "^power" exponent-style bonus this file's
    -- own Crystal/Ruby/Sapphire cards already use for their "^1.75" /
    -- "^#1#" text -- plain Lua numbers, not big(), same as those. Starts
    -- at 1 (^1 = no effect yet) and grows permanently from there.
    config = {
        extra = {
            e_mult = big(1),
            e_mult_gain = big(0.25),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.e_mult, card.ability.extra.e_mult_gain } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                e_mult = card.ability.extra.e_mult,
                e_chips = card.ability.extra.e_mult,
            }
        end

        -- Same context.open_booster hook Receipt uses elsewhere in this
        -- file for its own "every Booster Pack opened" trigger.
        if context.open_booster and not context.blueprint then
            card.ability.extra.e_mult = card.ability.extra.e_mult:add(card.ability.extra.e_mult_gain)

            return {
                message = localize("k_upgrade_ex"),
                colour = G.C.MYTHIC,
            }
        end
    end,
}



-- Thermonuclear Bomb: at the end of every Boss Blind, destroys 25% of
-- your full deck (floor-rounded), then permanently gains +0.25 to its
-- own e_mult/e_chips stat for every card destroyed. Floor-rounding
-- means a 1-card deck (floor(0.25*1) = 0) or even a 3-card deck
-- (floor(0.75) = 0) never loses its last card or cards naturally --
-- guarded explicitly below anyway for clarity. Uses the same
-- pool-scan + pseudorandom pick-and-remove + start_dissolve pattern the
-- Collapse Spectral uses in consumables.lua, and the same
-- context.end_of_round + G.GAME.blind.boss + last_round dedupe Totem
-- uses elsewhere in this file. e_mult/e_chips growth and application
-- mirrors Hypergeometric's own ^n Mult/Chips exponent pattern, just
-- growing permanently instead of staying fixed.
SMODS.Joker{
    key = "thermonuclear_bomb",

    loc_txt = {
        name = "Thermonuclear Bomb",
        text = {
            "At the end of every {C:attention}Boss Blind{},",
            "destroys {C:attention}25%{} of your deck",
            "Gains {C:mult}^0.25{} Mult and",
            "{C:chips}^0.25{} Chips for every",
            "card destroyed this way",
            "{C:inactive}(Currently {}{C:mult}^#1#{}{C:inactive} Mult,{}",
            "{C:inactive}{}{C:chips}^#1#{}{C:inactive} Chips){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot, same as other undrawn Mythic+ jokers
    rarity = "hex_mythic",
    in_pool = function(self) return false end, -- hidden/unlock-only rarity, like other Mythic+ jokers

    cost = 200,
    unlocked = true,
    discovered = true,
    blueprint_compat = false, -- self-referential permanent growth tied to this specific card's own destruction event; a Blueprint copy re-triggering the destruction/growth off the same stat would double-apply it
    eternal_compat = true,

    config = {
        extra = {
            e_mult = big(1), -- starts at 1 (^1 = no-op), same convention as Goodstein Sequence/Hypergeometric
            e_chips = big(1),
            last_round = nil,
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.e_mult } }
    end,

    calculate = function(self, card, context)
        -- ^n Mult and ^n Chips, every scoring hand
        if context.joker_main and not context.blueprint then
            return {
                e_mult = card.ability.extra.e_mult,
                e_chips = card.ability.extra.e_chips,
                colour = G.C.MULT,
            }
        end

        -- Destroy 25% of the deck, once per Boss Blind
        if context.end_of_round
        and G.GAME.blind
        and G.GAME.blind.boss
        and not context.blueprint
        and card.ability.extra.last_round ~= G.GAME.round then

            card.ability.extra.last_round = G.GAME.round

            if not (G.playing_cards and #G.playing_cards > 0) then return end

            local pool = {}
            for _, c in ipairs(G.playing_cards) do
                pool[#pool + 1] = c
            end

            local count = math.floor(#pool * 0.25)
            if #pool <= 1 then count = 0 end -- never touch the last card

            if count <= 0 then return end

            local to_destroy = {}
            for i = 1, count do
                if #pool == 0 then break end
                local idx = math.floor(pseudorandom(pseudoseed(mod.prefix .. "_thermonuclear_" .. i), 1, #pool))
                to_destroy[#to_destroy + 1] = pool[idx]
                table.remove(pool, idx)
            end

            local destroyed_count = #to_destroy

            for i, c in ipairs(to_destroy) do
                G.E_MANAGER:add_event(Event({
                    trigger = "after",
                    delay = 0.02 * i,
                    func = function()
                        if c.area then
                            c.area:remove_card(c)
                        end
                        if G.playing_cards then
                            for j, pc in ipairs(G.playing_cards) do
                                if pc == c then
                                    table.remove(G.playing_cards, j)
                                    break
                                end
                            end
                        end
                        c:start_dissolve()
                        return true
                    end
                }))
            end

            local gain = big(0.25):mul(big(destroyed_count))
            card.ability.extra.e_mult = card.ability.extra.e_mult:add(gain)
            card.ability.extra.e_chips = card.ability.extra.e_chips:add(gain)

            return {
                message = "Boom!",
                colour = G.C.RED,
            }
        end
    end,
}






SMODS.Joker{
    key = "khinchin",

    loc_txt = {
        name = "Khinchin's Constant",
        text = {
            "Takes {C:chips}Chips{} to the power of",
            "Khinchin's constant",
            "{C:inactive}(Khinchin's constant is roughly {}{C:attention}2.68545{}{C:inactive}){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot

    rarity = "hex_mythic",
    in_pool = function(self)
        return false
    end,    
    cost = 606,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                e_chips = big(2.68545),
            }
        end
    end,
}

-- Hypergeometric: ^2 Mult and ^2 Chips, plus +$1000 and +20 Hex points
-- at the end of every round. Exponent scoring mirrors Set Theory's
-- e_mult/e_chips pattern above; the end-of-round payout uses the same
-- context.end_of_round + last_round dedupe as Totem/Overtime/Cantor,
-- since context.end_of_round fires multiple times per card in this build.
SMODS.Joker{
    key = "hypergeometric",

    loc_txt = {
        name = "Hypergeometric",
        text = {
            "Gives {C:mult}^#1#{} Mult and",
            "{C:chips}^#1#{} Chips",
            "At the end of round, gives",
            "{C:money}+$#2#{} and {C:purple}+#3#{}",
            "{C:purple}Hex points{}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot, same as other undrawn Mythic+ jokers
    rarity = "hex_mythic",
    in_pool = function(self) return false end, -- hidden/unlock-only rarity, like other Mythic+ jokers

    cost = 200,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,

    config = {
        extra = {
            e_mult = big(2),
            e_chips = big(2),
            dollars = 1000,
            hex_points = big(20),
            last_round = nil,
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.e_mult,
                card.ability.extra.dollars,
                card.ability.extra.hex_points,
            }
        }
    end,

    calculate = function(self, card, context)
        -- ^2 Mult and ^2 Chips, every scoring hand
        if context.joker_main then
            return {
                e_mult = card.ability.extra.e_mult,
                e_chips = card.ability.extra.e_chips,
                colour = G.C.MULT,
            }
        end

        -- +$1000 and +20 Hex points, once per round
        if context.end_of_round
        and not context.blueprint
        and card.ability.extra.last_round ~= G.GAME.round then

            card.ability.extra.last_round = G.GAME.round

            G.GAME.hex_points = (G.GAME.hex_points or big(0)):add(card.ability.extra.hex_points)

            return {
                dollars = card.ability.extra.dollars,
                colour = G.C.MONEY,
            }
        end
    end,
}




-- Zeta Function: reads G.GAME.hex_live_chips (mirrored by the
-- mod_chips() hook in main.lua) -- the running Chips right before this
-- card's own position, including every Joker to its left -- runs it
-- through 2^x / (1 + (2/3)^x + (2/4)^x + (4/9)^x), then returns the
-- result divided by x as Xchip_mod. Same "replace the running stat with
-- f(x) regardless of what's already been applied" trick Ackermann
-- Function above uses for Mult, just for Chips via Xchip_mod (the same
-- multiplicative Chips key Pokémon Card uses elsewhere in this file)
-- instead of Xmult.
SMODS.Joker{
    key = "zeta_function",

    loc_txt = {
        name = "Zeta Function",
        text = {
            "Takes {C:attention}1/(zeta(chips)-1){} of chips",
            "where {C:attention}zeta(x){} is the Riemann zeta function",
            "{C:inactive}(f(x) = 2^x / (1+(2/3)^x +(2/4)^x+(4/9)^x)){}",
        },
    },

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot, same as other undrawn Mythic+ jokers
    rarity = "hex_mythic",
    in_pool = function(self) return false end, -- hidden/unlock-only rarity, like other Mythic+ jokers

    cost = 200,
    unlocked = true,
    discovered = true,
    blueprint_compat = false, -- reads the live running Chips directly; a Blueprint copy would read from ITS OWN position in the row, a different snapshot, so it's excluded below
    eternal_compat = true,

    calculate = function(self, card, context)
        if context.joker_main and not context.blueprint then
            local x = (G.GAME and G.GAME.hex_live_chips) or big(1)

            if x:gt(big(0)) then
                local base1 = big(2):div(big(3))
                local base2 = big(2):div(big(4))
                local base3 = big(4):div(big(9))

                local numerator = big(2):arrow(1, x)
                local denominator = big(1)
                    :add(base1:arrow(1, x))
                    :add(base2:arrow(1, x))
                    :add(base3:arrow(1, x))

                local fx = numerator:div(denominator)
                local xchips = fx:div(x)

                return {
                    Xchip_mod = xchips,
                    message = "X" .. tostring(xchips),
                    colour = G.C.CHIPS,
                }
            end
        end
    end,
}

-- Lorenz Attractor: every hand played, randomly picks ONE of four
-- effects to apply -- ^5 Mult, ^5 Chips, +$5000, or +50 Hex points.
-- Uses the same pseudorandom_element(pool, pseudoseed(key)) pattern
-- as The Seal of Aces above for a seeded, save-compatible random pick.
-- Hex points are applied via direct state mutation (not a native
-- scoring field), same as Totem/Overtime/Cantor elsewhere in this file.
SMODS.Joker{
    key = "lorenz_attractor",

    loc_txt = {
        name = "Lorenz Attractor",
        text = {
            "Every hand played, gives one",
            "of the following at random:",
            "{C:mult}^#1#{} Mult, {C:chips}^#1#{} Chips,",
            "{C:money}+$#2#{}, or {C:purple}+#3#{} {C:purple}Hex points{}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot, same as other undrawn Mythic+ jokers
    rarity = "hex_mythic",
    in_pool = function(self) return false end, -- hidden/unlock-only rarity, like other Mythic+ jokers

    cost = 200,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            e_mult = big(5),
            dollars = 5000,
            hex_points = big(50),
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.e_mult,
                card.ability.extra.dollars,
                card.ability.extra.hex_points,
            }
        }
    end,

    calculate = function(self, card, context)
        if context.joker_main and not context.blueprint then
            local options = { "mult", "chips", "dollars", "hex" }
            local chosen = pseudorandom_element(options, pseudoseed(mod.prefix .. "_lorenz_attractor"))

            if chosen == "mult" then
                return {
                    e_mult = card.ability.extra.e_mult,
                    colour = G.C.MULT,
                }
            elseif chosen == "chips" then
                return {
                    e_chips = card.ability.extra.e_mult,
                    colour = G.C.CHIPS,
                }
            elseif chosen == "dollars" then
                return {
                    dollars = card.ability.extra.dollars,
                    colour = G.C.MONEY,
                }
            else
                G.GAME.hex_points = (G.GAME.hex_points or big(0)):add(card.ability.extra.hex_points)

                return {
                    message = "+50 Hex",
                    colour = G.C.HEX_ORPLE or G.C.PURPLE,
                }
            end
        end
    end,
}




-- Ackermann Function: reads G.GAME.hex_live_mult (mirrored by the
-- mod_mult() hook in main.lua) -- the ACTUAL running Mult right before
-- this card's own position, including every Joker to its left -- computes
-- A(3, mult) = 2^(mult+3) - 3 on it, then returns A(3,mult)/mult as
-- Xmult. Since the engine applies Xmult as mult = mult * Xmult_mod
-- (state_events.lua line 912), mult * (A(3,mult)/mult) = A(3,mult)
-- exactly, regardless of what's already been applied by cards to the
-- left -- effectively REPLACING the running Mult with A(3, mult) at
-- this card's position, rather than just multiplying it further.
SMODS.Joker{
    key = "ackermann_function",

    loc_txt = {
        name = "Ackermann Function",
        text = {
            "Takes the Ackermann Function of mult",
            "{C:attention}A(3, mult){}",
            "{C:inactive}(A(3,n) = 2^(n+3) - 3){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot, same as other undrawn Mythic+ jokers
    rarity = "hex_mythic",
    in_pool = function(self) return false end, -- hidden/unlock-only rarity, like other Mythic+ jokers

    cost = 200,
    unlocked = true,
    discovered = true,
    blueprint_compat = false, -- reads the live running Mult directly; a Blueprint copy would read from ITS OWN position in the row, which is a different (and semantically confusing) snapshot, so it's excluded below
    eternal_compat = true,

    calculate = function(self, card, context)
        if context.joker_main and not context.blueprint then
            local mult = (G.GAME and G.GAME.hex_live_mult) or big(1)

            if mult:gt(big(0)) then
                local a3m = big(2):arrow(1, mult:add(big(3))):sub(big(3))
                local xmult = a3m:div(mult)

                return {
                    Xmult = xmult,
                    colour = G.C.MULT,
                }
            end
        end
    end,
}






-- Aurora: raises both Chips and Mult to the power of (1 + 0.05 per
-- dollar currently held), so 0 dollars = ^1 (no change), 20 dollars =
-- ^2, etc. Live-computed from G.GAME.dollars every time it scores,
-- same "fully dynamic, no stored/growing state" approach Juno uses for
-- its own tetration height -- rises and falls immediately as your
-- balance changes, rather than being a permanent stacking counter like
-- Lemniscate's own exponent. G.GAME.dollars is a plain Lua number in
-- this build (unlike Hex points), so this stays in plain arithmetic
-- rather than going through the big() API.
SMODS.Joker{
    key = "aurora",

    loc_txt = {
        name = "Aurora",
        text = {
            "Raises {C:chips}Chips{} and {C:mult}Mult{}",
            "to the power of {C:attention}^1{}, plus",
            "{C:attention}^0.05{} per {C:money}$1{} held",
            "{C:inactive}(Currently {}{C:attention}^#1#{}{C:inactive}){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 5, y = 0 },

    rarity = "hex_mythic",
    in_pool = function(self)
        return false
    end,

    cost = 200,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    -- Shows the current live exponent (1 + dollars x 0.05, computed in
    -- OmegaNum space) in the card's own text, computed the same way
    -- calculate() below applies it. Guards G.GAME being nil since
    -- loc_vars can also be called from the collection screen outside of
    -- a run.
    loc_vars = function(self, info_queue, card)
        local dollars = to_big((G.GAME and G.GAME.dollars) or 0)
        local exponent = big(1):add(dollars:mul(big(0.05)))

        return { vars = { exponent } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            local dollars = to_big((G.GAME and G.GAME.dollars) or 0)
            local exponent = big(1):add(dollars:mul(big(0.05)))

            return {
                e_chips = exponent,
                e_mult = exponent,
            }
        end
    end,
}


SMODS.Joker{
    key = "hypercube",

    loc_txt = {
        name = "Hypercube",
        text = {
            "Gains {X:chips,C:white}^#2#{} Chips and",
            "{X:mult,C:white}^#2#{} Mult for every",
            "{C:purple}Hex point{} owned",
            "{C:inactive}(Currently {}{X:chips,C:white}^#1#{}{C:inactive} Chips,{}",
            "{C:inactive}{}{X:mult,C:white}^#1#{}{C:inactive} Mult){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot

    rarity = "hex_mythic",
    in_pool = function(self)
        return false
    end,    
    cost = 606,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            e_mult_gain = big(0.1),
        }
    },

    -- Shows the current live Xchips/Xmult (1 + hex_points x 0.1) in the
    -- card's own text, computed the same way calculate() below applies
    -- it. Guards G.GAME being nil since loc_vars can also be called
    -- from the collection screen outside of a run.
    loc_vars = function(self, info_queue, card)
        local hex_points = (G.GAME and G.GAME.hex_points) or big(0)
        local bonus = hex_points:mul(big(card.ability.extra.e_mult_gain))
        local xstat = big(1):add(bonus)

        return { vars = { xstat, card.ability.extra.e_mult_gain } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            local hex_points = G.GAME.hex_points or big(0)
            local bonus = hex_points:mul(big(card.ability.extra.e_mult_gain))
            local xstat = big(1):add(bonus)

            return {
                e_chips = xstat,
                e_mult = xstat,
            }
        end
    end,
}




-- Glitch: every hand played, rolls two SEPARATE random integers
-- 1-10 -- one for ^Mult, one for ^Chips. Uses the same
-- math.floor(pseudorandom(pseudoseed(key), 1, max)) integer-roll
-- pattern as the Collapse effect in consumables.lua, with two distinct
-- seed keys so the two rolls don't move in lockstep with each other.
SMODS.Joker{
    key = "glitch",

    loc_txt = {
        name = "Glitch",
        text = {
            "Gives {C:mult}^1{} to {C:mult}^10{} Mult",
            "and {C:chips}^1{} to {C:chips}^10{} Chips",
            "at random, {C:attention}separately{},",
            "when {C:attention}playing{} a hand",
        }
    },

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot, same as other undrawn Mythic+ jokers
    rarity = "hex_mythic",
    in_pool = function(self) return false end, -- hidden/unlock-only rarity, like other Mythic+ jokers

    cost = 200,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            last_mult_roll = 1,
            last_chips_roll = 1,
        }
    },

    -- Shows the most recent roll in the card's own text, same
    -- "display the last live value" approach other dynamic jokers in
    -- this file use for their (Currently ...) lines.
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.last_mult_roll,
                card.ability.extra.last_chips_roll,
            }
        }
    end,

    calculate = function(self, card, context)
        if context.joker_main and not context.blueprint then
            local mult_roll = math.floor(pseudorandom(pseudoseed(mod.prefix .. "_glitch_mult"), 1, 10))
            local chips_roll = math.floor(pseudorandom(pseudoseed(mod.prefix .. "_glitch_chips"), 1, 10))

            card.ability.extra.last_mult_roll = mult_roll
            card.ability.extra.last_chips_roll = chips_roll

            return {
                e_mult = big(mult_roll),
                e_chips = big(chips_roll),
                colour = G.C.MULT,
            }
        end
    end,
}




SMODS.Joker{
    key = "overflow",

    loc_txt = {
        name = "Overflow",
        text = {
            "Gain {C:mythic}+1{} Joker slot",
            "after defeating each Boss Blind"
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 0 },

    rarity = "hex_mythic",
    in_pool = function(self)
        return false
    end,

    cost = 200,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    
    config = {
        extra = {
            last_round = nil
        }
    },

    calculate = function(self, card, context)
        -- NOTE: this used to dedupe against G.GAME.round_resets.ante, but
        -- that field doesn't actually increment at the moment end_of_round
        -- fires right after beating a Boss Blind -- it only updates later,
        -- once the next blind is set up -- so the ante-based check only
        -- ever passed once and never again after that. Deduping against
        -- G.GAME.round instead (the same per-card-stamp trick Black Seal
        -- uses elsewhere in this file for its own end_of_round quirk)
        -- tracks "have we already given a slot for this round's boss
        -- fight" directly, which is the thing we actually care about.
        if context.end_of_round
        and G.GAME.blind
        and G.GAME.blind.boss
        and not context.blueprint
        and card.ability.extra.last_round ~= G.GAME.round then

            card.ability.extra.last_round = G.GAME.round

            G.E_MANAGER:add_event(Event({
                func = function()
                    G.jokers.config.card_limit = G.jokers.config.card_limit + 1
                    return true
                end
            }))

            return {
                message = "+1 Slot",
                colour = G.C.MYTHIC
            }
        end
    end
}

-- Orion: draws the entire remaining deck into hand at the start of every
-- round. NOTE: this used to be hooked off a `context.first_hand_drawn`
-- calculate context, but that context flag doesn't actually exist/fire in
-- this Steamodded build (that's why it was silently doing nothing and you
-- kept seeing the normal 8-card hand). The real trigger logic now lives in
-- the per-frame Game:update poll further down the file, right next to the
-- other "while owned, do X" checks like Polydactyly's hand-limit override
-- and Fractal's boss-disable check -- see hex_orion_last_round below.
SMODS.Joker{
    key = "orion",

    loc_txt = {
        name = "Orion",
        text = {
            "At the start of each round,",
            "{C:attention}draw the entire deck{}",
            "into hand",
        }
    },

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot, same as other undrawn Mythic+ jokers

    rarity = "hex_mythic",
    in_pool = function(self)
        return false -- hidden/unlock-only rarity, like the other Mythic+ jokers
    end,

    cost = 200,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
}

SMODS.Joker{
    key = "polydactyly",

    loc_txt = {
        name = "Polydactyly",
        text = {
            "{C:attention}Infinte{}",
            "card selection limit",
        }
    },

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot, same as other undrawn Mythic+ jokers

    rarity = "hex_mythic",
    in_pool = function(self)
        return false
    end,

    cost = 200,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
}

-- Polydactyly: G.hand.config.highlighted_limit (set in the Game:update
-- hook further down) is enough to let you *highlight* more than 5 cards,
-- since CardArea:add_to_highlighted reads that value live. But the Play
-- Hand button's enable/disable check, G.FUNCS.can_play, has its own
-- hardcoded `#G.hand.highlighted > 5` in vanilla Balatro -- completely
-- separate from highlighted_limit -- so it greys out past 5 regardless.
-- We override can_play to drop that hardcoded cap whenever the
-- effective selection limit has actually been raised above 5 -- either
-- because Polydactyly is owned (its own highlighted_limit override sets
-- it all the way to 999995), or because Pinwheel Galaxy (Galaxy) has
-- permanently bumped it a few points past 5 -- rather than only
-- Polydactyly specifically, so Pinwheel Galaxy's bonus isn't silently
-- capped back down to 5 the moment you actually try to play/discard.
-- (can_discard has no equivalent hardcoded cap in vanilla, so it
-- doesn't need a matching override.)
local function hex_selection_limit_raised()
    if SMODS.find_card and #SMODS.find_card("j_" .. mod.prefix .. "_polydactyly") > 0 then
        return true
    end
    return G.hand and G.hand.config
        and (G.hand.config.highlighted_limit or HEX_POLY_DEFAULT_HAND_LIMIT) > HEX_POLY_DEFAULT_HAND_LIMIT
end

local old_can_play = G.FUNCS.can_play
G.FUNCS.can_play = function(e)
    -- Allow playing with nothing highlighted, so the "None" hand can be
    -- submitted -- mirrors how Cryptid implements their own None hand:
    -- they don't touch play_cards_from_highlighted at all, they just let
    -- the normal Play Hand button/flow fire with 0 cards. Vanilla's own
    -- play_cards_from_highlighted -> evaluate_play chain already handles
    -- hands_left decrementing and the state transition correctly; our
    -- earlier attempt to bypass straight to evaluate_play skipped
    -- whatever step does that, which is why hands_left never moved and
    -- it only worked once.
    if #G.hand.highlighted == 0 then
        if G.GAME.blind and G.GAME.blind.block_play then
            e.config.colour = G.C.UI.BACKGROUND_INACTIVE
            e.config.button = nil
        else
            e.config.colour = G.C.BLUE
            e.config.button = "play_cards_from_highlighted"
        end
    elseif hex_selection_limit_raised() then
        if #G.hand.highlighted <= 0 or (G.GAME.blind and G.GAME.blind.block_play) then
            e.config.colour = G.C.UI.BACKGROUND_INACTIVE
            e.config.button = nil
        else
            e.config.colour = G.C.BLUE
            e.config.button = "play_cards_from_highlighted"
        end
    else
        old_can_play(e)
    end
end

-- Discard: this installed game's version of can_discard apparently also
-- hardcodes an upper cap (unlike the source snapshot checked during
-- development, which only gated on discards_left/highlighted<=0) -- same
-- symptom as can_play, same fix: bypass it entirely whenever the
-- effective selection limit has been raised (see hex_selection_limit_raised
-- above) and just gate on the two things that should actually matter,
-- discards remaining and having something highlighted.
local old_can_discard = G.FUNCS.can_discard
G.FUNCS.can_discard = function(e)
    if hex_selection_limit_raised() then
        if (G.GAME.current_round and (G.GAME.current_round.discards_left or 0) <= 0)
        or #G.hand.highlighted <= 0 then
            e.config.colour = G.C.UI.BACKGROUND_INACTIVE
            e.config.button = nil
        else
            e.config.colour = G.C.RED
            e.config.button = "discard_cards_from_highlighted"
        end
    else
        old_can_discard(e)
    end
end


-- Gamma Function: reads G.GAME.hex_live_mult (same mirror the mod_mult
-- hook in main.lua already maintains for Ackermann Function above) --
-- the running Mult right before this card's own position, including
-- every Joker to its left -- runs it through
-- 2.5 * sqrt(x) * (x^2 / e^x), then returns the result divided by x as
-- Xmult. Same "replace the running stat with f(x) regardless of what's
-- already been applied" trick Ackermann Function/Zeta Function use.
-- e is hardcoded as a big() literal since there's no built-in Euler's
-- number constant in this codebase's OmegaNum layer; big(2.71828...):
-- arrow(1, x) computes e^x the same way base:arrow(1, exponent) is used
-- for "^" everywhere else in this file.
SMODS.Joker{
    key = "gamma_function",

    loc_txt = {
        name = "Gamma Function",
        text = {
            "Takes the {C:attention}Gamma function{} of mult",
            "{C:inactive}(f(x) = 2.5*sqrt(x)*(x^2/e^x)){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot, same as other undrawn Mythic+ jokers
    rarity = "hex_mythic",
    in_pool = function(self) return false end, -- hidden/unlock-only rarity, like other Mythic+ jokers

    cost = 200,
    unlocked = true,
    discovered = true,
    blueprint_compat = false, -- reads the live running Mult directly; a Blueprint copy would read from ITS OWN position in the row, a different snapshot, so it's excluded below
    eternal_compat = true,

    calculate = function(self, card, context)
        if context.joker_main and not context.blueprint then
            local x = (G.GAME and G.GAME.hex_live_mult) or big(1)

            if x:gt(big(0)) then
                local e_const = big(2.718281828459045)

                local sqrt_x = x:arrow(1, 0.5)
                local x_tet = x:arrow(2, 2)
                local e_pow_x = e_const:arrow(1, x)

                local fx = big(2.5):mul(sqrt_x):mul(x_tet):div(e_pow_x)
                local xmult = fx:div(x)

                return {
                    Xmult = xmult,
                    colour = G.C.MULT,
                }
            end
        end
    end,
}


SMODS.Joker{
    key = "hamiltonian",

    loc_txt = {
        name = "Hamiltonian",
        text = {
            "Gains {C:chips}^0.25{} Chips when",
            "selling a Joker with higher",
            "rarity than Common",
            "{C:inactive}(Currently {}{C:chips}^#1#{}{C:inactive} Chips){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot, same as other undrawn Mythic+ jokers

    rarity = "hex_mythic",
    in_pool = function(self)
        return false -- hidden/unlock-only rarity, like the other Mythic+ jokers
    end,

    cost = 200,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            e_chips = big(1),
            e_chips_gain = big(0.25),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.e_chips } }
    end,

    calculate = function(self, card, context)
        -- Apply the exponent
        if context.joker_main then
            return {
                e_chips = card.ability.extra.e_chips,
                colour = G.C.CHIPS,
            }
        end

        -- Detect selling a Joker with rarity above Common (rarity 1).
        -- Same context.selling_card + context.card.ability.set == "Joker"
        -- shape trash_bin uses for its own Rare-only check, just gated on
        -- "not Common" (~= 1) instead of a single specific rarity, so any
        -- Uncommon/Rare/Legendary/Mythic+ sale qualifies.
        if context.selling_card
        and context.card.ability
        and context.card.ability.set == "Joker"
        and context.card.config.center.rarity ~= 1
        and not context.blueprint then

            card.ability.extra.e_chips =
                card.ability.extra.e_chips:add(card.ability.extra.e_chips_gain)

            return {
                message = localize("k_upgrade_ex"),
                colour = G.C.MYTHIC,
            }
        end
    end,
}

-- Lagrangian: while owned, sets G.GAME.probabilities.normal to an
-- enormous value, guaranteeing every probability check in this
-- codebase resolves as true. G.GAME.probabilities.normal is the same
-- shared global multiplier Oops All 6s/Crystal Ball/Russian Roulette
-- etc. all read as `chance = base_chance * G.GAME.probabilities.normal`
-- before comparing against pseudorandom() (content.lua:1571/1595,
-- jokers.lua:1266/2008/2547/2743) -- with base_chance typically a
-- small fraction like 1/4 or 1/23, a multiplier this large pushes the
-- computed chance far past 1, which pseudorandom()'s [0,1) roll can
-- never exceed, guaranteeing a hit. Uses the same add_to_deck/
-- remove_from_deck lifecycle pair Open Market uses for its own
-- persistent global bonus, applied once regardless of how the card
-- enters/leaves your Jokers.
SMODS.Joker{
    key = "lagrangian",

    loc_txt = {
        name = "Lagrangian",
        text = {
            "All listed probabilities are",
            "{C:attention}100%{} chance to happen",
        }
    },

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot, same as other undrawn Mythic+ jokers
    rarity = "hex_mythic",
    in_pool = function(self) return false end, -- hidden/unlock-only rarity, like other Mythic+ jokers

    cost = 200,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,

    config = {
        extra = {
            previous_normal = nil,
        }
    },

    add_to_deck = function(self, card, from_debuff)
        G.GAME.probabilities = G.GAME.probabilities or {}
        G.GAME.probabilities.normal = (G.GAME.probabilities.normal or 1) * 1000
    end,

    remove_from_deck = function(self, card, from_debuff)
        if G.GAME.probabilities then
            G.GAME.probabilities.normal = (G.GAME.probabilities.normal or 1000) / 1000
        end
    end,
}





















-- Spacetime: at the end of a Boss Blind, creates 1 random Black Hole
-- card. Same context.end_of_round + G.GAME.blind.boss + last_round
-- dedupe pattern Totem uses above, and the same
-- hex_get_black_hole_centers() + explicit-key SMODS.create_card pattern
-- Sheaf uses for Star cards elsewhere in this file (Black Hole cards
-- are this mod's own custom ConsumableType, shop_rate = 0, never
-- naturally generated -- see hex_get_black_hole_centers() in
-- consumables.lua, which already respects Showman for duplicates).
SMODS.Joker{
    key = "spacetime",

    loc_txt = {
        name = "Spacetime",
        text = {
            "Creates {C:attention}1{} random",
            "{C:black_hole}Black Hole{} card at the",
            "end of a {C:attention}Boss Blind{}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot, same as other undrawn Transcendental+ jokers
    rarity = "hex_transcendental",
    in_pool = function(self)
        return false -- hidden/unlock-only rarity, like Cantor/Jokeo/SSCG Function above
    end,

    cost = 100000,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,

    config = {
        extra = {
            last_round = nil,
        }
    },

    calculate = function(self, card, context)
        if context.end_of_round
        and G.GAME.blind
        and G.GAME.blind.boss
        and not context.blueprint
        and card.ability.extra.last_round ~= G.GAME.round then

            card.ability.extra.last_round = G.GAME.round

            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.2,
                func = function()
                    if G.consumeables and #G.consumeables.cards < G.consumeables.config.card_limit then
                        local pool = hex_get_black_hole_centers()

                        if #pool > 0 then
                            local chosen = pool[math.random(#pool)]

                            local new_card = SMODS.create_card({
                                key = chosen.key,
                                area = G.consumeables,
                            })

                            G.consumeables:emplace(new_card)
                        end
                    end
                    return true
                end
            }))

            return {
                message = "Black Hole!",
                colour = G.C.BLACK_HOLE,
            }
        end
    end,
}




-- Amplifier: makes every scaling Joker scale as O(a^n) instead of
-- Singularity's O(n^a), where a = this card's own extra.exponent
-- (starts at 2). Storing it as `extra.exponent` means Entropy squares
-- it automatically, no allowlist entry needed -- "exponent$" is already
-- in HEX_ENTROPY_SCORE_PATTERNS (consumables.lua), and
-- hex_entropy_square_table recurses into any plain sub-table (like
-- `extra`) looking for name matches regardless of the per-Joker
-- allowlist, which is only needed for fields that DON'T match a known
-- name pattern.
SMODS.Joker{
    key = "amplifier",

    loc_txt = {
        name = "Amplifier",
        text = {
            "Every {C:attention}scaling{} Joker",
            "permanently scales at",
            "{C:attention}O(#1#^n){}, overwriting",
            "{C:attention}Singularity{} scaling",
            "{C:inactive}(n = times that Joker has scaled){}",
            "{C:inactive}(a can be squared by {}{C:attention}Entropy{}{C:inactive}){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot, same as other undrawn Transcendental+ jokers
    rarity = "hex_transcendental",
    in_pool = function(self)
        return false -- hidden/unlock-only rarity, like Cantor/Jokeo/Einstein above
    end,

    cost = 100000,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,

    config = {
        extra = {
            exponent = big(2), -- "a" -- named extra.exponent specifically so Entropy's existing field-name matching squares it for free
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.exponent } }
    end,
}



-- Same override as before, but the Card.calculate_joker wrap is now
-- installed LAZILY (on first use) rather than at file-load time.
-- jokers.lua loads before consumables.lua in this mod, so capturing
-- Card.calculate_joker here directly would grab the UNPATCHED original --
-- Singularity's own patch (installed later, in consumables.lua) would
-- then wrap OURS instead of the other way around, meaning Singularity's
-- polynomial rewrite would run AFTER Amplifier's and silently undo it.
-- Deferring the actual wrap until the first real call happens (which is
-- guaranteed to be well after every mod file has finished loading, since
-- Card.calculate_joker isn't called until an actual hand is scored)
-- ensures we always wrap whatever's ALREADY installed at that point --
-- Singularity included -- so Amplifier's rewrite still runs last.
function hex_amplifier_rewrite(card, snapshot, a)
    if #snapshot == 0 then return end

    card.ability.hex_amplifier_info = card.ability.hex_amplifier_info or {}
    local info = card.ability.hex_amplifier_info

    for _, s in ipairs(snapshot) do
        local now = s.tbl[s.key]

        if type(now) == "number" or type(now) == "table" or type(now) == "cdata" then
            local delta = to_big(now):sub(s.value)

            if delta:gt(big(0)) then
                local entry = info[s.path]
                if not entry then
                    entry = { base = hex_singularity_lenient(delta), n = big(0) }
                    info[s.path] = entry
                end

                entry.n = to_big(entry.n):add(big(1))
                local n = entry.n

                if entry.rate_key == nil then
                    entry.rate_key = hex_singularity_find_rate_field(s.tbl, s.key, delta) or false
                end

                if entry.rate_key then
                    local next_step = a:arrow(1, n:add(big(1))):sub(a:arrow(1, n))

                    print("AMPLIFIER n=" .. tostring(n) .. " a=" .. tostring(a)
                        .. " next_step=" .. tostring(next_step)
                        .. " base=" .. tostring(entry.base)) -- TEMP DEBUG

                    if next_step:gt(big(0)) then
                        local written = to_big(entry.base):mul(next_step)
                        print("AMPLIFIER writing " .. tostring(written) .. " to " .. tostring(entry.rate_key)) -- TEMP DEBUG
                        s.tbl[entry.rate_key] = hex_singularity_lenient(written)
                    else
                        print("AMPLIFIER next_step NOT > 0, skipping write") -- TEMP DEBUG
                    end
                else
                    local step

                    if n:lt(big(2)) then
                        step = big(1)
                    else
                        step = a:arrow(1, n):sub(a:arrow(1, n:sub(big(1))))
                    end

                    if step:gt(big(0)) then
                        s.tbl[s.key] = hex_singularity_lenient(
                            s.value:add(to_big(entry.base):mul(step))
                        )
                    end
                end
            end
        end
    end
end

function hex_amplifier_a()
    local found = SMODS.find_card("j_" .. mod.prefix .. "_amplifier")
    if found and found[1] and found[1].ability and found[1].ability.extra then
        return to_big(found[1].ability.extra.exponent or 2)
    end
    return big(2)
end



-- Install trigger, take three: G.FUNCS.evaluate_play doesn't reliably
-- fire the way this needed (see the N of a Kind / Flush N of a Kind
-- comment on G.HEX_REAL_SCORING's own declaration -- that exact wrap
-- approach was tried and documented as not actually working in this
-- build, for reasons specific to how vanilla defers scoring). Using
-- Game:update instead -- the same per-frame poll pattern Orion's
-- start-of-round check and the hex_relativistic_jets/Coupon-style
-- "while owned, do X" checks already use successfully in this file --
-- guarantees this runs on some frame well after every file (including
-- consumables.lua's Singularity patch) has finished loading, since the
-- game has to render at least one frame before any of that matters.
local hex_amplifier_hook_installed = false

local hex_old_game_update_amplifier = Game.update

function Game:update(dt)
    if not hex_amplifier_hook_installed then
        hex_amplifier_hook_installed = true

        local hex_old_calculate_joker_amplifier = Card.calculate_joker

        Card.calculate_joker = function(self, context)
            if not (self.ability and SMODS.find_card("j_" .. mod.prefix .. "_amplifier")[1]) then
                return hex_old_calculate_joker_amplifier(self, context)
            end

            local ok, err = pcall(function()
                local a = hex_amplifier_a()

                local snapshot = {}
                hex_singularity_collect(self.ability, 1, "", snapshot)

                local ret = hex_old_calculate_joker_amplifier(self, context)

                hex_amplifier_rewrite(self, snapshot, a)

                return ret
            end)

            if not ok then
                print("AMPLIFIER ERROR: " .. tostring(err)) -- TEMP DEBUG
                return hex_old_calculate_joker_amplifier(self, context)
            end

            return ok and err -- pcall's second return is the wrapped function's return value when ok
        end
    end

    return hex_old_game_update_amplifier(self, dt)
end



-- Exponential Factorial: reads G.GAME.hex_live_mult (same mirror the
-- mod_mult hook in main.lua maintains for Ackermann Function above) --
-- the running Mult right before this card's own position, including
-- every Joker to its left. Only triggers when that Mult is above 5,
-- where 10^^(n - 2.2787667783) is a close approximation of the true
-- exponential factorial sequence. 10:arrow(2, x) is tetration (10^^x),
-- the same arrow(2, n) operator this file's own ee_mult/ee_chips fields
-- use elsewhere, just with a fractional height here rather than an
-- integer one. Same "return f(x)/x as Xmult" trick Ackermann/Gamma/Zeta
-- use to replace the running stat with f(x) regardless of what's
-- already been applied by Jokers to the left.
SMODS.Joker{
    key = "exponential_factorial",

    loc_txt = {
        name = "Exponential Factorial",
        text = {
            "Takes the {C:attention}exponential factorial{} of Mult",
            "{C:inactive}(10^^(n - 2.2787667783)){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot, same as other undrawn Transcendental+ jokers
    rarity = "hex_transcendental",
    in_pool = function(self)
        return false -- hidden/unlock-only rarity, like Cantor/Jokeo/Einstein above
    end,

    cost = 100000,
    unlocked = true,
    discovered = true,
    blueprint_compat = false, -- reads the live running Mult directly; a Blueprint copy would read from ITS OWN position in the row, a different snapshot, so it's excluded below
    eternal_compat = true,

    calculate = function(self, card, context)
        if context.joker_main and not context.blueprint then
            local n = (G.GAME and G.GAME.hex_live_mult) or big(1)

            local height = n:sub(big(2.2787667783))
            local fx = big(10):arrow(2, height)
            local xmult = fx:div(n)

            return {
                Xmult = xmult,
                message = "=" .. tostring(fx),
                colour = G.C.MULT,
            }
        end
    end,
}





-- Cantor: gives its current award (starting at +50) in Hex points at the
-- end of every round, then -- if that round was ended by defeating a
-- Boss Blind -- permanently grows that award by +25 for all future
-- rounds. Same end_of_round + per-card round-stamp dedupe that Totem/
-- Overtime use elsewhere in this file (context.end_of_round fires
-- multiple times per card in this build), combined with the same
-- "apply current value, then permanently grow it" ordering Cubed Joker
-- uses for its own Xchips. The payout for the boss round itself still
-- uses the pre-growth award; the +25 takes effect starting the round
-- after.
SMODS.Joker{
    key = "cantor",

    loc_txt = {
        name = "Cantor",
        text = {
            "Gives {C:purple}+#1#{} Hex points",
            "at the end of every round",
            "{C:purple}+#2#{} permanently at the",
            "end of every {C:attention}Boss Blind{}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot, same as other undrawn Transcendental+ jokers

    rarity = "hex_transcendental",
    in_pool = function(self)
        return false -- hidden/unlock-only rarity, like Juno/Endless Abyss above
    end,

    cost = 100000,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,

    config = {
        extra = {
            award = big(50),
            award_gain = big(25),
            last_round = nil,
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.award,
                card.ability.extra.award_gain,
            }
        }
    end,

    calculate = function(self, card, context)
        if context.end_of_round
        and not context.blueprint
        and card.ability.extra.last_round ~= G.GAME.round then

            card.ability.extra.last_round = G.GAME.round

            G.GAME.hex_points = (G.GAME.hex_points or big(0)):add(card.ability.extra.award)

            local was_boss = G.GAME.blind and G.GAME.blind.boss

            if was_boss then
                card.ability.extra.award = card.ability.extra.award:add(card.ability.extra.award_gain)
            end
        end
    end,
}




SMODS.Joker{
    key = "aleph_null",

    loc_txt = {
        name = "Aleph Null",
        text = {
            "Gains {X:chips,C:white}^^#2#{} Chips and",
            "{X:mult,C:white}^^#2#{} Mult for every",
            "{C:purple}Hex point{} owned",
            "{C:inactive}(Currently {}{X:chips,C:white}^^#1#{}{C:inactive} Chips,{}",
            "{C:inactive}{}{X:mult,C:white}^^#1#{}{C:inactive} Mult){}",
        },
    },

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot

    rarity = "hex_transcendental",
    in_pool = function(self)
        return false
    end,    
    cost = 246913578,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            ee_mult_gain = big(0.1),
        }
    },

    -- Shows the current live Xchips/Xmult (1 + hex_points x 0.1) in the
    -- card's own text, computed the same way calculate() below applies
    -- it. Guards G.GAME being nil since loc_vars can also be called
    -- from the collection screen outside of a run.
    loc_vars = function(self, info_queue, card)
        local hex_points = (G.GAME and G.GAME.hex_points) or big(0)
        local bonus = hex_points:mul(big(card.ability.extra.ee_mult_gain))
        local xstat = big(1):add(bonus)

        return { vars = { xstat, card.ability.extra.ee_mult_gain } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            local hex_points = G.GAME.hex_points or big(0)
            local bonus = hex_points:mul(big(card.ability.extra.ee_mult_gain))
            local xstat = big(1):add(bonus)

            return {
                ee_chips = xstat,
                ee_mult = xstat,
            }
        end
    end,
}


-- Juno: raises Mult by tetration (^^), with the tetration height
-- equal to the number of currently owned Jokers -- Juno counts itself,
-- so 5 owned Jokers (Juno included) means the final Mult is raised to
-- ^^5. Unlike Exponent Joker, this isn't a permanent stacking counter;
-- the height is derived live from #G.jokers.cards every time it scores,
-- so it rises and falls immediately as Jokers are bought/sold/destroyed,
-- the same "fully dynamic" approach Absolute uses for its hyperoperator
-- bonus. `to_big(mult):arrow(2, height)` is Amulet's OmegaNum tetration
-- (arrow(2, n) = ^^n), applied directly to the current running Mult.
SMODS.Joker{
    key = "juno",

    loc_txt = {
        name = "Juno",
        text = {
            "{C:transcendental}^^#1#{} {C:mult}mult{}",
            "{C:transcendental}+1{} per owned Joker",
        }
    },

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot, same as other undrawn Transcendental+ jokers

    rarity = "hex_transcendental",
    in_pool = function(self)
        return false -- hidden/unlock-only rarity, like Aria/Overflow/Exponent Joker
    end,
 
    cost = 203050,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    -- Fills the #1# placeholder in the description text with the current
    -- tetration height (i.e. how many Jokers are currently owned).
    loc_vars = function(self, info_queue, card)
        local height = ((G.jokers and #G.jokers.cards) or 1) +1
        return { vars = { height } }
    end,

    calculate = function(self, card, context)
        -- Applied when Juno itself scores, in its actual position among
        -- the Joker slots (like Musa Acuminata's ^2), rather than being
        -- forced to the very end of scoring. Jokers to Juno's left have
        -- already applied their Chips/Mult changes when this tetration
        -- happens, and Jokers to Juno's right apply on top of it.
        if context.joker_main then
            local height = ((G.jokers and #G.jokers.cards) or 1) + 1

            if height > 0 then
                return {
                    ee_mult = height,
                }
            end
        end
    end,
}

-- Endless Abyss: grants a flat +99,995 Joker slots while owned, using the
-- same add_to_deck/remove_from_deck lifecycle Steamodded Jokers get (the
-- same pair Inaccessible's add_to_deck already uses elsewhere in this
-- file for its own one-shot flag flip). Adding the bonus in add_to_deck
-- and symmetrically subtracting it in remove_from_deck means it's applied
-- exactly once no matter how the card enters/leaves your Jokers (bought,
-- created via Life/Manifest-style summon, sold, destroyed, etc.), rather
-- than needing a per-frame poll like Polydactyly/Coupon/Fractal above.
SMODS.Joker{
    key = "endless_abyss",

    loc_txt = {
        name = "Endless Abyss",
        text = {
            "Gives {C:transcendental}Infinite{}",
            "{C:attention}Joker slots{}",
        }
    },

    rarity = "hex_transcendental",
    in_pool = function(self) return false end, -- hidden/unlock-only rarity, like the other Divine jokers

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot shared with the other undrawn Divine/Transcendental jokers

    cost = 100000,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,

    add_to_deck = function(self, card, from_debuff)
        G.jokers.config.card_limit = G.jokers.config.card_limit + 999995
    end,

    remove_from_deck = function(self, card, from_debuff)
        G.jokers.config.card_limit = G.jokers.config.card_limit - 999995
    end,
}


-- Jokeo: at the end of the shop, duplicates a random OWNED Joker of
-- Mythic rarity or below (excludes Transcendental/Divine/Absolute --
-- and Jokeo itself, since Jokeo's own rarity is hex_transcendental --
-- so nothing above Mythic can ever be picked) as a Negative copy.
-- Same G.FUNCS.toggle_shop hook + copy_card + set_edition({negative=true})
-- pattern the Perkeo-copy hook above uses for consumables, just
-- pointed at G.jokers.cards with a rarity filter instead. No card_limit
-- check, matching Fermi Method's own reasoning elsewhere in this file --
-- Negative Jokers don't count against the Joker slot limit in vanilla.
local hex_old_toggle_shop_jokeo = G.FUNCS.toggle_shop

G.FUNCS.toggle_shop = function(e)
    if G.jokers and G.jokers.cards then
        for _, source in ipairs(G.jokers.cards) do
            if source.config and source.config.center
            and source.config.center.key == ("j_" .. mod.prefix .. "_jokeo") then

                local pool = {}
                for _, j in ipairs(G.jokers.cards) do
                    local rarity = j.config and j.config.center and j.config.center.rarity

                    -- Mythic (string key "hex_mythic") or below (plain
                    -- numeric rarities 1-4). Transcendental/Divine/Absolute
                    -- are their own separate string keys, so they're
                    -- excluded automatically -- this also excludes Jokeo
                    -- itself, whose own rarity is "hex_transcendental".
                    if j ~= source
                    and (type(rarity) == "number" or rarity == "hex_mythic") then
                        pool[#pool + 1] = j
                    end
                end

                if pool[1] then
                    local chosen = pseudorandom_element(pool, pseudoseed(mod.prefix .. "_jokeo"))

                    G.E_MANAGER:add_event(Event({
                        trigger = "after",
                        delay = 0.2,
                        func = function()
                            local new_card = copy_card(chosen, nil)
                            new_card:set_edition({ negative = true }, true)
                            new_card:add_to_deck()
                            G.jokers:emplace(new_card)
                            return true
                        end
                    }))

                    card_eval_status_text(source, "extra", nil, nil, nil, {
                        message = localize("k_duplicated_ex"),
                        colour = G.C.LEGENDARY,
                    })
                end
            end
        end
    end

    return hex_old_toggle_shop_jokeo(e)
end

SMODS.Joker{
    key = "jokeo",

    loc_txt = {
        name = "Jokeo",
        text = {
            "At the end of the shop,",
            "creates a {C:dark_edition}Negative{} copy of a",
            "random owned Joker of",
            "{C:mythic}Mythic{} rarity or below",
        }
    },

    atlas = "HexJokers",
    pos = { x = 7, y = 8 }, 
    soul_pos = { x = 1, y = 9 },
    rarity = "hex_transcendental",
    in_pool = function(self)
        return false -- hidden/unlock-only rarity, like Cantor/Juno/Endless Abyss above
    end,

    cost = 200000,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
}










-- SSCG Function: when a Blind is selected, adds one card with a random
-- Suit and Rank to your deck, carrying the Diamond enhancement. Uses
-- the same context.setting_blind + last_round dedupe as Dirac Equation
-- above (that context fires more than once per blind-select in this
-- build), and the same SMODS.create_card{set="Base",...} + add_to_deck +
-- G.playing_cards registration block the Genesis consumable uses
-- elsewhere in this mod for creating a fresh playing card mid-run.
local HEX_SSCG_RANKS = { "A", "K", "Q", "J", "T", "9", "8", "7", "6", "5", "4", "3", "2" }
local HEX_SSCG_SUITS = { "Spades", "Hearts", "Clubs", "Diamonds" }

SMODS.Joker{
    key = "sscg_function",

    loc_txt = {
        name = "SSCG Function",
        text = {
            "When {C:attention}Blind{} is selected,",
            "adds a card with a random",
            "Suit and Rank to your deck,",
            "carrying the {C:blue}Diamond{} enhancement",
        }
    },

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot, same as other undrawn Transcendental+ jokers
    rarity = "hex_transcendental",
    in_pool = function(self)
        return false -- hidden/unlock-only rarity, like Cantor/Dirac Equation above
    end,

    cost = 100000,
    unlocked = true,
    discovered = true,
    blueprint_compat = false, -- same reasoning as Dirac Equation: effect explicitly excludes context.blueprint below, so a Blueprint copy has nothing to trigger
    eternal_compat = true,

    config = {
        extra = {
            last_round = nil,
        }
    },

    calculate = function(self, card, context)
        if context.setting_blind
        and not context.blueprint
        and card.ability.extra.last_round ~= G.GAME.round then

            card.ability.extra.last_round = G.GAME.round

            local suit = pseudorandom_element(HEX_SSCG_SUITS, pseudoseed(mod.prefix .. "_sscg_suit"))
            local rank = pseudorandom_element(HEX_SSCG_RANKS, pseudoseed(mod.prefix .. "_sscg_rank"))

            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.1,
                func = function()
                    local new_card = SMODS.create_card({
                        set = "Base",
                        suit = suit,
                        rank = rank,
                        enhancement = "m_" .. mod.prefix .. "_diamond",
                        area = G.deck,
                    })

                    new_card:add_to_deck()
                    G.deck:emplace(new_card)

                    if G.playing_cards then
                        local already_present = false
                        for _, c in ipairs(G.playing_cards) do
                            if c == new_card then already_present = true; break end
                        end
                        if not already_present then
                            table.insert(G.playing_cards, new_card)
                        end
                    end

                    card_eval_status_text(new_card, "extra", nil, nil, nil, {
                        message = "SSCG!",
                        colour = G.C.BLUE,
                    })

                    return true
                end
            }))
        end
    end,
}



-- TREE(3): gives ^^100 Mult via the engine's own native ee_mult key
-- (current Mult tetrated to height 100, same self-referential operator
-- Hypergeometric's e_mult and Goodstein Sequence's ee_mult use
-- elsewhere -- no live-read needed here since it's just "current Mult
-- ^^ 100", the exact thing ee_mult already does).
--
-- Chips is different: reads G.GAME.hex_live_chips (the mirror the
-- mod_chips hook in main.lua maintains for Zeta Function above) --
-- the running Chips right before this card's own position, including
-- every Joker to its left -- takes chips:slog(big(10)) (super-log base
-- 10), clamps the result to a minimum of 1, then returns
-- result/chips as Xchip_mod so the running Chips gets REPLACED with
-- the super-log result, same "f(x)/x as Xchip_mod" trick Zeta Function
-- uses.
SMODS.Joker{
    key = "tree_3",

    loc_txt = {
        name = "TREE(3)",
        text = {
            "Gives {X:mult,C:white}^^100{} Mult, but",
            "takes the {C:attention}super-logarithm{}",
            "base 10 of Chips",
            "{C:inactive}(min chips of 1){}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot, same as other undrawn Transcendental+ jokers
    rarity = "hex_transcendental",
    in_pool = function(self)
        return false -- hidden/unlock-only rarity, like Cantor/Jokeo/Einstein/Exponential Factorial above
    end,

    cost = 100000,
    unlocked = true,
    discovered = true,
    blueprint_compat = false, -- reads the live running Chips directly for the slog half; a Blueprint copy would read from ITS OWN position in the row, a different snapshot, so it's excluded below
    eternal_compat = true,

    config = {
        extra = {
            e_amount = big(100), -- the ^^100 Mult height
        }
    },

    calculate = function(self, card, context)
        if context.joker_main and not context.blueprint then
            local chips = (G.GAME and G.GAME.hex_live_chips) or big(1)
            if chips:lt(big(1)) then chips = big(1) end

            local slog_chips = chips:slog(big(10))
            if slog_chips:lt(big(1)) then slog_chips = big(1) end

            hex_arm_chip_override(slog_chips)

            return {
                ee_mult = card.ability.extra.e_amount,
                chips = big(0), -- no-op addition; the real override happens via hex_arm_chip_override above
                message = "=" .. tostring(slog_chips) .. " Chips",
                colour = G.C.MULT,
            }
        end
    end,
}






SMODS.Joker{
    key = "goodstein_sequence",

    loc_txt = {
        name = "Goodstein Sequence",
        text = {
            "Raises {C:mult}Mult{} and {C:chips}Chips{}",
            "to the power of {C:transcendental}^^#1#{}",
            "increases by {C:attention}1{}",
            "at the end of every Blind",
        }
    },

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot, same as other undrawn Mythic+/Transcendental jokers

    rarity = "hex_transcendental",
    in_pool = function(self) return false end, -- hidden/unlock-only, matching Endless Abyss above
    cost = 30300303,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    -- ee_mult/ee_chips is this file's own "^^" (tetration) field pair --
    -- same arrow(2, n) notation TON 618's own "^^^" pentation uses one
    -- level up, and the same e_/ee_/eee_ naming Final Form Jimbo stacks
    -- all three of at once. n starts at 1 (Mult^^1 = Mult, so the first
    -- Blind is a no-op) and grows by exactly 1 permanently every Blind
    -- from there.
    config = {
        extra = {
            ee_mult_gain = big(1),
            last_round = nil,
            last_round_blueprint = {},
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.ee_mult_gain } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                ee_mult = card.ability.extra.ee_mult_gain,
                ee_chips = card.ability.extra.ee_mult_gain,
            }
        end

        -- Grows n by 1 exactly once per Blind. Same natural/Blueprint
        -- dual-stamp dedup Schwarzschild Radius uses elsewhere in this
        -- file -- Blueprint copies share this card's own ability.extra
        -- table, so a single stamp would have the natural firing and the
        -- Blueprint-copied firing block each other.
        if not context.end_of_round then return end

        if context.blueprint then
            if type(card.ability.extra.last_round_blueprint) ~= "table" then
                card.ability.extra.last_round_blueprint = {}
            end

            local bp_card = context.blueprint_card
            local bp_key = bp_card and (bp_card.sort_id or bp_card) or "unknown"

            if card.ability.extra.last_round_blueprint[bp_key] ~= G.GAME.round then
                card.ability.extra.last_round_blueprint[bp_key] = G.GAME.round
                card.ability.extra.ee_mult_gain = card.ability.extra.ee_mult_gain:add(big(1))

                return {
                    message = localize("k_upgrade_ex"),
                    colour = G.C.TRANSCENDENTAL,
                }
            end
        else
            if card.ability.extra.last_round ~= G.GAME.round then
                card.ability.extra.last_round = G.GAME.round
                card.ability.extra.ee_mult_gain = card.ability.extra.ee_mult_gain:add(big(1))

                return {
                    message = localize("k_upgrade_ex"),
                    colour = G.C.TRANSCENDENTAL,
                }
            end
        end
    end,
}



-- Creates `count` random Negative cards from a given center pool,
-- staggered so their materialize animations don't all overlap -- same
-- staggered create+force-Negative shape Virgo Cluster/Big Bang use
-- elsewhere in this file. No consumable-slot-limit check, matching
-- Virgo Cluster's own precedent.
-- Self-contained pool builder (doesn't depend on consumables.lua's own
-- hex_get_nebula_centers/hex_get_galaxy_centers/hex_get_star_centers,
-- which turned out to be `local` to that file and therefore invisible
-- from jokers.lua) -- scans G.P_CENTERS directly for the same lowercase
-- `set` keys those consumables are registered under elsewhere in this
-- mod (e.g. SMODS.Consumable{ set = "galaxy", ... }).
local function hex_cpt_symmetry_get_centers(set_key)
    local out = {}
    for _, center in pairs(G.P_CENTERS) do
        if center.set == set_key then
            out[#out + 1] = center
        end
    end
    return out
end

local function hex_cpt_symmetry_summon_from_pool(centers, count)
    if #centers == 0 then return end

    for i = 1, count do
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.15 * i,
            func = function()
                local chosen = centers[math.random(#centers)]

                local new_card = SMODS.create_card({
                    key = chosen.key,
                    area = G.consumeables
                })

                new_card:set_edition({ negative = true }, true)

                G.consumeables:emplace(new_card)

                return true
            end
        }))
    end
end

local function hex_cpt_symmetry_summon_all()
    hex_cpt_symmetry_summon_from_pool(hex_cpt_symmetry_get_centers("nebula"), 1)
    hex_cpt_symmetry_summon_from_pool(hex_cpt_symmetry_get_centers("galaxy"), 2)
    hex_cpt_symmetry_summon_from_pool(hex_cpt_symmetry_get_centers("star"), 5)
end

SMODS.Joker{
    key = "cpt_symmetry",

    loc_txt = {
        name = "CPT Symmetry",
        text = {
            "Creates {C:attention}1{} {C:dark_edition}Negative{}",
            "{C:nebula}Nebula{} card,",
            "{C:attention}2{} {C:dark_edition}Negative{} {C:galaxy}Galaxy{} cards,",
            "and {C:attention}5{} {C:dark_edition}Negative{} {C:star}Star{} cards",
            "at the end of every round",
        }
    },

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot, same as other undrawn Mythic+/Transcendental jokers

    rarity = "hex_transcendental",
    in_pool = function(self) return false end, -- hidden/unlock-only, matching Goodstein Sequence/Endless Abyss above
    cost = 10203040,
    unlocked = true,
    discovered =true,
    blueprint_compat = true,
    eternal_compat = true,

    config = {
        extra = {
            last_round = nil,
            last_round_blueprint = {},
        }
    },

    calculate = function(self, card, context)
        if not context.end_of_round then return end

        -- Same natural/Blueprint dual-stamp dedup Schwarzschild
        -- Radius/Goodstein Sequence use elsewhere in this file.
        if context.blueprint then
            if type(card.ability.extra.last_round_blueprint) ~= "table" then
                card.ability.extra.last_round_blueprint = {}
            end

            local bp_card = context.blueprint_card
            local bp_key = bp_card and (bp_card.sort_id or bp_card) or "unknown"

            if card.ability.extra.last_round_blueprint[bp_key] ~= G.GAME.round then
                card.ability.extra.last_round_blueprint[bp_key] = G.GAME.round
                hex_cpt_symmetry_summon_all()

                return {
                    message = "+8 Negative",
                    colour = G.C.TRANSCENDENTAL,
                }
            end
        else
            if card.ability.extra.last_round ~= G.GAME.round then
                card.ability.extra.last_round = G.GAME.round
                hex_cpt_symmetry_summon_all()

                return {
                    message = "+8 Negative",
                    colour = G.C.TRANSCENDENTAL,
                }
            end
        end
    end,
}












SMODS.Joker{
    key = "final_form_jimbo",

    loc_txt = {
        name = "Final Form Jimbo",
        text = {
            "Gives {C:mult}+4{}, {X:mult,C:white}X4{}, {C:mult}^4{}, {C:mult}^^4{},",
            "and {C:mult}^^^4{} Mult",
        }
    },

    atlas = "HexJokers",
    pos = { x = 3, y = 8 }, -- placeholder art slot
    soul_pos = { x = 7, y = 9 },

    rarity = "hex_divine",
    in_pool = function(self)
        return false
    end,    
    cost = big(2e100),
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,


    calculate = function(self, card, context)
        if context.joker_main then
            return {
                mult = 4,
                Xmult = 4,
                e_mult = 4,
                ee_mult = 4,
                eee_mult = 4,
            }
        end
    end,
}



SMODS.Joker{
    key = "aleph_omega",

    loc_txt = {
        name = "Aleph Omega",
        text = {
            "Gains {X:chips,C:white}^^^#2#{} Chips and",
            "{X:mult,C:white}^^^#2#{} Mult for every",
            "{C:purple}Hex point{} owned",
            "{C:inactive}(Currently {}{X:chips,C:white}^^^#1#{}{C:inactive} Chips,{}",
            "{C:inactive}{}{X:mult,C:white}^^^#1#{}{C:inactive} Mult){}",
        },
    },

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot

    rarity = "hex_divine",
    in_pool = function(self)
        return false
    end,    
    cost = big(2e100),
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,

    config = {
        extra = {
            eee_mult_gain = big(0.1),
        }
    },

    -- Shows the current live Xchips/Xmult (1 + hex_points x 0.1) in the
    -- card's own text, computed the same way calculate() below applies
    -- it. Guards G.GAME being nil since loc_vars can also be called
    -- from the collection screen outside of a run.
    loc_vars = function(self, info_queue, card)
        local hex_points = (G.GAME and G.GAME.hex_points) or big(0)
        local bonus = hex_points:mul(big(card.ability.extra.eee_mult_gain))
        local xstat = big(1):add(bonus)

        return { vars = { xstat, card.ability.extra.eee_mult_gain } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            local hex_points = G.GAME.hex_points or big(0)
            local bonus = hex_points:mul(big(card.ability.extra.eee_mult_gain))
            local xstat = big(1):add(bonus)

            return {
                eee_chips = xstat,
                eee_mult = xstat,
            }
        end
    end,
}



SMODS.Joker{
    key = "oracle",

    loc_txt = {
        name = "Oracle",
        text = {
            "{C:ritual}Rituals{} can be",
            "{C:attention}summoned more than once{}",
        }
    },

    rarity = "hex_divine",
    in_pool = function(self) return false end, -- hidden/unlock-only rarity, like the other Divine jokers

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot shared with the other undrawn Divine/Transcendental jokers

    cost = 2e100,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
}

SMODS.Joker{
    key = "phanes",

    loc_txt = {
        name = "Phanes",
        text = {
            "The {C:ritual}Life{} ritual can",
            "also bring {C:transcendental}Transcendental{}",
            "Jokers to life",
        }
    },

    rarity = "hex_divine",
    in_pool = function(self) return false end, -- hidden/unlock-only rarity, like the other Divine jokers

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot shared with the other undrawn Divine/Transcendental jokers

    cost = 2e100,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
}



SMODS.Joker{
    key = "rayo_number",

    loc_txt = {
        name = "Rayo's Number",
        text = {
            "Gives {C:mult}^^^^1.1{} and {C:chips}^^^^1.1{}",
        }
    },

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot

    rarity = "hex_divine",
    in_pool = function(self)
        return false
    end,    
    cost = big(2e100),
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,


    calculate = function(self, card, context)
        if context.joker_main then
            
            return {
                hyper_mult = { 4, 1.1 },
                hyper_chips = { 4, 1.1 },
            }
        end
    end,
}



SMODS.Joker{
    key = "inaccessible",

    loc_txt = {
        name = "Inaccessible",
        text = {
            "Permanently unlocks a button to",
            "summon {C:absolute}Absolute{} for",
            "{C:absolute}1.0e21{} Hex points",
            "{C:attention}Destroys all other Jokers{}",
            "when summoned",
        }
    },

    rarity = "hex_divine",
    in_pool = function(self) return false end, -- hidden/unlock-only rarity, like the other Divine jokers

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot shared with the other undrawn Divine/Transcendental jokers

    cost = big(2e308),
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,

    -- Flips the flag that permanently unlocks the "Summon Absolute" button
    -- for the rest of this run (see the Game:update hook and start_run
    -- reset near the button-creation code further down the file).
    add_to_deck = function(self, card, from_debuff)
        G.GAME.hex_inaccessible_unlocked = true
    end,
}

SMODS.Joker{
    key = "absolute",
    loc_txt = {
        name = "Absolute",
        text = {
            "Increases {C:chips}chips{}-{C:mult}mult{} hyperoperator",
            "by 1 for every hex point currently ownded + 1"
        }   
    },
    rarity = "hex_absolute",
    in_pool = function(self) return false end, 

    atlas = "HexJokers",
    pos = { x = 5, y = 0 },
    cost = 0,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,  
}







-- ============================================================
-- Joker selection system (click to select, for Curse/Vessel below)
-- Vanilla never highlights Jokers -- this raises G.jokers' own
-- highlighted_limit to 1 (permanently; harmless when nothing uses it)
-- and manages click-to-toggle ourselves, the same
-- CardArea:add_to_highlighted/remove_from_highlighted API G.hand's own
-- highlighting already goes through elsewhere in the game.
-- ============================================================

local old_start_run_joker_select = Game.start_run

function Game:start_run(...)
    local ret = old_start_run_joker_select(self, ...)

    if G.jokers and G.jokers.config then
        G.jokers.config.highlighted_limit = 1
    end

    return ret
end

local hex_joker_select_old_click = Card.click

function Card:click()
    if self.area == G.jokers and self.ability and self.ability.set == "Joker" then
        if self.highlighted then
            G.jokers:remove_from_highlighted(self)
        else
            -- Enforce single-selection: drop anything else currently
            -- highlighted before adding this one.
            if G.jokers.highlighted then
                for i = #G.jokers.highlighted, 1, -1 do
                    if G.jokers.highlighted[i] ~= self then
                        G.jokers:remove_from_highlighted(G.jokers.highlighted[i])
                    end
                end
            end
            G.jokers:add_to_highlighted(self)
        end

        return
    end

    hex_joker_select_old_click(self)
end







-- Helper: eligible Jokers for Huge-LQG's random hex -- same exclusions
-- G.FUNCS.hex_sacrifice itself enforces (Eternal Jokers and Absolute can
-- never be hexed), reusing hex_apply_immortal_sticker's own key so this
-- also can never target anything carrying the Immortal sticker.
function hex_huge_lqg_eligible_jokers()
    local out = {}
    if not (G.jokers and G.jokers.cards) then return out end

    for _, j in ipairs(G.jokers.cards) do
        local eternal = j.ability and j.ability.eternal
        local immortal = j.ability and j.ability[HEX_IMMORTAL_STICKER_KEY]
        local is_absolute = j.config and j.config.center
            and j.config.center.key == ("j_" .. mod.prefix .. "_absolute")

        if not eternal and not immortal and not is_absolute then
            out[#out + 1] = j
        end
    end

    return out
end