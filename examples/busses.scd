s.boot;
s.meter;

//create groups to make proper audio routing
// so that fx are alwasys after audio source
(
~audio_sources = Group.new();
~fx_group = Group.new(~audio_sources, \addAfter);

// assign busses for FX
~reverb = Bus.audio(s, 2);

)
// create reverb FX
(
SynthDef.new(\reverb, {
  arg in=0, mix=0.4, out=0;
  var sig, wet;
  sig = In.ar(in, 2); // reads from the audio bus
  sig = FreeVerb2.ar(
    sig[0], sig[1],
    mix: mix.clip(0.0, 1.0), room: 0.999, damp: 0.85
  );
  Out.ar(out, sig)
}).add;
)

Synth.new(\reverb, [\in, ~reverb], target: ~fx_group)
~fx_group.freeAll;

(
SynthDef.new(\supasaw, {
	arg freq=440, out=0, gate=1, offset=2, amp=0.5, lpf=3000, atk=2.5, rel=1;
	var sig, env;
	// build the envelope
	env = EnvGen.ar(
		Env.new(
			[0, 1, 0.75, 0],
			[atk, 0.5, rel],
			-2,
		),
    gate,
		doneAction: 2,
	);

	sig = VarSaw.ar(
    freq: [ freq-11, freq-3, freq, freq+3, freq+5, freq+7, freq+9, freq+11],
    iphase: {Rand(0.0, 1.0)}!8,
    width: {ExpRand(0.001, 0.02)}!8
  );

	sig = Splay.ar(sig) * 0.5;
  sig = RLPF.ar(sig, lpf.clip(20, 20000), 1);
	sig = Balance2.ar(sig[0], sig[1], 0, amp)  * env;
	Out.ar(out, sig);
}).add;


)

(
Synth.new(\supasaw, [\freq, exprand(100, 660), \out, ~reverb], target: ~audio_sources)
)
