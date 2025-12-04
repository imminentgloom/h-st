--      .                   
--                         
--          .          .     
--   HøST
--                .         
--    .                     
--                         .
-- .
-- v1.0 / imminent gloom 

-- setup
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

engine.name = "Harvest"
Harvest = include("lib/Harvest_engine")
tab = require("tabutil")

local save_on_exit = true

local g = grid.connect()
local a = arc.connect()

local s = screen
local fps = 60
local splash = false
local frame = 1

local soil = {}
local particles = 48

local focus = 1
local prev_focus = 1

-- keyboard
local playing = {}
local voice = 1
local transpose = 0
local note
local velocity = 100
local duration = 600
local ch = 1
local hold = false
local oct = 2
local trail = 8

-- clock events
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

local function redraw_event()
   while true do
      clock.sleep(1/fps)
      redraw()
      redraw_grid()
      redraw_arc()
   end
end

local function splash_event()
   if splash then
      splash_level = 15
      while splash_level > 0 do
         clock.sleep(0.05)
         splash_level = splash_level - 1
      end
      splash = false
   end
end

-- functions
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

local function seed(n)
   for n = 1, n do
      soil[n] = {math.random(2, 127), math.random(2, 63)}
   end
end

local function stop_keys()
   for n = 1, #playing do
      engine.harvest_note_off(playing[n].note + playing[n].transpose)
   end
   playing = {}
end

local function stop_held()
   for n = #playing, 1, -1 do
      if playing[n].held then
         engine.harvest_note_off(playing[n].note + playing[n].transpose)
         table.remove(playing, n)
      end
   end
end

local function xy_to_note(x, y)
   note = 12
   note = note + x
   note = note + 5 * (8 - y)
   return note
end

local function play_note(x, y, z, note)
   note = note or xy_to_note(x, y)
   transpose = 12 * oct
   if z == 1 then 
      if #playing >= 4 then
         engine.harvest_note_off(playing[1].note + playing[1].transpose)
         table.remove(playing, 1)
      end
      table.insert(playing, {note = note, transpose = transpose, x = x, y = y, held = false})
      engine.harvest_note_on(note + transpose, velocity, duration)
   else
      for i, v in pairs(playing) do
         if v.x == x and v.y == y then
            engine.harvest_note_off(playing[i].note + playing[i].transpose)
            table.remove(playing, i)
            break
         end
      end
   end
end

local function hold_note(x, y, z, note)
   if z == 1 then
      note = note or xy_to_note(x, y)
      transpose = 12 * oct
      local voice = nil
      for i, v in pairs(playing) do
         if v.x == x and v.y == y then
            engine.harvest_note_off(playing[i].note + playing[i].transpose)
            table.remove(playing, i)
            voice = i
            break
         end
      end
      if voice == nil then
         if #playing >= 4 then
            engine.harvest_note_off(playing[1].note + playing[1].transpose)
            table.remove(playing, 1)
         end
         table.insert(playing, {note = note, transpose = transpose, x = x, y = y, held = true})
         engine.harvest_note_on(note + transpose, velocity, duration)
      end
   end
end

-- params
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

params:add{
   type = "group",
   id   = "harvest",
   name = "HØST",
   n    = 27
}

params:add{
   type        = "option",
   id          = "focus",
   name        = "focus",
   options     = {"drone", "poly", "fx"},
   default     = 1, 
   action      = function(x)
      prev_focus = focus
      focus = x
      seed(particles)
   end
}

-- init
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function init()
   seed(particles)

   clk_redraw = clock.run(redraw_event)
   clk_splash = clock.run(splash_event)

   Harvest.init(false)
   
   if save_on_exit then params:read(norns.state.data .. "state.pset") end
   params:set("focus", 1)
end

