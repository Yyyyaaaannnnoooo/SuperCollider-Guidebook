// general purpose envelope
(

SynthDef(\hoover, {
    var snd, freq, bw, delay, attack = 0.01, decay = 1.0;
    freq = \freq.kr(440);
    freq = freq * Env([-5, 6, 0], [0.1, 1.7], [\lin, -4]).kr.midiratio;
    bw = 1.035;
    snd = { DelayN.ar(Saw.ar(freq * ExpRand(bw, 1 / bw)) + Saw.ar(freq * 0.5 * ExpRand(bw, 1 / bw)), 0.01, Rand(0, 0.01)) }.dup(20);
    snd = (Splay.ar(snd) * 3).atan;
    snd = snd * Env.asr(attack, 1.0, decay).kr(0, \gate.kr(1));
    snd = FreeVerb2.ar(snd[0], snd[1], 0.3, 0.9);
    snd = snd * Env.asr(0, 1.0, decay, 6).kr(2, \gate.kr(1));
    Out.ar(\out.kr(0), snd * \amp.kr(0.1));
}).add;

)

(

SynthDef(\gabberkick, {
    var snd, freq, high, lfo;
    freq = \freq.kr(440) * (Env.perc(0.001, 0.08, curve: -1).ar * 48 * \bend.kr(1)).midiratio;
    snd = Saw.ar(freq);
    snd = (snd * 100).tanh + ((snd.sign - snd) * -8.dbamp);
    high = HPF.ar(snd, 300);
    lfo = SinOsc.ar(8, [0, 0.5pi]).range(0, 0.01);
    high = high.dup(2) + (DelayC.ar(high, 0.01, lfo) * -2.dbamp);
    snd = LPF.ar(snd, 100).dup(2) + high;
    snd = RLPF.ar(snd, 7000, 2);
    snd = BPeakEQ.ar(snd, \ffreq.kr(3000) * XLine.kr(1, 0.8, 0.3), 0.5, 15);
    snd = snd * Env.asr(0.001, 1, 0.05).ar(2, \gate.kr(1));
    Out.ar(\out.kr(0), snd * \amp.kr(0.1));
}).add;
)

(
SynthDef.new(\saw, {
	arg freq=200,  amp=0.2, gate=1, out=0;
	var sig, env;
	// build the envelope
	env = EnvGen.ar(
		Env.new(
			[0, 1, 0.5, 0], // amplitudes
			[0.25, 1, 1], // segment durations
			-2, // curve of the segment
			2 // segment to be sustained
		),
		gate,
		doneAction: 2
	);
	// build the sound source
	sig = Saw.ar([freq, freq + 2]);
	// attenuate the signal
	sig = sig * amp;
	// pass it trough the envelope
	sig = sig * env;
	Out.ar(out, sig);
}).add;
)

x = Synth.new(\saw);
x.set(\gate, 0);


// Sequencing

// create a clock in sc
// sc tempo is in seconds, therefore divide by 60
t = TempoClock.new(185/60);
// make a clock that survives `cmd + .`
t = TempoClock.new(185/60).permanent_(true);
t.beats;
// set clock dynamically
t.tempo_(145/60);
// basic sequencer


(
Pdef(\s1, Pbind(
  \instrument, \hoover,
  \dur, Prand([1, 2, 0.5], inf),
  \decay, 0.0125,
  \amp, -20.dbamp,
  \freq, Prand([220, 440, 40, 660], inf)
)
)
)



(
Pdef(\s1).quant_(4);
Pdef(\s1).fadeTime = 1.0;
Pdef(\s1).play(t, doReset: false);
)

Pdef(\s1).stop;


(
Pdef(\s2, Pbind(
  \instrument, \gabberkick,
  \dur, Prand(0.5.dup(16) ++ [1, 2, 0.5] ++ 0.25.dup(10), inf),
  // \decay, 0.0125,
  \amp, -10.dbamp,
  \freq, Prand([22, 48, 40, 60], inf)
)
)
)

(
Pdef(\s2).quant_(4);
Pdef(\s2).fadeTime = 1.0;
Pdef(\s2).play(t, doReset: false);
)

Pdef(\s2).stop
