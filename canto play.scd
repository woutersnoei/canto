(
~canto = ~canto ? EM();

~canto.latency = (128 + 64)/44100; // audio i/o latency Babyface: (1024 + 64)/44100

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
	dev = 0.3, mod = 0.25|
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
	sig = RoundPan.ar(~canto.numChan ? 4, sig, Rand(-0.05,0.05) + pan);
	env = Env([1,1,0], [sustain * sharpness.linlin(16,32,1,0.01).clip(0.01,1), 0.1]).ar(2);
	sig = RemoveBadValues.ar(sig);
	OffsetOut.ar( 0, sig * env * amp );
}).load(s);
);

(
SynthDef( "canto_note2", { |amp = 0.1, sustain = 1, damp = 16, freq = 440, dev = 0.0075, sharpness = 2, pan = 0, mfreq = 1, mamt = 0, mod = 0.25|
	var sig, envs, env, n=5;
	var amps, cutenv;
	mod = mod * 0.25;
	sig = Pulse.ar( (freq * 0.5) + ([-0.5,0.5]), 
		LFDNoise1.kr(0.25.dup).range(0.01,0.99)
		//TRand.kr(0.dup,1,In.kr(1) )
	).sum;
	sig = sig + GrayNoise.ar(0.1);
	
	//sig = sig ring1: SinOsc.ar( LFDNoise1.kr( 20 ).exprange(1000,6000), 0, 0.75);
	//freq = TExpRand.kr(0.25,1,In.kr(1) ).lag(0.05) * freq;
	
	//freq = freq * Trig1.kr( In.kr(1), 0.02 ).lag(0,0.5).linexp(0,1,0.4,1);
	
	//freq = LFDNoise3.kr(0.05.dup(5))
	
	cutenv = Line.kr( sharpness.linlin(18,32,1,32), sharpness.linlin(18,32,1,8), sustain );
	
	sig = BLowPass.ar( sig, (
		freq.blend( 
			LFDNoise3.kr(0.1).exprange( 40,100 ), 0.1) 
				* sharpness.linlin(1,15,32,1)
				* cutenv
				* SinOsc.kr( 1/sustain, 0.5pi, mod, 1 );
			//SinOsc.kr( mfreq, 0, mamt )
		)
		.clip(20,20000), 0.125 );
	//sig = (sig / 4).softclip * 4;
	
	sig = BLowCut.ar( sig, (freq * (cutenv / 2)).clip(20,20000), 3 );
	sig = sig * Line.kr( 1, sharpness.linlin(17,32,1,0.1), sustain );

	sig = RoundPan.ar( ~canto.numChan ? 4, sig, Rand(-0.05,0.05) + pan);
	env = Env([0,1,1,0], [0.01, sustain * 1.2, 0.1]).kr(2);
	//Poll.kr( Impulse.kr(10), sharpness );
	sig = RemoveBadValues.ar(sig);
	OffsetOut.ar( 0, sig * env * amp * 1 );
}).load(s);
);

(
SynthDef( "canto_note3", { |amp = 0.1, sustain = 1, damp = 16, freq = 440, dev = 0.0075, sharpness = 2, pan = 0|
	var sig, envs, env, n=5;
	var noise;
	var amps;
	noise = GrayNoise.ar(0.5) * Env.perc( 0.01, sustain * 0.1 ).kr;
	noise = BLowCut.ar( noise, freq, 4);
	noise = OnePole.ar(noise, 0.95 );
	sig = CombL.ar( noise, 1/50, 1/freq, 0.75 );
	//sig = Pulse.ar( freq * 0.5, LFDNoise1.kr(0.25).range(0,1) );
	sig = BLowPass.ar( sig, (freq * (33 - sharpness)).clip(20,20000), 0.125 );
	sig = RoundPan.ar(~canto.numChan ? 4, sig, Rand(-0.05,0.05) + pan);
	env = Env([0,1,1,0], [0.01, sustain, 0.01]).kr(2);
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

~canto.defNames = [ 'canto_note2', 'canto_note', 'canto_hihat' ];

~canto.instruments = 'canto_note'!14;

~canto.instruments[4] = 'canto_hihat';
~canto.instruments[10] = 'canto_note2';

~canto.playNote = { |evt, track = 0, nn = 64, sustain = 1, amps, pan = 0, damp = 4, sharpness = 2, amp = 0.1, mod = 0|
	if(  evt.instruments[ track ].asSymbol === 'canto_note' ) {
		Synth( evt.instruments[ track ], [ freq: nn.midicps, sustain: sustain,  pan: pan, amp: amp, 
			damp: damp, sharpness: sharpness, mod: mod, amps: amps ? (1!5) ] );
	} {
		Synth( evt.instruments[ track ], [ freq: nn.midicps, sustain: sustain,  pan: pan, amp: amp, 
			damp: damp, sharpness: sharpness, mod: mod ] );
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

~canto.pan = { Pbrown(-2.0,2.0,0.1).wrap(-1,1).asStream ! 5 }!13;

~canto.mod = 0.0!13;


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
			(pos-time).wait;
			s.makeBundle( 0.1 + (0.00001.rand), { 
				evt.playNote( track, note[4], note[6] / TempoClock.tempo, 
					evt.amps[ track ][(pos * 5).round(1)].collect(_.value),
					evt.pan[ track ][(pos * 5).round(1)].collect(_.value),
					evt.damp[ track ][(pos * 5).round(1)].collect(_.value),
					evt.sharpness[ track ].value,
					evt.amp[ track ].value,
					evt.mod[ track ].value
				);
			});
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
					evt.tracks.do({ |track|
						evt.playBar( track, evt.bar, evt.currentCell, variant );
					});
				};
				1.wait;
				evt.bar = ((evt.bar + 1) % dur).floor;
				if( evt.bar == 0 ) { 
					if( evt.currentCell.notNil && { evt.currentCell.bridge }) { 
						evt.currentIndex = evt.currentIndex + 1 
					};
					evt.currentCell = evt.cells[ evt.currentIndex ];
					if( evt.currentCell.notNil ) { dur = evt.currentCell.duration; };
					variant = 0; // first
				} {
					variant = 1; // second
				};
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