-- norns: keys
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function key(n, z)
   if n == 1 and z == 1 then k1_held = true end
   if n == 1 and z == 0 then k1_held = false end
   if n == 2 and z == 1 then k2_held = true end
   if n == 2 and z == 0 then k2_held = false end
   if n == 3 and z == 1 then k3_held = true end
   if n == 3 and z == 0 then k3_held = false end

   if n == 2 and z == 1 and not k3_held then
      params:set("focus", 1)
   end

   if n == 3 and z == 1 and not k2_held then
      params:set("focus", 2)
   end

   if k2_held and k3_held then
      params:set("focus", 3)
   end
end

-- norns: encoders
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function enc(n, d)
   if n == 1 then
      params:delta("focus", d)
   end
   if n == 2 then
      params:delta("fx_gain", d)
   end
   if n == 3 then
      params:delta("poly_scale", d)
   end
end

-- grid: keys
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

g.key = function(x, y, z)
   if x == 1 and y == 1 then
      if z == 1 then
         if hold then 
            hold = false
            stop_held()
            -- for n = 1, #playing do
            --    if playing[n][5] == "held" then
            --       print(n)
            --       engine.harvest_note_off(playing[n][3] + playing[n][4])
            --       table.remove(playing, n)
            --    end
            -- end
         else
            hold = true
         end
      end
   elseif x == 1 and y == 2 then
      if z == 1 then
         if params:get("poly_loop") == 2 then
            params:set("poly_loop", 1)
         else
            params:set("poly_loop", 2)
         end
      end
   elseif x == 1 and y == 3 then
      if z == 1 then
         params:set("focus", 1)
      end
   elseif x == 1 and y == 4 then
      if z == 1 then
         params:set("focus", 2)
      end
   elseif x == 1 and y == 5 then
      if z == 1 then
         params:set("focus", 3)
      end
   elseif x == 1 and y == 6 then
      if z == 1 then
         oct = 3
      end
   elseif x == 1 and y == 7 then
      if z == 1 then
         oct = 2
      end
   elseif x == 1 and y == 8 then
      if z == 1 then
         oct = 1
      end
   else
      if not hold then
         play_note(x, y, z)
      else   
         hold_note(x, y, z)  
      end
   end
end

-- arc: key
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

a.key = function(n, z)
   if n == 1 then
      if z == 1 then
         if focus == 3 then
            focus = prev_focus
         else
            prev_focus = focus
            focus = 3
         end
      end
      if z == 0 then
         if focus == 3 then
            focus = prev_focus
         else
            focus = 3
         end
      end
   end
end

-- arc: encoders
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

a.delta = function(n, d)
   d = d * 0.1

   if focus == 1 then
      if n == 1 then
         params:delta("drone_timbre", d)
      end
      if n == 2 then
         params:delta("drone_noise", d)
      end
      if n == 3 then
         params:delta("drone_bias", d)
      end
      if n == 4 then
         params:delta("drone_freq", d)
      end
   end

   if focus == 2 then
      if n == 1 then
         params:delta("poly_timbre", d)
      end
      if n == 2 then
         params:delta("poly_noise", d)
      end
      if n == 3 then
         params:delta("poly_bias", d)
      end
      if n == 4 then
         params:delta("poly_shape", d)
      end
   end

   if focus == 3 then
      if n == 1 then
         params:delta("fx_peak_1", d)
      end
      if n == 2 then
         params:delta("fx_peak_2", d)
      end
      if n == 3 then
         params:delta("fx_meta", d)
      end
      if n == 4 then
         params:delta("fx_time", d)
      end
   end
end

