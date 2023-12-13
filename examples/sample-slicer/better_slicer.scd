/*
* some source can be found here
* https://schollz.com/blog/sampler/
*/

s.boot;
s.quit;
(
// load all audio files in Path to keyed collection
// from Eli Fieldsteel

var path, subfolders;
b = ();
path = PathName(thisProcess.nowExecutingPath).parentPath;
path.postln;
subfolders = PathName(path ++ "audio/").entries;
subfolders.do({
  arg dir;
  var buf_array;
  buf_array = dir.entries.collect({
    arg file;
    Buffer.readChannel(s, file.fullPath, channels: [0, 1]);
  });
  b[dir.folderName.asSymbol] = buf_array;
});


~breaks = b[\breaks];
)

(
SynthDef.new(\slicer, {
  arg t_trig=1,buf=0,amp=0.5, lpf=17000, fold_amt=0.15,clip_amt=0.15, out=0,
  slice=0, num_slices=1, slices=32,
  rel=0,atk=0, sus=1,loops=1,rate=1,pitch=1,bars=4,beat=1,do_stretch=1,grain=5;
  var sig, env, pos_env, pos, clip, fold, frames, start, end, start_pos, end_pos, duration,
  sustain, pos_rate, micro_pos, micro_dur,tot_duration, sample_duration, stretch=1, llist, index = 0, phase;
  tot_duration = beat * 4 * bars;
  sample_duration = BufDur.kr(buf);
  stretch = 1 / (tot_duration / sample_duration);
  llist = [stretch, 1];
  stretch = (((do_stretch>=1) * stretch) + ((do_stretch<1)*1));
  // stretch = ((stretch<=1) * stretch)
  stretch.poll;
  // beat.poll;
  pos_rate = (BufRateScale.ir(buf) * rate) * stretch;
  frames = BufFrames.kr(buf);
  duration = (frames / slices) * num_slices;
  start = slice * duration;
  end = start + duration;

  sustain = (duration / (rate.abs * stretch) / BufSampleRate.ir(buf)) * loops;

  // NEEDS BETTER ENVELOPE

  env = EnvGen.ar(
    Env.new([0,1,1,0],[atk, sustain * sus, rel],\lin),
    gate: t_trig,
    doneAction: 2,
  );
  pos_env = EnvGen.ar(
    Env.new([0,1,1,0],[0, sustain, 0],\lin),
    gate: t_trig,
    doneAction: 2,
  );
  start_pos = (((rate>0)*start)+((rate<0)*end));
  end_pos = (((rate>0)*end)+((rate<0)*start));
  pos = Phasor.ar(t_trig,pos_rate,start_pos,end_pos,start);
  // timestretch withouth Pitch shift
  micro_dur = duration / grain;
  micro_dur = (((rate>0) * micro_dur)-((rate<0)* micro_dur));
  micro_pos = Phasor.ar(t_trig, pitch.abs, pos, pos + micro_dur, start);
  micro_pos = micro_pos * pos_env;
  sig = BufRd.ar(numChannels: 2, bufnum: buf, phase: micro_pos, loop: 0, interpolation: 4);
  sig = RLPF.ar(sig, lpf.clip(25, 19500), 0.5);
  fold_amt = 1-fold_amt;
  fold_amt = fold_amt.clip(0.001, 1);
  clip_amt = 1-clip_amt;
  clip_amt = clip_amt.clip(0.001, 1);
  fold = Fold.ar(sig, 0-fold_amt, fold_amt) * 1/fold_amt;
  clip = Clip.ar(sig, 0-clip_amt, clip_amt) * 1/clip_amt;
  sig = Mix.ar([sig, fold, clip]);
  sig = (sig * 1).tanh;
  sig = (sig * 1).atan;
  sig = sig.clip(-1, 1);
  sig = sig * amp * env;
  Out.ar(out, sig);
}).add;
)





t = TempoClock.new(185/60);
(
~sl = Synth(\slicer, [
  \buf, ~breaks[3],
  \num_slices, 1,
  \beat, t.beatDur,
  \rate, 0.1,
  \grain, 5,
  \pitch, 1
]);


)


