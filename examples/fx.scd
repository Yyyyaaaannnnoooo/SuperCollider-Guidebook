s.boot;
//  TO DO
//  test FX and busses:

// PitchShiftPA

b = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01-44_1.aiff");
(
x.free;
x = {
    var in = PlayBuf.ar(1, b, BufRateScale.kr(b), loop: 1);
    PitchShiftPA.ar(
        in,
        50, //instead of tracking pitch, this controls the granulation speed; this might need to be raised to minimize artifacts when shifting up by more than 5
        1, //pitchRatio is not used and should be 1
        MouseY.kr(0.5, 2), //formantRatio becomes actual pitch ratio
        10, //minFreq may be lower if needed (this is the lowest value for the freq parameter)
        20, //maxFormantRatio becomes maximum pitch ratio, may be raised if desired
        4, //grainPeriods - more overlaps is desirable when using as asynchronous pitchshifter
        6, //timeDispersion helps to minimize combing effect; could be also a large number, used as a granulation "effect"
    ) * -3.dbamp;
}.play
)
x.free;

// DelayN

(
// Dust randomly triggers Decay to create an exponential
// decay envelope for the WhiteNoise input source
{
z = Decay.ar(Dust.ar(1,0.5), 0.3, WhiteNoise.ar);
DelayN.ar(z, 0.2, 0.2, 1, z); // input is mixed with delay via the add input
}.play
)
s.freeAll;

// CombN <= this is the real delay!!!

{ CombN.ar(Decay.ar(Dust.ar(1,0.5), 0.2, WhiteNoise.ar), 0.2, 0.2, 3) }.play;