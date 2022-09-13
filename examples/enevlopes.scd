s.boot;
(
// general purpose envelope
Env.new(
	[0, 1, 0.5, 0.5, 0],
	[0.25, 1, 2.5, 1],
	-2
).plot
)


(
// good for arps?
Env.linen(0.1, 0.001, 0.1, 0.6, -2).plot
)

(
// useful for percussions
Env.perc(0.01, 1.0, 1.0, -2).plot
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


s.quit;