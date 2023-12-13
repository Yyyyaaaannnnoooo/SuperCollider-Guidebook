s.boot;
ServerOptions.outDevices;
Server.default.options.outDevice_("AudioBox USB 96");

(
SynthDef.new(\reese, {
  arg freq=40, gate=1, out=0, amp=0.5,
  atk=0.05, rel=1, lpf=1000;
  var sig, detune, env, vcf_lfo, lfo_mod;

  env = EnvGen.kr(Env.asr(atk, 1, rel), gate, doneAction:2);

  detune = LFNoise1.kr(0.2!8).bipolar(0.2).midiratio;
  sig = VarSaw.ar(freq:freq*detune,iphase:{Rand(0.0, 1.0)}!8,width:{ExpRand(0.001,0.02)}!8);
  sig = Splay.ar(sig) * amp;

  lfo_mod = SinOsc.kr(0.8).range(0.005, 0.025);
  vcf_lfo = SinOsc.kr(lfo_mod, phase:1).range(250, lpf);

  sig = RLPF.ar(sig, vcf_lfo.clip(20, 20000), 1);
  Out.ar(out, sig);
}).add
)

(
~reese = Synth.new(\reese);

)

~reese.set(\gate, 0);
~reese.set(\lpf, 900);
~reese.set(\freq, 40);

(
SynthDef.new(\ptr, {
  arg out=0, buf=0, rate=1;
  var sig;
  sig = Phasor.ar(0, BufRateScale.kr(buf) * rate, 0, BufFrames.kr(buf));
  Out.ar(out, sig)
}).add
)

(
SynthDef.new(\rec, {
  arg ptr_in=0, audio_in=0, buf=0;
  var ptr, sig;
  ptr = In.ar(ptr_in, 1);
  sig = In.ar(audio_in, 1);
  BufWr(sig, buf, ptr);
}).add
)

(
SynthDef.new(\grain, {
  arg amp=0.5, buf=0, out=0,
  atk=1, rel=1, gate=1,
  sync=1, dens=40,
  base_dur=0.05, dur_rand=1,
  rate=1, rate_rand=1,
  pan=0, pan_rand=0,
  grain_env=(-1), ptr_bus=0, ptr_sample_delay=20000,//ptr = pointer inside the buffer
  ptr_rand_samples=5000, min_ptr_delay=1000;

  var sig, env, dens_ctrl, dur_ctrl, rate_ctrl, pan_ctrl, ptr, curr_ptr, ptr_rand, tot_delay, max_grain_dur;

  //grain buf envelope
  env = EnvGen.kr(Env.asr(atk, 1, rel), gate, doneAction:2);
  // density of the grains,
  dens_ctrl = Select.ar(sync, [Dust.ar(dens), Impulse.ar(dens)]);
  // duration control
  dur_ctrl = base_dur * LFNoise1.ar(100).exprange(1/dur_rand, dur_rand);
  // rate control
  rate_ctrl = rate * LFNoise1.ar(100).exprange(1/rate_rand, rate_rand);
  //pan control
  pan_ctrl = pan + LFNoise1.kr(100).bipolar(pan_rand);

  ptr_rand = LFNoise1.ar(100).bipolar(ptr_rand_samples);
  curr_ptr = ptr_sample_delay - ptr_rand;
  tot_delay = max(curr_ptr, min_ptr_delay);

  ptr = In.ar(ptr_bus);
  ptr = ptr - tot_delay;
  ptr = ptr / BufFrames.kr(buf);

  max_grain_dur = (tot_delay / rate_ctrl) / SampleRate.ir;
  dur_ctrl = min(dur_ctrl, max_grain_dur);

  sig = GrainBuf.ar(
    numChannels: 2,
    trigger: dens_ctrl,
    dur: dur_ctrl,
    sndbuf: buf,
    rate: rate_ctrl,
    pos: ptr,
    interp: 2,
    pan: pan_ctrl,
    envbufnum: grain_env
  );

  sig = sig * env * amp;
  Out.ar(out, sig);j
}).add
)