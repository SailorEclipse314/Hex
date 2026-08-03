-- ============================================================
-- Hex -- Content
-- Every custom Atlas/Rarity registration, PokerHand, Enhancement,
-- Shader, Edition, Seal, Sticker, Voucher, and deck (Back) -- plus
-- the systems built purely to support them (deck-selection payouts,
-- the enhancement/seal pool exclusions, the seal-strip and voucher-
-- dedupe CardArea:emplace hooks, the negative-deck/create_card
-- patch, and the redeemed-vouchers Run Info tab paging) -- lives
-- here. Everything that is a Joker lives in jokers.lua instead, and
-- everything that is a Consumable lives in consumables.lua.
--
-- Loaded from main.lua via SMODS.load_file, so it runs AFTER
-- main.lua's own top-level code -- every shared helper this file
-- calls (big, hex_to_plain_number, hex_format_points,
-- hex_format_dollars, HEX_POLY_DEFAULT_HAND_LIMIT, the custom G.C
-- colour additions, etc.) is already a defined global by the time
-- this file's own top-level code runs.
--
-- The Celestial/Black Hole deck payouts, the voucher-pool-excluding
-- helper, and the voucher-dedupe CardArea:emplace hook used to sit
-- further down main.lua, physically after the Jokers -- they're
-- gathered up here instead, next to every other deck/voucher system,
-- since none of it is order-sensitive (it's all deferred function
-- bodies, never called until well after every mod file has loaded).
-- ============================================================

local mod = SMODS.current_mod

SMODS.Atlas{
    key = "HexJokers",
    path = "jokers.png",
    px = 71,
    py = 95,
}

SMODS.Atlas{
    key = "HexPlanets",
    path = "Planets.png",
    px = 71,
    py = 95,
}
SMODS.Atlas{
    key = "HexSpectrals",
    path = "Spectrals.png",
    px = 71,
    py = 95,
}

SMODS.Atlas{
    key = "HexEnhancers",
    path = "Enhancers.png",
    px = 71,
    py = 95,
}

SMODS.Atlas{
    key = "HexRitualsQuantums",
    path = "rituals_and_quantums.png",
    px = 71,
    py = 95,
}

SMODS.Atlas{
    key = "HexBoosters",
    path = "boosters.png",
    px = 71,
    py = 95,
}

SMODS.Atlas{
    key = "HexBlindChips",
    path = "BlindChips.png",
    px = 71,
    py = 95,
}

SMODS.Atlas{
    key = "HexStarsGalaxies",
    path = "Stars_and_Galaxies.png",
    px = 71,
    py = 95,
}

SMODS.Atlas{
    key = "HexTags",
    path = "tags.png",
    px = 34,
    py = 34,
}

SMODS.Atlas{
    key = "HexVouchers",
    path = "Vouchers.png",
    px = 71,
    py = 95,
}

SMODS.Atlas{
    key = "HexStickers",
    path = "stickers.png",
    px = 71,
    py = 95,
}

SMODS.Atlas{
    key = "HexNebulasBlackholes",
    path = "Nebulas_and_Blackholes.png",
    px = 71,
    py = 95,
}

SMODS.Atlas{
    key = "HexAstralsCosmics",
    path = "Astrals_and_Cosmics.png",
    px = 71,
    py = 95,
}


R_HEX_MYTHIC = SMODS.Rarity{
    key = "hex_mythic",
    loc_txt = {
        name = "Mythic"
    },
    default_weight = 0.0001,
    badge_colour = G.C.MYTHIC
}

R_HEX_TRANSCENDENTAL = SMODS.Rarity{
    key = "hex_transcendental",
    loc_txt = {
        name = "Transcendental"
    },
    default_weight = 0.00001, -- rarer than mythic (0.0001) — tune as you like
    badge_colour = G.C.TRANSCENDENTAL
}


R_HEX_DIVINE = SMODS.Rarity{
    key = "hex_divine",
    loc_txt = {
        name = "Divine"
    },
    default_weight = 0.000001, -- rarer than mythic (0.0001) — tune as you like
    badge_colour = G.C.DIVINE
}

R_HEX_ABSOLUTE = SMODS.Rarity{
    key = "hex_absolute",
    loc_txt = {
        name = "Absolute"
    },
    default_weight = 0.0000001, -- rarer than mythic (0.0001) — tune as you like
    badge_colour = G.C.ABSOLUTE
}





-- ============================================================
-- Custom Poker Hands: Three Pair / Flush Three Pair / Four Pair /
-- Flush Four Pair
--
-- Built on Steamodded's SMODS.PokerHandPart system. `parts._2` is
-- Steamodded's own list of "all groups of at least 2 cards sharing a
-- rank" (a Full House's own 3-of-a-kind group still counts as one of
-- these groups too -- the same generalized way vanilla's rewritten Two
-- Pair counts them, per Steamodded's own PR notes on the system), so
-- "N pairs of different ranks" is just "at least N groups in parts._2",
-- and the scoring cards are every card across all of those groups
-- merged together. Like vanilla Full House also registering as Three
-- of a Kind + Pair, these deliberately don't exclude each other or the
-- vanilla hands -- Four Pair also counts as Three Pair (and Two Pair),
-- and the Flush variants also count as their non-flush counterpart --
-- only the Flush variants additionally require every one of those
-- paired cards to share a suit.
-- ============================================================

-- Checks whether every card in `cards` shares the same suit, respecting
-- Smeared Joker via SMODS.smeared_check -- the same helper vanilla-style
-- Flush detection itself relies on for that. Only meaningful once the
-- caller has already confirmed `cards` is non-empty.
local function hex_cards_all_same_suit(cards)
    if not cards or #cards == 0 then return false end

    local target_suit = cards[1].base and cards[1].base.suit
    if not target_suit then return false end

    for _, c in ipairs(cards) do
        local matches = c.base and (
            c.base.suit == target_suit
            or (SMODS.smeared_check and SMODS.smeared_check(c, target_suit))
        )
        if not matches then return false end
    end

    return true
end

-- Merges every parts._2 group (each group is itself a list of same-rank
-- cards) into one flat, duplicate-free list of cards -- the same way
-- Steamodded's own Two Pair evaluate merges all of its pair groups
-- together instead of hard-capping at exactly two.
local hex_table_unpack = table.unpack or unpack

local function hex_merge_all_pair_groups(parts)
    return SMODS.merge_lists(parts._2)
end

SMODS.PokerHand{
    key = "three_pair",
    visible = false,
    mult = 20,
    chips = 200,
    l_mult = 5,
    l_chips = 50,

    loc_txt = {
        name = "Three Pair",
        description = {
            "3 Pairs of",
            "different ranks",
        }
    },

    example = {
        { 'S_9', true },
        { 'H_9', true },
        { 'C_5', true },
        { 'D_5', true },
        { 'S_3', true },
        { 'H_3', true },
    },

    evaluate = function(parts, hand)
        if #parts._2 >= 3 then
            return { hex_merge_all_pair_groups(parts) }
        end
        return {}
    end,
}

SMODS.PokerHand{
    key = "flush_three_pair",
    mult = 30,
    chips = 300,
    l_mult = 10,
    l_chips = 100,
    visible = false,

    loc_txt = {
        name = "Flush Three Pair",
        description = {
            "3 Pairs of different",
            "ranks, all one suit",
        }
    },

    example = {
        { 'S_9', true },
        { 'S_9', true },
        { 'S_5', true },
        { 'S_5', true },
        { 'S_3', true },
        { 'S_3', true },
    },

    evaluate = function(parts, hand)
        if #parts._2 >= 3 then
            local cards = hex_merge_all_pair_groups(parts)
            if hex_cards_all_same_suit(cards) then
                return { cards }
            end
        end
        return {}
    end,
}

SMODS.PokerHand{
    key = "four_pair",
    mult = 40,
    chips = 400,
    l_mult = 15,
    l_chips = 200,
    visible = false,

    loc_txt = {
        name = "Four Pair",
        description = {
            "4 Pairs of",
            "different ranks",
        }
    },

    example = {
        { 'S_9', true },
        { 'H_9', true },
        { 'C_5', true },
        { 'D_5', true },
        { 'S_3', true },
        { 'H_3', true },
        { 'C_2', true },
        { 'D_2', true },
    },

    evaluate = function(parts, hand)
        if #parts._2 >= 4 then
            return { hex_merge_all_pair_groups(parts) }
        end
        return {}
    end,
}

SMODS.PokerHand{
    key = "flush_four_pair",
    mult = 50,
    chips = 500,
    l_mult = 35,
    l_chips = 600,
    visible = false,

    loc_txt = {
        name = "Flush Four Pair",
        description = {
            "4 Pairs of different",
            "ranks, all one suit",
        }
    },

    example = {
        { 'S_9', true },
        { 'S_9', true },
        { 'S_5', true },
        { 'S_5', true },
        { 'S_3', true },
        { 'S_3', true },
        { 'S_2', true },
        { 'S_2', true },
    },

    evaluate = function(parts, hand)
        if #parts._2 >= 4 then
            local cards = hex_merge_all_pair_groups(parts)
            if hex_cards_all_same_suit(cards) then
                return { cards }
            end
        end
        return {}
    end,
}

-- ============================================================
-- Custom Poker Hands: Dual Three of a Kind / Flush Dual Three of a
-- Kind / Grand House / Flush Grand House
--
-- Same generalized-groups approach as Three/Four Pair above, just
-- built on parts._3 (groups of at least 3 cards sharing a rank) and
-- parts._4 (groups of at least 4 cards sharing a rank) instead of
-- parts._2.
-- ============================================================

-- Merges every parts._3 group into one flat list, the same way
-- hex_merge_all_pair_groups does for parts._2 above.
local function hex_merge_all_trip_groups(parts)
    return SMODS.merge_lists(parts._3)
end

SMODS.PokerHand{
    key = "dual_three_of_a_kind",
    visible = false,
    mult = 20,
    chips = 400,
    l_mult = 8,
    l_chips = 80,

    loc_txt = {
        name = "Dual Three of a Kind",
        description = {
            "2 Three of a Kinds",
            "of different ranks",
        }
    },

    example = {
        { 'S_9', true },
        { 'H_9', true },
        { 'C_9', true },
        { 'S_5', true },
        { 'H_5', true },
        { 'C_5', true },
    },

    evaluate = function(parts, hand)
        if #parts._3 >= 2 then
            return { hex_merge_all_trip_groups(parts) }
        end
        return {}
    end,
}

SMODS.PokerHand{
    key = "flush_dual_three_of_a_kind",
    visible = false,
    mult = 30,
    chips = 700,
    l_mult = 12,
    l_chips = 140,

    loc_txt = {
        name = "Flush Dual Three of a Kind",
        description = {
            "2 Three of a Kinds of",
            "different ranks, all one suit",
        }
    },

    example = {
        { 'S_9', true },
        { 'S_9', true },
        { 'S_9', true },
        { 'S_5', true },
        { 'S_5', true },
        { 'S_5', true },
    },

    evaluate = function(parts, hand)
        if #parts._3 >= 2 then
            local cards = hex_merge_all_trip_groups(parts)
            if hex_cards_all_same_suit(cards) then
                return { cards }
            end
        end
        return {}
    end,
}

