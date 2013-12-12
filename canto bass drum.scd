
// TR-909 style kick
(
SynthDef( "bassdrum", { |amp = 0.25, freq = 42, pulse = 0.1, attackFreq = 100, decay = 0.075,
		sustain = 3, pan = 0|
	var sig;
	sig = BLowPass.ar( Impulse.ar(0,0,pulse), 8000 );
	sig = sig + LFPar.ar( 
		Env.perc(0,decay).ar.linexp(0,1,freq, attackFreq) *
			LFDNoise3.kr(0.1).exprange(-0.1.midiratio, 0.1.midiratio),
		-1);
	sig = sig * Env([1,0], [sustain], -4).kr(2);
	sig = RoundPan.ar( 4, sig, pan + Rand(-0.1,0.1)) * amp;
	//CheckBadValues.ar( sig, 100, 2 );
	sig = RemoveBadValues.ar( sig );
	OffsetOut.ar(0, sig )
}).load(s);

SynthDef( "canto_snare", { |amp = 0.1, fb = 1.75, disperse = 0.001, lpf = 3000, brassage = 0|
	var sig, tofbsig, fbsig;
	
	sig = (
		GrayNoise.ar(1.dup(4)) + WhiteNoise.ar(0.5.dup(4)) +
		(SinOsc.ar(XLine.ar(1000,250,0.1)).distort).dup(4)
		).distort * amp * Env.perc(0.0001,0.2).ar;
	sig = BLowPass.ar( sig, (lpf * ExpRand(0.5,1/0.5)).clip(20,20000), 0.4 );
	fbsig = LocalIn.ar( 4 );
	tofbsig = sig + Limiter.ar( LeakDC.ar( fb * fbsig ), 0.99, 0.01);
	tofbsig = PitchShift.ar(tofbsig, [0.1,0.09], 1, disperse, 0.1 );
	tofbsig = BBandPass.ar( tofbsig, 1500, 15 );
	LocalOut.ar( tofbsig.rotate(1) );
	tofbsig = tofbsig * TRand.kr( 0.dup(4), 1, In.kr(1) ).linlin(0,1,1-brassage,1);
	sig = RemoveBadValues.ar( (sig + (Line.kr(0,1,0.2) * tofbsig))[[0,1]] );
	Out.ar( 0, sig * 0.5 * Env([1,0], [3], -2 ).kr(2) );
}).load(s);
);

(

~canto.bassAmp = 0.0;
~canto.snareAmp = 0;
~canto.bassDelay = { [0, 4/5].choose };
~canto.snareDelay = { [0, 2/5].choose };

~canto.snareDisperse = 0.001;
~canto.snareFreq = 3000;
~canto.snareBrassage = 0;

/*
~canto.bassAmp = 0.3;
~canto.snareBrassage = 1;
*/
~canto.bassCtrl.remove;
~canto.bassCtrl = SimpleController( ~canto );
~canto.bassCtrl.put( \bar, { |...args|
		switch( (~canto.bar % 4).asInt,
			0, {
				if(  ~canto.bassAmp > 0 ) {
					s.makeBundle( 0.1, { 
						Synth( "bassdrum", [ \amp, ~canto.bassAmp ] ); 
					}); 
				};
			},
			1, {
				if( ~canto.snareAmp > 0 ) {
					s.makeBundle( 0.1, { 
						Synth( "canto_snare", [ 
							\amp, ~canto.snareAmp, 
							\disperse, ~canto.snareDisperse,
							\lpf, ~canto.snareFreq ? 3000,
							\brassage, ~canto.snareBrassage ? 0,
						] ); 
					});
				};
			},
			2, {
				if(  (~canto.bassAmp > 0) && (~canto.snareAmp > 0) ) {
					{
						if( 0.5.coin ) {
							~canto.bassDelay.value.wait;
							s.makeBundle( 0.1, { 
								Synth( "bassdrum", [ \amp, ~canto.bassAmp ] ); 
							}); 
						};
					}.fork;
				};
			},
			3, {
				if( ~canto.snareAmp > 0 ) {
					{
						~canto.snareDelay.value.wait;
							s.makeBundle( 0.1, { 
								Synth( "canto_snare", [ 
								\amp, ~canto.snareAmp, 
								\disperse, ~canto.snareDisperse,
								\lpf, ~canto.snareFreq ? 3000,
								\brassage, ~canto.snareBrassage ? 0,
							] ); 
						}); 
					}.fork;
				};
			}
		);
		/*
		if( ((~canto.bar % 2) == 0) && { ~canto.currentCell.notNil } ) { 
			s.makeBundle( 0.1, { 
				Synth( "bassdrum", [ \amp, ~canto.bassAmp ] ); 
			}); 
		};
		*/ 
});

if( e.notNil ) {
	e.masterKnob.action = { |sl| ~canto.bassAmp = \amp.asSpec.map( sl.value ) * 0.5; };
	e.actions.slider[16] = { |sl| ~canto.bassAmp = \amp.asSpec.map( sl.value ) * 0.5; };
	e.actions.slider[17] = { |sl| ~canto.snareAmp = \amp.asSpec.map( sl.value ) * 0.5; };
	e.actions.knob[17] = { |sl| ~canto.snareFreq = sl.value.linexp(0,1,250,5000); };
	e.actions.knob[16] = { |sl| ~canto.snareDisperse = sl.value.linexp(0,1,0.0001,0.1); };
	e.actions.button.on[17] = { |bt| ~canto.snareBrassage = bt.value; };

	//e.masterKnob.value = 0;
	~canto.bassCtrl.put( \bassAmp, { 
		e.masterKnob.value = \amp.asSpec.unmap( ~canto.bassAmp * 2 );
		e.active = false;
		e.buttons.rec[16].valueAction = (~canto.bassAmp > 0).binaryValue;
		e.sliders[16].valueAction = \amp.asSpec.unmap( ~canto.bassAmp * 2 );
		e.active = true;
	});
	~canto.bassCtrl.put( \snareAmp, { 
			e.active = false;
			e.buttons.rec[17].valueAction = (~canto.snareAmp > 0).binaryValue;
			e.sliders[17].valueAction = \amp.asSpec.unmap( ~canto.snareAmp * 2 );
			e.active = true;
		});

	~canto.changed( \bassAmp );
	~canto.changed( \snareAmp );
};
);
