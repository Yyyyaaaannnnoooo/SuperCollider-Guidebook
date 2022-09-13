s.boot;
s.quit;
// load all audio files in Path to keyed collection
(
var path, subfolders;
b = ();
path = PathName(thisProcess.nowExecutingPath).parentPath;
subfolders = PathName(path ++ "audio/").entries;
subfolders.do({
	arg dir;
	var buf_array;
	buf_array = dir.entries.collect({
		arg file;
		Buffer.readChannel(s, file.fullPath, channels: [0, 1]);
	});
	b[dir.folderName.asSymbol] = buf_array;
});
)

b.size;

b[\breaks][0].play;

(
SynthDef.new(\supasaw, {
	arg freq=440, out=0, gate=1, offset=2, amp=0.1, lpf=3000;
	var sig, env;
	// build the envelope
	env = EnvGen.ar(
		Env.new(
			[0, 1, 0.25, 0],
			[0.25, 0.5, 1],
			-2,
			2
		),
		gate,
		doneAction: 2
	);

	sig = VarSaw.ar(
    freq: [ freq-7, freq-2, freq, freq+2, freq+7],
    iphase: {Rand(0.0, 1.0)}!8,
    width: {ExpRand(0.001, 0.02)}!8
  );

	sig = Splay.ar(sig) * 0.5;
  sig = RLPF.ar(sig, lpf.clip(20, 20000), 1);
	sig = Balance2.ar(sig[0], sig[1], 0, amp)  * env;
	Out.ar(out, sig);
}).add
)


(
SynthDef.new(\reverb,{
  arg in=0, mix=0.4, out=0;
  var sig, wet;
  sig = In.ar(in, 2); // reads from the audio bus
  sig = FreeVerb2.ar(
    sig[0], sig[1],
    mix: mix.clip(0.0, 1.0), room: 0.999, damp: 0.85
  );
  Out.ar(out, sig)
}).add;
s.newBusAllocators;
~bus = Bus.audio(s, 2);
)

~reverb = Synth.new(\reverb, [\in, ~bus]);

x = Synth.new(\supasaw, [\freq, 110, \lpf, 2000])
x.set(\lpf, 1000)
x.set(\lpf, 10000)
x.set(\gate, 0)


// create a clock in sc
// sc tempo is in seconds, therefore divide by 60
t = TempoClock.new(185/60);
// make a clock that survives `cmd + .`
t = TempoClock.new(185/60).permanent_(true);
t.beats;
// set clock dynamically
t.tempo_(185/60);
// basic sequencer
(
 p = Pbind(
   \instrument, \supasaw,
   \dur, 1,
   \amp, 0.2,
   \freq, Pseq([200, 100, 300], inf)
 );
~seq = p.play(t);
)

~seq.stop;
~seq.resume;


s.quit;