// create a clock in sc
// sc tempo is in seconds, therefore divide by 60
t = TempoClock.new(185/60);
// make a clock that survives `cmd + .`
t = TempoClock.new(185/60).permanent_(true);
t.beats;
t.bar;
(t.beatDur * 4) * 127/60;
t.tempo_(203/60);
// basic sequencer
(
t.tempo_(203/60);
Pdef(\p, Pbind(
  \instrument, \slicer,
  // \group, ~synths,
  \dur, Prand([0.5].lace(100)++[1, 1, 2, 2, 3, 3], inf),
  \beat, t.beatDur,
  // \bars, 16,
  \rate, 1,
  \rate, Pfunc({
    arg ev;
    var return;
    if(
      ev[\dur] < 1 ,
      {return = 1},
      {return = (-1/(2 * ev[\dur].abs))}
    );
  }
  ),
  // \grain, 10,
  \fold_amt, 0,
  \clip_amt, 0,
  \grain, Prand((5..10), inf),
  \buf, Prand([~breaks[3]], inf),
  // \lpf, Pseq([Env([3000, 17000, 8000], [50,10], \sine).asPseg], inf),
  \loops, 1,
  \slices, 32,
  // \slice, Pseq((0..7) + [Pwhite.new(0,2)] + 0 , inf),
  \slice,Pxrand(
    [
      // Pwrand((0..31), (0..7).lace(32).reverse.normalizeSum, 1),
      Pseq((16..31)),
      Pseq((24..31)),
      Pseq((0..7).lace(3)),
      Pseq((8..23)),
      Pseq((17..21).lace(12)),
      Pseq((0..3).lace(12)),
      Pseq((1..3).lace(9)),
    ]
    , inf),
  \amp, -10.dbamp,
  \atk, 0.009,
  // \out, ~delay_bus,
)
)
)


Pdef(\p).quant_(4);
Pdef(\p).fadeTime = 1.0;
Pdef(\p).play(t, doReset:false);
Pdef(\p).stop;

// set clock dynamically
(
t.tempo_(30/60);

Pdef(\p).set(\beat, t.beatDur)
)

s.freeAll;



(

SynthDef.new(\slicer, {
  arg t_trig=1,buf=0,amp=0.5, lpf=17000, fold_amt=0.15,clip_amt=0.15, out=0,
  slice=0, num_slices=1, slices=32,
  rel=0,atk=0, sus=1,loops=1,rate=1,pitch=1,bars=4,beat=1,do_stretch=1,grain=5;
  var sig, env, pos_env, pos, clip, fold, frames, start, end, start_pos, end_pos, duration,
  sustain, pos_rate, micro_pos, micro_dur,tot_duration, sample_duration, stretch=1, llist, index = 0, phase;
  tot_duration = beat * 4 * bars;
  sample_duration = BufDur.kr(buf);
  stretch = 1 / (tot_duration / sample_duration);
  llist = [stretch, 1];
  stretch = (((do_stretch>=1) * stretch) + ((do_stretch<1)*1));
  pos_rate = (BufRateScale.ir(buf) * rate) * stretch;
  frames = BufFrames.kr(buf);
  duration = (frames / slices) * num_slices;
  start = slice * duration;
  end = start + duration;

  sustain = (duration / rate.abs / BufSampleRate.ir(buf)) * loops;

  // NEEDS BETTER ENVELOPE

  env = EnvGen.ar(
    Env.new([0,1,1,0],[atk, sustain * sus, rel],\lin),
    gate: t_trig,
    doneAction: 2,
  );
  pos_env = EnvGen.ar(
    Env.new([0,1,1,0],[0, sustain, 0],\lin),
    gate: t_trig,
    doneAction: 2,
  );
  start_pos = (((rate>0)*start)+((rate<0)*end));
  end_pos = (((rate>0)*end)+((rate<0)*start));
  pos = Phasor.ar(t_trig,pos_rate,start_pos,end_pos,start);
  // timestretch withouth Pitch shift
  micro_dur = duration / grain;
  micro_dur = (((rate>0) * micro_dur)-((rate<0)* micro_dur));
  micro_pos = Phasor.ar(t_trig, pitch.abs, pos, pos + micro_dur, start);
  micro_pos = micro_pos * pos_env;
  sig = BufRd.ar(numChannels: 2, bufnum: buf, phase: micro_pos, loop: 0, interpolation: 4);
  sig = RLPF.ar(sig, lpf.clip(25, 19500), 0.5);
  fold_amt = 1-fold_amt;
  fold_amt = fold_amt.clip(0.001, 1);
  clip_amt = 1-clip_amt;
  clip_amt = clip_amt.clip(0.001, 1);
  fold = Fold.ar(sig, 0-fold_amt, fold_amt) * 1/fold_amt;
  clip = Clip.ar(sig, 0-clip_amt, clip_amt) * 1/clip_amt;
  sig = Mix.ar([sig, fold, clip]);
  sig = sig * amp * env;
  Out.ar(out, sig);
}).add;

)