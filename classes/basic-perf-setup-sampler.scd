(
// Server.default.options.outDevice_("VB-Cable");
~path = PathName(thisProcess.nowExecutingPath).parentPath;
s.waitForBoot({
  ///~~~ LOAD SAMPLES IN BUFFERS ~~~///
  ///~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~///
  var subfolders;
  b = ();
  ~path.postln;
  "loading Samples...".postln;

  subfolders = PathName(~path ++ "audio/").entries;

  subfolders.do({
    arg dir;
    var buf_array;
    buf_array = dir.entries.collect({
      arg file;
      Buffer.readChannel(s, file.fullPath, channels: [0, 1]);
    });
    b[dir.folderName.asSymbol] = buf_array;
  });

  ~sd = b[\sd];
  ~o = b[\o];
  ~ultra = b[\ultrcr];
  ~hrbg = b[\hrbig];
  ~mod = b[\modular];
  ~vox = b[\vox];

  "Samples Loaded".postln;
});

)

(
SynthDef.new(\sampler, {
  arg b, rate = 1, amp = 1, start = 0, lpf = 10000;
  var sig, duration, start_pos = 0;
  duration = BufDur.kr(b);
  duration = (BufFrames.kr(b) * 1) - 5;
  // duration.poll;
  start = ((rate >= 0) * start_pos) + ((rate < 0) * duration);
  // start.poll;
  // rate = ((rate == 0) * 1) + (((rate !== 0) * 1));
  rate = rate + 0.001;
  // rate.poll;
  sig = PlayBuf.ar(2, b, rate, trigger: 1, startPos: start, loop: 0.0, doneAction: 2);
  sig = RLPF.ar(sig, lpf.clip(20, 19500), 1.0);
  sig = sig * amp;
  Out.ar(0, sig);
}).add;
)

(
x = Synth.new(\sampler, [\b, ~hrbg[4], \rate, 1, \lpf, 12500])
)

t = TempoClock.new(185/60).permanent_(true);
// set clock dynamically
t.tempo_(145/60);

(
Pdef(\s1, Pbind(
  \instrument, \sampler,
  \dur, 0.5,
  \b, Prand(~hrbg[4].dup(3) ++ ~hrbg[0].dup(5) ++ ~hrbg[3].dup(4), inf),
  \rate, Pseq(Array.linrand(10, 1, 2).postln,inf)
));
)

(
Pdef(\s1).quant_(4);
Pdef(\s1).fadeTime = 1.0;
Pdef(\s1).play(t, doReset: false);
)

Pdef(\s1).stop;

Array.series(8, 0, 0.25).replace(0, Rest(0.5)).stutter(1).mirror().scramble().postln;
Array.series(4, 0, 0.5).replace(0, Rest(0.5)).lace(4 * 4).postln;
Array.interpolation(10, -1, 1.5).postln;

[1, 2, 3].powerset.postln

a = (0..10) ++ (0..10);
a.replace([4, 5, 6], 100);
a.replace([4, 5, 6], [1734, 1985, 1860]);

