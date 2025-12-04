-- Harvest Engine lib
-- Engine params and functions
--
-- @module HarvestEngine
-- @release v1.0
-- imminent gloom

local Harvest = {}

-- adds a list of params
-- @bool midicontrol If false, don't build and set-up midi params
function Harvest.init(midicontrol)

-- main
   params:add{
      type        = "control",
      id          = "fx_amp",
      name        = "volume",
      controlspec = controlspec.new(0, 2, 'lin', 0.01, 0.5),
      action      = function(x)
         engine.harvest_fx_set("amp", x)
      end
   }

-- drone
   params:add_separator("drone", "drone")

   params:add{
      type        = "control",
      id          = "drone_amp",
      name        = "volume",
      controlspec = controlspec.new(0, 1, 'lin', 0.01, 0.8),
      action      = function(x)
         engine.harvest_drone_set("amp", x)
      end
   }

   params:add{
      type        = "control",
      id          = "drone_timbre",
      name        = "timbre",
      controlspec = controlspec.new(0, 1, 'lin', 0.01, 0.5),
      action      = function(x)
         engine.harvest_drone_set("timbre", x)
      end
   }

   params:add{
      type        = "control",
      id          = "drone_noise",
      name        = "noise",
      controlspec = controlspec.new(0, 1, 'lin', 0.01, 0.0),
      action      = function(x)
         engine.harvest_drone_set("noise", x)
      end
   }

   params:add{
      type        = "control",
      id          = "drone_bias",
      name        = "bias",
      controlspec = controlspec.new(0, 1, 'lin', 0.01, 0),
      action      = function(x)
         engine.harvest_drone_set("bias", x)
      end
   }

   params:add{
      type        = "control",
      id          = "drone_freq",
      name        = "freq",
      controlspec = controlspec.new(0.2, 2000, 'exp', 0.01, 117, 'hz'),
      action      = function(x)
         engine.harvest_drone_set("freq", x)
      end
   }
   
-- poly
   params:add_separator("poly", "poly")
   
   params:add{
      type        = "control",
      id          = "poly_amp",
      name        = "volume",
      controlspec = controlspec.new(0, 1, 'lin', 0.01, 0.8),
      action      = function(x)
         engine.harvest_poly_set("amp", x)
      end
   }

   params:add{
      type        = "control",
      id          = "poly_timbre",
      name        = "timbre",
      controlspec = controlspec.new(0, 1, 'lin', 0.01, 0.2),
      action      = function(x)
         engine.harvest_poly_set("timbre", x)
      end
   }

   params:add{
      type        = "control",
      id          = "poly_noise",
      name        = "noise",
      controlspec = controlspec.new(0, 1, 'lin', 0.01, 0.3),
      action      = function(x)
         engine.harvest_poly_set("noise", x)
      end
   }

   params:add{
      type        = "control",
      id          = "poly_bias",
      name        = "bias",
      controlspec = controlspec.new(0, 1, 'lin', 0.01, 0.6),
      action      = function(x)
         engine.harvest_poly_set("bias", x)
      end
   }

   params:add{
      type        = "control",
      id          = "poly_shape",
      name        = "shape",
      controlspec = controlspec.new(0, 1, 'lin', 0.01, 0.1),
      action      = function(x)
         engine.harvest_poly_set("shape", x)
      end
   }

   params:add{
      type        = "option",
      id          = "poly_loop",
      name        = "loop",
      options     = {"no", "yes"},
      default     = 1,
      action      = function(x)
         engine.harvest_poly_set("loop", x - 1)
      end
   }

   params:add{
      type        = "control",
      id          = "poly_max_attack",
      name        = "attack",
      controlspec = controlspec.new(0.001, 10, 'exp', 0.01, 1, "sec"),
      action      = function(x)
         engine.harvest_poly_set("max_attack", x)
      end
   }

   params:add{
      type        = "control",
      id          = "poly_max_release",
      name        = "release",
      controlspec = controlspec.new(0.001, 10, 'exp', 0.01, 3, "sec"),
      action      = function(x)
         engine.harvest_poly_set("max_release", x)
      end
   }
   
   params:add{
      type        = "control",
      id          = "poly_scale",
      name        = "scale",
      controlspec = controlspec.new(0.01, 1, 'lin', 0.01, 1),
      action      = function(x)
         engine.harvest_poly_set("scale", x)
      end
   }

