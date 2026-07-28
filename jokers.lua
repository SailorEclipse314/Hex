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