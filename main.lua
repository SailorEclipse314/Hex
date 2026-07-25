print("I LOVE YURI!!!!!")

-- the Steammodded version is smods-1.0.0-beta-1620a
-- ALSO arrow(1,x) is always is to the power while tetartion uses arrow(2,x)

local mod = SMODS.current_mod

mod.badge_colour = HEX("1E3A8A")



mod.optional_features = {
    quantum = true,
    object_weights = true,
}

-- Amulet (Talisman-compatible) big-number support.
-- `to_big` is provided globally by Amulet; it converts a plain number into
-- an OmegaNum (cdata) value that can scale past the double-precision limit
-- of ~1.7e308. If Amulet's OmegaNum feature is turned off, `to_big` still
-- exists but just hands the plain number back, so it's always safe to call.
-- `big()` here is just a defensive wrapper in case Amulet isn't loaded at all.
local function big(n)
    if to_big then
        return to_big(n)
    end
    return n
end

-- Converts a (possibly OmegaNum/big) value into a plain Lua number,
-- best-effort. Declared up here (not just further down near the scoring
-- calculation code) so every joker/consumable in this file -- even ones
-- defined earlier in the file, like Exponent Joker -- can safely turn a
-- big value back into a plain number wherever one is required (e.g.
-- string.format, which cannot accept OmegaNum cdata directly). Amulet's
-- OmegaNum cdata doesn't expose one single guaranteed accessor across
-- versions, so we try the common method names before falling back to
-- string parsing (tostring on an OmegaNum prints something Lua's
-- tonumber can still read, e.g. "1.23e+45").
local function hex_to_plain_number(value)
    if type(value) == "number" then
        return value
    end
    if type(value) == "table" or type(value) == "cdata" then
        if value.to_number then
            local ok, n = pcall(function() return value:to_number() end)
            if ok and type(n) == "number" then return n end
        end
        if value.toNumber then
            local ok, n = pcall(function() return value:toNumber() end)
            if ok and type(n) == "number" then return n end
        end
    end
    local n = tonumber(tostring(value))
    return n or 0
end


-- Formats a (possibly big/OmegaNum) Hex point value using Amulet's own
-- number_format function -- the same function OmegaMeta.__tostring calls
-- internally, so this is exactly what you'd get from tostring(value) on
-- a big number, just called directly rather than going through the
-- metamethod indirection.
local function hex_format_points(value)
    local big_value = value
    if to_big then
        local ok, bv = pcall(to_big, value)
        if ok and bv ~= nil then big_value = bv end
    end

    if number_format then
        local ok, result = pcall(number_format, big_value)
        if ok and type(result) == "string" then
            return result
        end
    end

    -- Fallback, only reached if number_format isn't available for some
    -- reason (e.g. Amulet not loaded) -- plain tostring still works since
    -- to_big() hands back an ordinary number in that case too.
    return tostring(big_value)
end

local function hex_format_dollars(value)
    return hex_format_points(value)
end

-- Vanilla's default cap on how many cards can be highlighted at once to
-- play or discard (G.hand.config.highlighted_limit). Used by Polydactyly
-- to restore the normal limit once it's no longer owned.
local HEX_POLY_DEFAULT_HAND_LIMIT = 5

G.C.PINK = HEX("FF69B4")

G.C.MYTHIC = HEX("1ABC9C")
G.C.TRANSCENDENTAL = HEX("6817ff")
G.C.DIVINE = HEX("ebb12a")
G.C.RITUAL = HEX("8f0d0d")
G.C.STAR = HEX("0045b5")
G.C.GALAXY = HEX("8A2BE2")
G.C.NEBULA = HEX("521652")
G.C.ASTRAL = HEX("276954")
G.C.COSMIC = HEX("6D6BC2")
G.C.BLACK_HOLE = HEX("12223B")

G.C.ABSOLUTE = {1, 0, 0, 1} -- initial color

local absolute_rainbow_time = 0

local old_update = Game.update
function Game:update(dt)
    old_update(self, dt)

    absolute_rainbow_time = absolute_rainbow_time + dt

    local hue = (absolute_rainbow_time * 0.25) % 1

    -- convert HSV -> RGB
    local i = math.floor(hue * 6)
    local f = hue * 6 - i
    local q = 1 - f

    local r, g, b

    if i % 6 == 0 then r, g, b = 1, f, 0
    elseif i == 1 then r, g, b = q, 1, 0
    elseif i == 2 then r, g, b = 0, 1, f
    elseif i == 3 then r, g, b = 0, q, 1
    elseif i == 4 then r, g, b = f, 0, 1
    elseif i == 5 then r, g, b = 1, 0, q
    end

    G.C.ABSOLUTE[1] = r
    G.C.ABSOLUTE[2] = g
    G.C.ABSOLUTE[3] = b
    G.C.ABSOLUTE[4] = 1
end



local old_loc_colour = loc_colour
function loc_colour(_c, _default)
    if _c == "mythic" then
        return G.C.MYTHIC
    end
    if _c == "transcendental" then
        return G.C.TRANSCENDENTAL
    end
    if _c == "divine" then
        return G.C.DIVINE
    end
    if _c == "absolute" then
        return G.C.ABSOLUTE
    end
    if _c == "ritual" then
        return G.C.RITUAL
    end
    if _c == "star" then
        return G.C.STAR
    end
    if _c == "galaxy" then
        return G.C.GALAXY
    end
    if _c == "nebula" then
        return G.C.NEBULA
    end
    if _c == "astral" then
        return G.C.ASTRAL
    end
    if _c == "cosmic" then
        return G.C.COSMIC
    end
    if _c == "black_hole" then
        return G.C.BLACK_HOLE
    end
    if _c == "pink" then
        return G.C.PINK
    end
    return old_loc_colour(_c, _default)
end


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


local R_HEX_MYTHIC = SMODS.Rarity{
    key = "hex_mythic",
    loc_txt = {
        name = "Mythic"
    },
    default_weight = 0.0001,
    badge_colour = G.C.MYTHIC
}

local R_HEX_TRANSCENDENTAL = SMODS.Rarity{
    key = "hex_transcendental",
    loc_txt = {
        name = "Transcendental"
    },
    default_weight = 0.00001, -- rarer than mythic (0.0001) — tune as you like
    badge_colour = G.C.TRANSCENDENTAL
}


local R_HEX_DIVINE = SMODS.Rarity{
    key = "hex_divine",
    loc_txt = {
        name = "Divine"
    },
    default_weight = 0.000001, -- rarer than mythic (0.0001) — tune as you like
    badge_colour = G.C.DIVINE
}


local R_HEX_ABSOLUTE = SMODS.Rarity{
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

local function hex_set_hand_stat(hand_key, stat, new_value)
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









-- ============================================================
-- New Planet cards: hand-specific Chips/Mult levelers & multipliers
-- ============================================================
-- Two shared factories cover every card below:
--   hex_make_level_planet  -- adds a flat number of levels to one
--                              specific hand, via vanilla's own
--                              level_up_hand (same call Vega/Canopus/
--                              Hoag's Object already use elsewhere in
--                              this file).
--   hex_make_stat_planet   -- permanently multiplies one specific
--                              hand's base Chips and/or Mult by a fixed
--                              factor, applied directly to
--                              G.GAME.hands[key].chips/.mult -- same
--                              live-mutation approach Polaris already
--                              uses above, just scoped to one hand
--                              instead of every hand, and via three
--                              possible operations:
--                                op = "mult"    -> plain X<factor> multiply
--                                op = "pow"     -> arrow(1, factor), i.e. ^factor
--                                op = "tetrate" -> arrow(2, factor), i.e. ^^factor
--                              (Per the note at the very top of this file:
--                              arrow(1,x) is always "to the power", while
--                              tetration is arrow(2,x) -- NOT the arrow(1)=
--                              multiply/arrow(2)=power mapping documented
--                              on Absolute's hyperoperator calculation
--                              further down; that comment describes a
--                              different, unrelated system.)
--
-- Every card here stacks uncapped with repeated uses, the same way
-- Polaris's own repeated-use multiply already does -- there's no
-- separate persistent-counter field being tracked, just the live
-- hand.chips/.mult value being multiplied again each time.
-- ============================================================

local function hex_planet_apply_stat(hand_key, stat, op, factor)
    if not (G.GAME and G.GAME.hands and G.GAME.hands[hand_key]) then return end

    local hand = G.GAME.hands[hand_key]
    local current = hand[stat]
    if not current then return end

    if op == "mult" then
        hex_set_hand_stat(hand_key, stat, to_big(current):mul(big(factor))) -- CHANGED: was * big(factor)
    elseif op == "pow" then
        hex_set_hand_stat(hand_key, stat, to_big(current):arrow(1, factor))
    elseif op == "tetrate" then
        hex_set_hand_stat(hand_key, stat, to_big(current):arrow(2, factor))
    end
end

-- args: key, name, hand_key, levels, atlas, pos, text
local function hex_make_level_planet(args)
    -- Only planets targeting one of THIS mod's own custom poker hands
    -- (three pair, dual three of a kind, grand house, N of a Kind, etc.
    -- -- every custom SMODS.PokerHand key in this file is prefixed with
    -- mod.prefix) get a Telescope-matchable hand_type. The vanilla-hand
    -- reuses of this same factory (Full House, Flush, Straight, Two Pair,
    -- Straight Flush, High Card, Flush Five, Flush House) are left with
    -- no config at all, so Telescope keeps picking vanilla's own real
    -- Planet card for those hands exactly as before.
    local is_custom_hand = tostring(args.hand_key):sub(1, #(mod.prefix .. "_")) == (mod.prefix .. "_")

    SMODS.Consumable{
        key = args.key,
        set = "Planet",
        weight = 0.1,
        set_badges = args.set_badges,

        atlas = args.atlas,
        pos = args.pos,

        unlocked = true,
        discovered = true,

        in_pool = function(self) return true end,
        in_pool = args.in_pool or function(self) return true end,

        -- CHANGED: stamps hand_type so vanilla Telescope's own search
        -- (`v.config.hand_type == _hand`) can find this card when the
        -- player's most-played hand is this custom poker hand.
        config = is_custom_hand and { hand_type = args.hand_key } or nil,

        loc_txt = {
            name = args.name,
            text = args.text,
        },

        can_use = function(self, card)
            return true
        end,

        use = function(self, card)
            level_up_hand(card, args.hand_key, nil, args.levels)

            card_eval_status_text(card, "extra", nil, nil, nil, {
                message = "+" .. tostring(args.levels) .. " Levels",
                colour = G.C.STAR
            })
        end,
    }
end

-- args: key, name, hand_key, stats (list of "chips"/"mult"), op, factor,
-- atlas, pos, text, status_message
local function hex_make_stat_planet(args)
    SMODS.Consumable{
        key = args.key,
        set = "Planet",
        weight = 0.1,
        set_badges = args.set_badges,

        atlas = args.atlas,
        pos = args.pos,

        unlocked = true,
        discovered = true,

        in_pool = function(self) return true end,
        in_pool = args.in_pool or function(self) return true end,
        
        loc_txt = {
            name = args.name,
            text = args.text,
        },

        can_use = function(self, card)
            return true
        end,

        use = function(self, card)
            for _, stat in ipairs(args.stats) do
                hex_planet_apply_stat(args.hand_key, stat, args.op, args.factor)
            end

            card_eval_status_text(card, "extra", nil, nil, nil, {
                message = args.status_message,
                colour = (#args.stats == 1 and args.stats[1] == "chips") and G.C.CHIPS or G.C.MULT
            })
        end,
    }
end


-- Returns an in_pool function that only allows this card to appear once
-- the given (mod-prefixed) hand key has been played at least once this
-- run. Used for the "only shows up when you have played this hand" cards.
local function hex_hand_played_check(hand_key)
    return function(self)
        return G.GAME
            and G.GAME.hands
            and G.GAME.hands[hand_key]
            and (G.GAME.hands[hand_key].played or 0) > 0
    end
end


-- ---- Full House ----

hex_make_level_planet{
    key = "the_moon",
    name = "The Moon",
    hand_key = "Full House",
    levels = 2,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 0, y = 0 }, -- placeholder art slot, adjust before shipping
    text = {
        "Upgrades {C:attention}Full House{}",
        "by {C:attention}2{} levels",
    },
}


-- ---- Four of a Kind ----

hex_make_stat_planet{
    key = "phobos",
    name = "Phobos",
    hand_key = "Four of a Kind",
    stats = { "chips" },
    op = "mult",
    factor = 1.75,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 1, y = 0 },
    text = {
        "Upgrades {C:attention}Four of a Kind{}",
        "{C:chips}Chips{} by {C:chips}X1.75{}",
    },
    status_message = "X1.75 Chips",
}

hex_make_stat_planet{
    key = "deimos",
    name = "Deimos",
    hand_key = "Four of a Kind",
    stats = { "mult" },
    op = "mult",
    factor = 1.75,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 2, y = 0 },
    text = {
        "Upgrades {C:attention}Four of a Kind{}",
        "{C:mult}Mult{} by {C:mult}X1.75{}",
    },
    status_message = "X1.75 Mult",
}


-- ---- Flush House ----

hex_make_level_planet{
    key = "vesta",
    name = "Vesta",
    hand_key = "Flush House",
    levels = 2,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Asteroid", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 3, y = 0 },
    in_pool = hex_hand_played_check("Flush House"),
    text = {
        "Upgrades {C:attention}Flush House{}",
        "by {C:attention}2{} levels",
    },
}

hex_make_stat_planet{
    key = "pallas",
    name = "Pallas",
    hand_key = "Flush House",
    stats = { "chips" },
    op = "mult",
    factor = 1.75,
    atlas = "HexPlanets",
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Asteroid", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    pos = { x = 4, y = 0 },
    in_pool = hex_hand_played_check("Flush House"),
    text = {
        "Upgrades {C:attention}Flush House{}",
        "{C:chips}Chips{} by {C:chips}X1.75{}",
    },
    status_message = "X1.75 Chips",
}

hex_make_stat_planet{
    key = "hygiea",
    name = "Hygiea",
    hand_key = "Flush House",
    stats = { "mult" },
    op = "mult",
    factor = 1.75,
    atlas = "HexPlanets",
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Asteroid", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    pos = { x = 5, y = 0 },
    in_pool = hex_hand_played_check("Flush House"),
    text = {
        "Upgrades {C:attention}Flush House{}",
        "{C:mult}Mult{} by {C:mult}X1.75{}",
    },
    status_message = "X1.75 Mult",
}


-- ---- Flush ----

hex_make_level_planet{
    key = "io",
    name = "Io",
    hand_key = "Flush",
    levels = 2,
    atlas = "HexPlanets",
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    pos = { x = 6, y = 0 },
    text = {
        "Upgrades {C:attention}Flush{}",
        "by {C:attention}2{} levels",
    },
}

hex_make_stat_planet{
    key = "europa",
    name = "Europa",
    hand_key = "Flush",
    stats = { "chips" },
    op = "mult",
    factor = 1.75,
    atlas = "HexPlanets",
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    pos = { x = 7, y = 0 },
    text = {
        "Upgrades {C:attention}Flush{}",
        "{C:chips}Chips{} by {C:chips}X1.75{}",
    },
    status_message = "X1.75 Chips",
}

hex_make_stat_planet{
    key = "ganymede",
    name = "Ganymede",
    hand_key = "Flush",
    stats = { "mult" },
    op = "mult",
    factor = 1.75,
    atlas = "HexPlanets",
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    pos = { x = 8, y = 0 },
    text = {
        "Upgrades {C:attention}Flush{}",
        "{C:mult}Mult{} by {C:mult}X1.75{}",
    },
    status_message = "X1.75 Mult",
}

hex_make_stat_planet{
    key = "callisto",
    name = "Callisto",
    hand_key = "Flush",
    stats = { "chips", "mult" },
    op = "mult",
    factor = 1.5,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 9, y = 0 },
    text = {
        "Upgrades {C:attention}Flush{}",
        "{C:chips}Chips{} and {C:mult}Mult{}",
        "by {C:attention}X1.5{}",
    },
    status_message = "X1.5 Chips/Mult",
}

hex_make_stat_planet{
    key = "amalthea",
    name = "Amalthea",
    hand_key = "Flush",
    stats = { "chips", "mult" },
    op = "pow",
    factor = 1.1,
    atlas = "HexPlanets",
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    pos = { x = 0, y = 1 },
    text = {
        "Upgrades {C:attention}Flush{}",
        "{C:chips}Chips{} and {C:mult}Mult{}",
        "by {C:attention}^1.1{}",
    },
    status_message = "^1.1 Chips/Mult",
}


-- ---- Straight ----

hex_make_level_planet{
    key = "mimas",
    name = "Mimas",
    hand_key = "Straight",
    levels = 2,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 1, y = 1 },
    text = {
        "Upgrades {C:attention}Straight{}",
        "by {C:attention}2{} levels",
    },
}

hex_make_stat_planet{
    key = "enceladus",
    name = "Enceladus",
    hand_key = "Straight",
    stats = { "chips" },
    op = "mult",
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    factor = 1.75,
    atlas = "HexPlanets",
    pos = { x = 2, y = 1 },
    text = {
        "Upgrades {C:attention}Straight{}",
        "{C:chips}Chips{} by {C:chips}X1.75{}",
    },
    status_message = "X1.75 Chips",
}

hex_make_stat_planet{
    key = "tethys",
    name = "Tethys",
    hand_key = "Straight",
    stats = { "mult" },
    op = "mult",
    factor = 1.75,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 3, y = 1 },
    text = {
        "Upgrades {C:attention}Straight{}",
        "{C:mult}Mult{} by {C:mult}X1.75{}",
    },
    status_message = "X1.75 Mult",
}

hex_make_stat_planet{
    key = "dione",
    name = "Dione",
    hand_key = "Straight",
    stats = { "chips", "mult" },
    op = "mult",
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    factor = 1.5,
    atlas = "HexPlanets",
    pos = { x = 4, y = 1 },
    text = {
        "Upgrades {C:attention}Straight{}",
        "{C:chips}Chips{} and {C:mult}Mult{}",
        "by {C:attention}X1.5{}",
    },
    status_message = "X1.5 Chips/Mult",
}

hex_make_stat_planet{
    key = "rhea",
    name = "Rhea",
    hand_key = "Straight",
    stats = { "chips", "mult" },
    op = "pow",
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    factor = 1.1,
    atlas = "HexPlanets",
    weight = 0.1,
    pos = { x = 5, y = 1 },
    text = {
        "Upgrades {C:attention}Straight{}",
        "{C:chips}Chips{} and {C:mult}Mult{}",
        "by {C:attention}^1.1{}",
    },
    status_message = "^1.1 Chips/Mult",
}

hex_make_stat_planet{
    key = "titan",
    name = "Titan",
    hand_key = "Straight",
    stats = { "mult" },
    op = "mult",
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    factor = 2,
    atlas = "HexPlanets",
    pos = { x = 6, y = 1 },
    text = {
        "Upgrades {C:attention}Straight{}",
        "{C:mult}Mult{} by {C:mult}X2{}",
    },
    status_message = "X2 Mult",
}

hex_make_stat_planet{
    key = "iapetus",
    name = "Iapetus",
    hand_key = "Straight",
    stats = { "chips" },
    op = "mult",
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    factor = 2,
    atlas = "HexPlanets",
    pos = { x = 7, y = 1 },
    text = {
        "Upgrades {C:attention}Straight{}",
        "{C:chips}Chips{} by {C:chips}X2{}",
    },
    status_message = "X2 Chips",
}


-- ---- Two Pair ----

hex_make_level_planet{
    key = "ariel",
    name = "Ariel",
    hand_key = "Two Pair",
    levels = 2,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 8, y = 1 },
    text = {
        "Upgrades {C:attention}Two Pair{}",
        "by {C:attention}2{} levels",
    },
}

hex_make_stat_planet{
    key = "umbriel",
    name = "Umbriel",
    hand_key = "Two Pair",
    stats = { "mult" },
    op = "mult",
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    factor = 1.75,
    atlas = "HexPlanets",
    pos = { x = 9, y = 1 },
    text = {
        "Upgrades {C:attention}Two Pair{}",
        "{C:mult}Mult{} by {C:mult}X1.75{}",
    },
    status_message = "X1.75 Mult",
}

hex_make_stat_planet{
    key = "titania",
    name = "Titania",
    hand_key = "Two Pair",
    stats = { "chips" },
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    op = "mult",
    weight = 0.1,
    factor = 1.75,
    atlas = "HexPlanets",
    pos = { x = 0, y = 2 },
    text = {
        "Upgrades {C:attention}Two Pair{}",
        "{C:chips}Chips{} by {C:chips}X1.75{}",
    },
    status_message = "X1.75 Chips",
}

hex_make_stat_planet{
    key = "oberon",
    name = "Oberon",
    hand_key = "Two Pair",
    stats = { "chips", "mult" },
    op = "mult",
    factor = 1.5,
    atlas = "HexPlanets",
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    pos = { x = 1, y = 2 },
    text = {
        "Upgrades {C:attention}Two Pair{}",
        "{C:chips}Chips{} and {C:mult}Mult{}",
        "by {C:attention}X1.5{}",
    },
    status_message = "X1.5 Chips/Mult",
}

hex_make_stat_planet{
    key = "miranda",
    name = "Miranda",
    hand_key = "Two Pair",
    stats = { "chips", "mult" },
    op = "pow",
    factor = 1.1,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 2, y = 2 },
    text = {
        "Upgrades {C:attention}Two Pair{}",
        "{C:chips}Chips{} and {C:mult}Mult{}",
        "by {C:attention}^1.1{}",
    },
    status_message = "^1.1 Chips/Mult",
}


-- ---- Straight Flush ----

hex_make_level_planet{
    key = "triton",
    name = "Triton",
    hand_key = "Straight Flush",
    levels = 2,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 3, y = 2 },
    text = {
        "Upgrades {C:attention}Straight Flush{}",
        "by {C:attention}2{} levels",
    },
}

hex_make_stat_planet{
    key = "nereid",
    name = "Nereid",
    hand_key = "Straight Flush",
    stats = { "chips" },
    op = "mult",
    factor = 1.75,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 4, y = 2 },
    text = {
        "Upgrades {C:attention}Straight Flush{}",
        "{C:chips}Chips{} by {C:chips}X1.75{}",
    },
    status_message = "X1.75 Chips",
}

hex_make_stat_planet{
    key = "naiad",
    name = "Naiad",
    hand_key = "Straight Flush",
    stats = { "mult" },
    op = "mult",
    factor = 1.75,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 5, y = 2 },
    text = {
        "Upgrades {C:attention}Straight Flush{}",
        "{C:mult}Mult{} by {C:mult}X1.75{}",
    },
    status_message = "X1.75 Mult",
}

hex_make_stat_planet{
    key = "thalassa",
    name = "Thalassa",
    hand_key = "Straight Flush",
    stats = { "chips", "mult" },
    op = "mult",
    factor = 1.5,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 6, y = 2 },
    text = {
        "Upgrades {C:attention}Straight Flush{}",
        "{C:chips}Chips{} and {C:mult}Mult{}",
        "by {C:attention}X1.5{}",
    },
    status_message = "X1.5 Chips/Mult",
}

hex_make_stat_planet{
    key = "despina",
    name = "Despina",
    hand_key = "Straight Flush",
    stats = { "chips", "mult" },
    op = "pow",
    factor = 1.1,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 7, y = 2 },
    text = {
        "Upgrades {C:attention}Straight Flush{}",
        "{C:chips}Chips{} and {C:mult}Mult{}",
        "by {C:attention}^1.1{}",
    },
    status_message = "^1.1 Chips/Mult",
}


-- ---- High Card ----

hex_make_stat_planet{
    key = "charon",
    name = "Charon",
    hand_key = "High Card",
    stats = { "mult" },
    op = "mult",
    factor = 1.75,
    weight = 0.1,
    atlas = "HexPlanets",
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    pos = { x = 8, y = 2 },
    text = {
        "Upgrades {C:attention}High Card{}",
        "{C:mult}Mult{} by {C:mult}X1.75{}",
    },
    status_message = "X1.75 Mult",
}

hex_make_stat_planet{
    key = "nix",
    name = "Nix",
    hand_key = "High Card",
    stats = { "chips" },
    op = "mult",
    factor = 1.75,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 9, y = 2 },
    text = {
        "Upgrades {C:attention}High Card{}",
        "{C:chips}Chips{} by {C:chips}X1.75{}",
    },
    status_message = "X1.75 Chips",
}

hex_make_level_planet{
    key = "hydra",
    name = "Hydra",
    hand_key = "High Card",
    levels = 2,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 0, y = 3 },
    text = {
        "Upgrades {C:attention}High Card{}",
        "by {C:attention}2{} levels",
    },
}

hex_make_stat_planet{
    key = "kerberos",
    name = "Kerberos",
    hand_key = "High Card",
    stats = { "chips", "mult" },
    op = "mult",
    factor = 1.5,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 1, y = 3 },
    text = {
        "Upgrades {C:attention}High Card{}",
        "{C:chips}Chips{} and {C:mult}Mult{}",
        "by {C:attention}X1.5{}",
    },
    status_message = "X1.5 Chips/Mult",
}

hex_make_stat_planet{
    key = "styx",
    name = "Styx",
    hand_key = "High Card",
    stats = { "chips", "mult" },
    op = "pow",
    factor = 1.1,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 2, y = 3 },
    text = {
        "Upgrades {C:attention}High Card{}",
        "{C:chips}Chips{} and {C:mult}Mult{}",
        "by {C:attention}^1.1{}",
    },
    status_message = "^1.1 Chips/Mult",
}


-- ---- Flush Five ----

hex_make_stat_planet{
    key = "orcus",
    name = "Orcus",
    hand_key = "Flush Five",
    stats = { "chips" },
    op = "mult",
    factor = 1.75,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Dwarf Planet", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 3, y = 3 },
    in_pool = hex_hand_played_check("Flush Five"),
    text = {
        "Upgrades {C:attention}Flush Five{}",
        "{C:chips}Chips{} by {C:chips}X1.75{}",
    },
    status_message = "X1.75 Chips",
}

hex_make_stat_planet{
    key = "haumea",
    name = "Haumea",
    hand_key = "Flush Five",
    stats = { "mult" },
    op = "mult",
    factor = 1.75,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Dwarf Planet", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 4, y = 3 },
    in_pool = hex_hand_played_check("Flush Five"),
    text = {
        "Upgrades {C:attention}Flush Five{}",
        "{C:mult}Mult{} by {C:mult}X1.75{}",
    },
    status_message = "X1.75 Mult",
}

hex_make_level_planet{
    key = "dysnomia",
    name = "Dysnomia",
    hand_key = "Flush Five",
    levels = 2,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Moon", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 5, y = 3 },
    in_pool = hex_hand_played_check("Flush Five"),
    text = {
        "Upgrades {C:attention}Flush Five{}",
        "by {C:attention}2{} levels",
    },
}


-- ---- Custom hex hands (only appear once played) ----

hex_make_level_planet{
    key = "quaoar",
    name = "Quaoar",
    hand_key = mod.prefix .. "_dual_three_of_a_kind",
    levels = 1,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Dwarf Planet", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 6, y = 3 },
    in_pool = hex_hand_played_check(mod.prefix .. "_dual_three_of_a_kind"),
    text = {
        "Upgrades {C:attention}Dual Three",
        "of a Kind{} by {C:attention}1{} level",
    },
}

hex_make_level_planet{
    key = "makemake",
    name = "Makemake",
    hand_key = mod.prefix .. "_flush_dual_three_of_a_kind",
    levels = 1,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Dwarf Planet", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 7, y = 3 },
    in_pool = hex_hand_played_check(mod.prefix .. "_flush_dual_three_of_a_kind"),
    text = {
        "Upgrades {C:attention}Flush Dual Three",
        "of a Kind{} by {C:attention}1{} level",
    },
}

hex_make_level_planet{
    key = "gonggong",
    name = "Gonggong",
    hand_key = mod.prefix .. "_grand_house",
    levels = 1,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Dwarf Planet", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 8, y = 3 },
    in_pool = hex_hand_played_check(mod.prefix .. "_grand_house"),
    text = {
        "Upgrades {C:attention}Grand House{}",
        "by {C:attention}1{} level",
    },
}

hex_make_level_planet{
    key = "sedna",
    name = "Sedna",
    hand_key = mod.prefix .. "_flush_grand_house",
    levels = 1,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Dwarf Planet", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 9, y = 3 },
    in_pool = hex_hand_played_check(mod.prefix .. "_flush_grand_house"),
    text = {
        "Upgrades {C:attention}Flush Grand House{}",
        "by {C:attention}1{} level",
    },
}

hex_make_level_planet{
    key = "comet_shoemaker_levy_9",
    name = "Comet Shoemaker-Levy 9",
    hand_key = mod.prefix .. "_three_pair",
    levels = 1,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Comet", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 1, y = 4 },
    in_pool = hex_hand_played_check(mod.prefix .. "_three_pair"),
    text = {
        "Upgrades {C:attention}Three Pair{}",
        "by {C:attention}1{} level",
    },
}

hex_make_level_planet{
    key = "hale_bopp_comet",
    name = "Hale-Bopp Comet",
    hand_key = mod.prefix .. "_four_pair",
    levels = 1,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Comet", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 2, y = 4 },
    in_pool = hex_hand_played_check(mod.prefix .. "_four_pair"),
    text = {
        "Upgrades {C:attention}Four Pair{}",
        "by {C:attention}1{} level",
    },
}

hex_make_level_planet{
    key = "oumuamua",
    name = "Oumuamua",
    hand_key = mod.prefix .. "_flush_three_pair",
    levels = 1,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Comet", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 3, y = 4 },
    in_pool = hex_hand_played_check(mod.prefix .. "_flush_three_pair"),
    text = {
        "Upgrades {C:attention}Flush Three Pair{}",
        "by {C:attention}1{} level",
    },
}

hex_make_level_planet{
    key = "comet_lovejoy",
    name = "Comet Lovejoy",
    hand_key = mod.prefix .. "_flush_four_pair",
    levels = 1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Comet", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    weight = 0.1,
    atlas = "HexPlanets",
    pos = { x = 4, y = 4 },
    in_pool = hex_hand_played_check(mod.prefix .. "_flush_four_pair"),
    text = {
        "Upgrades {C:attention}Flush Four Pair{}",
        "by {C:attention}1{} level",
    },
}

hex_make_level_planet{
    key = "bennu",
    name = "Bennu",
    hand_key = mod.prefix .. "_n_of_a_kind",
    levels = 1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Comet", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    weight = 0.1,
    atlas = "HexPlanets",
    pos = { x = 5, y = 4 },
    in_pool = hex_hand_played_check(mod.prefix .. "_n_of_a_kind"),
    text = {
        "Upgrades {C:attention}N of a Kind{}",
        "by {C:attention}1{} level",
    },
}

hex_make_level_planet{
    key = "arrokoth",
    name = "Arrokoth",
    hand_key = mod.prefix .. "_flush_n",
    levels = 1,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Comet", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,
    atlas = "HexPlanets",
    pos = { x = 6, y = 4 },
    in_pool = hex_hand_played_check(mod.prefix .. "_flush_n"),
    text = {
        "Upgrades {C:attention}Flush N{}",
        "by {C:attention}1{} level",
    },
}


