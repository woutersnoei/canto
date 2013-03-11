(
~canto.eq = EQSetting( EQdef.global ); // define een setting instance, based on def

~canto.eq.setting;

SynthDef( "canto_eq", {
	var sig, in;
	in = PrivateIn.ar(0,2);
	sig = ~canto.eq.ar( in, \eqSetting.kr( ~canto.eq.setting ) );
	PrivateReplaceOut.ar(0,sig);
	Out.ar( 6, sig );
}).load;

~canto.eqView = EQView( eqSetting: ~canto.eq ); // create a gui

~canto.eqView.action = { |view, setting| ~canto.eqSynth.set( \eqSetting, setting ) } 

);

~canto.eqSynth = Synth( "canto_eq", addAction: \addBefore );


~canto.eqSynth.free;