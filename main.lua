print("I LOVE YURI!!!!!")

-- the Steammodded version is smods-1.0.0-beta-1620a
-- ALSO arrow(1,x) is always is to the power while tetartion uses arrow(2,x)

local mod = SMODS.current_mod

mod.badge_colour = HEX("1E3A8A")



mod.optional_features = {
    quantum = true,
    object_weights = true,
    retrigger_joker = true,
}

-- Amulet (Talisman-compatible) big-number support.
-- `to_big` is provided globally by Amulet; it converts a plain number into
-- an OmegaNum (cdata) value that can scale past the double-precision limit
-- of ~1.7e308. If Amulet's OmegaNum feature is turned off, `to_big` still
-- exists but just hands the plain number back, so it's always safe to call.
-- `big()` here is just a defensive wrapper in case Amulet isn't loaded at all.
function big(n)
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
function hex_to_plain_number(value)
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
function hex_format_points(value)
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

function hex_format_dollars(value)
    return hex_format_points(value)
end

-- Vanilla's default cap on how many cards can be highlighted at once to
-- play or discard (G.hand.config.highlighted_limit). Used by Polydactyly
-- to restore the normal limit once it's no longer owned.
HEX_POLY_DEFAULT_HAND_LIMIT = 5

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







-- Mirrors the live running Mult into G.GAME.hex_live_mult every single
-- time it changes during hand scoring. mod_mult() in misc_functions.lua
-- is a trivial identity wrapper that EVERY mult update in evaluate_play()
-- passes through (state_events.lua lines 615/893/910-912/etc.), so
-- hooking it here gives real-time visibility into "the current running
-- Mult" without touching evaluate_play() itself. By the time a Joker's
-- own calculate() runs for its context.joker_main effect (state_events.lua
-- line 905), the last mod_mult() call was from either the previous
-- Joker's own Xmult_mod/mult_mod application or this Joker's own edition
-- effect -- never this Joker's own joker_main effect, since that hasn't
-- been applied yet. So G.GAME.hex_live_mult at that moment is exactly
-- "the Mult so far, including every Joker to this card's left."
local hex_old_mod_mult = mod_mult

function mod_mult(_mult)
    local result = hex_old_mod_mult(_mult)

    if G.GAME then
        G.GAME.hex_live_mult = to_big(result)
    end

    return result
end

-- Extends the hex_live_chips mirror with an "override" mechanism: any
-- joker can call hex_arm_chip_override(value) right before returning
-- its calculate() result to force the VERY NEXT mod_chips() call to
-- return that exact value directly, bypassing addition/division
-- entirely. This avoids the catastrophic precision loss that happens
-- when arithmetic mixes a huge running Chips value with a comparatively
-- tiny target value (e.g. slog_chips - chips silently rounds to -chips
-- once chips is large enough, since the tiny slog_chips term falls
-- below floating-point/OmegaNum's significant-digit precision). Same
-- "arm right before triggering, consume once, clear after" idiom the
-- Black Hole display-total code uses elsewhere in this mod.
local hex_old_mod_chips = mod_chips
local hex_chip_override = nil

function mod_chips(_chips)
    if hex_chip_override ~= nil then
        local override = hex_chip_override
        hex_chip_override = nil

        if G.GAME then G.GAME.hex_live_chips = to_big(override) end
        return override
    end

    local result = hex_old_mod_chips(_chips)

    if G.GAME then G.GAME.hex_live_chips = to_big(result) end
    return result
end

function hex_arm_chip_override(value)
    hex_chip_override = value
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
            dollars = dollars:add(big(type(ret) == "number" and ret or ret.dollars or 0))
        end
    end
    for i = 1, #G.GAME.tags do
        local ret = G.GAME.tags[i]:apply_to_run({type = 'eval'})
        if ret then
            -- Some tags' apply_to_run return a plain number (just a dollar
            -- amount) instead of a table with .dollars/.condition/.pos/.tag --
            -- normalize here so indexing below never crashes.
            if type(ret) == "number" then
                ret = { dollars = ret }
            end

            add_round_eval_row({dollars = ret.dollars, bonus = true, name='tag'..i, pitch = pitch, condition = ret.condition, pos = ret.pos, tag = ret.tag})
            pitch = pitch + 0.06
            dollars = dollars + big(ret.dollars or 0)
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

-- ============================================================
-- content.lua holds every custom Atlas/Rarity registration, plus
-- every deck (Back), seal, edition, enhancement, poker hand, shader,
-- sticker, and voucher (and their support systems). jokers.lua holds
-- every SMODS.Joker (and its support systems). consumables.lua holds
-- every SMODS.Consumable/ConsumableType, their dedicated packs, and
-- their support systems. All three are loaded here, in that order,
-- via SMODS.load_file, so they run AFTER main.lua's own top-level
-- code -- every shared helper defined above (big, hex_to_plain_number,
-- hex_format_points, hex_format_dollars, hex_set_hand_stat,
-- hex_owns_showman, hex_apply_immortal_sticker, hex_count_diamond_cards,
-- hex_cursed_deck_selected, the custom Rarities/Atlases/colours,
-- HEX_IMMORTAL_STICKER_KEY, HEX_SOUL_CENTER_KEY, HEX_HEART_CENTER_KEY,
-- HEX_ALTAIR_BASE_RATE, HEX_POLY_DEFAULT_HAND_LIMIT,
-- HEX_SHOP_ENHANCED_ALLOWED) is already a defined global by the time
-- each file's own top-level code runs. jokers.lua loads before
-- consumables.lua because hex_huge_lqg_eligible_jokers (defined in
-- jokers.lua) needs to already be a defined global by the time
-- consumables.lua's own top-level code runs.
-- ============================================================
assert(SMODS.load_file("content.lua"))()
assert(SMODS.load_file("jokers.lua"))()
assert(SMODS.load_file("consumables.lua"))()