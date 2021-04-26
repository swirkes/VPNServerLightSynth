  //-------------------------//
 //        boot up          //
//-------------------------//
s.boot;
s.scope;

//~port.read;
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
 //  Rvb Bus 7 //
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
(
SynthDef.new(\Reverb, {
	arg in, out=0, mix=0.5, room=0.5, damp=0.5;
	var sig;
	sig = In.ar(in, 1) * 2;
	sig = FreeVerb.ar(sig, mix:mix, room:room, damp:damp);
	Out.ar(out, sig ! 2);
}).add;
)
x = Synth.new(\LFO, [\in, 6]);
y = Synth.new(\Reverb, [\in, 7]);

     //-------------------------//
    //    Connect lfo cutoff   //
   //    and                  //
  //    reverb mix to light  //
 //    sensor readings      //
//-------------------------//
(

~control = Routine.new( {
	{
		x.set(\cutoff, ~val.linexp(0, 1024, 300, 3000));
		//0.01.wait;
		y.set(\mix, ~val.linlin(0.0, 1024.0, 0.001, 0.75).postln);
		0.01.wait;
	}.loop;
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
 //   kick/clap definitions //
//-------------------------//
(
SynthDef('fullkickdrum', {
        var out=0,subosc, subenv, suboutput, clickosc,
		clickenv, clickoutput;

        subosc = {SinOsc.ar(60)};
        subenv = {Line.ar(1, 0.001, 1, doneAction: 2)};

        clickosc = {LPF.ar(WhiteNoise.ar(1),1500)};
        clickenv = {Line.ar(1, 0, 0.02)};

        suboutput = (subosc * subenv);
        clickoutput = (clickosc * clickenv);

        Out.ar(out, Pan2.ar(suboutput, 0));
   }).add;
)

(
SynthDef('clap', {
        var out=0,subosc, subenv, suboutput, clickosc,
		clickenv, clickoutput;

        subosc = {SinOsc.ar(60)};
        subenv = {Line.ar(1, 0.001, 1, doneAction: 2)};

        clickosc = {LPF.ar(WhiteNoise.ar(1),1500)};
        clickenv = {Line.ar(1, 0, 0.12)};

        suboutput = (subosc * subenv);
        clickoutput = (clickosc * clickenv);

        Out.ar(out, Pan2.ar(clickoutput, 0));
   }).add;
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

	//sig = RLPF.ar(sig, cutoff.lag(0.02), 0.25, 0.2);
	Out.ar(out, sig ! 2);
}).add;
)

  //-------------------------//
 //    kick/clap sequence   //
//-------------------------//
(
Pdef(\xxKick, Pbind(
	\instrument, \fullkickdrum,
	\dur, Pseq([0.75, 0.75, 0.75, 0.75, 0.5, 0.75], inf)
)).play(quant: 1/8);

Pdef(\claps, Pbind(
	\instrument, \clap,
	\amp, 0.dbamp,
	\dur, Pseq([Rest(4), 0.25, Rest(4), 0.25], inf),
	\out, 6
)).play(quant: 1);
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

  //-------------------------//
 //   sine pad sequence     //
//-------------------------//
(
Pdef(\sineseq,
	Pbind(
		\instrument, \sine,
		\dur, Pexprand(0.2, 1),
		\freq, Pexprand(200, 800),
		\atk, Pexprand(0.02, 1),
		\rel, Pexprand(1, 7), \out, 7;
)).play;
)


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
	\out, 7
).play;
)
q.stop;


