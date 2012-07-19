(

~canto.loopBuffers = Order();
~canto.loopSynths = Order();

~canto.latency =  ~canto.latency ? (1024 + 64)/44100;

~canto.catchLoop = { |evt|
	var buffer, index;
	{
		index = ~canto.currentIndex;
		buffer = Buffer.alloc(s, 44100 * (~canto.ddur ? 2) / TempoClock.tempo, 1 );
		~canto.loopBuffers[index] =  ~canto.loopBuffers[index].add( buffer );
		s.sync;
		~canto.recbuf.catch( buffer, 0, { "done".postln }, 0.25 );
		s.makeBundle( 0.45, { 
			~canto.loopSynths[index] =  ~canto.loopSynths[index].add(
				 Synth( "canto_playbuf", [ 
					\bufnum, buffer, 
					\offset, 0.25 + ~canto.latency
				] ++ evt.loopSettings.getPairs )
				.freeAction_({ |synth| 
					~canto.loopSynths[index].remove( synth );
					buffer.free;
					~canto.loopBuffers[index].remove( buffer );
				});
			);
		});
	}.fork( SystemClock );
	buffer;
};

(
SynthDef( "canto_playbuf", { |bufnum = 0, amp = 0.5, offset = 0, gate = 1,
		lowCut = #[20,20], hiCut = #[20000, 20000], pwidth = 0.25|
	var sig, env, trig;
	
	trig = In.kr(1);
	
	sig = PlayBuf.ar( 1, bufnum, startPos: offset * SampleRate.ir, loop: true );
	
	sig = BLowCut.ar( sig, TExpRand.kr( lowCut[0], lowCut[1], trig ).lag(0.1), 3 );
	sig = BHiCut.ar( sig, TExpRand.kr( hiCut[0], hiCut[1], trig ).lag(0.1), 3 );

	env = Env.asr(0.25,1,0.1).kr(2,gate);
	
	sig = RoundPan.ar( 2, sig, LFSaw.kr( LFDNoise1.kr(0.1) * 0.125 ) );
	
	
	Out.ar( 0, sig * amp );
}).load(s);
);


~canto.stopLoops = { |evt|
	evt.loopSynths.do({ |item| item.do(_.release) });
};

~canto.setLoops = { |evt ...what|
	evt.loopSynths.do({ |item| item.do(_.set(*what)) });
};

~canto.loopSettings.releaseDependants;

~canto.loopSettings = EM(
	\amp, 0.1,
	\lowCut, [20,20],
	\hiCut, [20000, 20000]
);

~canto.loopSettings.addDependant({ |evt, what|
	~canto.setLoops( what, evt[ what ] );
});

(
if( ~canto.loopWindow.notNil && { ~canto.loopWindow.isClosed.not } ) {
	~canto.loopWindow.close;
};

~canto.loopWindow = Window( "canto loops", Rect(500, 623, 264, 166) ).front;

~canto.loopWindow.addFlowLayout;

RoundView.useWithSkin( (font: Font( "Helvetica", 9 ) ),
	{
	var ctrl, filterSliders;
	
	ctrl = SimpleController( ~canto.loopSettings );
	
	SmoothButton( ~canto.loopWindow, 30@16 )
		.label_( [ "arm", "arm" ] )
		.hiliteColor_( Color.green )
		.value_( ~canto.recbuf.sn.notNil.binaryValue )
		.action_({ |bt|
			switch( bt.value, 
				1, {  ~canto.recbuf.start },
				0, {  ~canto.recbuf.end }
			);
		});
	
	SmoothButton( ~canto.loopWindow, 40@16 )
		.label_(  "catch" )
		.action_({ ~canto.catchLoop });
	
	SmoothButton( ~canto.loopWindow, 40@16 )
		.label_( [ "clear" ] )
		.action_({ ~canto.stopLoops });

	 ~canto.loopWindow.view.decorator.nextLine;
	 
	 [ 
	  \amp, \amp.asSpec,
	].pairsDo({ |key, spec|
		 var sl;
		 sl = EZSmoothSlider(  ~canto.loopWindow, 250@13, key, spec, 
		 	{ |sl|
			 	 ~canto.loopSettings.perform( key.asSetter, sl.value );
		 	}, ~canto.loopSettings[ key ] );
		 ctrl.put( key, { sl.value =  ~canto.loopSettings[ key ]; });
	 });
	 		
	[ 
	 	\lowCut, \freq.asSpec,
		\hiCut, \freq.asSpec
	].pairsDo({ |key, spec|
		 var sl;
		 sl = EZSmoothRanger(  ~canto.loopWindow, 250@13, key, spec, 
		 	{ |sl|
			 	 ~canto.loopSettings.perform( key.asSetter, sl.value );
		 	}, ~canto.loopSettings[ key ] );
		 ctrl.put( key, { sl.value =  ~canto.loopSettings[ key ]; });
	 });
	
	~canto.loopWindow.addToOnClose({ ctrl.remove; });
});

);

)

/*

~canto.stopLoops;

~canto.catchLoop;

~canto.loopSettings.amp = 0.5;

~canto.recbuf.start;

~canto.loopSynths.do({ |item| item.do(_.release) });

~canto.loopSynths.do({ |item| 
	item.do(_.set( \lowCut, [ 20, 20 ] ) );
});

~canto.loopSynths.do({ |item| 
	item.do(_.set( \hiCut, [ 20000, 20000 ] ) );
});

(
{
	var time;
	time = thisThread.seconds;
	b = Buffer.alloc(s, 44100 * (~canto.ddur ? 2) / TempoClock.tempo, 1 );
	s.sync;
	~canto.recbuf.catch( b, 0, { "done".postln }, 0.25 );
	s.makeBundle( 0.45, { a = Synth( "canto_playbuf", [ 
		\bufnum, b, 
		\offset, 0.25 - (512/44100) 
		] ) 
	});
}.fork( SystemClock );
)


*/