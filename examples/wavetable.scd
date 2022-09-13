s.boot;
s.quit;

// BUILD WAVES
(
var num_seg = rrand(6, 35);
~wt = [
  Signal.sineFill(size: 1024, amplitudes: ({rrand(0.01, 1.0)}!8).scramble).asWavetable,
  Signal.chebyFill(size: 1024, amplitudes: ({rrand(0.01, 1.0)}!8).scramble).asWavetable,
  Env(
    [0]++
    (({rrand(0.0, 1.0)}!(num_seg-1))* [1, -1]).scramble
    ++[0],
    {exprand(1, 20)}!num_seg,
    {rrand(-20, 20)}!num_seg
  ).asSignal(1024).asWavetable,
  Env(
    [0]++
    (({rrand(0.0, 1.0)}!(num_seg-1))* [1, -1]).scramble
    ++[0],
    {exprand(1, 20)}!num_seg,
    {rrand(-20, 20)}!num_seg
  ).asSignal(1024).asWavetable,
  Env(
    [0]++
    (({rrand(0.0, 1.0)}!(num_seg-1))* [1, -1]).scramble
    ++[0],
    {exprand(1, 20)}!num_seg,
    {rrand(-20, 20)}!num_seg
  ).asSignal(1024).asWavetable,
  Signal.sineFill(size: 1024, amplitudes: ({rrand(0.01, 1.0)}!8).scramble).asWavetable,
  ]
)

~buf = Buffer.allocConsecutive(~wt.size, s, 2048);

(
~buf.do({
  arg buf, i;
  buf.loadCollection(~wt[i]);
});
)

~wt.do({arg n, i; n.plot(~buf[i].bufnum.asString); })

(
SynthDef.new(\vosc, {
  arg out=0, amp=0.5, buf=0, num_bufs=2, freq=80, lpf=20000;
  var sig, bufpos, detune, mod, lpf_mod;
  detune = LFNoise1.kr(0.2!8).bipolar(0.2).midiratio;

  // bufpos = buf + LFNoise1.kr(0.05).range(0, num_bufs - 1);
  mod = SinOsc.ar(0.025).range(0.5, 0.005);
  bufpos = buf + SinOsc.kr(mod).range(0.001, num_bufs - 1.01);
  sig = VOsc.ar(bufpos, freq * detune);
  sig = Splay.ar(sig);
  lpf_mod = SinOsc.ar(0.025).range(600, 15000);
  sig = RLPF.ar(sig, lpf_mod.clip(2, 20000), 1.0);
  sig = LeakDC.ar(sig) * amp;
  Out.ar(out, sig);
}).add;
)

(
x = Synth.new(\vosc, [
  \buf, ~buf[0].bufnum, \num_bufs, ~wt.size
]);
)
x.set(\freq, 80);
x.free;

s.meter;




