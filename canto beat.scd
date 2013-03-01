~canto.beat = ~canto.beat ? EM();

~canto.beat.samplePaths = [
	"/Users/woutersnoei/Dropbox/Work/gwyneth/canto/samples/amen-brother-3-bars.wav"
];

~canto.beat.buffers = ~canto.beat.samplePaths.collect({ |path|
	Buffer.read(s, path);
});

~canto.beat.numBars = [ 3 ];

SynthDef("canto_beat", { |bufnum = 0, numBars = 3, rate = 1, div = 4, amp = 0.1, pos = #[0,1,2,3,4],
		hicut = 20000, lowcut = 20|
	var trigger, sig, on;
	trigger = In.kr(1);
	on = Peak.kr( trigger ) >= 1;
	//trigger = (Peak.kr( trigger ) >= 1) * trigger;
	trigger = (trigger * 5);
	rate = rate * (numBars * 2 * (4/5) / BufDur.kr( bufnum ));
	pos = LFDNoise1.kr( Rand( 0.05.dup(5), 0.5 ) ).range(0, (numBars * div * 2) + 5 ).round(1);
	pos = BufFrames.kr( bufnum ) * ((pos / 2) / (numBars * div));
	pos = Select.kr( 5 - Latch.kr(trigger, trigger), pos );
	trigger = TDuty.kr( Dstutter( 8, 
		Dwrand( 
			([ 1, 1/3, 1/4, 1/8, 1/16 ]/5) / rate, 
			[ 0.875,0.025,0.025,0.025, 0.01 ] 
		) 
	), trigger );
	sig = PlayBuf.ar( 2, bufnum, rate, trigger, pos ) * on;
	sig = BHiCut.ar( sig, hicut.lag(5), 3 );
	sig = BLowCut.ar( sig, lowcut.lag(5), 3 );
	Out.ar( 0, sig * amp );
}).load(s);

(
b.free; b = Synth( "canto_beat", [ 
	\bufnum, ~canto.beat.buffers[0], 
	\numBars, ~canto.beat.numBars[ 0 ],
	\amp, 0.15, 
	\rate, 60/57 
] );
)


b.set( \hicut, 4000 );
b.set( \hicut, 20000 );
b.set( \lowcut, 600 );
b.set( \lowcut, 20);

b.set( \rate, 30/57 );
b.set( \rate, 60/57 );

b.set( \pos, [0,1,2,3,22] );
b.set( \rate, 60/57 );

b.free;