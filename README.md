# SuperCollider Guidebook

[toc]

### Basic Commands

```
// Auto complete brackets, and other stuff
preferences => Behavior => Auto insert Matching...
// evaluate line or region of code within
// (
// some code here
// )
cmd + enter

// evaluate single line of code

cmd + ?????

// quit everything
cmd + .

// get help in the help browser
cmd + d (with cursor over a function)
```

### Server commands

```supercollider
// start the server
s.boot;
// quit the server
s.quit;
// free all the nodes on the server, remove sound without quitting the server
s.freeAll;
// show the meter
s.meter
```

### Variables

```
// SuperCollider is not typed, any variable can be anything
// similar behavior can be find in languages like JavaScript
// and Python 🐍
// scoped variables. to use within functions without exiting
// parenthesis region
var osc = SinOsc.ar(440)
// arguments for functions
arg value
// global variables
~osc = SinOsc.ar(440)
// [a => z] are global variables available, that do not
//require initialization by prepending var. Exeption is made
//for the global variable s that is reserved for server actions
```

### Conditional Logic

```
// follows the same logic as other programming languages
1 == 1 // true 
1 > 0  // false
1 < 2  // true
1 >= 2 // false
1 <= 1 // true

if statement syntax

(
if(
		[0, 1].choose == 0, // statement to evaluate
		{"0 was chosen".postln;}, // if true do this
		{"1 was chosen".postln;}	// if false do this
	);
)

```

### Loops

```
// for loop
for (
  3, 
	7, 
	{ arg i; i.postln }
); // prints values 3 through 7

// do loop [maybe better suited for musical stuff]
// assumes you know how to build an array
[
note_val_1,
note_val_2,
note_val_3,
note_val_4,
note_val_5,
note_val_6,
].do(
	{
		arg item, index;
		// do something with item and index
	}
)
```

### Functions

```
~function = {
	arg freq
	{SinOsc.ar(freq)}.play;
}

~function.value(440)


```

### Arrays aka Collection

```
[
  your,
  items,
  go,
  here
].size // returns length
// arrays shortcut that are useful later for making sound
// fill array with same item
7.dup(2) // [7, 7]
7!5 // [7, 7, 7, 7, 7]
// make an array of n items in sequence
~myarr = (1..100)


```

### Randomness

```
// return random value between two numbers
rrand(-10, 30)
// to include floats
rrand(0.5, 20)
// exponential distribution of randomness towards the
// lower value in the function to be used with frequency and 
// amplitude. It always returns floats!
exprand(10, 30) 
```

### Making Sound

```
// very basic
(
~firstsound = {
	arg freq;
	SinOsc.ar(freq, 0, 0.2, 0);
};
)
// play sound
x = ~firstsound.play(args: [\freq, 400]);
// set frequencies
x.set(\freq, 300);
x.set(\freq, 200);
x.free;
```

### SynthDef

```
(
SynthDef.new(\saw, {
	arg freq=200, amp=0.2, gate=1, out=0;
	var sig, env;
	
	// here we build the envelope
	env = EnvGen.ar(
		Env.new(
			[], // < = amplitudes at various stages values between 0 = > 1
			[], // < = duration of the stages in seconds amplitudes.zizes - 1
			[] // < = shape of the curves values between - infinity = > + infinity but \lin || \exp will also work or a single +- integer
			gate,
			doneAction: 2
		).plot // shows the envelope
	)
	
	sig = saw.ar(freq);
	sig = sig * amp;
	sig = sig * env;
	Out.ar(out, sig) // < = mono
	}).add; // < = very important 
)
```

### Envelopes

```
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
```

### Sequencing

```
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
   \dur, 1, // patterns speed
   \amp, 0.2,
   \freq, Pseq([200, 100, 300], inf)
 );
~seq = p.play(t);
~seq = p.play(t, quant: 4); // very important: quantization and pattern syncing!
)

~seq.stop;
~seq.resume;
```

### Basic Sample Slicer

