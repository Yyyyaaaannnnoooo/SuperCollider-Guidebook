(
///~~~ SERVER CLEANUP ~~~///
~cleanup = {
  ServerBoot.removeAll;
  ServerQuit.removeAll;
  ServerTree.removeAll;
  CmdPeriod.removeAll;
};

ServerQuit.add(~cleanup);
~cleanup.();

///~~~ Load path to samples here ~~~///
~path = PathName(thisProcess.nowExecutingPath).parentPath;

///~~~ BUSSES ~~~///
s.newBusAllocators;
~reverb_bus = Bus.audio(s, 2);

///~~~ MIDI ~~~///
MIDIIn.connectAll();
MIDIIn.disconnectAll();

/*MIDIIn.noteOn({
  // function for your midi notes
  // like playing a synth
}).permanent_(true);*/ /// <= this makes it cmd + . agnostic

s.waitForBoot({
  ///~~~ LOAD SAMPLES IN BUFFERS ~~~///
  ///~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~///
  var subfolders;
  b = ();
  ~path.postln;
  subfolders = PathName(~path ++ "audio/").entries;
  subfolders.do({
    arg dir;
    var buf_array;
    buf_array = dir.entries.collect({
      arg file;
      Buffer.readChannel(s, file.fullPath, channels: [0, 1]);
    });
    b[dir.folderName.asSymbol] = buf_array;
  });


  ~breaks = b[\breaks];

  ///~~~ LOAD SYNTH DEFS ~~~///
  ///~~~~~~~~~~~~~~~~~~~~~~~///

  ///~~~ LOAD FX SYNTH DEFS ~~~///
  ///~~~~~~~~~~~~~~~~~~~~~~~~~~///
  SynthDef.new(\reverb,
    {
      arg in=0, mix=0.4, out=0;
      var sig, wet;
      sig = In.ar(in, 2); // reads from the audio bus
      sig = FreeVerb2.ar(
        sig[0], sig[1],
        mix: mix.clip(0.0, 1.0), room: 0.999, damp: 0.85
      );
      Out.ar(out, sig)
  }).add;

  ///~~~ VERY IMPORTANT ~~~///
  s.sync;
  // wait that the synthdefs are loaded
  // so that it is possible to assign
  // synthdefs to global variables
  ~make_nodes ={
    // we need to package all inside a function
    // so that the groups and synths will be bult once the
    // server tree is built
    ~synths = Group.new();
    ~fxs = Group.new(~synths, \addAfter);
    ~verb = Synth.new(\reverb, [\in, ~reverb_bus], target: ~fxs);
  };
  // here we assign the function above as callback
  // for the ServerTree function
  ServerTree.add(~make_nodes);
  // after we run it
  ServerTree.run;
});
)