-- ---- None ----
-- Not multiplicative like the others -- a flat +1/+1 bump straight onto
-- G.GAME.hands[key].chips/.mult, wrapped in to_big()/big() the same way
-- the rest of the file wraps Amulet-scaled fields.
SMODS.Consumable{
    key = "halleys_comet",
    set = "Planet",

    atlas = "HexPlanets",
    pos = { x = 0, y = 4 },

    unlocked = true,
    discovered = true,
    weight = 0.1,
    set_badges = function(self, card, badges)
        badges[1] = create_badge("Comet", G.C.SECONDARY_SET["Planet"], nil, 1.2)
    end,

    -- CHANGED: added so Telescope's own search (`v.config.hand_type ==
    -- _hand`) can find this card when the player's most-played hand is
    -- "None" (0 cards played) -- same reasoning as hex_make_level_planet's
    -- own hand_type stamp above.
    config = { hand_type = mod.prefix .. "_none" },

    in_pool = function(self) return true end,

    loc_txt = {
        name = "Halley's Comet",
        text = {
            "Upgrades {C:attention}None{}",
            "by {C:chips}+1{} Chips and",
            "{C:mult}+1{} Mult",
        },
    },
    weight = 0.1,

    can_use = function(self, card)
        return true
    end,

    in_pool = hex_hand_played_check(mod.prefix .. "_none"),

    use = function(self, card)
        local hand_key = mod.prefix .. "_none"
        local hand = G.GAME and G.GAME.hands and G.GAME.hands[hand_key]

        if hand then
            hand.chips = to_big(hand.chips or 0) + big(1)
            hand.mult = to_big(hand.mult or 0) + big(1)
        end

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+1 Chips/Mult",
            colour = G.C.BLUE
        })
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
            "{C:green}1 in 2{} chance to give",
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

    calculate = function(self, card, context)
        if context.main_scoring and context.cardarea == G.play then
            if pseudorandom(pseudoseed(mod.prefix .. "_crystal_" .. tostring(card.sort_id or card))) < 0.5 then
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
local function hex_count_diamond_cards()
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
        if context.repetition and context.cardarea == G.play then
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
        if context.repetition and context.cardarea == G.play then
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
        if context.repetition and context.cardarea == G.play then
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














-- Colour used for the Immortal sticker's badge/description text, the
-- same way G.C.HEX_ORANGE_SEAL/HEX_GREEN_SEAL/HEX_PINK_SEAL/
-- HEX_BLACK_SEAL were defined above for their respective Seals.
G.C.HEX_IMMORTAL = HEX("E8E8E8")

-- The full, mod-prefixed key this sticker is actually stored/checked
-- under on a card's `ability` table (card.ability[HEX_IMMORTAL_STICKER_KEY]).
-- Declared once, up here, so both the sticker's own registration below
-- and every other piece of code that needs to apply or check for it
-- later in the file (the Card.start_dissolve hook, and Absolute's own
-- summon function) all stay in sync automatically.
local HEX_IMMORTAL_STICKER_KEY = mod.prefix .. "_immortal"

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
local function hex_apply_immortal_sticker(card)
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
local HEX_SOUL_CENTER_KEY = "c_soul" -- vanilla's own Soul card
local HEX_HEART_CENTER_KEY = "c_" .. mod.prefix .. "_heart"

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
            "{C:inactive}(Half as often as{}",
            "{C:inactive}Spectral packs){}",
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
            "{C:inactive}(Half as often as{}",
            "{C:inactive}Star Packs){}",
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
local HEX_ALTAIR_BASE_RATE = 0.003

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
local HEX_STAR_PACK_CHANCE = 1 / 33


local HEX_STAR_PACK_CHANCE = 1 / 33

local function hex_owns_showman()
    return SMODS.find_card and #SMODS.find_card("j_showman") > 0
end

-- Checks whether a Star (or any) consumable with this exact key is
-- currently sitting in the player's consumable slots.
local function hex_consumable_already_owned(key)
    if not (G.consumeables and G.consumeables.cards) then return false end
    for _, c in ipairs(G.consumeables.cards) do
        if c.config and c.config.center and c.config.center.key == key then
            return true
        end
    end
    return false
end

local function hex_get_star_centers()
    local out = {}
    local showman = hex_owns_showman()

    local toi_125_key = "c_" .. mod.prefix .. "_toi_125"
    local vy_key = "c_" .. mod.prefix .. "_vy_canis_majoris"

    for _, center in pairs(G.P_CENTERS) do
        if center.set == "star" then
            local skip = false

            if center.key == toi_125_key
            and G.GAME and G.GAME.hex_toi_125_used then
                skip = true
            end

            if center.key == vy_key then
                if not (G.GAME and G.GAME.hex_vy_unlocked) then
                    skip = true
                end
                if G.GAME and G.GAME.hex_vy_used then
                    skip = true
                end
            end

            if not skip and not showman and hex_consumable_already_owned(center.key) then
                skip = true
            end

            if not skip then
                out[#out + 1] = center
            end
        end
    end
    return out
end


local HEX_GALAXY_PACK_CHANCE = 1 / 66
local HEX_GALAXY_IN_STARPACK_CHANCE = 1 / 33
local HEX_SMC_CENTER_KEY = "c_" .. mod.prefix .. "_small_magellanic_cloud"
local HEX_LMC_CENTER_KEY = "c_" .. mod.prefix .. "_large_magellanic_cloud"
local function hex_get_galaxy_centers()
    local out = {}

    for _, center in pairs(G.P_CENTERS) do
        if center.set == "galaxy" then
            local skip = false

            -- Respect each center's own in_pool -- this is what actually
            -- catches Sculptor Galaxy (in_pool = false once Astral is
            -- unlocked) and generically covers any future single-use
            -- unlock card the same way, instead of needing a new
            -- hardcoded key check added here every time. Small/Large
            -- Magellanic Cloud's own in_pool functions already say the
            -- exact same thing the manual checks below say, so this
            -- alone would cover those too -- the manual checks are kept
            -- as a redundant safety net rather than removed.
            if center.in_pool and not center.in_pool(center) then
                skip = true
            end

            if center.key == HEX_SMC_CENTER_KEY
            and G.GAME and G.GAME.hex_smc_used then
                skip = true
            end

            if center.key == HEX_LMC_CENTER_KEY then
                if not (G.GAME and G.GAME.hex_lmc_unlocked) then
                    skip = true
                end
                if G.GAME and G.GAME.hex_lmc_used then
                    skip = true
                end
            end

            if not skip then
                out[#out + 1] = center
            end
        end
    end

    return out
end

local HEX_NEBULA_IN_GALAXYPACK_CHANCE = 1 / 25

local function hex_get_nebula_centers()
    local out = {}
    local showman = hex_owns_showman()

    for _, center in pairs(G.P_CENTERS) do
        if center.set == "nebula" then
            local skip = false

            if not showman and hex_consumable_already_owned(center.key) then
                skip = true
            end

            if not skip then
                out[#out + 1] = center
            end
        end
    end

    return out
end


local HEX_ASTRAL_IN_PACK_CHANCE = 1 / 33

local function hex_get_astral_centers()
    local out = {}
    local showman = hex_owns_showman()

    for _, center in pairs(G.P_CENTERS) do
        if center.set == "astral" then
            local skip = false

            if not showman and hex_consumable_already_owned(center.key) then
                skip = true
            end

            if not skip then
                out[#out + 1] = center
            end
        end
    end

    return out
end

local HEX_COSMIC_IN_PACK_CHANCE = 1 / 33

local function hex_get_cosmic_centers()
    local out = {}
    local showman = hex_owns_showman()

    for _, center in pairs(G.P_CENTERS) do
        if center.set == "cosmic" then
            local skip = false

            if not showman and hex_consumable_already_owned(center.key) then
                skip = true
            end

            if not skip then
                out[#out + 1] = center
            end
        end
    end

    return out
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
local HEX_SHOP_ENHANCED_ALLOWED = {
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
local function hex_apply_negative_boosts(card)
    if not (card and card.edition == nil) then return end

    local mult = hex_negative_boost_multiplier()
    if mult <= 1 then return end

    local chance = math.min(1, HEX_ALTAIR_BASE_RATE * mult)

    if pseudorandom(pseudoseed(mod.prefix .. "_negative_boost")) < chance then
        card:set_edition({ negative = true }, true)
    end
end






-- Base chance for an individual shop consumable slot to be replaced with
-- a Star card instead, once Hypernova has been bought. Kept independent
-- of HEX_STAR_PACK_CHANCE (packs show several cards at once; the shop
-- only ever has a couple of consumable slots showing at any moment), so
-- tune this on its own if Star cards feel too rare/common in the shop.
local HEX_STAR_SHOP_CHANCE = 1 / 10




-- Hypernova: intercept at the moment a card is actually added to the
-- shop's consumable/joker row, rather than trying to catch it inside
-- create_card -- shop consumable slots don't necessarily route through
-- our create_card hook the same way other card creation does, so
-- hooking CardArea:emplace directly is the reliable point that catches
-- a Tarot/Planet/Spectral card no matter how it was actually built.
local old_cardarea_emplace_hypernova = CardArea.emplace

function CardArea:emplace(card, ...)
    if self == G.shop_jokers and card and card.ability and card.ability.set then

        if (card.ability.set == "Tarot" or card.ability.set == "Planet" or card.ability.set == "Spectral")
        and G.GAME and G.GAME.hex_hypernova_unlocked
        and pseudorandom(pseudoseed(mod.prefix .. "_hypernova_shop")) < HEX_STAR_SHOP_CHANCE then

            local stars = hex_get_star_centers()
            if #stars > 0 then
                local chosen_key = stars[math.random(#stars)].key
                local chosen_center = G.P_CENTERS[chosen_key]

                if chosen_center then
                    card:set_ability(chosen_center, true)

                    if card.set_cost then
                        card:set_cost()
                    end
                end
            end
        end

        -- Negative Deck / Altair / Negative Bunch / Negative Cluster:
        -- shop-added Jokers don't reliably route through the create_card
        -- hook the same way other card creation does (same category of
        -- quirk the Hypernova Star injection above already works around),
        -- so catch them here too, the reliable way.
        if card.ability.set == "Joker" then
            hex_apply_negative_boosts(card)
        end
    end

    return old_cardarea_emplace_hypernova(self, card, ...)
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


    -- Heart: soul_rate/soul_set alone isn't reliably picked up by this
    -- build's own soul-injection logic (same category of issue Star/Galaxy
    -- cards work around by being force-injected here instead of trusting a
    -- similar automatic mechanism) -- so Heart gets the same manual
    -- injection treatment. Uses the center's own soul_rate field directly
    -- as the roll chance, so Mythic Heart's voucher (which multiplies that
    -- same field) still scales it correctly.
    if (_type == "Spectral" or _type == "Tarot")
    and area == G.pack_cards
    and not forced_key then
        local heart_center = G.P_CENTERS[HEX_HEART_CENTER_KEY]
        if heart_center and heart_center.soul_rate
        and pseudorandom(pseudoseed(mod.prefix .. "_heart_soul")) < heart_center.soul_rate then
            forced_key = HEX_HEART_CENTER_KEY
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

local function hex_cursed_deck_selected()
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
    key = "holy_deck",

    loc_txt = {
        name = "Holy Deck",
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

-- Key of Holy Deck, used the same way HEX_PRESTIGE_DECK_KEY is used
-- above, to check which deck is currently selected.
local HEX_HOLY_DECK_KEY = "b_" .. mod.prefix .. "_holy_deck"

local function hex_holy_deck_selected()
    return G.GAME
        and G.GAME.selected_back
        and G.GAME.selected_back.effect
        and G.GAME.selected_back.effect.center
        and G.GAME.selected_back.effect.center.key == HEX_HOLY_DECK_KEY
end

-- Holy Deck: grants one random Divine Joker (same pool-scan approach
-- Prestige/Infernal Deck's grants above use) and raises win_ante to 32.
-- Same new-run-only guard as the decks above. Inaccessible is excluded
-- from the pool, the same way G.FUNCS.summon_divine excludes it -- it
-- must be earned normally, never handed out as a starting Joker.
local old_start_run_holy_deck = Game.start_run

function Game:start_run(args, ...)
    local ret = old_start_run_holy_deck(self, args, ...)

    if hex_holy_deck_selected() and not (args and args.savetext) then
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
            "Win ante is ante 16",
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
        G.GAME.win_ante = 16

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
            "Win ante is ante 1",
            "{C:mult}-4{} Joker slot",
            "{C:mult}-3{} hand each round",
            "{C:mult}-3{} discard each round",
            "{C:attention}-3{} hand size",
            "Start with {C:money}$0{}",
        }
    },

    config = {
        joker_slot = -4
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

        G.GAME.round_resets.hands = math.max(1, (G.GAME.round_resets.hands or 4) - 3)
        G.GAME.round_resets.discards = math.max(0, (G.GAME.round_resets.discards or 3) - 3)
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
        return G.GAME and G.GAME.cavendish_broken
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


-- Perkeo: fires when actually leaving the shop via the "Next Round"
-- button. That button's config is `button = 'toggle_shop'` (see
-- G.UIDEF.shop's next_round_button node) -- not `end_shop` -- so the
-- hook has to be on G.FUNCS.toggle_shop specifically, or it's never
-- invoked at all. (An earlier attempt hooked a global `end_shop` and
-- then G.FUNCS.end_shop, neither of which is what this button actually
-- calls in this installed build.)
local hex_old_toggle_shop = G.FUNCS.toggle_shop

G.FUNCS.toggle_shop = function(e)
    if G.jokers and G.jokers.cards then
        for _, j in ipairs(G.jokers.cards) do
            if j.ability and j.ability.name == 'Perkeo' then
                if G.consumeables and G.consumeables.cards[1] then

                    -- Same eligible-pool filter as before: excludes
                    -- Ritual/Star/Galaxy-set consumables.
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
                        card_eval_status_text(j, 'extra', nil, nil, nil, {message = localize('k_duplicated_ex')})
                    end
                end
            end
        end
    end

    return hex_old_toggle_shop(e)
end



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
    in_pool = function(self)
        return true
    end,

    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
}

SMODS.Joker{
    key = "green_screen",
    loc_txt = {
        name = "Green Screen",
        text = {
            "This Joker gains {X:mult,C:white}X1{} Mult",
            "every time a",
            "{C:attention}Full House{} is played",
            "{C:inactive}(Currently {}{X:mult,C:white}X#1#{}{C:inactive} Mult){}"
        }
    },
    config = { extra = { Xmult = big(1), Xmult_gain = big(1) } },
    atlas = "HexJokers",
    pos = { x = 0, y = 0 }, -- first frame in the atlas
    rarity = 4,             -- 1 common, 2 uncommon, 3 rare, 4 legendary
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
        return { vars = { card.ability.extra.Xmult } }
    end,
}

SMODS.Joker{
    key = "lemniscate",

    loc_txt = {
        name = "Lemniscate",
        text = {
            "Raises Mult to the power of {C:purple}^#1#{}",
            "Gains {C:purple}+0.01{} power",
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
                card.ability.extra.exponent or big(1)
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

    cost = 1e308,
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
-- New Spectral cards: Covenant / Oath / Prism / Forge / Shine /
-- Enchant / Polish
-- ============================================================

-- Covenant: 1-in-4 chance to give a random editionless Joker one of this
-- mod's own Prismatic/Brilliant/Chromatic editions -- same eligible-pool
-- filter and pseudorandom_element pick Barnard's Star/Cigar Galaxy use
-- elsewhere in this file, just gated behind a chance roll first (same
-- reasoning as the "chance to X" pattern Tadpole Galaxy/Sculptor Galaxy
-- use), and drawing from this trio of editions rather than Cigar
-- Galaxy's own trio.
SMODS.Consumable{
    key = "covenant",
    set = "Spectral",

    atlas = "HexSpectrals",
    pos = { x = 3, y = 2 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Covenant",
        text = {
            "{C:green}1 in 4{} chance to give a",
            "{C:attention}random{} Joker",
            "{C:attention}without an Edition{}",
            "{C:dark_edition}Prismatic{}, {C:dark_edition}Brilliant{},",
            "or {C:dark_edition}Chromatic{}",
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS["e_" .. mod.prefix .. "_prismatic"]
        info_queue[#info_queue + 1] = G.P_CENTERS["e_" .. mod.prefix .. "_brilliant"]
        info_queue[#info_queue + 1] = G.P_CENTERS["e_" .. mod.prefix .. "_chromatic"]
        return { vars = {} }
    end,

    can_use = function(self, card)
        if not (G.jokers and G.jokers.cards) then return false end

        for _, j in ipairs(G.jokers.cards) do
            if not j.edition then
                return true
            end
        end

        return false
    end,

    use = function(self, card)
        if pseudorandom(pseudoseed(mod.prefix .. "_covenant_chance")) < (1 / 4) then
            if not (G.jokers and G.jokers.cards) then return end

            local eligible = {}
            for _, j in ipairs(G.jokers.cards) do
                if not j.edition then
                    eligible[#eligible + 1] = j
                end
            end

            if not eligible[1] then return end

            local chosen_joker = pseudorandom_element(
                eligible,
                pseudoseed(mod.prefix .. "_covenant_joker")
            )

            local editions = {
                mod.prefix .. "_prismatic",
                mod.prefix .. "_brilliant",
                mod.prefix .. "_chromatic",
            }
            local chosen_edition = pseudorandom_element(
                editions,
                pseudoseed(mod.prefix .. "_covenant_edition")
            )

            chosen_joker:set_edition({ [chosen_edition] = true }, true)

            card_eval_status_text(chosen_joker, "extra", nil, nil, nil, {
                message = localize("k_upgrade_ex"),
                colour = G.C.SECONDARY_SET.Spectral
            })
        else
            card_eval_status_text(card, "extra", nil, nil, nil, {
                message = "Nope",
                colour = G.C.SECONDARY_SET.Spectral
            })
        end
    end,
}

-- Oath: gives one selected playing card a Pink Seal. Same
-- "select exactly one card from hand, then use" pattern Cappella/Pistol
-- Star/Triangulum Galaxy already use above for their own seal grants.
SMODS.Consumable{
    key = "oath",
    set = "Spectral",

    atlas = "HexSpectrals",
    pos = { x = 4, y = 2 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Oath",
        text = {
            "Gives {C:attention}1{} selected",
            "playing card a",
            "{C:pink}Pink Seal{}",
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_SEALS[mod.prefix .. "_pink"]
        return { vars = {} }
    end,

    can_use = function(self, card)
        return G.hand and G.hand.highlighted and #G.hand.highlighted == 1
    end,

    use = function(self, card)
        if not (G.hand and G.hand.highlighted and G.hand.highlighted[1]) then return end

        local target = G.hand.highlighted[1]
        target:set_seal(mod.prefix .. "_pink", true)

        card_eval_status_text(target, "extra", nil, nil, nil, {
            message = "Pink Seal",
            colour = G.C.SECONDARY_SET.Spectral
        })
    end,
}

-- Prism: 1-in-3 chance to give a selected playing card this mod's own
-- Prismatic edition. Playing-card editions use Card:set_edition the same
-- way Joker editions do elsewhere in this file, just targeting a single
-- highlighted hand card instead of a Joker.
SMODS.Consumable{
    key = "prism",
    set = "Spectral",

    atlas = "HexSpectrals",
    pos = { x = 5, y = 2 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Prism",
        text = {
            "{C:green}1 in 3{} chance to give",
            "{C:attention}1{} selected playing card",
            "the {C:dark_edition}Prismatic{} edition",
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS["e_" .. mod.prefix .. "_prismatic"]
        return { vars = {} }
    end,

    can_use = function(self, card)
        return G.hand and G.hand.highlighted and #G.hand.highlighted == 1
    end,

    use = function(self, card)
        if not (G.hand and G.hand.highlighted and G.hand.highlighted[1]) then return end

        local target = G.hand.highlighted[1]

        if pseudorandom(pseudoseed(mod.prefix .. "_prism_chance")) < (1 / 3) then
            target:set_edition({ [mod.prefix .. "_prismatic"] = true }, true)

            card_eval_status_text(target, "extra", nil, nil, nil, {
                message = localize("k_upgrade_ex"),
                colour = G.C.SECONDARY_SET.Spectral
            })
        else
            card_eval_status_text(card, "extra", nil, nil, nil, {
                message = "Nope",
                colour = G.C.SECONDARY_SET.Spectral
            })
        end
    end,
}

-- Forge: gives one selected playing card the Bronze enhancement, via
-- Card:set_ability the same way Alcyoneus/Cartwheel Galaxy/Needle Galaxy
-- above apply their own custom enhancements to a selected card.
SMODS.Consumable{
    key = "forge",
    set = "Spectral",

    atlas = "HexSpectrals",
    pos = { x = 6, y = 2 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Forge",
        text = {
            "Gives {C:attention}1{} selected",
            "playing card the",
            "{C:attention}Bronze{} enhancement",
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS["m_" .. mod.prefix .. "_bronze"]
        return { vars = {} }
    end,

    can_use = function(self, card)
        return G.hand and G.hand.highlighted and #G.hand.highlighted == 1
    end,

    use = function(self, card)
        if not (G.hand and G.hand.highlighted and G.hand.highlighted[1]) then return end

        local target = G.hand.highlighted[1]
        target:set_ability(G.P_CENTERS["m_" .. mod.prefix .. "_bronze"])

        card_eval_status_text(target, "extra", nil, nil, nil, {
            message = "Bronze!",
            colour = G.C.SECONDARY_SET.Spectral
        })
    end,
}

-- Shine: 1-in-2 chance to give a selected playing card this mod's own
-- Brilliant edition. Same pattern as Prism above, just Brilliant instead
-- of Prismatic and 1-in-2 odds instead of 1-in-3.
SMODS.Consumable{
    key = "shine",
    set = "Spectral",

    atlas = "HexSpectrals",
    pos = { x = 7, y = 2 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Shine",
        text = {
            "{C:green}1 in 2{} chance to give",
            "{C:attention}1{} selected playing card",
            "the {C:dark_edition}Brilliant{} edition",
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS["e_" .. mod.prefix .. "_brilliant"]
        return { vars = {} }
    end,

    can_use = function(self, card)
        return G.hand and G.hand.highlighted and #G.hand.highlighted == 1
    end,

    use = function(self, card)
        if not (G.hand and G.hand.highlighted and G.hand.highlighted[1]) then return end

        local target = G.hand.highlighted[1]

        if pseudorandom(pseudoseed(mod.prefix .. "_shine_chance")) < (1 / 2) then
            target:set_edition({ [mod.prefix .. "_brilliant"] = true }, true)

            card_eval_status_text(target, "extra", nil, nil, nil, {
                message = localize("k_upgrade_ex"),
                colour = G.C.SECONDARY_SET.Spectral
            })
        else
            card_eval_status_text(card, "extra", nil, nil, nil, {
                message = "Nope",
                colour = G.C.SECONDARY_SET.Spectral
            })
        end
    end,
}

-- Enchant: gives one selected playing card this mod's own Chromatic
-- edition, guaranteed -- no chance roll, unlike Prism/Shine above.
SMODS.Consumable{
    key = "enchant",
    set = "Spectral",

    atlas = "HexSpectrals",
    pos = { x = 8, y = 2 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Enchant",
        text = {
            "Gives {C:attention}1{} selected",
            "playing card the",
            "{C:dark_edition}Chromatic{} edition",
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS["e_" .. mod.prefix .. "_chromatic"]
        return { vars = {} }
    end,

    can_use = function(self, card)
        return G.hand and G.hand.highlighted and #G.hand.highlighted == 1
    end,

    use = function(self, card)
        if not (G.hand and G.hand.highlighted and G.hand.highlighted[1]) then return end

        local target = G.hand.highlighted[1]
        target:set_edition({ [mod.prefix .. "_chromatic"] = true }, true)

        card_eval_status_text(target, "extra", nil, nil, nil, {
            message = localize("k_upgrade_ex"),
            colour = G.C.SECONDARY_SET.Spectral
        })
    end,
}

-- Polish: gives one selected playing card the Topaz enhancement, but
-- costs $25 to use -- deducted the same OmegaNum-safe way every other
-- money change in this file goes through (to_big/big, matching
-- ease_dollars's own arithmetic). can_use checks both the card-selection
-- requirement and that at least $25 is currently available, so the card
-- greys out in the consumable-use menu if either isn't met.
SMODS.Consumable{
    key = "polish",
    set = "Spectral",

    atlas = "HexSpectrals",
    pos = { x = 9, y = 2 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Polish",
        text = {
            "Gives {C:attention}1{} selected",
            "playing card the",
            "{C:attention}Topaz{} enhancement",
            "{C:inactive}(Costs {C:money}$25{C:inactive} to use){}",
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS["m_" .. mod.prefix .. "_topaz"]
        return { vars = {} }
    end,

    can_use = function(self, card)
        if not (G.hand and G.hand.highlighted and #G.hand.highlighted == 1) then
            return false
        end
        return to_big(G.GAME.dollars or 0):gte(big(25))
    end,

    use = function(self, card)
        if not (G.hand and G.hand.highlighted and G.hand.highlighted[1]) then return end
        if to_big(G.GAME.dollars or 0):lt(big(25)) then return end

        G.GAME.dollars = to_big(G.GAME.dollars or 0):sub(big(25))

        local target = G.hand.highlighted[1]
        target:set_ability(G.P_CENTERS["m_" .. mod.prefix .. "_topaz"])

        card_eval_status_text(target, "extra", nil, nil, nil, {
            message = "Topaz!",
            colour = G.C.SECONDARY_SET.Spectral
        })
    end,
}



SMODS.Consumable{
    key = "heart",
    set = "Spectral",

    atlas = "HexSpectrals",
    pos = {x = 2, y = 2},
    soul_pos = {x = 6, y = 5 },
    unlocked = true,
    discovered = true,

    soul_set = "Tarot",
    soul_rate = 0.001,

    in_pool = function(self, args)
        return false
    end,

    loc_txt = {
        name = "Heart",
        text = {
            "Creates a random",
            "{V:1,E:2}Mythic{} Joker"
        }
    },
    
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                colours = { G.C.MYTHIC }
            }
        }
    end,

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)

        local mythics = {}

        local showman_owned = hex_owns_showman()

        for _, center in pairs(G.P_CENTERS) do
            if center.set == "Joker"
            and center.rarity == R_HEX_MYTHIC.key
            and (showman_owned or #SMODS.find_card(center.key) == 0) then
                mythics[#mythics+1] = center
            end
        end

        if #mythics > 0 then
            local chosen = mythics[math.random(#mythics)]

            SMODS.add_card{
                set = "Joker",
                key = chosen.key
            }

            card_eval_status_text(card, "extra", nil, nil, nil, {
                message = "Mythic!",
                colour = G.C.MYTHIC
            })
        end
    end
}


















SMODS.ConsumableType{
    key = "ritual",
    primary_colour = G.C.RITUAL,
    secondary_colour = G.C.RITUAL,
    collection_rows = { 4, 4 },
    shop_rate = 0,          -- never appears in normal shop generation
    loc_txt = {
        name = "Ritual",
        collection = "Rituals",
        undiscovered = {
            name = "Undiscovered Ritual",
            text = {
                "Use this Ritual",
                "to discover it"
            }
        }
    },
    can_stack = true,
    can_divide = true,
}

-- Stars: never appear in the shop (shop_rate = 0) and never generated by
-- the normal Spectral/Tarot draw pools (Sol below sets in_pool = false,
-- the same way every Ritual does) -- instead, each is given a flat
-- 1-in-33 chance to replace a card slot in a Spectral or Arcana pack,
-- via the create_card hook near the top of this file.
SMODS.ConsumableType{
    key = "star",
    primary_colour = G.C.STAR,
    secondary_colour = G.C.STAR,
    badge_colour = G.C.STAR,
    collection_rows = { 6, 6 },
    shop_rate = 0,          -- never appears in normal shop generation
    loc_txt = {
        name = "Star",
        collection = "Stars",
        undiscovered = {
            name = "Undiscovered Star",
            text = {
                "Use this Star",
                "to discover it"
            }
        }
    },
    can_stack = true,
    can_divide = true,
}

-- Galaxies: rarer cousins of Stars. Never appear in the shop (shop_rate
-- = 0) and are never generated by the normal Spectral/Tarot draw pools
-- (every Galaxy card sets in_pool = false, same as Stars/Rituals) --
-- instead each Galaxy card is injected via the create_card hook above:
-- a 1-in-50 chance to replace a Spectral/Arcana pack slot, or a 1-in-10
-- chance to take a slot in this mod's own Star Pack instead of a Star.
SMODS.ConsumableType{
    key = "galaxy",
    primary_colour = G.C.GALAXY,
    secondary_colour = G.C.GALAXY,
    badge_colour = G.C.GALAXY,
    collection_rows = { 6, 6 },
    shop_rate = 0,          -- never appears in normal shop generation
    loc_txt = {
        name = "Galaxy",
        collection = "Galaxies",
        undiscovered = {
            name = "Undiscovered Galaxy",
            text = {
                "Use this Galaxy",
                "to discover it"
            }
        }
    },
    can_stack = true,
    can_divide = true,
}

SMODS.ConsumableType{
    key = "nebula",
    primary_colour = G.C.NEBULA,
    secondary_colour = G.C.NEBULA,
    badge_colour = G.C.NEBULA,
    collection_rows = { 4, 5 },
    shop_rate = 0,          -- never appears in normal shop generation
    loc_txt = {
        name = "Nebula",
        collection = "Nebulas",
        undiscovered = {
            name = "Undiscovered Nebula",
            text = {
                "Use this Nebula",
                "to discover it"
            }
        }
    },
    can_stack = true,
    can_divide = true,
}





SMODS.ConsumableType{
    key = "astral",
    primary_colour = G.C.ASTRAL,
    secondary_colour = G.C.ASTRAL,
    badge_colour = G.C.ASTRAL,
    collection_rows = { 5, 5 },
    shop_rate = 0,          -- never appears in normal shop generation
    loc_txt = {
        name = "Astral",
        collection = "Astrals",
        undiscovered = {
            name = "Undiscovered Astral",
            text = {
                "Use this Astral",
                "to discover it"
            }
        }
    },
    can_stack = true,
    can_divide = true,
}


SMODS.ConsumableType{
    key = "cosmic",
    primary_colour = G.C.COSMIC,
    secondary_colour = G.C.COSMIC,
    badge_colour = G.C.COSMIC,
    collection_rows = { 5, 5 },
    shop_rate = 0,          -- never appears in normal shop generation
    loc_txt = {
        name = "Cosmic",
        collection = "Cosmics",
        undiscovered = {
            name = "Undiscovered Cosmic",
            text = {
                "Use this Cosmic",
                "to discover it"
            }
        }
    },
    can_stack = true,
    can_divide = true,
}


SMODS.ConsumableType{
    key = "black_hole",
    primary_colour = G.C.BLACK_HOLE,
    secondary_colour = G.C.BLACK_HOLE,
    badge_colour = G.C.BLACK_HOLE,
    collection_rows = { 2, 3 },
    shop_rate = 0,          -- never appears in normal shop generation
    loc_txt = {
        name = "Black Hole",
        collection = "Black Holes",
        undiscovered = {
            name = "Undiscovered Black Hole",
            text = {
                "Use this Black Hole",
                "to discover it"
            }
        }
    },
    can_stack = true,
    can_divide = true,
}









local HEX_STAR_PACK_WEIGHT = ((G.P_CENTERS.p_spectral_normal and G.P_CENTERS.p_spectral_normal.weight) or 0.6) 

-- Filters out any Star/Galaxy centers already picked earlier in this
-- same pack opening, unless the player owns Showman (which allows
-- duplicates everywhere else, so it makes sense to allow them here too).
local function hex_filter_already_picked(centers, picked)
    if hex_owns_showman() then return centers end

    local out = {}
    for _, c in ipairs(centers) do
        if not picked[c.key] then
            out[#out + 1] = c
        end
    end
    return out
end


-- Star Pack: a Spectral-pack-style booster (3 cards shown, choose 1)
-- whose contents are always drawn from this mod's own Star pool (see
-- hex_get_star_centers above) instead of the normal Spectral/Tarot
-- pools -- the create_card hook near the top of this file forces this
-- whenever `_type == "star"`, which is exactly the string Steamodded
-- passes through as a Booster's opening `_type` when its own `kind`
-- field is set to "star" (matching both the ConsumableType key
-- registered just above, and the `set = "star"` every Star card itself
-- uses).

-- Hidden from the shop's normal pack-weight pool (in_pool = false)
-- until the Nova voucher has been bought (see its own registration
-- earlier in the file, alongside Legendary Soul/Mythic Heart), at which
-- point it becomes available at exactly half of vanilla's own Spectral
-- Normal pack weight -- i.e. "twice as rare" as a normal Spectral pack,
-- per how it was requested. Read once, at registration time, straight
-- off p_spectral_normal's own .weight (rather than a hardcoded number)
-- so this stays in sync with whatever Spectral's own rarity actually is
-- -- falling back to vanilla's own base value (0.6) only if that center
-- somehow isn't registered yet at the point this file loads.
SMODS.Booster{
    key = "star_pack",
    kind = "star",
    cost = 4,

    atlas = "HexBoosters",
    pos = { x = 0, y = 5 },

    config = { extra = 3, choose = 1 },

    loc_txt = {
        name = "Star Pack",
        group_name = "Star Pack",
        text = {
            "Choose {C:attention}1{} of {C:attention}3{}",
            "{C:star}Star{} cards",
        }
    },

    unlocked = true,
    discovered = true,
    draw_hand = true,

    in_pool = function(self)
        return (G.GAME and G.GAME.hex_nova_unlocked) or false
    end,

    weight = HEX_STAR_PACK_WEIGHT,

    create_card = function(self, card, i)
        if i == 1 then
            card.hex_star_pack_picked = {}
        end
        card.hex_star_pack_picked = card.hex_star_pack_picked or {}

        local chosen_key = nil

        if G.GAME and G.GAME.hex_cosmic_unlocked
        and pseudorandom(pseudoseed(mod.prefix .. "_star_pack_cosmic")) < HEX_COSMIC_IN_PACK_CHANCE then
            local cosmics = hex_filter_already_picked(hex_get_cosmic_centers(), card.hex_star_pack_picked)
            if #cosmics > 0 then
                chosen_key = cosmics[math.random(#cosmics)].key
            end
        end

        if G.GAME and G.GAME.hex_astral_unlocked
        and pseudorandom(pseudoseed(mod.prefix .. "_star_pack_astral")) < HEX_ASTRAL_IN_PACK_CHANCE then
            local astrals = hex_filter_already_picked(hex_get_astral_centers(), card.hex_star_pack_picked)
            if #astrals > 0 then
                chosen_key = astrals[math.random(#astrals)].key
            end
        end

        if not chosen_key
        and pseudorandom(pseudoseed(mod.prefix .. "_star_pack_galaxy")) < HEX_GALAXY_IN_STARPACK_CHANCE then
            local galaxies = hex_filter_already_picked(hex_get_galaxy_centers(), card.hex_star_pack_picked)
            if #galaxies > 0 then
                chosen_key = galaxies[math.random(#galaxies)].key
            end
        end

        if not chosen_key then
            local stars = hex_filter_already_picked(hex_get_star_centers(), card.hex_star_pack_picked)
            if #stars > 0 then
                chosen_key = stars[math.random(#stars)].key
            end
        end

        if not chosen_key then
            return { set = "Joker", area = G.pack_cards }
        end

        card.hex_star_pack_picked[chosen_key] = true

        return {
            key = chosen_key,
            area = G.pack_cards,
            skip_materialize = true,
        }
    end,
}


-- Jumbo Star Pack: same Star-only pool as Star Pack, just 5 cards shown
-- (choose 1), the same "Normal -> Jumbo" size step vanilla's own Arcana/
-- Celestial/Spectral/Standard/Buffoon Jumbo packs use. Weight is half of
-- Star Pack's own, mirroring the size-vs-rarity tradeoff vanilla's own
-- Jumbo packs make relative to their Normal counterpart.
SMODS.Booster{
    key = "jumbo_star_pack",
    kind = "star",
    cost = 6,

    atlas = "HexBoosters",
    pos = { x = 0, y = 5 }, 

    config = { extra = 5, choose = 1 },

    loc_txt = {
        name = "Jumbo Star Pack",
        group_name = "Star Pack",
        text = {
            "Choose {C:attention}1{} of {C:attention}5{}",
            "{C:star}Star{} cards",
        }
    },

    unlocked = true,
    discovered = true,
    draw_hand = true,

    in_pool = function(self)
        return (G.GAME and G.GAME.hex_nova_unlocked) or false
    end,

    weight = HEX_STAR_PACK_WEIGHT / 2,

    create_card = function(self, card, i)
        if i == 1 then
            card.hex_star_pack_picked = {}
        end
        card.hex_star_pack_picked = card.hex_star_pack_picked or {}

        local chosen_key = nil

        if G.GAME and G.GAME.hex_cosmic_unlocked
        and pseudorandom(pseudoseed(mod.prefix .. "_star_pack_cosmic")) < HEX_COSMIC_IN_PACK_CHANCE then
            local cosmics = hex_filter_already_picked(hex_get_cosmic_centers(), card.hex_star_pack_picked)
            if #cosmics > 0 then
                chosen_key = cosmics[math.random(#cosmics)].key
            end
        end

        if G.GAME and G.GAME.hex_astral_unlocked
        and pseudorandom(pseudoseed(mod.prefix .. "_star_pack_astral")) < HEX_ASTRAL_IN_PACK_CHANCE then
            local astrals = hex_filter_already_picked(hex_get_astral_centers(), card.hex_star_pack_picked)
            if #astrals > 0 then
                chosen_key = astrals[math.random(#astrals)].key
            end
        end

        if not chosen_key
        and pseudorandom(pseudoseed(mod.prefix .. "_star_pack_galaxy")) < HEX_GALAXY_IN_STARPACK_CHANCE then
            local galaxies = hex_filter_already_picked(hex_get_galaxy_centers(), card.hex_star_pack_picked)
            if #galaxies > 0 then
                chosen_key = galaxies[math.random(#galaxies)].key
            end
        end

        if not chosen_key then
            local stars = hex_filter_already_picked(hex_get_star_centers(), card.hex_star_pack_picked)
            if #stars > 0 then
                chosen_key = stars[math.random(#stars)].key
            end
        end

        if not chosen_key then
            return { set = "Joker", area = G.pack_cards }
        end

        card.hex_star_pack_picked[chosen_key] = true

        return {
            key = chosen_key,
            area = G.pack_cards,
            skip_materialize = true,
        }
    end,
}

-- Mega Star Pack: same pool again, 5 cards shown but choose 2, the
-- "Jumbo -> Mega" step vanilla's own packs use. Weight is half of Jumbo
-- Star Pack's own, so it's the rarest of the three tiers.
SMODS.Booster{
    key = "mega_star_pack",
    kind = "star",
    cost = 8,

    atlas = "HexBoosters",
    pos = { x = 0, y = 5 }, 

    config = { extra = 5, choose = 2 },

    loc_txt = {
        name = "Mega Star Pack",
        group_name = "Star Pack",
        text = {
            "Choose {C:attention}2{} of {C:attention}5{}",
            "{C:star}Star{} cards",
        }
    },

    unlocked = true,
    discovered = true,
    draw_hand = true,

    in_pool = function(self)
        return (G.GAME and G.GAME.hex_nova_unlocked) or false
    end,

    weight = HEX_STAR_PACK_WEIGHT / 4,

    create_card = function(self, card, i)
        if i == 1 then
            card.hex_star_pack_picked = {}
        end
        card.hex_star_pack_picked = card.hex_star_pack_picked or {}

        local chosen_key = nil

        if G.GAME and G.GAME.hex_cosmic_unlocked
        and pseudorandom(pseudoseed(mod.prefix .. "_star_pack_cosmic")) < HEX_COSMIC_IN_PACK_CHANCE then
            local cosmics = hex_filter_already_picked(hex_get_cosmic_centers(), card.hex_star_pack_picked)
            if #cosmics > 0 then
                chosen_key = cosmics[math.random(#cosmics)].key
            end
        end

        if G.GAME and G.GAME.hex_astral_unlocked
        and pseudorandom(pseudoseed(mod.prefix .. "_star_pack_astral")) < HEX_ASTRAL_IN_PACK_CHANCE then
            local astrals = hex_filter_already_picked(hex_get_astral_centers(), card.hex_star_pack_picked)
            if #astrals > 0 then
                chosen_key = astrals[math.random(#astrals)].key
            end
        end

        if not chosen_key
        and pseudorandom(pseudoseed(mod.prefix .. "_star_pack_galaxy")) < HEX_GALAXY_IN_STARPACK_CHANCE then
            local galaxies = hex_filter_already_picked(hex_get_galaxy_centers(), card.hex_star_pack_picked)
            if #galaxies > 0 then
                chosen_key = galaxies[math.random(#galaxies)].key
            end
        end

        if not chosen_key then
            local stars = hex_filter_already_picked(hex_get_star_centers(), card.hex_star_pack_picked)
            if #stars > 0 then
                chosen_key = stars[math.random(#stars)].key
            end
        end

        if not chosen_key then
            return { set = "Joker", area = G.pack_cards }
        end

        card.hex_star_pack_picked[chosen_key] = true

        return {
            key = chosen_key,
            area = G.pack_cards,
            skip_materialize = true,
        }
    end,
}




-- Checks whether a Star (or any) consumable with this exact key is
-- currently sitting in the player's consumable slots.
local function hex_consumable_already_owned(key)
    if not (G.consumeables and G.consumeables.cards) then return false end
    for _, c in ipairs(G.consumeables.cards) do
        if c.config and c.config.center and c.config.center.key == key then
            return true
        end
    end
    return false
end

local HEX_GALAXY_PACK_WEIGHT = HEX_STAR_PACK_WEIGHT 
local function hex_galaxy_pack_create_card(card, i)
    if i == 1 then
        card.hex_galaxy_pack_picked = {}
    end
    card.hex_galaxy_pack_picked = card.hex_galaxy_pack_picked or {}

    local chosen_key = nil

    if G.GAME and G.GAME.hex_cosmic_unlocked
    and pseudorandom(pseudoseed(mod.prefix .. "_galaxy_pack_cosmic")) < HEX_COSMIC_IN_PACK_CHANCE then
        local cosmics = hex_filter_already_picked(hex_get_cosmic_centers(), card.hex_galaxy_pack_picked)
        if #cosmics > 0 then
            chosen_key = cosmics[math.random(#cosmics)].key
        end
    end

    if G.GAME and G.GAME.hex_astral_unlocked
    and pseudorandom(pseudoseed(mod.prefix .. "_galaxy_pack_astral")) < HEX_ASTRAL_IN_PACK_CHANCE then
        local astrals = hex_filter_already_picked(hex_get_astral_centers(), card.hex_galaxy_pack_picked)
        if #astrals > 0 then
            chosen_key = astrals[math.random(#astrals)].key
        end
    end

    if not chosen_key
    and pseudorandom(pseudoseed(mod.prefix .. "_galaxy_pack_nebula")) < HEX_NEBULA_IN_GALAXYPACK_CHANCE then
        local nebulas = hex_filter_already_picked(hex_get_nebula_centers(), card.hex_galaxy_pack_picked)
        if #nebulas > 0 then
            chosen_key = nebulas[math.random(#nebulas)].key
        end
    end

    if not chosen_key then
        local galaxies = hex_filter_already_picked(hex_get_galaxy_centers(), card.hex_galaxy_pack_picked)
        if #galaxies > 0 then
            chosen_key = galaxies[math.random(#galaxies)].key
        end
    end

    if not chosen_key then
        return { set = "Joker", area = G.pack_cards }
    end

    card.hex_galaxy_pack_picked[chosen_key] = true

    return {
        key = chosen_key,
        area = G.pack_cards,
        skip_materialize = true,
    }
end

SMODS.Booster{
    key = "galaxy_pack",
    kind = "galaxy",
    cost = 4,

    atlas = "HexBoosters",
    pos = { x = 0, y = 5 }, -- shares a frame with the Star Pack tiers -- move before shipping if unintentional

    config = { extra = 3, choose = 1 },

    loc_txt = {
        name = "Galaxy Pack",
        group_name = "Galaxy Pack",
        text = {
            "Choose {C:attention}1{} of {C:attention}3{}",
            "{C:galaxy}Galaxy{} cards",
        }
    },

    unlocked = true,
    discovered = true,
    draw_hand = true,

    in_pool = function(self)
        return (G.GAME and G.GAME.hex_cosmic_rays_unlocked) or false
    end,

    weight = HEX_GALAXY_PACK_WEIGHT,

    create_card = hex_galaxy_pack_create_card,
}

SMODS.Booster{
    key = "jumbo_galaxy_pack",
    kind = "galaxy",
    cost = 6,

    atlas = "HexBoosters",
    pos = { x = 0, y = 5 },

    config = { extra = 5, choose = 1 },

    loc_txt = {
        name = "Jumbo Galaxy Pack",
        group_name = "Galaxy Pack",
        text = {
            "Choose {C:attention}1{} of {C:attention}5{}",
            "{C:galaxy}Galaxy{} cards",
        }
    },

    unlocked = true,
    discovered = true,
    draw_hand = true,

    in_pool = function(self)
        return (G.GAME and G.GAME.hex_cosmic_rays_unlocked) or false
    end,

    weight = HEX_GALAXY_PACK_WEIGHT / 2,

    create_card = hex_galaxy_pack_create_card,
}

SMODS.Booster{
    key = "mega_galaxy_pack",
    kind = "galaxy",
    cost = 8,

    atlas = "HexBoosters",
    pos = { x = 0, y = 5 },

    config = { extra = 5, choose = 2 },

    loc_txt = {
        name = "Mega Galaxy Pack",
        group_name = "Galaxy Pack",
        text = {
            "Choose {C:attention}2{} of {C:attention}5{}",
            "{C:galaxy}Galaxy{} cards",
        }
    },

    unlocked = true,
    discovered = true,
    draw_hand = true,

    in_pool = function(self)
        return (G.GAME and G.GAME.hex_cosmic_rays_unlocked) or false
    end,

    weight = HEX_GALAXY_PACK_WEIGHT / 4,

    create_card = hex_galaxy_pack_create_card,
}











-- Sol: rather than just knocking down the currently active blind's chip
-- requirement (a one-off, single-blind effect), Sol permanently shrinks
-- every blind's score requirement, present and future, by a stacking
-- X0.9 each time a Sol card is used. This is stored as a persistent
-- multiplier on G.GAME (hex_sol_blind_mult, starting at 1) that vanilla's
-- own get_blind_amount(ante) -- the function that computes a blind's
-- chip target for a given ante -- gets hooked to multiply its result by,
-- so it applies uniformly to every blind's requirement from here on,
-- however many times Sol is used (0.9, then 0.81, then 0.729, ...).
local old_get_blind_amount = get_blind_amount

function get_blind_amount(ante)
    local amount = old_get_blind_amount(ante)
    local mult = (G.GAME and G.GAME.hex_sol_blind_mult) or 1

    if mult ~= 1 then
        -- Blind chip totals aren't OmegaNum-scaled the way scoring
        -- Chips/Mult are, so a plain Lua multiply + floor is safe here
        -- even with Amulet installed.
        amount = math.floor(amount * mult)
    end

    return amount
end

SMODS.Consumable{
    key = "sol",
    set = "star",
    cost = 4, 

    atlas = "HexStarsGalaxies",
    pos = { x = 0, y = 0 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Sol",
        text = {
            "Permanently makes the size",
            "of {C:attention}every Blind{} {C:attention}X0.9{}",
            "smaller",
            "{C:inactive}(Currently X#1#){}"
        }
    },

    loc_vars = function(self, info_queue, card)
        local mult = (G.GAME and G.GAME.hex_sol_blind_mult) or 1
        return { vars = { string.format("%.3f", mult) } }
    end,

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        G.GAME.hex_sol_blind_mult = ((G.GAME and G.GAME.hex_sol_blind_mult) or 1) * 0.9

        -- Apply immediately to whatever blind is currently active too,
        -- rather than only taking effect starting next blind.
        if G.GAME.blind and G.GAME.blind.chips then
            G.GAME.blind.chips = math.floor(G.GAME.blind.chips * 0.9)

            if G.GAME.blind.chip_text then
                G.GAME.blind.chip_text = number_format(G.GAME.blind.chips)
            end
        end

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "X0.9 Blind Size",
            colour = G.C.STAR
        })
    end,
}

-- Sirius: permanently grants +1 hand size. Mirrors the hand-size fixup
-- code Gambler's/Hard Deck already use elsewhere in this file -- bump
-- the per-round baseline (round_resets.hand_size, so every future round
-- also deals the extra card) and the live G.hand.config.card_limit, then
-- immediately draw one more card from the deck if one's available so the
-- extra slot doesn't just sit empty until the next round.
SMODS.Consumable{
    key = "sirius",
    set = "star",
    cost = 4, 

    atlas = "HexStarsGalaxies",
    pos = { x = 1, y = 0 }, -- placeholder art slot, next open frame after Sol; move if a dedicated sprite exists

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Sirius",
        text = {
            "Permanently gain",
            "{C:attention}+1{} hand size",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        G.GAME.round_resets.hand_size = (G.GAME.round_resets.hand_size or 8) + 1

        if G.hand and G.hand.config then
            G.hand.config.card_limit = G.hand.config.card_limit + 1

            if G.deck and #G.deck.cards > 0 then
                G.hand:draw({ G.deck.cards[1] })
            end
        end

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+1 Hand Size",
            colour = G.C.STAR
        })
    end,
}

-- Deneb: a straightforward one-off Hex point grant, the same mechanism
-- (and the same big() wrapper for Amulet/OmegaNum compatibility) the
-- Cursed/Broken Deck starting grants and The Monolith's Hex bonus above
-- already use.
SMODS.Consumable{
    key = "deneb",
    set = "star",
    cost = 4, 

    atlas = "HexStarsGalaxies",
    pos = { x = 2, y = 0 }, -- placeholder art slot, next open frame after Sirius; move if a dedicated sprite exists

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,
    
    loc_txt = {
        name = "Deneb",
        text = {
            "Gain {C:purple}12{}",
            "{C:purple}Hex points{}",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        G.GAME.hex_points = (G.GAME.hex_points or big(0)):add(big(12))  -- Deneb, CHANGED

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+12 Hex",
            colour = G.C.HEX_ORPLE or G.C.STAR
        })
    end,
}

-- Pollux: permanently grants +1 hand every round. Same round_resets
-- pattern as Sirius above -- bump the per-round baseline so every future
-- round gets the extra hand, and also top up the current round's live
-- counter (if one exists) so the bonus is felt immediately rather than
-- waiting for the next round to start.
SMODS.Consumable{
    key = "pollux",
    set = "star",
    cost = 4, 

    atlas = "HexStarsGalaxies",
    pos = { x = 3, y = 0 }, -- placeholder art slot, next open frame after Deneb; move if a dedicated sprite exists

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Pollux",
        text = {
            "Permanently gain",
            "{C:attention}+1{} hand",
            "every round",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        G.GAME.round_resets.hands = (G.GAME.round_resets.hands or 4) + 1

        if G.GAME.current_round then
            G.GAME.current_round.hands_left = (G.GAME.current_round.hands_left or 0) + 1
        end

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+1 Hand",
            colour = G.C.STAR
        })
    end,
}

-- Castor: permanently grants +1 discard every round. Identical pattern to
-- Pollux above, just against round_resets.discards / discards_left
-- instead of hands.
SMODS.Consumable{
    key = "castor",
    set = "star",
    cost = 4, 

    atlas = "HexStarsGalaxies",
    pos = { x = 4, y = 0 }, -- placeholder art slot, next open frame after Pollux; move if a dedicated sprite exists

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Castor",
        text = {
            "Permanently gain",
            "{C:attention}+1{} discard",
            "every round",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        G.GAME.round_resets.discards = (G.GAME.round_resets.discards or 3) + 1

        if G.GAME.current_round then
            G.GAME.current_round.discards_left = (G.GAME.current_round.discards_left or 0) + 1
        end

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+1 Discard",
            colour = G.C.STAR
        })
    end,
}

-- Fomalhaut: sets the ante back one step (the same G.GAME.round_resets.
-- ante field Overflow above already reads as the authoritative
-- current-ante value). Unlike vanilla's Hieroglyph voucher this doesn't
-- cost a Hand, and there's no floor -- repeated uses can push the ante
-- into negative numbers with no lower bound.
SMODS.Consumable{
    key = "fomalhaut",
    set = "star",
    cost = 4, 

    atlas = "HexStarsGalaxies",
    pos = { x = 5, y = 0 }, -- placeholder art slot, next open frame after Castor; move if a dedicated sprite exists

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Fomalhaut",
        text = {
            "{C:attention}-1{} Ante",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        G.GAME.round_resets.ante = (G.GAME.round_resets.ante or 1) - 1

        -- G.GAME.round_resets.ante is the value scoring/blind-amount code
        -- reads (see get_blind_amount's caller and Overflow's own check
        -- above), but the HUD's on-screen ante counter is actually driven
        -- by a *separate* field, G.GAME.round_resets.ante_disp -- so only
        -- touching .ante changes blind difficulty correctly but leaves
        -- the visible number on screen stale. Keep them in lockstep here
        -- so the UI updates immediately.
        if G.GAME.round_resets.ante_disp then
            G.GAME.round_resets.ante_disp = G.GAME.round_resets.ante_disp - 1
        end

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "-1 Ante",
            colour = G.C.STAR
        })
    end,
}

-- Saiph: permanently discounts shop rerolls by $1, floored so the cost
-- can never drop below $1. Same round_resets/current_round pairing as
-- Coupon's flat pin above -- adjusting round_resets.reroll_cost keeps
-- every future shop's starting price down, and adjusting current_round.
-- reroll_cost too means an already-open shop feels the discount right
-- away rather than waiting for the next one. Because both fields are
-- shifted down permanently (rather than being pinned to a fixed value
-- like Coupon does), vanilla's own per-reroll cost escalation on top of
-- that baseline is untouched -- rerolling still gets pricier as normal,
-- just $1 cheaper at every step, further stacking with each extra Saiph.
SMODS.Consumable{
    key = "saiph",
    set = "star",
    cost = 4, 

    atlas = "HexStarsGalaxies",
    pos = { x = 6, y = 0 }, -- placeholder art slot, next open frame after Fomalhaut; move if a dedicated sprite exists

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Saiph",
        text = {
            "Permanently makes shop",
            "{C:money}rerolls{} cost {C:money}$1{} less",
            "{C:inactive}(Minimum $1){}"
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        G.GAME.round_resets.reroll_cost = math.max(1, (G.GAME.round_resets.reroll_cost or 5) - 1)

        if G.GAME.current_round then
            G.GAME.current_round.reroll_cost = math.max(1, (G.GAME.current_round.reroll_cost or 5) - 1)
        end

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "-$1 Reroll",
            colour = G.C.STAR
        })
    end,
}

-- Spica: permanently raises the interest cap by $5 -- the same field
-- (G.GAME.interest_cap, base 5) vanilla's own Seed Money/Money Tree
-- vouchers raise to $10/$20 respectively.
SMODS.Consumable{
    key = "spica",
    set = "star",
    cost = 4, 

    atlas = "HexStarsGalaxies",
    pos = { x = 7, y = 0 }, -- placeholder art slot, next open frame after Saiph; move if a dedicated sprite exists

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Spica",
        text = {
            "Permanently increases the",
            "{C:money}interest{} cap by {C:money}$5{}",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        G.GAME.interest_cap = (G.GAME.interest_cap or 5) + 25

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+$5 Cap",
            colour = G.C.STAR
        })
    end,
}

-- Vega: gives 6 levels to a random poker hand, using vanilla's own
-- level_up_hand(card, hand_key, bypass_visual, amount) function -- the
-- same one Planet cards call -- against a hand key picked at random from
-- every currently-visible entry in G.GAME.hands (so it only ever targets
-- a hand type the player has actually discovered/can see, never a
-- still-hidden secret hand).
SMODS.Consumable{
    key = "vega",
    set = "star",
    cost = 4, 

    atlas = "HexStarsGalaxies",
    pos = { x = 8, y = 0 }, -- placeholder art slot, next open frame after Spica; move if a dedicated sprite exists

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Vega",
        text = {
            "Gives {C:attention}6{} levels",
            "to a {C:attention}random{}",
            "poker hand",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        local hand_keys = {}
        for k, h in pairs(G.GAME.hands) do
            if h.visible then
                hand_keys[#hand_keys + 1] = k
            end
        end

        if #hand_keys > 0 then
            local chosen = pseudorandom_element(hand_keys, pseudoseed(mod.prefix .. "_vega"))
            level_up_hand(card, chosen, nil, 6)
        end

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+6 Levels",
            colour = G.C.STAR
        })
    end,
}

-- Canopus: permanently boosts every future Black Hole use by +1 extra
-- Planet level, stacking with each copy used. Like Sirius/Pollux/Castor
-- above, the bonus itself is just a persistent counter on G.GAME
-- (hex_canopus_bonus_levels) -- the actual application happens in the
-- Black Hole hook right below this card's definition.
SMODS.Consumable{
    key = "canopus",
    set = "star",
    cost = 4, 

    atlas = "HexStarsGalaxies",
    pos = { x = 9, y = 0 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Canopus",
        text = {
            "Permanently gives the",
            "{C:attention}Black Hole{} Spectral card",
            "{C:attention}+1{} extra Planet level",
            "{C:inactive}(Currently +#1#){}"
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { (G.GAME and G.GAME.hex_canopus_bonus_levels) or 0 } }
    end,

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        G.GAME.hex_canopus_bonus_levels = (G.GAME.hex_canopus_bonus_levels or 0) + 1

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+1 Black Hole",
            colour = G.C.STAR
        })
    end,
}

-- Toliman: permanently grants +$10 at cash-out, but only after a Boss
-- Blind. Stored the same way (persistent counter, stacks per copy used);
-- actually paid out in the G.FUNCS.cash_out hook below.
SMODS.Consumable{
    key = "toliman",
    set = "star",
    cost = 4, 

    atlas = "HexStarsGalaxies",
    pos = { x = 0, y = 1 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Toliman",
        text = {
            "Permanently gain {C:money}$10{}",
            "extra at the end of every",
            "{C:attention}Boss Blind{} when",
            "cashing out",
            "{C:inactive}(Currently +$#1#){}"
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { (G.GAME and G.GAME.hex_toliman_bonus) or 0 } }
    end,

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        G.GAME.hex_toliman_bonus = (G.GAME.hex_toliman_bonus or 0) + 10

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+$10 Boss Cash",
            colour = G.C.STAR
        })
    end,
}

-- Rigil Kentaurus: permanently grants +$3 at cash-out after every Blind
-- (Small/Big/Boss alike), stacking with Toliman's boss-only bonus above
-- rather than replacing it. Same persistent-counter pattern.
SMODS.Consumable{
    key = "rigil_kentaurus",
    set = "star",
    cost = 4, 

    atlas = "HexStarsGalaxies",
    pos = { x = 1, y = 1 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Rigil Kentaurus",
        text = {
            "Permanently gain {C:money}$3{}",
            "extra after every Blind",
            "when cashing out",
            "{C:inactive}(Currently +$#1#){}"
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { (G.GAME and G.GAME.hex_rigil_bonus) or 0 } }
    end,

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        G.GAME.hex_rigil_bonus = (G.GAME.hex_rigil_bonus or 0) + 3

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+$3 Cash",
            colour = G.C.STAR
        })
    end,
}

-- Canopus display fix: vanilla Black Hole's own animation code hardcodes
-- `level = '+1'` in its final update_hand_text call, regardless of how
-- many levels are actually being applied -- so with Canopus adding bonus
-- levels on top, the on-screen text was lying about the real amount.
-- Since that call happens deep inside Card:use_consumeable's own Black
-- Hole branch (not something we can reach after the fact), we instead
-- wrap update_hand_text globally and, while our flag is armed, rewrite
-- any '+1' level text to the real total the instant Black Hole's code
-- tries to display it.
local hex_old_update_hand_text = update_hand_text
local hex_black_hole_display_total = nil

function update_hand_text(config, vars)
    if hex_black_hole_display_total and vars and vars.level == '+1' then
        vars.level = "+" .. tostring(hex_black_hole_display_total)
    end
    return hex_old_update_hand_text(config, vars)
end

-- Canopus hook: intercepts every consumable use via the Card class method
-- itself (Card:use_consumeable), rather than patching the Black Hole
-- center's .use function directly -- G.P_CENTERS entries can be
-- rebuilt/reassigned after mod load, which was silently breaking the
-- direct-patch version. We arm hex_black_hole_display_total with the
-- real total (vanilla's base 1 + Canopus's bonus) right before calling
-- the original Black Hole logic, so its own hardcoded '+1' text gets
-- rewritten via the update_hand_text wrapper above, then apply the extra
-- levels on top exactly as before once the original call returns.
local HEX_STAR_PICK_PACK_HOLD = {
    ["c_" .. mod.prefix .. "_betelgeuse"] = true,
    ["c_" .. mod.prefix .. "_antares"] = true,
}

local hex_old_use_consumeable = Card.use_consumeable

function Card:use_consumeable(area, copier)
    local is_black_hole = self.ability and self.ability.name == 'Black Hole'
    local bonus = 0

    if is_black_hole then
        bonus = (G.GAME and G.GAME.hex_canopus_bonus_levels) or 0
        hex_black_hole_display_total = 1 + bonus
    end

    -- NEW: Betelgeuse / Antares open a menu instead of resolving
    -- immediately, but vanilla still decrements the pack's choice count
    -- the instant use_consumeable returns -- closing the pack out from
    -- under the picker. Cancel that decrement out here; it's paid back
    -- once the picker actually resolves (see the exit_overlay_menu hook
    -- further down the file).
    if area == G.pack_cards
    and self.config and self.config.center
    and HEX_STAR_PICK_PACK_HOLD[self.config.center.key]
    and G.GAME and G.GAME.pack_choices then
        G.GAME.pack_choices = G.GAME.pack_choices + 1
        G.HEX_STAR_PICK_PACK_HELD = true
    end

    local ret = hex_old_use_consumeable(self, area, copier)

    hex_black_hole_display_total = nil

    if is_black_hole and bonus > 0 and G.GAME and G.GAME.hands then
        for k, v in pairs(G.GAME.hands) do
            level_up_hand(self, k, true, bonus)
        end
    end

    return ret
end


-- Lightweight stand-in for a real Card, just enough to satisfy what
-- add_round_eval_row's 'joker' row branch and its generic juice_up call
-- need (config.card.config.center.set / .key, and a :juice_up method).
-- Used below to show a Rocket/Golden-Joker-style "+$X" line for Rigil
-- Kentaurus/Toliman -- unlike an actual Joker, these are consumables
-- that have already been used and are long gone from the board by the
-- time this fires, so there's no live Card object to hand over; this
-- just points at the same center (G.P_CENTERS entry) a real card of
-- that kind would have, which is all localize{type='name_text', ...}
-- actually reads to look up the display name.
local function hex_star_bonus_card_stub(short_key)
    return {
        config = { center = G.P_CENTERS["c_" .. mod.prefix .. "_" .. short_key] },
        juice_up = function() end,
    }
end

-- Toliman / Rigil Kentaurus hook: folds the bonus into config.dollars on
-- add_round_eval_row's final 'bottom' row -- the row that both builds the
-- "Cash Out: $X" button and stores X into G.GAME.current_round.dollars.
-- Deliberately does NOT call ease_dollars itself: add_round_eval_row has
-- no money-crediting calls anywhere in it (it's purely display), and the
-- actual wallet credit happens later, inside vanilla's own G.FUNCS.
-- cash_out, which pays out G.GAME.current_round.dollars the moment the
-- button is clicked. So bumping config.dollars here is enough on its
-- own: the button's number already includes the bonus, and vanilla's
-- own click handler pays out that whole (bonus-inclusive) number exactly
-- once. Two earlier versions of this got it wrong in opposite
-- directions -- one hooked G.FUNCS.cash_out and called ease_dollars
-- itself, landing the bonus as its own separate pop disconnected from
-- the button's number; the other did that *and* bumped config.dollars
-- here, which double-paid it (once from our own ease_dollars call, once
-- again when vanilla's cash_out paid out the now-inflated
-- current_round.dollars).

-- Guarded by G.GAME.round purely as cheap insurance against this
-- somehow firing more than once for the same round -- it self-clears the
-- moment the round number moves on to the next round.
local hex_old_add_round_eval_row = add_round_eval_row

function add_round_eval_row(config)
    if config and config.name == 'bottom'
    and G.GAME and G.GAME.round
    and G.GAME.hex_cash_out_paid_round ~= G.GAME.round then

        local is_boss_blind = G.GAME.blind and G.GAME.blind.boss

        local rigil_bonus = G.GAME.hex_rigil_bonus or 0
        local toliman_bonus = is_boss_blind and (G.GAME.hex_toliman_bonus or 0) or 0
        local bonus = rigil_bonus + toliman_bonus

        -- Big Bang: independent of the money-bonus dedupe just below
        -- (hex_cash_out_paid_round), so it still fires every round even
        -- if neither Rigil Kentaurus nor Toliman is owned. The number of
        -- cards created is however many the persistent hex_big_bang_count
        -- counter has stacked up to (see its own definition -- +3 per
        -- use, uncapped). Each card independently rolls Star vs. Galaxy,
        -- then is always forced Negative -- same as Sombrero Galaxy/
        -- Rigel's own grants -- but deliberately NOT gated on there being
        -- room in G.consumeables, unlike those two: every card here is
        -- always created regardless of how full the consumable area
        -- already is.
        local big_bang_count = G.GAME.hex_big_bang_count or 0

        if big_bang_count > 0
        and G.GAME.hex_big_bang_paid_round ~= G.GAME.round then

            G.GAME.hex_big_bang_paid_round = G.GAME.round

            -- Tracks every key already granted by this specific batch of
            -- Big Bang cards, so (without Showman) the same Star/Galaxy
            -- card can't be handed out twice in the same round -- reuses
            -- hex_filter_already_picked, the same picked-table filter
            -- Star Pack/Galaxy Pack's own create_card already use, which
            -- itself skips the filter entirely once Showman is owned,
            -- letting duplicates appear freely.
            local big_bang_picked = {}

            for i = 1, big_bang_count do
                G.E_MANAGER:add_event(Event({
                    trigger = "after",
                    delay = 0.2 * i,
                    func = function()
                        if G.consumeables then
                            local chosen_key = nil

                            if pseudorandom(pseudoseed(mod.prefix .. "_big_bang_galaxy_" .. i .. "_" .. G.GAME.round)) < 0.1 then
                                local galaxies = hex_filter_already_picked(hex_get_galaxy_centers(), big_bang_picked)
                                if #galaxies > 0 then
                                    chosen_key = galaxies[math.random(#galaxies)].key
                                end
                            end

                            if not chosen_key then
                                local stars = hex_filter_already_picked(hex_get_star_centers(), big_bang_picked)
                                if #stars > 0 then
                                    chosen_key = stars[math.random(#stars)].key
                                end
                            end

                            if chosen_key then
                                big_bang_picked[chosen_key] = true

                                local new_card = SMODS.create_card({
                                    key = chosen_key,
                                    area = G.consumeables
                                })

                                new_card:set_edition({ negative = true }, true)

                                G.consumeables:emplace(new_card)
                            end
                        end
                        return true
                    end
                }))
            end
        end

        if bonus > 0 then
            G.GAME.hex_cash_out_paid_round = G.GAME.round
            config.dollars = to_big(config.dollars or 0):add(big(bonus))

            if rigil_bonus > 0 then
                hex_old_add_round_eval_row({
                    name = 'joker_hex_rigil_kentaurus',
                    dollars = rigil_bonus,
                    card = hex_star_bonus_card_stub('rigil_kentaurus'),
                    pitch = 1,
                })
            end

            if toliman_bonus > 0 then
                hex_old_add_round_eval_row({
                    name = 'joker_hex_toliman',
                    dollars = toliman_bonus,
                    card = hex_star_bonus_card_stub('toliman'),
                    pitch = 1,
                })
            end
        end
    end

    return hex_old_add_round_eval_row(config)
end





-- Proxima Centauri: creates two random Jokers, each forced Negative.
-- Negative edition Jokers don't count against the Joker slot limit in
-- vanilla Balatro (that's the whole point of the edition), so unlike the
-- Life ritual/Relic-Deck-style grants elsewhere in this file, there's no
-- need to check G.jokers.config.card_limit here -- both copies are always
-- created regardless of how full the Joker row already is. SMODS.add_card
-- with no `key` behaves like a normal shop roll (random Joker respecting
-- in_pool), the same shortcut Heart/Prestige/Relic/Infernal/Holy Deck's
-- grants above use, just without pinning a rarity -- so this can hand out
-- any ordinary-rarity Joker, same odds as the shop. Staggered by a short
-- delay between the two so their materialize animations don't perfectly
-- overlap.
SMODS.Consumable{
    key = "proxima_centauri",
    set = "star",
    cost = 4, 

    atlas = "HexStarsGalaxies",
    pos = { x = 2, y = 1 }, -- next open frame in the atlas, after Rigil Kentaurus (1,1)

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Proxima Centauri",
        text = {
            "Creates {C:attention}2{} random",
            "{C:attention}Negative{} Jokers",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        for i = 1, 2 do
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.2 * i,
                func = function()
                    local new_card = SMODS.add_card({ set = "Joker" })
                    if new_card then
                        new_card:set_edition({ negative = true }, true)
                    end
                    return true
                end
            }))
        end

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+2 Negative",
            colour = G.C.STAR
        })
    end,
}


-- Barnard's Star: picks one currently-owned Joker *without* an edition
-- already and gives it a random Foil/Holographic/Polychrome edition --
-- same restriction vanilla's own Wheel of Fortune tarot card uses (it
-- only ever targets editionless Jokers, so it can never overwrite/waste
-- an edition you already earned). Eligible pool is built by filtering
-- G.jokers.cards down to cards with no card.edition set, then picked
-- from with the same pseudorandom_element pattern The Seal of Aces uses
-- above for its seal roll. can_use (and use, as a second guard in case
-- the eligible set changes between opening the menu and clicking) both
-- require at least one editionless Joker to exist.
SMODS.Consumable{
    key = "barnards_star",
    set = "star",
    cost = 4, 

    atlas = "HexStarsGalaxies",
    pos = { x = 3, y = 1 }, -- next open frame in the atlas, after Proxima Centauri (2,1)

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Barnard's Star",
        text = {
            "Gives a {C:attention}random{} Joker",
            "{C:attention}without an Edition{}",
            "{C:attention}Foil{}, {C:attention}Holographic{},",
            "or {C:attention}Polychrome{}",
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.e_foil
        info_queue[#info_queue + 1] = G.P_CENTERS.e_holo
        info_queue[#info_queue + 1] = G.P_CENTERS.e_polychrome
        return { vars = {} }
    end,

    -- Shared helper so can_use and use always agree on what's eligible.
    can_use = function(self, card)
        if not (G.jokers and G.jokers.cards) then return false end

        for _, j in ipairs(G.jokers.cards) do
            if not j.edition then
                return true
            end
        end

        return false
    end,

    use = function(self, card)
        if not (G.jokers and G.jokers.cards) then return end

        local eligible = {}
        for _, j in ipairs(G.jokers.cards) do
            if not j.edition then
                eligible[#eligible + 1] = j
            end
        end

        if not eligible[1] then return end

        local chosen_joker = pseudorandom_element(
            eligible,
            pseudoseed(mod.prefix .. "_barnards_star_joker")
        )

        local editions = { "foil", "holo", "polychrome" }
        local chosen_edition = pseudorandom_element(
            editions,
            pseudoseed(mod.prefix .. "_barnards_star_edition")
        )

        chosen_joker:set_edition({ [chosen_edition] = true }, true)

        card_eval_status_text(chosen_joker, "extra", nil, nil, nil, {
            message = localize("k_upgrade_ex"),
            colour = G.C.STAR
        })
    end,
}


-- Bellatrix: grants 3 Double Tags. Uses vanilla Balatro's own tag-granting
-- API (`add_tag(Tag(key))`), the same mechanism vanilla content uses to
-- hand out tags outside of the normal Blind-skip flow -- "tag_double" is
-- vanilla's own key for the Double Tag (the tag that duplicates the next
-- tag you get). Three separate add_tag calls rather than a single call
-- with a count, since add_tag only ever inserts one tag per call.
SMODS.Consumable{
    key = "bellatrix",
    set = "star",
    cost = 4, 

    atlas = "HexStarsGalaxies",
    pos = { x = 4, y = 1 }, -- next open frame in the atlas, after Barnard's Star (3,1)

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Bellatrix",
        text = {
            "Gain {C:attention}3{}",
            "{C:attention}Double{} Tags",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        for i = 1, 3 do
            add_tag(Tag("tag_double"))
        end

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+3 Double Tags",
            colour = G.C.STAR
        })
    end,
}

-- Cappella: gives one selected playing card a Black Seal. Same
-- "select exactly one card from hand, then use" pattern vanilla's own
-- Seal-granting Spectral cards (Deja Vu/Trance/Talisman/Medium) use --
-- can_use gates on exactly one highlighted card in G.hand, and use()
-- applies the seal to that card via Card:set_seal, the same call
-- The Seal of Aces Joker already uses elsewhere in this file (passing
-- the capitalized "Black" name, matching that Joker's own seal list).
SMODS.Consumable{
    key = "cappella",
    set = "star",
    cost = 4, 

    atlas = "HexStarsGalaxies",
    pos = { x = 5, y = 1 }, -- next open frame in the atlas, after Bellatrix (4,1)

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Cappella",
        text = {
            "Gives {C:attention}1{} selected",
            "playing card a",
            "{C:attention}Black Seal{}",
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_SEALS[mod.prefix .. "_black"]
        return { vars = {} }
    end,

    can_use = function(self, card)
        return G.hand and G.hand.highlighted and #G.hand.highlighted == 1
    end,

    use = function(self, card)
        if not (G.hand and G.hand.highlighted and G.hand.highlighted[1]) then return end

        local target = G.hand.highlighted[1]
        target:set_seal(mod.prefix .. "_black", true)   -- was just "black"

        card_eval_status_text(target, "extra", nil, nil, nil, {
            message = "Black Seal",
            colour = G.C.STAR
        })
    end,
}


-- Rigel: creates 2 Negative Planet cards, 2 Negative Tarot cards, and 1
-- Negative Spectral card, staggered by a short delay each (same
-- staggering technique Proxima Centauri already uses above for its own
-- two Negative Jokers) so their materialize animations don't perfectly
-- overlap. Unlike Negative Jokers (which are exempt from the Joker slot
-- limit), Negative consumables still count against the normal
-- consumable slot limit, so each creation is individually gated on
-- there being room in G.consumeables at the moment it actually fires --
-- a card queued up before the area fills up would otherwise just be
-- silently lost. SMODS.create_card with only `set` (no `key`) behaves
-- like a normal draw from that type's pool -- the same shortcut Black
-- Seal's Spectral grant elsewhere in this file uses -- so every card
-- here is a genuinely random member of its type, just always Negative.
SMODS.Consumable{
    key = "rigel",
    set = "star",
    cost = 4, 

    atlas = "HexStarsGalaxies",
    pos = { x = 6, y = 1 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Rigel",
        text = {
            "Creates {C:attention}2{} {C:attention}Negative{}",
            "Planet cards, {C:attention}2{} {C:attention}Negative{}",
            "Tarot cards, and {C:attention}1{}",
            "{C:attention}Negative{} Spectral card",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        local to_create = { "Planet", "Planet", "Tarot", "Tarot", "Spectral" }

        for i, card_type in ipairs(to_create) do
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.2 * i,
                func = function()
                    if G.consumeables then
                        -- Deliberately no slot-limit check here -- Rigel
                        -- always creates all 5 cards regardless of how
                        -- full the consumable area already is, the same
                        -- way Negative Jokers ignore the Joker slot limit
                        -- elsewhere in this file.
                        local new_card = SMODS.create_card({
                            set = card_type,
                            area = G.consumeables
                        })

                        new_card:set_edition({ negative = true }, true)

                        G.consumeables:emplace(new_card)
                    end
                    return true
                end
            }))
        end

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+5 Negative",
            colour = G.C.STAR
        })
    end,
}

-- Arcturus: permanently grants +1 consumable slot, the same effect the
-- vanilla Crystal Ball voucher gives -- but as a Star card rather than a
-- voucher, it isn't limited to a single purchase, so every additional
-- copy used stacks another +1 on top, uncapped. Straightforward direct
-- bump of G.consumeables.config.card_limit, the same field Crystal Ball
-- itself raises.
SMODS.Consumable{
    key = "arcturus",
    set = "star",
    cost = 4, 

    atlas = "HexStarsGalaxies",
    pos = { x = 7, y = 1 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Arcturus",
        text = {
            "Permanently gain",
            "{C:attention}+1{} consumable slot",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        if G.consumeables and G.consumeables.config then
            G.consumeables.config.card_limit = G.consumeables.config.card_limit + 1
        end

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+1 Slot",
            colour = G.C.STAR
        })
    end,
}

-- Procyon: disables the next Boss Blind encountered. Stores a stacking
-- charge counter (G.GAME.hex_procyon_charges) rather than a single flag,
-- so using multiple copies of this card queues up multiple future Boss
-- Blind disables rather than only ever affecting one. The actual
-- disabling happens in the Game:update hook further down the file, right
-- alongside Fractal's own boss-disable poll -- same Blind:disable() call
-- Chicot/Fractal already use, just gated on `charges > 0` instead of a
-- permanent "used" flag, and decremented by 1 every time it actually
-- fires. Checking `not G.GAME.blind.disabled` (same guard Fractal uses)
-- naturally prevents this from double-decrementing on later frames once
-- a given Boss Blind is already disabled -- the charge is only spent the
-- one frame the disable actually happens.
SMODS.Consumable{
    key = "procyon",
    set = "star",
    cost = 4, 

    atlas = "HexStarsGalaxies",
    pos = { x = 8, y = 1 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Procyon",
        text = {
            "The next {C:attention}Boss Blind{}",
            "is {C:attention}disabled{}",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        G.GAME.hex_procyon_charges = (G.GAME.hex_procyon_charges or 0) + 1

        -- If a Boss Blind is already active/selected right now, disable
        -- it immediately rather than waiting up to a frame -- same
        -- immediate-apply treatment Fractal's own use function gives its
        -- currently-active Boss Blind.
        if G.GAME.blind and G.GAME.blind.boss and not G.GAME.blind.disabled then
            G.GAME.blind:disable()
            G.GAME.hex_procyon_charges = G.GAME.hex_procyon_charges - 1
        end

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "Boss Disabled!",
            colour = G.C.STAR
        })
    end,
}


SMODS.Consumable{
    key = "polaris",
    set = "star",
    cost = 4, 

    atlas = "HexStarsGalaxies",
    pos = { x = 9, y = 1 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Polaris",
        text = {
            "All Poker hand permanently",
            "gains {C:purple}^1.25{}",
            "{C:chips}Chips{} and {C:mult}Mult{}",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        
        if G.GAME and G.GAME.hands then
            for hand_key, hand in pairs(G.GAME.hands) do
                if hand.chips then
                    hex_set_hand_stat(hand_key, "chips", to_big(hand.chips):arrow(1, 1.25))
                end
                if hand.mult then
                    hex_set_hand_stat(hand_key, "mult", to_big(hand.mult):arrow(1, 1.25))
                end
            end
        end
    end,
}

-- Betelgeuse: changes 2 selected playing cards to a chosen Rank, keeping
-- each card's own Suit, Enhancement, Seal, and Edition untouched. Reuses
-- the exact same overlay-menu "collection grid" picker Manifest's own
-- Rank step is built from (see the hex_star_pick_* system defined right
-- after the Manifest ritual further down the file) -- only the mode
-- ("rank") and the captured target cards differ.
SMODS.Consumable{
    key = "betelgeuse",
    set = "star",
    cost = 4, 

    atlas = "HexStarsGalaxies",
    pos = { x = 0, y = 2 }, -- next open row in the atlas, after Polaris (9,1)

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Betelgeuse",
        text = {
            "Change {C:attention}up to 2{} selected",
            "playing cards to a",
            "{C:attention}chosen Rank{}",
        }
    },

    -- At least 1 and at most 2 cards highlighted -- unlike Cappella's
    -- exact-1 gate elsewhere in this file, this is a range so the player
    -- can hit just 1 card without needing a second one highlighted too.
    can_use = function(self, card)
        return G.hand and G.hand.highlighted
            and #G.hand.highlighted >= 1
            and #G.hand.highlighted <= 2
    end,

    use = function(self, card)
        if not (G.hand and G.hand.highlighted
        and #G.hand.highlighted >= 1
        and #G.hand.highlighted <= 2) then return end

        -- Capture whichever cards are highlighted right now (1 or 2 of
        -- them) -- opening the overlay menu changes hover/focus state, so
        -- re-reading G.hand.highlighted once the menu is open (at
        -- click-time) would be unreliable.
        local targets = {}
        for _, c in ipairs(G.hand.highlighted) do
            targets[#targets + 1] = c
        end

        G.HEX_STAR_PICK_TARGETS = targets
        G.HEX_STAR_PICK_MODE = "rank"
        G.HEX_STAR_PICK_TITLE = "Betelgeuse -- Choose a Rank"
        G.FUNCS.hex_star_pick_menu()
    end,
}

-- Antares: changes 3 selected playing cards to a chosen Suit, keeping
-- each card's own Rank, Enhancement, Seal, and Edition untouched. Same
-- hex_star_pick_* picker as Betelgeuse above, just mode = "suit" and 3
-- captured targets instead of 2.
SMODS.Consumable{
    key = "antares",
    set = "star",
    cost = 4, 

    atlas = "HexStarsGalaxies",
    pos = { x = 1, y = 2 }, -- next open frame in the atlas, after Betelgeuse (0,2)

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Antares",
        text = {
            "Change {C:attention}up to 3{} selected",
            "playing cards to a",
            "{C:attention}chosen Suit{}",
        }
    },

    -- At least 1 and at most 3 cards highlighted, same range-gate
    -- approach as Betelgeuse above.
    can_use = function(self, card)
        return G.hand and G.hand.highlighted
            and #G.hand.highlighted >= 1
            and #G.hand.highlighted <= 3
    end,

    use = function(self, card)
        if not (G.hand and G.hand.highlighted
        and #G.hand.highlighted >= 1
        and #G.hand.highlighted <= 3) then return end

        local targets = {}
        for _, c in ipairs(G.hand.highlighted) do
            targets[#targets + 1] = c
        end

        G.HEX_STAR_PICK_TARGETS = targets
        G.HEX_STAR_PICK_MODE = "suit"
        G.HEX_STAR_PICK_TITLE = "Antares -- Choose a Suit"
        G.FUNCS.hex_star_pick_menu()
    end,
}

-- Altair: permanently raises the persistent Hex Altair multiplier by
-- X1.1 (stacking with itself, uncapped) -- see HEX_ALTAIR_BASE_RATE and
-- the create_card hook above for how this multiplier actually gets
-- applied to Joker Negative-edition odds. Also stacks with Negative
-- Deck's own boost, since that's a completely separate, independent roll.
SMODS.Consumable{
    key = "altair",
    set = "star",
    cost = 4, 

    atlas = "HexStarsGalaxies",
    pos = { x = 2, y = 2 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Altair",
        text = {
            "Permanently increases the chance",
            "for Jokers to be {C:attention}Negative{}",
            "by {C:attention}X2{}",
            "{C:inactive}(Currently X#1#){}",
        }
    },

    loc_vars = function(self, info_queue, card)
        local mult = (G.GAME and G.GAME.hex_altair_mult) or 1
        return { vars = { string.format("%.2f", mult) } }
    end,

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        G.GAME.hex_altair_mult = ((G.GAME and G.GAME.hex_altair_mult) or 1) * 2

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "X2 Negative",
            colour = G.C.STAR
        })
    end,
}

-- Pistol Star: gives one selected playing card an Orange Seal. Same
-- "select exactly one card from hand, then use" pattern Cappella's
-- Black Seal grant above already uses -- can_use gates on exactly one
-- highlighted card in G.hand, and use() applies the seal to that card
-- via Card:set_seal (passing this mod's own "orange" seal key, the same
-- way Cappella passes mod.prefix .. "_black").
SMODS.Consumable{
    key = "pistol_star",
    set = "star",
    cost = 4, 

    atlas = "HexStarsGalaxies",
    pos = { x = 3, y = 2 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Pistol Star",
        text = {
            "Gives {C:attention}1{} selected",
            "playing card an",
            "{C:attention}Orange Seal{}",
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_SEALS[mod.prefix .. "_orange"]
        return { vars = {} }
    end,

    can_use = function(self, card)
        return G.hand and G.hand.highlighted and #G.hand.highlighted == 1
    end,

    use = function(self, card)
        if not (G.hand and G.hand.highlighted and G.hand.highlighted[1]) then return end

        local target = G.hand.highlighted[1]
        target:set_seal(mod.prefix .. "_orange", true)

        card_eval_status_text(target, "extra", nil, nil, nil, {
            message = "Orange Seal",
            colour = G.C.STAR
        })
    end,
}

-- Toi-125: a one-time-use unlock card. Using it permanently unlocks VY
-- Canis Majoris (below) so it can start appearing via the Spectral/
-- Arcana pack hook, and Toi-125 itself is removed from that same pool
-- for the rest of the run the moment it's used -- both handled by the
-- hex_get_star_centers filter near the top of the file, gated on the two
-- G.GAME flags set below.
SMODS.Consumable{
    key = "toi_125",
    set = "star",
    cost = 4, 

    atlas = "HexStarsGalaxies",
    pos = { x = 4, y = 2 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return not (G.GAME and G.GAME.hex_toi_125_used) 
    end,

    loc_txt = {
        name = "Toi-125",
        text = {
            "Unlocks {C:attention}VY Canis Majoris{}",
            "{C:inactive}This card can't appear{}",
            "{C:inactive}again after being used{}",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        G.GAME.hex_toi_125_used = true
        G.GAME.hex_vy_unlocked = true

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "Unlocked!",
            colour = G.C.STAR
        })
    end,
}

-- VY Canis Majoris: grants +1 Joker slot. Hidden from the Star pool
-- entirely until Toi-125 has been used (see hex_get_star_centers), and
-- -- same as Toi-125 -- removed from that pool for the rest of the run
-- the moment it's used itself, via hex_vy_used below.
SMODS.Consumable{
    key = "vy_canis_majoris",
    set = "star",
    cost = 4, 

    atlas = "HexStarsGalaxies",
    pos = { x = 5, y = 2 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return (G.GAME and G.GAME.hex_vy_unlocked and not G.GAME.hex_vy_used) or false
    end,

    loc_txt = {
        name = "VY Canis Majoris",
        text = {
            "Gain {C:attention}+1{} Joker slot",
            "{C:inactive}This card can't appear{}",
            "{C:inactive}again after being used{}",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        if G.jokers and G.jokers.config then
            G.jokers.config.card_limit = G.jokers.config.card_limit + 1
        end

        G.GAME.hex_vy_used = true

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+1 Slot",
            colour = G.C.STAR
        })
    end,
}



-- ============================================================
-- Galaxy cards
-- Rarer cousins of Star cards (see the "galaxy" ConsumableType and the
-- HEX_GALAXY_PACK_CHANCE / HEX_GALAXY_IN_STARPACK_CHANCE-gated injection
-- in the create_card hook above for how these actually enter play).
-- The Milky Way is just a first example -- add more
-- SMODS.Consumable{ set = "galaxy", ... } entries the same way to expand
-- the pool; every one of them is automatically picked up by
-- hex_get_galaxy_centers().
-- ============================================================

-- The Milky Way: converts current money into Hex points at a rate of 1
-- Hex point per $10 (rounded down), capped at a maximum single-use gain
-- of 100 Hex points, then divides whatever money is left over by 10
-- (also rounded down) -- so cashing this in on, say, $850 grants the
-- capped 100 Hex points and leaves $85 behind, while cashing it in on
-- $40 grants 4 Hex points and leaves $4 behind. Plain math.floor/math.min
-- is used throughout (not the big()/OmegaNum helpers) since dollars are
-- always an ordinary Lua number, never scaled past double-precision
-- range the way Hex points or scoring Chips/Mult can be.
SMODS.Consumable{
    key = "the_milky_way",
    set = "galaxy",

    atlas = "HexStarsGalaxies",
    pos = { x = 0, y = 3 }, 
    unlocked = true,
    discovered = true,

    in_pool = function(self)    
        return true
    end,


    loc_txt = {
        name = "The Milky Way",
        text = {
            "Gain {C:purple}1{} Hex point for every",
            "{C:money}$10{} you have",
            "{C:inactive}(Max of 100 Hex points){}",
            "Then divides your {C:money}money{}",
            "by {C:money}10{}",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        local dollars_plain = hex_to_plain_number(G.GAME.dollars or 0)
        local gain = math.min(100, math.floor(dollars_plain / 10))

        if gain > 0 then
            G.GAME.hex_points = (G.GAME.hex_points or big(0)):add(big(gain))
        end

        G.GAME.dollars = big(math.floor(dollars_plain / 10))

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+" .. tostring(gain) .. " Hex",
            colour = G.C.GALAXY
        })
    end,
}

-- Andromeda: destroys one random currently-owned Joker, then creates a
-- random Legendary (rarity 4) Joker. Eternal Jokers are never eligible
-- to be the one destroyed -- same protection vanilla's own destroy
-- effects respect -- and neither is anything carrying this mod's own
-- Immortal sticker (see HEX_IMMORTAL_STICKER_KEY/hex_apply_immortal_sticker
-- near the top of the file), so Absolute (which is always Immortal) can
-- never be sacrificed by this either. can_use gates on at least one
-- eligible (non-Eternal, non-Immortal) Joker existing, since without one
-- there's nothing this card is allowed to destroy; use() re-checks the
-- same eligible pool as a second guard. The destroy animation plays
-- first, and the Legendary Joker is created shortly after, mirroring the
-- stagger already used for Relic Deck's own Legendary grant elsewhere in
-- this file (pool-scan + math.random rather than pseudorandom_element,
-- since some Legendary Jokers -- from this or other mods -- may set
-- in_pool = false, which pseudorandom_element would otherwise filter
-- out).
local function hex_andromeda_eligible_jokers()
    local out = {}
    if not (G.jokers and G.jokers.cards) then return out end

    for _, j in ipairs(G.jokers.cards) do
        local immortal = j.ability and j.ability[HEX_IMMORTAL_STICKER_KEY]
        if not immortal then
            out[#out + 1] = j
        end
    end

    return out
end

SMODS.Consumable{
    key = "andromeda",
    set = "galaxy",

    atlas = "HexStarsGalaxies",
    pos = { x = 1, y = 3 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,


    loc_txt = {
        name = "Andromeda",
        text = {
            "Destroys {C:attention}1{} random Joker,",
            "then creates a random",
            "{C:legendary}Legendary{} Joker",
        }
    },

    can_use = function(self, card)
        return #hex_andromeda_eligible_jokers() > 0
    end,

    use = function(self, card)
        local eligible = hex_andromeda_eligible_jokers()
        if not eligible[1] then return end

        local to_destroy = pseudorandom_element(eligible, pseudoseed(mod.prefix .. "_andromeda_destroy"))

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.1,
            func = function()
                to_destroy:start_dissolve()
                return true
            end
        }))

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

            -- NOTE: deliberately not gated on `#G.jokers.cards <
            -- G.jokers.config.card_limit` here. card:start_dissolve()
            -- above only *visually* dissolves the destroyed Joker over
            -- time -- it doesn't necessarily drop out of G.jokers.cards
            -- the instant this event fires, so checking the live card
            -- count here could still see the area as "full" and silently
            -- skip creating the Legendary, even though this is always a
            -- guaranteed 1-for-1 swap (we already committed to destroying
            -- exactly one Joker to make room for exactly one Legendary).
            -- Mirrors Absolute's own summon function elsewhere in this
            -- file, which destroys first and creates unconditionally
            -- after, for the same reason.
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.5,
                func = function()
                    local new_card = SMODS.create_card({
                        set = "Joker",
                        key = chosen.key,
                        area = G.jokers
                    })

                    G.jokers:emplace(new_card)
                    new_card:add_to_deck()

                    card_eval_status_text(new_card, "extra", nil, nil, nil, {
                        message = "ANDROMEDA!",
                        colour = G.C.GALAXY
                    })

                    return true
                end
            }))
        end

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "Destroyed!",
            colour = G.C.GALAXY
        })
    end,
}

-- Triangulum Galaxy: gives one selected playing card a Green Seal. Same
-- "select exactly one card from hand, then use" pattern Cappella (Black
-- Seal) and Pistol Star (Orange Seal) already use above -- can_use gates
-- on exactly one highlighted card in G.hand, and use() applies the seal
-- to that card via Card:set_seal, passing this mod's own "green" seal
-- key the same way Cappella/Pistol Star pass their own mod-prefixed keys.
SMODS.Consumable{
    key = "triangulum_galaxy",
    set = "galaxy",

    atlas = "HexStarsGalaxies",
    pos = { x = 2, y = 3 }, 

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,


    loc_txt = {
        name = "Triangulum Galaxy",
        text = {
            "Gives {C:attention}1{} selected",
            "playing card a",
            "{C:green}Green Seal{}",
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_SEALS[mod.prefix .. "_green"]
        return { vars = {} }
    end,

    can_use = function(self, card)
        return G.hand and G.hand.highlighted and #G.hand.highlighted == 1
    end,

    use = function(self, card)
        if not (G.hand and G.hand.highlighted and G.hand.highlighted[1]) then return end

        local target = G.hand.highlighted[1]
        target:set_seal(mod.prefix .. "_green", true)

        card_eval_status_text(target, "extra", nil, nil, nil, {
            message = "Green Seal",
            colour = G.C.GALAXY
        })
    end,
}

-- Sombrero Galaxy: creates 4 Negative Star cards, staggered by a short
-- delay each (same staggering technique Proxima Centauri/Rigel already
-- use above so their materialize animations don't perfectly overlap).
-- SMODS.create_card with `set = "star"` (no `key`) behaves like a normal
-- draw from the Star pool -- the same shortcut Rigel's own Planet/Tarot/
-- Spectral grants use for their respective types -- so every card here
-- is a genuinely random Star, just always Negative. Deliberately no
-- consumable-slot-limit check here, matching Rigel's own precedent
-- immediately above it in this file: all 4 are always created regardless
-- of how full G.consumeables already is, the same way Negative Jokers
-- ignore the Joker slot limit elsewhere in this file.
SMODS.Consumable{
    key = "sombrero_galaxy",
    set = "galaxy",

    atlas = "HexStarsGalaxies",
    pos = { x = 4, y = 3 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,


    loc_txt = {
        name = "Sombrero Galaxy",
        text = {
            "Creates {C:attention}4{} {C:attention}Negative{}",
            "{C:star}Star{} cards",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        for i = 1, 4 do
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.2 * i,
                func = function()
                    if G.consumeables then
                        -- Star cards all set in_pool = false (see the
                        -- "star" ConsumableType and every Star card's own
                        -- registration above), so a plain
                        -- SMODS.create_card({ set = "star" }) call would
                        -- draw from an empty pool and fail. Same fix
                        -- Sol/Sirius/etc.'s own injection into packs
                        -- uses: pick a random center from
                        -- hex_get_star_centers() ourselves and force that
                        -- exact key.
                        local stars = hex_get_star_centers()
                        if #stars > 0 then
                            local chosen = stars[math.random(#stars)]

                            local new_card = SMODS.create_card({
                                key = chosen.key,
                                area = G.consumeables
                            })

                            new_card:set_edition({ negative = true }, true)

                            G.consumeables:emplace(new_card)
                        end
                    end
                    return true
                end
            }))
        end

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+4 Negative",
            colour = G.C.GALAXY
        })
    end,
}

-- Cigar Galaxy: picks one currently-owned Joker *without* an edition
-- already and gives it a random Prismatic/Chromatic/Brilliant edition --
-- this mod's own custom editions (see the SMODS.Edition{ key =
-- "prismatic"/"chromatic"/"brilliant", ... } registrations near the top
-- of the file), applied the same restriction-and-selection pattern
-- Barnard's Star (Star) uses above for vanilla's own Foil/Holo/
-- Polychrome. Eligible pool is built by filtering G.jokers.cards down to
-- cards with no card.edition set, then picked from with the same
-- pseudorandom_element pattern Barnard's Star uses. can_use (and use, as
-- a second guard in case the eligible set changes between opening the
-- menu and clicking) both require at least one editionless Joker to
-- exist. Note the "_" .. mod.prefix .. "_" prefix on each edition key
-- below -- these are modded editions, so set_edition needs the exact
-- same mod-prefixed key the create_card hook's own random-roll code uses
-- elsewhere in this file (e.g. `[mod.prefix .. "_prismatic"] = true`),
-- unlike vanilla's own bare "foil"/"holo"/"polychrome" keys.
SMODS.Consumable{
    key = "cigar_galaxy",
    set = "galaxy",

    atlas = "HexStarsGalaxies",
    pos = { x = 5, y = 3 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Cigar Galaxy",
        text = {
            "Gives a {C:attention}random{} Joker",
            "{C:attention}without an Edition{}",
            "{C:purple}Prismatic{}, {C:blue}Chromatic{},",
            "or {C:blue}Brilliant{}",
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS["e_" .. mod.prefix .. "_prismatic"]
        info_queue[#info_queue + 1] = G.P_CENTERS["e_" .. mod.prefix .. "_chromatic"]
        info_queue[#info_queue + 1] = G.P_CENTERS["e_" .. mod.prefix .. "_brilliant"]
        return { vars = {} }
    end,

    -- Shared helper so can_use and use always agree on what's eligible.
    can_use = function(self, card)
        if not (G.jokers and G.jokers.cards) then return false end

        for _, j in ipairs(G.jokers.cards) do
            if not j.edition then
                return true
            end
        end

        return false
    end,

    use = function(self, card)
        if not (G.jokers and G.jokers.cards) then return end

        local eligible = {}
        for _, j in ipairs(G.jokers.cards) do
            if not j.edition then
                eligible[#eligible + 1] = j
            end
        end

        if not eligible[1] then return end

        local chosen_joker = pseudorandom_element(
            eligible,
            pseudoseed(mod.prefix .. "_cigar_galaxy_joker")
        )

        local editions = {
            mod.prefix .. "_prismatic",
            mod.prefix .. "_chromatic",
            mod.prefix .. "_brilliant",
        }
        local chosen_edition = pseudorandom_element(
            editions,
            pseudoseed(mod.prefix .. "_cigar_galaxy_edition")
        )

        chosen_joker:set_edition({ [chosen_edition] = true }, true)

        card_eval_status_text(chosen_joker, "extra", nil, nil, nil, {
            message = localize("k_upgrade_ex"),
            colour = G.C.GALAXY
        })
    end,
}

-- Antennae Galaxies: picks one currently-owned Joker *without* an
-- edition already and makes it Negative -- same restriction-and-
-- selection pattern Cigar Galaxy/Barnard's Star use just above, just
-- with vanilla's own bare "negative" key instead of a mod-prefixed
-- custom edition, and no roll needed since there's only one possible
-- outcome. can_use (and use, as a second guard) both require at least
-- one editionless Joker to exist.
SMODS.Consumable{
    key = "antennae_galaxies",
    set = "galaxy",

    atlas = "HexStarsGalaxies",
    pos = { x = 6, y = 3 }, 
    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,


    loc_txt = {
        name = "Antennae Galaxies",
        text = {
            "Makes a {C:attention}random{} Joker",
            "{C:attention}without an Edition,{}",
            "{C:dark_red}Negative{}",
        }
    },

    -- Shared helper so can_use and use always agree on what's eligible.
    can_use = function(self, card)
        if not (G.jokers and G.jokers.cards) then return false end

        for _, j in ipairs(G.jokers.cards) do
            if not j.edition then
                return true
            end
        end

        return false
    end,

    use = function(self, card)
        if not (G.jokers and G.jokers.cards) then return end

        local eligible = {}
        for _, j in ipairs(G.jokers.cards) do
            if not j.edition then
                eligible[#eligible + 1] = j
            end
        end

        if not eligible[1] then return end

        local chosen_joker = pseudorandom_element(
            eligible,
            pseudoseed(mod.prefix .. "_antennae_galaxies_joker")
        )

        chosen_joker:set_edition({ negative = true }, true)

        card_eval_status_text(chosen_joker, "extra", nil, nil, nil, {
            message = localize("k_upgrade_ex"),
            colour = G.C.GALAXY
        })
    end,
}

-- Hoag's Object: levels up every poker hand by however many times that
-- exact hand has been played so far this run. G.GAME.hands[key].played
-- is vanilla's own running play-count for each hand type (the same
-- field vanilla tracks for stats/achievements), so this reads that
-- straight off rather than keeping any separate counter of its own.
-- Uses vanilla's own level_up_hand(card, hand_key, bypass_visual, amount)
-- function -- the same one Vega (Star) and Canopus's Black Hole bonus
-- both call above -- passing bypass_visual = true (like Canopus's loop)
-- since this can be leveling up several hands at once and a popup for
-- every single one would be excessive. Hands that haven't been played at
-- all this run (played == 0) are skipped entirely, since leveling them
-- by 0 would do nothing anyway.
SMODS.Consumable{
    key = "hoags_object",
    set = "galaxy",

    atlas = "HexStarsGalaxies",
    pos = { x = 7, y = 3 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,


    loc_txt = {
        name = "Hoag's Object",
        text = {
            "Levels up {C:attention}every{} poker hand",
            "by how many times",
            "it's been {C:attention}played{} this run",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        if G.GAME and G.GAME.hands then
            for k, hand in pairs(G.GAME.hands) do
                local times_played = hand.played or 0
                if times_played > 0 then
                    level_up_hand(card, k, true, times_played)
                end
            end
        end

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "Level Up!",
            colour = G.C.GALAXY
        })
    end,
}

-- Pinwheel Galaxy: permanently raises how many playing cards can be
-- highlighted at once by +1 per use, stacking uncapped. The actual
-- application lives in the Game:update poll further down the file
-- (right next to Polydactyly's own highlighted_limit override), which
-- reads this same persistent counter (hex_pinwheel_bonus_limit) every
-- frame -- this use function just increments it.
SMODS.Consumable{
    key = "pinwheel_galaxy",
    set = "galaxy",

    atlas = "HexStarsGalaxies",
    pos = { x = 8, y = 3 }, 

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,


    loc_txt = {
        name = "Pinwheel Galaxy",
        text = {
            "Permanently gain",
            "{C:attention}+1{} selection limit",
            "for playing cards",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        G.GAME.hex_pinwheel_bonus_limit = (G.GAME.hex_pinwheel_bonus_limit or 0) + 1

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+1 Limit",
            colour = G.C.GALAXY
        })
    end,
}





-- Small Magellanic Cloud: a one-time-use unlock card, mirroring Toi-125's
-- own unlock chain above for Star cards. Using it permanently unlocks
-- Large Magellanic Cloud (below) so it can start appearing via the
-- Spectral/Arcana pack hook and Big Bang/Sombrero Galaxy-style grants,
-- and Small Magellanic Cloud itself is removed from the Galaxy pool for
-- the rest of the run the moment it's used -- both handled by the
-- hex_get_galaxy_centers filter above, gated on the two G.GAME flags
-- set below.
SMODS.Consumable{
    key = "small_magellanic_cloud",
    set = "galaxy",

    atlas = "HexStarsGalaxies",
    pos = { x = 3, y = 3 }, 

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return not (G.GAME and G.GAME.hex_smc_used)
    end,

    loc_txt = {
        name = "Small Magellanic Cloud",
        text = {
            "Unlocks {C:attention}Large",
            "Magellanic Cloud{}",
            "{C:inactive}This card can't appear{}",
            "{C:inactive}again after being used{}",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        G.GAME.hex_smc_used = true
        G.GAME.hex_lmc_unlocked = true

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "Unlocked!",
            colour = G.C.GALAXY
        })
    end,
}

-- Large Magellanic Cloud: grants +2 Joker slots. Hidden from the Galaxy
-- pool entirely until Small Magellanic Cloud has been used (see
-- hex_get_galaxy_centers), and -- same as Small Magellanic Cloud itself
-- -- removed from that pool for the rest of the run the moment it's
-- used, via hex_lmc_used below.
SMODS.Consumable{
    key = "large_magellanic_cloud",
    set = "galaxy",

    atlas = "HexStarsGalaxies",
    pos = { x = 9, y = 3 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return (G.GAME and G.GAME.hex_lmc_unlocked and not G.GAME.hex_lmc_used) or false
    end,

    loc_txt = {
        name = "Large Magellanic Cloud",
        text = {
            "Gain {C:attention}+2{} Joker slots",
            "{C:inactive}This card can't appear{}",
            "{C:inactive}again after being used{}",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        if G.jokers and G.jokers.config then
            G.jokers.config.card_limit = G.jokers.config.card_limit + 2
        end

        G.GAME.hex_lmc_used = true

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+2 Slots",
            colour = G.C.GALAXY
        })
    end,
}


SMODS.Consumable{
    key = "tadpole_galaxy",
    set = "galaxy",

    atlas = "HexStarsGalaxies",
    pos = { x = 0, y = 4 }, 

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Tadpole Galaxy",
        text = {
            "{C:green}1 in 5{} chance to create a",
            "random {C:purple}Nebula{} card",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        if pseudorandom(pseudoseed(mod.prefix .. "_tadpole_galaxy")) < (1 / 5) then
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.1,
                func = function()
                    if G.consumeables and #G.consumeables.cards < G.consumeables.config.card_limit then
                        local nebulas = hex_get_nebula_centers()
                        if #nebulas > 0 then
                            local chosen = nebulas[math.random(#nebulas)]

                            local new_card = SMODS.create_card({
                                key = chosen.key,
                                area = G.consumeables
                            })

                            G.consumeables:emplace(new_card)

                            card_eval_status_text(new_card, "extra", nil, nil, nil, {
                                message = "Nebula!",
                                colour = G.C.NEBULA
                            })
                        end
                    end
                    return true
                end
            }))
        else
            card_eval_status_text(card, "extra", nil, nil, nil, {
                message = "Nope",
                colour = G.C.GALAXY
            })
        end
    end,
}


SMODS.Consumable{
    key = "alcyoneus",
    set = "galaxy",

    atlas = "HexStarsGalaxies",
    pos = { x = 1, y = 4 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Alcyoneus",
        text = {
            "Gives {C:attention}up to 2{} selected",
            "playing cards the",
            "{C:blue}Crystal{} enhancement",
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS["m_" .. mod.prefix .. "_crystal"]
        return { vars = {} }
    end,

    can_use = function(self, card)
        return G.hand and G.hand.highlighted
            and #G.hand.highlighted >= 1
            and #G.hand.highlighted <= 2
    end,

    use = function(self, card)
        if not (G.hand and G.hand.highlighted
        and #G.hand.highlighted >= 1
        and #G.hand.highlighted <= 2) then return end

        local targets = {}
        for _, c in ipairs(G.hand.highlighted) do
            targets[#targets + 1] = c
        end

        for _, target in ipairs(targets) do
            target:set_ability(G.P_CENTERS["m_" .. mod.prefix .. "_crystal"])
        end

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "Crystal!",
            colour = G.C.GALAXY
        })
    end,
}

-- Whirlpool Galaxy: permanently adds a bonus number of extra levels onto
-- every Planet card's own level_up_hand call, the same "persistent
-- counter read by a wrapped function" approach Canopus already uses for
-- Black Hole above. Wrapping level_up_hand globally (rather than editing
-- every individual hex_make_level_planet call) means this applies to
-- vanilla-style Planet cards and any future custom Planet added the same
-- way, automatically -- gated on the calling card's own center.set being
-- "Planet" so it never touches Vega/Hoag's Object/Ritual-driven
-- level_up_hand calls, which aren't Planet cards themselves.
local hex_old_level_up_hand_whirlpool = level_up_hand

function level_up_hand(card, hand, bypass_visual_effect, amount)
    local bonus = 0

    if card and card.config and card.config.center and card.config.center.set == "Planet" then
        bonus = (G.GAME and G.GAME.hex_whirlpool_bonus_levels) or 0
    end

    return hex_old_level_up_hand_whirlpool(card, hand, bypass_visual_effect, (amount or 1) + bonus)
end

SMODS.Consumable{
    key = "whirlpool_galaxy",
    set = "galaxy",

    atlas = "HexStarsGalaxies",
    pos = { x = 2, y = 4 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Whirlpool Galaxy",
        text = {
            "Permanently gives every",
            "{C:attention}Planet{} card",
            "{C:attention}+1{} extra level",
            "{C:inactive}(Currently +#1#){}"
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { (G.GAME and G.GAME.hex_whirlpool_bonus_levels) or 0 } }
    end,

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        G.GAME.hex_whirlpool_bonus_levels = (G.GAME.hex_whirlpool_bonus_levels or 0) + 1

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+1 Planet Level",
            colour = G.C.GALAXY
        })
    end,
}

SMODS.Consumable{
    key = "cartwheel_galaxy",
    set = "galaxy",

    atlas = "HexStarsGalaxies",
    pos = { x = 3, y = 4 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Cartwheel Galaxy",
        text = {
            "Gives {C:attention}1{} selected",
            "playing card the",
            "{C:red}Ruby{} enhancement",
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS["m_" .. mod.prefix .. "_ruby"]
        return { vars = {} }
    end,

    can_use = function(self, card)
        return G.hand and G.hand.highlighted and #G.hand.highlighted == 1
    end,

    use = function(self, card)
        if not (G.hand and G.hand.highlighted and G.hand.highlighted[1]) then return end

        local target = G.hand.highlighted[1]
        target:set_ability(G.P_CENTERS["m_" .. mod.prefix .. "_ruby"])

        card_eval_status_text(target, "extra", nil, nil, nil, {
            message = "Ruby!",
            colour = G.C.GALAXY
        })
    end,
}


SMODS.Consumable{
    key = "needle_galaxy",
    set = "galaxy",

    atlas = "HexStarsGalaxies",
    pos = { x = 4, y = 4 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Needle Galaxy",
        text = {
            "Gives {C:attention}1{} selected",
            "playing card the",
            "{C:blue}Sapphire{} enhancement",
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS["m_" .. mod.prefix .. "_sapphire"]
        return { vars = {} }
    end,

    can_use = function(self, card)
        return G.hand and G.hand.highlighted and #G.hand.highlighted == 1
    end,

    use = function(self, card)
        if not (G.hand and G.hand.highlighted and G.hand.highlighted[1]) then return end

        local target = G.hand.highlighted[1]
        target:set_ability(G.P_CENTERS["m_" .. mod.prefix .. "_sapphire"])

        card_eval_status_text(target, "extra", nil, nil, nil, {
            message = "Sapphire!",
            colour = G.C.GALAXY
        })
    end,
}


SMODS.Consumable{
    key = "sculptor_galaxy",
    set = "galaxy",

    atlas = "HexStarsGalaxies",
    pos = { x = 5, y = 4 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return not (G.GAME and G.GAME.hex_astral_unlocked)
    end,

    loc_txt = {
        name = "Sculptor Galaxy",
        text = {
            "{C:green}#1# in 100{} chance to",
            "unlock {C:astral}Astral{} cards",
            "{C:inactive}(Can't appear after{}",
            "{C:inactive}Astral cards are unlocked){}",
        }
    },

    loc_vars = function(self, info_queue, card)
        local mult = (G.GAME and G.GAME.hex_ic1101_mult) or 1
        local prob_mod = (G.GAME and G.GAME.probabilities and G.GAME.probabilities.normal) or 1
        return { vars = { 1 * mult * prob_mod } }
    end,

    can_use = function(self, card)
        return not (G.GAME and G.GAME.hex_astral_unlocked)
    end,

    use = function(self, card)
        if G.GAME.hex_astral_unlocked then return end

        local mult = (G.GAME and G.GAME.hex_ic1101_mult) or 1
        local prob_mod = (G.GAME and G.GAME.probabilities and G.GAME.probabilities.normal) or 1
        local chance = (1 / 100) * mult * prob_mod

        if pseudorandom(pseudoseed(mod.prefix .. "_sculptor_galaxy")) < chance then
            G.GAME.hex_astral_unlocked = true

            card_eval_status_text(card, "extra", nil, nil, nil, {
                message = "Astrals Unlocked!",
                colour = G.C.ASTRAL
            })
        else
            card_eval_status_text(card, "extra", nil, nil, nil, {
                message = "Nope!",
                colour = G.C.GALAXY
            })
        end
    end,
}




SMODS.Consumable{
    key = "ic_1101",
    set = "galaxy",

    atlas = "HexStarsGalaxies",
    pos = { x = 6, y = 4 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        if G.GAME and G.GAME.hex_astral_unlocked then return false end
        if G.GAME and (G.GAME.hex_ic1101_uses or 0) >= 4 then return false end
        return true
    end,

    loc_txt = {
        name = "IC 1101",
        text = {
            "{C:attention}X3{} the chance to unlock",
            "{C:astral}Astral{} cards when using",
            "{C:attention}Sculptor Galaxy{}",
            "{C:inactive}(Can be used up to 4 times){}",
            "{C:inactive}(Currently X#1#, #2#/4 uses){}",
        }
    },

    loc_vars = function(self, info_queue, card)
        local mult = (G.GAME and G.GAME.hex_ic1101_mult) or 1
        local uses = (G.GAME and G.GAME.hex_ic1101_uses) or 0
        return { vars = { mult, uses } }
    end,

    can_use = function(self, card)
        if G.GAME and G.GAME.hex_astral_unlocked then return false end
        if G.GAME and (G.GAME.hex_ic1101_uses or 0) >= 4 then return false end
        return true
    end,

    use = function(self, card)
        if G.GAME.hex_astral_unlocked then return end
        if (G.GAME.hex_ic1101_uses or 0) >= 4 then return end

        G.GAME.hex_ic1101_uses = (G.GAME.hex_ic1101_uses or 0) + 1
        G.GAME.hex_ic1101_mult = ((G.GAME.hex_ic1101_mult or 1)) * 3

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "X3 Sculptor",
            colour = G.C.GALAXY
        })
    end,
}








-- Applies a stat operation (mult/pow/tetrate) to every registered poker
-- hand's Chips and/or Mult at once -- same three ops (and the same
-- to_big()/arrow() mechanics) hex_planet_apply_stat already uses for a
-- single hand, and the same "loop over every G.GAME.hands entry"
-- approach Polaris/Eclipse already use elsewhere in this file, just
-- generalized to cover either stat, either op, and any factor.
local function hex_nebula_apply_all_hands(stats, op, factor)
    if not (G.GAME and G.GAME.hands) then return end

    for hand_key, hand in pairs(G.GAME.hands) do
        for _, stat in ipairs(stats) do
            local current = hand[stat]
            if current then
                if op == "mult" then
                    hex_set_hand_stat(hand_key, stat, to_big(current) * big(factor))
                elseif op == "pow" then
                    hex_set_hand_stat(hand_key, stat, to_big(current):arrow(1, factor))
                elseif op == "tetrate" then
                    hex_set_hand_stat(hand_key, stat, to_big(current):arrow(2, factor))
                end
            end
        end
    end
end

-- args: key, name, atlas, pos, text, stats (list of "chips"/"mult"),
-- op ("mult"/"pow"/"tetrate"), factor, status_message
local function hex_make_nebula(args)
    SMODS.Consumable{
        key = args.key,
        set = "nebula",

        atlas = args.atlas or "HexNebulasBlackholes",
        pos = args.pos,

        unlocked = true,
        discovered = true,

        in_pool = function(self) return True end, -- never naturally generated (for now); must be granted directly

        loc_txt = {
            name = args.name,
            text = args.text,
        },

        can_use = function(self, card)
            return true
        end,

        use = function(self, card)
            hex_nebula_apply_all_hands(args.stats, args.op, args.factor)

            card_eval_status_text(card, "extra", nil, nil, nil, {
                message = args.status_message,
                colour = G.C.NEBULA
            })
        end,
    }
end



hex_make_nebula{
    key = "tarantula_nebula",
    name = "Tarantula Nebula",
    atlas = "HexNebulasBlackholes",
    pos = { x = 0, y = 0 },
    stats = { "chips", "mult" },
    op = "mult",
    factor = 1000,
    text = {
        "{C:chips}Chips{} and {C:mult}Mult{} of",
        "every poker hand {C:attention}X1000{}",
    },
    status_message = "X1000 Chips/Mult",
}

hex_make_nebula{
    key = "eagle_nebula",
    name = "Eagle Nebula",
    atlas = "HexNebulasBlackholes",
    pos = { x = 0, y = 0 },
    stats = { "mult" },
    op = "mult",
    factor = 10000,
    text = {
        "{C:mult}Mult{} of every",
        "poker hand {C:mult}X10000{}",
    },
    status_message = "X10000 Mult",
}

hex_make_nebula{
    key = "crab_nebula",
    name = "Crab Nebula",
    atlas = "HexNebulasBlackholes",
    pos = { x = 0, y = 0 },
    stats = { "chips" },
    op = "mult",
    factor = 10000,
    text = {
        "{C:chips}Chips{} of every",
        "poker hand {C:chips}X10000{}",
    },
    status_message = "X10000 Chips",
}

hex_make_nebula{
    key = "cygnus_loop_nebula",
    name = "Cygnus Loop Nebula",
    atlas = "HexNebulasBlackholes",
    pos = { x = 0, y = 0 },
    stats = { "chips", "mult" },
    op = "pow",
    factor = 7.5,
    text = {
        "{C:chips}Chips{} and {C:mult}Mult{} of",
        "every poker hand {C:attention}^7.5{}",
    },
    status_message = "^7.5 Chips/Mult",
}

hex_make_nebula{
    key = "lagoon_nebula",
    name = "Lagoon Nebula",
    atlas = "HexNebulasBlackholes",
    pos = { x = 0, y = 0 },
    stats = { "mult" },
    op = "pow",
    factor = 10,
    text = {
        "{C:mult}Mult{} of every",
        "poker hand {C:mult}^10{}",
    },
    status_message = "^10 Mult",
}

hex_make_nebula{
    key = "orion_nebula",
    name = "Orion Nebula",
    atlas = "HexNebulasBlackholes",
    pos = { x = 0, y = 0 },
    stats = { "chips" },
    op = "pow",
    factor = 10,
    text = {
        "{C:chips}Chips{} of every",
        "poker hand {C:chips}^10{}",
    },
    status_message = "^10 Chips",
}

hex_make_nebula{
    key = "ring_nebula",
    name = "Ring Nebula",
    atlas = "HexNebulasBlackholes",
    pos = { x = 0, y = 0 },
    stats = { "chips", "mult" },
    op = "tetrate",
    factor = 2,
    text = {
        "{C:chips}Chips{} and {C:mult}Mult{} of",
        "every poker hand {C:attention}^^2{}",
    },
    status_message = "^^2 Chips/Mult",
}

hex_make_nebula{
    key = "helix_nebula",
    name = "Helix Nebula",
    atlas = "HexNebulasBlackholes",
    pos = { x = 0, y = 0 },
    stats = { "mult" },
    op = "tetrate",
    factor = 2.5,
    text = {
        "{C:mult}Mult{} of every",
        "poker hand {C:mult}^^2.5{}",
    },
    status_message = "^^2.5 Mult",
}

hex_make_nebula{
    key = "butterfly_nebula",
    name = "Butterfly Nebula",
    atlas = "HexNebulasBlackholes",
    pos = { x = 0, y = 0 },
    stats = { "chips" },
    op = "tetrate",
    factor = 2.5,
    text = {
        "{C:chips}Chips{} of every",
        "poker hand {C:chips}^^2.5{}",
    },
    status_message = "^^2.5 Chips",
}





SMODS.Consumable{
    key = "exoplanet",
    set = "astral",

    atlas = "HexAstralsCosmics",
    pos = { x = 0, y = 0 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true -- never naturally generated; must be granted directly
    end,

    loc_txt = {
        name = "Exoplanet",
        text = {
            "Creates {C:attention}2{} {C:dark_red}Negative{}",
            "{C:purple}Nebula{} cards",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        for i = 1, 2 do
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.2 * i,
                func = function()
                    if G.consumeables then
                        local nebulas = hex_get_nebula_centers()
                        if #nebulas > 0 then
                            local chosen = nebulas[math.random(#nebulas)]

                            local new_card = SMODS.create_card({
                                key = chosen.key,
                                area = G.consumeables
                            })

                            new_card:set_edition({ negative = true }, true)

                            G.consumeables:emplace(new_card)
                        end
                    end
                    return true
                end
            }))
        end

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+2 Negative",
            colour = G.C.ASTRAL
        })
    end,
}


SMODS.Consumable{
    key = "brown_dwarf",
    set = "astral",

    atlas = "HexAstralsCosmics",
    pos = { x = 0, y = 0 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true -- never naturally generated; must be granted directly
    end,

    loc_txt = {
        name = "Brown Dwarf",
        text = {
            "{C:money}X10{} your money",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        G.GAME.dollars = to_big(G.GAME.dollars or 0):mul(big(10))

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "X10 Money",
            colour = G.C.ASTRAL
        })
    end,
}


SMODS.Consumable{
    key = "white_dwarf",
    set = "astral",

    atlas = "HexAstralsCosmics",
    pos = { x = 0, y = 0 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true -- never naturally generated; must be granted directly
    end,

    loc_txt = {
        name = "White Dwarf",
        text = {
            "Gain {C:purple}300{}",
            "{C:purple}Hex points{}",
            "{C:attention}-2{} hand size,",
            "{C:attention}-2{} hands and",
            "{C:attention}-2{} discards every round",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        G.GAME.hex_points = (G.GAME.hex_points or big(0)):add(big(300)) -- White Dwarf, CHANGED

        G.GAME.round_resets.hand_size = math.max(1, (G.GAME.round_resets.hand_size or 8) - 2)
        G.GAME.round_resets.hands = math.max(1, (G.GAME.round_resets.hands or 4) - 2)
        G.GAME.round_resets.discards = math.max(0, (G.GAME.round_resets.discards or 3) - 2)

        if G.GAME.current_round then
            G.GAME.current_round.hands_left = math.max(1, (G.GAME.current_round.hands_left or 0) - 2)
            G.GAME.current_round.discards_left = math.max(0, (G.GAME.current_round.discards_left or 0) - 2)
        end

        -- Hand size shrink is applied to the live hand immediately, same
        -- fixup Hard Deck's start_run hook uses -- trims the hand down to
        -- the new limit, returning the excess cards to the deck.
        if G.hand and G.hand.config then
            G.hand.config.card_limit = math.max(1, G.hand.config.card_limit - 2)

            if G.deck then
                for i = #G.hand.cards, 1, -1 do
                    if #G.hand.cards <= G.hand.config.card_limit then break end
                    local c = G.hand:remove_card(G.hand.cards[i])
                    if c then
                        G.deck:emplace(c)
                    end
                end
            end
        end

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+300 Hex",
            colour = G.C.ASTRAL
        })
    end,
}

SMODS.Consumable{
    key = "neutron_star",
    set = "astral",

    atlas = "HexAstralsCosmics",
    pos = { x = 0, y = 0 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true -- never naturally generated; must be granted directly
    end,

    loc_txt = {
        name = "Neutron Star",
        text = {
            "Gives {C:attention}1{} selected",
            "playing card the",
            "{C:blue}Diamond{} enhancement",
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS["m_" .. mod.prefix .. "_diamond"]
        return { vars = {} }
    end,

    can_use = function(self, card)
        return G.hand and G.hand.highlighted and #G.hand.highlighted == 1
    end,

    use = function(self, card)
        if not (G.hand and G.hand.highlighted and G.hand.highlighted[1]) then return end

        local target = G.hand.highlighted[1]
        target:set_ability(G.P_CENTERS["m_" .. mod.prefix .. "_diamond"])

        card_eval_status_text(target, "extra", nil, nil, nil, {
            message = "Diamond!",
            colour = G.C.ASTRAL
        })
    end,
}

SMODS.Consumable{
    key = "quasars",
    set = "astral",

    atlas = "HexAstralsCosmics",
    pos = { x = 0, y = 0 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true -- never naturally generated; must be granted directly
    end,

    loc_txt = {
        name = "Quasar",
        text = {
            "{C:attention}X10{} the chance for",
            "{C:legendary}The Soul{} and {C:mythic}Heart{}",
            "to appear in {C:tarot}Arcana{} and",
            "{C:spectral}Spectral{} packs",
            "{C:inactive}(Can only be used once){}",
        }
    },

    can_use = function(self, card)
        return not (G.GAME and G.GAME.hex_quasars_used)
    end,

    use = function(self, card)
        if G.GAME.hex_quasars_used then return end
        G.GAME.hex_quasars_used = true

        local soul_center = G.P_CENTERS[HEX_SOUL_CENTER_KEY]
        if soul_center and soul_center.soul_rate then
            soul_center.soul_rate = soul_center.soul_rate * 10
        end

        local heart_center = G.P_CENTERS[HEX_HEART_CENTER_KEY]
        if heart_center and heart_center.soul_rate then
            heart_center.soul_rate = heart_center.soul_rate * 10
        end

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "X10 Soul/Heart",
            colour = G.C.ASTRAL
        })
    end,
}


SMODS.Consumable{
    key = "quark_star",
    set = "astral",

    atlas = "HexAstralsCosmics",
    pos = { x = 0, y = 0 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true -- never naturally generated; must be granted directly
    end,

    loc_txt = {
        name = "Quark Star",
        text = {
            "Gain {C:attention}+2{} Joker slots",
            "{C:inactive}(Can only be used once){}",
        }
    },

    can_use = function(self, card)
        return not (G.GAME and G.GAME.hex_quark_star_used)
    end,

    use = function(self, card)
        if G.GAME.hex_quark_star_used then return end
        G.GAME.hex_quark_star_used = true

        if G.jokers and G.jokers.config then
            G.jokers.config.card_limit = G.jokers.config.card_limit + 2
        end

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+2 Slots",
            colour = G.C.ASTRAL
        })
    end,
}

SMODS.Consumable{
    key = "boson_star",
    set = "astral",

    atlas = "HexAstralsCosmics",
    pos = { x = 0, y = 0 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true -- never naturally generated; must be granted directly
    end,

    loc_txt = {
        name = "Boson Star",
        text = {
            "Gain {C:purple}75{}",
            "{C:purple}Hex points{}",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        G.GAME.hex_points = (G.GAME.hex_points or big(0)):add(big(75))  -- Boson Star, CHANGED

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+75 Hex",
            colour = G.C.ASTRAL
        })
    end,
}


SMODS.Consumable{
    key = "white_hole",
    set = "astral",

    atlas = "HexAstralsCosmics",
    pos = { x = 0, y = 0 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true -- never naturally generated; must be granted directly
    end,

    loc_txt = {
        name = "White Hole",
        text = {
            "Gives a {C:attention}random{} Joker",
            "{C:attention}without an Edition{}",
            "the {C:purple}Radiant{} edition",
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS["e_" .. mod.prefix .. "_radiant"]
        return { vars = {} }
    end,

    -- Shared helper so can_use and use always agree on what's eligible.
    can_use = function(self, card)
        if not (G.jokers and G.jokers.cards) then return false end

        for _, j in ipairs(G.jokers.cards) do
            if not j.edition then
                return true
            end
        end

        return false
    end,

    use = function(self, card)
        if not (G.jokers and G.jokers.cards) then return end

        local eligible = {}
        for _, j in ipairs(G.jokers.cards) do
            if not j.edition then
                eligible[#eligible + 1] = j
            end
        end

        if not eligible[1] then return end

        local chosen_joker = pseudorandom_element(
            eligible,
            pseudoseed(mod.prefix .. "_white_hole_joker")
        )

        chosen_joker:set_edition({ [mod.prefix .. "_radiant"] = true }, true)

        card_eval_status_text(chosen_joker, "extra", nil, nil, nil, {
            message = localize("k_upgrade_ex"),
            colour = G.C.ASTRAL
        })
    end,
}



-- Wormhole: permanently adds +1 to the number of cards shown in every
-- booster pack opened (Arcana, Celestial, Spectral, Standard, Buffoon,
-- and this mod's own Star/Galaxy packs alike), stacking with itself up
-- to +10 total. self.ability.extra is the runtime field Card:open reads
-- to know how many cards to generate for a given pack -- it's set at
-- card-creation time from the Booster's own config.extra (the same field
-- every SMODS.Booster{ config = { extra = N, ... } } registration in
-- this file sets), so bumping it here, right before the original open()
-- call runs, affects the pack about to be opened without needing to
-- touch the Booster's own definition at all.
local hex_old_card_open = Card.open

function Card:open(...)
    if self.ability and self.ability.set == "Booster" then
        local bonus = (G.GAME and G.GAME.hex_wormhole_bonus) or 0
        if bonus > 0 and self.ability.extra then
            self.ability.extra = self.ability.extra + bonus
        end
    end

    return hex_old_card_open(self, ...)
end


SMODS.Consumable{
    key = "wormhole",
    set = "astral",

    atlas = "HexAstralsCosmics",
    pos = { x = 0, y = 0 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return ((G.GAME and G.GAME.hex_wormhole_bonus) or 0) < 10
    end,

    loc_txt = {
        name = "Wormhole",
        text = {
            "Permanently gain {C:attention}+1{}",
            "card in every {C:attention}booster pack{}",
            "{C:inactive}(Max of +10){}",
            "{C:inactive}(Currently +#1#){}",
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { (G.GAME and G.GAME.hex_wormhole_bonus) or 0 } }
    end,

    can_use = function(self, card)
        return ((G.GAME and G.GAME.hex_wormhole_bonus) or 0) < 10
    end,

    use = function(self, card)
        if ((G.GAME and G.GAME.hex_wormhole_bonus) or 0) >= 10 then return end

        G.GAME.hex_wormhole_bonus = (G.GAME.hex_wormhole_bonus or 0) + 1

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+1 Pack Size",
            colour = G.C.ASTRAL
        })
    end,
}



-- Planck Star: a one-time-use unlock card, mirroring Sculptor Galaxy's
-- own Astral-unlock pattern and Toi-125/Small Magellanic Cloud's own
-- "removed from the pool after use" pattern. Using it permanently
-- unlocks Cosmic cards (see hex_get_cosmic_centers and the Star/Galaxy
-- Pack create_card hooks below for how they actually enter play) at a
-- steep, immediate cost -- and Planck Star itself is removed from the
-- Astral pool for the rest of the run the moment it's used.
SMODS.Consumable{
    key = "planck_star",
    set = "astral",

    atlas = "HexAstralsCosmics",
    pos = { x = 0, y = 0 }, -- next open frame in the atlas; adjust if taken

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return not (G.GAME and G.GAME.hex_planck_star_used)
    end,

    loc_txt = {
        name = "Planck Star",
        text = {
            "Unlocks {C:cosmic}Cosmic{} cards",
            "{C:attention}-3{} hand size, {C:attention}-3{} hands",
            "and {C:attention}-3{} discards every round",
            "{C:attention}-3{} Joker slots",
            "Sets {C:money}money{} to {C:money}$0{}",
            "{C:inactive}This card can't appear{}",
            "{C:inactive}again after being used{}",
        }
    },

    -- Requires at least 3 *empty* Joker slots (so shrinking the limit by
    -- 3 can never leave you with more Jokers than slots), and requires
    -- the total slot count to be more than 3 to begin with (so the
    -- limit can never be reduced down to 0 or below).
    can_use = function(self, card)
        if not (G.jokers and G.jokers.config) then return false end

        local total = G.jokers.config.card_limit or 0
        local owned = #G.jokers.cards

        return total > 3 and (total - owned) >= 3
    end,

    use = function(self, card)
        G.GAME.hex_planck_star_used = true
        G.GAME.hex_cosmic_unlocked = true

        -- Hand size / hands / discards every round -- same round_resets +
        -- current_round pairing White Dwarf's own -2/-2/-2 penalty uses
        -- above, just -3 each and with a hard floor so nothing goes
        -- unplayable.
        G.GAME.round_resets.hand_size = math.max(1, (G.GAME.round_resets.hand_size or 8) - 3)
        G.GAME.round_resets.hands = math.max(1, (G.GAME.round_resets.hands or 4) - 3)
        G.GAME.round_resets.discards = math.max(0, (G.GAME.round_resets.discards or 3) - 3)

        if G.GAME.current_round then
            G.GAME.current_round.hands_left = math.max(1, (G.GAME.current_round.hands_left or 0) - 3)
            G.GAME.current_round.discards_left = math.max(0, (G.GAME.current_round.discards_left or 0) - 3)
        end

        -- Hand size shrink applied to the live hand immediately, same
        -- fixup Hard Deck/White Dwarf use -- trims the hand down to the
        -- new limit, returning the excess cards to the deck.
        if G.hand and G.hand.config then
            G.hand.config.card_limit = math.max(1, G.hand.config.card_limit - 3)

            if G.deck then
                for i = #G.hand.cards, 1, -1 do
                    if #G.hand.cards <= G.hand.config.card_limit then break end
                    local c = G.hand:remove_card(G.hand.cards[i])
                    if c then
                        G.deck:emplace(c)
                    end
                end
            end
        end

        -- Joker slots -- floored at 1 so this can never fully lock you
        -- out of having a Joker.
        if G.jokers and G.jokers.config then
            G.jokers.config.card_limit = math.max(1, G.jokers.config.card_limit - 3)
        end

        -- Money
        G.GAME.dollars = big(0)

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "Cosmics Unlocked!",
            colour = G.C.COSMIC
        })
    end,
}







-- Shared rarity->Hex-value table and calculation, used by both the
-- manual HEX sacrifice button (G.FUNCS.hex_sacrifice, defined later in
-- the file) and Huge-LQG below. Declared here, early, since Huge-LQG is
-- defined before the button's own code appears later in the file.
local hex_sacrifice_values = {
    [1] = big(1),
    [2] = big(2),
    [3] = big(5),
    [4] = big(20),
    ["hex_mythic"] = big(50),
    ["hex_transcendental"] = big(250),
    ["hex_divine"] = big(5000),
}

-- Computes the Hex-point gain for hexing/sacrificing a given Joker card,
-- applying Cursed Deck's double and The Monolith's flat bonus in that
-- order -- the exact same order G.FUNCS.hex_sacrifice itself applies
-- them in, since it now calls this same function.
-- Computes the Hex-point gain for hexing/sacrificing a given Joker card,
-- applying Laniakea Supercluster's permanent X2 (if used), then Cursed
-- Deck's double, then The Monolith's flat bonus -- the exact same order
-- G.FUNCS.hex_sacrifice and Huge-LQG both go through, since they now
-- call this same function.
local function hex_compute_sacrifice_gain(card)
    local rarity = card.config.center.rarity
    local gain = hex_sacrifice_values[rarity] or big(0)

    if gain:gt(big(0)) then
        if G.GAME and G.GAME.hex_laniakea_used then
            gain = gain:mul(big(2))
        end

        if hex_cursed_deck_selected() then
            gain = gain:mul(big(2))
        end

        local monolith_count = #SMODS.find_card("j_" .. mod.prefix .. "_the_monolith")
        if monolith_count > 0 then
            gain = gain:add(big(monolith_count)) 
        end
    end

    return gain
end



-- ============================================================
-- Cosmic cards
-- Rare -- like Astral cards, these never appear via shop_rate
-- (0 on the "cosmic" ConsumableType above) or any create_card
-- injection anywhere in this file; they only ever enter play if
-- something (a future Joker/Voucher/Ritual, etc.) grants them
-- directly.
-- ============================================================



-- Virgo Cluster: creates 5 Negative copies of vanilla's own Soul card
-- (the Spectral that creates a Legendary Joker) and 3 Negative copies of
-- this mod's own Heart card (the Mythic-Joker-creating counterpart to
-- Soul) -- same staggered create+force-Negative pattern Rigel/Sombrero
-- Galaxy use above, and the same forced-key SMODS.create_card call
-- Black Seal's own Spectral grant uses, just pointed at these two exact
-- keys instead of drawing randomly. Deliberately no consumable-slot-
-- limit check, matching Rigel/Sombrero Galaxy's own precedent -- every
-- one of the 8 cards is always created regardless of how full
-- G.consumeables already is.
SMODS.Consumable{
    key = "virgo_cluster",
    set = "cosmic",

    atlas = "HexAstralsCosmics",
    pos = { x = 0, y = 2 }, -- placeholder, adjust before shipping

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true -- never naturally generated; must be granted directly
    end,

    loc_txt = {
        name = "Virgo Cluster",
        text = {
            "Creates {C:attention}5{} {C:dark_red}Negative",
            "{C:legendary}The Soul{} cards and {C:attention}3{}",
            "{C:dark_red}Negative{} {C:mythic}The Heart{} cards",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        -- 5 Negative Soul cards
        for i = 1, 5 do
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.15 * i,
                func = function()
                    if G.consumeables then
                        local new_card = SMODS.create_card({
                            key = HEX_SOUL_CENTER_KEY,
                            area = G.consumeables
                        })

                        new_card:set_edition({ negative = true }, true)

                        G.consumeables:emplace(new_card)
                    end
                    return true
                end
            }))
        end

        -- 3 Negative Heart cards, staggered to start right after the
        -- 5 Soul cards above finish their own staggered creation.
        for i = 1, 3 do
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.15 * (5 + i),
                func = function()
                    if G.consumeables then
                        local new_card = SMODS.create_card({
                            key = HEX_HEART_CENTER_KEY,
                            area = G.consumeables
                        })

                        new_card:set_edition({ negative = true }, true)

                        G.consumeables:emplace(new_card)
                    end
                    return true
                end
            }))
        end

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+8 Negative",
            colour = G.C.COSMIC
        })
    end,
}




SMODS.Consumable{
    key = "laniakea_supercluster",
    set = "cosmic",

    atlas = "HexAstralsCosmics",
    pos = { x = 0, y = 2 }, -- placeholder, adjust before shipping

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return not (G.GAME and G.GAME.hex_laniakea_used)
    end,

    loc_txt = {
        name = "Laniakea Supercluster",
        text = {
            "Permanently {C:attention}doubles{} the",
            "{C:purple}Hex points{} gained from",
            "hexing Jokers",
            "{C:inactive}This card can't appear{}",
            "{C:inactive}again after being used{}",
        }
    },

    can_use = function(self, card)
        return not (G.GAME and G.GAME.hex_laniakea_used)
    end,

    use = function(self, card)
        if G.GAME.hex_laniakea_used then return end
        G.GAME.hex_laniakea_used = true

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "X2 Hex Gain!",
            colour = G.C.COSMIC
        })
    end,
}





SMODS.Consumable{
    key = "shapley_supercluster",
    set = "cosmic",

    atlas = "HexAstralsCosmics",
    pos = { x = 0, y = 2 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true -- never naturally generated; must be granted directly
    end,

    loc_txt = {
        name = "Shapley Supercluster",
        text = {
            "Gain {C:attention}+1{}",
            "{C:attention}Joker slot{}",
        }
    },

    can_use = function(self, card)
        return true
    end,

    -- No "used" flag -- unlike Toi-125/Small Magellanic Cloud etc.,
    -- this stays in the pool and can be used again every time you get
    -- another copy, same reusable pattern as Arcturus (+1 consumable
    -- slot) above.
    use = function(self, card)
        if G.jokers and G.jokers.config then
            G.jokers.config.card_limit = G.jokers.config.card_limit + 1
        end

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+1 Slot",
            colour = G.C.COSMIC
        })
    end,
}

SMODS.Consumable{
    key = "pisces_cetus_supercluster",
    set = "cosmic",

    atlas = "HexAstralsCosmics",
    pos = { x = 0, y = 2 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true -- never naturally generated; must be granted directly
    end,

    loc_txt = {
        name = "Pisces-Cetus Supercluster",
        text = {
            "{C:purple}Doubles{} your",
            "{C:purple}Hex points{}",
            "{C:inactive}(Max gain of 303){}",
        }
    },

    can_use = function(self, card)
        return true
    end,

    -- Comparison/arithmetic operators on OmegaNum values already work
    -- fine elsewhere in this file (e.g. the cost checks in
    -- summon_transcendental/summon_divine), so this stays safe even
    -- once Hex points scale well past double-precision range.
    use = function(self, card)
        local current = (G.GAME and G.GAME.hex_points) or big(0)
        local cap = big(303)

        local gain = current:min(cap)

        G.GAME.hex_points = current:add(gain)

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+" .. tostring(gain) .. " Hex",
            colour = G.C.COSMIC
        })
    end,
}

SMODS.Consumable{
    key = "giant_grb_ring",
    set = "cosmic",

    atlas = "HexAstralsCosmics",
    pos = { x = 0, y = 2},

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true -- never naturally generated; must be granted directly
    end,

    loc_txt = {
        name = "Giant GRB Ring",
        text = {
            "Destroys {C:attention}3{} random",
            "owned Jokers",
            "Gain {C:purple}1000{}",
            "{C:purple}Hex points{}",
        }
    },

    -- Reuses hex_andromeda_eligible_jokers (defined above under the
    -- Galaxy cards / Andromeda section) so anything
    -- carrying the Immortal sticker (i.e. Absolute) can never be
    -- destroyed by this either.
    can_use = function(self, card)
        return #hex_andromeda_eligible_jokers() > 0
    end,

    use = function(self, card)
        local eligible = hex_andromeda_eligible_jokers()

        -- Destroys up to 3 -- fewer if there aren't 3 eligible Jokers
        -- to pick from, same "take what's available" fallback used
        -- elsewhere in this file rather than failing outright.
        local to_destroy = {}
        for i = 1, math.min(3, #eligible) do
            local pick = pseudorandom_element(eligible, pseudoseed(mod.prefix .. "_grb_ring_" .. i))
            to_destroy[#to_destroy + 1] = pick

            for j, c in ipairs(eligible) do
                if c == pick then
                    table.remove(eligible, j)
                    break
                end
            end
        end

        for i, j in ipairs(to_destroy) do
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.15 * i,
                func = function()
                    j:start_dissolve()
                    return true
                end
            }))
        end

        G.GAME.hex_points = (G.GAME.hex_points or big(0)):add(big(1000)) -- Giant GRB Ring, CHANGED

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+1000 Hex",
            colour = G.C.COSMIC
        })
    end,
}




-- Helper: eligible Jokers for Huge-LQG's random hex -- same exclusions
-- G.FUNCS.hex_sacrifice itself enforces (Eternal Jokers and Absolute can
-- never be hexed), reusing hex_apply_immortal_sticker's own key so this
-- also can never target anything carrying the Immortal sticker.
local function hex_huge_lqg_eligible_jokers()
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

SMODS.Consumable{
    key = "huge_lqg",
    set = "cosmic",

    atlas = "HexAstralsCosmics",
    pos = { x = 0, y = 2 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true -- never naturally generated; must be granted directly
    end,

    loc_txt = {
        name = "Huge-LQG",
        text = {
            "Hexes a {C:attention}random{} Joker for",
            "{C:attention}X50{} the normal",
            "{C:purple}Hex point{} value",
        }
    },

    can_use = function(self, card)
        return #hex_huge_lqg_eligible_jokers() > 0
    end,

    use = function(self, card)
        local eligible = hex_huge_lqg_eligible_jokers()
        if not eligible[1] then return end

        local chosen = pseudorandom_element(eligible, pseudoseed(mod.prefix .. "_huge_lqg"))

        -- X50 is applied AFTER Cursed Deck's double and Monolith's flat
        -- bonus, since hex_compute_sacrifice_gain already folds both of
        -- those in before returning.
        local gain = hex_compute_sacrifice_gain(chosen):mul(big(50)) -- CHANGED: was * big(50)

        if gain:gt(big(0)) then -- CHANGED: was gain > big(0)
            G.GAME.hex_points = (G.GAME.hex_points or big(0)):add(gain) -- CHANGED: was + gain
            
            card_eval_status_text(chosen, "extra", nil, nil, nil, {
                message = "+" .. tostring(gain) .. " Hex",
                colour = G.C.COSMIC
            })

            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.3,
                func = function()
                    chosen:start_dissolve()
                    return true
                end
            }))
        end
    end,
}






-- Helper: every registered Black Hole center, mirroring
-- hex_get_nebula_centers/hex_get_astral_centers -- excludes already-owned
-- Black Hole consumables unless Showman is owned.
local function hex_get_black_hole_centers()
    local out = {}
    local showman = hex_owns_showman()

    for _, center in pairs(G.P_CENTERS) do
        if center.set == "black_hole" then
            local skip = false

            if not showman and hex_consumable_already_owned(center.key) then
                skip = true
            end

            if not skip then
                out[#out + 1] = center
            end
        end
    end

    return out
end

SMODS.Consumable{
    key = "local_void",
    set = "cosmic",

    atlas = "HexAstralsCosmics",
    pos = { x = 0, y = 2 }, -- placeholder, adjust before shipping

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true -- never naturally generated; must be granted directly
    end,

    loc_txt = {
        name = "Local Void",
        text = {
            "Creates a random",
            "{C:blue}Black Hole{} card",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        if G.consumeables and #G.consumeables.cards < G.consumeables.config.card_limit then
            local black_holes = hex_get_black_hole_centers()

            if #black_holes > 0 then
                local chosen = black_holes[math.random(#black_holes)]

                local new_card = SMODS.create_card({
                    key = chosen.key,
                    area = G.consumeables
                })

                G.consumeables:emplace(new_card)

                card_eval_status_text(new_card, "extra", nil, nil, nil, {
                    message = "Black Hole!",
                    colour = G.C.BLACK_HOLE
                })
            end
        end
    end,
}

SMODS.Consumable{
    key = "bootes_void",
    set = "cosmic",

    atlas = "HexAstralsCosmics",
    pos = { x = 0, y = 2 }, -- placeholder, adjust before shipping

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true -- never naturally generated; must be granted directly
    end,

    loc_txt = {
        name = "Boötes Void",
        text = {
            "{C:money}X1729{} your money",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        local current = to_big((G.GAME and G.GAME.dollars) or 0)
        local result = current:mul(big(1729))

        G.GAME.dollars = result -- CHANGED: was hex_to_plain_number(result) -- keep it big now that dollars itself is OmegaNum

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "X1729 Money",
            colour = G.C.COSMIC
        })
    end,
}


-- Giant Arc: permanently raises how many cards can be *chosen* from every
-- booster pack opened (Arcana, Celestial, Spectral, Standard, Buffoon,
-- and this mod's own Star/Galaxy/Black Hole packs alike), by +1 per use,
-- capped at a total bonus of +10. Mirrors Wormhole's own Card:open hook
-- above almost exactly, just targeting self.ability.choose (the runtime
-- field mirroring a Booster's own config.choose) instead of
-- self.ability.extra (config.extra, the number of cards shown).
local hex_old_card_open_giant_arc = Card.open

function Card:open(...)
    if self.ability and self.ability.set == "Booster" then
        local bonus = (G.GAME and G.GAME.hex_giant_arc_bonus) or 0
        if bonus > 0 and self.ability.choose then
            self.ability.choose = self.ability.choose + bonus
        end
    end

    return hex_old_card_open_giant_arc(self, ...)
end

SMODS.Consumable{
    key = "giant_arc",
    set = "cosmic",

    atlas = "HexAstralsCosmics",
    pos = { x = 0, y = 2 }, -- placeholder, adjust before shipping

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return ((G.GAME and G.GAME.hex_giant_arc_bonus) or 0) < 10
    end,

    loc_txt = {
        name = "Giant Arc",
        text = {
            "Permanently gain {C:attention}+1{}",
            "selection limit in {C:attention}booster packs{}",
            "{C:inactive}(Max of +10){}",
            "{C:inactive}(Currently +#1#){}",
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { (G.GAME and G.GAME.hex_giant_arc_bonus) or 0 } }
    end,

    can_use = function(self, card)
        return ((G.GAME and G.GAME.hex_giant_arc_bonus) or 0) < 10
    end,

    use = function(self, card)
        if ((G.GAME and G.GAME.hex_giant_arc_bonus) or 0) >= 10 then return end

        G.GAME.hex_giant_arc_bonus = (G.GAME.hex_giant_arc_bonus or 0) + 1

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+1 Selection",
            colour = G.C.COSMIC
        })
    end,
}









--==================== Black holes ================



-- Loops over every registered poker hand and lets `fn(hand)` mutate its
-- .chips/.mult fields directly -- same "loop over every G.GAME.hands
-- entry" approach Polaris/Eclipse/Nebula cards already use elsewhere in
-- this file.
local function hex_black_hole_apply_all_hands(fn)
    if not (G.GAME and G.GAME.hands) then return end

    for hand_key, hand in pairs(G.GAME.hands) do
        fn(hand_key, hand)
    end
end

-- Cygnus X-1: raises every hand's Mult to the power of (10^Chips).
-- 10^chips is computed first as its own OmegaNum value
-- (big(10):arrow(1, chips)), then used as the exponent for Mult's own
-- arrow(1, ...) power.
SMODS.Consumable{
    key = "cygnus_x1",
    set = "black_hole",

    atlas = "HexNebulasBlackholes",
    pos = { x = 0, y = 3 }, -- placeholder, adjust before shipping

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true -- never naturally generated; must be granted directly
    end,

    loc_txt = {
        name = "Cygnus X-1",
        text = {
            "{C:mult}Mult{} of every poker hand",
            "is raised to the power of",
            "{C:attention}10^Chips{}",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        hex_black_hole_apply_all_hands(function(hand_key, hand)
            if hand.mult and hand.chips then
                local exponent = big(10):arrow(1, hand.chips)
                hex_set_hand_stat(hand_key, "mult", to_big(hand.mult):arrow(1, exponent))
            end
        end)

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "^(10^Chips) Mult",
            colour = G.C.BLACK_HOLE
        })
    end,
}

-- Messier 87: mirror of Cygnus X-1, raising Chips to the power of
-- (10^Mult) instead.
SMODS.Consumable{
    key = "messier_87",
    set = "black_hole",

    atlas = "HexNebulasBlackholes",
    pos = { x = 0, y = 3 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Messier 87",
        text = {
            "{C:chips}Chips{} of every poker hand",
            "is raised to the power of",
            "{C:attention}10^Mult{}",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        hex_black_hole_apply_all_hands(function(hand_key, hand)
            if hand.chips and hand.mult then
                local exponent = big(10):arrow(1, hand.mult)
                hex_set_hand_stat(hand_key, "chips", to_big(hand.chips):arrow(1, exponent))
            end
        end)

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "^(10^Mult) Chips",
            colour = G.C.BLACK_HOLE
        })
    end,
}

-- Sagittarius A*: tetrates every hand's Chips to a height of
-- Mult^0.5 (i.e. sqrt(Mult)), computed entirely in OmegaNum space via
-- arrow(1, 0.5) rather than converting down to a plain Lua number, so
-- this never risks the plain-number-inf issue that crashed arrow()
-- before.
SMODS.Consumable{
    key = "sagittarius_a_star",
    set = "black_hole",

    atlas = "HexNebulasBlackholes",
    pos = { x = 0, y = 3 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Sagittarius A*",
        text = {
            "{C:chips}Chips{} of every poker hand",
            "is tetrated to",
            "{C:attention}Mult^0.5{}",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        hex_black_hole_apply_all_hands(function(hand_key, hand)
            if hand.chips and hand.mult then
                local height = to_big(hand.mult):arrow(1, 0.5)
                hex_set_hand_stat(hand_key, "chips", to_big(hand.chips):arrow(2, height))
            end
        end)

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "^^(Mult^0.5)",
            colour = G.C.BLACK_HOLE
        })
    end,
}

-- Centaurus A: mirror of Sagittarius A*, tetrating Mult to a height of
-- Chips^0.5 instead, same big()/arrow()-only approach.
SMODS.Consumable{
    key = "centaurus_a",
    set = "black_hole",

    atlas = "HexNebulasBlackholes",
    pos = { x = 0, y = 3 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "Centaurus A",
        text = {
            "{C:mult}Mult{} of every poker hand",
            "is tetrated to",
            "{C:attention}Chips^0.5{}",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        hex_black_hole_apply_all_hands(function(hand_key, hand)
            if hand.mult and hand.chips then
                local height = to_big(hand.chips):arrow(1, 0.5)
                hex_set_hand_stat(hand_key, "mult", to_big(hand.mult):arrow(2, height))
            end
        end)

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "^^(Chips^0.5)",
            colour = G.C.BLACK_HOLE
        })
    end,
}

-- TON 618: the biggest known black hole, and the strongest card here --
-- pentates (arrow(3, ...)) both Chips and Mult of every poker hand to a
-- height of 1.1.
SMODS.Consumable{
    key = "ton_618",
    set = "black_hole",

    atlas = "HexNebulasBlackholes",
    pos = { x = 0, y = 3 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return true
    end,

    loc_txt = {
        name = "TON 618",
        text = {
            "{C:chips}Chips{} and {C:mult}Mult{} of",
            "every poker hand are",
            "pentated to {C:attention}^^^1.1{}",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        hex_black_hole_apply_all_hands(function(hand_key, hand)
            if hand.chips then
                hex_set_hand_stat(hand_key, "chips", to_big(hand.chips):arrow(3, 1.1))
            end
            if hand.mult then
                hex_set_hand_stat(hand_key, "mult", to_big(hand.mult):arrow(3, 1.1))
            end
        end)

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "^^^1.1 Chips/Mult",
            colour = G.C.BLACK_HOLE
        })
    end,
}


















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
local hex_operator_names = {
    [0] = "Chips x Mult",
    [1] = "Chips ^ Mult",
    [2] = "Chips ^^ Mult",
    [3] = "Chips ^^^ Mult",
    [4] = "Chips ^^^^ Mult",
}

local function hex_operator_name(level)
    return hex_operator_names[level]
        or ("Chips {" .. tostring(level) .. "} Mult")
end

-- Register a custom scoring calculation with Steamodded's Chip-Mult
-- Operator API (SMODS.Scoring_Calculation). This replaces the *entire*
-- chips/mult combination step for a hand, rather than nudging `mult`
-- mid-scoring like exponent_joker does. We capture the returned object so
-- we always call SMODS.set_scoring_calculation with the exact key
-- Steamodded assigned to it, instead of guessing how it gets prefixed.
-- `to_big(chips):arrow(n, mult)` is Amulet's OmegaNum hyperoperator:
--   arrow(1, b) = a ^ b            (exponentiation)
--   arrow(2, b) = a ^^ b            (tetration)
--   arrow(3, b) = a ^^^ b           (pentation)
--   ...and so on, all fully OmegaNum-safe past 1.7e308.
-- Converts a (possibly OmegaNum/big) value into a plain Lua number,
-- best-effort. Amulet's OmegaNum cdata doesn't expose one single
-- guaranteed accessor across versions, so we try the common method names
-- before falling back to string parsing (tostring on an OmegaNum prints
-- something Lua's tonumber can still read, e.g. "1.23e+45").
local function hex_to_plain_number(value)
    if type(value) == "number" then
        return value
    end
    if type(value) == "table" or type(value) == "cdata" then
        if value.to_number then
            local ok, n = pcall(function() return value:to_number() end)
            if ok and type(n) == "number" then return n end
        end
        if value.toNumber then
            local ok, n = pcall(function() return value:toNumber() end)
            if ok and type(n) == "number" then return n end
        end
    end
    local n = tonumber(tostring(value))
    return n or 0
end

-- Absolute: while owned, the Chips/Mult operator's hyperoperator level is
-- boosted 1-for-1 by however many Hex points you currently have, stacking
-- on top of whatever level Hyperbolic has permanently bought. Unlike
-- Hyperbolic's level, this is fully dynamic -- it rises and falls in
-- real time as your Hex points change (e.g. spending them on a summon
-- drops the level right back down).
local function hex_absolute_bonus_level()
    if not (SMODS.find_card and G.GAME) then return 0 end
    if #SMODS.find_card("j_" .. mod.prefix .. "_absolute") == 0 then return 0 end

    local points = hex_to_plain_number(G.GAME.hex_points or 0)
    if points <= 0 then return 0 end

    return math.floor(points)
end

local hex_hyperbolic_calc = nil

if SMODS.Scoring_Calculation then
    hex_hyperbolic_calc = SMODS.Scoring_Calculation{
        key = "hex_hyperbolic",
        func = function(self, chips, mult, flames)
            local level = ((G.GAME and G.GAME.hex_hyperbolic_level) or 0) + hex_absolute_bonus_level()

            if level <= 0 then
                -- Not yet upgraded (shouldn't normally be reached, since we
                -- only switch to this calculation once level >= 1) — fall
                -- back to ordinary multiplication.
                return big(chips):mul(big(mult)) -- CHANGED: was big(chips) * big(mult)
            end

            -- level 1 -> arrow(1) = ^, level 1 -> arrow(1) = ^^, etc.
            return to_big(chips):arrow(level, mult)
        end,
        
        -- NOTE: the base game's operator-refresh function only ever reads
        -- .text and .colour off this object, and never touches the operator
        -- DynaText's .scale — so a top-level `scale` field here is silently
        -- ignored. To actually control the size we have to take over the
        -- update ourselves via `update_ui`, which is given the operator's
        -- UI node directly.
        update_ui = function(self, container, chip_display, mult_display, operator)
            if not operator then return end

            local level = ((G.GAME and G.GAME.hex_hyperbolic_level) or 0) + hex_absolute_bonus_level()
            if level <= 0 then level = 1 end
            local txt

            if level <= 3 then
                txt = string.rep("^", level)
            else
                txt = "{" .. tostring(level) .. "}"
            end

            -- Vanilla builds this node with scale = (local scale 0.4) * 2 = 0.8.
            -- We start 0.35 smaller than that (0.45), then shrink further as
            -- the string gets longer than a "comfortable" length, so it
            -- doesn't overflow the little purple box at high levels.
            local base_scale = 1
            local comfortable_len = 1 
            local len = #txt

            local scale = base_scale
            if len > comfortable_len then
                scale = base_scale * (comfortable_len / len)
            end
            scale = math.max(scale, 0.18) -- never shrink below a readable floor

            operator.children[1].config.text = txt
            operator.children[1].config.colour = G.C.PURPLE
            operator.children[1].config.scale = scale

            operator.UIBox:recalculate()
        end,
    }
end

-- Safely switch to our custom scoring calculation, without ever crashing
-- the game if something about the registration didn't go as expected.
local function hex_activate_hyperbolic_calculation()
    if not (hex_hyperbolic_calc and SMODS.set_scoring_calculation) then
        return
    end

    local ok, err = pcall(SMODS.set_scoring_calculation, hex_hyperbolic_calc.key)
    if not ok then
        print("[hex] failed to activate hyperbolic scoring calculation: " .. tostring(err))
    end
end

SMODS.Consumable{
    key = "hyperbolic",     -- was "ritual_template1"
    set = "ritual",

    atlas = "HexRitualsQuantums",
    pos = { x = 0, y = 0 },

    unlocked = true,
    discovered = true,

    config = {
        extra = {}
    },

    in_pool = function(self)
        return false             -- never naturally generated; must be granted directly
    end,

    loc_txt = {
        name = "Hyperbolic",
        text = {
            "Permanently upgrades the operator",
            "between {C:chips}Chips{} and {C:mult}Mult{}",
            "to the next {C:attention}hyperoperator{}",
        }
    },

    loc_vars = function(self, info_queue, card)
        local level = (G.GAME and G.GAME.hex_hyperbolic_level) or 0
        return {
            vars = { hex_operator_name(level) }
        }
    end,

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        G.GAME.hex_hyperbolic_level = (G.GAME.hex_hyperbolic_level or 0) + 1

        hex_activate_hyperbolic_calculation()

        G.GAME.hex_rituals_used = G.GAME.hex_rituals_used or {}
        G.GAME.hex_rituals_used["hyperbolic"] = true

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = hex_operator_name(G.GAME.hex_hyperbolic_level),
            colour = G.C.HEX_ORPLE or G.C.MULT
        })
    end,
}


-- ============================================================
-- Ritual: Life
-- Opens a menu of every registered Joker. Clicking one adds it to
-- your owned Jokers directly. Only Jokers of Mythic rarity or below
-- are selectable; Transcendental/Divine/Absolute Jokers are shown
-- but marked with an X and can't be picked.
-- ============================================================

local hex_life_base_selectable_rarities = {
    [1] = true,
    [2] = true,
    [3] = true,
    [4] = true,
    ["hex_mythic"] = true,
}

-- Returns true if the player currently owns at least one copy of the given
-- Joker key. SMODS.find_card is key-based (mod-safe) and works regardless
-- of edition/eternal/etc state on the card.
local function hex_life_owns_phanes()
    return SMODS.find_card and #SMODS.find_card("j_" .. mod.prefix .. "_phanes") > 0
end

-- Oracle lets rituals be summoned more than once (i.e. bypasses the
-- "already summoned" bookkeeping in G.FUNCS.create_ritual below).
local function hex_owns_oracle()
    return SMODS.find_card and #SMODS.find_card("j_" .. mod.prefix .. "_oracle") > 0
end

-- Phanes lets the Life ritual also offer Transcendental Jokers, but never
-- Divine or Absolute ones -- those stay locked no matter what.
local function hex_life_rarity_selectable(rarity)
    if hex_life_base_selectable_rarities[rarity] then
        return true
    end
    if rarity == "hex_transcendental" and hex_life_owns_phanes() then
        return true
    end
    return false
end

-- This reuses Balatro's real Collection-screen machinery (the same
-- CardArea-of-rows + create_option_cycle pager the game's own Jokers
-- collection tab is built from) so the menu looks and pages exactly
-- like the vanilla Collection. True while our menu's overlay is open,
-- so the Card.click hook below only intercepts clicks in this context.
G.HEX_LIFE_ACTIVE = false

local HEX_LIFE_ROWS = 3
local HEX_LIFE_COLS = 5

-- Builds the list of Jokers the Life ritual can offer. G.P_CENTER_POOLS
-- only contains centers whose `in_pool` returns true (it's the pool the
-- shop's RNG draws from) — Transcendental/Divine/Absolute Jokers all set
-- in_pool = false on purpose, so they're never in there. We start from the
-- normal pool (preserving its existing order untouched) and then append
-- every other registered Joker that wasn't already included, so the
-- higher rarities still show up on the list — just later in it — instead
-- of being silently dropped.
local function hex_life_get_pool()
    local out = {}
    local seen = {}

    for _, center in ipairs(G.P_CENTER_POOLS["Joker"] or {}) do
        if not seen[center.key] then
            out[#out + 1] = center
            seen[center.key] = true
        end
    end

    local extra = {}
    for _, center in pairs(G.P_CENTERS) do
        if center.set == "Joker" and not seen[center.key] then
            extra[#extra + 1] = center
            seen[center.key] = true
        end
    end
    table.sort(extra, function(a, b) return a.key < b.key end)

    for _, center in ipairs(extra) do
        out[#out + 1] = center
    end

    return out
end

-- Locked (Transcendental+) cards are visually marked using Steamodded's
-- built-in debuff treatment (see hex_life_spawnfunc below) rather than a
-- hand-rolled overlay, so there's nothing extra to track or tear down
-- here -- the dim/red-X visual lives on the card object itself and goes
-- away automatically when the card is removed each time the page rebuilds.

local function hex_life_spawnfunc(card, center)
    if not hex_life_rarity_selectable(center.rarity) then
        card.states.hover.can = false
        card.states.drag.can = false

        -- Use Steamodded's built-in debuff visual (dim + red "X") instead
        -- of trying to fake greying with card.alpha or a custom overlay.
        -- Vanilla doesn't dim locked collection items via alpha at all,
        -- and Card:update recalculates alpha every frame from hover/drag
        -- state anyway, so a manual override never sticks. set_debuff /
        -- SMODS.debuff_card is the same treatment the base game uses for
        -- cards that can't currently be used (e.g. Boss Blind debuffs),
        -- so it's guaranteed to render correctly.
        if SMODS.debuff_card then
            SMODS.debuff_card(card, true, "hex_life_lock")
        elseif card.set_debuff then
            card:set_debuff(true)
        else
            card.debuff = true
        end
    end
end

local function hex_life_rebuild_page(current_option)
    if not G.hex_life_rows then return end

    local pool = hex_life_get_pool()

    for j = 1, #G.hex_life_rows do
        for i = #G.hex_life_rows[j].cards, 1, -1 do
            local c = G.hex_life_rows[j]:remove_card(G.hex_life_rows[j].cards[i])
            if c then c:remove() end
        end
    end

    for j = 1, #G.hex_life_rows do
        for i = 1, HEX_LIFE_COLS do
            local center = pool[i + (j - 1) * HEX_LIFE_COLS + (HEX_LIFE_COLS * #G.hex_life_rows) * (current_option - 1)]
            if center then
                local card = Card(
                    G.hex_life_rows[j].T.x + G.hex_life_rows[j].T.w / 2,
                    G.hex_life_rows[j].T.y,
                    G.CARD_W, G.CARD_H,
                    G.P_CARDS.empty,
                    center
                )
                hex_life_spawnfunc(card, center)
                G.hex_life_rows[j]:emplace(card)
            end
        end
    end
end

G.FUNCS.hex_life_page_change = function(args)
    if not args or not args.cycle_config then return end
    hex_life_rebuild_page(args.cycle_config.current_option)
end

local function hex_life_build_definition()
    local pool = hex_life_get_pool()
    local per_page = HEX_LIFE_COLS * HEX_LIFE_ROWS
    local pages = math.max(1, math.ceil(#pool / per_page))

    local deck_tables = {}
    G.hex_life_rows = {}

    for j = 1, HEX_LIFE_ROWS do
        G.hex_life_rows[j] = CardArea(
            G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2, G.ROOM.T.h,
            5 * G.CARD_W, 0.95 * G.CARD_H,
            { card_limit = HEX_LIFE_COLS, type = "title", highlight_limit = 0, collection = true }
        )

        deck_tables[#deck_tables + 1] = {
            n = G.UIT.R,
            config = { align = "cm", padding = 0.07, no_fill = true },
            nodes = { { n = G.UIT.O, config = { object = G.hex_life_rows[j] } } },
        }
    end

    local options = {}
    for i = 1, pages do
        options[#options + 1] = "Page " .. i .. "/" .. pages
    end

    hex_life_rebuild_page(1)

    -- Solid vanilla-style panel: a dark, mostly-opaque card with rounded
    -- corners, the same treatment the game's own Collection/options panels
    -- use, rather than a see-through overlay.
    return {
        n = G.UIT.ROOT,
        config = {
            align = "cm",
            colour = G.C.WHITE, -- White border
            padding = 0.045,     -- Border thickness
            r = 0.1,
        },
        nodes = {
            {
                n = G.UIT.C,
                config = {
                    align = "cm",
                    colour = G.C.L_BLACK, -- Original panel color
                    padding = 0.2,
                    r = 0.08,
                },
                nodes = {
                    {
                        n = G.UIT.R,
                        config = { align = "cm", padding = 0.1 },
                        nodes = {
                            { n = G.UIT.T, config = { text = "Choose a Joker to bring to life", scale = 0.4, colour = G.C.WHITE } },
                        },
                    },
                    {
                        n = G.UIT.R,
                        config = { align = "cm", r = 0.1, colour = G.C.BLACK, emboss = 0.05 },
                        nodes = deck_tables,
                    },
                    {
                        n = G.UIT.R,
                        config = { align = "cm", padding = 0.1 },
                        nodes = {
                            create_option_cycle({
                                options = options,
                                w = 4.5,
                                cycle_shoulders = true,
                                opt_callback = "hex_life_page_change",
                                current_option = 1,
                                colour = G.C.RED,
                                no_pips = true,
                                focus_args = { snap_to = true, nav = "wide" },
                            }),
                        },
                    },
                    {
                        n = G.UIT.R,
                        config = { align = "cm", padding = 0.1 },
                        nodes = {
                            {
                                n = G.UIT.C,
                                config = {
                                    align = "cm",
                                    padding = 0.1,
                                    r = 0.08,
                                    minw = 3,
                                    minh = 0.7,
                                    hover = true,
                                    shadow = true,
                                    colour = G.C.RED,
                                    button = "exit_overlay_menu",
                                },
                                nodes = {
                                    { n = G.UIT.T, config = { text = "Back", scale = 0.4, colour = G.C.WHITE } },
                                },
                            },
                        },
                    },
                },
            },
        },
    }
end

G.FUNCS.hex_life_menu = function()
    G.HEX_LIFE_ACTIVE = true
    G.FUNCS.overlay_menu({ definition = hex_life_build_definition() })
end

-- Always clear our "menu is active" flag when any overlay closes, so a
-- stray leftover flag can never affect the real Collection screen later.
local hex_life_old_exit_overlay_menu = G.FUNCS.exit_overlay_menu
G.FUNCS.exit_overlay_menu = function(e)
    G.HEX_LIFE_ACTIVE = false
    return hex_life_old_exit_overlay_menu(e)
end

-- Intercepts clicks on collection cards while our menu is open (the same
-- technique the published "UltraHand" Balatro mod uses to make collection
-- cards clickable). Only fires while G.HEX_LIFE_ACTIVE is true, so it has
-- zero effect on the real vanilla Collection screen otherwise.
local hex_life_old_card_click = Card.click
function Card:click()
    if G.HEX_LIFE_ACTIVE and G.OVERLAY_MENU then
        if self.config and self.config.center and self.config.center.set == "Joker" then
            local center = self.config.center

            if hex_life_rarity_selectable(center.rarity)
            and G.jokers
            and #G.jokers.cards < G.jokers.config.card_limit
            and G.GAME then

                G.GAME.hex_rituals_used = G.GAME.hex_rituals_used or {}
                G.GAME.hex_rituals_used["life"] = true

                local chosen_key = center.key

                G.FUNCS.exit_overlay_menu()

                G.E_MANAGER:add_event(Event({
                    trigger = "after",
                    delay = 0.1,
                    func = function()
                        local new_card = SMODS.create_card({
                            set = "Joker",
                            key = chosen_key,
                            area = G.jokers
                        })

                        G.jokers:emplace(new_card)

                        card_eval_status_text(new_card, "extra", nil, nil, nil, {
                            message = "Life!",
                            colour = G.C.HEX_ORPLE
                        })

                        return true
                    end
                }))
            end
        end

        return -- swallow the click while our menu is open either way
    end

    hex_life_old_card_click(self)
end

SMODS.Consumable{
    key = "life",
    set = "ritual",

    atlas = "HexRitualsQuantums",
    pos = { x = 1, y = 0 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return false             -- never naturally generated; must be granted directly
    end,

    loc_txt = {
        name = "Life",
        text = {
            "Choose a Joker of",
            "{C:mythic}Mythic{} rarity or below",
            "to add to your Jokers",
            "{C:inactive}(requires an empty Joker slot){}"
        }
    },

    -- Can only be used with an empty Joker slot.
    can_use = function(self, card)
        return G.jokers and (#G.jokers.cards < G.jokers.config.card_limit)
    end,

    use = function(self, card)
        G.FUNCS.hex_life_menu()
    end,
}

SMODS.Consumable{
    key = "eclipse",

    set = "ritual",

    atlas = "HexRitualsQuantums",
    pos = { x = 2, y = 0 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return false             -- never naturally generated; must be granted directly
    end,

    loc_txt = {
        name = "Eclipse",
        text = {
            "Permanently {C:attention}tetrates{}",
            "the {C:chips}Chips{} and {C:mult}Mult{}",
            "of {C:attention}every poker hand{} to {C:attention}^^2{}",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        -- Tetrates every poker hand's base Chips and Mult (the same
        -- numbers planet cards level up) to a height of 2, i.e. each
        -- value becomes value^value. This is completely separate from
        -- the Hyperbolic ritual: Hyperbolic changes the *operator* used
        -- to combine the final Chips and Mult together at the end of
        -- scoring (x -> ^ -> ^^ -> ...); Eclipse never touches that
        -- operator. It only reaches into G.GAME.hands[*].chips/.mult
        -- and tetrates those base values directly, once, permanently.
        -- So e.g. a Flush's base 35 Chips / 4 Mult (with no planet
        -- levels) becomes 35^35 Chips and 4^4 Mult, and any planet
        -- levels bought afterward still add onto those new totals as
        -- normal.
        --
        -- `to_big(n):arrow(2, 2)` is Amulet's OmegaNum tetration:
        -- arrow(2, height) is the tetration operator, so arrow(2, 2)
        -- raises a value to a power tower of itself two high (n^n).
        if G.GAME and G.GAME.hands then
            for hand_key, hand in pairs(G.GAME.hands) do
                if hand.chips then
                    hex_set_hand_stat(hand_key, "chips", to_big(hand.chips):arrow(2, 2))
                end
                if hand.mult then
                    hex_set_hand_stat(hand_key, "mult", to_big(hand.mult):arrow(2, 2))
                end
            end
        end

        G.GAME.hex_rituals_used = G.GAME.hex_rituals_used or {}
        G.GAME.hex_rituals_used["eclipse"] = true

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "Eclipse!",
            colour = G.C.RITUAL
        })
    end,
}

SMODS.Consumable{
    key = "fractal",

    set = "ritual",

    atlas = "HexRitualsQuantums",
    pos = { x = 4, y = 0 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return false             -- never naturally generated; must be granted directly
    end,

    loc_txt = {
        name = "Fractal",
        text = {
            "Permanently {C:attention}disables{}",
            "the effect of {C:attention}every{}",
            "{C:attention}Boss Blind{}, for the",
            "rest of the run",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        -- hex_fractal_used is monotonic -- it only ever gets set to true,
        -- here or anywhere else in the file, and nothing ever sets it back
        -- to false. So this is NOT a toggle: using Fractal a second (or
        -- third, etc.) time can never re-enable Boss Blinds. The guard
        -- below just avoids redundant work on a repeat use (re-disabling
        -- an already-disabled blind, re-showing the status text) -- it
        -- doesn't change the actual disable behaviour, which is already
        -- permanent from the very first use.
        local already_active = G.GAME.hex_fractal_used

        G.GAME.hex_fractal_used = true

        if G.GAME.blind and G.GAME.blind.boss and not G.GAME.blind.disabled then
            G.GAME.blind:disable()
        end

        G.GAME.hex_rituals_used = G.GAME.hex_rituals_used or {}
        G.GAME.hex_rituals_used["fractal"] = true

        if not already_active then
            card_eval_status_text(card, "extra", nil, nil, nil, {
                message = "Fractal!",
                colour = G.C.RITUAL
            })
        end
    end,
}


-- Ascension: a straightforward, immediate stat-boost ritual -- no menu,
-- same "apply everything right away" style as Eclipse/Fractal above.
-- Each stat bump reuses the exact same fields/patterns already
-- established elsewhere in this file for that stat, rather than
-- inventing new mechanisms:
--   * Joker/Consumable slots: direct card_limit bumps, same as
--     Overflow/Endless Abyss/Arcturus/VY Canis Majoris.
--   * Hands/Discards every round: round_resets + current_round bump,
--     same pattern Pollux/Castor/Gambler's Deck use.
--   * Hand size: round_resets.hand_size + live G.hand.config.card_limit
--     bump, then draws the newly-opened slots from the deck immediately,
--     same pattern Sirius/Gambler's Deck use.
--   * Playing card selection limit: adds directly onto
--     hex_pinwheel_bonus_limit, the exact same persistent counter
--     Pinwheel Galaxy bumps -- it's already read every frame in the
--     Game:update poll (alongside Polydactyly/Reach/Long Reach), so
--     Ascension's bonus stacks and behaves identically to more copies
--     of Pinwheel Galaxy without needing any new poll logic.
--   * Money: a straight X50 multiply on G.GAME.dollars.
SMODS.Consumable{
    key = "ascension",
    set = "ritual",

    atlas = "HexRitualsQuantums",
    pos = { x = 5, y = 0 }, -- next open frame in the atlas, after Fractal (4,0)

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return false             -- never naturally generated; must be granted directly
    end,

    loc_txt = {
        name = "Ascension",
        text = {
            "Permanently gain {C:attention}+5{} Joker slots,",
            "{C:attention}+5{} consumable slots,",
            "{C:attention}+5{} hands{} and {C:attention}+5{} discards{}",
            "every round, {C:attention}+5{} hand size{},",
            "{C:attention}+3{} card selection limit{},",
            "and {C:money}X50{} money",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        -- Joker slots
        if G.jokers and G.jokers.config then
            G.jokers.config.card_limit = G.jokers.config.card_limit + 5
        end

        -- Consumable slots
        if G.consumeables and G.consumeables.config then
            G.consumeables.config.card_limit = G.consumeables.config.card_limit + 5
        end

        -- Hands / Discards every round
        G.GAME.round_resets.hands = (G.GAME.round_resets.hands or 4) + 5
        G.GAME.round_resets.discards = (G.GAME.round_resets.discards or 3) + 5

        if G.GAME.current_round then
            G.GAME.current_round.hands_left = (G.GAME.current_round.hands_left or 0) + 5
            G.GAME.current_round.discards_left = (G.GAME.current_round.discards_left or 0) + 5
        end

        -- Hand size: bump the baseline + live limit, then top the
        -- current hand up with the newly-opened slots right away.
        G.GAME.round_resets.hand_size = (G.GAME.round_resets.hand_size or 8) + 5

        if G.hand and G.hand.config then
            G.hand.config.card_limit = G.hand.config.card_limit + 5

            if G.deck and #G.deck.cards > 0 then
                local to_draw = {}
                for i = 1, math.min(5, #G.deck.cards) do
                    to_draw[#to_draw + 1] = G.deck.cards[i]
                end
                if #to_draw > 0 then
                    G.hand:draw(to_draw)
                end
            end
        end

        -- Playing card selection limit -- stacks onto the same
        -- persistent counter Pinwheel Galaxy uses.
        G.GAME.hex_pinwheel_bonus_limit = (G.GAME.hex_pinwheel_bonus_limit or 0) + 3

        -- Money
        G.GAME.dollars = to_big(G.GAME.dollars or 0):mul(big(50))

        G.GAME.hex_rituals_used = G.GAME.hex_rituals_used or {}
        G.GAME.hex_rituals_used["ascension"] = true

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "Ascension!",
            colour = G.C.RITUAL
        })
    end,
}


-- Big Bang: a permanent, ongoing ritual (unlike Ascension's one-time
-- stat boost) -- once used, it keeps firing at the end of every future
-- round for the rest of the run. The actual card creation is hooked
-- into the same add_round_eval_row wrap Toliman/Rigil Kentaurus's own
-- end-of-round cash bonuses use further down the file (see that hook's
-- own comment for why 'bottom' is the right one-shot-per-round trigger
-- point) -- it's the same "end of round" moment, just producing cards
-- instead of money. Uses its own G.GAME.hex_big_bang_paid_round dedupe
-- flag, independent of hex_cash_out_paid_round, so it fires every round
-- regardless of whether Toliman/Rigil Kentaurus are also owned.
--
-- Every additional use (via Oracle, or however many copies you get your
-- hands on) stacks +3 more onto a persistent per-run counter
-- (hex_big_bang_count), the same "persistent counter that keeps growing
-- every time this exact card is used again" approach Altair/Canopus/
-- Toliman/Rigil Kentaurus all use above for their own stacking bonuses --
-- so 2 uses grants 6 cards a round, 3 uses grants 9, and so on, uncapped.
--
-- Each card independently rolls a 1-in-10 chance to be a Galaxy card
-- instead of a Star card (same HEX_GALAXY_IN_STARPACK_CHANCE-style odds
-- already used for Star Pack's own Galaxy chance elsewhere in the file),
-- then is always set Negative -- same create-then-force-Negative pattern
-- Sombrero Galaxy/Rigel use above. Unlike those, creation here is
-- deliberately NOT gated on room in G.consumeables -- every card is
-- always created regardless of how full the consumable area already is,
-- the same unconditional treatment Negative Jokers get elsewhere in
-- this file for the Joker slot limit.
SMODS.Consumable{
    key = "big_bang",
    set = "ritual",

    atlas = "HexRitualsQuantums",
    pos = { x = 6, y = 0 }, -- next open frame in the atlas, after Ascension (5,0)

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return false             -- never naturally generated; must be granted directly
    end,

    loc_txt = {
        name = "Big Bang",
        text = {
            "Permanently gain {C:attention}+3{}",
            "{C:dark_red}Negative{} {C:star}Star{} cards",
            "at the {C:attention}end of every round{}",
            "{C:inactive}(#1# in 10 chance each of being{}",
            "{C:inactive}a Galaxy card instead){}",
            "{C:inactive}(Currently +#2# per round){}",
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { 1, (G.GAME and G.GAME.hex_big_bang_count) or 0 } }
    end,

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        G.GAME.hex_big_bang_used = true
        G.GAME.hex_big_bang_count = (G.GAME.hex_big_bang_count or 0) + 3

        G.GAME.hex_rituals_used = G.GAME.hex_rituals_used or {}
        G.GAME.hex_rituals_used["big_bang"] = true

        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "Big Bang!",
            colour = G.C.RITUAL
        })
    end,
}


-- ============================================================
-- Ritual: Manifest
-- Lets the player build one fully custom playing card and add it to
-- their hand, by walking through a sequence of five selection
-- screens -- Suit, then Rank, then Enhancement, then Seal, then
-- Edition -- one after another. No new menu design is used for any
-- of this: every single screen is built from the *exact* same
-- overlay-menu "collection grid" pieces as the Life ritual above
-- (same CardArea rows/cols, same panel layout, same Page cycle
-- widget). Only the list of cards shown on the grid, and what
-- happens when you click one, changes between the five steps.
-- ============================================================

-- true while any Manifest selection screen is open, mirroring
-- G.HEX_LIFE_ACTIVE above -- the Card.click hook below only
-- intercepts clicks while this is set.
G.HEX_MANIFEST_ACTIVE = false

-- Which step we're on (index into HEX_MANIFEST_STEPS) and the
-- choices accumulated so far. Reset every time Manifest is used.
G.HEX_MANIFEST_STEP_INDEX = 1
G.HEX_MANIFEST_CHOICE = {}

local HEX_MANIFEST_STEPS = { "suit", "rank", "enhancement", "seal", "edition" }

-- Lua tables can't hold a literal nil as an array element (it just
-- creates a hole), so "no Enhancement/Seal/Edition" is represented by
-- this sentinel string instead, and only converted to a real nil at
-- the point it's actually applied to a card.
local HEX_MANIFEST_NONE = "none"

local function hex_manifest_resolve(value)
    if value == HEX_MANIFEST_NONE then
        return nil
    end
    return value
end

local HEX_MANIFEST_SUIT_LETTERS = {
    Spades = "S",
    Hearts = "H",
    Clubs = "C",
    Diamonds = "D",
}

-- Base-game playing card ranks, using the same single-character keys
-- Balatro's own G.P_CARDS table is keyed with (T = Ten).
local HEX_MANIFEST_RANKS = { "A", "K", "Q", "J", "T", "9", "8", "7", "6", "5", "4", "3", "2" }

-- These three lists used to be hand-typed, which meant any enhancement,
-- seal, or edition added later (by this mod or any other mod) silently
-- never showed up in Manifest. Instead we scan the game's own registries
-- live, every time a menu is built, so Manifest always offers whatever is
-- currently loaded -- vanilla content and modded content alike.

-- Enhancements are Centers with set == "Enhanced" (m_bonus, m_mult, ...).
local function hex_manifest_get_enhancements()
    local out = { HEX_MANIFEST_NONE }
    local list = {}

    for _, center in pairs(G.P_CENTERS) do
        if center.set == "Enhanced" then
            list[#list + 1] = center.key
        end
    end

    table.sort(list)
    for _, k in ipairs(list) do out[#out + 1] = k end
    return out
end

-- Seals aren't Centers in vanilla Balatro, so there's no single
-- guaranteed registry to scan. We check every place Steamodded is known
-- to expose them (G.P_SEALS, and Centers with set == "Seal", for
-- versions/mods that register seals that way) and always guarantee the
-- four vanilla seals are present even if neither source has anything.
local function hex_manifest_get_seals()
    local out = { HEX_MANIFEST_NONE }
    local seen = {}
    local list = {}

    local function add(key)
        if key and not seen[key] then
            seen[key] = true
            list[#list + 1] = key
        end
    end

    if G.P_SEALS then
        for key, _ in pairs(G.P_SEALS) do
            add(key)
        end
    end

    for _, center in pairs(G.P_CENTERS) do
        if center.set == "Seal" then
            add(center.key)
        end
    end

    for _, key in ipairs({ "Gold", "Red", "Blue", "Purple" }) do
        add(key)
    end

    table.sort(list)
    for _, k in ipairs(list) do out[#out + 1] = k end
    return out
end

-- Editions are Centers with set == "Edition", keyed like "e_foil".
-- Card:set_edition / SMODS.create_card both want the *short* key with
-- the "e_" stripped (e.g. "foil"), so we strip it here once, for every
-- edition, instead of hardcoding four short keys by hand.
local function hex_manifest_get_editions()
    local out = { HEX_MANIFEST_NONE }
    local list = {}

    -- Empowered can't be picked via Manifest -- it's the strongest custom
    -- edition (pentation), and pentating a single playing card's Chips/
    -- Mult on demand like this would be too strong to hand out freely.
    local empowered_key = "e_" .. mod.prefix .. "_empowered"

    for _, center in pairs(G.P_CENTERS) do
        -- "e_base" is vanilla's internal placeholder representing "no
        -- edition" (used for shop RNG weighting) -- it isn't a real
        -- edition to apply to a card, and we already offer our own
        -- HEX_MANIFEST_NONE option for that, so skip it here or it shows
        -- up as a second blank/no-edition entry.
        if center.set == "Edition" and center.key ~= "e_base" and center.key ~= empowered_key then
            list[#list + 1] = (center.key:gsub("^e_", ""))
        end
    end

    table.sort(list)
    for _, k in ipairs(list) do out[#out + 1] = k end
    return out
end

-- Each entry is a function (not a static table) so it's re-evaluated
-- every time a step's options are needed, picking up anything newly
-- registered.
local HEX_MANIFEST_STEP_OPTIONS = {
    suit = function() return { "Spades", "Hearts", "Clubs", "Diamonds" } end,
    rank = function() return HEX_MANIFEST_RANKS end,
    enhancement = hex_manifest_get_enhancements,
    seal = hex_manifest_get_seals,
    edition = hex_manifest_get_editions,
}

local HEX_MANIFEST_STEP_TITLES = {
    suit = "Manifest -- Choose a Suit",
    rank = "Manifest -- Choose a Rank",
    enhancement = "Manifest -- Choose an Enhancement",
    seal = "Manifest -- Choose a Seal",
    edition = "Manifest -- Choose an Edition",
}

-- Builds a preview Card for one option of the current step, using
-- whatever's already been picked for every other step (so e.g. while
-- picking a Rank, every card shown already has the Suit chosen a
-- moment ago). This is the same idea as hex_life_spawnfunc's cards --
-- a real Card object, not a mocked-up sprite -- just built from base
-- playing-card parts (G.P_CARDS front + G.P_CENTERS enhancement
-- center) instead of a Joker center, with seal/edition layered on
-- with the same Card:set_seal / Card:set_edition calls the rest of
-- the mod already uses.
local function hex_manifest_preview_card(step, value)
    local suit = (step == "suit") and value or (G.HEX_MANIFEST_CHOICE.suit or "Spades")
    local rank = (step == "rank") and value or (G.HEX_MANIFEST_CHOICE.rank or "A")
    local enhancement = (step == "enhancement") and value or G.HEX_MANIFEST_CHOICE.enhancement
    local seal = (step == "seal") and value or G.HEX_MANIFEST_CHOICE.seal
    local edition = (step == "edition") and value or G.HEX_MANIFEST_CHOICE.edition

    local suit_letter = HEX_MANIFEST_SUIT_LETTERS[suit] or "S"
    local front = G.P_CARDS[suit_letter .. "_" .. rank] or G.P_CARDS.empty

    local enh_key = hex_manifest_resolve(enhancement)
    local center = (enh_key and G.P_CENTERS[enh_key]) or G.P_CENTERS.c_base

    local card = Card(0, 0, G.CARD_W, G.CARD_H, front, center)

    local seal_key = hex_manifest_resolve(seal)
    if seal_key then
        card:set_seal(seal_key, true)
    end

    local edition_key = hex_manifest_resolve(edition)
    if edition_key then
        card:set_edition({ [edition_key] = true }, true)
    end

    -- Cards on every step (including "None" options) are always
    -- clickable -- unlike Life, nothing in Manifest is ever locked, so
    -- (unlike hex_life_spawnfunc's locked-card branch) we leave
    -- hover/drag at their default enabled state here.
    card.hex_manifest_value = value

    return card
end

local function hex_manifest_rebuild_page(current_option)
    if not G.hex_manifest_rows then return end

    local step = HEX_MANIFEST_STEPS[G.HEX_MANIFEST_STEP_INDEX]
    local options = HEX_MANIFEST_STEP_OPTIONS[step]()

    for j = 1, #G.hex_manifest_rows do
        for i = #G.hex_manifest_rows[j].cards, 1, -1 do
            local c = G.hex_manifest_rows[j]:remove_card(G.hex_manifest_rows[j].cards[i])
            if c then c:remove() end
        end
    end

    for j = 1, #G.hex_manifest_rows do
        for i = 1, HEX_LIFE_COLS do
            local idx = i + (j - 1) * HEX_LIFE_COLS + (HEX_LIFE_COLS * #G.hex_manifest_rows) * (current_option - 1)
            local value = options[idx]
            if value then
                local card = hex_manifest_preview_card(step, value)
                card.T.x = G.hex_manifest_rows[j].T.x + G.hex_manifest_rows[j].T.w / 2
                card.T.y = G.hex_manifest_rows[j].T.y
                G.hex_manifest_rows[j]:emplace(card)
            end
        end
    end
end

G.FUNCS.hex_manifest_page_change = function(args)
    if not args or not args.cycle_config then return end
    hex_manifest_rebuild_page(args.cycle_config.current_option)
end

-- Identical panel/grid/pager layout to hex_life_build_definition,
-- just re-titled per step and with a Back/Cancel button instead of a
-- plain Back button (see back_button_text below).
local function hex_manifest_build_definition()
    local step = HEX_MANIFEST_STEPS[G.HEX_MANIFEST_STEP_INDEX]
    local options = HEX_MANIFEST_STEP_OPTIONS[step]()
    local per_page = HEX_LIFE_COLS * HEX_LIFE_ROWS
    local pages = math.max(1, math.ceil(#options / per_page))

    local deck_tables = {}
    G.hex_manifest_rows = {}

    for j = 1, HEX_LIFE_ROWS do
        G.hex_manifest_rows[j] = CardArea(
            G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2, G.ROOM.T.h,
            5 * G.CARD_W, 0.95 * G.CARD_H,
            { card_limit = HEX_LIFE_COLS, type = "title", highlight_limit = 0, collection = true }
        )

        deck_tables[#deck_tables + 1] = {
            n = G.UIT.R,
            config = { align = "cm", padding = 0.07, no_fill = true },
            nodes = { { n = G.UIT.O, config = { object = G.hex_manifest_rows[j] } } },
        }
    end

    local page_options = {}
    for i = 1, pages do
        page_options[#page_options + 1] = "Page " .. i .. "/" .. pages
    end

    hex_manifest_rebuild_page(1)

    local back_button_text = (G.HEX_MANIFEST_STEP_INDEX == 1) and "Cancel" or "Back"

    return {
        n = G.UIT.ROOT,
        config = {
            align = "cm",
            colour = G.C.WHITE,
            padding = 0.045,
            r = 0.1,
        },
        nodes = {
            {
                n = G.UIT.C,
                config = {
                    align = "cm",
                    colour = G.C.L_BLACK,
                    padding = 0.2,
                    r = 0.08,
                },
                nodes = {
                    {
                        n = G.UIT.R,
                        config = { align = "cm", padding = 0.1 },
                        nodes = {
                            { n = G.UIT.T, config = { text = HEX_MANIFEST_STEP_TITLES[step], scale = 0.4, colour = G.C.WHITE } },
                        },
                    },
                    {
                        n = G.UIT.R,
                        config = { align = "cm", r = 0.1, colour = G.C.BLACK, emboss = 0.05 },
                        nodes = deck_tables,
                    },
                    {
                        n = G.UIT.R,
                        config = { align = "cm", padding = 0.1 },
                        nodes = {
                            create_option_cycle({
                                options = page_options,
                                w = 4.5,
                                cycle_shoulders = true,
                                opt_callback = "hex_manifest_page_change",
                                current_option = 1,
                                colour = G.C.RED,
                                no_pips = true,
                                focus_args = { snap_to = true, nav = "wide" },
                            }),
                        },
                    },
                    {
                        n = G.UIT.R,
                        config = { align = "cm", padding = 0.1 },
                        nodes = {
                            {
                                n = G.UIT.C,
                                config = {
                                    align = "cm",
                                    padding = 0.1,
                                    r = 0.08,
                                    minw = 3,
                                    minh = 0.7,
                                    hover = true,
                                    shadow = true,
                                    colour = G.C.RED,
                                    button = "hex_manifest_back",
                                },
                                nodes = {
                                    { n = G.UIT.T, config = { text = back_button_text, scale = 0.4, colour = G.C.WHITE } },
                                },
                            },
                        },
                    },
                },
            },
        },
    }
end

G.FUNCS.hex_manifest_menu = function()
    G.HEX_MANIFEST_ACTIVE = true
    G.FUNCS.overlay_menu({ definition = hex_manifest_build_definition() })
end

-- Steps backward through the wizard, or cancels out entirely from
-- step 1. Re-opening the menu (rather than mutating the existing
-- one) keeps this consistent with how advancing to the next step
-- works below, and with Life's existing open/close pattern.
G.FUNCS.hex_manifest_back = function()
    if G.HEX_MANIFEST_STEP_INDEX > 1 then
        G.HEX_MANIFEST_STEP_INDEX = G.HEX_MANIFEST_STEP_INDEX - 1
        G.FUNCS.exit_overlay_menu()

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.05,
            func = function()
                G.FUNCS.hex_manifest_menu()
                return true
            end
        }))
    else
        G.HEX_MANIFEST_CHOICE = {}
        G.HEX_MANIFEST_STEP_INDEX = 1
        G.FUNCS.exit_overlay_menu()
    end
end

-- Always clear our "menu is active" flag when any overlay closes,
-- exactly like the equivalent Life hook above.
local hex_manifest_old_exit_overlay_menu = G.FUNCS.exit_overlay_menu
G.FUNCS.exit_overlay_menu = function(e)
    G.HEX_MANIFEST_ACTIVE = false
    return hex_manifest_old_exit_overlay_menu(e)
end

-- Intercepts clicks on the grid cards while a Manifest screen is
-- open, the same technique (and the same underlying Card.click hook
-- chain) as the Life ritual's click interceptor above.
local hex_manifest_old_card_click = Card.click
function Card:click()
    if G.HEX_MANIFEST_ACTIVE and G.OVERLAY_MENU then
        if self.hex_manifest_value ~= nil then
            local step = HEX_MANIFEST_STEPS[G.HEX_MANIFEST_STEP_INDEX]
            G.HEX_MANIFEST_CHOICE[step] = self.hex_manifest_value

            if G.HEX_MANIFEST_STEP_INDEX < #HEX_MANIFEST_STEPS then
                -- Advance to the next selection screen.
                G.HEX_MANIFEST_STEP_INDEX = G.HEX_MANIFEST_STEP_INDEX + 1
                G.FUNCS.exit_overlay_menu()

                G.E_MANAGER:add_event(Event({
                    trigger = "after",
                    delay = 0.05,
                    func = function()
                        G.FUNCS.hex_manifest_menu()
                        return true
                    end
                }))
            else
                -- Edition was the last step -- build the finished card
                -- and add it straight to the player's hand.
                G.FUNCS.exit_overlay_menu()

                local suit = G.HEX_MANIFEST_CHOICE.suit
                local rank = G.HEX_MANIFEST_CHOICE.rank
                local enhancement = hex_manifest_resolve(G.HEX_MANIFEST_CHOICE.enhancement)
                local seal = hex_manifest_resolve(G.HEX_MANIFEST_CHOICE.seal)
                local edition = hex_manifest_resolve(G.HEX_MANIFEST_CHOICE.edition)

                G.GAME.hex_rituals_used = G.GAME.hex_rituals_used or {}
                G.GAME.hex_rituals_used["manifest"] = true

                G.HEX_MANIFEST_CHOICE = {}
                G.HEX_MANIFEST_STEP_INDEX = 1

                G.E_MANAGER:add_event(Event({
                    trigger = "after",
                    delay = 0.1,
                    func = function()
                        local new_card = SMODS.create_card({
                            set = "Base",
                            suit = suit,
                            rank = rank,
                            enhancement = enhancement,
                            seal = seal,
                            edition = edition and ("e_" .. edition) or nil,
                            area = G.deck,
                        })

                        new_card:add_to_deck()
                        G.deck:emplace(new_card)

                        -- Belt-and-braces: add_to_deck should already register the
                        -- card in G.playing_cards, but if it doesn't (e.g. due to
                        -- how the card was constructed above), the deck-view UI
                        -- reads straight from G.playing_cards, so make sure it's
                        -- actually in there and not duplicated.
                        if G.playing_cards then
                            local already_present = false
                            for _, c in ipairs(G.playing_cards) do
                                if c == new_card then
                                    already_present = true
                                    break
                                end
                            end
                            if not already_present then
                                table.insert(G.playing_cards, new_card)
                            end
                        end

                        card_eval_status_text(new_card, "extra", nil, nil, nil, {
                            message = "Manifest!",
                            colour = G.C.HEX_ORPLE
                        })

                        return true
                    end
                }))
            end
        end

        return -- swallow the click while our menu is open either way
    end

    hex_manifest_old_card_click(self)
end

SMODS.Consumable{
    key = "manifest",
    set = "ritual",

    atlas = "HexRitualsQuantums",
    pos = { x = 3, y = 0 },

    unlocked = true,
    discovered = true,

    in_pool = function(self)
        return false             -- never naturally generated; must be granted directly
    end,

    loc_txt = {
        name = "Manifest",
        text = {
            "Choose a {C:attention}Suit{}, {C:attention}Rank{},",
            "{C:attention}Enhancement{}, {C:attention}Seal{},",
            "and {C:attention}Edition{} to add a fully",
            "custom card to your hand",
        }
    },

    can_use = function(self, card)
        return true
    end,

    use = function(self, card)
        G.HEX_MANIFEST_CHOICE = {}
        G.HEX_MANIFEST_STEP_INDEX = 1
        G.FUNCS.hex_manifest_menu()
    end,
}


-- ============================================================
-- Shared picker: Betelgeuse (Rank) / Antares (Suit)
-- A single-step overlay menu, built from the exact same CardArea-grid-
-- of-rows + create_option_cycle pager pieces the Life and Manifest
-- rituals' own menus above are built from (same HEX_LIFE_ROWS/COLS grid
-- size, same panel layout). Rather than duplicating Manifest's whole
-- multi-step wizard, this is just one of Manifest's own steps (Rank or
-- Suit) pulled out on its own, reused by both Betelgeuse and Antares --
-- the only things that differ between the two cards are the picker's
-- mode ("rank" vs "suit") and which playing cards it applies the choice
-- to once something is clicked.
-- ============================================================

-- True while a Betelgeuse/Antares picker overlay is open, mirroring
-- G.HEX_LIFE_ACTIVE / G.HEX_MANIFEST_ACTIVE above -- the Card.click hook
-- below only intercepts clicks in this context.
G.HEX_STAR_PICK_ACTIVE = false
G.HEX_STAR_PICK_MODE = nil     -- "rank" or "suit"
G.HEX_STAR_PICK_TARGETS = {}   -- the specific playing cards being changed
G.HEX_STAR_PICK_TITLE = ""
G.HEX_STAR_PICK_PACK_HELD = false -- true while we're holding a pack's choice-count open for the picker


local HEX_STAR_PICK_OPTIONS = {
    rank = function() return HEX_MANIFEST_RANKS end,
    suit = function() return { "Spades", "Hearts", "Clubs", "Diamonds" } end,
}

-- Maps a base card's `.value` (vanilla's own full-word rank name, e.g.
-- "Ace"/"10"/"9", the same field checked elsewhere in this file via
-- `context.other_card.base.value == "Ace"` for The Seal of Aces) to the
-- single-letter rank token G.P_CARDS is keyed with (matching
-- HEX_MANIFEST_RANKS above -- "A","K","Q","J","T","9".."2").
local HEX_RANK_VALUE_TO_LETTER = {
    ["Ace"] = "A",
    ["King"] = "K",
    ["Queen"] = "Q",
    ["Jack"] = "J",
    ["10"] = "T",
    ["9"] = "9",
    ["8"] = "8",
    ["7"] = "7",
    ["6"] = "6",
    ["5"] = "5",
    ["4"] = "4",
    ["3"] = "3",
    ["2"] = "2",
}

-- Recovers "what Suit and Rank is this card currently" straight from its
-- own `.base.suit` / `.base.value` fields (rather than scanning G.P_CARDS
-- for a table that's identical() to card.base) -- dealt-into-hand cards
-- aren't guaranteed to keep sharing the exact same table reference as the
-- G.P_CARDS entry they were built from, so an identity scan can silently
-- come up empty even though the card's suit/value fields are fine.
-- HEX_MANIFEST_SUIT_LETTERS (Spades/Hearts/Clubs/Diamonds -> S/H/C/D) is
-- reused here since card.base.suit is that same full-word format.
local function hex_get_card_letters(card)
    if not (card and card.base) then return nil, nil end

    local suit_letter = HEX_MANIFEST_SUIT_LETTERS[card.base.suit]
    local rank_letter = HEX_RANK_VALUE_TO_LETTER[card.base.value]

    return suit_letter, rank_letter
end

-- Preview card for one picker option -- a plain base (no enhancement/
-- seal/edition) showing just the Rank (on a Spade) or the Suit (as an
-- Ace), since only that single attribute is actually being chosen here.
local function hex_star_pick_preview_card(mode, value)
    local front

    if mode == "rank" then
        front = G.P_CARDS["S_" .. value]
    else
        local suit_letter = HEX_MANIFEST_SUIT_LETTERS[value] or "S"
        front = G.P_CARDS[suit_letter .. "_A"]
    end

    front = front or G.P_CARDS.empty

    local card = Card(0, 0, G.CARD_W, G.CARD_H, front, G.P_CENTERS.c_base)
    card.hex_star_pick_value = value

    return card
end

local function hex_star_pick_rebuild_page(current_option)
    if not G.hex_star_pick_rows then return end

    local options = HEX_STAR_PICK_OPTIONS[G.HEX_STAR_PICK_MODE]()

    for j = 1, #G.hex_star_pick_rows do
        for i = #G.hex_star_pick_rows[j].cards, 1, -1 do
            local c = G.hex_star_pick_rows[j]:remove_card(G.hex_star_pick_rows[j].cards[i])
            if c then c:remove() end
        end
    end

    for j = 1, #G.hex_star_pick_rows do
        for i = 1, HEX_LIFE_COLS do
            local idx = i + (j - 1) * HEX_LIFE_COLS + (HEX_LIFE_COLS * #G.hex_star_pick_rows) * (current_option - 1)
            local value = options[idx]
            if value then
                local card = hex_star_pick_preview_card(G.HEX_STAR_PICK_MODE, value)
                card.T.x = G.hex_star_pick_rows[j].T.x + G.hex_star_pick_rows[j].T.w / 2
                card.T.y = G.hex_star_pick_rows[j].T.y
                G.hex_star_pick_rows[j]:emplace(card)
            end
        end
    end
end

G.FUNCS.hex_star_pick_page_change = function(args)
    if not args or not args.cycle_config then return end
    hex_star_pick_rebuild_page(args.cycle_config.current_option)
end

-- Identical panel/grid/pager layout to hex_life_build_definition /
-- hex_manifest_build_definition above, just re-titled per card
-- (G.HEX_STAR_PICK_TITLE) and with a plain "Cancel" button, since there's
-- only ever one step here.
local function hex_star_pick_build_definition()
    local options = HEX_STAR_PICK_OPTIONS[G.HEX_STAR_PICK_MODE]()
    local per_page = HEX_LIFE_COLS * HEX_LIFE_ROWS
    local pages = math.max(1, math.ceil(#options / per_page))

    local deck_tables = {}
    G.hex_star_pick_rows = {}

    for j = 1, HEX_LIFE_ROWS do
        G.hex_star_pick_rows[j] = CardArea(
            G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2, G.ROOM.T.h,
            5 * G.CARD_W, 0.95 * G.CARD_H,
            { card_limit = HEX_LIFE_COLS, type = "title", highlight_limit = 0, collection = true }
        )

        deck_tables[#deck_tables + 1] = {
            n = G.UIT.R,
            config = { align = "cm", padding = 0.07, no_fill = true },
            nodes = { { n = G.UIT.O, config = { object = G.hex_star_pick_rows[j] } } },
        }
    end

    local page_options = {}
    for i = 1, pages do
        page_options[#page_options + 1] = "Page " .. i .. "/" .. pages
    end

    hex_star_pick_rebuild_page(1)

    return {
        n = G.UIT.ROOT,
        config = {
            align = "cm",
            colour = G.C.WHITE,
            padding = 0.045,
            r = 0.1,
        },
        nodes = {
            {
                n = G.UIT.C,
                config = {
                    align = "cm",
                    colour = G.C.L_BLACK,
                    padding = 0.2,
                    r = 0.08,
                },
                nodes = {
                    {
                        n = G.UIT.R,
                        config = { align = "cm", padding = 0.1 },
                        nodes = {
                            { n = G.UIT.T, config = { text = G.HEX_STAR_PICK_TITLE, scale = 0.4, colour = G.C.WHITE } },
                        },
                    },
                    {
                        n = G.UIT.R,
                        config = { align = "cm", r = 0.1, colour = G.C.BLACK, emboss = 0.05 },
                        nodes = deck_tables,
                    },
                    {
                        n = G.UIT.R,
                        config = { align = "cm", padding = 0.1 },
                        nodes = {
                            create_option_cycle({
                                options = page_options,
                                w = 4.5,
                                cycle_shoulders = true,
                                opt_callback = "hex_star_pick_page_change",
                                current_option = 1,
                                colour = G.C.RED,
                                no_pips = true,
                                focus_args = { snap_to = true, nav = "wide" },
                            }),
                        },
                    },
                    {
                        n = G.UIT.R,
                        config = { align = "cm", padding = 0.1 },
                        nodes = {
                            {
                                n = G.UIT.C,
                                config = {
                                    align = "cm",
                                    padding = 0.1,
                                    r = 0.08,
                                    minw = 3,
                                    minh = 0.7,
                                    hover = true,
                                    shadow = true,
                                    colour = G.C.RED,
                                    button = "exit_overlay_menu",
                                },
                                nodes = {
                                    { n = G.UIT.T, config = { text = "Cancel", scale = 0.4, colour = G.C.WHITE } },
                                },
                            },
                        },
                    },
                },
            },
        },
    }
end

G.FUNCS.hex_star_pick_menu = function()
    G.HEX_STAR_PICK_ACTIVE = true
    G.FUNCS.overlay_menu({ definition = hex_star_pick_build_definition() })
end

-- Always clear our "menu is active" flag when any overlay closes, the
-- same layered wrapping Life's and Manifest's own exit_overlay_menu
-- hooks above already do (each wrap calls the previous one in turn, so
-- all three flags -- Life's, Manifest's, and this one -- get cleared
-- together no matter which menu was actually open).
local hex_star_pick_old_exit_overlay_menu = G.FUNCS.exit_overlay_menu
G.FUNCS.exit_overlay_menu = function(e)
    if G.HEX_STAR_PICK_PACK_HELD and G.GAME and G.GAME.pack_choices then
        G.GAME.pack_choices = math.max(0, G.GAME.pack_choices - 1)
        G.HEX_STAR_PICK_PACK_HELD = false

        -- Vanilla's "close the pack" check only ever runs once, synchronously,
        -- at the moment a card is used -- which we deliberately dodged above
        -- so the pack would stay open behind our picker. Now that the picker
        -- is done and the real count is in, nothing else is going to re-run
        -- that check, so we have to force the close ourselves if we're out
        -- of choices.
        if G.GAME.pack_choices <= 0 then
            local ok = pcall(function()
                G.FUNCS.skip_booster()
            end)
            if not ok then
                print("[hex] star pick: couldn't auto-close the pack after last choice")
            end
        end
    end

    G.HEX_STAR_PICK_ACTIVE = false
    return hex_star_pick_old_exit_overlay_menu(e)
end

-- Intercepts clicks on the grid cards while a Betelgeuse/Antares picker
-- is open, the same technique (and the same underlying Card.click hook
-- chain) as the Life and Manifest click interceptors above. On a click,
-- rewrites each captured target card's Rank (keeping its own Suit) or
-- Suit (keeping its own Rank) via Card:set_base -- Enhancement, Seal,
-- and Edition all live on separate fields (config.center / seal /
-- edition) that set_base never touches, so those stay exactly as they
-- were.
local hex_star_pick_old_card_click = Card.click
function Card:click()
    if G.HEX_STAR_PICK_ACTIVE and G.OVERLAY_MENU then
        if self.hex_star_pick_value ~= nil then
            local chosen_value = self.hex_star_pick_value
            local mode = G.HEX_STAR_PICK_MODE
            local targets = G.HEX_STAR_PICK_TARGETS or {}

            G.FUNCS.exit_overlay_menu()

            for _, target in ipairs(targets) do
                if target and target.base then
                    local suit_letter, rank_letter = hex_get_card_letters(target)

                    if suit_letter and rank_letter then
                        local new_key = (mode == "rank")
                            and (suit_letter .. "_" .. chosen_value)
                            or ((HEX_MANIFEST_SUIT_LETTERS[chosen_value] or suit_letter) .. "_" .. rank_letter)

                        local new_front = G.P_CARDS[new_key]

                        if new_front then
                            -- Card:set_base is the normal API for this (it's
                            -- what vanilla's own Death Tarot uses to turn one
                            -- selected card into another), but fall back to
                            -- setting the fields by hand + re-running whatever
                            -- sprite-refresh method exists, in case this
                            -- installed build exposes it under a different
                            -- name -- so this still has the best chance of
                            -- working either way instead of silently no-oping.
                            if target.set_base then
                                target:set_base(new_front)
                            else
                                target.base = new_front
                                if target.config then target.config.card = new_front end
                                if target.set_sprites then
                                    target:set_sprites(target.config and target.config.center, new_front)
                                end
                            end
                        end
                    end
                end
            end
        end

        return -- swallow the click while our menu is open either way
    end

    hex_star_pick_old_card_click(self)
end








-- Create Hex Points when a run starts
local old_start_run = Game.start_run

function Game:start_run(...)
    local ret = old_start_run(self, ...)

    G.GAME.hex_points = G.GAME.hex_points or big(0)

    return ret
end


-- HEX POINT DISPLAY

G.HEX_DISPLAY = {
    value = "TEST HEX"
}

-- Update display


local old_game_update = Game.update

function Game:update(dt)

    old_game_update(self, dt)

    if G.GAME then
        local new_display = hex_format_points(G.GAME.hex_points or 0)

        if G.GAME.hex_display ~= new_display then
            G.GAME.hex_display = new_display

            if G.HEX_TEXT then
                G.HEX_TEXT:remove()

                G.HEX_TEXT = UIBox{
                    definition = {
                        n = G.UIT.ROOT,
                        config = {
                            align = "cm",
                            colour = G.C.UI.TRANSPARENT_DARK,
                            padding = 0.1
                        },
                        nodes = {
                            {
                                n = G.UIT.T,
                                config = {
                                    ref_table = G.GAME,
                                    ref_value = "hex_display",
                                    scale = 0.5,
                                    colour = G.C.WHITE,
                                    align = "cm",
                                }
                            }
                        }
                    },
                    config = {
                        align = "cm",
                        offset = {
                            x = 9,
                            y = -2
                        },
                        major = G.ROOM_ATTACH
                    }
                }
            end
        end
    end
end


-- Update the number
local old_game_update = Game.update

function Game:update(dt)

    old_game_update(self, dt)

    if G.GAME and G.HEX_DISPLAY then
        G.HEX_DISPLAY.value = hex_format_points(G.GAME.hex_points or 0)
    end
end

-- Builds the "Summon Absolute" button. Kept separate from the other three
-- (Ritual/Transcendental/Divine) buttons, which are only ever created once
-- at start_run, because Inaccessible can be bought mid-run and the button
-- needs to appear the moment that happens rather than next run.
-- `disabled` greys the button out and strips its click binding/hover/shadow,
-- for once Absolute has already been summoned this run.
local function hex_create_absolute_button(disabled)
    local hex_bg_colour = (G.C.UI.BACKGROUND_INACTIVE or HEX("4a4a4a"))
    local hex_text_colour = (G.C.UI.TEXT_INACTIVE or HEX("8a8a8a"))

    G.ABSOLUTE_BUTTON = UIBox{
        definition = {
            n = G.UIT.ROOT,
            config = {
                align = "cm",
                colour = G.C.UI.TRANSPARENT,
                padding = -1,
            },
            nodes = {
                {
                    n = G.UIT.C,
                    config = { align = "cm" },
                    nodes = {
                        {
                            n = G.UIT.R,
                            config = { align = "cm" },
                            nodes = {
                                {
                                    n = G.UIT.C,
                                    config = {
                                        align = "cm",
                                        hover = not disabled,
                                        shadow = not disabled,
                                        r = 0.08,
                                        minw = 2.5,
                                        minh = 0.8,
                                        colour = disabled and hex_bg_colour or G.C.ABSOLUTE,
                                        one_press = true,
                                        button = (not disabled) and "summon_absolute" or nil,
                                    },
                                    nodes = {
                                        {
                                            n = G.UIT.R,
                                            config = { align = "cm" },
                                            nodes = {
                                                { n = G.UIT.T, config = { text = "Summon", scale = 0.35, colour = disabled and hex_text_colour or G.C.WHITE, align = "cm", shadow = not disabled } },
                                            },
                                        },
                                        {
                                            n = G.UIT.R,
                                            config = { align = "cm" },
                                            nodes = {
                                                { n = G.UIT.T, config = { text = "Absolute", scale = 0.35, colour = disabled and hex_text_colour or G.C.WHITE, align = "cm", shadow = not disabled } },
                                            },
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
        config = {
            align = "cm",
            offset = { x = 9, y = 2.0 },
            major = G.ROOM_ATTACH,
            emboss = 0,
            no_fill = true,
        },
    }
end


-- Keep display updated
local old_game_update = Game.update

function Game:update(dt)

    old_game_update(self, dt)

    if G.GAME and G.HEX_DISPLAY then
        G.HEX_DISPLAY.value = hex_format_points(G.GAME.hex_points or 0)
    end

    -- Permanently (for the rest of this run) create the Summon Absolute
    -- button the moment Inaccessible is picked up, without waiting for a
    -- new run to start.
    if G.GAME and G.GAME.hex_inaccessible_unlocked then
        if not G.ABSOLUTE_BUTTON then
            hex_create_absolute_button(G.GAME.hex_absolute_summoned)
        elseif G.GAME.hex_absolute_summoned and not G.ABSOLUTE_BUTTON_LOCKED then
            G.ABSOLUTE_BUTTON_LOCKED = true
            if G.ABSOLUTE_BUTTON.remove then G.ABSOLUTE_BUTTON:remove() end
            hex_create_absolute_button(true)
        end
    end

    -- N of a Kind / Flush N of a Kind: derives G.HEX_REAL_SCORING from
    -- G.STATE every frame instead of trying to toggle it around
    -- G.FUNCS.evaluate_play (see the long comment on G.HEX_REAL_SCORING's
    -- own declaration, and the one where that old wrap used to live, for
    -- why the wrap approach never actually worked). G.STATE only moves
    -- away from G.STATES.SELECTING_HAND once a hand is genuinely being
    -- played/scored -- the same distinction Orion's own poll above
    -- already relies on -- so this stays true for the entire scoring
    -- pass, including every deferred G.E_MANAGER event that pass queues
    -- up, and reads false the whole time cards are merely highlighted
    -- for the live preview.
    if G.STATE then
        G.HEX_REAL_SCORING = (G.STATE ~= G.STATES.SELECTING_HAND)
    end

    -- Coupon: while owned, the shop reroll cost is pinned to $1.
    --
    -- G.GAME.round_resets.reroll_cost is only the *base* cost that gets
    -- copied in when a new shop is entered (this is the field vouchers
    -- like Reroll Surplus/Glut discount). The cost that's actually
    -- displayed on the reroll button AND the one G.FUNCS.reroll_shop
    -- charges via `ease_dollars(-G.GAME.current_round.reroll_cost)` is
    -- G.GAME.current_round.reroll_cost, which then climbs by $1 (or more,
    -- with certain vouchers/tags) on every reroll within that shop visit.
    -- We pin both fields every frame so it never shows or charges
    -- anything above $1, no matter how many times the shop is rerolled.
    if G.GAME and SMODS.find_card and #SMODS.find_card("j_" .. mod.prefix .. "_coupon") > 0 then
        if G.GAME.round_resets then
            G.GAME.round_resets.reroll_cost = 1
        end
        if G.GAME.current_round then
            G.GAME.current_round.reroll_cost = 1
        end
    end

    -- Absolute: make sure our custom hyperoperator scoring calculation is
    -- active whenever Absolute is owned, even if Hyperbolic was never
    -- used (hex_hyperbolic_level == 0) -- the actual level applied is
    -- computed dynamically from current Hex points inside
    -- hex_hyperbolic_calc's func/update_ui (see hex_absolute_bonus_level).
    if G.GAME and SMODS.find_card and #SMODS.find_card("j_" .. mod.prefix .. "_absolute") > 0 then
        if hex_hyperbolic_calc
        and SMODS.set_scoring_calculation
        and G.GAME.current_scoring_calculation_key ~= hex_hyperbolic_calc.key then
            hex_activate_hyperbolic_calculation()
        end
    end

    -- Fractal: once used, every Boss Blind for the rest of the run is
    -- neutralized the moment it becomes current, via the same
    -- Blind:disable() vanilla Chicot uses on a single blind. We just
    -- check every frame instead of hooking every single boss blind's
    -- setup function individually, and skip the call once .disabled is
    -- already true so it isn't re-triggered every frame for nothing.
    if G.GAME and G.GAME.hex_fractal_used
    and G.GAME.blind
    and G.GAME.blind.boss
    and not G.GAME.blind.disabled then
        G.GAME.blind:disable()
    end

    -- Procyon: while charges remain, neutralizes every Boss Blind it
    -- encounters (one charge per Blind), the same Blind:disable() poll
    -- Fractal uses just above -- see the comment on Procyon's own
    -- definition above for why a stacking charge counter is used instead
    -- of a permanent flag. `not G.GAME.blind.disabled` (the same guard
    -- Fractal's poll relies on) keeps this from spending more than one
    -- charge on the same Boss Blind across multiple frames.
    if G.GAME and (G.GAME.hex_procyon_charges or 0) > 0
    and G.GAME.blind
    and G.GAME.blind.boss
    and not G.GAME.blind.disabled then
        G.GAME.blind:disable()
        G.GAME.hex_procyon_charges = G.GAME.hex_procyon_charges - 1
    end

    -- Polydactyly: while owned, removes the cap on how many cards can be
    -- highlighted at once to play or discard. NOTE: CardArea's *internal*
    -- field is config.highlighted_limit (with "ed") -- CardArea:init only
    -- accepts "highlight_limit" (no "ed") as a *constructor* option and
    -- immediately re-stores it as config.highlighted_limit, so once the
    -- area already exists (like G.hand here), the field we actually have
    -- to overwrite is the "ed" one. CardArea:add_to_highlighted checks
    -- #self.highlighted >= self.config.highlighted_limit on every card
    -- click, so pinning it every frame (same trick as Coupon's reroll
    -- cost) is enough. HEX_POLY_DEFAULT_HAND_LIMIT is restored the moment
    -- the Joker is no longer owned (sold/destroyed), so nothing is left
    -- permanently inflated if it leaves play.
    if G.GAME and G.hand and G.hand.config and SMODS.find_card then
        local owns_polydactyly = #SMODS.find_card("j_" .. mod.prefix .. "_polydactyly") > 0
        if owns_polydactyly then
            G.hand.config.highlighted_limit = 999995
        else
            -- Pinwheel Galaxy: permanently raises the normal 5-card
            -- selection limit by +1 per use, stacking uncapped -- stored
            -- as a persistent counter on G.GAME (hex_pinwheel_bonus_limit,
            -- starting at 0) the same way Sirius/Pollux/Castor's own
            -- permanent bonuses are elsewhere in this file. Pinned every
            -- frame here (same trick as Coupon's reroll-cost pin above)
            -- rather than only applied once, so it survives anything else
            -- that might otherwise reset G.hand.config.highlighted_limit.
            -- While Polydactyly is owned, its own effectively-infinite
            -- limit above takes over completely and this bonus is simply
            -- not relevant.
            --
            -- Reach / Long Reach: same idea, but from the two vouchers'
            -- own persistent counter (hex_reach_bonus_limit -- +1 for
            -- Reach, an additional +2 for Long Reach, both bumped/undone
            -- directly in each voucher's own add_to_deck/remove_from_deck
            -- above). This is exactly what makes selling Polydactyly fall
            -- back to "whatever it was with Reach/Long Reach and however
            -- many times Pinwheel Galaxy has been used" instead of a flat
            -- 5 -- the moment Polydactyly is no longer owned, this branch
            -- takes back over and rebuilds the limit from the base plus
            -- both of these persistent bonuses, exactly as if Polydactyly
            -- had never been here.
            local pinwheel_bonus = G.GAME.hex_pinwheel_bonus_limit or 0
            local reach_bonus = G.GAME.hex_reach_bonus_limit or 0
            G.hand.config.highlighted_limit = HEX_POLY_DEFAULT_HAND_LIMIT + pinwheel_bonus + reach_bonus
        end
    end

    -- Orion: while owned, raises the hand's card_limit just enough to fit
    -- however many cards are actually in play (hand + remaining deck),
    -- capturing whatever the limit was before we touch it so it can be
    -- restored exactly once Orion is no longer owned (hand size can be
    -- affected by vouchers/decks independently of this Joker).
    --
    -- IMPORTANT: unlike Polydactyly's highlighted_limit override above,
    -- G.hand's card_limit is *also* used to size each card's slot when
    -- CardArea:align_cards lays the row out (slot width scales down as
    -- card_limit goes up). Pinning it to an arbitrary huge placeholder
    -- like 999995 (the trick used for highlighted_limit, which has no
    -- layout role) made every slot collapse to near-zero width, stacking
    -- every card on top of each other. Sizing it to the real card count
    -- instead keeps the layout math sane -- cramped with a full deck in
    -- hand, same as vanilla gets cramped with a large hand, but not a
    -- total stack.
    --
    -- Recomputed every frame so it tracks the real total as cards move
    -- between hand/deck/discard over the course of the round.
    --
    -- Once per round -- tracked via G.GAME.round, Balatro's own round
    -- counter, so this only fires again after a genuinely new round
    -- starts -- draws every remaining card in the deck into the hand.
    --
    -- NOTE: this used to be wired to a `context.first_hand_drawn`
    -- calculate context, but that context flag doesn't actually exist in
    -- this Steamodded build, so it silently never fired (hand stayed at
    -- its normal size). Polling here, the same way Fractal/Polydactyly/
    -- Absolute already do above, is the reliable way to catch "a new
    -- round just started" without a dedicated engine hook for it.
    --
    -- Also: pass a *copy* of G.deck.cards to CardArea:draw, not the live
    -- table. CardArea:draw removes each card from its source area as it
    -- moves it, so handing it the live G.deck.cards table means we'd be
    -- mutating the exact table the draw loop is iterating over -- which
    -- is what caused only about half the deck to actually get drawn.
    if G.GAME and G.hand and G.hand.config and G.deck and SMODS.find_card then
        local owns_orion = #SMODS.find_card("j_" .. mod.prefix .. "_orion") > 0

        if owns_orion then
            if not G.GAME.hex_orion_captured_hand_limit then
                G.GAME.hex_orion_captured_hand_limit = G.hand.config.card_limit
            end
            local total_cards = #G.hand.cards + #G.deck.cards
            G.hand.config.card_limit = math.max(G.GAME.hex_orion_captured_hand_limit, total_cards)
        elseif G.GAME.hex_orion_captured_hand_limit then
            G.hand.config.card_limit = G.GAME.hex_orion_captured_hand_limit
            G.GAME.hex_orion_captured_hand_limit = nil
        end

        if owns_orion
        and G.STATE == G.STATES.SELECTING_HAND
        and #G.hand.cards > 0
        and G.GAME.hex_orion_last_round ~= G.GAME.round then

            G.GAME.hex_orion_last_round = G.GAME.round

            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.1,
                func = function()
                    if G.deck and G.hand and #G.deck.cards > 0 then
                        local cards_to_draw = {}
                        for i = 1, #G.deck.cards do
                            cards_to_draw[i] = G.deck.cards[i]
                        end
                        G.hand:draw(cards_to_draw)
                    end
                    return true
                end
            }))
        end
    end
end

-- Create Hex Points when a run starts + create display

local old_start_run = Game.start_run

function Game:start_run(...)

    G.GAME.hex_rituals_used = G.GAME.hex_rituals_used or {}
    G.GAME.hex_rituals_summoned = G.GAME.hex_rituals_summoned or {}
    local ret = old_start_run(self, ...)
    G.GAME.hex_overstock_ppp_unlocked = G.GAME.hex_overstock_ppp_unlocked or false
    G.GAME.hex_hypernova_unlocked = G.GAME.hex_hypernova_unlocked or false
    G.GAME.hex_points = G.GAME.hex_points or big(0)
    G.GAME.hex_display = hex_format_points(G.GAME.hex_points)
    G.GAME.hex_hyperbolic_level = G.GAME.hex_hyperbolic_level or 0
    G.GAME.hex_fractal_used = G.GAME.hex_fractal_used or false
    G.GAME.hex_sol_blind_mult = G.GAME.hex_sol_blind_mult or 1
    G.GAME.hex_altair_mult = G.GAME.hex_altair_mult or 1
    G.GAME.hex_toi_125_used = G.GAME.hex_toi_125_used or false
    G.GAME.hex_vy_unlocked = G.GAME.hex_vy_unlocked or false
    G.GAME.hex_vy_used = G.GAME.hex_vy_used or false
    G.GAME.hex_nova_unlocked = G.GAME.hex_nova_unlocked or false
    G.GAME.hex_cosmic_rays_unlocked = G.GAME.hex_cosmic_rays_unlocked or false
    G.GAME.hex_pinwheel_bonus_limit = G.GAME.hex_pinwheel_bonus_limit or 0
    G.GAME.hex_whirlpool_bonus_levels = G.GAME.hex_whirlpool_bonus_levels or 0
    G.GAME.hex_reach_bonus_limit = G.GAME.hex_reach_bonus_limit or 0
    G.GAME.hex_negative_bunch_unlocked = G.GAME.hex_negative_bunch_unlocked or false
    G.GAME.hex_negative_cluster_unlocked = G.GAME.hex_negative_cluster_unlocked or false
    G.GAME.hex_quasars_used = G.GAME.hex_quasars_used or false
    G.GAME.hex_quark_star_used = G.GAME.hex_quark_star_used or false
    G.GAME.hex_astral_unlocked = G.GAME.hex_astral_unlocked or false
    G.GAME.hex_ic1101_mult = G.GAME.hex_ic1101_mult or 1
    G.GAME.hex_ic1101_uses = G.GAME.hex_ic1101_uses or 0
    G.GAME.hex_wormhole_bonus = G.GAME.hex_wormhole_bonus or 0
    G.GAME.hex_laniakea_used = G.GAME.hex_laniakea_used or false
    G.GAME.hex_giant_arc_bonus = G.GAME.hex_giant_arc_bonus or 0

    -- Re-apply the hyperoperator scoring calculation on resume/load, since
    -- G.GAME.current_scoring_calculation_key isn't guaranteed to survive it.
    if G.GAME.hex_hyperbolic_level > 0 then
        hex_activate_hyperbolic_calculation()
    end

    -- Re-disable the current blind on resume/load if Fractal was already
    -- used and we happen to be resuming mid-boss-blind. Normally the
    -- per-frame Game:update check (right above this function) handles
    -- this, but doing it here too means it takes effect the instant the
    -- run loads rather than waiting up to a frame.
    if G.GAME.hex_fractal_used
    and G.GAME.blind
    and G.GAME.blind.boss
    and not G.GAME.blind.disabled then
        G.GAME.blind:disable()
    end

    -- Navy blue color
    G.C.HEX_ORPLE = HEX("3b006e")

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 2,
        func = function()
            G.HEX_TEXT = UIBox{
                definition = {
                    n = G.UIT.ROOT,
                    config = {
                        align = "cm",
                        colour = G.C.UI.TRANSPARENT_DARK,
                        padding = 0.1
                    },
                    nodes = {
                        {
                            n = G.UIT.T,
                            config = {
                                ref_table = G.GAME,
                                ref_value = "hex_display",
                                scale = 0.5,
                                colour = G.C.WHITE,
                                align = "cm",
                            }
                        }
                    }
                },
                config = {
                    align = "cm",
                    offset = {
                        x = 9,
                        y = -2
                    },
                    major = G.ROOM_ATTACH
                }
            }
            return true
        end
    }))
    return ret
end
G.FUNCS.hex_sacrifice = function(e)

    local card = e.config.ref_table

    if not card then return end

    if card.ability and card.ability.eternal then return end
    if card.config and card.config.center and card.config.center.key == ("j_" .. mod.prefix .. "_absolute") then return end

    local gain = hex_compute_sacrifice_gain(card)

    if gain:gt(big(0)) then -- CHANGED: was gain > big(0)
        G.GAME.hex_points = (G.GAME.hex_points or big(0)):add(gain) -- CHANGED: was + gain        
        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "+" .. tostring(gain) .. " Hex",
            colour = G.C.HEX_ORPLE
        })

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

local old_use_and_sell_buttons = G.UIDEF.use_and_sell_buttons

function G.UIDEF.use_and_sell_buttons(card)

    local ret = old_use_and_sell_buttons(card)

    if card
    and card.ability
    and card.config.center.set == "Joker" 
    and card.area == G.jokers then

        -- Eternal Jokers and the Absolute Joker can never be sacrificed.
        local hex_disabled =
            (card.ability.eternal)
            or (card.config.center.key == ("j_" .. mod.prefix .. "_absolute"))

        local hex_bg_colour = (G.C.UI.BACKGROUND_INACTIVE or HEX("4a4a4a"))
        local hex_text_colour = (G.C.UI.TEXT_INACTIVE or HEX("8a8a8a"))

        local sacrifice_row = {
            n = G.UIT.R,
            config = { align = "cl" },
            nodes = {
                {n=G.UIT.C, config={align = "cr"}, nodes={
                    {n=G.UIT.C, config={
                        ref_table = card,
                        align = "cr",
                        padding = 0.2,
                        r = 0.08,
                        minw = 1.25,
                        hover = not hex_disabled,
                        shadow = not hex_disabled,
                        colour = hex_disabled and hex_bg_colour or G.C.HEX_ORPLE,
                        one_press = true,
                        button = (not hex_disabled) and "hex_sacrifice" or nil,
                    }, nodes={
                        {n=G.UIT.T, config={text=" HEX", colour = hex_disabled and hex_text_colour or G.C.WHITE, scale=0.5, shadow = not hex_disabled}}
                    }}
                }}
            }
        }

        table.insert(ret.nodes[1].nodes, sacrifice_row)
    end

    return ret
end

G.FUNCS.create_ritual = function()

    if not G.GAME then return end


    if (G.GAME.hex_points or big(0)):lt(big(100)) then
        return
    end


    if #G.consumeables.cards >= G.consumeables.config.card_limit then
        return
    end

    G.GAME.hex_rituals_used = G.GAME.hex_rituals_used or {}

    -- Separate from hex_rituals_used (which is only set once a ritual's
    -- `use` function actually fires). This one is set the moment a ritual
    -- is summoned, so a ritual sitting unused in your consumable slot
    -- can't be rolled a second time.
    G.GAME.hex_rituals_summoned = G.GAME.hex_rituals_summoned or {}

    -- Master list of every ritual's short key (matches the keys set to
    -- `true` in G.GAME.hex_rituals_used by each ritual's `use` function).
    local all_ritual_keys = {
        "hyperbolic",
        "life",
        "fractal",
        "eclipse",
        "manifest",
        "ascension",
        "big_bang",
    }

    local rituals = {}

    -- Oracle: rituals are never excluded for already having been summoned.
    local oracle_owned = hex_owns_oracle()

    for _, ritual_key in ipairs(all_ritual_keys) do
        if oracle_owned or not G.GAME.hex_rituals_summoned[ritual_key] then
            rituals[#rituals+1] = "c_" .. mod.prefix .. "_" .. ritual_key
        end
    end

    if #rituals == 0 then
        return
    end

    local chosen = pseudorandom_element(
        rituals,
        pseudoseed("ritual")
    )


    -- Mark it summoned immediately, before the card even materializes,
    -- so it can't be rolled again while it's sitting unused. Skipped
    -- entirely with Oracle, since that Joker allows repeats anyway.
    local chosen_key = chosen:gsub("^c_" .. mod.prefix .. "_", "")
    if not oracle_owned then
        G.GAME.hex_rituals_summoned[chosen_key] = true
    end

    G.GAME.hex_points = G.GAME.hex_points:sub(big(100)) -- CHANGED: was - big(100)


    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.1,
        func = function()

            local card = SMODS.create_card({
                key = chosen,
                area = G.consumeables
            })

            G.consumeables:emplace(card)

            return true
        end
    }))


end

-- Returns true if the player currently owns a "Showman" Joker, which in
-- vanilla Balatro allows duplicate copies of otherwise-unique Jokers.
local function hex_has_showman()
    return #SMODS.find_card("j_showman") > 0
end

-- Returns true if the player currently owns at least one copy of the Joker
-- with the given key (checked via SMODS.find_card, which is key-based and
-- therefore mod-safe).
local function hex_owns_joker(key)
    return #SMODS.find_card(key) > 0
end
G.FUNCS.summon_transcendental = function()

    if not G.GAME then return end

    local cost = big(1000)

    if (G.GAME.hex_points or big(0)):lt(cost) then -- CHANGED: was < cost
        return
    end

    if #G.jokers.cards >= G.jokers.config.card_limit then
        return
    end

    local showman_owned = hex_has_showman()

    local transcendental_jokers = {}

    for _, center in pairs(G.P_CENTERS) do
        if center.set == "Joker"
        and center.rarity == R_HEX_TRANSCENDENTAL.key
        and (showman_owned or not hex_owns_joker(center.key)) then -- Mythic+ rarities are capped at one copy each, UNLESS Showman is owned
            transcendental_jokers[#transcendental_jokers + 1] = center.key
        end
    end

    if #transcendental_jokers == 0 then
        return
    end

    local chosen = pseudorandom_element(
        transcendental_jokers,
        pseudoseed("transcendental")
    )

    G.GAME.hex_points = G.GAME.hex_points:sub(cost) -- CHANGED: was - cost

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.1,
        func = function()

            local card = SMODS.create_card({
                set = "Joker",
                key = chosen,
                area = G.jokers
            })

            G.jokers:emplace(card)
            card:add_to_deck()
            card_eval_status_text(card, "extra", nil, nil, nil, {
                message = "TRANSCENDENTAL!",
                colour = G.C.TRANSCENDENTAL
            })

            return true
        end
    }))
end
G.FUNCS.summon_divine = function()

    if not G.GAME then return end

    local cost = big(10000)

    if (G.GAME.hex_points or big(0)):lt(cost) then
        return
    end

    if #G.jokers.cards >= G.jokers.config.card_limit then
        return
    end

    local showman_owned = hex_has_showman()

    local divine_jokers = {}

    for _, center in pairs(G.P_CENTERS) do
        if center.set == "Joker"
        and center.rarity == R_HEX_DIVINE.key
        and center.key ~= ("j_" .. mod.prefix .. "_inaccessible") -- Inaccessible can never be summoned via this button; it must be earned normally
        and (showman_owned or not hex_owns_joker(center.key)) then -- Divine Jokers are capped at one copy each, UNLESS Showman is owned
            divine_jokers[#divine_jokers + 1] = center.key
        end
    end

    if #divine_jokers == 0 then
        return
    end

    local chosen = pseudorandom_element(
        divine_jokers,
        pseudoseed("divine")
    )

    G.GAME.hex_points = G.GAME.hex_points:sub(cost)

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.1,
        func = function()

            local card = SMODS.create_card({
                set = "Joker",
                key = chosen,
                area = G.jokers
            })

            G.jokers:emplace(card)
            card:add_to_deck()
            card_eval_status_text(card, "extra", nil, nil, nil, {
                message = "DIVINE!",
                colour = G.C.DIVINE
            })

            return true
        end
    }))
end

G.FUNCS.summon_absolute = function()

    if not G.GAME then return end

    -- Once unlocked, this stays usable for the rest of the run even if
    -- Inaccessible itself is later sold or destroyed. The button that
    -- calls this is only created once the flag is set anyway, but this
    -- guard is kept in case something else ever calls it directly.
    if not G.GAME.hex_inaccessible_unlocked then
        return
    end

    if G.GAME.hex_absolute_summoned then
        return
    end

    local cost = big(1.0e21)

    if (G.GAME.hex_points or big(0)):lt(cost) then -- CHANGED: was < cost
        return
    end

    -- Absolute rarity is always capped at one copy each, even with
    -- Showman -- Showman only affects normal-rarity Jokers -- so this
    -- guard is unconditional and doesn't check hex_has_showman().
    if hex_owns_joker("j_" .. mod.prefix .. "_absolute") then
        return
    end

    -- Summoning Absolute wipes the player out completely rather than
    -- just deducting the flat 1.0e21-point cost -- both Hex
    -- points and dollars are reset straight to zero, whatever they
    -- were at (including any amount left over past the cost). Money is
    -- zeroed the same way Hard Deck's start_run hook sets G.GAME.dollars
    -- above; Hex points reuse `big(0)` the same way every other
    -- point-granting deck hook in this file already does.
    G.GAME.hex_points = big(0)
    G.GAME.dollars = big(0) -- CHANGED: was plain 0 -- dollars is OmegaNum now, so this needs to be a big value too, not a plain Lua number

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.1,
        func = function()

            -- Destroy every other Joker currently held. start_dissolve
            -- plays the usual dissolve animation and removal, same as the
            -- HEX sacrifice button and Cavendish, and Inaccessible itself
            -- dissolves right along with the rest. G.HEX_ABSOLUTE_SUMMONING
            -- is flipped on for exactly this loop -- the one deliberate
            -- window the Immortal sticker's Card.start_dissolve block
            -- allows a dissolve through in -- and back off immediately
            -- after, so nothing else in the game can ever destroy an
            -- Immortal-stickered card outside of this moment.
            G.HEX_ABSOLUTE_SUMMONING = true

            for i = #G.jokers.cards, 1, -1 do
                local c = G.jokers.cards[i]
                if c then
                    c:start_dissolve()
                end
            end

            G.HEX_ABSOLUTE_SUMMONING = false

            local card = SMODS.create_card({
                set = "Joker",
                key = "j_" .. mod.prefix .. "_absolute",
                area = G.jokers
            })

            G.jokers:emplace(card)
            card:add_to_deck()
            -- Absolute itself is permanently granted the Immortal sticker
            -- the moment it's summoned (and, as part of the same call,
            -- has any randomly-rolled Eternal/Perishable stripped off so
            -- the three never stack -- see hex_apply_immortal_sticker's
            -- own comment above for details). See the Card.start_dissolve
            -- hook further up the file for what Immortal actually
            -- protects this card from.
            hex_apply_immortal_sticker(card)

            G.GAME.hex_absolute_summoned = true

            card_eval_status_text(card, "extra", nil, nil, nil, {
                message = "ABSOLUTE!",
                colour = G.C.ABSOLUTE
            })

            return true
        end
    }))
end

-- Add button under Hex counter

local old_start_run_ritual_button = Game.start_run

function Game:start_run(...)

    local ret = old_start_run_ritual_button(self, ...)

    -- Reset the Absolute button each new run -- Inaccessible has to be
    -- re-earned to unlock it again.
    G.ABSOLUTE_BUTTON = nil
    G.ABSOLUTE_BUTTON_LOCKED = nil


    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 2,
        func = function()
            
            G.RITUAL_BUTTON = UIBox{
                definition = {
                    n = G.UIT.ROOT,
                    config = {
                        align = "cm",
                        colour = G.C.UI.TRANSPARENT,
                        padding = -1,
                        emboss = 0,

                    },

                    nodes = {

                        {
                            n = G.UIT.C,
                            config = {
                                align = "cm",
                                ref_table = G.GAME,
                            },

                            nodes = {

                                {
                                    n = G.UIT.R,
                                    config = {
                                        align = "cm"
                                    },

                                    nodes = {

                                        {
                                            n = G.UIT.C,
                                            config = {
                                                align = "cm",
                                                hover = true,
                                                shadow = true,
                                                r = 0.08,
                                                minw = 2.5,
                                                minh = 0.8,
                                                colour = G.C.HEX_ORPLE,
                                                button = "create_ritual",
                                            },

                                            nodes = {

                                                {
                                                    n = G.UIT.T,
                                                    config = {
                                                        text = "Create a ritual",
                                                        scale = 0.35,
                                                        colour = G.C.WHITE,
                                                    }
                                                }

                                            }
                                        }

                                    }
                                }

                            }
                        }

                    }
                },

                config = {
                    align = "cm",
                    offset = {
                        x = 9,
                        y = -1.0
                    },
                    major = G.ROOM_ATTACH,
                    emboss = 0,
                    no_fill = true

                }
            }

            G.TRANSCENDENTAL_BUTTON = UIBox{
                definition = {
                    n = G.UIT.ROOT,
                    config = {
                        align = "cm",
                        colour = G.C.UI.TRANSPARENT,
                        padding = -1,
                    },

                    nodes = {
                        {
                            n = G.UIT.C,
                            config = {
                                align = "cm",
                            },

                            nodes = {
                                {
                                    n = G.UIT.R,
                                    config = {
                                        align = "cm"
                                    },

                                    nodes = {
                                        {
                                            n = G.UIT.C,
                                            config = {
                                                align = "cm",
                                                hover = true,
                                                shadow = true,
                                                r = 0.08,
                                                minw = 2.5,
                                                minh = 0.8,
                                                colour = G.C.TRANSCENDENTAL,
                                                button = "summon_transcendental",
                                            },
                                            nodes = {
                                                {
                                                    n = G.UIT.R,
                                                    config = {
                                                        align = "cm",
                                                    },
                                                    nodes = {
                                                        {
                                                            n = G.UIT.T,
                                                            config = {
                                                                text = "Summon",
                                                                scale = 0.35,
                                                                colour = G.C.WHITE,
                                                                align = "cm",
                                                                shadow = true,
                                                            }
                                                        }
                                                    }
                                                },
                                                {
                                                    n = G.UIT.R,
                                                    config = {
                                                        align = "cm",
                                                    },
                                                    nodes = {
                                                        {
                                                            n = G.UIT.T,
                                                            config = {
                                                                text = "Transcendental",
                                                                scale = 0.35,
                                                                colour = G.C.WHITE,
                                                                align = "cm",
                                                                shadow = true,
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                },

                config = {
                    align = "cm",
                    offset = {
                        x = 9,
                        y = 0
                    },
                    major = G.ROOM_ATTACH,
                    emboss = 0,
                    no_fill = true
                }
            }

            G.DIVINE_BUTTON = UIBox{
                definition = {
                    n = G.UIT.ROOT,
                    config = {
                        align = "cm",
                        colour = G.C.UI.TRANSPARENT,
                        padding = -1,
                    },

                    nodes = {
                        {
                            n = G.UIT.C,
                            config = {
                                align = "cm",
                            },

                            nodes = {
                                {
                                    n = G.UIT.R,
                                    config = {
                                        align = "cm"
                                    },

                                    nodes = {
                                        {
                                            n = G.UIT.C,
                                            config = {
                                                align = "cm",
                                                hover = true,
                                                shadow = true,
                                                r = 0.08,
                                                minw = 2.5,
                                                minh = 0.8,
                                                colour = G.C.DIVINE,
                                                button = "summon_divine",
                                            },
                                            nodes = {
                                                {
                                                    n = G.UIT.R,
                                                    config = {
                                                        align = "cm",
                                                    },
                                                    nodes = {
                                                        {
                                                            n = G.UIT.T,
                                                            config = {
                                                                text = "Summon",
                                                                scale = 0.35,
                                                                colour = G.C.WHITE,
                                                                align = "cm",
                                                                shadow = true,
                                                            }
                                                        }
                                                    }
                                                },
                                                {
                                                    n = G.UIT.R,
                                                    config = {
                                                        align = "cm",
                                                    },
                                                    nodes = {
                                                        {
                                                            n = G.UIT.T,
                                                            config = {
                                                                text = "Divine",
                                                                scale = 0.35,
                                                                colour = G.C.WHITE,
                                                                align = "cm",
                                                                shadow = true,
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                },

                config = {
                    align = "cm",
                    offset = {
                        x = 9,
                        y = 1.0
                    },
                    major = G.ROOM_ATTACH,
                    emboss = 0,
                    no_fill = true
                }
            }

            return true
        end
    }))


    return ret
end



-- Overstock Plus Plus (and any other +voucher-slot source) can put 2+
-- voucher slots in the shop at once -- but get_next_voucher_key has no
-- awareness of other slots being filled in that same shop, so it can
-- independently roll the same voucher into both. Wrapping it here to
-- check against whatever's already sitting in G.shop_vouchers.cards at
-- the moment each slot is filled -- the same "check what's already
-- there and resample" approach hex_filter_already_picked already uses
-- for Star/Galaxy pack slots elsewhere in this file, just applied
-- directly against the live shop CardArea instead of a picked-table,
-- since voucher slots are filled one at a time straight into
-- G.shop_vouchers rather than all at once from a single candidate list.
local hex_old_get_next_voucher_key = get_next_voucher_key

function get_next_voucher_key(_from_tag)
    local center = hex_old_get_next_voucher_key(_from_tag)

    if G.shop_vouchers and G.shop_vouchers.cards and #G.shop_vouchers.cards > 0 then
        local already_in_shop = {}
        for _, c in ipairs(G.shop_vouchers.cards) do
            if c.config and c.config.center and c.config.center.key then
                already_in_shop[c.config.center.key] = true
            end
        end

        local it = 1
        -- Cap the resample attempts so a genuinely tiny remaining pool
        -- (e.g. very late-run, most vouchers already bought) can never
        -- loop forever -- falls back to whatever was last rolled if it
        -- can't find a free one in a reasonable number of tries.
        while already_in_shop[center] and it < 20 do
            it = it + 1
            center = hex_old_get_next_voucher_key(_from_tag)
        end
    end

    return center
end


function ease_dollars(mod, instant)
    local function _mod(mod)
        local dollar_UI = G.HUD:get_UIE_by_ID('dollar_text_UI')
        mod = to_big(mod or 0)

        local text = '+'..localize('$')
        local col = G.C.MONEY

        if mod:lt(big(0)) then
            text = '-'..localize('$')
            col = G.C.RED
        else
            -- Career stat tracking is a plain-number accumulator, so this
            -- is a best-effort conversion (same caveat as high-score
            -- tracking below) -- fine for normal play, just won't stay
            -- accurate once gains blow past double-precision range.
            inc_career_stat('c_dollars_earned', hex_to_plain_number(mod))
        end

        -- Keep the actual balance in OmegaNum space the whole time.
        G.GAME.dollars = to_big(G.GAME.dollars or 0):add(mod)

        -- check_and_set_high_score stores/compares a plain Lua number --
        -- best-effort converted down, same as inc_career_stat above.
        check_and_set_high_score('most_money', hex_to_plain_number(G.GAME.dollars))

        check_for_unlock({type = 'money'})
        dollar_UI.config.object:update()
        G.HUD:recalculate()

        local abs_mod = mod:abs()

        attention_text({
          text = text..hex_format_dollars(abs_mod),
          scale = 0.8, 
          hold = 0.7,
          cover = dollar_UI.parent,
          cover_colour = col,
          align = 'cm',
          })

        play_sound('coin1')
    end
    if instant then
        _mod(mod)
    else
        G.E_MANAGER:add_event(Event({
        trigger = 'immediate',
        func = function()
            _mod(mod)
            return true
        end
        }))
    end
end




G.FUNCS.evaluate_round = function()
    local pitch = 0.95
    local dollars = big(0) -- CHANGED: was 0, now OmegaNum-safe accumulator

    if G.GAME.chips - G.GAME.blind.chips >= 0 then
        add_round_eval_row({dollars = G.GAME.blind.dollars, name='blind1', pitch = pitch})
        pitch = pitch + 0.06
        dollars = dollars:add(big(G.GAME.blind.dollars))
    else
        add_round_eval_row({dollars = 0, name='blind1', pitch = pitch, saved = true})
        pitch = pitch + 0.06
    end

    G.E_MANAGER:add_event(Event({
        trigger = 'before',
        delay = 1.3*math.min(G.GAME.blind.dollars+2, 7)/2*0.15 + 0.5,
        func = function()
          G.GAME.blind:defeat()
          return true
        end
      }))
    delay(0.2)
    G.E_MANAGER:add_event(Event({
        func = function()
            ease_background_colour_blind(G.STATES.ROUND_EVAL, '')
            return true
        end
    }))
    G.GAME.selected_back:trigger_effect({context = 'eval'})

    if G.GAME.current_round.hands_left > 0 and not G.GAME.modifiers.no_extra_hand_money then
        local hand_bonus = G.GAME.current_round.hands_left*(G.GAME.modifiers.money_per_hand or 1)
        add_round_eval_row({dollars = hand_bonus, disp = G.GAME.current_round.hands_left, bonus = true, name='hands', pitch = pitch})
        pitch = pitch + 0.06
        dollars = dollars:add(big(hand_bonus))
    end
    if G.GAME.current_round.discards_left > 0 and G.GAME.modifiers.money_per_discard then
        local discard_bonus = G.GAME.current_round.discards_left*(G.GAME.modifiers.money_per_discard)
        add_round_eval_row({dollars = discard_bonus, disp = G.GAME.current_round.discards_left, bonus = true, name='discards', pitch = pitch})
        pitch = pitch + 0.06
        dollars = dollars:add(big(discard_bonus))
    end
    for i = 1, #G.jokers.cards do
        local ret = G.jokers.cards[i]:calculate_dollar_bonus()
        if ret then
            add_round_eval_row({dollars = ret, bonus = true, name='joker'..i, pitch = pitch, card = G.jokers.cards[i]})
            pitch = pitch + 0.06
            dollars = dollars:add(big(ret.dollars))
        end
    end
    for i = 1, #G.GAME.tags do
        local ret = G.GAME.tags[i]:apply_to_run({type = 'eval'})
        if ret then
            add_round_eval_row({dollars = ret.dollars, bonus = true, name='tag'..i, pitch = pitch, condition = ret.condition, pos = ret.pos, tag = ret.tag})
            pitch = pitch + 0.06
            dollars = dollars + big(ret.dollars) -- CHANGED
        end
    end
    if G.GAME.dollars:gte(big(5)) and not G.GAME.modifiers.no_interest then -- CHANGED: big(5), relies on OmegaNum's own >= metamethod
        -- CHANGED: down-cast G.GAME.dollars to a plain number just for this
        -- ratio -- always saturates safely via math.min against
        -- interest_cap/5 even at absurd OmegaNum balances (hex_to_plain_number
        -- returns math.huge past double-precision range, and math.min(huge, cap)
        -- still correctly returns cap).
        local dollars_plain = hex_to_plain_number(G.GAME.dollars)
        local interest_units = math.min(math.floor(dollars_plain/5), G.GAME.interest_cap/5)
        local interest_gain = G.GAME.interest_amount*interest_units

        add_round_eval_row({bonus = true, name='interest', pitch = pitch, dollars = interest_gain})
        pitch = pitch + 0.06
        if not G.GAME.seeded and not G.GAME.challenge then
            if interest_gain == G.GAME.interest_amount*G.GAME.interest_cap/5 then 
                G.PROFILES[G.SETTINGS.profile].career_stats.c_round_interest_cap_streak = G.PROFILES[G.SETTINGS.profile].career_stats.c_round_interest_cap_streak + 1
            else
                G.PROFILES[G.SETTINGS.profile].career_stats.c_round_interest_cap_streak = 0
            end
        end
        check_for_unlock({type = 'interest_streak'})
        dollars = dollars:add(big(interest_gain))
    end

    pitch = pitch + 0.06

    add_round_eval_row({name = 'bottom', dollars = dollars})
end




function add_round_eval_row(config)
    local config = config or {}
    local width = G.round_eval.T.w - 0.51
    local num_dollars = hex_to_plain_number(config.dollars or 1)
    local scale = 0.9

    if config.name ~= 'bottom' then
        if config.name ~= 'blind1' then
            if not G.round_eval.divider_added then 
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',delay = 0.25,
                    func = function() 
                        local spacer = {n=G.UIT.R, config={align = "cm", minw = width}, nodes={
                            {n=G.UIT.O, config={object = DynaText({string = {'......................................'}, colours = {G.C.WHITE},shadow = true, float = true, y_offset = -30, scale = 0.45, spacing = 13.5, font = G.LANGUAGES['en-us'].font, pop_in = 0})}}
                        }}
                        G.round_eval:add_child(spacer,G.round_eval:get_UIE_by_ID(config.bonus and 'bonus_round_eval' or 'base_round_eval'))
                        return true
                    end
                }))
                delay(0.6)
                G.round_eval.divider_added = true
            end
        else
            delay(0.2)
        end

        delay(0.2)

        G.E_MANAGER:add_event(Event({
            trigger = 'before',delay = 0.5,
            func = function()
                --Add the far left text and context first:
                local left_text = {}
                if config.name == 'blind1' then
                    local stake_sprite = get_stake_sprite(G.GAME.stake or 1, 0.5)
                    local blind_sprite = AnimatedSprite(0, 0, 1.2,1.2, G.ANIMATION_ATLAS['blind_chips'], copy_table(G.GAME.blind.pos))
                    blind_sprite:define_draw_steps({
                        {shader = 'dissolve', shadow_height = 0.05},
                        {shader = 'dissolve'}
                    })
                    table.insert(left_text, {n=G.UIT.O, config={w=1.2,h=1.2 , object = blind_sprite, hover = true, can_collide = false}})
  
                    table.insert(left_text,                  
                    config.saved and 
                    {n=G.UIT.C, config={padding = 0.05, align = 'cm'}, nodes={
                        {n=G.UIT.R, config={align = 'cm'}, nodes={
                            {n=G.UIT.O, config={object = DynaText({string = {' '..localize('ph_mr_bones')..' '}, colours = {G.C.FILTER}, shadow = true, pop_in = 0, scale = 0.5*scale, silent = true})}}
                        }}
                    }}
                    or {n=G.UIT.C, config={padding = 0.05, align = 'cm'}, nodes={
                        {n=G.UIT.R, config={align = 'cm'}, nodes={
                            {n=G.UIT.O, config={object = DynaText({string = {' '..localize('ph_score_at_least')..' '}, colours = {G.C.UI.TEXT_LIGHT}, shadow = true, pop_in = 0, scale = 0.4*scale, silent = true})}}
                        }},
                        {n=G.UIT.R, config={align = 'cm', minh = 0.8}, nodes={
                            {n=G.UIT.O, config={w=0.5,h=0.5 , object = stake_sprite, hover = true, can_collide = false}},
                            {n=G.UIT.T, config={text = G.GAME.blind.chip_text, scale = scale_number(G.GAME.blind.chips, scale, 100000), colour = G.C.RED, shadow = true}}
                        }}
                    }}) 
                elseif string.find(config.name, 'tag') then
                    local blind_sprite = Sprite(0, 0, 0.7,0.7, G.ASSET_ATLAS['tags'], copy_table(config.pos))
                    blind_sprite:define_draw_steps({
                        {shader = 'dissolve', shadow_height = 0.05},
                        {shader = 'dissolve'}
                    })
                    blind_sprite:juice_up()
                    table.insert(left_text, {n=G.UIT.O, config={w=0.7,h=0.7 , object = blind_sprite, hover = true, can_collide = false}})
                    table.insert(left_text, {n=G.UIT.O, config={object = DynaText({string = {config.condition}, colours = {G.C.UI.TEXT_LIGHT}, shadow = true, pop_in = 0, scale = 0.4*scale, silent = true})}})                   
                elseif config.name == 'hands' then
                    table.insert(left_text, {n=G.UIT.T, config={text = config.disp or config.dollars, scale = 0.8*scale, colour = G.C.BLUE, shadow = true, juice = true}})
                    table.insert(left_text, {n=G.UIT.O, config={object = DynaText({string = {" "..localize{type = 'variable', key = 'remaining_hand_money', vars = {G.GAME.modifiers.money_per_hand or 1}}}, colours = {G.C.UI.TEXT_LIGHT}, shadow = true, pop_in = 0, scale = 0.4*scale, silent = true})}})
                elseif config.name == 'discards' then
                    table.insert(left_text, {n=G.UIT.T, config={text = config.disp or config.dollars, scale = 0.8*scale, colour = G.C.RED, shadow = true, juice = true}})
                    table.insert(left_text, {n=G.UIT.O, config={object = DynaText({string = {" "..localize{type = 'variable', key = 'remaining_discard_money', vars = {G.GAME.modifiers.money_per_discard or 0}}}, colours = {G.C.UI.TEXT_LIGHT}, shadow = true, pop_in = 0, scale = 0.4*scale, silent = true})}})
                elseif string.find(config.name, 'joker') then
                    table.insert(left_text, {n=G.UIT.O, config={object = DynaText({string = localize{type = 'name_text', set = config.card.config.center.set, key = config.card.config.center.key}, colours = {G.C.FILTER}, shadow = true, pop_in = 0, scale = 0.6*scale, silent = true})}})
                elseif config.name == 'interest' then
                    table.insert(left_text, {n=G.UIT.T, config={text = num_dollars, scale = 0.8*scale, colour = G.C.MONEY, shadow = true, juice = true}})
                    table.insert(left_text,{n=G.UIT.O, config={object = DynaText({string = {" "..localize{type = 'variable', key = 'interest', vars = {G.GAME.interest_amount, 5, G.GAME.interest_amount*G.GAME.interest_cap/5}}}, colours = {G.C.UI.TEXT_LIGHT}, shadow = true, pop_in = 0, scale = 0.4*scale, silent = true})}})
                end
                local full_row = {n=G.UIT.R, config={align = "cm", minw = 5}, nodes={
                    {n=G.UIT.C, config={padding = 0.05, minw = width*0.55, minh = 0.61, align = "cl"}, nodes=left_text},
                    {n=G.UIT.C, config={padding = 0.05,minw = width*0.45, align = "cr"}, nodes={{n=G.UIT.C, config={align = "cm", id = 'dollar_'..config.name},nodes={}}}}
                }}
        
                if config.name == 'blind1' then
                    G.GAME.blind:juice_up()
                end
                G.round_eval:add_child(full_row,G.round_eval:get_UIE_by_ID(config.bonus and 'bonus_round_eval' or 'base_round_eval'))
                play_sound('cancel', config.pitch or 1)
                play_sound('highlight1',( 1.5*config.pitch) or 1, 0.2)
                if config.card then config.card:juice_up(0.7, 0.46) end
                return true
            end
        }))
        local dollar_row = 0
        if num_dollars > 60 then -- change if need
            G.E_MANAGER:add_event(Event({
                trigger = 'before',delay = 0.38,
                func = function()
                    G.round_eval:add_child(
                            {n=G.UIT.R, config={align = "cm", id = 'dollar_row_'..(dollar_row+1)..'_'..config.name}, nodes={
                                {n=G.UIT.O, config={object = DynaText({string = {localize('$')..hex_format_dollars(config.dollars or 1)}, colours = {G.C.MONEY}, shadow = true, pop_in = 0, scale = 0.65, float = true})}} -- CHANGED: hex_format_dollars(config.dollars or 1) instead of raw num_dollars
                            }},
                            G.round_eval:get_UIE_by_ID('dollar_'..config.name))

                    play_sound('coin3', 0.9+0.2*math.random(), 0.7)
                    play_sound('coin6', 1.3, 0.8)
                    return true
                end
            }))
        else
            for i = 1, num_dollars or 1 do
                G.E_MANAGER:add_event(Event({
                    trigger = 'before',delay = 0.18 - ((num_dollars > 20 and 0.13) or (num_dollars > 9 and 0.1) or 0),
                    func = function()
                        if i%30 == 1 then 
                            G.round_eval:add_child(
                                {n=G.UIT.R, config={align = "cm", id = 'dollar_row_'..(dollar_row+1)..'_'..config.name}, nodes={}},
                                G.round_eval:get_UIE_by_ID('dollar_'..config.name))
                                dollar_row = dollar_row+1
                        end

                        local r = {n=G.UIT.T, config={text = localize('$'), colour = G.C.MONEY, scale = ((num_dollars > 20 and 0.28) or (num_dollars > 9 and 0.43) or 0.58), shadow = true, hover = true, can_collide = false, juice = true}}
                        play_sound('coin3', 0.9+0.2*math.random(), 0.7 - (num_dollars > 20 and 0.2 or 0))
                        
                        if config.name == 'blind1' then 
                            G.GAME.current_round.dollars_to_be_earned = G.GAME.current_round.dollars_to_be_earned:sub(2)
                        end

                        G.round_eval:add_child(r,G.round_eval:get_UIE_by_ID('dollar_row_'..(dollar_row)..'_'..config.name))
                        G.VIBRATION = G.VIBRATION + 0.4
                        return true
                    end
                }))
            end
        end
    else
        delay(0.4)
        G.E_MANAGER:add_event(Event({
            trigger = 'before',delay = 0.5,
            func = function()
                UIBox{
                    definition = {n=G.UIT.ROOT, config={align = 'cm', colour = G.C.CLEAR}, nodes={
                        {n=G.UIT.R, config={id = 'cash_out_button', align = "cm", padding = 0.1, minw = 7, r = 0.15, colour = G.C.ORANGE, shadow = true, hover = true, one_press = true, button = 'cash_out', focus_args = {snap_to = true}}, nodes={
                            {n=G.UIT.T, config={text = localize('b_cash_out')..": ", scale = 1, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
                            {n=G.UIT.T, config={text = localize('$')..hex_format_dollars(config.dollars), scale = 1.2*scale, colour = G.C.WHITE, shadow = true, juice = true}} -- CHANGED: hex_format_dollars(config.dollars) instead of raw config.dollars
                    }},}},
                    config = {
                      align = 'tmi',
                      offset ={x=0,y=0.4},
                      major = G.round_eval}
                }

                G.GAME.current_round.dollars = config.dollars
                
                play_sound('coin6', config.pitch or 1)
                G.VIBRATION = G.VIBRATION + 1
                return true
            end
        }))
    end
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




function Game:splash_screen()
    if G.SETTINGS.skip_splash == 'Yes' then
        G:main_menu()
        return
    end

    self:prep_stage(G.STAGES.MAIN_MENU, G.STATES.SPLASH, true)
    G.E_MANAGER:add_event(Event({
        func = (function()
            discover_card()
            return true
        end)
    }))

    G.E_MANAGER:add_event(Event({
        trigger = 'immediate',
        func = (function()
            local blue_swirl = {
                c1 = HEX('1E3A8A'), -- deep navy blue
                c2 = HEX('38BDF8'), -- lighter sky blue
            }
            G.TIMERS.TOTAL = 0
            G.TIMERS.REAL = 0
            G.SPLASH_BACK = Sprite(-30, -13, G.ROOM.T.w+60, G.ROOM.T.h+22, G.ASSET_ATLAS["ui_1"], {x = 2, y = 0})
            G.SPLASH_BACK:define_draw_steps({{
                shader = 'splash',
                send = {
                    {name = 'time', ref_table = G.TIMERS, ref_value = 'REAL'},
                    {name = 'vort_speed', val = 1},
                    {name = 'colour_1', ref_table = blue_swirl, ref_value = 'c1'},
                    {name = 'colour_2', ref_table = blue_swirl, ref_value = 'c2'},
                    {name = 'mid_flash', val = 0},
                    {name = 'vort_offset', val = (2*90.15315131*os.time())%100000},
                }}})
            G.SPLASH_BACK:set_alignment({ major = G.ROOM_ATTACH, type = 'cm', offset = {x=0,y=0} })

            G.SPLASH_FRONT = Sprite(0,-20, G.ROOM.T.w*2, G.ROOM.T.h*4, G.ASSET_ATLAS["ui_1"], {x = 2, y = 0})
            G.SPLASH_FRONT:define_draw_steps({{
                shader = 'flash',
                send = {
                    {name = 'time', ref_table = G.TIMERS, ref_value = 'REAL'},
                    {name = 'mid_flash', val = 1}
                }}})
            G.SPLASH_FRONT:set_alignment({ major = G.ROOM_ATTACH, type = 'cm', offset = {x=0,y=0} })

            --spawn in splash card
            local SC = nil
            G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.2,func = (function()
                local SC_scale = 1.2
                SC = Card(G.ROOM.T.w/2 - SC_scale*G.CARD_W/2, 10. + G.ROOM.T.h/2 - SC_scale*G.CARD_H/2, SC_scale*G.CARD_W, SC_scale*G.CARD_H, G.P_CARDS.empty, G.P_CENTERS['c_hex'])
                SC.T.y = G.ROOM.T.h/2 - SC_scale*G.CARD_H/2
                SC.ambient_tilt = 1
                SC.states.drag.can = false
                SC.states.hover.can = false
                SC.no_ui = true
                G.VIBRATION = G.VIBRATION + 2
                play_sound('whoosh1', 0.7, 0.2)
                play_sound('introPad1', 0.704, 0.6)
            return true;end)}))

            G.E_MANAGER:add_event(Event({trigger = 'after',delay = 1.8,func = (function()
                SC:start_dissolve({G.C.WHITE, G.C.WHITE},true, 12, true)
                play_sound('magic_crumple', 1, 0.5)
                play_sound('splash_buildup', 1, 0.7)
            return true;end)}))

            function make_splash_card(args)
                args = args or {}
                local angle = math.random()*2*3.14
                local card_size = (args.scale or 1.5)*(math.random() + 1)
                local card_pos = args.card_pos or {
                    x = (18 + card_size)*math.sin(angle),
                    y = (18 + card_size)*math.cos(angle)
                }
                local card = Card(  card_pos.x + G.ROOM.T.w/2 - G.CARD_W*card_size/2,
                                    card_pos.y + G.ROOM.T.h/2 - G.CARD_H*card_size/2,
                                    card_size*G.CARD_W, card_size*G.CARD_H, pseudorandom_element(G.P_CARDS), G.P_CENTERS.c_base)
                if math.random() > 0.8 then card.sprite_facing = 'back'; card.facing = 'back' end
                card.no_shadow = true
                card.states.hover.can = false
                card.states.drag.can = false
                card.vortex = true and not args.no_vortex
                card.T.r = angle
                return card, card_pos
            end

            G.vortex_time = G.TIMERS.REAL
            local temp_del = nil

            for i = 1, 200 do
                temp_del = temp_del or 3
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    blockable = false,
                    delay = temp_del,
                    func = (function()
                    local card, card_pos = make_splash_card({scale = 2 - i/300})
                    local speed = math.max(2. - i*0.005, 0.001)
                    ease_value(card.T, 'scale', -card.T.scale, nil, nil, nil, 1.*speed, 'elastic')
                    ease_value(card.T, 'x', -card_pos.x, nil, nil, nil, 0.9*speed)
                    ease_value(card.T, 'y', -card_pos.y, nil, nil, nil, 0.9*speed)
                    local temp_pitch = i*0.007 + 0.6
                    local temp_i = i
                    G.E_MANAGER:add_event(Event({
                        blockable = false,
                        func = (function()
                            if card.T.scale <= 0 then
                                if temp_i < 30 then
                                    play_sound('whoosh1', temp_pitch + math.random()*0.05, 0.25*(1 - temp_i/50))
                                end
                                if temp_i == 15 then
                                    play_sound('whoosh_long',0.9, 0.7)
                                end
                                G.VIBRATION = G.VIBRATION + 0.1
                                card:remove()
                                return true
                            end
                        end)}))
                        return true
                    end)}))
                    temp_del = temp_del + math.max(1/(i), math.max(0.2*(170-i)/500, 0.016))
            end

            G.E_MANAGER:add_event(Event({trigger = 'after',delay = 2.,func = (function()
                G.SPLASH_BACK:remove()
                G.SPLASH_BACK = G.SPLASH_FRONT
                G.SPLASH_FRONT = nil
                G:main_menu('splash')
            return true;end)}))
        return true
    end)
    }))
end

function Game:main_menu(change_context)
    if change_context ~= 'splash' then 
        G.TIMERS.REAL = 12
        G.TIMERS.TOTAL = 12
    else
        RESET_STATES(G.STATES.MENU)
    end

    self:prep_stage(G.STAGES.MAIN_MENU, G.STATES.MENU, true)

    -- Hex UI (counter + buttons) shouldn't persist once we leave a run.
    -- These are only ever removed here on returning to the menu; the
    -- per-frame update logic in Game:update never touches G.HEX_TEXT
    -- unless it already exists, so setting it to nil just pauses it
    -- until the next start_run recreates it (still updating every
    -- second from that point on).
    if G.HEX_TEXT then
        G.HEX_TEXT:remove()
        G.HEX_TEXT = nil
    end
    if G.RITUAL_BUTTON then
        G.RITUAL_BUTTON:remove()
        G.RITUAL_BUTTON = nil
    end
    if G.TRANSCENDENTAL_BUTTON then
        G.TRANSCENDENTAL_BUTTON:remove()
        G.TRANSCENDENTAL_BUTTON = nil
    end
    if G.DIVINE_BUTTON then
        G.DIVINE_BUTTON:remove()
        G.DIVINE_BUTTON = nil
    end
    if G.ABSOLUTE_BUTTON then
        G.ABSOLUTE_BUTTON:remove()
        G.ABSOLUTE_BUTTON = nil
    end
    G.ABSOLUTE_BUTTON_LOCKED = nil

    self.GAME.selected_back = Back(G.P_CENTERS.b_red)

    if (not G.SETTINGS.tutorial_complete) and G.SETTINGS.tutorial_progress.completed_parts['big_blind'] then G.SETTINGS.tutorial_complete = true end

    G.FUNCS.change_shadows{to_key = G.SETTINGS.GRAPHICS.shadows == 'On' and 1 or 2}

    ease_background_colour{new_colour = G.C.BLACK, contrast = 1}

    if G.SPLASH_FRONT then G.SPLASH_FRONT:remove(); G.SPLASH_FRONT = nil end
    if G.SPLASH_BACK then G.SPLASH_BACK:remove(); G.SPLASH_BACK = nil end
    G.SPLASH_BACK = Sprite(-30, -13, G.ROOM.T.w+60, G.ROOM.T.h+22, G.ASSET_ATLAS["ui_1"], {x = 2, y = 0})
    G.SPLASH_BACK:set_alignment({
        major = G.ROOM_ATTACH,
        type = 'cm',
        offset = {x=0,y=0}
    })
    local splash_args = {mid_flash = change_context == 'splash' and 1.6 or 0.}
    ease_value(splash_args, 'mid_flash', -(change_context == 'splash' and 1.6 or 0), nil, nil, nil, 4)

    local blue_swirl = {
        c1 = HEX('1E3A8A'), -- deep navy blue
        c2 = HEX('38BDF8'), -- lighter sky blue
    }

    G.SPLASH_BACK:define_draw_steps({{
        shader = 'splash',
        send = {
            {name = 'time', ref_table = G.TIMERS, ref_value = 'REAL_SHADER'},
            {name = 'vort_speed', val = 0.4},
            {name = 'colour_1', ref_table = blue_swirl, ref_value = 'c1'},
            {name = 'colour_2', ref_table = blue_swirl, ref_value = 'c2'},
            {name = 'mid_flash', ref_table = splash_args, ref_value = 'mid_flash'},
            {name = 'vort_offset', val = 0},
        }}})

    G.E_MANAGER:add_event(Event({
        trigger = 'immediate',
        func = (function()
            unlock_notify()
            return true
        end)
      }))

    local SC_scale = 1.1*(G.debug_splash_size_toggle and 0.8 or 1)
    local CAI = {
        TITLE_TOP_W = G.CARD_W,
        TITLE_TOP_H = G.CARD_H,
    }
    self.title_top = CardArea(
        0, 0,
        CAI.TITLE_TOP_W,CAI.TITLE_TOP_H,
        {card_limit = 1, type = 'title'})

    G.SPLASH_LOGO = Sprite(0, 0, 
        13*SC_scale, 
        13*SC_scale*(G.ASSET_ATLAS["balatro"].py/G.ASSET_ATLAS["balatro"].px),
        G.ASSET_ATLAS["balatro"], {x=0,y=0})

    G.SPLASH_LOGO:set_alignment({
        major = G.title_top,
        type = 'cm',
        bond = 'Strong',
        offset = {x=0,y=0}
    })
    G.SPLASH_LOGO:define_draw_steps({{
            shader = 'dissolve',
        }})

    G.SPLASH_LOGO.dissolve_colours = {G.C.WHITE, G.C.WHITE}
    G.SPLASH_LOGO.dissolve = 1   

    -- 🔻 changed: base is now nil, center is c_hex instead of S_A / c_base 🔻
    local replace_card = Card(self.title_top.T.x, self.title_top.T.y, 1.2*G.CARD_W*SC_scale, 1.2*G.CARD_H*SC_scale, nil, G.P_CENTERS.c_hex)
    self.title_top:emplace(replace_card)

    replace_card.states.visible = false
    replace_card.no_ui = true
    replace_card.ambient_tilt = 0.0

    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay = change_context == 'game' and 1.5 or 0,
        blockable = false,
        blocking = false,
        func = (function()
            if change_context == 'splash' then 
                replace_card.states.visible = true
                replace_card:start_materialize({G.C.WHITE,G.C.WHITE}, true, 2.5)
                play_sound('whoosh1', math.random()*0.1 + 0.3,0.3)
                play_sound('crumple'..math.random(1,5), math.random()*0.2 + 0.6,0.65)
            else
                replace_card.states.visible = true
                replace_card:start_materialize({G.C.WHITE,G.C.WHITE}, nil, 1.2)
            end
            G.VIBRATION = G.VIBRATION + 1
            return true
    end)}))

    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay = change_context == 'splash' and 1.8 or change_context == 'game' and 2 or 0.5,
        blockable = false,
        blocking = false,
        func = (function()
            play_sound('magic_crumple'..(change_context == 'splash' and 2 or 3), (change_context == 'splash' and 1 or 1.3), 0.9)
            play_sound('whoosh1', 0.4, 0.8)
            ease_value(G.SPLASH_LOGO, 'dissolve', -1, nil, nil, nil, change_context == 'splash' and 2.3 or 0.9)
            G.VIBRATION = G.VIBRATION + 1.5
            return true
    end)}))

    delay(0.1 + (change_context == 'splash' and 2 or change_context == 'game' and 1.5 or 0))

    -- 🔻 removed: the block that swapped replace_card to a random locked Joker/Voucher 🔻
    -- (this kept it from dissolving Hex away a few seconds later)

    G.E_MANAGER:add_event(Event({func = function() G.CONTROLLER.lock_input = false; return true end}))
    set_screen_positions()

    self.title_top:sort('order')
    self.title_top:set_ranks()
    self.title_top:align_cards()
    self.title_top:hard_set_cards()

    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay = change_context == 'splash' and 4.05 or change_context == 'game' and 3 or 1.5,
        blockable = false,
        blocking = false,
        func = (function()
                set_main_menu_UI()
                return true
            end)
        }))

    for k, v in pairs(G.PROFILES[G.SETTINGS.profile].career_stats) do
        check_for_unlock({type = 'career_stat', statname = k})
    end
    check_for_unlock({type = 'blind_discoveries'})

    G.E_MANAGER:add_event(Event({
        blockable = false,
        func = function()
            set_discover_tallies()
            set_profile_progress()
            G.REFRESH_ALERTS = true
        return true
        end
      }))

    UIBox{
        definition = 
        {n=G.UIT.ROOT, config={align = "cm", colour = G.C.UI.TRANSPARENT_DARK}, nodes={
            {n=G.UIT.T, config={text = G.VERSION, scale = 0.3, colour = G.C.UI.TEXT_LIGHT}}
        }},
        config = {align="tri", offset = {x=0,y=0}, major = G.ROOM_ATTACH, bond = 'Weak'}
    }
end