-- fx
   params:add_separator("fx_filter_delay", "filter + delay")
   
   params:add{
      type        = "control",
      id          = "fx_peak_1",
      name        = "peak 1, cutoff",
      controlspec = controlspec.new(20, 20000, 'exp', 0.01, 115, "hz"),
      action      = function(x)
         engine.harvest_fx_set("peak1", x)
      end
   }
   
   params:add{
      type        = "option",
      id          = "fx_type_1",
      name        = "peak 1, type",
      options     = {"lp", "bp", "hp"},
      default     = 2,
      action      = function(x)
         engine.harvest_poly_set("type1", x - 1)
      end
   }

   params:add{
      type        = "control",
      id          = "fx_peak_2",
      name        = "peak 2, cutoff",
      controlspec = controlspec.new(20, 20000, 'exp', 0.01, 218, "hz"),
      action      = function(x)
         engine.harvest_fx_set("peak2", x)
      end
   }

   params:add{
      type        = "option",
      id          = "fx_type_2",
      name        = "peak 2, type",
      options     = {"lp", "bp", "hp"},
      default     = 2,
      action      = function(x)
         engine.harvest_poly_set("type2", x - 1)
      end
   }

   params:add{
      type        = "control",
      id          = "fx_meta",
      name        = "feedback",
      controlspec = controlspec.new(0, 1, 'lin', 0.01, 0),
      action      = function(x)
         engine.harvest_fx_set("meta", x)
      end
   }

   params:add{
      type        = "control",
      id          = "fx_time",
      name        = "time",
      controlspec = controlspec.new(0.01, 2, 'lin', 0.001, 1, "sec"),
      action      = function(x)
         engine.harvest_fx_set("time", x)
      end
   }

   params:add_separator("fx_distortion", "distortion")

   params:add{
      type        = "control",
      id          = "fx_gain",
      name        = "gain",
      controlspec = controlspec.new(0.5, 16, 'lin', 0.01, 1),
      action      = function(x)
         engine.harvest_fx_set("gain", x)
      end
   }

-- midi
   if not midicontrol then
      return
   end
   params:add_separator("midi_sep", "midi")
   local mididevice = {}
   local mididevice_list={"none"}
   midi_channels={"all"}
   for i=1,16 do
      table.insert(midi_channels,i)
   end
   for _,dev in pairs(midi.devices) do
      if dev.port ~= nil then
            local name = string.lower(dev.name)
            table.insert(mididevice_list,name)
            print("adding " .. name .. " to port " ..dev.port)
            mididevice[name] = {
               name = name,
               port = dev.port,
               midi = midi.connect(dev.port),
               active = false,
            }
            mididevice[name].midi.event = function(data)
               if mididevice[name].active == false then
                  return
               end
               local d = midi.to_msg(data)
               if d.ch ~= midi_channels[params:get("midichannel")]
                  and params:get("midichannel") > 1 then
                  return
               end
               if d.type == "note_on" then
                  local amp = util.linexp(1, 127, 0.01, 1.0, d.vel)
                  engine.harvest_note_on(d.note, amp, 600)
               elseif d.type == "note_off" then
                  engine.harvest_note_off(d.note)
               elseif d.cc == 64 then -- sustain pedal
                  local val = d.val > 126 and 1 or 0
                  if params:get("pedal_mode") == 1 then
                        engine.harvest_sustain(val)
                  else
                        engine.harvest_sostenuto(val)
                  end
               end
            end
      end
   end
   tab.print(mididevice_list)

   params:add{
      type    = "option",
      id      = "pedal_mode",
      name    = "pedal mode",
      options = {"sustain", "sostenuto"},
      default = 1,
   }
   params:add{
      type    = "option",
      id      = "midi",
      name    = "midi in",
      options = mididevice_list,
      default = 1
   }
   params:set_action("midi", function(v)
      if v == 1 then return end
      for _, dev in pairs(mididevice) do
            dev.active = false
      end
      mididevice[mididevice_list[v]].active = true
   end)
   params:add{
      type    = "option",
      id      = "midichannel",
      name    = "midi ch",
      options = midi_channels,
      default = 1
   }

   if #mididevice_list>1 then
      params:set("midi",2)
   end
end

-- Note on function
-- @int note Midi note number
-- @number vel Velocity (0.0-1.0)
-- @number time Gate time (optional)
function Harvest.note_on(note, vel, time)
   if not time then time = 600 end
   engine.harvest_note_on(note, vel, time)
end

-- Note off function
-- @int note Midi note number
function Harvest.note_off(note)
   engine.harvest_note_off(note)
end

return Harvest