```
SynthDef.new(\slicer, {
  arg t_trig=1, buf=0, amp=0.5, slice=0, rate=1, out=0, fold_amt=0.15, clip_amt=0.15;
  var sig, env, clip, fold, frames, start, duration, sustain;
  rate = BufRateScale.ir(buf) * rate;
  frames = BufFrames.kr(buf);
  duration = frames / 32;
  start = slice * duration;
  sig = PlayBuf.ar(2, buf, rate, startPos: start, loop: 0);
  sustain = duration/rate/s.sampleRate;
  env=EnvGen.ar(
    Env.new(
      levels: [0,1,1,0],
      times: [0,sustain-0.01,0.01],
      curve:\sine,
    ),
    gate: t_trig,
    doneAction: 2;
  );
  fold = Fold.ar(sig, 0.0, fold_amt);
  clip = Clip.ar(sig, 0.0, clip_amt);
  sig = Mix.ar([sig * amp, clip, fold]);
  sig = sig * amp * env;
  Out.ar(out, sig);
}).add;
```

### Advanced Sample Slicer

```
SynthDef.new(\slicer, {
  arg t_trig=1, buf=0, amp=0.5,
  slice=0, num_slices=1, rel=0.05, loops=1,
  rate=1, out=0, fold_amt=0.15, clip_amt=0.15;

  var sig, env, pos, clip, fold, frames, start, end, duration, sustain, pos_rate;

  pos_rate = BufRateScale.ir(buf) * rate;
  frames = BufFrames.kr(buf);
  duration = (frames / 32) * num_slices;
  start = slice * duration;
  end = start + duration;

  sustain = (duration / rate.abs / BufSampleRate.ir(buf)) * loops;
  env = EnvGen.ar(
    Env.new(
      levels: [0,1,1,0],
      times: [0, sustain - rel, rel],
      curve: \lin
    ),
    gate: t_trig,
    doneAction: 2,
  );
  // phasor
  pos = Phasor.ar(
    trig: t_trig,
    rate: pos_rate,
    start:   (((rate>0)*start)+((rate<0)*end)),
    end:     (((rate>0)*end)+((rate<0)*start)),
    resetPos:(((rate>0)*start)+((rate<0)*end))
  );

  sig = BufRd.ar(
    numChannels: 2,bufnum: buf, phase: pos, loop: 0, interpolation: 4
  );

  fold = Fold.ar(sig, 0.0, fold_amt);
  clip = Clip.ar(sig, 0.0, clip_amt);
  sig = Mix.ar([sig * amp, clip, fold]);
  sig = sig * amp * env;
  Out.ar(out, sig);
}).add;
```



### [Access values of Pbind](https://youtu.be/NGa2XeOoBpM?t=1706)

### FX send inside SynthDef

```
// assign busses for FX
~fx0 = Bus.audio(s, 2);
~fx1 = Bus.audio(s, 2);
~fxn = Bus.audio(s, 2);

(
SynthDef.new(\saw_send, {
	arg out=0, t_trig=1, freq=220, amp=0.5, fx0_mix=0.0, fx1_mix=0.0, fxn_mix=0.0;
	var sig, env, detune;
	detune = LFNoise1.kr(0.2!8).bipolar(0.2).midiratio;
	env = EnvGen.ar(Env.Perc(0.05, 1.0, 1.0, -2), t_trig, doneAction: 2);
	sig = Saw.ar(freq * detune);
	sig = Splay.ar(sig) * 0.5;
	sig = sig * env;
	Out.ar(out, sig);
	// send channels
	Out(~fx0, sig * fx0_mix);
	Out(~fx1, sig * fx1_mix);
	Out(~fxn, sig * fxn_mix);
	}).add
)
```

### Prepping for Live Events

```
// Create a init file for all the synths, fx and busses

(
s.wait
)
```


### TO DO
- add description to examples
- in `examples/sample-slicer/better_slicer.scd` revert to version with Clip.ar and Fold.ar for distortion to prevent errors if quarks are not compiled
- Build akai style realtime stretch ✅
- reverse time stretch needs improvement
- Control Busses
- Midi connection