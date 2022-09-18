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
  arg t_trig=1, 
  buf=0,        // ample to play
  amp=0.5,      // volume control
  slice=0,      // the slice number to play
  num_slices=1, // number of slices to playback [similar to octatrack]
  slices=32,    // number of slices to cut the sample
  rel=0.05,     // release
  loops=1,      // how many times does the loop speed up
  rate=1,       // playback speed
  out=0,        //where does the signal flow out to 
  fold_amt=0.15,
  clip_amt=0.15,
  bars=4,       // time in bars of original sample
  beat=1;       // beat givent by TempoClock.beatDur
  var sig, env, pos, clip, fold, frames, start, end, duration,
  sustain, pos_rate, tot_duration, sample_duration, stretch=1;
  tot_duration = beat * 4 * bars;

  sample_duration = BufDur.kr(buf);

  stretch = 1 / (tot_duration / sample_duration);

  pos_rate = (BufRateScale.ir(buf) * rate) * stretch;
  frames = BufFrames.kr(buf);
  duration = (frames / slices) * num_slices;
  start = slice * duration;
  end = start + duration;
  sustain = (duration / rate.abs / BufSampleRate.ir(buf)) * loops;
  env = EnvGen.ar(
    Env.new(levels: [0,1,1,0],times: [0, sustain - rel, rel],curve: \lin),
    gate: t_trig,
    doneAction: 2,
  );
  // phasor
  start = (((rate>0)*start)+((rate<0)*end));
  end= (((rate>0)*end)+((rate<0)*start));
  pos = Phasor.ar(t_trig,pos_rate,start,end,start);
  sig = BufRd.ar(numChannels: 2, bufnum: buf, phase: pos, loop: 0, interpolation: 4);
  fold = CrossoverDistortion.ar(sig, fold_amt, smooth: clip_amt);
  sig = Mix.ar([sig * amp, fold]);
  sig = sig * amp * env;
  Out.ar(out, sig);
}).add;
)


// create a clock in sc
// sc tempo is in seconds, therefore divide by 60
t = TempoClock.new(185/60);
// make a clock that survives `cmd + .`
t = TempoClock.new(185/60).permanent_(true);
t.beats;
t.bar;
(t.beatDur * 4) * 127/60;
t.tempo_(130/60);
// basic sequencer
(
t.tempo_(185/60);
Pdef(\p, Pbind(
  \instrument, \slicer,
  // \dur, Pseq([Pshuf([0.5,0.5,0.5,0.5,0.5,0.25, Rest(0.25)], 1)], inf),
  \dur, 0.5,
  \clip_amt, 0,
  \fold_amt, 0,
  \rate , 8,
  \beat, t.beatDur,
  \loops, 10,
  // \rate, Prand([1, 1, 1, 2, -1, -1, -2, 0.5, -0.25, 4, 6, 8], inf),
  /* \rate, Pseq(
  [Pxrand([1, 2, 4, 1.5, 1, 2, 1, 1, 1, 0.5, 2, 0.1, -1, -2, -0.5], 1)],
  inf),*/
  /*\loops, Pfunc({
    arg ev;
    var return;
    if(
      ev[\rate] < 1 ,
      {return = 1},
      {return = ev[\rate].abs}
    );
  }
  ),*/
  \buf, Pseq([Pshuf([~breaks[3]], 1)] , inf),
  \slice,Pxrand(
    [
      Pwrand((0..31), (0..7).lace(32).reverse.normalizeSum, 1),
      Pseq((16..31)),
      Pseq((24..31)),
      Pseq((0..7)),
      Pseq((8..23)),
      Pseq((8..23)),
      Pseq((8..23)),
      Pseq((8..23)),
      Pseq((24..31)),
      Pseq((24..31)),
      Pseq((1..3).lace(9)),
    ]
    , inf)
);
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





