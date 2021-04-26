  //-------------------------//
 //        boot up          //
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
 //     test connection     //
//-------------------------//
{SinOsc.ar(400,mul:0.2)}.play;


   //-------------------------//
  //   search for arduino    //
 //    and connect          //
//-------------------------//
SerialPort.devices;
~port = SerialPort.new("/dev/ttyACM0", 9600);


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
 // delay bus 6  //
//---------------//
(
SynthDef.new(\Reverb, {
	arg in, out=0, maxdelay=0.2, delay=0.2, decay=1.0;
	var sig;
	sig = In.ar(in, 1) * 2;
	sig = FreeVerb.ar(sig);
	sig = CombN.ar(sig, maxdelaytime:maxdelay, delaytime:delay, decaytime:decay);
	Out.ar(out, sig ! 2);
}).add;
)
x = Synth.new(\Reverb, [\in, 6]);
x.set(\decay, 1)

x.free;
   //------------------------------//
  //  connect reverb mix          //
 //    to lightsensor readings   //
//------------------------------//
(
~control = Routine.new({
	{
		x.set(\delay, ~val.linexp(0, 1024, 0.001, 1).postln);

		0.5.wait;
    }.loop
}).play;
)
~control.stop;
  //-------------------------//
 //   kick/clap definitions //
//-------------------------//
(
SynthDef('fullkickdrum', {
        var out=0,subosc, subenv, suboutput;

        subosc = {SinOsc.ar(60)};
        subenv = {Line.ar(1, 0.001, 1, doneAction: 2)};

        suboutput = (subosc * subenv);

        Out.ar(out, Pan2.ar(suboutput, 0));
   }).add;

SynthDef('clap', {
        var out=6, clickosc, clickenv, clickoutput;

        clickosc = {LPF.ar(WhiteNoise.ar(1),1500)};
        clickenv = {Line.ar(1, 0, 0.12)};

        clickoutput = (clickosc * clickenv);

        Out.ar(out, clickoutput);
   }).add;
)

  //-------------------------//
 //    kick/clap sequence   //
//-------------------------//
(
TempoClock.default.tempo = 132/60;
p = Pdef(\xxKick, Pbind(
	\instrument, \fullkickdrum,
	\dur, Pseq([0.75, 0.75, 0.75, 0.75, 0.5, 0.75], inf)
)).play(quant: 1/8);

q = Pdef(\claps, Pbind(
	\instrument, \clap,
	\amp, 0.dbamp,
	\dur, Pseq([Rest(4), 0.25, Rest(4), 0.25], inf),
	\out, 6
)).play(quant: 1);
)
p.stop;
q.stop;


Server.freeAll;
