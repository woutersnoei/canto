
// TR-909 style kick
(
SynthDef( "bassdrum", { |amp = 0.25, freq = 40, pulse = 0.1, attackFreq = 100, decay = 0.1,
		sustain = 3, pan = 0|
	var sig;
	sig = BLowPass.ar( Impulse.ar(0,0,pulse), 8000 );
	sig = sig + LFPar.ar( 
		Env.perc(0,decay).ar.linexp(0,1,freq, attackFreq) *
			LFDNoise3.kr(0.1).exprange(-0.1.midiratio, 0.1.midiratio),
		-1);
	sig = sig * Env([1,0], [sustain], -4).kr(2);
	sig = RoundPan.ar( 2, sig, pan + Rand(-0.1,0.1)) * amp;
	sig = RemoveBadValues.ar( sig );
	OffsetOut.ar(10, sig )
}).load(s);
);

(

~canto.bassAmp = 0.0;
/*
~canto.bassAmp = 0.3;
*/
~canto.bassCtrl.remove;
~canto.bassCtrl = SimpleController( ~canto );
~canto.bassCtrl.put( \bar, { |...args|
	if( ~canto.bassAmp > 0 ) {
		if( (~canto.bar == 0) && { ~canto.currentCell.notNil } ) { 
			s.makeBundle( 0.1, { 
				Synth( "bassdrum", [ \amp, ~canto.bassAmp ] ); 
			}); 
		}; 
	}
});

if( e.notNil ) {
	e.masterKnob.action = { |sl| ~canto.bassAmp = \amp.asSpec.map( sl.value ) * 0.5; };
	//e.masterKnob.value = 0;
	~canto.bassCtrl.put( \bassAmp, { 
		e.masterKnob.value = \amp.asSpec.unmap( ~canto.bassAmp * 2 ) 
	});
	~canto.changed( \bassAmp );
};
);
