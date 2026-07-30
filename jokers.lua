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
    eternal_compat = true,

    config = {
        extra = {
            dollars = 6,
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
            card.ability.extra.dollars = math.max(0, card.ability.extra.dollars - 1)

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
            "Gains {C:mult}+2{} Mult",
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
            mult = 0,
            mult_gain = 2,
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
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
            card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.mult_gain

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
            "Gives {X:chips,C:white}X3{} Chips when",
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

    calculate = function(self, card, context)
        if context.joker_main and context.scoring_name == "High Card" then
            return {
                x_chips = 3,
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
            "Gives {X:mult,C:white}X6.66{} Mult if",
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
                    Xmult = 6.66,
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
            "Gives {C:chips}+69{} Chips if",
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

    calculate = function(self, card, context)
        if context.joker_main and not next(context.poker_hands["Straight"]) then
            return {
                chips = 69,
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
            "Gives {C:mult}+10{} Mult if",
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

    calculate = function(self, card, context)
        if context.joker_main and not context.scoring_name == "Pair" then
            return {
                mult = 10,
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
            "Gives {C:mult}+10{} Mult",
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

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                mult = 10,
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

SMODS.Joker{
    key = "hatsune_miku",

    loc_txt = {
        name = "Hatsune Miku",
        text = {
            "Gains {C:chips}+15{} Chips for",
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
            chips = 0,
            chips_gain = 15,
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
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
                card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chips_gain

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
    pos = { x = 0, y = 1 },
    in_pool = hex_in_pool,
    rarity = 1,
    cost = 4,
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
            "Gives {C:money}+$5{} when",
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

    calculate = function(self, card, context)
        if context.skip_blind and not context.blueprint then
            return {
                dollars = 5,
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
            "Gives {C:chips}+50{} Chips for every",
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

    calculate = function(self, card, context)
        if context.joker_main then
            local used = (G.consumeables and #G.consumeables.cards) or 0

            if used > 0 then
                return {
                    chips = used * 50,
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
    blueprint_compat = true,
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
            "Gives {C:chips}X4{} Chips if the",
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
                x_chips = 4,
                colour = G.C.CHIPS,
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
            "Gains {C:chips}+35{} Chips at the",
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
            chips = 0,
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
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
                card.ability.extra.chips = card.ability.extra.chips + 35

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
                    j.ability.extra.chips = 0
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

G.FUNCS.discard_cards_from_highlighted = function(e)
    G.GAME.hex_last_discard_count = (G.hand and G.hand.highlighted and #G.hand.highlighted) or 0
    G.GAME.hex_discard_action_id = (G.GAME.hex_discard_action_id or 0) + 1

    return hex_old_discard_from_highlighted(e)
end


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
    blueprint_compat = true,
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
            "Gains {X:mult,C:white}X0.1{} Mult and",
            "{X:chips,C:white}X0.1{} Chips when",
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
        return { vars = { card.ability.extra.Xmult, card.ability.extra.xchips } }
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
    eternal_compat = true,

    config = {
        extra = {
            xchips = 3,
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { math.max(0, card.ability.extra.xchips) } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                x_chips = math.max(0, card.ability.extra.xchips),
                colour = G.C.CHIPS,
            }
        end

        if context.reroll_shop and not context.blueprint then
            card.ability.extra.xchips = card.ability.extra.xchips - 0.25

            return {
                message = "-0.25",
                colour = G.C.CHIPS,
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
            "Gives {C:money}$3{} when you",
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
        }
    },

    calculate = function(self, card, context)
        if context.discard
        and not context.blueprint
        and (G.GAME.hex_last_discard_count or 0) == 1
        and card.ability.extra.last_discard_id ~= G.GAME.hex_discard_action_id then

            card.ability.extra.last_discard_id = G.GAME.hex_discard_action_id

            return {
                dollars = 3,
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
            "Gives {C:mult}+6{} Mult for every",
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
            mult_per_card = 6,
        }
    },

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
                    mult = unscored * card.ability.extra.mult_per_card,
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
            "Gains {C:mult}+7{} Mult for every",
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
            mult = 0,
            hands_this_round = 0,
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
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
                card.ability.extra.mult = card.ability.extra.mult + 7
            else
                card.ability.extra.mult = 0
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
                chips = 10,
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
                    j.ability.extra.chips = (j.ability.extra.chips or 0) + 20
                    j.ability.extra.mult = (j.ability.extra.mult or 0) + 2
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
            ""
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
            chips = 0,
            mult = 0,
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
    key = "musa_acuminata",

    loc_txt = {
        name = "Musa Acuminata",
        text = {
            "This Joker {C:purple}^2{}",
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

    -- Only appears after Cavendish breaks
    in_pool = function(self)
        return (hex_owns_showman() or #SMODS.find_card(self.key) == 0)
            and G.GAME and G.GAME.cavendish_broken
    end,

    calculate = function(self, card, context)

        if context.joker_main then
            return {
                e_mult = big(2),
                colour = G.C.PURPLE
            }

        end
    end
}

local old_start_dissolve = Card.start_dissolve

function Card.start_dissolve(self, ...)
    
    if self.config
    and self.config.center
    and self.config.center.key == "j_cavendish" then
        G.GAME.cavendish_broken = true
    end

    -- Immortal sticker: blocks this exact card from ever being
    -- dissolved/destroyed by anything -- selling, debuffs, other
    -- Jokers' destroy effects, the HEX sacrifice button, all of it --
    -- with a single deliberate exception. G.HEX_ABSOLUTE_SUMMONING is
    -- set true only for the brief moment G.FUNCS.summon_absolute spends
    -- destroying every currently-held Joker, and cleared immediately
    -- after, so that's the one window this block gets bypassed in.
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
            "Gains {X:mult,C:white}X0.25{} Mult after",
            "every {C:attention}Small{} and {C:attention}Big Blind{}",
            "Gains {X:chips,C:white}X0.5{} Chips after",
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
            xchips = big(1),
            xchips_gain = big(0.5),
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult, card.ability.extra.xchips } }
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
                card.ability.extra.xchips = card.ability.extra.xchips:add(card.ability.extra.xchips_gain)

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
    key = "the_seal_of_aces",

    loc_txt = {
        name = "The Seal of Aces",
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
            "Gives {C:chips}X3{} Chips,",
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

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                x_chips = 3,
                colour = G.C.CHIPS,
            }
        end
    end,
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

SMODS.Joker{
    key = "hypergrowth",

    loc_txt = {
        name = "Hypergrowth",
        text = {
            "Gives {C:purple}^1.01{} Mult and Chips",
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
                e_mult = 1.01,
                e_chips = 1.01,
            }
        end
    end,
}





SMODS.Joker{
    key = "bonus_joker",
    loc_txt = {
        name = "Bonus Joker",
        text = {
            "This Joker gains {X:mult,C:white}X0.25{} Mult",
            "every bonus card scored",
            "{C:inactive}(Currently {}{X:mult,C:white}X#1#{}{C:inactive} Mult)"
        }
    },
    config = { extra = { Xmult = big(1), Xmult_gain = big(0.25) } },
    atlas = "HexJokers",
    pos = { x = 1, y = 0 }, -- second frame in the atlas (sprite to the right)
    in_pool = hex_in_pool,
    rarity = 3,             -- 1 common, 2 uncommon, 3 rare, 4 legendary
    cost = 8,
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
        return { vars = { card.ability.extra.Xmult } }
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
        and context.card.config.center.rarity == 3 then

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

SMODS.Joker{
    key = "coupon",

    loc_txt = {
        name = "Coupon",
        text = {
            "Rerolls in the shop",
            "always cost {C:money}$1{}"
        }
    },

    rarity = "hex_mythic",
    in_pool = function(self) return false end, -- hidden/unlock-only rarity, like the other Mythic+ jokers

    atlas = "HexJokers",
    pos = { x = 5, y = 0 }, -- placeholder art slot, same as other undrawn Mythic+ jokers

    cost = 200,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
}


-- Juno: raises final Mult by tetration (^^), with the tetration height
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

    cost = 100000,
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

    cost = 1e100,
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

    cost = 1e100,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
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