-- norns: drawing
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function redraw()
   local lengths = {0, 2, 64}
   local levels = {
      {15,  0,  0,  0}, -- drone
      {15,  3,  7,  0}, -- poly
      {15,  3,  7,  0}, -- fx
   }

   s.clear()
   s.aa(0)

   if splash then
      s.level(splash_level)
      s.move(63, 48)
      s.font_face(9)
      s.font_size(40)
      s.text_center("høst")
   else
      if focus == 1 then
         soil_level = levels[1][1]
         leaf_level = levels[1][2]
         light_level = levels[1][3]
         dark_level = levels[1][4]
         length = lengths[1]
      elseif focus == 2 then
         soil_level = levels[2][1]
         leaf_level = levels[2][2]
         light_level = levels[2][3]
         dark_level = levels[2][4]
         length = lengths[2]
      elseif focus == 3 then
         soil_level = levels[3][1]
         leaf_level = levels[3][2]
         light_level = levels[3][3]
         dark_level = levels[3][4]
         length = lengths[3]
      end
      
      --light
      s.level(light_level)
      s.move(64, 0)
      s.line(0, 64)
      s.line(0, 64)
      s.line(128, 64)
      s.line(128, 0)
      s.fill()

      -- detrius
      s.level(leaf_level)
      s.line_width(1)
      for n = 1, #soil do
         x = soil[n][1]
         y = soil[n][2]
         s.move(x, y + 1)
         s.line(x - length, y + 1 + length)
      end
      s.stroke()

      -- dark
      s.level(dark_level)
      s.move(64, 0)
      s.line(0, 64)
      s.line(0, 0)
      s.fill()
      
      -- soil
      s.level(soil_level)
      for n = 1, #soil do
         x = soil[n][1]
         y = soil[n][2]
         s.pixel(x, y)
      end
      s.fill()
   end

   s.update()
   s.ping()
end

-- grid: drawing
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function redraw_grid()
   g:all(0)

   local background = 3
   -- background
   for n = 6, 16 do g:led(n, 1, background) end
   for n = 5, 16 do g:led(n, 2, background) end
   for n = 4, 16 do g:led(n, 3, background) end
   for n = 3, 16 do g:led(n, 4, background) end
   for n = 2, 16 do g:led(n, 5, background) end
   for n = 1, 16 do g:led(n, 6, background) end
   for n = 1, 16 do g:led(n, 7, background) end
   for n = 1, 16 do g:led(n, 8, background) end
   
   -- coll 1 off
   if not hold then g:led(1, 1, background) end
   if not hold then g:led(1, 2, background) end
   
   for n = 6, 8 do 
      g:led(1, n, background)
   end

   -- light up held keys
   for n = 1, #playing do
      for m = 1, math.min(trail, playing[n].x - 1) do
         g:led(playing[n].x - m, playing[n].y + m, 0)
      end
   end
   for n = 1, #playing do
      g:led(playing[n].x, playing[n].y, 10)
   end

   -- col 1 on
   if hold then g:led(1, 1, 10) end 
   if params:get("poly_loop") == 2 then g:led(1, 2, 10) end 
   
   g:led(1, 2 + focus, 5)
   g:led(1, 9 - oct, 5)

   g:refresh()
end

