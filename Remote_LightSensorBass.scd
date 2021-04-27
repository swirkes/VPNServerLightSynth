   //-------------------------//
  //    boot up and connect  //
 //     to remote server    //
//-------------------------//
(
o = ServerOptions.new;
o.maxLogins = 8;
s = Server.remote(\remote, NetAddr("192.168.1.70", 57110), o, 1);
// set to correct address and port
s.makeWindow; // make a window for monitoring.
//**CLICK [-> default] BUTTON IN POP-UP WINDOW**//
)

  //-------------------------//
 //  connect with arduino   //
//-------------------------//
SerialPort.devices;
~port = SerialPort.new("/dev/tty.usbmodem1D11201", 9600);

   //-------------------------//
  //  process arduino input  //
 //   and store in ~val     //
//-------------------------//
(
~charArray = [ ];
~getValues = Routine.new({
	var ascii;
	{
		ascii = ~port.read.asAscii;
		if(ascii.isDecDigit, {~charArray = ~charArray.add(ascii)});
		if(ascii == $a, {
			~val = ~charArray.collect(_.digit).convertDigits;
			~charArray = [ ];
		});
	}.loop
}).play;
);


  //------------//
 //  LFO Bus 6 //
//------------//
(
SynthDef.new(\LFO, {
	arg in, out=0, cutoff=1000, mix=0.5, room=0.5, damp=0.5;
	var sig;
	sig = In.ar(in, 1) * 2;
	sig = RLPF.ar(sig, cutoff.lag(0.02), 0.25, 0.2);
	Out.ar(out, sig ! 2);
}).add;
)
x = Synth.new(\LFO, [\in, 6]);

    //-------------------------//
   //    Connect lfo cutoff   //
  //     to light            //
 //      sensor readings    //
//-------------------------//
(
~control = Routine.new( {
	{
		x.set(\cutoff, ~val.linexp(0, 1024, 300, 3000));
		0.01.wait;
	}.loop;
}).play;
)

  //-------------------------//
 //  bass definition        //
//-------------------------//
(
SynthDef.new(\sawBass, {
	arg out, freq=440, cutoff = 1000, env, atk=0.01, dcy=0.3, sus=0.4,
	rel=0.1, slideTime=0.17, gate=1, width=0.15, preamp=4, amp=0.5,
	detune=1.005;
	var sig;
	freq = Lag.kr(freq, slideTime);
	env = Env.adsr(atk, dcy, sus, rel);
	sig = Mix(VarSaw.ar([freq, freq * detune], 0, width, preamp)).distort * amp * EnvGen.kr(env, gate, doneAction:Done.freeSelf);
	Out.ar(out, sig ! 2);
}).add;
)

  //-------------------------//
 //    bass line sequence   //
//-------------------------//
(
TempoClock.default.tempo = 132/60;
p = Pdef(\bassLine,
Pxrand([
    Pbind(            // repeated notes
        \instrument, \sawBass,
        \midinote, 36,
        \dur, Pseq([0.75, 0.25, 0.25, 0.25, 0.25], 1),
        \legato, Pseq([0.9, 0.3, 0.3, 0.3, 0.3], 1),
        \amp, 0.5, \detune, 1.005, \out, 6
    ),
    Pmono(\sawBass,
        \midinote, Pseq([36, 39, 36], 1),
        \dur, Pseq([0.25, 0.25, 0.5], 1),
        \amp, 0.5, \detune, 1.005, \out, 6
    ),
    Pmono(\sawBass,
        \midinote, Pseq([36, 48, 60, 36], 1),
        \dur, Pseq([0.25, 0.25, 0.25, 0.5], 1),
        \amp, 0.5, \detune, 1.005, \out, 6
    ),
    Pmono(\sawBass,
        \midinote, Pseq([36, 39, 36, 44], 1),
        \dur, Pseq([0.25, 0.5, 0.25, 0.5], 1),
        \amp, 0.5, \detune, 1.005, \out, 6
    )
], inf)).play(quant: 1);
)
p.stop;

