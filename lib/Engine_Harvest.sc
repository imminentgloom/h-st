// Engine_harvest
// a part of Høst
//
// v1.1
// imminent gloom

Engine_Harvest : CroneEngine {
   var harvestParameters;
   var harvestVoices;
   var harvestVoicesOn;
   var harvestDrone;
   var harvestFx;
   var harvestBus;
   var fnNoteOn, fnNoteOnPoly, fnNoteAdd;
   var fnNoteOff, fnNoteOffPoly;
   var pedalSustainOn = false;
   var pedalSostenutoOn = false;
   var pedalSustainNotes;
   var pedalSostenutoNotes;
   var harvestPolyphonyMax = 6;
   var harvestPolyphonyCount = 0;

   *new { arg context, doneCallback;
      ^super.new(context, doneCallback);
   }

   alloc {

      // initialize variables
      harvestParameters = Dictionary.with(*[
         "amp"->0.8,
         "timbre"->0.2,
         "noise"->0.3,
         "bias"->0.6,
         "freq"->100.0,
         "loop"->0.0,
         "shape"->0.1,
         "max_attack"->1,
         "max_release"->3,
         "scale"->1,
      ]);
      harvestVoices = Dictionary.new;
      harvestVoicesOn = Dictionary.new;
      pedalSustainNotes = Dictionary.new;
      pedalSostenutoNotes = Dictionary.new;

      // initialize synth defs
      SynthDef(\harvestfx, {
         var input, body, filter, peak1, peak2, res, delay, time, feedback, mix, gain, dist;
  
         input = In.ar(\inBus.ir(10), 2);

         body     = \body.kr(0.0, 0.1);
         res      = LinSelectX.kr(body * 3, [0.5, 0.5, 0.5 , 0.5]);
         feedback = LinSelectX.kr(body * 3, [0.0, 0.2, 0.99, 0.8]);

         peak1 = SVF.ar(input, \peak1.kr(115, 0.1).clip(20, 20000), res, 0, 1, 0);
         peak2 = SVF.ar(input, \peak2.kr(218, 0.1).clip(20, 20000), res, 0, 1, 0);

         filter = peak1 + peak2;

         delay = XFade2.ar(filter, input, SelectX.kr(body * 3, [-1, -1, -1, 1]));
         delay = delay + LPF.ar(LocalIn.ar(2), 4000) * feedback;
         delay = DelayC.ar(delay, 10, \time.kr(1, 0.25));
         LocalOut.ar(delay);

         mix = SelectX.ar(body * 3, [input, filter, filter + delay * 0.7, input * 0.5 + delay]);

         gain = \gain.kr(1, 0.1);
         dist = (mix * gain).tanh * (1 / gain.sqrt) * \amp.kr(0.5, 0.1);

         Out.ar(\out.ir(0), dist);
      }).add;

      SynthDef(\harvestdrone, {
         var amp, freq, noise, timbre, pulsewidth, sine, saw, square, waveform, threshold, min, lpg;

         amp = \amp.kr(0.8, 0.1);
         freq = \freq.kr(100, 0.1);
         noise = \noise.kr(0.0, 0.1);
         timbre = \timbre.kr(0.5, 0.1);

         freq = WhiteNoise.ar(noise) * freq + freq;
         freq = freq.clip(0, SampleRate.ir * 0.5);

         pulsewidth = LinSelectX.kr(timbre * 2, [0.001, 0.5, 1]);
         
         sine   = SinOsc.ar(freq);
         saw    = VarSaw.ar(freq, 0, pulsewidth, 0.61);
         square = Pulse.ar(freq, pulsewidth, 0.667);

         waveform = SelectX.ar(timbre * 2, [saw, sine, square]);
         waveform = SelectX.ar( noise * 2, [waveform, waveform * PinkNoise.ar(noise * 3.5, 1), PinkNoise.ar(3.5)]);
         waveform = waveform.clip(-1, 1);
         
         threshold = -1 * (\bias.kr(0, 0.1) * 2 - 1);
         min = LeakDC.ar((waveform > threshold * waveform) + (waveform <= threshold * threshold));

         lpg = LPF.ar(min, amp.linexp(0, 1, 200, 20000), amp);

         Out.ar(\out.ir(0), Pan2.ar(lpg) * 0.5);
      }).add;

      SynthDef(\harvestpoly, {
         var amp, freq, noise, timbre, pulsewidth, sine, saw, square, waveform, bias, threshold, min, vel, gate, loop, shape, scale, max_attack, max_release, attack, release, curve, asr, ararar, env, lpg;

         amp = \amp.kr(0.8, 0.1);
         freq = \freq.kr(100, 0.1);
         noise = \noise.kr(0.0, 0.1);
         timbre = \timbre.kr(0.5, 0.1);

         freq = WhiteNoise.ar(noise) * freq + freq;
         freq = freq.clip(0, SampleRate.ir * 0.5);

         pulsewidth = LinSelectX.kr(timbre * 2, [0.001, 0.5, 1]);
         
         sine   = SinOsc.ar(freq);
         saw    = VarSaw.ar(freq, 0, pulsewidth, 0.61);
         square = Pulse.ar(freq, pulsewidth, 0.667);

         waveform = SelectX.ar(timbre * 2, [saw, sine, square]);
         waveform = SelectX.ar( noise * 2, [waveform, waveform * PinkNoise.ar(noise * 3.5, 1), PinkNoise.ar(3.5)]);
         waveform = waveform.clip(-1, 1);
         
         threshold = -1 * (\bias.kr(1.0, 0.1) * 2 - 1);
         min = LeakDC.ar((waveform > threshold * waveform) + (waveform <= threshold * threshold));

         vel =    \vel.kr(1.0);
         gate =    \gate.kr(1.0);
         loop =     \loop.kr(0);
         shape =     \shape.kr(0.1, 0.1);
         max_attack = \max_attack.kr(1, 0.1);
         max_release = \max_release.kr(3, 0.1);
         scale =        \scale.kr(1, 0.1);

         attack  = (LinSelectX.kr(shape * 3, [0.01, 0.01, max_attack, max_attack]) * scale).clip(0.01, max_attack);
         release = (LinSelectX.kr(shape * 3, [0.01, max_release, max_release, 0.01]) * scale).clip(0.01, max_release);
         curve   =  LinSelectX.kr(shape * 3, [-2, -0.5, 0, 0]);

         asr    = EnvGen.kr(Env.asr(attack, 1, release, curve: curve), gate, doneAction: 2);
         ararar = EnvGen.kr(Env.new([0, 1, 0, 1, 0], [attack, release, attack, release], releaseNode: 3, loopNode: 1, curve: curve), gate, doneAction: 2);
         env    = LinSelectX.kr(loop.lag((release * scale).clip(0.01, release)), [asr, ararar]);

         lpg = LPF.ar(min, env.linexp(0, 1, 200, 20000), env * vel * amp);

         Out.ar(\out.ir(0), Pan2.ar(lpg) * 0.5);
      }).add;

      // initialize fx synth and bus
      context.server.sync;
      harvestBus = Bus.audio(context.server, 2);
      context.server.sync;
      harvestFx = Synth.new(\harvestfx, [\out, 0, \inBus, harvestBus]);
      context.server.sync;
      harvestDrone = Synth.new(\harvestdrone, [\out, harvestBus]);
      context.server.sync;

      fnNoteOnPoly = {
         arg note, amp, duration;
         var lowestNote = 10000;
         var sub = 0;
         // (harvestParameters.at("synth")++" note_on "++note).postln;

         // low-note priority for sub oscillator
         harvestVoicesOn.keysValuesDo({ arg key, syn;
            if (key < lowestNote, {
               lowestNote = key;
            });
         });
         if (lowestNote < 10000,{
            if (note < lowestNote, {
               sub = 1;
               harvestVoices.at(lowestNote).set(\sub, 0);
            },{
               sub = 0;
            });
         },{
            sub = 1;
         });

         harvestVoices.put(note,
            Synth.before(harvestFx, "harvestpoly",[
               \amp, harvestParameters.at("amp"),
               \out, harvestBus,
               \freq, (note).midicps,
               \timbre, harvestParameters.at("timbre"),
               \noise, harvestParameters.at("noise"),
               \bias, harvestParameters.at("bias"),
               \shape, harvestParameters.at("shape"),
               \loop, harvestParameters.at("loop"),
               \max_attack, harvestParameters.at("max_attack"),
               \max_release, harvestParameters.at("max_release"),
               \scale, harvestParameters.at("scale")
            ]);
         );
         NodeWatcher.register(harvestVoices.at(note));
         fnNoteAdd.(note);
      };

      fnNoteAdd = {
         arg note;
         var oldestNote = 0;
         var oldestNoteVal = 10000000;
         harvestPolyphonyCount = harvestPolyphonyCount + 1;
         harvestVoicesOn.put(note, harvestPolyphonyCount);
         if (harvestVoicesOn.size > harvestPolyphonyMax, {
            // remove the oldest voice
            harvestVoicesOn.keysValuesDo({ arg key, val;
               if (val < oldestNoteVal, {
                  oldestNoteVal = val;
                  oldestNote = key;
               });
            });
            ("max polyphony reached, removing note "++oldestNote).postln;
            fnNoteOff.(oldestNote);
         });
      };

      // intialize helper functions
      fnNoteOn = {
         arg note, amp, duration;
         // ("note on: "++note).postln;
         fnNoteOnPoly.(note, amp, duration);
      };

      fnNoteOff = {
         arg note;
         // ("note off: "++note).postln;
         // remove it it hasn't already been removed	and synth gone
         if ((harvestVoices.at(note) == nil) || ((harvestVoices.at(note).isRunning == false) && (harvestVoicesOn.at(note) == nil)),{},{
            fnNoteOffPoly.(note);
         });
      };

      fnNoteOffPoly = {
         arg note;
         var lowestNote = 10000;
         // ("harvest_note_off "++note).postln;

         harvestVoicesOn.removeAt(note);

         if (pedalSustainOn == true, {
            pedalSustainNotes.put(note, 1);
         }, {
            if ((pedalSostenutoOn == true) && (pedalSostenutoNotes.at(note) != nil),{
               // do nothing, it is a sostenuto note
            }, {
               // remove the sound
               harvestVoices.at(note).set(\gate, 0);
            });
         });
      };

      // add norns commands
      this.addCommand("harvest_note_on", "iff", { arg msg;
         var lowestNote = 10000;
         var note = msg[1];
         if (harvestVoices.at(note) != nil, {
            if (harvestVoices.at(note).isRunning == true, {
               // (harvestParameters.at("synth")++" retrigger "++note).postln;
               harvestVoices.at(note).set(\gate, 0);
            });
         });
         fnNoteOn.(msg[1], msg[2], msg[3]);
      });

      this.addCommand("harvest_note_off", "i", { arg msg;
         var note = msg[1];
         fnNoteOff.(note);
      });

      this.addCommand("harvest_sustain", "i", { arg msg;
         pedalSustainOn = (msg[1] == 1);
         if (pedalSustainOn == false, {
            // release all sustained notes
            // that aren't currently being held down
            pedalSustainNotes.keysValuesDo({ arg note, val;
               if (harvestVoicesOn.at(note) == nil, {
                  pedalSustainNotes.removeAt(note);
                  fnNoteOff.(note);
               });
            });
         },{
            // add currently down notes to the pedal
            harvestVoicesOn.keysValuesDo({ arg note, val;
               pedalSustainNotes.put(note, 1);
            });
         });
      });

      this.addCommand("harvest_sustenuto", "i", { arg msg;
         pedalSostenutoOn = (msg[1] == 1);
         if (pedalSostenutoOn == false, {
            // release all sustained notes
            // that aren't currently being held down
            pedalSostenutoNotes.keysValuesDo({ arg note, val;
               if (harvestVoicesOn.at(note) == nil, {
                  pedalSostenutoNotes.removeAt(note);
                  fnNoteOff.(note);
               });
            });
         },{
            // add currently held notes
            harvestVoicesOn.keysValuesDo({ arg note, val;
               pedalSostenutoNotes.put(note, 1);
            });
         });
      });

      this.addCommand("harvest_fx_set","sf",{ arg msg;
         var key = msg[1].asSymbol;
         var val = msg[2];
         harvestFx.set(key, val);
      });

      this.addCommand("harvest_drone_set","sf",{ arg msg;
         var key = msg[1].asSymbol;
         var val = msg[2];
         harvestDrone.set(key, val);
      });

      this.addCommand("harvest_poly_set", "sf", { arg msg;
         var key = msg[1].asString;
         var val = msg[2];
         harvestParameters.put(key, val);
         switch (key,
            "", {}, // add parameters here if you don't want them to change while voice is playing
            {
               harvestVoices.keysValuesDo({ arg note, syn;
                  if (syn.isRunning == true, {
                  syn.set(key.asSymbol, val);
                  });
               });
            }
         );
      });
   }

   free {
      harvestBus.free;
      harvestFx.free;
      harvestDrone.free;
      harvestVoices.keysValuesDo({ arg key, value; value.free; });
   }
}
