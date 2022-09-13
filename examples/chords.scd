s.boot;
s.quit;

(
SynthDef.new(\chord, {
	arg freq=440, out=0, gate=1, offset=2, amp=0.1, lpf=3000;
	var sig, env, midis=[-11, 3, 5, 23].collect({
		arg item;
		freq.cpsmidi + item};
	);
	// build the envelope
	env = EnvGen.ar(
		Env.new(
			[0, 1, 0.75, 0],
			[0.25, 0.5, 1],
			-2,
			2
		),
		gate,
		doneAction: 2
	);

	sig = midis.collect({
		arg f, index;
		var saw;
		saw = Saw.ar(f!2);
	});

	sig = Mix.new(sig);
	sig = RLPF.ar(sig, lpf, 1);
	sig = sig * amp;
	sig = sig * env;
	Out.ar(out, sig);
}).add
)

x = Synth.new(\chord, [\freq, 440])
x.set(\amp, 0.5);
x.set(\lpf, 2000);
x.set(\gate, 0);




