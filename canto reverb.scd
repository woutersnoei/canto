
(
/// 4ch reverb
// luistert naar bus PrivateBus 0,1,2,3

//Server.default = Server.local;
//s = Server.default;

q = q ? EM();
q.verb = q.verb ? EM();

q.verb.font = Font( Font.defaultSansFace, 10 );

q.verb.active = 0;
q.verb.n = 4; // number of channels
q.verb.fftsize= 2048; 
q.verb.amp = 0.1;
q.verb.preDelay = 0;
q.verb.dur = 1.5;
q.verb.private = false;

q.verb.offset = 22; // eucon slider

(
SynthDef( "ws_verb%".format( q.verb.n ), { |in = 0, amp = 0.33, preDelay = 0, out = 0, 
		fftsize = 2048, private = 0, gate = 1, 
		hishelf = 1, hishelfFreq = 3000, lowshelf = -3, lowshelfFreq = 400, leak = 0.05|
	var bufs = \bufs.ir( 0!q.verb.n );
	var input, sig, env;
	env = Env([0,1,1,0,0], [0.1,0,0.1, BufDur.ir( bufs[0] ) + preDelay ], \lin, 2 ).kr(2, gate );
	input = In.ar( 0 + (FirstPrivateBus.ir * private), bufs.size );
	//CheckBadValues.ar( input );
	//input = input + WhiteNoise.ar(1.0e-9);
	input = RemoveBadValues.ar(input);
	input = input + (input.sum * leak ) * env * amp ;
	input = BHiShelf.ar( input, hishelfFreq, 1, hishelf );
	input = BLowShelf.ar( input, lowshelfFreq, 1, lowshelf );
	input = DelayC.ar(input, 0.25, preDelay );
	sig = bufs.collect({ |sp, i| 
		PartConv.ar(input[i], fftsize, sp, 0.5); 
	});
	
	Out.ar( 0, sig * 2 );
}).load(s);
);

(
SynthDef( "ws_verb%_sum".format( q.verb.n ), { |in = 0, amp = 0.33, preDelay = 0, out = 0, 
		fftsize = 2048, private = 0, gate = 1, hishelf = 0, hishelfFreq = 1200|
	var bufs = \bufs.ir( 0!q.verb.n );
	var input, sig, env;
	env = Env([0,1,1,0,0], [0.1,0,0.1, BufDur.ir( bufs[0] ) + preDelay ], \lin, 3 ).kr(2, gate );
	input = In.ar( 0 + (FirstPrivateBus.ir * private), bufs.size ).sum;
	input = input * env;
	input = BHiShelf.ar( input, hishelfFreq, 1, hishelf );
	input = DelayC.ar(input, 0.25, preDelay );
	sig = bufs.collect({ |sp, i| 
		PartConv.ar(input, fftsize, sp, 0.5); 
	});
	
	Out.ar( 0, sig * amp * 2 );
}).load(s);
);


q.verb.danStowel = {|evt| 
	var ir, f;
	//synthesise the honourable 'Dan Stowell' impulse response
	ir = ((0..evt.dur*44100).linlin(0,evt.dur*44100,1,0.125).collect{|f| f =
	f.squared.squared; f = if(f.coin){0}{f.squared}; f =
	if(0.5.coin){0-f}{f}  }) * (-27.dbamp);
};

q.verb.prepare = { |evt, action|
	
		evt.irspectrum.do( _.free );
		evt.irspectrum = nil;
		
		{
		q.verb.n.do({ |i|
			var ir, irbuffer, bufsize; 
		
			ir = q.verb.danStowel;
			irbuffer = Buffer.loadCollection(s,ir);
				
			s.sync;
			
			bufsize= PartConv.calcBufSize(evt.fftsize,irbuffer);
			//q.verb.numpartitions= PartConv.calcNumPartitions(q.verb.fftsize,irbuffer);
			
			evt.irspectrum = evt.irspectrum.add( Buffer.alloc(s,bufsize,1) );
			0.1.wait; // make sure it's allocated
			evt.irspectrum.last.preparePartConv(irbuffer, evt.fftsize);
			
			s.sync; 
			
			irbuffer.free; //don't need time domain data anymore, just needed spectral version
			});
		"prepare done".postln;
		action.value;
		}.fork;

};
		
q.verb.start = { |evt|  // doesn't check if already started !!
	evt.active = 1;
	evt.sn = Synth( "ws_verb%".format( evt.n ), [
		 		\amp, evt.amp, 
 		 		\preDelay, evt.preDelay,
 		 		\bufs, evt.irspectrum,
 		 		\fftsize, evt.fftsize,
 		 		\private, evt.private.binaryValue
 			 ], addAction: \addAfter );
	};

q.verb.end = { |evt|
	evt.active = 0;
	evt.sn.release; evt.sn = nil;
};


q.verb.cmdPeriod = { |evt| if( evt.active == 1 ) { { evt.start }.defer(0.1); } };
	
CmdPeriod.add( q.verb );

// window and views
q.verb.w = Window( "verb", Rect(146, 365, 113, 84)).front;
q.verb.w.addFlowLayout;
q.verb.views = ();


q.verb.w.onClose = { q.verb.sn.free; q.verb.sn = nil; CmdPeriod.remove( q.verb ); };

q.verb.views[ \prepare ] = RoundButton( q.verb.w, 70@16 )
	.states_([[ "prepare" ]])
	.font_( q.verb.font )
	.action_({ q.verb.prepare });

q.verb.views[ \power ] = RoundButton( q.verb.w, 16@16 )
	.states_([[ 'power' ], [ 'power', Color.black, Color.green(0.75).alpha_(0.75) ]])
	.action_({ |bt|
		switch( bt.value,
			1, { q.verb.start; },
	 		0, { q.verb.end; })
			});
			
q.verb.views[ \amp ] = SmoothSlider(  q.verb.w, 94@16 ).value_( q.verb.amp ? 0.33 )
	.action_({ |sl| 
		q.verb.amp = sl.value;
		q.verb.sn.set( \amp, q.verb.amp ); 
	});
			
StaticText( q.verb.w, 50@16 ).string_( "predelay" ).align_( \right ).font_( q.verb.font );
q.verb.views[ \preDelay ] = SmoothNumberBox( q.verb.w, 40@16 ).value_( q.verb.preDelay ? 0)
	.clipLo_( 0 ).clipHi_(0.25).step_(0.01).font_( q.verb.font )
	.action_({ |sl| 
		q.verb.preDelay = sl.value;
		q.verb.sn.set( \preDelay, q.verb.preDelay ); 
	});
				
StaticText( q.verb.w, 50@16 ).string_( "dur" ).align_( \right ).font_( q.verb.font );
q.verb.views[ \dur ] = SmoothNumberBox( q.verb.w, 40@16 ).value_( q.verb.dur ? 1.3 )
	.clipLo_( 0.1 ).clipHi_(5).scroll_step_(0.1).step_(0.1).font_( q.verb.font )
	.action_({ |nb| q.verb.dur = nb.value; });
	
q.verb.prepare({ q.verb.views.power.valueAction = 1; });
	
/*
if( e.notNil )
	{
		e.coupleSlider( 7, { |sl| q.verb.views.amp.valueAction = sl.value }, "verb" );
		e.actions.button.rec[7] = { |bt|  q.verb.views.power.valueAction = bt.value.asInt };		e.sliders[7].valueAction = q.verb.amp;
		e.buttons.rec[ 7].valueAction = 0;		
	};
*/

// now on NanoKONTROL fader 9

)