-- arc: drawing
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function redraw_arc()
   a:all(0)
   
   if focus == 1 then
      local offset = 5.625 * -31
      local level = 5
      local s1 = 0
      local s2 = 0

      local val = params:get_raw("drone_timbre") * 2 - 1
      if val < 0 then
         s1 = math.rad(val * 5.625 * 31)
         s2 = math.rad(0)
      else
         s1 = math.rad(0)
         s2 = math.rad(val * 5.625 * 32)
      end
      a:segment(1, s1, s2, level)
      a:led(1, 1, 1)
      a:led(1, 33, 1)
      
      s1 = math.rad(offset)
      s2 = math.rad(params:get_raw("drone_noise") * 5.625 * 63 + offset)
      a:segment(2, s1, s2, level)
      a:led(2, 1, 1)
      a:led(2, 33, 1)
      
      s1 = math.rad(offset)
      s2 = math.rad(params:get_raw("drone_bias") * 5.625 * 63 + offset)
      a:segment(3, s1, s2, level)
      a:led(3, 33, 1)
      
      s1 = math.rad(offset)
      s2 = math.rad(params:get_raw("drone_freq") * 5.625 * 63 + offset)
      a:segment(4, s1, s2, level)
      a:led(4, 33, 1)
      a:led(4, 1, 1)
   end
   
   if focus == 2 then
      local offset = 5.625 * -31
      local level = 5
      local s1 = 0
      local s2 = 0

      local val = params:get_raw("poly_timbre") * 2 - 1
      if val < 0 then
         s1 = math.rad(val * 5.625 * 31)
         s2 = math.rad(0)
      else
         s1 = math.rad(0)
         s2 = math.rad(val * 5.625 * 32)
      end
      a:segment(1, s1, s2, level)
      a:led(1, 1, 1)
      a:led(1, 33, 1)
      
      s1 = math.rad(offset)
      s2 = math.rad(params:get_raw("poly_noise") * 5.625 * 63 + offset)
      a:segment(2, s1, s2, level)
      a:led(2, 1, 1)
      a:led(2, 33, 1)
      
      s1 = math.rad(offset)
      s2 = math.rad(params:get_raw("poly_bias") * 5.625 * 63 + offset)
      a:segment(3, s1, s2, level)
      a:led(3, 33, 1)
      
      s1 = math.rad(offset)
      s2 = math.rad(params:get_raw("poly_shape") * 5.625 * 63 + offset)
      a:segment(4, s1, s2, level)
      a:led(4, 33, 1)
      a:led(4, 1 + 11, 1)
      a:led(4, 1 - 11, 1)
   end

   if focus == 3 then
      local offset = 5.625 * -31
      local level = 5
      local s1 = 0
      local s2 = 0
      local lp1 = 0
      local lp2 = 0
      local bp1 = 0
      local bp2 = 0
      local hp1 = 0
      local hp2 = 0

      if params:get("fx_type_1") == 1 then
         lp1 = math.rad(offset)
         lp2 = math.rad(params:get_raw("fx_peak_1") * 5.625 * 63 + offset)
         a:segment(1, lp1, lp2, level)
      end 
      if params:get("fx_type_1") == 2 then
         bp1 = math.rad(params:get_raw("fx_peak_1") * 5.625 * 60 + offset)
         bp2 = math.rad(params:get_raw("fx_peak_1") * 5.625 * 60 + 5.625 * 3 + offset)
         a:segment(1, bp1, bp2, level)
      end 
      if params:get("fx_type_1") == 3 then
         hp1 = math.rad(params:get_raw("fx_peak_1") * 5.625 * 63 + offset)
         hp2 = math.rad(offset + 5.625 * 63)
         a:segment(1, hp1, hp2, level)
      end 
      a:led(1, 33, 1)
      
      if params:get("fx_type_2") == 1 then
         lp1 = math.rad(offset)
         lp2 = math.rad(params:get_raw("fx_peak_2") * 5.625 * 63 + offset)
         a:segment(2, lp1, lp2, level)
      end 
      if params:get("fx_type_2") == 2 then
         bp1 = math.rad(params:get_raw("fx_peak_2") * 5.625 * 60 + offset)
         bp2 = math.rad(params:get_raw("fx_peak_2") * 5.625 * 60 + 5.625 * 3 + offset)
         a:segment(2, bp1, bp2, level)
      end 
      if params:get("fx_type_2") == 3 then
         hp1 = math.rad(params:get_raw("fx_peak_2") * 5.625 * 63 + offset)
         hp2 = math.rad(offset + 5.625 * 63)
         a:segment(2, hp1, hp2, level)
      end 
      a:led(2, 33, 1)

      s1 = math.rad(offset)
      s2 = math.rad(params:get_raw("fx_meta") * 5.625 * 63 + offset)
      a:segment(3, s1, s2, level)
      a:led(3, 1, 1)
      a:led(3, 33, 1)
      
      s1 = math.rad(offset)
      s2 = math.rad(params:get_raw("fx_time") * 5.625 * 63 + offset)
      a:segment(4, s1, s2, level)
      a:led(4, 33, 1)
   end

   a:refresh()
end

-- cleanup
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function cleanup()
   if save_on_exit then params:write(norns.state.data .. "state.pset") end
end
