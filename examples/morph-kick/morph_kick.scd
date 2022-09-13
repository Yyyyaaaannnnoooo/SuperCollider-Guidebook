s.quit;
s.boot;



(
SynthDef.new(\kmorph,{
  arg
  morph=0.75, // adjust amout of noise 0 => 1
  clipamt=1, // second distortion stage
  depth=170, // pitch envelope depth
  freq=20,
  sweep=0,
  amp=0.25,
  record=0,
  buf=3,
  rel=1, t_trig=1, out=0;
  var sig, env, p_env, n_env, recordbuf,
  path, filename, folderexists, recording,
  routine, noise, dist, clip, submix, wrap;

  wrap = 1-morph;
  wrap = wrap.clip(0.001, 1);
  clipamt = 1-clipamt;
  clipamt = clipamt.clip(0.001, 1);

  env = EnvGen.ar(
    Env.perc(0.001, rel, 1, -4),
    gate: t_trig,
    doneAction: 2,
  );
  p_env = EnvGen.ar(
    Env.perc(0.001, rel + sweep, depth, -16),
    gate: t_trig,
    doneAction: 2,
  );
  n_env = EnvGen.ar(
    Env.perc(0.05, 0.75, 1, -4),
    gate: t_trig,
    doneAction: 2,
  );
  noise = WhiteNoise.ar([morph]!2) * n_env;
  noise = PitchShift.ar(noise, 0.002, wrap, 0.0, 0.0);
  dist = Clip.ar(noise, 0-wrap, wrap) * 1/wrap;
  sig = SinOsc.ar([freq+p_env]!2);
  submix = Mix.ar([sig, dist]);
  clip = Fold.ar(submix, 0-clipamt, clipamt) * 1/clipamt;
  clip = Wrap.ar(submix, 0-clipamt, clipamt) * 1/clipamt;
  clip = Clip.ar(submix, 0-clipamt, clipamt) * 1/clipamt;
  sig = Mix.ar([sig, clip]);
  sig = sig * amp * env;


  Out.ar(out, sig);
 /* // here we sample the sound
  // create a buffer the size of our percussive sound
  recordbuf = Buffer.alloc(s, s.sampleRate * 4, 2);
  // record signal into buffer
  recording = RecordBuf.ar(sig, recordbuf);

  routine = Routine({
    4.wait;
    path = PathName(thisProcess.nowExecutingPath).parentPath ++ "recordings/";
    folderexists = File.mkdir(path);
    filename = path ++ "output.aiff";
    filename.postln;
    recordbuf.write(filename, headerFormat: "aiff", sampleFormat: "int16");
    recordbuf.close;
    recordbuf.free;
  });
  if(
    env.value <= 0,
    {routine.play;}
  );*/
}).add
)


(
x = Synth.new(\kmorph, [
  \morph, 0.2,
  \clipamt, 1,
  \sweep, 0.5,
  \freq, 40,
  \depth, 170,
  \rel, 1.5
]);

)

x.free;

// create a clock in sc
// sc tempo is in seconds, therefore divide by 60
t = TempoClock.new(185/60);
// make a clock that survives `cmd + .`
t = TempoClock.new(185/60).permanent_(true);
t.beats;
// set clock dynamically
t.tempo_(127/60);
// basic sequencer
(
~seq.stop;
p = Pbind(
  \instrument, \kmorph,
  \dur, Pwrand([1, 0.5, 0.25], [0.9, 0.05, 0.05], inf),
  \morph, Pxrand([1, 5, 7, 13].normalizeSum, inf),
  \clipamt, Pxrand([1, 5, 7, 13].normalizeSum, inf),
  \sweep, 0.5,
  \freq, 40,
  \depth, 170,
  \rel, 0.75
);
~seq = p.play(t, quant: 4); // very important: quantization and pattern syncing!
)

~seq.stop;

[1, 5, 7, 13].normalizeSum
