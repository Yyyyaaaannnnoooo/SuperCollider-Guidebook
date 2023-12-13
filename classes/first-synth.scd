// cmd + enter Execute code within region

s.boot;

// a => z

"hello".postln;
[1, 2, 3].postln;

(

~sine = {
  SinOsc.ar([220, 320, 80, 120])
};

)

~sine.play;


// Oscillator
// Envelope

(
SynthDef.new("synth", {
  arg attack = 0.01, release = 1, amp = 0.5, freq = 220;
  // oscillator
  var sig, env;
  sig = LFSaw.ar([freq, freq + 10.midicps, freq + 2.midicps, freq - 5.midicps]);
  // envelope
  env = EnvGen.ar(Env.perc(attack, release, curve: -4), doneAction: 2);
  sig = sig * env * amp;
  Out.ar(0, sig!2);
}).add;
)

x = Synth.new("synth", ["attack", 1, "release", 5, "freq", 110, "amp", 0.5]);
x.set("gate", 0)
x.free;



Env.perc(curve: -2).plot;


Env.adsr().plot;

Env.new(
  [0, 1, 0.5, 0.5, 0],
  [0.25, 1, 2.5, 1],
  -2
).plot


