~canto.beatCtrl.remove;
~canto.beatCtrl = SimpleController( ~canto );
~canto.beatServer = Server.local;

~canto.beatAmp = 0;
~canto.beatSnap = 0.75;
~canto.beatPat = [ 1, 1, 1, 0, 1, 0, 0.5, 1, 0.5, 1, ];
~canto.beatFilter = [ 0.2, 0.4, 0.2, 1, 0.6, 1, 1, 0.4, 1, 0.4, ];

/*
~canto.beatAmp = 1;
*/

(
SynthDef( "canto_beatnoise", { |amp = 0.1, sustain = 1, filter = 0.5, snap = 0.75, pan = 0|
	var sig, envs, env, n=5;
	var noise;
	var amps;
	noise = BHiCut.ar( Impulse.ar(0) + GrayNoise.ar(1), 5500, 1 );
	noise = noise.distort;
	noise = BLowCut.ar( noise, filter.linexp( 0, 1, 20, 5000 ) );
	noise = BHiCut.ar( noise, filter.linexp( 0, 1, 200, 10000 ) );
	//noise = SinOsc.ar( freq * 4, 0.5, 1 ) * noise;
	sig = noise;
	env = Env([0,1,0,0], [0.01, sustain, 0.01], snap.linlin(0,1,-10,-2)).kr(2);
	sig = RoundPan.ar(~canto.numChan ? 4, sig, pan);
	sig = RemoveBadValues.ar(sig);
	OffsetOut.ar( 0, sig * env * amp );
}).store;
);

~canto.beatCtrl.put( \bar, { |...args|
	if( ~canto.beatAmp != 0 ) {
		Task({
			var res;
			var pat = ~canto.beatPat.copy;
			if( 0.1.coin ) { 
				pat = pat.reverse;
			};
			5.do({ |ii|
				//res = ~canto.beatRes.ceil;
				res = [2,4].wchoose([0.95,0.05]);
				if( pat[ii*2] != 0 ) {
					~canto.beatServer.makeBundle( 0.1, {
							Synth( "canto_beatnoise", [ 
								\amp, (0.75 rrand: 1) * ~canto.beatAmp * pat[ii*2], 
								\filter, ~canto.beatFilter[ii*2],
								\sustain, 0.1,
								\snap, ~canto.beatSnap ? 0.75,
							], ~canto.beatServer );
						});
				};
				((1/5)/res).wait;
				if( pat[(ii*2) + 1] != 0 ) {
					(res-1).do({ |i|
						~canto.beatServer.makeBundle( 0.1, {
							Synth( "canto_beatnoise", [ 
								\amp, (0.375 rrand: 0.5) * ~canto.beatAmp * pat[(ii*2) + 1], 
								\filter, ~canto.beatFilter[(ii*2) + 1],
								\sustain, 0.1,
								\snap, ~canto.beatSnap ? 0.75,
							], ~canto.beatServer );
						});
						((1/5)/res).wait;	
					});
				} {
					(res-1).do({ ((1/5)/res).wait; });
				};
			});
		}).start;
	};
});


if( e.notNil ) {
	e.masterKnob.action = { |sl| ~canto.bassAmp = \amp.asSpec.map( sl.value ); };
	e.actions.slider[18] = { |sl| ~canto.beatAmp = \amp.asSpec.map( sl.value ); };
	e.actions.knob[18] = { |sl| ~canto.beatSnap = sl.value };

	//e.masterKnob.value = 0;
	~canto.bassCtrl.put( \beatAmp, { 
		e.active = false;
		e.buttons.rec[18].valueAction = (~canto.beatAmp > 0).binaryValue;
		e.sliders[18].valueAction = \amp.asSpec.unmap( ~canto.beatAmp );
		e.active = true;
	});
	~canto.bassCtrl.put( \beatSnap, { 
			e.active = false;
			e.knobs[18].valueAction = ~canto.beatSnap;
			e.active = true;
		});

	~canto.changed( \beatAmp );
	~canto.changed( \beatSnap );
};
