(
~canto = ~canto ? EM();

~canto.latency = (1024 + 64)/44100; // audio i/o latency Babyface: (1024 + 64)/44100

~canto.cutbus = Bus( \control, 1, 1 );

TempoClock.tempo = 57 / 60;

~canto.getCell = { |evt, cell = 1|
	if( cell.isKindOf( Dictionary ).not ) {
		cell = cell.asSymbol;
		cell = evt.cells.detect({ |item| item.id == cell });
	};
	cell ? ();
};

~canto.getCellNotes = { |evt, cell = 1, variant = 0|
	if( variant.class != Symbol ) {
		variant = #[ notes, notesSecond, notesEnd ][ variant ] ? \notes;
	};
	cell = evt.getCell( cell );
	cell[ variant ] ?? { cell[ \notes ] };
};

~canto.getCellBar = { |evt, bar = 0, cell = 1, variant = 0|
	var notes;
	cell = evt.getCell( cell );
	notes = evt.getCellNotes( cell, variant );
	bar = bar % (cell.duration ? 0);
	notes.select({ |note|
		(note[1] >= bar ) && { note[1] < (bar+1) }
	});
};

(
SynthDef( "canto_note", { |amp = 0.1, sustain = 1, damp = 16, freq = 440, sharpness = 2, pan = 0, 
	dev = 0.3, mod = 0.25, hpf = 20|
	var sig, envs, env, n=5;
	var amps, freqs, modfreq;
	dev = (dev / 2).midiratio - 1;
	envs = n.collect({ |i|
		Env.perc(ExpRand(
			sharpness.linlin(16,32,0.025,0.005).clip(0.005,0.025,),
		0.04),1,0.99,(i+1).neg * damp).ar + 0.01;
	});
	amps = \amps.kr( 1.dup(n) );
	//amps = ExpRand(0.005.dup(n),1);
	amps = (1/((1..n) ** sharpness.fold(1,16.5))) * amps;
	amps = (amps * n * envs) / (amps.sum);
	
	freqs = freq * (1..n) * ExpRand((1-dev).dup(n),1/(1-dev));
	
	sig = SinOsc.ar( freqs, 
			//Rand(0.dup(n),2pi), 
		0,
		amps
		);
		
	//sig = BLowPass.ar( sig, freq * XLine.kr(3,1,sustain), 0.33 );
	
	sig = sig.sum / n.sqrt;
	sig = sig * AmpComp.kr( freq * 2);
	sig = sig + LPF.ar( Impulse.ar(0, 0.5), 1200 );
	modfreq = LFDNoise3.kr(0.1 + (mod * 2)).exprange(100,1000);
	sig = CombC.ar( sig, 1/100, 1/modfreq, 
		0.01 + (mod * 0.04) );
	sig = BPeakEQ.ar( sig, 1000, 1, mod * -3 );
	sig = BLowCut.ar( sig, hpf, 2 );
	sig = RoundPan.ar(~canto.numChan ? 4, sig, Rand(-0.05,0.05) + pan);
	env = Env([1,1,0], [sustain * sharpness.linlin(16,32,1,0.01).clip(0.01,1), 0.1]).ar(2);
	sig = RemoveBadValues.ar(sig);
	OffsetOut.ar( 0, sig * env * amp );
}).load(s);
);

( // new bass
SynthDef( "canto_bass", { |amp = 0.1, sustain = 1, damp = 16, freq = 440, dev = 0.0075, sharpness = 2, pan = 0, mfreq = 1, mamt = 0, mod = 0.25, hpf = 20|
	var sig, envs, env, n=5;
	var amps, cutenv;
	var inclick;
	inclick = In.kr(1);
	mod = mod * 0.25;
	sig = Pulse.ar( (freq * 0.5) + ([-0.5,0.5] +(mod * [-1,1])), 
		LFDNoise1.kr(0.25.dup(4)).range(0.01,0.99)
		//TRand.kr(0.dup,1,In.kr(1) )
	);
	sig = sig + BrownNoise.ar(0.15);
	
	//sig = sig ring1: SinOsc.ar( LFDNoise1.kr( 20 ).exprange(1000,6000), 0, 0.75);
	//freq = TExpRand.kr(0.25,1,In.kr(1) ).lag(0.05) * freq;
	
	//freq = freq * Trig1.kr( In.kr(1), 0.02 ).lag(0,0.5).linexp(0,1,0.4,1);
	
	//freq = LFDNoise3.kr(0.05.dup(5))
	
	//cutenv = Line.kr( sharpness.linlin(18,32,1,32), sharpness.linlin(18,32,1,8), sustain );
	
	//cutenv = Latch.kr(inclick, inclick).lag(0.05).linlin( 0, 1, 1, sharpness.linlin(18,32,1,32) );
	
	cutenv = Select.kr( Latch.kr( inclick, inclick ) * 5, \amps.kr( 1.dup(n) ) )
		.clip(-80.dbamp,1).lincurve( -80.dbamp, 1, sharpness.linlin(18,32,1,2), sharpness.linlin(18,32,1,36), -4 )
		.varlag(0.05);
	
	sig = BLowPass.ar( sig, (
		freq.blend( 
			LFDNoise3.kr(0.1).exprange( 40,100 ), 0.1) 
				* sharpness.linlin(1,15,32,1)
				* cutenv
				//* SinOsc.kr( 1/sustain, 0.5pi, mod, 1 );
			//SinOsc.kr( mfreq, 0, mamt )
		)
		.clip(20,20000), 0.125 );
		
	/*
	cutenv = freq.blend( LFDNoise3.kr(0.1).exprange( 40,100 ), 0.1) * sharpness.linlin(1,15,32,1);
		
	sig = SelectCF.ar( (Latch.kr( inclick, inclick ) * 5) - 1, 
		BLowPass.ar( sig, 
			(
				\amps.kr( 1.dup(n) ).clip(-80.dbamp,1).lincurve( -80.dbamp, 1, sharpness.linlin(18,32,1,2), sharpness.linlin(18,32,1,36), -4 ) * cutenv 
		) .clip(20,20000), 0.125 
	), 0.02, 0 );
	*/
				
	//sig = (sig / 4).softclip * 4;
	
	//sig = BLowCut.ar( sig, (freq * (cutenv / 2)).clip(20,20000), 3 );
	//sig = sig * Line.kr( 1, sharpness.linlin(17,32,1,0.1), sustain );
	
	sig = BLowCut.ar( sig, hpf, 2 );
	//sig = RoundPan.ar( ~canto.numChan ? 4, sig, Rand(-0.05,0.05) + (pan * 0.1));
	sig = Splay.ar( sig, levelComp: false );
	env = Env([0,1,1,0], [0.01, sustain * 1.2, 0.1]).kr(2);
	//Poll.kr( Impulse.kr(10), sharpness );
	sig = RemoveBadValues.ar(sig);
	OffsetOut.ar( 0, sig * env * amp * 0.25 );
}).load(s);
);

(
SynthDef( "canto_noteNoise", { |amp = 0.1, sustain = 1, damp = 16, freq = 440, sharpness = 2, pan = 0, 
	dev = 0.3, mod = 0.25, hpf = 20|
	var sig, envs, env, n=5;
	var amps, freqs, modfreq;
	var moddev;
	dev = (dev / 2).midiratio - 1;
	envs = n.collect({ |i|
		Env.perc(ExpRand(
			sharpness.linlin(16,32,0.02,0.0025).clip(0.0025,0.02,),
		0.02),1,0.99,(i+1).neg * damp).ar + 0.01;
	});
	amps = \amps.kr( 1.dup(n) );
	//amps = ExpRand(0.005.dup(n),1);
	amps = (1/((1..n) ** sharpness.fold(1,16.5))) * amps;
	amps = (amps * n * envs) / (amps.sum);
	
	freqs = freq * (1..n) * ExpRand((1-dev).dup(n),1/(1-dev));
	
	/*
	sig = SinOsc.ar( freqs, 
			//Rand(0.dup(n),2pi), 
		0,
		amps
		);
	*/
	
	//sig = BBandPass.ar( GrayNoise.ar(1.dup(freqs.size)), freqs, 0.01, amps * 100 );
	
	/*
	sig = freqs.collect({ |fr,i|
		var sg;
		sg = GrayNoise.ar(10);
		sg = BLowCut.ar( sg, fr, 5 );
		sg = BHiCut.ar( sg, fr, 5 );
		sg
	}) * amps;
	*/
	moddev = 1.01 + (mod * 0.5);
	
	sig = freqs.collect({ |fr,i|
		var sg;
		sg = SinOsc.ar( (WhiteNoise.ar(0.5) + PinkNoise.ar(0.5)).exprange( fr/moddev, fr*moddev ) );
		sg
	}) * amps;
	
		
	//sig = BLowPass.ar( sig, freq * XLine.kr(3,1,sustain), 0.33 );
	
	sig = sig.sum / n.sqrt;
	//sig = BLowCut.ar( sig, freq );
	sig = sig * AmpComp.kr( freq * 2);
	sig = sig + LPF.ar( Impulse.ar(0, 0.5), 1200 );
	modfreq = LFDNoise3.kr(0.1 + (mod * 2)).exprange(100,1000);
	
	sig = CombC.ar( sig, 1/100, 1/modfreq, 
		0.01 );
	
	sig = BPeakEQ.ar( sig, 1000, 1, mod * -3 );
	sig = BLowCut.ar( sig, hpf, 2 );
	sig = RoundPan.ar(~canto.numChan ? 4, sig, Rand(-0.05,0.05) + pan);
	env = Env([1,1,0], [sustain * sharpness.linlin(16,32,1,0.01).clip(0.01,1), 0.1]).ar(2);
	sig = RemoveBadValues.ar(sig);
	OffsetOut.ar( 0, sig * env * amp );
}).load(s);
);

(
SynthDef( "canto_noteFormant", { |amp = 0.1, sustain = 1, damp = 16, freq = 440, sharpness = 2, pan = 0, 
	dev = 0.3, mod = 0.25, hpf = 20|
	var sig, envs, env, n=5;
	var amps, freqs, modfreq;
	var formants;
	var moddev;
	//dev = ((dev * mod.linlin(0,1,1,0.5))/ 2).midiratio - 1;
	dev = (dev / 2).midiratio - 1;
	envs = n.collect({ |i|
		Env.perc(
		/*
		ExpRand(
			sharpness.linlin(16,32,0.025,0.005).clip(0.005,0.025,),
		0.04)
		*/
		0.002
		,1,1.0,(i+1).neg * damp).ar + 0.01;
	});
	amps = \amps.kr( 1.dup(n) );
	//amps = ExpRand(0.005.dup(n),1);
	//amps = (1/((1..n) ** sharpness.fold(1,16.5))) * amps;
	//amps = (amps * n) / (amps.sum);
	
	formants = amps.linexp( 0, 1, freq, freq * sharpness.fold(1,16.5).lincurve(1,16.5,12,1,4) );
	
	freqs = freq * ExpRand((1-dev).dup(n),1/(1-dev));
	
	/*
	sig = SinOsc.ar( freqs, 
			//Rand(0.dup(n),2pi), 
		0,
		amps
		);
	*/
	
	//sig = BBandPass.ar( GrayNoise.ar(1.dup(freqs.size)), freqs, 0.01, amps * 100 );
	
	/*
	sig = freqs.collect({ |fr,i|
		var sg;
		sg = GrayNoise.ar(10);
		sg = BLowCut.ar( sg, fr, 5 );
		sg = BHiCut.ar( sg, fr, 5 );
		sg
	}) * amps;
	*/
	moddev = 1.01 + (mod * 0.25);
	
	sig = (freqs.collect({ |fr,i|
		var sg;
		sg = Formant.ar( fr, formants[i], fr * mod.linlin(0,1,1,4) );
		sg
	}) / n) * envs;
	
	//sig = DelayN.ar( sig, 0.2, Rand(0.dup(sig.size),0.2) );
		
	//sig = BLowPass.ar( sig, freq * XLine.kr(3,1,sustain), 0.33 );
	
	sig = sig.sum / n.sqrt;
	//sig = BLowCut.ar( sig, freq );
	//sig = sig * AmpComp.kr( freq * 2);
	sig = sig + LPF.ar( Impulse.ar(0, 0.5), 1200 );
	modfreq = LFDNoise3.kr(0.1 + (mod * 2)).exprange(100,1000);
	
	sig = CombC.ar( sig, 1/100, 1/modfreq, 
		0.01 );
	
	sig = BPeakEQ.ar( sig, 1000, 1, mod * -3 );
	sig = BLowCut.ar( sig, hpf, 2 );
	sig = RoundPan.ar(~canto.numChan ? 4, sig, Rand(-0.05,0.05) + pan);
	env = Env([1,1,0], [sustain * sharpness.linlin(16,32,1,0.01).clip(0.01,1), 0.1]).ar(2);
	sig = RemoveBadValues.ar(sig);
	OffsetOut.ar( 0, sig * env * amp * 2 );
}).load(s);
);

(
SynthDef( "canto_noteFilt", { |amp = 0.1, sustain = 1, damp = 16, freq = 440, sharpness = 2, pan = 0, 
	dev = 0.3, mod = 0.25, hpf = 20|
	var sig, envs, env, n=5;
	var amps, freqs, modfreq;
	var formants;
	var moddev;
	var dur;

	dur = sustain * sharpness.linlin(16,32,1,0.1).clip(0.01,1);

	amps = \amps.kr( 1.dup(n) );
	
	formants = amps.linlin( 0, 1, sharpness.fold(16.5,32).linexp(16.5,32, freq, 2000 ) , 
		//freq * sharpness.fold(1,16.5).lincurve(1,16.5,12,1,4) 
		sharpness.fold(16.5,32).linexp(16.5,32, freq, 20000 ) 
	);
	
	sig = { Saw.ar( freq + Rand(-2,2), 0.25 ) + Pulse.ar( freq + Rand(-2,2), 0.25 ); }!n;
	
	sig = MoogVCF.ar( sig, 
		Env.perc(0.01,dur * 4).kr.linexp( 0,1, freq, 
			//sharpness.fold(16.5,32).linexp(16.5,32, freq, 15000 ) 
			formants
		), K2A.ar( mod.linlin(0,1,0.8,1.0) )
	);
	
	
	sig = sig.sum / n.sqrt;

	sig = RoundPan.ar(~canto.numChan ? 4, sig, Rand(-0.05,0.05) + pan);
	env = Env([1,1,0], [sustain * sharpness.linlin(16,32,1,0.01).clip(0.01,1), 0.1]).ar(2);
	sig = RemoveBadValues.ar(sig);
	OffsetOut.ar( 0, sig * env * amp );
}).load(s);
);

(
SynthDef( "canto_hihat", { |amp = 0.1, sustain = 1, damp = 16, freq = 440, dev = 0.0075, sharpness = 2, pan = 0|
	var sig, envs, env, n=5;
	var noise;
	var amps;
	noise = WhiteNoise.ar(0.5);
	//noise = SinOsc.ar( freq * 4, 0.5, 1 ) * noise;
	noise = noise * Env.perc( ExpRand(0.001,0.001), sustain * ExpRand(0.1,2) ).ar;
	noise = BLowCut.ar( noise, sharpness.linexp(16,32,2000,13000).clip(2000,20000), 4);
	//noise = OnePole.ar(noise, 0.95 );
	sig = noise;
	//sig = CombL.ar( noise, 1/50, 1/freq, 0.5 );
	//sig = Pulse.ar( freq * 0.5, LFDNoise1.kr(0.25).range(0,1) );
	sig = BLowPass.ar( sig, (1100 * sharpness).clip(20,20000), 0.5 );
	sig = RoundPan.ar(~canto.numChan ? 4, sig, Rand(-0.05,0.05) + pan);
	env = Env([0,1,1,0], [0.01, sustain, 0.01]).kr(2);
	sig = RemoveBadValues.ar(sig);
	OffsetOut.ar( 0, sig * env * amp );
}).load(s);
);

~canto.defNames = [ 'canto_bass', 'canto_noteFilt', 'canto_noteFormant', 'canto_note', 'canto_noteNoise', 'canto_hihat' ];

~canto.instruments = 'canto_note'!14;

~canto.instruments[4] = 'canto_hihat';
~canto.instruments[10] = 'canto_bass';

~canto.playNote = { |evt, track = 0, nn = 64, sustain = 1, amps, pan = 0, damp = 4, sharpness = 2, amp = 0.1, mod = 0, hpf = 20, gain = 0, noteDur = 1|
	if(  evt.instruments[ track ].asSymbol !== 'canto_hihat' ) {
		Synth( evt.instruments[ track ], [ freq: nn.midicps, sustain: sustain * noteDur,  pan: pan, 
			amp: amp * gain.dbamp, 
			damp: damp, sharpness: sharpness, mod: mod, hpf: hpf, amps: amps ? (1!5) ] );
	} {
		Synth( evt.instruments[ track ], [ freq: nn.midicps, sustain: sustain * noteDur,  pan: pan, 
			amp: amp * gain.dbamp, 
			damp: damp, sharpness: sharpness, mod: mod,  hpf: hpf] );
	};
};

~canto.setSlowChange = { |evt|
	evt.amps = { ({ Pbrown(0.0,1.0,0.1).linexp(0,1,-80.dbamp,1).asStream }!5) !5 }!13;
	evt.damp = { Pbrown(0,1,0.1).linexp(0,1,2,16).asStream ! 5 }!13;
};

~canto.setFastChange = { |evt|
	evt.amps = { { { Pbrown(0.0,1.0,0.15).linexp(0,1,-80.dbamp,1).asStream }!5 }!5 }!13;
	evt.damp = { { PintL( Pwhite(0.0,1,inf), 40 ).linexp(0,1,2,16).asStream } ! 5 }!13;
};


~canto.amp = { (PintC( Pwhite(0,1), 0.01 ).linexp(0,1,-15.dbamp,1) * 0.1).asStream }!13;
~canto.sharpness = { Pbrown(0,1,0.05).linexp(0,1,3,8).asStream }!13;

~canto.gain = 0!13; ~canto.gain[10] = 12;

~canto.hpf = ~canto.hpf ? EM(); 13.do({ |i| ~canto.hpf[i] = 20 });
~canto.noteDur = ~canto.noteDur ? EM(); 13.do({ |i| ~canto.noteDur[i] = 1 });

~canto.setSlowChange;

/*
~canto.setFastChange;
~canto.amps = { { { Pbrown(0.0,1.0,0.2).linexp(0,1,-80.dbamp,1).asStream }!5 }!5 }!13;
~canto.amps = { ({ Pbrown(0.0,1.0,0.1).linexp(0,1,-80.dbamp,1).asStream }!5) !5 }!13;
~canto.damp = { Pbrown(0,1,0.1).linexp(0,1,2,16).asStream ! 5 }!13;
~canto.damp = { { PintL( Pwhite(0.0,1,inf), 20 ).linexp(0,1,2,16).asStream } ! 5 }!13;
~canto.damp = { { Pbrown(0,1,0.1).linexp(0,1,2,16).asStream } ! 5 }!13;
~canto.pan = { { Pbrown(-1.0,1.0,0.1).asStream } ! 5 }!13;
*/


~canto.setSlowPan = { |evt|
	"set slow pan".postln;
	evt.pan = { Pbrown(-2.0,2.0,0.1).wrap(-1,1).asStream ! 5 }!13;
};

~canto.setFastPan = { |evt|
	"set fast pan".postln;
	evt.pan = { { Pbrown(-2.0,2.0,0.1).wrap(-1,1).asStream }!5 }!13;
};

~canto.setSlowPan;

/*
~canto.pan = { { Pbrown(-2.0,2.0,0.1).wrap(-1,1).asStream }!5 }!13;
*/

~canto.mod = 0.0!13;

~canto.useNote = [true,true,true,true,true];

~canto.playBar = { |evt, track = 4, bar = 0, cell = 2, variant = 0|
	var notes;
	notes = evt.getCellBar( bar, cell, variant );
	Task({
		var time = 0;
		evt.barStartSecond = thisThread.seconds;
		notes.select({ |note| note[0] == track }).sort({ |a,b|
			a[1] <= b[1];
		}).do({ |note|
			var pos;
			pos = note[1] - bar;
			//pos.postln;
			(pos-time).wait;
			if( evt.useNote[(pos * 5).round(1).asInt] != false ) {
				s.makeBundle( 0.1 + (0.00001.rand), { 
					evt.playNote( track, note[4], note[6] / TempoClock.tempo, 
						evt.amps[ track ][(pos * 5).round(1)].collect(_.value),
						evt.pan[ track ][(pos * 5).round(1)].collect(_.value),
						evt.damp[ track ][(pos * 5).round(1)].collect(_.value),
						evt.sharpness[ track ].value,
						evt.amp[ track ].value,
						evt.mod[ track ].value,
						evt.hpf[ track ].value,
						evt.gain[ track ].value,
						evt.noteDur[ track ].value,

					);
				});
			};
			time = pos;
		});
	}).start;
	Task({
		5.do({ |i|
			s.makeBundle( 0.1, { 
				~canto.cutbus.set( i.linlin(0,5,1,0) );
			});
			(1/10).wait;
			s.makeBundle( 0.1, { 
				~canto.cutbus.set( 0 );
			});
			(1/10).wait;
		});
	}).start;
};

~canto.currentIndex = 0;
~canto.bar = 0;


~canto.currentCell_ = { |evt, cell|
	var last;
	last = evt[ \currentCell ];
	evt[ \currentCell ] = cell;
	if( last != cell ) { "current cell: %\n".postf( cell !? _.id ); };
};

~canto.jumpNow = { |evt, index = 0|
	evt.currentIndex = index;
	evt.currentCell = evt.cells[ evt.currentIndex ];
};

~canto.nextNow = { |evt, amt = 1|
	evt.jumpNow( evt.currentIndex + amt );
};

~canto.bar_ = { |evt, bar = 0|
	evt[ \bar ] = bar;
	if( evt.verbose == true ) { "current bar: %\n".postf(bar+1); };
};

~canto.tracks = (..12);

~canto.start = { |evt|
	if( evt.task.isNil or: { evt.task.isPlaying.not } ) {
		evt.task = Task({
			var dur = 2, variant = 0;
			evt.bar = 0;
			evt.currentCell = evt.cells[ evt.currentIndex ];
			dur = evt.currentCell !? _.duration ? dur;
			inf.do({
				if( evt.currentCell.notNil ) {
					//[ evt.bar, variant, dur ].postln;
					evt.tracks.do({ |track|
						evt.playBar( track, evt.bar % dur, evt.currentCell, variant );
					});
				};
				1.wait;
				evt.bar = ((evt.bar + 1) % dur).floor;
				if( evt.bar == 0 ) { 
					if( evt.currentCell.notNil && { evt.currentCell.bridge }) { 
						evt.currentIndex = evt.currentIndex + 1 
					};
					if( evt.currentCell != evt.cells[ evt.currentIndex ]  ) { variant = 0 }; 
					evt.currentCell = evt.cells[ evt.currentIndex ];
				} {
					variant = 1; // second
				};
				if( evt.currentCell.notNil ) { dur = evt.currentCell.duration; };
				if( evt.currentCell != evt.cells[ evt.currentIndex ]  ) { variant = 2 }; // last
			});
		}).start;
	};
};

~canto.end = { |evt|
	evt.task.stop;
	evt.task = nil;
};
)

/*
~canto.start; "";

TempoClock.tempo = 59/60;

~canto.currentIndex = ~canto.currentIndex - 1;

~canto.currentIndex = ~canto.currentIndex + 1;

~canto.end;


~canto.mf.noteOnEvents.collect(_[0]).as(Set).as(Array).sort

[ 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 ]

(
~canto.getCellNotes( 9 ).select({ |note|
	(note[1] >= 0.2 ) && { note[1] < 0.4 }
});
)

~canto.playBar(0,0,1)

~canto.cells.collect(_.duration)
*/