-- Grand House: a Four of a Kind plus a separate Three of a Kind (of a
-- different rank). Note that a four-of-a-kind group also naturally
-- satisfies parts._3's own "at least 3 cards sharing a rank" test, so
-- `#parts._3 >= 2` alone isn't enough to confirm a *separate* trip
-- exists -- we explicitly find a parts._3 group whose rank differs from
-- every parts._4 group's rank before accepting the hand.
SMODS.PokerHand{
    key = "grand_house",
    visible = false,
    mult = 60,
    chips = 1000,
    l_mult = 25,
    l_chips = 250,

    loc_txt = {
        name = "Grand House",
        description = {
            "A Four of a Kind and",
            "a Three of a Kind",
        }
    },

    example = {
        { 'S_9', true },
        { 'H_9', true },
        { 'C_9', true },
        { 'D_9', true },
        { 'S_5', true },
        { 'H_5', true },
        { 'C_5', true },
    },

    evaluate = function(parts, hand)
        if #parts._4 >= 1 and #parts._3 >= 2 then
            local four_cards = SMODS.merge_lists(parts._4)

            local four_ranks = {}
            for _, group in ipairs(parts._4) do
                local rank = group[1] and group[1].base and group[1].base.value
                if rank then four_ranks[rank] = true end
            end

            local extra_group = nil
            for _, group in ipairs(parts._3) do
                local rank = group[1] and group[1].base and group[1].base.value
                if rank and not four_ranks[rank] then
                    extra_group = group
                    break
                end
            end

            if extra_group then
                local cards = {}
                for _, c in ipairs(four_cards) do cards[#cards + 1] = c end
                for _, c in ipairs(extra_group) do cards[#cards + 1] = c end
                return { cards }
            end
        end
        return {}
    end,
}

SMODS.PokerHand{
    key = "flush_grand_house",
    visible = false,
    mult = 120,
    chips = 4000,
    l_mult = 50,
    l_chips = 1000,

    loc_txt = {
        name = "Flush Grand House",
        description = {
            "A Four of a Kind and a",
            "Three of a Kind, all one suit",
        }
    },

    example = {
        { 'S_9', true },
        { 'S_9', true },
        { 'S_9', true },
        { 'S_9', true },
        { 'S_5', true },
        { 'S_5', true },
        { 'S_5', true },
    },

    evaluate = function(parts, hand)
        if #parts._4 >= 1 and #parts._3 >= 2 then
            local four_cards = SMODS.merge_lists(parts._4)

            local four_ranks = {}
            for _, group in ipairs(parts._4) do
                local rank = group[1] and group[1].base and group[1].base.value
                if rank then four_ranks[rank] = true end
            end

            local extra_group = nil
            for _, group in ipairs(parts._3) do
                local rank = group[1] and group[1].base and group[1].base.value
                if rank and not four_ranks[rank] then
                    extra_group = group
                    break
                end
            end

            if extra_group then
                local cards = {}
                for _, c in ipairs(four_cards) do cards[#cards + 1] = c end
                for _, c in ipairs(extra_group) do cards[#cards + 1] = c end

                if hex_cards_all_same_suit(cards) then
                    return { cards }
                end
            end
        end
        return {}
    end,
}




-- ============================================================
-- Custom Poker Hands: N of a Kind / Flush N of a Kind
--
-- evaluate() ONLY identifies cards here -- exactly like every other
-- hand in this file -- and never mutates G.GAME.hands. That's the
-- critical fix: evaluate() runs continuously while cards are merely
-- highlighted (that's what builds the live score preview in
-- cardarea.lua's parse_highlighted), not just when a hand is actually
-- played. Mutating shared hand state from inside evaluate() corrupted
-- the UI's already-bound preview objects mid-frame, which is what was
-- crashing parse_highlighted -- it had nothing to do with big()/plain
-- number typing.
--
-- The dynamic "starts at n*X chips / n*Y mult" scaling is instead
-- applied exactly once, only at real play-time, via the
-- G.HEX_REAL_SCORING flag. NOTE: this used to be armed/disarmed by
-- wrapping G.FUNCS.evaluate_play (true right before calling the
-- original, false right after) -- but that function only *kicks off*
-- the Play Hand sequence; vanilla defers the actual hand evaluation
-- (the very call to evaluate() that matters here) onto G.E_MANAGER as
-- a delayed event, which doesn't run until a later frame. By the time
-- it did, the wrapper had already flipped the flag back to false, so
-- hex_apply_dynamic_n_hand below never fired and the hand's chips/mult
-- silently stayed pinned at their static base values -- this was the
-- actual bug causing N of a Kind / Flush N of a Kind to never scale.
-- Instead, the flag is now derived every frame from G.STATE (see the
-- Game:update poll further down the file) -- G.STATE only leaves
-- G.STATES.SELECTING_HAND once a hand is actually being played/scored
-- (Orion's own poll already relies on that same distinction), so this
-- stays accurate for the entire scoring pass, deferred events included,
-- while still reading false the whole time cards are merely highlighted
-- for preview.
-- ============================================================

G.HEX_REAL_SCORING = false




-- N of a Kind / Flush N of a Kind recompute their own base chips/mult
-- every play (see hex_apply_dynamic_n_hand below), which silently
-- discarded any permanent boost from Nebula/Black Hole cards, Planet
-- stat cards, Polaris, or Eclipse -- all of those write straight to
-- G.GAME.hands[key].chips/.mult, and the next time the hand was
-- played, hex_apply_dynamic_n_hand overwrote it right back to n*base
-- as if the boost never happened. Every mutation site now routes
-- through hex_set_hand_stat, which for these two hands specifically
-- records the ratio as a persistent multiplier that gets folded back
-- in on every recompute.
local HEX_DYNAMIC_N_HAND_KEYS = {
    [mod.prefix .. "_n_of_a_kind"] = true,
    [mod.prefix .. "_flush_n"] = true,
}

function hex_set_hand_stat(hand_key, stat, new_value)
    local hand = G.GAME and G.GAME.hands and G.GAME.hands[hand_key]
    if not hand then return end

    local old_value = hand[stat]
    hand[stat] = new_value

    if HEX_DYNAMIC_N_HAND_KEYS[hand_key] then
        local old_big = to_big(old_value or 0)
        if old_big:gt(big(0)) then
            local ratio = to_big(new_value) / old_big
            G.GAME.hex_dynamic_hand_mult = G.GAME.hex_dynamic_hand_mult or {}
            G.GAME.hex_dynamic_hand_mult[hand_key] = G.GAME.hex_dynamic_hand_mult[hand_key] or {}
            G.GAME.hex_dynamic_hand_mult[hand_key][stat] =
                (G.GAME.hex_dynamic_hand_mult[hand_key][stat] or big(1)) * ratio
        end
    end
end






local function hex_biggest_rank_group(hand)
    local groups = {}

    for _, c in ipairs(hand) do
        local rank = c.base and c.base.value
        if rank then
            groups[rank] = groups[rank] or {}
            groups[rank][#groups[rank] + 1] = c
        end
    end

    local best = nil
    for _, cards in pairs(groups) do
        if not best or #cards > #best then
            best = cards
        end
    end

    return best
end

-- Only ever called while G.HEX_REAL_SCORING is true (see the
-- evaluate_play wrap below). Plain Lua arithmetic, matching every other
-- hand's static chips/mult fields -- G.GAME.hands[key].chips/.mult are
-- vanilla fields read by vanilla, Amulet-unaware UI code, so this stays
-- deliberately unwrapped by big().
local function hex_apply_dynamic_n_hand(key, n, chips_per_n, mult_per_n)
    local hand_info = G.GAME.hands[key]
    if not hand_info then return end

    local level = hand_info.level or 1
    local extra_levels = math.max(0, level - 1)

    local base_chips = n * chips_per_n + extra_levels * (hand_info.l_chips or 0)
    local base_mult = n * mult_per_n + extra_levels * (hand_info.l_mult or 0)

    local bonus = (G.GAME.hex_dynamic_hand_mult and G.GAME.hex_dynamic_hand_mult[key]) or {}

    hand_info.chips = to_big(base_chips):mul(bonus.chips or big(1))
    hand_info.mult = to_big(base_mult):mul(bonus.mult or big(1))
end


SMODS.PokerHand{
    key = "n_of_a_kind",
    visible = false,
    mult = 18,
    chips = 180,
    l_mult = 2,
    l_chips = 20,

    loc_txt = {
        name = "N of a Kind",
        description = {
            "6 or more cards of",
            "the same rank",
        }
    },

    example = {
        { 'S_9', true },
        { 'H_9', true },
        { 'C_9', true },
        { 'D_9', true },
        { 'S_9', true },
        { 'H_9', true },
    },

    -- N of a Kind
    evaluate = function(parts, hand)
        local group = hex_biggest_rank_group(hand)

        if group and #group >= 6 then
            hex_apply_dynamic_n_hand(mod.prefix .. "_n_of_a_kind", #group, 30, 3)
            return { group }
        end

        return {}
    end,
    -- Dynamic display name ("6 of a Kind", "7 of a Kind", ...). This is
    -- Steamodded's own documented mechanism for this exact purpose (see
    -- the SMODS.PokerHand wiki page's `modify_display_text` entry) --
    -- rather than the display text being poked from inside evaluate(),
    -- the engine calls this itself at the moment it actually needs the
    -- name, and looks up whatever key is returned inside
    -- misc.poker_hands. A fresh, count-specific key is registered (and
    -- returned) each time rather than overwriting this hand's own base
    -- "n_of_a_kind" entry, so the un-numbered name in the hands menu/
    -- collection is left alone.
    modify_display_text = function(self, cards, scoring_hand)
        local group = hex_biggest_rank_group(scoring_hand or cards)

        if group and #group >= 6 then
            local key = mod.prefix .. "_n_of_a_kind_" .. tostring(#group)
            if G.localization and G.localization.misc and G.localization.misc.poker_hands then
                G.localization.misc.poker_hands[key] = tostring(#group) .. " of a Kind"
            end
            return key
        end
    end,
}

SMODS.PokerHand{
    key = "flush_n",
    visible = false,
    mult = 30,
    chips = 240,
    l_mult = 3,
    l_chips = 25,

    loc_txt = {
        name = "Flush N",
        description = {
            "6 or more cards of the",
            "same rank, all one suit",
        }
    },

    example = {
        { 'S_9', true },
        { 'S_9', true },
        { 'S_9', true },
        { 'S_9', true },
        { 'S_9', true },
        { 'S_9', true },
    },

    -- Flush N
    evaluate = function(parts, hand)
        local group = hex_biggest_rank_group(hand)

        if group and #group >= 6 and hex_cards_all_same_suit(group) then
            hex_apply_dynamic_n_hand(mod.prefix .. "_flush_n", #group, 40, 5)
            return { group }
        end

        return {}
    end,

    -- Same dynamic-name treatment as N of a Kind's own modify_display_text
    -- above, just for the Flush key ("Flush", "Flush 7")
    modify_display_text = function(self, cards, scoring_hand)
        local group = hex_biggest_rank_group(scoring_hand or cards)

        if group and #group >= 6 and hex_cards_all_same_suit(group) then
            local key = mod.prefix .. "_flush_n" .. tostring(#group)
            if G.localization and G.localization.misc and G.localization.misc.poker_hands then
                G.localization.misc.poker_hands[key] = "Flush " .. tostring(#group) 
            end
            return key
        end
    end,
}

-- NOTE: this used to wrap G.FUNCS.evaluate_play here to arm/disarm
-- G.HEX_REAL_SCORING around the "Play Hand" button press. That never
-- actually worked -- see the comment on G.HEX_REAL_SCORING's own
-- declaration above for why -- so it's been removed entirely in favor
-- of deriving the flag from G.STATE every frame instead (see the
-- Game:update poll further down the file, right next to the other
-- "while owned/used, do X" checks like Fractal's and Procyon's).



SMODS.PokerHand{
    key = "none",
    visible = true, -- shows up in the Poker Hands / leveling screen, unlike your merged-variant hands (Three Pair etc.) which stay hidden
    mult = 0,
    chips = 0,
    l_mult = 1,
    l_chips = 1,

    loc_txt = {
        name = "None",
        description = {
            "Play {C:attention}0{} cards",
        }
    },

    example = {}, -- no example cards, since this hand is 0 cards by definition

    -- Fires when the played hand is genuinely empty. Every other
    -- PokerHand's evaluate() in this file indexes into `parts` (parts._2,
    -- parts._flush, etc.), which Steamodded builds *from* the hand's
    -- cards -- with 0 cards, some of those parts tables may not exist at
    -- all, so this deliberately checks `hand` directly instead of parts,
    -- and never touches parts.
    evaluate = function(parts, hand)
        if hand and #hand == 0 then
            return { {} } -- one scoring group, containing zero cards
        end
        return {}
    end,
}










SMODS.Enhancement{
    key = "bronze",
    loc_txt = {
        name = "Bronze Card",
        text = {
            "Gives {C:chips}X2{} Chips",
            "when held in hand",
        }
    },
    atlas = "HexEnhancers",
    pos = { x = 6, y = 0 },
    unlocked = true,
    discovered = true,
    weight = 1,
    in_pool = function(self) return true end,

    calculate = function(self, card, context)
        if context.main_scoring and context.cardarea == G.hand then
            return {
                x_chips = 2,
                colour = G.C.CHIPS,
                card = card,
            }
        end
    end,
}

SMODS.Enhancement{
    key = "crystal",
    loc_txt = {
        name = "Crystal Card",
        text = {
            "{C:green}#1# in 2{} chance to give",
            "{C:chips}^1.75{} Chips and",
            "{C:mult}^1.75{} Mult",
            "when scored",
        }
    },
    atlas = "HexEnhancers",
    pos = { x = 5, y = 1 },
    unlocked = true,
    discovered = true,
    weight = 0,
    in_pool = function(self) return true end,

    loc_vars = function(self, info_queue, card)
        return { vars = { G.GAME.probabilities.normal or 1 } }
    end,

    calculate = function(self, card, context)
        if context.main_scoring and context.cardarea == G.play then
            if pseudorandom(pseudoseed(mod.prefix .. "_crystal_" .. tostring(card.sort_id or card))) < G.GAME.probabilities.normal / 2 then
                return {
                    e_chips = 1.75,
                    e_mult = 1.75,
                    colour = G.C.BLUE,
                    card = card,
                }
            end
        end
    end,
}

SMODS.Enhancement{
    key = "platinum",
    loc_txt = {
        name = "Platinum Card",
        text = {
            "Gives {C:chips}^^1.25{} Chips and",
            "{C:mult}^^1.25{} Mult when scored",
            "{C:inactive}(Destroyed after the hand is played){}",
        }
    },
    atlas = "HexEnhancers",
    pos = { x = 1, y = 0 },
    unlocked = true,
    discovered = true,
    weight = 0,
    in_pool = function(self) return true end,

    calculate = function(self, card, context)
        -- Applies the tetration bonus when this card is scored -- same
        -- timing as before.
        if context.main_scoring and context.cardarea == G.play then
            return {
                ee_chips = 1.25,
                ee_mult = 1.25,
                colour = G.C.PURPLE,
                card = card,
                message = "Platinum!",
            }
        end

        -- Card Destruction Stage: this fires once per card, AFTER the
        -- entire hand has been scored (same stage vanilla Glass Card
        -- uses for its own break chance) -- context.destroying_card is
        -- only set if this particular card actually scored, so a
        -- Platinum card that was played but didn't score (e.g. not part
        -- of the winning poker hand, no Splash Joker) survives.
        if context.destroy_card
        and context.cardarea == G.play
        and context.destroying_card then
            return {
                remove = true
            }
        end
    end,
}


SMODS.Enhancement{
    key = "ruby",

    loc_txt = {
        name = "Ruby Card",
        text = {
            "Gives {C:mult}^#1#{} Mult",
            "when scored",
            "Gains {C:attention}+1{} power",
            "every time this card is played",
        }
    },

    atlas = "HexEnhancers",
    pos = { x = 3, y = 1 },

    unlocked = true,
    discovered = true,
    weight = 0,

    in_pool = function(self) return true end,

    config = { extra = { power = 1 } },

    loc_vars = function(self, info_queue, card)
        return { vars = { (card.ability.extra and card.ability.extra.power) or 1 } }
    end,

    calculate = function(self, card, context)
        -- Fires exactly once per card, before scoring begins -- resets
        -- the "already grew power this hand" flag so this specific
        -- card's power only ever grows once per play, no matter how
        -- many retriggers it gets, and no matter how many other cards
        -- are in the played hand.
        if context.before and context.cardarea == G.play then
            card.hex_ruby_grown_this_hand = false
        end

        if context.main_scoring and context.cardarea == G.play then
            if not card.hex_ruby_grown_this_hand then
                card.ability.extra.power = (card.ability.extra.power or 1) + 1
                card.hex_ruby_grown_this_hand = true
            end

            return {
                e_mult = card.ability.extra.power,
                colour = G.C.RED,
                card = card,
            }
        end
    end,
}

SMODS.Enhancement{
    key = "sapphire",

    loc_txt = {
        name = "Sapphire Card",
        text = {
            "Gives {C:chips}^#1#{} Chips",
            "when scored",
            "Gains {C:attention}+1{} power",
            "every time this card is played",
        }
    },

    atlas = "HexEnhancers",
    pos = { x = 1, y = 1 },

    unlocked = true,
    discovered = true,
    weight = 0,

    in_pool = function(self) return true end,

    config = { extra = { power = 1 } },

    loc_vars = function(self, info_queue, card)
        return { vars = { (card.ability.extra and card.ability.extra.power) or 1 } }
    end,

    calculate = function(self, card, context)
        if context.before and context.cardarea == G.play then
            card.hex_sapphire_grown_this_hand = false
        end

        if context.main_scoring and context.cardarea == G.play then
            if not card.hex_sapphire_grown_this_hand then
                card.ability.extra.power = (card.ability.extra.power or 1) + 1
                card.hex_sapphire_grown_this_hand = true
            end

            return {
                e_chips = card.ability.extra.power,
                colour = G.C.BLUE,
                card = card,
            }
        end
    end,
}

SMODS.Enhancement{
    key = "topaz",

    loc_txt = {
        name = "Topaz Card",
        text = {
            "Gives {C:money}+$#1#{}",
            "when triggered",
            "Gains {C:attention}+1{} power",
            "every time this card is played",
        }
    },

    atlas = "HexEnhancers",
    pos = { x = 2, y = 1 },

    unlocked = true,
    discovered = true,
    weight = 0,

    in_pool = function(self) return true end,

    config = { extra = { power = 1 } },

    loc_vars = function(self, info_queue, card)
        return { vars = { (card.ability.extra and card.ability.extra.power) or 1 } }
    end,

    calculate = function(self, card, context)
        if context.before and context.cardarea == G.play then
            card.hex_topaz_grown_this_hand = false
        end

        if context.main_scoring and context.cardarea == G.play then
            if not card.hex_topaz_grown_this_hand then
                card.ability.extra.power = (card.ability.extra.power or 1) + 1
                card.hex_topaz_grown_this_hand = true
            end

            return {
                dollars = card.ability.extra.power,
                colour = G.C.MONEY,
                card = card,
            }
        end
    end,
}

-- Counts every playing card in the whole deck (hand/deck-pile/discard/
-- play, anywhere -- using G.playing_cards, the same master registry the
-- Manifest ritual registers newly-created cards into elsewhere in this
-- file) that currently carries the Diamond enhancement.
function hex_count_diamond_cards()
    if not G.playing_cards then return 0 end

    local count = 0
    for _, c in ipairs(G.playing_cards) do
        if c.ability
        and c.ability.set == "Enhanced"
        and c.config
        and c.config.center
        and c.config.center.key == "m_" .. mod.prefix .. "_diamond" then
            count = count + 1
        end
    end

    return count
end

-- height = 1 + 0.5 * count, so 1 Diamond card in the deck (count = 1)
-- gives height 1.5, 2 gives 2.0, and so on.
local function hex_diamond_height()
    return 1 + 0.5 * hex_count_diamond_cards()
end

SMODS.Enhancement{
    key = "diamond",

    loc_txt = {
        name = "Diamond Card",
        text = {
            "Gives {C:chips}^^#1#{} Chips and",
            "{C:mult}^^#1#{} Mult when scored",
            "{C:inactive}(+0.5 height per Diamond{}",
            "{C:inactive}card in your deck){}",
        }
    },

    atlas = "HexEnhancers",
    pos = { x = 5, y = 0 },

    unlocked = true,
    discovered = true,
    weight = 0,
    no_rank = true,
    no_suit = true,
    replace_base_card = true,
    always_scores = true,

    in_pool = function(self) return true end,

    loc_vars = function(self, info_queue, card)
        return { vars = { string.format("%.1f", hex_diamond_height()) } }
    end,

    calculate = function(self, card, context)
        if context.main_scoring and context.cardarea == G.play then
            local height = hex_diamond_height()

            return {
                ee_chips = height,
                ee_mult = height,
                colour = G.C.BLUE,
                card = card,
            }
        end
    end,
}







local function hex_edition_context_ok(context)
    if context.post_joker then
        return true
    end

    if context.main_scoring and context.cardarea == G.play then
        return true
    end

    return false
end

SMODS.Shader({
    key = "prismatic",
    path = "prismatic.fs",
    send = function(self, shader, card)
        shader:send("time", G.TIMERS.REAL)
    end
})

SMODS.Shader({
    key = "chromatic",
    path = "chromatic.fs",
    send = function(self, shader, card)
        shader:send("time", G.TIMERS.REAL)
    end
})

SMODS.Shader({
    key = "brilliant",
    path = "brilliant.fs",
    send = function(self, shader, card)
        shader:send("time", G.TIMERS.REAL)
    end
})

SMODS.Shader({
    key = "radiant",
    path = "radiant.fs",
    send = function(self, shader, card)
        shader:send("time", G.TIMERS.REAL)
    end
})

SMODS.Shader({
    key = "empowered",
    path = "empowered.fs",
    send = function(self, shader, card)
        shader:send("time", G.TIMERS.REAL)
    end
})

SMODS.Edition{
    key = "prismatic",

    loc_txt = {
        name = "Prismatic", 
        label = "Prismatic",

        text = {
            "{C:purple}^1.25{} Mult"
        }
    },

    shader = "prismatic",
    in_shop = true,
    unlocked = true,
    discovered = true,
    weight = 1.0,
    extra_cost = 10,

    in_pool = function(self)
        return true
    end,

    calculate = function(self, card, context)
        if (context.edition and context.cardarea == G.jokers and card.config.trigger)
        or (context.main_scoring and context.cardarea == G.play) then
            return {
                e_mult = 1.25,
                colour = G.C.PURPLE
            }
        end

        if context.joker_main then
            card.config.trigger = true
        end

        if context.after then
            card.config.trigger = nil
        end
    end,
}

SMODS.Edition{
    key = "chromatic",

    loc_txt = {
        name = "Chromatic",
        label = "Chromatic",

        text = {
            "{C:blue}X2{} chips"
        }
    },

    shader = "chromatic",
    in_shop = true,
    unlocked = true,
    discovered = true,
    weight = 2.0,
    extra_cost = 5,

    in_pool = function(self)
        return true
    end,

    -- Doubles the running Chips whenever the card carrying this edition
    -- (Joker or playing card) scores.
    calculate = function(self, card, context)
        if (context.edition and context.cardarea == G.jokers and card.config.trigger)
        or (context.main_scoring and context.cardarea == G.play) then
            return {
                x_chips = 2,
                colour = G.C.BLUE
            }
        end

        if context.joker_main then
            card.config.trigger = true
        end

        if context.after then
            card.config.trigger = nil
        end
    end,

}

SMODS.Edition{
    key = "brilliant",

    loc_txt = {
        name = "Brilliant",
        label = "Brilliant",

        text = {
            "{C:blue}^1.5{} chips"
        }
    },

    shader = "brilliant",
    in_shop = true,
    unlocked = true,
    discovered = true,
    weight = 1.0,
    extra_cost = 10,

    in_pool = function(self)
        return true
    end,

    -- Raises the running Chips to the power of 1.5 whenever the card
    -- carrying this edition (Joker or playing card) scores.
    calculate = function(self, card, context)
        if (context.edition and context.cardarea == G.jokers and card.config.trigger)
        or (context.main_scoring and context.cardarea == G.play) then
            return {
                e_chips = 1.5,
                colour = G.C.BLUE
            }
        end

        if context.joker_main then
            card.config.trigger = true
        end

        if context.after then
            card.config.trigger = nil
        end
    end,
}


SMODS.Edition{
    key = "radiant",

    loc_txt = {
        name = "Radiant",
        label = "Radiant",

        text = {
            "{C:purple}^^1.25{} Chips and Mult"
        }
    },

    shader = "radiant",
    in_shop = true,
    unlocked = true,
    discovered = true,
    weight = 0.1,
    extra_cost = 40,

    in_pool = function(self)
        return true
    end,

    -- Tetrates both the running Chips and Mult to a height of 1.5
    -- whenever the card carrying this edition (Joker or playing card)
    -- scores.
    calculate = function(self, card, context)
        if (context.edition and context.cardarea == G.jokers and card.config.trigger)
        or (context.main_scoring and context.cardarea == G.play) then
            return {
                ee_chips = 1.25,
                ee_mult = 1.25,
            }
        end

        if context.joker_main then
            card.config.trigger = true
        end

        if context.after then
            card.config.trigger = nil
        end
    end,

}

G.C.HEX_EMPOWERED = HEX("9D4EDD") -- violet, used for Infused edition's badge/text

SMODS.Edition{
    key = "empowered",

    loc_txt = {
        name = "Empowered",
        label = "Empowered",

        text = {
            "{C:purple}^^^1.1{} Chips and Mult"
        }
    },

    shader = "empowered",
    in_shop = true,
    unlocked = true,
    discovered = true,
    weight = 0.05, -- rarer than Radiant, matches the step up in power
    extra_cost = 100,

    in_pool = function(self)
        return true
    end,

    -- Pentates both the running Chips and Mult to a height of 1.1
    -- whenever the card carrying this edition (Joker or playing card)
    -- scores.
    calculate = function(self, card, context)
        if (context.edition and context.cardarea == G.jokers and card.config.trigger)
        or (context.main_scoring and context.cardarea == G.play) then
            return {
                eee_chips = 1.1,
                eee_mult = 1.1,
                colour = G.C.HEX_EMPOWERED
            }
        end
        if context.joker_main then card.config.trigger = true end
        if context.after then card.config.trigger = nil end
    end,
}


-- Colour used for the Orange Seal's badge/description text -- vanilla
-- Balatro only defines Gold/Red/Blue/Purple seal colours (G.C.SEAL_*
-- equivalents), so a custom one is needed here the same way MYTHIC/
-- TRANSCENDENTAL/DIVINE/RITUAL each got their own G.C entry up top.
G.C.HEX_ORANGE_SEAL = HEX("FF8800")

-- Orange Seal: retriggers the card it's on two additional times (i.e.
-- the card scores a total of 3 times -- once normally, plus these 2
-- extra reps). Mirrors vanilla's own Red Seal implementation exactly
-- (context.repetition + context.cardarea == G.play, returning a
-- `repetitions` count alongside the specific `card` being retriggered),
-- just with repetitions = 2 instead of Red Seal's 1.
SMODS.Seal{
    key = "orange",

    loc_txt = {
        name = "Orange Seal",
        label = "Orange Seal",
        text = {
            "Retriggers this card",
            "{C:attention}2{} additional times",
        }
    },

    atlas = "HexEnhancers",
    pos = { x = 2, y = 0 },

    badge_colour = G.C.HEX_ORANGE_SEAL,

    unlocked = true,
    discovered = true,

    calculate = function(self, card, context)
        if context.repetition and (context.cardarea == G.play or context.cardarea == G.hand) then
            return {
                repetitions = 2,
                card = card
            }
        end
    end,
}

-- Colours used for the Green and Pink Seals' badges/description text,
-- the same way G.C.HEX_ORANGE_SEAL was defined above for Orange Seal.
G.C.HEX_GREEN_SEAL = HEX("00CC44")
G.C.HEX_PINK_SEAL = HEX("FF69B4")

-- Green Seal: retriggers the card it's on 3 additional times (i.e. the
-- card scores a total of 4 times), same implementation as Orange Seal
-- above just with a higher flat repetitions count.
SMODS.Seal{
    key = "green",

    loc_txt = {
        name = "Green Seal",
        label = "Green Seal",
        text = {
            "Retriggers this card",
            "{C:attention}3{} additional times",
        }
    },

    atlas = "HexEnhancers",
    pos = { x = 3, y = 4 },

    badge_colour = G.C.HEX_GREEN_SEAL,

    unlocked = true,
    discovered = true,

    calculate = function(self, card, context)
        if context.repetition and (context.cardarea == G.play or context.cardarea == G.hand) then
            return {
                repetitions = 3,
                card = card
            }
        end
    end,
}

-- Pink Seal: on each trigger, an independent 1-in-8 roll grants 10
-- additional retriggers of the card (i.e. that particular trigger scores
-- 11 times total). Unlike Orange/Green Seal's flat, guaranteed bonus,
-- this is a probabilistic jackpot -- most triggers do nothing extra, but
-- roughly one in eight blow up into a huge score.
SMODS.Seal{
    key = "pink",

    loc_txt = {
        name = "Pink Seal",
        label = "Pink Seal",
        text = {
            "{C:green}#1# in 8{} chance to retrigger",
            "this card {C:attention}10{} additional times",
        }
    },

    atlas = "HexEnhancers",
    pos = { x = 5, y = 4 },

    badge_colour = G.C.HEX_PINK_SEAL,

    unlocked = true,
    discovered = true,

    -- Fills the #1# placeholder above with the *real*, current "X in 8"
    -- odds, taking G.GAME.probabilities.normal into account -- the same
    -- multiplier Oops! All 6s doubles (and stacks further with multiple
    -- copies of it), which is also what the seal's own calculate function
    -- below folds into its actual roll. Base odds are 1 in 8; Oops! All 6s
    -- doubling probabilities.normal to 2 means the true odds are 2 in 8,
    -- and this keeps the tooltip in sync with that instead of always
    -- showing the unmodified base value. Deliberately kept as "X in 8"
    -- (numerator scaled, denominator left at 8) rather than simplified
    -- down to a reduced fraction like "1 in 4", per request. Falls back
    -- to the base 1-in-8 reading (prob_mod = 1) outside of a run, e.g. in
    -- the collection screen, where G.GAME.probabilities may not exist yet.
    loc_vars = function(self, info_queue, card)
        local prob_mod = (G.GAME and G.GAME.probabilities and G.GAME.probabilities.normal) or 1
        local numer = 1 * prob_mod

        local numer_display
        if numer == math.floor(numer) then
            numer_display = math.floor(numer)
        else
            numer_display = string.format("%.2f", numer)
        end

        return { vars = { numer_display } }
    end,

    -- Uses pseudoseed the same way the Negative Deck's edition-roll boost
    -- above does (a fixed seed key, not per-card), so the roll is still
    -- deterministic/seed-safe per game seed, just re-rolled fresh every
    -- time this fires. G.GAME.probabilities.normal is the same global
    -- multiplier vanilla's own "1 in X" joker effects (Space Joker,
    -- Reserved Parking, Oops! All 6s itself, etc.) read -- Oops! All 6s
    -- doubles it (and stacks further with multiple copies), so folding
    -- it into our odds here is all that's needed for Oops! All 6s to
    -- affect this seal too, without checking for that Joker directly.
    calculate = function(self, card, context)
        if context.repetition and (context.cardarea == G.play or context.cardarea == G.hand) then
            local chance = (1 / 8) * (G.GAME.probabilities.normal or 1)
            if pseudorandom(pseudoseed(mod.prefix .. "_pink_seal")) < chance then
                return {
                    repetitions = 10,
                    card = card
                }
            end
        end
    end,
}

-- Colour used for the Black Seal's badge/description text, the same way
-- G.C.HEX_ORANGE_SEAL/HEX_GREEN_SEAL/HEX_PINK_SEAL were defined above.
-- A pure black (000000) badge would be unreadable against the game's
-- dark panels, so this uses a lighter charcoal instead, the same
-- brightness compromise vanilla's own near-black UI elements (e.g.
-- G.C.JOKER_GREY) make for the same reason.
G.C.HEX_BLACK_SEAL = HEX("3A3A3A")

-- Black Seal: mirrors vanilla Blue Seal's own "card held in hand at end
-- of round" main effect. Unlike Orange/Green/Pink Seal above (which hook
-- context.repetition to add extra scoring triggers), this is a seal's
-- *main* effect, which Steamodded's own eval_card evaluates whenever
-- context.cardarea == G.hand and context.repetition is NOT set -- adding
-- an context.individual check here (as an earlier draft of this seal
-- did) is wrong and silently never fires, since that flag is set for
-- *Jokers* granting effects to individual cards, not for a card's own
-- seal/enhancement main ability. Unlike Blue Seal (which always creates
-- a Planet), this creates a random Spectral card -- SMODS.create_card
-- with set = "Spectral" and no explicit key draws randomly from the
-- game's normal Spectral pool, so custom grant-only Spectrals like this
-- mod's own Heart (in_pool = false) are correctly excluded, the same
-- way normal shop/pack generation would exclude them.
SMODS.Seal{
    key = "black",

    loc_txt = {
        name = "Black Seal",
        label = "Black Seal",
        text = {
            "",
            "creates a random {C:spectral}Spectral{} card",
            "at end of round if held in hand",
            "{C:inactive}(Must have room){}",
        }
    },

    atlas = "HexEnhancers",
    pos = { x = 4, y = 4 },

    badge_colour = G.C.HEX_BLACK_SEAL,

    unlocked = true,
    discovered = true,

    calculate = function(self, card, context)
        -- context.end_of_round fires multiple times per card in this
        -- Steamodded build (same category of quirk as the
        -- context.first_hand_drawn issue noted elsewhere in this file for
        -- Orion) -- Steamodded's own docs recommend gating on
        -- context.main_eval for a once-per-round effect, but that flag
        -- doesn't actually get set on this call in this installed build,
        -- so relying on it made the seal never fire at all. Instead we
        -- dedupe the same way Orion does further down the file: stamp the
        -- current G.GAME.round directly onto the card the moment we act,
        -- and skip if we've already fired for this exact round. This is
        -- per-card (not global), so multiple Black Seals in hand each
        -- still grant their own Spectral card once per round.
        if context.end_of_round
        and context.cardarea == G.hand
        and not context.repetition
        and not context.blueprint
        and card.hex_black_seal_last_round ~= G.GAME.round then

            card.hex_black_seal_last_round = G.GAME.round

            if G.consumeables and #G.consumeables.cards < G.consumeables.config.card_limit then

                G.E_MANAGER:add_event(Event({
                    trigger = "after",
                    delay = 0.1,
                    func = function()
                        -- Re-check room here, at the moment this actually
                        -- fires, not just back when it was scheduled --
                        -- multiple Black Seals in hand can all pass the
                        -- outer check in the same frame (before any of
                        -- their delayed events have actually added a card
                        -- yet), which could otherwise overflow past the
                        -- consumable slot limit. This second check is what
                        -- actually prevents that.
                        if not (G.consumeables and #G.consumeables.cards < G.consumeables.config.card_limit) then
                            return true
                        end

                        -- NOTE: deliberately NOT calling new_card:add_to_deck()
                        -- here -- that call registers a card into the
                        -- playing-card/deck-tracking systems (G.playing_cards,
                        -- deck count UI, etc.), which is only correct for
                        -- actual 52-card-deck cards (see the Manifest ritual's
                        -- playing-card creation further down the file, which
                        -- legitimately needs it). Calling it on a Spectral
                        -- consumable misregistered it there, which is what
                        -- caused the glitched/flickering blue-box texture.
                        -- SMODS.create_card already plays its own
                        -- materialize animation automatically (that's what
                        -- the skip_materialize option exists to suppress) --
                        -- calling new_card:start_materialize() again here on
                        -- top of that ran two overlapping materialize
                        -- animations on the same card at once, which is what
                        -- produced the corrupted blue-shard/double-exposure
                        -- look. Every other card creation in this file
                        -- (Life ritual, Manifest ritual, Ritualistic Deck's
                        -- grant, etc.) just creates + emplaces and leaves it
                        -- at that, so this now matches that pattern.
                        local new_card = SMODS.create_card({
                            set = "Spectral",
                            area = G.consumeables
                        })

                        G.consumeables:emplace(new_card)

                        return true
                    end
                }))

                return {
                    message = "+1 Spectral",
                    colour = G.C.HEX_BLACK_SEAL
                }
            end
        end
    end,
}












local HEX_ENHANCEMENT_POOL_EXCLUDE = {
    ["m_" .. mod.prefix .. "_crystal"] = true,
    ["m_" .. mod.prefix .. "_platinum"] = true,
    ["m_" .. mod.prefix .. "_ruby"] = true,
    ["m_" .. mod.prefix .. "_sapphire"] = true,
    ["m_" .. mod.prefix .. "_topaz"] = true,
    ["m_" .. mod.prefix .. "_diamond"] = true,
}

-- Custom Seals (Orange/Green/Pink/Black) should never be randomly rolled
-- onto a card by vanilla mechanisms -- e.g. Standard Packs' own "special"
-- seal chance, or the Certificate Joker's random-rank/suit/seal grant --
-- both of which build their candidate seal list from whatever seal keys
-- are currently registered, which now includes every custom seal this
-- mod adds via SMODS.Seal (Steamodded registers those into the same
-- G.P_SEALS pool as vanilla's own Gold/Red/Blue/Purple). Every one of
-- our custom seals is meant to be grant-only (via specific Star/Galaxy
-- cards, The Seal of Aces, etc.) -- seals have no should_apply hook the
-- way Stickers do (see Immortal's should_apply = false above for that
-- pattern), so this filters them out of the shared pseudorandom_element
-- roll instead, the same exclusion approach HEX_ENHANCEMENT_POOL_EXCLUDE
-- already uses just above for custom Enhancements.
local HEX_SEAL_POOL_EXCLUDE = {
    [mod.prefix .. "_orange"] = true,
    [mod.prefix .. "_green"] = true,
    [mod.prefix .. "_pink"] = true,
    [mod.prefix .. "_black"] = true,
}


-- Strip any custom seal off a card the instant it's emplaced into an open
-- Standard/Celestial/Buffoon/Arcana/Spectral Pack's own card area
-- (G.pack_cards). This is a single guaranteed choke point every pack
-- card passes through, regardless of whether its seal was set via
-- Card:set_seal, a raw field assignment, or anything else internal to
-- how the pack rolled it -- so it doesn't matter how vanilla actually
-- applied the seal, only that we clean it up right before the player
-- can see/pick the card.
local hex_old_cardarea_emplace_seal_strip = CardArea.emplace

function CardArea:emplace(card, ...)
    if self == G.pack_cards
    and card
    and card.seal
    and HEX_SEAL_POOL_EXCLUDE[card.seal] then

        if card.set_seal then
            card:set_seal(nil, true)
        else
            card.seal = nil
        end
    end

    return hex_old_cardarea_emplace_seal_strip(self, card, ...)
end








local hex_old_pseudorandom_element = pseudorandom_element

function pseudorandom_element(_t, seed)
    -- Detect "this is the Enhanced pool" by looking at what's actually
    -- IN the table, rather than comparing table identity against
    -- G.P_CENTER_POOLS.Enhanced -- if Steamodded ever hands Familiar/
    -- Grim/Incantation/Shadow a rebuilt/derived table instead of the
    -- literal same object, an identity check silently never matches
    -- and nothing gets filtered.
    if type(_t) == "table" and #_t > 0 and type(_t[1]) == "table" and _t[1].set == "Enhanced" then
        local filtered = {}
        for _, center in ipairs(_t) do
            if not HEX_ENHANCEMENT_POOL_EXCLUDE[center.key] then
                filtered[#filtered + 1] = center
            end
        end

        if #filtered > 0 then
            return hex_old_pseudorandom_element(filtered, seed)
        end
    end

    -- Seal pools are plain string keys ("Gold", "Red", "Blue", "Purple",
    -- plus every custom seal registered by this or any other mod) rather
    -- than Center tables, so they're detected differently -- by checking
    -- that the first element is a string which is actually a registered
    -- seal key in G.P_SEALS.
    if type(_t) == "table" and #_t > 0 and type(_t[1]) == "string" and G.P_SEALS and G.P_SEALS[_t[1]] then
        local filtered = {}
        for _, key in ipairs(_t) do
            if not HEX_SEAL_POOL_EXCLUDE[key] then
                filtered[#filtered + 1] = key
            end
        end

        if #filtered > 0 then
            return hex_old_pseudorandom_element(filtered, seed)
        end
    end

    return hex_old_pseudorandom_element(_t, seed)
end



-- Certificate Joker: full override. Vanilla implements this effect as a
-- hardcoded name check inside Card:calculate_joker itself (not via a
-- Center's own .calculate function) -- see the file's earlier comment
-- history on this override for why that matters. This intercepts
-- Card:calculate_joker directly (same technique the Perkeo override
-- elsewhere in this file uses), runs our own exact copy of vanilla's
-- effect, and returns without calling the original, so vanilla's own
-- hardcoded branch never runs a second time alongside ours.
--
-- trigger = 'after' + a short delay (rather than the default 'immediate'
-- trigger vanilla's own event uses) makes sure this card is created
-- AFTER the normal start-of-round hand draw has already finished,
-- instead of racing ahead of it.
local hex_old_calculate_joker_certificate = Card.calculate_joker

function Card:calculate_joker(context)
    if self.ability and self.ability.name == 'Certificate' then
        if context.first_hand_drawn and not context.blueprint then
            G.E_MANAGER:add_event(Event({
                func = function()
                    local _card = create_playing_card({
                        front = pseudorandom_element(G.P_CARDS, pseudoseed('cert_fr')),
                        center = G.P_CENTERS.c_base}, G.hand, nil, nil, {G.C.SECONDARY_SET.Enhanced})

                    local seal_type = pseudorandom(pseudoseed('certsl'))
                    if seal_type > 0.75 then _card:set_seal('Red', true)
                    elseif seal_type > 0.5 then _card:set_seal('Blue', true)
                    elseif seal_type > 0.25 then _card:set_seal('Gold', true)
                    else _card:set_seal('Purple', true)
                    end

                    G.GAME.blind:debuff_card(_card)
                    G.hand:sort()
                    if context.blueprint_card then context.blueprint_card:juice_up() else self:juice_up() end
                    return true
                end
            }))

            playing_card_joker_effects({true})
        end

        return
    end

    return hex_old_calculate_joker_certificate(self, context)
end


-- Colour used for the Immortal sticker's badge/description text, the
-- same way G.C.HEX_ORANGE_SEAL/HEX_GREEN_SEAL/HEX_PINK_SEAL/
-- HEX_BLACK_SEAL were defined above for their respective Seals.
G.C.HEX_IMMORTAL = HEX("7D7D7D")

-- The full, mod-prefixed key this sticker is actually stored/checked
-- under on a card's `ability` table (card.ability[HEX_IMMORTAL_STICKER_KEY]).
-- Declared once, up here, so both the sticker's own registration below
-- and every other piece of code that needs to apply or check for it
-- later in the file (the Card.start_dissolve hook, and Absolute's own
-- summon function) all stay in sync automatically.
HEX_IMMORTAL_STICKER_KEY = mod.prefix .. "_immortal"

-- Immortal: a purely cosmetic/flag sticker -- it carries no scoring
-- `calculate` of its own (unlike Seals above). Its actual "can't be
-- destroyed" behaviour lives entirely in the Card.start_dissolve hook
-- further down the file, which blocks the dissolve/destroy animation
-- outright for any card carrying this sticker, with one deliberate
-- exception (see that hook's own comment for the Absolute-summon
-- carve-out). should_apply is hard-pinned to false so this can never be
-- randomly rolled onto a shop card the way Eternal/Perishable/Rental
-- normally can -- the only place in this mod that ever applies it is
-- Absolute's own summon function, further down the file.
SMODS.Sticker{
    key = "immortal",

    loc_txt = {
        name = "Immortal",
        label = "Immortal",
        text = {
            "This card can",
            "{C:attention}never{} be destroyed",
            "{C:inactive}(except when{}",
            "{C:inactive}summoning {C:absolute}Absolute{}{C:inactive}){}",
        }
    },

    atlas = "HexStickers",
    pos = { x = 0, y = 0 },

    badge_colour = G.C.HEX_IMMORTAL,

    should_apply = function(self, card, center)
        return false -- never naturally rolled onto a card; only ever applied directly by Absolute's summon function
    end,
}

-- Applies the Immortal sticker to a card, and enforces mutual exclusivity
-- with Eternal and Perishable at the same time -- vanilla's own stake-
-- based sticker roll (inside old_create_card, same place its edition roll
-- runs) can independently land either of those on a freshly-created
-- Joker, so both are stripped unconditionally here to guarantee Immortal
-- is always the only one of the three ever present on the card. Uses
-- Steamodded's own Seal/Edition-style card:set_sticker API when it's
-- available; otherwise falls back to setting the ability flag directly
-- (which is all our own Card.start_dissolve check further down the file
-- actually reads anyway), so this still works either way instead of
-- silently no-oping.
function hex_apply_immortal_sticker(card)
    if not card then return end

    if card.set_sticker then
        card:set_sticker(HEX_IMMORTAL_STICKER_KEY, true)
    end

    card.ability = card.ability or {}
    card.ability[HEX_IMMORTAL_STICKER_KEY] = true

    card.ability.eternal = nil
    card.ability.perishable = nil
    card.ability.perish_tally = nil
end

-- ============================================================
-- Vouchers: Legendary Soul / Mythic Heart
-- Both double the chance of their respective "soul" card showing up
-- inside Arcana/Spectral packs -- vanilla's own Soul (c_soul, the card
-- that creates a Legendary Joker) for Legendary Soul, and this mod's own
-- Heart consumable (which mirrors Soul's soul_rate/soul_set mechanism,
-- see its SMODS.Consumable{...} definition further down the file) for
-- Mythic Heart. Both vouchers just multiply the target center's own
-- soul_rate field directly -- the same field already driving both
-- cards' natural appearance chance -- rather than touching any global
-- probability table, so this can never affect anything else that rolls
-- off G.GAME.probabilities elsewhere in this file (Pink Seal, Altair,
-- etc).
--
-- Mythic Heart is the tier-2 voucher (via `requires`), unlocked only
-- after Legendary Soul has been bought, the same tier-1/tier-2
-- relationship vanilla's own voucher pairs (Overstock/Overstock Plus,
-- Clearance Sale/Liquidation, etc.) use.
HEX_SOUL_CENTER_KEY = "c_soul" -- vanilla's own Soul card
HEX_HEART_CENTER_KEY = "c_" .. mod.prefix .. "_heart"

do
    local soul_center = G.P_CENTERS[HEX_SOUL_CENTER_KEY]
    if soul_center and not soul_center.soul_rate then
        soul_center.soul_rate = 0.003
    end
end

SMODS.Voucher{
    key = "legendary_soul",

    loc_txt = {
        name = "Legendary Soul",
        text = {
            "{C:attention}Doubles{} the chance",
            "to find {C:legendary}The Soul{} card",
            "in {C:tarot}Arcana{} and {C:spectral}Spectral{} packs",
        }
    },

    atlas = "HexVouchers",
    pos = { x = 7, y = 0 },

    unlocked = true,
    discovered = true,

    -- NOTE: Vouchers use `redeem`, not `add_to_deck` -- add_to_deck/
    -- remove_from_deck are the generic Center hooks for when a card is
    -- added to/removed from a persistent owned CardArea (how Jokers/Backs
    -- work), but a Voucher card doesn't stick around in one of those
    -- after being bought -- it's redeemed once and disappears. `redeem`
    -- is Steamodded's own voucher-specific hook for that moment.
    redeem = function(self, card)
        local center = G.P_CENTERS[HEX_SOUL_CENTER_KEY]
        if center and center.soul_rate then
            center.soul_rate = center.soul_rate * 2
        end
    end,
}

SMODS.Voucher{
    key = "mythic_heart",

    loc_txt = {
        name = "Mythic Heart",
        text = {
            "{C:attention}Doubles{} the chance",
            "to find {C:mythic}Heart{} card",
            "in {C:tarot}Arcana{} and {C:spectral}Spectral{} packs",
        }
    },

    atlas = "HexVouchers",
    pos = { x = 7, y = 0 }, -- NOTE: shares its atlas frame with Legendary Soul (7,0), per how it was requested -- move it to an unused frame in HexVouchers before shipping if that overlap isn't intentional, since both currently render with the same sprite.

    -- Tier 2: only appears/unlocks in the shop after Legendary Soul has
    -- been bought, same requires-based gating vanilla's own tier-2
    -- vouchers use.
    requires = { "v_" .. mod.prefix .. "_legendary_soul" },

    unlocked = true,
    discovered = true,

    redeem = function(self, card)
        local center = G.P_CENTERS[HEX_HEART_CENTER_KEY]
        if center and center.soul_rate then
            center.soul_rate = center.soul_rate * 2
        end
    end,
}

-- Nova: unlocks Star Packs (see the SMODS.Booster{ key = "star_pack",
-- kind = "star", ... } registration further down the file, right after
-- the "star" ConsumableType) so they can start appearing in the shop's
-- normal pack-weight pool at all -- Star Pack's own in_pool check reads
-- this exact flag. Star Pack's own `weight` field (set once at
-- registration time, to half of vanilla Spectral Normal's own weight)
-- is what actually makes it show up half as often as a regular Spectral
-- pack once unlocked; this voucher only flips that on/off switch.
SMODS.Voucher{
    key = "nova",

    loc_txt = {
        name = "Nova",
        text = {
            "{C:star}Star Packs{} can now",
            "appear in the shop",
        }
    },

    atlas = "HexVouchers",
    pos = { x = 7, y = 0 }, -- NOTE: shares its atlas frame with Legendary Soul / Mythic Heart (7,0), the same overlap those two already have with each other -- move it to an unused frame in HexVouchers before shipping if that isn't intentional.

    unlocked = true,
    discovered = true,

    redeem = function(self, card)
        G.GAME.hex_nova_unlocked = true
    end,
}

-- Hypernova: tier 2 of Nova, via `requires` (same tier-1/tier-2 pattern
-- every other paired voucher in this file uses). Unlike Nova (which only
-- unlocks Star Pack showing up as a booster), this lets individual Star
-- cards themselves appear directly in the shop's normal consumable
-- slots -- handled by the create_card hook's own shop-injection roll
-- below, gated on this exact flag.
SMODS.Voucher{
    key = "hypernova",

    loc_txt = {
        name = "Hypernova",
        text = {
            "{C:star}Star cards{} can now",
            "appear in the {C:attention}shop{}",
        }
    },

    atlas = "HexVouchers",
    pos = { x = 7, y = 0 }, -- NOTE: shares its atlas frame with the other (7,0) vouchers in this mod, per the existing convention -- move it to an unused frame in HexVouchers before shipping if that overlap isn't intentional.

    requires = { "v_" .. mod.prefix .. "_nova" },

    unlocked = true,
    discovered = true,

    redeem = function(self, card)
        G.GAME.hex_hypernova_unlocked = true
    end,
}



-- Cosmic Rays: tier 3 of Nova (requires Hypernova). Unlocks Galaxy Packs
-- appearing in the shop's normal pack-weight pool -- same on/off switch
-- pattern Nova uses for Star Packs, just gating a separate flag that
-- Galaxy Pack / Jumbo Galaxy Pack / Mega Galaxy Pack's own in_pool
-- checks read below.
SMODS.Voucher{
    key = "cosmic_rays",

    loc_txt = {
        name = "Cosmic Rays",
        text = {
            "{C:galaxy}Galaxy Packs{} can now",
            "appear in the shop",
        }
    },

    atlas = "HexVouchers",
    pos = { x = 7, y = 0 }, -- shares its frame with the other (7,0) vouchers in this mod, per existing convention

    requires = { "v_" .. mod.prefix .. "_hypernova" },

    unlocked = true,
    discovered = true,

    redeem = function(self, card)
        G.GAME.hex_cosmic_rays_unlocked = true
    end,
}






-- Gravitational Waves: tier 4 of Nova (requires Cosmic Rays). Unlocks
-- Galaxy cards appearing directly in the shop's normal consumable slots --
-- same on/off switch pattern Hypernova uses for Star cards, just gating a
-- separate flag that the shop-injection hook below reads.
SMODS.Voucher{
    key = "gravitational_waves",

    loc_txt = {
        name = "Gravitational Waves",
        text = {
            "{C:galaxy}Galaxy cards{} can now",
            "appear in the {C:attention}shop{}",
        }
    },

    atlas = "HexVouchers",
    pos = { x = 7, y = 0 }, -- shares its frame with the other (7,0) vouchers in this mod, per existing convention

    requires = { "v_" .. mod.prefix .. "_cosmic_rays" },

    unlocked = true,
    discovered = true,

    redeem = function(self, card)
        G.GAME.hex_grav_waves_unlocked = true
    end,
}

-- Relativistic Jets: tier 5 of Nova (requires Gravitational Waves).
-- Permanently boosts the odds of Nebula, Cosmic, and Astral cards
-- appearing as bonus slots inside Star/Galaxy packs -- multiplies the
-- existing HEX_NEBULA_IN_GALAXYPACK_CHANCE / HEX_COSMIC_IN_PACK_CHANCE /
-- HEX_ASTRAL_IN_PACK_CHANCE odds via hex_relativistic_jets_mult() (see
-- below), read at every one of those roll sites.
SMODS.Voucher{
    key = "relativistic_jets",

    loc_txt = {
        name = "Relativistic Jets",
        text = {
            "{C:nebula}Nebula{}, {C:cosmic}Cosmic{}, and",
            "{C:astral}Astral{} cards are {C:attention}X3{} more",
            "likely to appear in packs",
        }
    },

    atlas = "HexVouchers",
    pos = { x = 7, y = 0 },

    requires = { "v_" .. mod.prefix .. "_gravitational_waves" },

    unlocked = true,
    discovered = true,

    redeem = function(self, card)
        G.GAME.hex_relativistic_jets_unlocked = true
    end,
}











-- Reach / Long Reach: permanently raises the playing-card selection
-- limit (the same limit Polydactyly overrides to effectively-infinite,
-- and Pinwheel Galaxy nudges up a point at a time) via a persistent
-- G.GAME counter, hex_reach_bonus_limit. Applied in the Game:update poll
-- further down the file, right alongside Polydactyly's own override and
-- Pinwheel Galaxy's bonus -- see the comment there for how all three
-- combine. Long Reach is the tier-2 voucher (via `requires`), unlocked
-- only after Reach has been bought, the same tier-1/tier-2 relationship
-- Legendary Soul/Mythic Heart use above -- but unlike some tier pairs,
-- its own +2 bonus is additive on top of Reach's +1 rather than
-- replacing it, per how it was requested ("stacks with Reacher").
SMODS.Voucher{
    key = "reach",

    loc_txt = {
        name = "Reach",
        text = {
            "{C:attention}+1{} selection limit",
            "for {C:attention}playing cards{}",
        }
    },

    atlas = "HexVouchers",
    pos = { x = 7, y = 0 },

    unlocked = true,
    discovered = true,

    redeem = function(self, card)
        G.GAME.hex_reach_bonus_limit = (G.GAME.hex_reach_bonus_limit or 0) + 1
    end,
}

SMODS.Voucher{
    key = "long_reach",

    loc_txt = {
        name = "Long Reach",
        text = {
            "{C:attention}+2{} selection limit",
            "for {C:attention}playing cards{}",
            "{C:inactive}(Stacks with Reach){}",
        }
    },

    atlas = "HexVouchers",
    pos = { x = 7, y = 0 }, -- NOTE: shares its atlas frame with the other (7,0) vouchers in this mod, per how it was requested -- move it to an unused frame in HexVouchers before shipping if that overlap isn't intentional.

    -- Tier 2: only appears/unlocks in the shop after Reach has been
    -- bought, same requires-based gating vanilla's own tier-2 vouchers
    -- (and this mod's Mythic Heart, above) use.
    requires = { "v_" .. mod.prefix .. "_reach" },

    unlocked = true,
    discovered = true,

    redeem = function(self, card)
        G.GAME.hex_reach_bonus_limit = (G.GAME.hex_reach_bonus_limit or 0) + 2
    end,
}

-- Negative Bunch / Negative Cluster: each permanently unlocks its own
-- independent, additional roll for the Negative edition on newly created
-- Jokers -- separate from (and stacking with) vanilla's own edition
-- roll, Negative Deck's boost, and Altair's boost, the same way each of
-- those already stack with one another. Implemented as simple on/off
-- flags (rather than a stacking multiplier like Altair's own
-- hex_altair_mult) since each of these vouchers can only ever be bought
-- once -- the actual rolls live in the create_card hook above, right
-- after Altair's own roll. Negative Cluster is the tier-2 voucher (via
-- `requires`), unlocked only after Negative Bunch has been bought, same
-- tier-1/tier-2 relationship Reach/Long Reach use just above -- and,
-- per how it was requested, its own roll stacks alongside Negative
-- Bunch's roll rather than replacing it.
SMODS.Voucher{
    key = "negative_bunch",

    loc_txt = {
        name = "Negative Bunch",
        text = {
            "{C:attention}Doubles{} the chance",
            "for Jokers to be {C:dark_red}Negative{}",
            "{C:inactive}(Stacks with other Negative boosts){}",
        }
    },

    atlas = "HexVouchers",
    pos = { x = 7, y = 0 },

    unlocked = true,
    discovered = true,

    redeem = function(self, card)
        G.GAME.hex_negative_bunch_unlocked = true
    end,
}

SMODS.Voucher{
    key = "negative_cluster",

    loc_txt = {
        name = "Negative Cluster",
        text = {
            "{C:attention}Triples{} the chance",
            "for Jokers to be {C:dark_red}Negative{}",
            "{C:inactive}(Stacks with other Negative boosts){}",
            "{C:inactive}and Negative Bunch){}",
        }
    },

    atlas = "HexVouchers",
    pos = { x = 7, y = 0 },

    requires = { "v_" .. mod.prefix .. "_negative_bunch" },

    unlocked = true,
    discovered = true,

    redeem = function(self, card)
        G.GAME.hex_negative_cluster_unlocked = true
    end,
}


-- checks.
SMODS.Voucher{
    key = "overstock_plus_plus",

    loc_txt = {
        name = "Overstock Plus Plus",
        text = {
            "{C:attention}+1{} booster pack slot",
            "and {C:attention}+1{} voucher slot",
            "available in the {C:attention}shop{}",
        }
    },

    atlas = "HexVouchers",
    pos = { x = 7, y = 0 },

    requires = { "v_overstock_plus" },

    unlocked = true,
    discovered = true,

    redeem = function(self, card)
        SMODS.change_booster_limit(1)
        SMODS.change_voucher_limit(1)
    end,
}


SMODS.Voucher{
    key = "big_box",

    loc_txt = {
        name = "Big Box",
        text = {
            "Booster Packs have",
            "{C:attention}+1{} more option",
            "{C:inactive}(Stacks with other ways{}",
            "{C:inactive}to get more options){}",
        }
    },

    atlas = "HexVouchers",
    pos = { x = 7, y = 0 },

    unlocked = true,
    discovered = true,

    redeem = function(self, card)
        G.GAME.hex_bigbox_bonus = (G.GAME.hex_bigbox_bonus or 0) + 1
    end,
}

SMODS.Voucher{
    key = "giant_box",

    loc_txt = {
        name = "Giant Box",
        text = {
            "Booster Packs have",
            "{C:attention}+1{} more option",
            "{C:inactive}(Stacks with other ways{}",
            "{C:inactive}to get more options){}",
        }
    },

    atlas = "HexVouchers",
    pos = { x = 7, y = 0 },

    requires = { "v_" .. mod.prefix .. "_big_box" },

    unlocked = true,
    discovered = true,

    redeem = function(self, card)
        G.GAME.hex_bigbox_bonus = (G.GAME.hex_bigbox_bonus or 0) + 1
    end,
}


SMODS.Voucher{
    key = "magic_studies",

    loc_txt = {
        name = "Magic Studies",
        text = {
            "Gain {C:purple}+1{}",
            "{C:purple}Hex point{} for",
            "hexing a Joker",
        }
    },

    atlas = "HexVouchers",
    pos = { x = 7, y = 0 },

    unlocked = true,
    discovered = true,

    redeem = function(self, card)
        G.GAME.hex_magic_studies_bonus = (G.GAME.hex_magic_studies_bonus or 0) + 1
    end,
}

SMODS.Voucher{
    key = "forbidden_knowledge",

    loc_txt = {
        name = "Forbidden Knowledge",
        text = {
            "Gain {C:purple}+2{}",
            "{C:purple}Hex points{} for",
            "hexing a Joker",
            "{C:inactive}(Stacks with Magic Studies){}",
        }
    },

    atlas = "HexVouchers",
    pos = { x = 7, y = 0 },

    requires = { "v_" .. mod.prefix .. "_magic_studies" },

    unlocked = true,
    discovered = true,

    redeem = function(self, card)
        G.GAME.hex_magic_studies_bonus = (G.GAME.hex_magic_studies_bonus or 0) + 2
    end,
}








SMODS.Back{
    key = "infinite_joker_deck",

    loc_txt = {
        name = "Infinite Deck",
        text = {
            "Start off with",
            "{C:attention}infinite Joker slots{}"
        }
    },

    config = {
        joker_slot = 999995
    },
    
    unlocked = true,
    discovered = true,

    pos = { x = 0, y = 0 },

    atlas = "HexEnhancers",
}

SMODS.Back{
    key = "negative_deck",

    loc_txt = {
        name = "Negative Deck",
        text = {
            "{C:attention}Negative{} Jokers appear",
            "{C:attention}50 times{} more often"
        }
    },

    config = {},

    unlocked = true,
    discovered = true,

    pos = { x = 0, y = 2 }, 

    atlas = "HexEnhancers",
}


SMODS.Back({
    key = "golden_deck",
    loc_txt = {
        name = "Golden Deck",
        text = {
            "Start with {C:money}$1000{}"
        }
    },

    config = { dollars = 996 },

    unlocked = true,
    discovered = true,

    pos = { x = 1, y = 4 },

    atlas = "HexEnhancers",

    set_deck = function(self, card, the_deck)
        if G.GAME and G.GAME.dollars then
            G.GAME.dollars = big(996) -- CHANGED: was 996
        end
    end
})


 
SMODS.Back{
    key = "overstock_deck",

    loc_txt = {
        name = "Overstock Deck",
        text = {
            "Start with {C:attention}Overstock{},",
            "{C:attention}Overstock Plus{}, and",
            "{C:attention}Overstock Plus Plus{}"
        }
    },

    atlas = "HexEnhancers",
    pos = {x = 1, y = 4},

    unlocked = true,
    discovered = true,

    config = {
        start_vouchers = {
            "v_overstock_norm",
            "v_overstock_plus",
            "v_hex_overstock_plus_plus"
        }
    },

    apply = function(self, back)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.1,
            func = function()
                G.GAME.shop.joker_max = (G.GAME.shop.joker_max or 0) + 2

                G.GAME.used_vouchers = G.GAME.used_vouchers or {}

                for _, key in ipairs({
                    "v_overstock_norm",
                    "v_overstock_plus",
                    "v_hex_overstock_plus_plus"
                }) do
                    local voucher = G.P_CENTERS[key]

                    if voucher then
                        G.GAME.used_vouchers[key] = true

                        if voucher.redeem then
                            voucher:redeem()
                        end
                    end
                end

                return true
            end
        }))
    end,

}

-- Key of our custom Back, used below to check which deck is currently
-- selected. Declared once here so both the create_card hook and any
-- future code referencing this deck stay in sync automatically if the
-- mod prefix ever changes.
local HEX_NEGATIVE_DECK_KEY = "b_" .. mod.prefix .. "_negative_deck"

-- Vanilla's own baseline chance of a shop/generated Joker rolling the
-- Negative edition is roughly 0.3% (0.003). We want Negative Jokers to
-- show up 10x as often while this deck is selected, so the extra,
-- independent roll below checks against 50x that baseline (0.15 / 15%).
local HEX_NEGATIVE_DECK_RATE = 0.15

-- Altair: rather than a flat boosted rate like Negative Deck above,
-- Altair keeps a persistent, stacking multiplier on G.GAME
-- (hex_altair_mult, starting at 1) that's increased X1.1 every time a
-- copy of Altair is used. This baseline rate (roughly vanilla's own
-- ~0.3% chance for a Joker to roll Negative) is what that multiplier is
-- applied against, via its own independent roll below -- separate from,
-- and therefore stacking with, both vanilla's own edition roll inside
-- old_create_card and the Negative Deck boost roll just below this one.
HEX_ALTAIR_BASE_RATE = 0.003

local function hex_negative_deck_selected()
    return G.GAME
        and G.GAME.selected_back
        and G.GAME.selected_back.effect
        and G.GAME.selected_back.effect.center
        and G.GAME.selected_back.effect.center.key == HEX_NEGATIVE_DECK_KEY
end

-- Star cards: cards of the custom "star" ConsumableType (see the
-- SMODS.ConsumableType{ key = "star", ... } registration further down
-- this file) never appear in the shop and are never part of the normal
-- Spectral/Tarot draw pools -- every Star card sets in_pool = false, the
-- same way this mod's Rituals do -- so they have to be injected by hand
-- instead. Whenever a Spectral or Arcana (Tarot) pack is generating one
-- of its card slots, `area` is G.pack_cards regardless of which of the
-- two pack types is open, which gives a single reliable hook point for
-- both. Each slot gets an independent, flat 1-in-33 chance to be
-- replaced with a random Star card instead of whatever it would have
-- naturally rolled from the Spectral/Tarot pool.
function hex_owns_showman()
    if SMODS and SMODS.showman then
        return SMODS.showman() and true or false
    end
    if SMODS and SMODS.find_card then
        return #SMODS.find_card("j_ring_master") > 0
    end
    return find_joker and next(find_joker("Showman")) and true or false
end









-- Applies this edition's own extra_cost onto a card's shop price. The
-- five custom editions (Prismatic/Chromatic/Brilliant/Radiant/Empowered)
-- are rolled onto Jokers via card:set_edition *after* old_create_card has
-- already finished computing the card's shop cost -- vanilla's own cost
-- calculation only ever accounts for whatever edition was already present
-- at that point, so our own editions' extra_cost fields were being
-- silently ignored. This adds the missing amount directly, then forces
-- the shop price display to refresh via card:set_cost() if it exists.
local function hex_apply_edition_cost(card, edition_key)
    local center = G.P_CENTERS["e_" .. edition_key]
    if not (card and center) then return end

    card.cost = (card.cost or 0) + (center.extra_cost or 0)

    if card.set_cost then
        card:set_cost()
    end
end



-- List of every Enhancement key allowed to appear as a random "Enhanced"
-- playing card in the shop (the slot type Magic Trick/Illusion unlock).
-- Every vanilla enhancement, plus this mod's own Bronze -- Crystal/
-- Platinum/Ruby/Sapphire/Topaz/Diamond are deliberately excluded here,
-- on top of their own in_pool = false, so this exact shop slot can never
-- pick them.
HEX_SHOP_ENHANCED_ALLOWED = {
    "m_bonus",
    "m_mult",
    "m_wild",
    "m_glass",
    "m_steel",
    "m_stone",
    "m_gold",
    "m_lucky",
    "m_" .. mod.prefix .. "_bronze",
}

local function hex_pick_shop_enhanced_key()
    local candidates = {}
    for _, key in ipairs(HEX_SHOP_ENHANCED_ALLOWED) do
        if G.P_CENTERS[key] then
            candidates[#candidates + 1] = key
        end
    end
    if #candidates == 0 then return nil end
    return candidates[math.random(#candidates)]
end




-- Combines every active Negative-edition boost into a single multiplier
-- over the baseline rate (HEX_ALTAIR_BASE_RATE), rather than rolling
-- each source independently. Negative Deck's flat HEX_NEGATIVE_DECK_RATE
-- is expressed as its own multiplier over the baseline so it combines on
-- the same footing as Altair/Negative Bunch/Negative Cluster.
local function hex_negative_boost_multiplier()
    local mult = 1

    if hex_negative_deck_selected() then
        mult = mult * (HEX_NEGATIVE_DECK_RATE / HEX_ALTAIR_BASE_RATE)
    end

    if G.GAME and (G.GAME.hex_altair_mult or 1) > 1 then
        mult = mult * (G.GAME.hex_altair_mult or 1)
    end

    if G.GAME and G.GAME.hex_negative_bunch_unlocked then
        mult = mult * 2
    end

    if G.GAME and G.GAME.hex_negative_cluster_unlocked then
        mult = mult * 3
    end

    return mult
end

-- Applies a single combined roll for Negative Deck / Altair / Negative
-- Bunch / Negative Cluster, using hex_negative_boost_multiplier() above
-- rather than four separate independent rolls. Only fires if the card
-- doesn't already have an edition, and only if at least one of the four
-- sources is actually active (mult > 1) -- otherwise there's nothing to
-- roll for. Called from both create_card (covers Judgement etc.) and
-- the CardArea:emplace hook below (covers shop-added Jokers, which
-- don't reliably route through create_card -- same category of quirk
-- Hypernova's own Star-card injection hit).
function hex_apply_negative_boosts(card)
    if not (card and card.edition == nil) then return end

    local mult = hex_negative_boost_multiplier()
    if mult <= 1 then return end

    local chance = math.min(1, HEX_ALTAIR_BASE_RATE * mult)

    if pseudorandom(pseudoseed(mod.prefix .. "_negative_boost")) < chance then
        card:set_edition({ negative = true }, true)
    end
end



















local old_create_card = create_card

function create_card(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append)

    -- Magic Trick / Illusion: the shop's random "Enhanced" playing-card
    -- slot arrives here with _type == nil, area == the shop area, and no
    -- forced_key -- vanilla/Steamodded would otherwise poll a random
    -- Enhancement center itself for this, which is exactly what's
    -- crashing. Handing it an explicit key from our own safe list avoids
    -- that poll entirely, and guarantees only Bronze (plus vanilla
    -- enhancements) can ever show up here.
    if _type == nil
    and area == G.shop_jokers
    and not forced_key
    and not legendary
    and not _rarity then
        forced_key = hex_pick_shop_enhanced_key()
    end
 
    

    -- Galaxy cards get first crack at a Spectral/Tarot pack slot (1 in
    -- 50 -- rarer than Star's 1 in 33 checked right after it). Both
    -- gate on `not forced_key`, so whichever roll succeeds first is the
    -- one that sticks; a slot can never be double-forced by both.
    if (_type == "Spectral" or _type == "Tarot")
    and area == G.pack_cards
    and not forced_key
    and pseudorandom(pseudoseed(mod.prefix .. "_galaxy_pack")) < HEX_GALAXY_PACK_CHANCE then

        local galaxies = hex_get_galaxy_centers()
        if #galaxies > 0 then
            forced_key = galaxies[math.random(#galaxies)].key
        end
    end

    if (_type == "Spectral" or _type == "Tarot")
    and area == G.pack_cards
    and not forced_key
    and pseudorandom(pseudoseed(mod.prefix .. "_star_pack")) < HEX_STAR_PACK_CHANCE then

        local stars = hex_get_star_centers()
        if #stars > 0 then
            forced_key = stars[math.random(#stars)].key
        end
    end

    if (_type == "Spectral" or _type == "Tarot")
    and area == G.pack_cards
    and not forced_key then
        local soul_center = G.P_CENTERS[HEX_SOUL_CENTER_KEY]
        local heart_center = G.P_CENTERS[HEX_HEART_CENTER_KEY]

        if soul_center and not soul_center.soul_rate then
            soul_center.soul_rate = 0.003
        end

        local soul_rate = (soul_center and soul_center.soul_rate) or 0
        local heart_rate = (heart_center and heart_center.soul_rate) or 0
        local combined = soul_rate + heart_rate

        if combined > 0 then
            local roll = pseudorandom(pseudoseed(mod.prefix .. "_soul_heart_roll"))

            if combined >= 1 then
                -- Both are boosted past "guaranteed" -- split the slot
                -- between them in proportion to their own rates instead
                -- of letting whichever is checked first win every time.
                if roll < soul_rate / combined then
                    forced_key = HEX_SOUL_CENTER_KEY
                else
                    forced_key = HEX_HEART_CENTER_KEY
                end
            else
                if roll < soul_rate then
                    forced_key = HEX_SOUL_CENTER_KEY
                elseif roll < combined then
                    forced_key = HEX_HEART_CENTER_KEY
                end
            end
        end
    end


    local card = old_create_card(
        _type,
        area,
        legendary,
        _rarity,
        skip_materialize,
        soulable,
        forced_key,
        key_append
    )



    if _type == "Joker" and pseudorandom(mod.prefix .. "_prismatic_joker") < 0.005 then
        card:set_edition({
            [mod.prefix .. "_prismatic"] = true
        }, true)
        hex_apply_edition_cost(card, mod.prefix .. "_prismatic")
    end

    if _type == "Joker" and pseudorandom(mod.prefix .. "_chromatic_joker") < 0.01 then
        card:set_edition({
            [mod.prefix .. "_chromatic"] = true
        }, true)
        hex_apply_edition_cost(card, mod.prefix .. "_chromatic")
    end
    if _type == "Joker" and pseudorandom(mod.prefix .. "_brilliant_joker") < 0.005 then
        card:set_edition({
            [mod.prefix .. "_brilliant"] = true
        }, true)
        hex_apply_edition_cost(card, mod.prefix .. "_brilliant")
    end
    if _type == "Joker" and pseudorandom(mod.prefix .. "_radiant_joker") < 0.0001 then
        card:set_edition({
            [mod.prefix .. "_radiant"] = true
        }, true)
        hex_apply_edition_cost(card, mod.prefix .. "_radiant")
    end
    if _type == "Joker" and pseudorandom(mod.prefix .. "_empowered_joker") < 0.00001 then
        card:set_edition({
            [mod.prefix .. "_empowered"] = true
        }, true)
        hex_apply_edition_cost(card, mod.prefix .. "_empowered")
    end

    if _type == "Joker" then
        hex_apply_negative_boosts(card)
    end

    return card
end








SMODS.Back{
    key = "gamblers_deck",

    loc_txt = {
        name = "Gambler's Deck",
        text = {
            "Start with a {C:attention}random{}",
            "amount of {C:mult}hands{}, {C:chips}discards{},",
            "{C:money}starting money{}, and",
            "{C:attention}hand size{}",
            "(each between 1 and 10)"
        }
    },

    config = {},

    unlocked = true,
    discovered = true,

    pos = { x = 1, y = 4 }, -- next open frame in the atlas, after Infinite Deck (0,0) and Negative Deck (0,2)

    atlas = "HexEnhancers",
} 




SMODS.Back{
    key = "celestial_deck",

    loc_txt = {
        name = "Celestial Deck",
        text = {
            "Start with {C:attention}Nova{} and",
            "{C:attention}Hypernova{}, and {C:attention}1{} random",
            "{C:star}Star{} card and {C:attention}1{} random",
            "{C:galaxy}Galaxy{} card",
        }
    },

    unlocked = true,
    discovered = true,

    -- NOTE: shares its atlas frame with the other (1,4) decks in this
    -- mod, per existing convention -- move it to an unused frame in
    -- HexEnhancers before shipping if that overlap isn't intentional.
    pos = { x = 1, y = 4 },

    atlas = "HexEnhancers",

    -- Redeems Nova and Hypernova immediately when the deck is applied --
    -- same apply-time redeem pattern Overstock Deck uses for its own
    -- three starting vouchers above (G.P_CENTERS[key]:redeem() plus
    -- marking G.GAME.used_vouchers so they show as owned/redeemed).
    -- Wrapped in the same 0.1s delayed event Overstock Deck uses, so
    -- G.GAME is guaranteed to exist by the time this runs.
    apply = function(self, back)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.1,
            func = function()
                G.GAME.used_vouchers = G.GAME.used_vouchers or {}

                for _, key in ipairs({
                    "v_" .. mod.prefix .. "_nova",
                    "v_" .. mod.prefix .. "_hypernova",
                }) do
                    local voucher = G.P_CENTERS[key]

                    if voucher then
                        G.GAME.used_vouchers[key] = true

                        if voucher.redeem then
                            voucher:redeem()
                        end
                    end
                end

                return true
            end
        }))
    end,
}



SMODS.Back{
    key = "black_hole_deck",

    loc_txt = {
        name = "Black Hole Deck",
        text = {
            "Start with a random",
            "{C:black_hole}Black Hole{} card",
        }
    },

    unlocked = true,
    discovered = true,

    -- NOTE: shares its atlas frame with the other (1,4) decks in this
    -- mod, per existing convention -- move it to an unused frame in
    -- HexEnhancers before shipping if that overlap isn't intentional.
    pos = { x = 1, y = 4 },

    atlas = "HexEnhancers",
}








SMODS.Back{
    key = "cursed_deck",

    loc_txt = {
        name = "Cursed Deck",
        text = {
            "Start with {C:purple}50{}",
            "{C:purple}Hex points{}",
            "Gain twice the",
            "{C:purple}Hex points{} from",
            "{C:purple}hexing{} a Joker"
        }
    },

    config = {},

    unlocked = true,
    discovered = true,

    -- NOTE: this shares its atlas frame with Gambler's Deck (pos 1,4) as
    -- requested -- if that's not intentional, move one of the two decks
    -- to an unused frame before shipping, since they'll currently render
    -- with the same sprite.
    pos = { x = 1, y = 4 },

    atlas = "HexEnhancers",
}

-- Key of Cursed Deck, used the same way HEX_NEGATIVE_DECK_KEY /
-- HEX_GAMBLERS_DECK_KEY are used, to check which deck is currently selected.
local HEX_CURSED_DECK_KEY = "b_" .. mod.prefix .. "_cursed_deck"

function hex_cursed_deck_selected()
    return G.GAME
        and G.GAME.selected_back
        and G.GAME.selected_back.effect
        and G.GAME.selected_back.effect.center
        and G.GAME.selected_back.effect.center.key == HEX_CURSED_DECK_KEY
end

-- Cursed Deck: grants 50 starting Hex points. Hooked onto Game:start_run
-- separately from the main "Create Hex Points when a run starts" hooks
-- further down the file, so it doesn't need to be threaded through those.
-- We only apply this on a genuinely new run (not a save being resumed) --
-- Balatro passes a table with a `savetext` field as the first vararg when
-- continuing a saved run, so checking for that keeps this from stomping
-- your accumulated Hex points every time you reload a Cursed Deck run.
local old_start_run_cursed_deck = Game.start_run

function Game:start_run(args, ...)
    local ret = old_start_run_cursed_deck(self, args, ...)

    if hex_cursed_deck_selected() and not (args and args.savetext) then
        G.GAME.hex_points = big(50)
    end

    return ret
end

SMODS.Back{
    key = "ritualistic_deck",

    loc_txt = {
        name = "Ritualistic Deck",
        text = {
            "Start with a random",
            "{C:ritual}Ritual{} card",
        }
    },

    unlocked = true,
    discovered = true,

    -- NOTE: shares its atlas frame with Gambler's, Cursed, Prestige, and
    -- Relic Deck (pos 1,4), per how it was requested -- move it to an
    -- unused frame in HexEnhancers before shipping if that overlap isn't
    -- intentional, since all five currently render with the same sprite.
    pos = { x = 1, y = 4 },

    atlas = "HexEnhancers",
}

-- Key of Ritualistic Deck, used the same way HEX_RELIC_DECK_KEY /
-- HEX_PRESTIGE_DECK_KEY are used, to check which deck is currently selected.
local HEX_RITUALISTIC_DECK_KEY = "b_" .. mod.prefix .. "_ritualistic_deck"

local function hex_ritualistic_deck_selected()
    return G.GAME
        and G.GAME.selected_back
        and G.GAME.selected_back.effect
        and G.GAME.selected_back.effect.center
        and G.GAME.selected_back.effect.center.key == HEX_RITUALISTIC_DECK_KEY
end

-- Ritualistic Deck: grants one random Ritual consumable on a genuine new
-- run. Rituals are never in the normal shop/consumable pool (they all set
-- in_pool = false, same reasoning as the Mythic/Legendary Joker grants
-- above), so we build the candidate list by hand -- the same short-key
-- list G.FUNCS.create_ritual already maintains further down the file --
-- rather than scanning G.P_CENTERS, and pick with math.random rather than
-- pseudorandom_element for the same in_pool-filtering reason.
local HEX_RITUAL_SHORT_KEYS = {
    "hyperbolic",
    "life",
    "fractal",
    "eclipse",
    "manifest",
    "ascension",
    "big_bang",
    "big_crunch",
    "big_rip",
    "false_vacuum_decay",
    "heat_death",
    "entropy",
    "singularity",
}

local old_start_run_ritualistic_deck = Game.start_run

function Game:start_run(args, ...)
    local ret = old_start_run_ritualistic_deck(self, args, ...)

    if hex_ritualistic_deck_selected() and not (args and args.savetext) then
        if G.consumeables and #G.consumeables.cards < G.consumeables.config.card_limit then
            local chosen_short_key = HEX_RITUAL_SHORT_KEYS[math.random(#HEX_RITUAL_SHORT_KEYS)]
            local chosen_key = "c_" .. mod.prefix .. "_" .. chosen_short_key

            -- Mirrors G.FUNCS.create_ritual further down the file exactly:
            -- SMODS.create_card + manual emplace, keyed only by the full
            -- "c_..." key with no `set` field. Passing set = "ritual" here
            -- (an earlier version of this hook did) made Steamodded treat
            -- "ritual" as a broad card-type token rather than our custom
            -- ConsumableType, which could create a card whose loc_txt
            -- (name/description) didn't match the actual key/center that
            -- got applied -- omitting `set` and letting `key` alone drive
            -- creation, like create_ritual already does, avoids that.
            local card = SMODS.create_card({
                key = chosen_key,
                area = G.consumeables
            })

            G.consumeables:emplace(card)

            G.GAME.hex_rituals_summoned = G.GAME.hex_rituals_summoned or {}
            G.GAME.hex_rituals_summoned[chosen_short_key] = true
        end
    end

    return ret
end

SMODS.Back{
    key = "relic_deck",

    loc_txt = {
        name = "Relic Deck",
        text = {
            "Start with a random",
            "{C:legendary}Legendary{} Joker",
        }
    },


    unlocked = true,
    discovered = true,

    -- NOTE: shares its atlas frame with Gambler's, Cursed, and Prestige
    -- Deck (pos 1,4), per how it was requested -- move it to an unused
    -- frame in HexEnhancers before shipping if that overlap isn't
    -- intentional, since all four currently render with the same sprite.
    pos = { x = 1, y = 4 },

    atlas = "HexEnhancers",
}

-- Key of Relic Deck, used the same way HEX_CURSED_DECK_KEY /
-- HEX_PRESTIGE_DECK_KEY are used, to check which deck is currently selected.
local HEX_RELIC_DECK_KEY = "b_" .. mod.prefix .. "_relic_deck"

local function hex_relic_deck_selected()
    return G.GAME
        and G.GAME.selected_back
        and G.GAME.selected_back.effect
        and G.GAME.selected_back.effect.center
        and G.GAME.selected_back.effect.center.key == HEX_RELIC_DECK_KEY
end

-- Relic Deck: grants one random Legendary (rarity 4) Joker on a genuine
-- new run, the same pool-scan-then-math.random approach used for Prestige
-- Deck's Mythic grant above (math.random rather than pseudorandom_element,
-- since some Legendary-rarity Jokers registered by this or other mods may
-- also set in_pool = false, which pseudorandom_element would otherwise
-- filter out -- see the comment on Prestige Deck's grant for the full
-- explanation of that pitfall). The 3-slot cap itself is handled purely by
-- the joker_slot config above; this hook only needs to worry about the
-- starting Joker grant.
local old_start_run_relic_deck = Game.start_run

function Game:start_run(args, ...)
    local ret = old_start_run_relic_deck(self, args, ...)

    if hex_relic_deck_selected() and not (args and args.savetext) then
        local showman_owned = hex_owns_showman()

        local legendaries = {}
        for _, center in pairs(G.P_CENTERS) do
            if center.set == "Joker"
            and center.rarity == 4
            and (showman_owned or #SMODS.find_card(center.key) == 0) then
                legendaries[#legendaries + 1] = center
            end
        end

        if #legendaries > 0 and G.jokers and #G.jokers.cards < G.jokers.config.card_limit then
            local chosen = legendaries[math.random(#legendaries)]

            SMODS.add_card{
                set = "Joker",
                key = chosen.key
            }
        end
    end

    return ret
end

SMODS.Back{
    key = "prestige_deck",

    loc_txt = {
        name = "Prestige Deck",
        text = {
            "Start with a random",
            "{C:mythic}Mythic{} Joker",
            "Win ante is ante 16",
        }
    },

    config = {},

    unlocked = true,
    discovered = true,

    -- NOTE: this also shares its atlas frame with Gambler's Deck and
    -- Cursed Deck (pos 1,4), per how it was requested -- move it to an
    -- unused frame in HexEnhancers before shipping if that overlap isn't
    -- intentional, since all three currently render with the same sprite.
    pos = { x = 1, y = 4 },

    atlas = "HexEnhancers",
}

-- Key of Prestige Deck, used the same way HEX_CURSED_DECK_KEY is used
-- above, to check which deck is currently selected.
local HEX_PRESTIGE_DECK_KEY = "b_" .. mod.prefix .. "_prestige_deck"

local function hex_prestige_deck_selected()
    return G.GAME
        and G.GAME.selected_back
        and G.GAME.selected_back.effect
        and G.GAME.selected_back.effect.center
        and G.GAME.selected_back.effect.center.key == HEX_PRESTIGE_DECK_KEY
end

-- Prestige Deck: grants one random Mythic Joker (same pool-scan approach
-- the Heart consumable above uses) and raises the ante at which Finisher
-- Blinds appear -- and therefore the ante the run is actually won at --
-- from the vanilla 8 up to 16. G.GAME.win_ante is Steamodded/vanilla's
-- own field for this (it's what the Finisher Blind check reads), so we
-- don't need any extra win-condition hooking beyond setting it.
-- Same new-run-only guard (checking args.savetext) as Cursed Deck above,
-- so reloading a save doesn't hand out a second free Mythic Joker or
-- reset win_ante if some other effect already changed it mid-run.
local old_start_run_prestige_deck = Game.start_run

function Game:start_run(args, ...)
    local ret = old_start_run_prestige_deck(self, args, ...)

    if hex_prestige_deck_selected() and not (args and args.savetext) then
        G.GAME.win_ante = 16

        local showman_owned = hex_owns_showman()

        local mythics = {}
        for _, center in pairs(G.P_CENTERS) do
            if center.set == "Joker"
            and center.rarity == R_HEX_MYTHIC.key
            and (showman_owned or #SMODS.find_card(center.key) == 0) then
                mythics[#mythics + 1] = center
            end
        end

        if #mythics > 0 then
            -- NOTE: deliberately not pseudorandom_element here. Steamodded's
            -- pseudorandom_element respects each candidate's in_pool (see the
            -- SMODS.Rank/Suit docs: "while respecting in_pool"), and every
            -- Mythic Joker in this mod sets in_pool = function() return false
            -- end (that's what makes them unlock/grant-only rarities in the
            -- first place) -- so it silently filtered the pool down to
            -- nothing and returned nil, crashing here. math.random matches
            -- what the Heart consumable's use function already does above
            -- for this exact same "pick a random Mythic" case.
            local chosen = mythics[math.random(#mythics)]

            if G.jokers and #G.jokers.cards < G.jokers.config.card_limit then
                SMODS.add_card{
                    set = "Joker",
                    key = chosen.key
                }
            end
        end
    end

    return ret
end

SMODS.Back{
    key = "infernal_deck",

    loc_txt = {
        name = "Infernal Deck",
        text = {
            "Start with a random",
            "{C:transcendental}Transcendental{} Joker",
            "Win ante is ante 24",
        }
    },

    config = {},

    unlocked = true,
    discovered = true,

    -- NOTE: shares its atlas frame with Gambler's, Cursed, Ritualistic,
    -- Relic, and Prestige Deck (pos 1,4), per how it was requested -- move
    -- it to an unused frame in HexEnhancers before shipping if that
    -- overlap isn't intentional, since all these decks currently render
    -- with the same sprite.
    pos = { x = 1, y = 4 },

    atlas = "HexEnhancers",
}

-- Key of Infernal Deck, used the same way HEX_PRESTIGE_DECK_KEY is used
-- above, to check which deck is currently selected.
local HEX_INFERNAL_DECK_KEY = "b_" .. mod.prefix .. "_infernal_deck"

local function hex_infernal_deck_selected()
    return G.GAME
        and G.GAME.selected_back
        and G.GAME.selected_back.effect
        and G.GAME.selected_back.effect.center
        and G.GAME.selected_back.effect.center.key == HEX_INFERNAL_DECK_KEY
end

-- Infernal Deck: grants one random Transcendental Joker (same pool-scan
-- approach Prestige Deck's Mythic grant above uses) and raises win_ante
-- to 24. Same new-run-only guard (checking args.savetext) as Prestige
-- Deck above, so reloading a save doesn't hand out a second free
-- Transcendental Joker or reset win_ante if some other effect already
-- changed it mid-run.
local old_start_run_infernal_deck = Game.start_run

function Game:start_run(args, ...)
    local ret = old_start_run_infernal_deck(self, args, ...)

    if hex_infernal_deck_selected() and not (args and args.savetext) then
        G.GAME.win_ante = 24

        local transcendentals = {}
        for _, center in pairs(G.P_CENTERS) do
            if center.set == "Joker" and center.rarity == R_HEX_TRANSCENDENTAL.key then
                transcendentals[#transcendentals + 1] = center
            end
        end

        if #transcendentals > 0 then
            -- Deliberately not pseudorandom_element here, for the same
            -- reason as Prestige Deck's Mythic grant above -- every
            -- Transcendental Joker in this mod sets in_pool = function()
            -- return false end, which pseudorandom_element would filter
            -- down to nothing.
            local chosen = transcendentals[math.random(#transcendentals)]

            if G.jokers and #G.jokers.cards < G.jokers.config.card_limit then
                SMODS.add_card{
                    set = "Joker",
                    key = chosen.key
                }
            end
        end
    end

    return ret
end

SMODS.Back{
    key = "ascended_deck",

    loc_txt = {
        name = "Ascended Deck",
        text = {
            "Start with a random",
            "{C:divine}Divine{} Joker",
            "Win ante is ante 32",
        }
    },

    config = {},

    unlocked = true,
    discovered = true,

    -- NOTE: shares its atlas frame with Gambler's, Cursed, Ritualistic,
    -- Relic, Prestige, and Infernal Deck (pos 1,4), per how it was
    -- requested -- move it to an unused frame in HexEnhancers before
    -- shipping if that overlap isn't intentional, since all these decks
    -- currently render with the same sprite.
    pos = { x = 1, y = 4 },

    atlas = "HexEnhancers",
}

-- Key of ascended Deck, used the same way HEX_PRESTIGE_DECK_KEY is used
-- above, to check which deck is currently selected.
local HEX_ASCENDED_DECK_KEY = "b_" .. mod.prefix .. "_ascended_deck"

local function hex_ascended_deck_selected()
    return G.GAME
        and G.GAME.selected_back
        and G.GAME.selected_back.effect
        and G.GAME.selected_back.effect.center
        and G.GAME.selected_back.effect.center.key == HEX_ASCENDED_DECK_KEY
end

-- ASCENDED Deck: grants one random Divine Joker (same pool-scan approach
-- Prestige/Infernal Deck's grants above use) and raises win_ante to 32.
-- Same new-run-only guard as the decks above. Inaccessible is excluded
-- from the pool, the same way G.FUNCS.summon_divine excludes it -- it
-- must be earned normally, never handed out as a starting Joker.
local old_start_run_ascended_deck = Game.start_run

function Game:start_run(args, ...)
    local ret = old_start_run_ascended_deck(self, args, ...)

    if hex_ascended_deck_selected() and not (args and args.savetext) then
        G.GAME.win_ante = 32

        local divines = {}
        for _, center in pairs(G.P_CENTERS) do
            if center.set == "Joker"
            and center.rarity == R_HEX_DIVINE.key
            and center.key ~= ("j_" .. mod.prefix .. "_inaccessible") then -- Inaccessible can never be handed out as a starting Joker; it must be earned normally, same as summon_divine's exclusion
                divines[#divines + 1] = center
            end
        end

        if #divines > 0 then
            -- Deliberately not pseudorandom_element here, for the same
            -- reason as Prestige/Infernal Deck's grants above.
            local chosen = divines[math.random(#divines)]

            if G.jokers and #G.jokers.cards < G.jokers.config.card_limit then
                SMODS.add_card{
                    set = "Joker",
                    key = chosen.key
                }
            end
        end
    end

    return ret
end

SMODS.Back{
    key = "hard_deck",

    loc_txt = {
        name = "Hard Deck",
        text = {
            "{C:mult}-1{} Joker slot",
            "{C:mult}-1{} hand each round",
            "{C:mult}-1{} discard each round",
            "{C:attention}-1{} hand size",
            "Start with {C:money}$0{}",
        }
    },

    -- joker_slot here is the same Steamodded Back config field
    -- Ritualistic/Relic Deck use above -- it's applied to
    -- G.jokers.config.card_limit automatically on start_run, no extra
    -- hook needed for the slot count itself. Hands/discards/hand_size/
    -- dollars have no equivalent auto-applied config field (see the
    -- comment on Gambler's Deck's hook further down for why), so those
    -- are handled manually in the start_run hook below.
    config = {
        joker_slot = -1
    },

    unlocked = true,
    discovered = true,

    -- NOTE: shares its atlas frame with Gambler's, Cursed, Ritualistic,
    -- Relic, Prestige, Infernal, and Holy Deck (pos 1,4), per how it was
    -- requested -- move it to an unused frame in HexEnhancers before
    -- shipping if that overlap isn't intentional, since all these decks
    -- currently render with the same sprite.
    pos = { x = 1, y = 2 },

    atlas = "HexEnhancers",
}

-- Key of Hard Deck, used the same way HEX_PRESTIGE_DECK_KEY is used
-- above, to check which deck is currently selected.
local HEX_HARD_DECK_KEY = "b_" .. mod.prefix .. "_hard_deck"

local function hex_hard_deck_selected()
    return G.GAME
        and G.GAME.selected_back
        and G.GAME.selected_back.effect
        and G.GAME.selected_back.effect.center
        and G.GAME.selected_back.effect.center.key == HEX_HARD_DECK_KEY
end

-- Hard Deck: raises win_ante to 16 and knocks a point off of hands,
-- discards, and hand size every round, plus starts with no money.
-- Same new-run-only guard (checking args.savetext) as the decks above,
-- so reloading a save doesn't re-subtract from an already-adjusted
-- round_resets or zero out money mid-run.
--
-- Hands/discards/hand size have no auto-applied Back config field the
-- way joker_slot does, so -- same approach Gambler's Deck's hook below
-- uses -- we overwrite the per-round baseline (round_resets) directly,
-- then fix up round 1's live counters and the hand that's already been
-- dealt by the time this runs. math.max floors keep a deck selection
-- (or a future mod stacking further reductions) from ever dropping any
-- of these to something unplayable (0 hands, negative hand size, etc.).
local old_start_run_hard_deck = Game.start_run

function Game:start_run(args, ...)
    local ret = old_start_run_hard_deck(self, args, ...)

    if hex_hard_deck_selected() and not (args and args.savetext) then

        G.GAME.round_resets.hands = math.max(1, (G.GAME.round_resets.hands or 4) - 1)
        G.GAME.round_resets.discards = math.max(0, (G.GAME.round_resets.discards or 3) - 1)
        G.GAME.round_resets.hand_size = math.max(1, (G.GAME.round_resets.hand_size or 8) - 1)

        if G.GAME.current_round then
            G.GAME.current_round.hands_left = G.GAME.round_resets.hands
            G.GAME.current_round.discards_left = G.GAME.round_resets.discards
        end

        G.GAME.dollars = big(0) -- CHANGED: was 0

        -- Hand size: the round-1 hand has already been dealt at the
        -- vanilla/deck-default size by the time this hook runs, so trim
        -- it down to match the reduced hand_size, returning the excess
        -- cards to the deck (mirrors the shrink branch of Gambler's
        -- Deck's own hand-size fixup below).
        if G.hand and G.hand.config then
            G.hand.config.card_limit = G.GAME.round_resets.hand_size

            if G.deck then
                for i = #G.hand.cards, 1, -1 do
                    if #G.hand.cards <= G.GAME.round_resets.hand_size then break end
                    local c = G.hand:remove_card(G.hand.cards[i])
                    if c then
                        G.deck:emplace(c)
                    end
                end
            end
        end
    end

    return ret
end


SMODS.Back{
    key = "impossible_deck",

    loc_txt = {
        name = "Impossible Deck",
        text = {
            "{C:mult}-3{} Joker slot",
            "{C:mult}-2{} hand each round",
            "{C:mult}-2{} discard each round",
            "{C:attention}-3{} hand size",
            "Start with {C:money}$0{}",
        }
    },

    config = {
        joker_slot = -3
    },

    unlocked = true,
    discovered = true,

    pos = { x = 1, y = 2 },

    atlas = "HexEnhancers",
}

local HEX_IMPOSSIBLE_DECK_KEY = "b_" .. mod.prefix .. "_impossible_deck"

local function hex_impossible_deck_selected()
    return G.GAME
        and G.GAME.selected_back
        and G.GAME.selected_back.effect
        and G.GAME.selected_back.effect.center
        and G.GAME.selected_back.effect.center.key == HEX_IMPOSSIBLE_DECK_KEY
end


local old_start_run_impossible_deck = Game.start_run

function Game:start_run(args, ...)
    local ret = old_start_run_impossible_deck(self, args, ...)

    if hex_impossible_deck_selected() and not (args and args.savetext) then
        G.GAME.win_ante = 1

        G.GAME.round_resets.hands = math.max(1, (G.GAME.round_resets.hands or 4) - 2)
        G.GAME.round_resets.discards = math.max(0, (G.GAME.round_resets.discards or 3) - 2)
        G.GAME.round_resets.hand_size = math.max(1, (G.GAME.round_resets.hand_size or 8) - 3)

        if G.GAME.current_round then
            G.GAME.current_round.hands_left = G.GAME.round_resets.hands
            G.GAME.current_round.discards_left = G.GAME.round_resets.discards
        end

        G.GAME.dollars = big(0) -- CHANGED: was 0

        if G.hand and G.hand.config then
            G.hand.config.card_limit = G.GAME.round_resets.hand_size

            if G.deck then
                for i = #G.hand.cards, 1, -1 do
                    if #G.hand.cards <= G.GAME.round_resets.hand_size then break end
                    local c = G.hand:remove_card(G.hand.cards[i])
                    if c then
                        G.deck:emplace(c)
                    end
                end
            end
        end
    end

    return ret
end





SMODS.Back{
    key = "broken_deck",

    loc_txt = {
        name = "Broken Deck",
        text = {
            "Start with {C:purple}100,000{}",
            "{C:purple}Hex points{}",
        }
    },

    config = {},

    unlocked = true,
    discovered = true,

    -- NOTE: shares its atlas frame with Gambler's, Cursed, Ritualistic,
    -- Relic, Prestige, Infernal, Holy, and Hard Deck (pos 1,4), per how
    -- it was requested -- move it to an unused frame in HexEnhancers
    -- before shipping if that overlap isn't intentional, since all these
    -- decks currently render with the same sprite.
    pos = { x = 1, y = 4 },

    atlas = "HexEnhancers",
}

-- Key of Broken Deck, used the same way HEX_CURSED_DECK_KEY is used
-- above, to check which deck is currently selected.
local HEX_BROKEN_DECK_KEY = "b_" .. mod.prefix .. "_broken_deck"

local function hex_broken_deck_selected()
    return G.GAME
        and G.GAME.selected_back
        and G.GAME.selected_back.effect
        and G.GAME.selected_back.effect.center
        and G.GAME.selected_back.effect.center.key == HEX_BROKEN_DECK_KEY
end

-- Broken Deck: grants 100,000 starting Hex points, the exact same
-- mechanism (and the exact same new-run-only guard) as Cursed Deck's
-- 50-point grant above, hooked separately from that deck so the two
-- amounts never interfere with each other. We deliberately set rather
-- than add to G.GAME.hex_points here, matching Cursed Deck's own
-- assignment -- since this only ever fires on a genuinely new run (not a
-- resumed save), there's nothing pre-existing to add on top of.
local old_start_run_broken_deck = Game.start_run

function Game:start_run(args, ...)
    local ret = old_start_run_broken_deck(self, args, ...)

    if hex_broken_deck_selected() and not (args and args.savetext) then
        G.GAME.hex_points = big(100000)
    end

    return ret
end

-- Key of Gambler's Deck, used the same way HEX_NEGATIVE_DECK_KEY is used
-- above, to check which deck is currently selected.
local HEX_GAMBLERS_DECK_KEY = "b_" .. mod.prefix .. "_gamblers_deck"

local function hex_gamblers_deck_selected()
    return G.GAME
        and G.GAME.selected_back
        and G.GAME.selected_back.effect
        and G.GAME.selected_back.effect.center
        and G.GAME.selected_back.effect.center.key == HEX_GAMBLERS_DECK_KEY
end

-- Rolls a single 1-10 stat for Gambler's Deck. Each stat gets its own tag
-- so the four rolls (hands/discards/dollars/hand_size) are independent of
-- one another instead of all landing on the same number every run.
local function hex_gamblers_roll(tag)
    local n = pseudorandom(pseudoseed(mod.prefix .. "_gamblers_" .. tag), 1, 10)
    return math.max(1, math.min(10, math.floor(n)))
end

-- Gambler's Deck: rolls random starting hands, discards, money, and hand
-- size (1-10 each) once per run, and applies them on top of whatever
-- old_start_run above already set up. Hands/discards/dollars just need
-- their stored numbers overwritten, but the starting hand of cards has
-- already been dealt out of G.deck and into G.hand by the time this runs
-- (at whatever the deck's normal default hand size is), so hand size is
-- handled separately below by topping the round-1 hand up or down to match
-- the rolled size, moving any difference to/from G.deck.
local old_start_run_gamblers_deck = Game.start_run

function Game:start_run(...)
    local ret = old_start_run_gamblers_deck(self, ...)

    if hex_gamblers_deck_selected() then
        local rolled_hands = hex_gamblers_roll("hands")
        local rolled_discards = hex_gamblers_roll("discards")
        local rolled_dollars = hex_gamblers_roll("dollars")
        local rolled_hand_size = hex_gamblers_roll("hand_size")

        G.GAME.gamblers_deck_rolls = {
            hands = rolled_hands,
            discards = rolled_discards,
            dollars = rolled_dollars,
            hand_size = rolled_hand_size,
        }


        -- Hands / Discards: overwrite both the per-round baseline
        -- (round_resets, used every time a new round starts) and, if
        -- round 1's live counters already exist by this point, those too,
        -- so round 1 itself uses the rolled values instead of the usual
        -- vanilla 4 hands / 3 discards.
        G.GAME.round_resets.hands = rolled_hands
        G.GAME.round_resets.discards = rolled_discards

        if G.GAME.current_round then
            G.GAME.current_round.hands_left = rolled_hands
            G.GAME.current_round.discards_left = rolled_discards
        end

        -- Starting money: overwrite whatever old_start_run set G.GAME.dollars to.
        G.GAME.dollars = big(rolled_dollars) -- CHANGED: was rolled_dollars

        -- Hand size: overwrite the baseline used every round, then fix up
        -- the hand that's already been dealt for round 1.
        G.GAME.round_resets.hand_size = rolled_hand_size

        if G.hand and G.hand.config then
            G.hand.config.card_limit = rolled_hand_size

            local diff = rolled_hand_size - #G.hand.cards

            if diff > 0 and G.deck and #G.deck.cards > 0 then
                local to_draw = {}
                for i = 1, math.min(diff, #G.deck.cards) do
                    to_draw[#to_draw + 1] = G.deck.cards[i]
                end
                if #to_draw > 0 then
                    G.hand:draw(to_draw)
                end
            elseif diff < 0 then
                for i = #G.hand.cards, 1, -1 do
                    if #G.hand.cards <= rolled_hand_size then break end
                    local c = G.hand:remove_card(G.hand.cards[i])
                    if c and G.deck then
                        G.deck:emplace(c)
                    end
                end
            end
        end
    end

    return ret
end
-- Key of Celestial Deck, used the same way every other deck-selection
-- check in this file is built.
local HEX_CELESTIAL_DECK_KEY = "b_" .. mod.prefix .. "_celestial_deck"

local function hex_celestial_deck_selected()
    return G.GAME
        and G.GAME.selected_back
        and G.GAME.selected_back.effect
        and G.GAME.selected_back.effect.center
        and G.GAME.selected_back.effect.center.key == HEX_CELESTIAL_DECK_KEY
end

-- Celestial Deck: grants one random Star card and one random Galaxy
-- card as consumables on a genuine new run -- same new-run-only
-- savetext guard, hex_get_star_centers()/hex_get_galaxy_centers()
-- helpers (both already defined earlier in the file), and manual
-- create+emplace pattern Ritualistic Deck's own consumable grant above
-- uses. Each grant is checked against the consumable slot limit
-- independently, so if there's only room for one, the Star card is
-- granted and the Galaxy card is simply skipped rather than crashing or
-- overflowing the area.
local old_start_run_celestial_deck = Game.start_run

function Game:start_run(args, ...)
    local ret = old_start_run_celestial_deck(self, args, ...)

    if hex_celestial_deck_selected() and not (args and args.savetext) then
        if G.consumeables and #G.consumeables.cards < G.consumeables.config.card_limit then
            local stars = hex_get_star_centers()
            if #stars > 0 then
                local chosen = stars[math.random(#stars)]

                local card = SMODS.create_card({
                    key = chosen.key,
                    area = G.consumeables
                })

                G.consumeables:emplace(card)
            end
        end

        if G.consumeables and #G.consumeables.cards < G.consumeables.config.card_limit then
            local galaxies = hex_get_galaxy_centers()
            if #galaxies > 0 then
                local chosen = galaxies[math.random(#galaxies)]

                local card = SMODS.create_card({
                    key = chosen.key,
                    area = G.consumeables
                })

                G.consumeables:emplace(card)
            end
        end
    end

    return ret
end



-- Key of Black Hole Deck, used the same way every other deck-selection
-- check in this file is built.
local HEX_BLACK_HOLE_DECK_KEY = "b_" .. mod.prefix .. "_black_hole_deck"

local function hex_black_hole_deck_selected()
    return G.GAME
        and G.GAME.selected_back
        and G.GAME.selected_back.effect
        and G.GAME.selected_back.effect.center
        and G.GAME.selected_back.effect.center.key == HEX_BLACK_HOLE_DECK_KEY
end

-- Black Hole Deck: grants one random Black Hole card as a consumable on
-- a genuine new run, reusing hex_get_black_hole_centers() (already
-- defined for Local Void above), same new-run-only savetext guard and
-- manual create+emplace pattern every other consumable-granting deck in
-- this file uses.
local old_start_run_black_hole_deck = Game.start_run

function Game:start_run(args, ...)
    local ret = old_start_run_black_hole_deck(self, args, ...)

    if hex_black_hole_deck_selected() and not (args and args.savetext) then
        if G.consumeables and #G.consumeables.cards < G.consumeables.config.card_limit then
            local black_holes = hex_get_black_hole_centers()
            if #black_holes > 0 then
                local chosen = black_holes[math.random(#black_holes)]

                local card = SMODS.create_card({
                    key = chosen.key,
                    area = G.consumeables
                })

                G.consumeables:emplace(card)
            end
        end
    end

    return ret
end







-- Human-readable names for each hyperoperator level, used in the
-- Hyperbolic loc text and status messages.



-- Overstock Plus Plus (and any other +voucher-slot source) can put 2+
-- voucher slots in the shop at once, and both slots' keys can get
-- rolled before either card is actually created/emplaced -- so relying
-- on G.shop_vouchers.cards (or on the G.shop_vouchers table's own
-- identity, which turned out to be an unreliable "new shop" signal) to
-- detect duplicates doesn't work.
---- Returns every Voucher key currently eligible for the shop, minus any
-- key in `exclude`. get_current_pool already handles redeemed vouchers,
-- locked ones, and unmet `requires` prerequisites, marking them
-- 'UNAVAILABLE' rather than omitting them.
local function hex_voucher_pool_excluding(exclude)
    local pool = get_current_pool("Voucher")
    local out = {}

    for _, key in ipairs(pool or {}) do
        if key and key ~= "UNAVAILABLE" and not exclude[key] and G.P_CENTERS[key] then
            out[#out + 1] = key
        end
    end

    return out
end

local hex_voucher_dedupe_rolls = 0
local hex_old_emplace_voucher_dedupe = CardArea.emplace

function CardArea:emplace(card, ...)
    if self == G.shop_vouchers
    and card and card.config and card.config.center and card.config.center.key then

        local present = {}
        local duplicate = false

        for _, c in ipairs(self.cards) do
            local k = c.config and c.config.center and c.config.center.key
            if k then
                present[k] = true
                if k == card.config.center.key then duplicate = true end
            end
        end

        if duplicate then
            present[card.config.center.key] = true

            local eligible = hex_voucher_pool_excluding(present)

            if #eligible > 0 then
                -- Counter in the seed so a third or fourth slot doesn't
                -- re-roll into the same replacement: pseudoseed advances
                -- per key string, so a fixed string would only vary by
                -- call order, and this makes that explicit.
                hex_voucher_dedupe_rolls = hex_voucher_dedupe_rolls + 1

                local new_key = pseudorandom_element(
                    eligible,
                    pseudoseed("hex_voucher_dedupe" .. hex_voucher_dedupe_rolls)
                )

                local new_center = G.P_CENTERS[new_key]
                if new_center then
                    card:set_ability(new_center, true)
                    if card.set_cost then card:set_cost() end
                end

            else
                -- Nothing else is eligible -- every other voucher is
                -- already redeemed, locked, or behind an unmet
                -- prerequisite. Rather than showing the same voucher
                -- twice, fill the slot with vanilla's own Blank voucher
                -- ("Does nothing?", the Antimatter prerequisite).
                local blank = G.P_CENTERS.v_blank

                if blank and card.config.center.key ~= "v_blank" then
                    card:set_ability(blank, true)
                    if card.set_cost then card:set_cost() end
                end
                -- If v_blank somehow isn't registered, the duplicate
                -- stands rather than the slot breaking.
            end
        end
    end

    return hex_old_emplace_voucher_dedupe(self, card, ...)
end
-- Redeemed-vouchers Run Info tab: vanilla's own G.UIDEF.used_vouchers has
-- no paging -- once enough base/upgrade voucher pairs have been redeemed
-- in a run (all 32 vouchers = 16 pairs), the areas overflow past 5-per-
-- row/2-rows and run off the edge of the panel. This adds paging, the
-- same persistent-CardArea + create_option_cycle rebuild pattern already
-- used for Life/Manifest and the vanilla Collection Vouchers tab
-- (create_UIBox_your_collection_vouchers) elsewhere in this file.
local HEX_USED_VOUCHERS_PER_PAGE = 10 -- matches vanilla's own row-break/shrink threshold (5 per row, 2 rows)

-- Builds the flat list of base/upgrade voucher pairs that have at least
-- one redeemed voucher this run -- same grouping vanilla's own function
-- used (key = 1 + floor((k-1)/2) groups each tier-1/tier-2 pair together).
local function hex_get_used_voucher_pairs()
    local keys_used = {}
    for k, v in ipairs(G.P_CENTER_POOLS["Voucher"]) do
        local key = 1 + math.floor((k - 0.1) / 2)
        keys_used[key] = keys_used[key] or {}
        if G.GAME.used_vouchers[v.key] then
            keys_used[key][#keys_used[key] + 1] = v
        end
    end

    local pairs_list = {}
    for k, v in ipairs(keys_used) do
        if next(v) then
            pairs_list[#pairs_list + 1] = v
        end
    end

    return pairs_list
end

local function hex_used_vouchers_rebuild_page(current_option)
    if not G.hex_used_voucher_areas then return end

    local all_pairs = hex_get_used_voucher_pairs()
    local start_index = (current_option - 1) * HEX_USED_VOUCHERS_PER_PAGE

    for _, area in ipairs(G.hex_used_voucher_areas) do
        for i = #area.cards, 1, -1 do
            local c = area:remove_card(area.cards[i])
            if c then c:remove() end
        end
    end

    local silent = false
    for area_idx = 1, #G.hex_used_voucher_areas do
        local pair = all_pairs[start_index + area_idx]
        if pair then
            local area = G.hex_used_voucher_areas[area_idx]
            for _, vv in ipairs(pair) do
                local center = G.P_CENTERS[vv.key]
                local card = Card(area.T.x + area.T.w / 2, area.T.y, G.CARD_W, G.CARD_H, nil, center, {bypass_discovery_center = true, bypass_discovery_ui = true, bypass_lock = true})
                card.ability.order = vv.order
                card:start_materialize(nil, silent)
                silent = true
                area:emplace(card)
            end
        end
    end
end

G.FUNCS.hex_used_vouchers_page_change = function(args)
    if not args or not args.cycle_config then return end
    hex_used_vouchers_rebuild_page(args.cycle_config.current_option)
end

function G.UIDEF.used_vouchers()

    local all_pairs = hex_get_used_voucher_pairs()

    if not next(all_pairs) then
        return {n=G.UIT.ROOT, config={align = "cm", colour = G.C.CLEAR}, nodes={
            {n=G.UIT.O, config={object = DynaText({string = {localize('ph_no_vouchers')}, colours = {G.C.UI.TEXT_LIGHT}, bump = true, scale = 0.6})}}
        }}
    end

    local per_page = HEX_USED_VOUCHERS_PER_PAGE
    local pages = math.max(1, math.ceil(#all_pairs / per_page))
    local area_count = math.min(per_page, #all_pairs)

    G.hex_used_voucher_areas = {}
    local voucher_tables = {}
    local voucher_table_rows = {}

    for i = 1, area_count do
        local pair = all_pairs[i]
        if #G.hex_used_voucher_areas == 5 then
            table.insert(voucher_table_rows,
                {n=G.UIT.R, config={align = "cm", padding = 0, no_fill = true}, nodes=voucher_tables}
            )
            voucher_tables = {}
        end

        G.hex_used_voucher_areas[#G.hex_used_voucher_areas + 1] = CardArea(
            G.ROOM.T.x + 0.2*G.ROOM.T.w/2, G.ROOM.T.h,
            (#pair == 1 and 1 or 1.33)*G.CARD_W,
            (area_count >= 10 and 0.75 or 1.07)*G.CARD_H,
            {card_limit = 2, type = 'voucher', highlight_limit = 0})

        table.insert(voucher_tables,
            {n=G.UIT.C, config={align = "cm", padding = 0, no_fill = true}, nodes={
                {n=G.UIT.O, config={object = G.hex_used_voucher_areas[#G.hex_used_voucher_areas]}}
            }}
        )
    end
    table.insert(voucher_table_rows,
        {n=G.UIT.R, config={align = "cm", padding = 0, no_fill = true}, nodes=voucher_tables}
    )

    hex_used_vouchers_rebuild_page(1)

    local page_options = {}
    for i = 1, pages do
        page_options[#page_options + 1] = localize('k_page')..' '..tostring(i)..'/'..tostring(pages)
    end

    local nodes = {
        {n=G.UIT.R, config={align = "cm"}, nodes={
            {n=G.UIT.O, config={object = DynaText({string = {localize('ph_vouchers_redeemed')}, colours = {G.C.UI.TEXT_LIGHT}, bump = true, scale = 0.6})}}
        }},
        {n=G.UIT.R, config={align = "cm", minh = 0.5}, nodes={}},
        {n=G.UIT.R, config={align = "cm", colour = G.C.BLACK, r = 1, padding = 0.15, emboss = 0.05}, nodes={
            {n=G.UIT.R, config={align = "cm"}, nodes=voucher_table_rows},
        }}
    }

    if pages > 1 then
        table.insert(nodes, {n=G.UIT.R, config={align = "cm", padding = 0.1}, nodes={
            create_option_cycle({
                options = page_options,
                w = 4.5,
                cycle_shoulders = true,
                opt_callback = 'hex_used_vouchers_page_change',
                current_option = 1,
                colour = G.C.RED,
                no_pips = true,
                focus_args = {snap_to = true, nav = 'wide'},
            })
        }})
    end

    return {n=G.UIT.ROOT, config={align = "cm", colour = G.C.CLEAR}, nodes=nodes}
end