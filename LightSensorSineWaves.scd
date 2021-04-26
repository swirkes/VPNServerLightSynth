  //-------------------------//
 //        boot up          //
//-------------------------//

(
o = ServerOptions.new;
o.maxLogins = 8;
s = Server.remote(\remote, NetAddr("192.168.1.70", 57110), o, 1);
// set to correct address and port
// info about returned client ID should be posted in the post window
s.makeWindow; // make a window for monitoring.
//**You may have to click -> default button**
s = Server.default;
)

  //-------------------------//
 //     test connection     //
//-------------------------//
{SinOsc.ar(400,mul:0.2)}.play;


   //-------------------------//
  //   search for arduino    //
 //    and connect          //
//-------------------------//
SerialPort.devices;
~port = SerialPort.new("/dev/tty.usbmodem1422101", 9600);


   //-------------------------//
  //  process arduino input  //
 //   and store in ~val     //
//-------------------------//
(
~charArray = [];
~getValues = Routine.new({
	var ascii;
	{
		ascii = ~port.read.asAscii;
		if(ascii.isDecDigit, {~charArray = ~charArray.add(ascii)});
		if(ascii == $a, {
			~val = ~charArray.collect(_.digit).convertDigits;
			~charArray = [];
		});
	}.loop
}).play
)

  //---------------//
 // reverb bus 6  //
//---------------//
(
SynthDef.new(\Reverb, {
	arg in, out=0, mix=0.5, room=0.5, damp=0.5;
	var sig;
	sig = In.ar(in, 1) * 2;
	sig = FreeVerb.ar(sig, mix:mix, room:room, damp:damp);
	Out.ar(out, sig ! 2);
}).add;
)
x = Synth.new(\Reverb, [\in, 6]);

   //------------------------------//
  //  connect reverb mix          //
 //    to lightsensor readings   //
//------------------------------//
(
~control = Routine.new({
	{
		x.set(\mix, ~val.linlin(0, 1024, 0.001, 0.99));
		0.01.wait;
    }.loop
}).play;
)

  //------------------------------------//
 //   sine wave overtones definition   //
//------------------------------------//
(
SynthDef.new(\sine, {
	arg out=0, freq=200, atk=0.5, rel=5, amp=1, pan=0, gate=1;
	var sig, ovr1, ovr2, ovr3, ovr4, env;
	sig = SinOsc.ar(freq, mul:0.5);
	ovr1 = SinOsc.ar(freq * 2, 0, 0.2);
	ovr2 = SinOsc.ar(freq * 3/2, 0, 0.2);
	ovr3 = Saw.ar(freq * 81/64, 0, 0.1);
	ovr4 = Saw.ar(freq * 32/27, 0, 0.1);
	env = EnvGen.kr(Env.new([0,1,0], [atk, rel], [1, -1]), gate, doneAction:2);
	sig = Pan2.ar(sig + ovr1 + ovr2 + ovr3 +ovr4 , pan, amp);
	sig = sig * env;
	Out.ar(out, sig);
}).add;
)


  //-------------------------//
 //   sine pad sequence     //
//-------------------------//
(
p = Pdef(\sineseq,
	Pbind(
		\instrument, \sine,
		\dur, Pexprand(0.2, 1),
		\freq, Pexprand(200, 800),
		\atk, Pexprand(0.02, 1),
		\rel, Pexprand(1, 7), \out, 6;
)).play;
)
p.stsop;

  //-------------------------//
 //  cminor sines sequence  //
//-------------------------//
(
q = Pbind(
	\instrument, \sine,
	\rel, 0.25,
	\atk, Pexprand(0.002, 0.5) ,
	\amp,  Pexprand(5, 100,inf)/127,
    \scale, #[0, 2, 3, 5, 7, 8, 10],
    \root, 1,
	\midinote, Pwrand([60, 72, 84, 96], [0.1, 0.8, 0.08, 0.2], inf),
    \dur, 1/16,
	\out, 6
).play;
)
q.stop;


