

(
// start the supercollider server
s.boot
)

// build a synth
(
SynthDef.new(\drone, {
	arg out = 0, amp = 0.5, gain = 10, freq = 80;
	var sig, lfo, lfo_mod, num_sines = 32;
	sig = SinOsc.ar(
		Array.exprand(num_sines, 0.1, 120.0) + freq.varlag(0.5),
		mul:num_sines.reciprocal);
	lfo_mod = SinOsc.kr(0.01).range(-0.5, 0.5);
	lfo = SinOsc.kr(lfo_mod).range(1, gain);
	// sig = sig * lfo;
	sig = (sig * gain).tanh;
	// sig = sig.tanh;
	sig = sig * amp;
	sig = Splay.ar(sig.scramble, 0.1);
	Out.ar(out, sig);
}).add;
)

// show the scope
s.scope


// play the synth
d = Synth(\drone)

// change parameters in the synth
d.set(\amp, -20.dbamp)
d.set(\gain, 10)
d.set(\freq, 160)

// free the synth
d.free


(
SynthDef.new(\noise, {
	arg speed=0.125, amp = 0.25;
	var sig, lfo;
	sig = PinkNoise.ar();
	lfo = SinOsc.kr([0.0125, 0.025, 0.05, 0.125] + speed.varlag(1)).range(80, 2000);
	sig = RLPF.ar(sig, lfo);
	sig = Splay.ar(sig.scramble, 1);
	sig = sig * amp;
	Out.ar(0,sig!2);
}).add
)

n = Synth(\noise)
n.set(\speed, 0.005)
n.set(\amp, -24.dbamp)
n.free


(
SynthDef.new(\droplets, {
	arg density = 10, amp = 0.25;
	var sig, trig, env, sh, noise, pan;

	trig = Dust.kr(density);
	env = Env.perc(0.01, 0.125).kr(doneAction:0, gate:trig);
	noise = LFNoise0.kr(500).range(120, 600);
	sh = Latch.kr(noise, trig);

	sig = PinkNoise.ar();
	sig = BPF.ar(sig, sh);

	sig = sig * amp;
	sig = sig * env;
	pan = sh.linlin(120, 600, -1, 1);
	sig = Pan2.ar(sig, pan);
	Out.ar(0, sig)
}).add
)

~droplet = Synth(\droplets)
~droplet.set(\density, 50)
~droplet.set(\amp, -6.dbamp)
~droplet.free

