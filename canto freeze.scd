(

~canto = ~canto ? EM();

~canto.freeze1= ~canto.freeze1 ? EM();

( // synthdef
SynthDef( "canto_magpeakfreeze", { |t_clear = 0, modAmt = 0, out = 0, in=0, spd = 10, 
			amp = 0.1, gate = 1, lpf = 20000, hpf = 20, shift = 1, hishelf=(-6), inHPF = 150, inLPF = 10000, mixShift = 0.1, cutup = 0, cutdur = 0.1, fb = 0.5, mixImp = 0, impSpeed = 0.5|
		var t_trig, input, sig, peak, mag, chain1, chain2, output;
		var a,b,c, fftSize = 2048;
		var env, disp;
		var msamp, pan = 1;
		
		amp = amp.lag(3);
		
		env = Env.asr(0.5,1,2, -4).kr(2,gate+Impulse.kr(0));
		
		a = { LocalBuf( fftSize, 1 ).clear }!2; // stereo fft
		#b,c = { LocalBuf( fftSize, 1 ).clear }!2;
		
		//input = GrayNoise.ar( 1.dup );
		input = Splay.ar( 
			LFPulse.kr( 
				SinOsc.kr(({0.01 rrand: 0.1}!10), { 2pi.rand }!10).exprange(2,20), 0, 0.1 )
					.linlin(0,1,1-modAmt,1+modAmt)
				* BBandPass.ar( 
					GrayNoise.ar((0.1 * (1-mixImp)).dup(10)) + 
						SinOsc.ar( 
							SinOsc.kr( ({ 0.5 exprand: 2}!10) * impSpeed).exprange(20,20000),
							mul: mixImp * 0.2
						), 
					SinOsc.kr(({0.01 rrand: 0.1}!10), { 2pi.rand }!10).exprange(100,10000)
				)
			);
		
		/*
			* Decay.ar( Dust.ar( LFNoise2.kr(0.25.dup).exprange(0.1,5) * 500.dup, 1 ), 
					0.005 ).clip(0,1);
		*/
					
		input = BLowPass.ar( input, lpf.clip(20,20000) );
		input = BHiPass.ar( input, hpf.clip(20,20000) );
		
		//t_clear = Dust.kr( 0.1 ) + t_clear;
		
		sig = LPF.ar( HPF.ar( PrivateIn.ar( in ), inHPF.lag(0.5).clip(20,20000) ), inLPF.lag(0.5).clip(20,20000) );
		
		t_trig = Impulse.kr( spd ); // update speed
	
		chain1 = FFT( a, input);
		chain2 = FFT( b, sig );
		
		#peak, mag = FFTPeak.kr( chain2, 100, 20000 );
		
		peak = ((peak / 22050) * (fftSize/2)).floor * 2;
				
		Demand.kr( t_trig, 0, Dbufwr( 
			mag.max( 
				// LinXFade2.kr( mag, BufRd.kr( 1, c, peak, interpolation: 0 ), 0.5 )
				mag.blend( BufRd.kr( 1, c, peak, interpolation: 0 ), fb ) // new wslib!!
				),
			 c, peak ) );
			
		RecordBuf.ar( K2A.ar(0), c, loop: 0, trigger: t_clear );
				
		chain1 = PV_MagMul( chain1, c );
		output = IFFT(chain1) *8;
		
		output = CompanderD.ar(	output, output.mean,
			thresh: 1,
			slopeBelow: 1,
			slopeAbove: 0.1,
			clampTime: 0.1,
			relaxTime: 1
			);
			
		output = BHiShelf.ar( output, 3000, 1, hishelf );
		
		//output = TIRand.kr( 0.dup(2), 1, In.kr(1) ) * output;
		
		output = (output * (1-mixShift) ) 
			+ PitchShift.ar(output, 0.17, 2, 0.001, 0.17, 0.25 + mixShift );
		
		output = ((Trig1.kr(In.kr(1), cutdur) * cutup) + (1-cutup)) * output;
		
		pan = LFSaw.kr( LFDNoise3.kr(0.05) * 0.05 );
	
		output = output.collect({ |sig, i|
			RoundPan.ar( ~canto.numChan ? 4, sig, [-0.25,0.25][i] + pan );
		}).sum;
		
		output = RemoveBadValues.ar(output);
		
		Out.ar(out, output * amp * 0.5 * env );
	}).store;
);


[	
	\amp, 0.1,
	\fb, 0.5,
	\lpf, 20000,
	\hpf, 100,
	\cutup, 0,
	\cutdur, 0.5/5,
	\impSpeed, 0.01,
	\mixImp, 0,
	\modAmt, 0,
	\mixShift, 0,
].pairsDo({ |key,value|
	~canto.freeze1[ key ] = value;
	~canto.freeze1[ key.asSetter ] = { |evt, val|
		evt[ key ] = val ? value;
		evt.synth.set( key, val ? value);
	};
});

~canto.freeze1.start = { |evt|
	evt.end;
	evt.synth = Synth( "canto_magpeakfreeze", 
		evt.getPairs([ 'amp', 'fb', 'lpf', 'hpf', 'cutup', 'cutdur', 
			'impSpeed', 'mixImp', 'modAmt', 'mixShift' ])
	);
};

~canto.freeze1.end = { |evt|
	evt.synth.release;
	evt.synth = nil;
};

(
~canto.freeze1.iconnect = { |evt, index = 0|
	
	var cutspec, cutdurspec;
	var modAmtSpec;
	
	cutspec = ControlSpec(0,1, [0,0.999,1]);
	cutdurspec = ControlSpec(0,1, [0.101,0.1,0.01]);
	modAmtSpec = ControlSpec(0,1, [0,0.01,1]);
	
	
	e.actions.slider[index] = { |sl|
		~canto.freeze1.amp = \amp.asSpec.map( sl.value );
	};
	e.actions.knob[index] = { |sl|
		~canto.freeze1.cutup = cutspec.map( sl.value );
		~canto.freeze1.cutdur = cutdurspec.map( sl.value );
	};
	e.actions.slider[index+1] = { |sl|
		var lpf, hpf, width;
		width = (1-e.knobs[index+1].value) / 2;
		#hpf, lpf = sl.value.linlin( 0, 1,  0+width, 1-width) + [width.neg, width];
		~canto.freeze1.lpf = \freq.asSpec.map(lpf);
		~canto.freeze1.hpf = \freq.asSpec.map(hpf);
	};
	e.actions.knob[index+1] = { |sl|
		var lpf, hpf, width;
		width = (1 - sl.value) / 2;
		#hpf, lpf = e.sliders[index+1].value
			.linlin( 0, 1, 0 + width,  1 - width) + [width.neg, width];
		~canto.freeze1.lpf = \freq.asSpec.map(lpf);
		~canto.freeze1.hpf = \freq.asSpec.map(hpf);
	};
	
	e.actions.slider[index+2] = { |sl|
		~canto.freeze1.mixImp = sl.value;
		~canto.freeze1.modAmt = modAmtSpec.map(sl.value);
	};
	e.actions.knob[index+2] = { |sl|
		~canto.freeze1.mixShift = sl.value;
	};
	
	e.actions.button.rec[index] = { |bt|
		switch( bt.value.asInt,
			1, { ~canto.freeze1.start },
			0, { ~canto.freeze1.end }
		);
	};
	e.actions.button.on[index] = { |bt|
		if( bt.value.asInt == 1 ) {
			~canto.freeze1.synth.set( \t_clear, 1 );
			e.buttons.on[index].valueAction = 0;
		};
	};

	evt.ctrl.remove;
	evt.ctrl = SimpleController( evt )
		.put( \amp, { 
			e.active = false;
			e.sliders[index].valueAction = \amp.asSpec.unmap( evt.amp );
			e.active = true;
		})
		.put( \cutup, {
			e.active = false;
			e.knobs[index].valueAction = cutspec.unmap( evt.cutup );
			e.active = true;
		})
		.put( \synth, {
			e.active = false;
			e.buttons.rec[index].valueAction = evt.synth.notNil.binaryValue;
			e.active = true;
		})
		.put( \hpf, {
			var lpf, hpf, width, center;
			hpf = \freq.asSpec.unmap( evt.hpf );
			lpf = \freq.asSpec.unmap( evt.lpf );
			width = (lpf - hpf)/2;
			center = (hpf + width).linlin(0+width,1-width,0,1);
			e.active = false;
			e.sliders[index+1].valueAction = center;
			e.knobs[index+1].valueAction = 1-(width*2);
			e.active = true;
		})
		.put( \lpf, {
			var lpf, hpf, width, center;
			hpf = \freq.asSpec.unmap( evt.hpf );
			lpf = \freq.asSpec.unmap( evt.lpf );
			width = (lpf - hpf)/2;
			center = (hpf + width).linlin(0+width,1-width,0,1);
			e.active = false;
			e.sliders[index+1].valueAction = center;
			e.knobs[index+1].valueAction = 1-(width*2);
			e.active = true;
		})
		.put( \mixImp, {
			e.active = false;
			e.sliders[index+2].valueAction = evt.mixImp;
			e.active = true;
		});
		
		[ \amp, \cutup, \hpf ].do({ |item| evt.changed(item) });
};

if( e.notNil ) { ~canto.freeze1.iconnect( 0 ); };
);
	


(
if( ~canto.freeze1Window.notNil && { ~canto.freeze1Window.isClosed.not } ) {
	~canto.freeze1Window.close;
};

~canto.freeze1Window = Window( "canto freeze1s", Rect(860, 623, 264, 196) ).front;

~canto.freeze1Window.addFlowLayout;

RoundView.useWithSkin( (font: Font( "Helvetica", 9 ) ),
	{
	var ctrl, powerButton, filterSlider;
	
	ctrl = SimpleController( ~canto.freeze1 );
	
	powerButton = SmoothButton( ~canto.freeze1Window, 16@16 )
		.label_( [ 'power', 'power' ] )
		.hiliteColor_( Color.green )
		.value_( ~canto.freeze1.synth.notNil.binaryValue )
		.action_({ |bt|
			switch( bt.value, 
				1, {  ~canto.freeze1.start },
				0, {  ~canto.freeze1.end }
			);
		});
		
	ctrl.put( \synth, {
		powerButton.value = ~canto.freeze1.synth.notNil.binaryValue;
	});
	
	StaticText( ~canto.freeze1Window, 200@16 ).string_( "freeze1" );
	
	SmoothButton( ~canto.freeze1Window, 40@16 )
		.label_( [ "clear" ] )
		.action_({ |bt|
			~canto.freeze1.synth.set( \t_clear, 1 );
		});

	 ~canto.freeze1Window.view.decorator.nextLine;
			
	[ 
	  \amp, \amp.asSpec,
	  \fb, [0,1].asSpec,
	  \cutup, [0,1].asSpec,
	  \cutdur, [0.05/5,5/5].asSpec,
	  \impSpeed, [0.001,20,\exp].asSpec,
	  \mixImp, [ 0, 1 ].asSpec,
	  \modAmt, [0,1].asSpec,
	  \mixShift, [0,1].asSpec,
	 ].pairsDo({ |key, spec|
		 var sl;
		 sl = EZSmoothSlider(  ~canto.freeze1Window, 250@13, key, spec, 
		 	{ |sl|
			 	~canto.freeze1.perform( key.asSetter, sl.value );
		 	}, ~canto.freeze1[ key ] );
		 ctrl.put( key, { sl.value = ~canto.freeze1[ key ]; });
	 });
	 
	filterSlider = EZSmoothRanger(  ~canto.freeze1Window, 250@10, "filter", \freq.asSpec,
		 	{ |sl|
			 	
			 	~canto.freeze1.hpf = sl.value[0];
			 	~canto.freeze1.lpf = sl.value[1];
		 	}, [ ~canto.freeze1.hpf, ~canto.freeze1.lpf]  );
		 	
	ctrl.put( \hpf, { filterSlider.value =  [ ~canto.freeze1.hpf, filterSlider.value[1]] });
	ctrl.put( \lpf, { filterSlider.value =  [ filterSlider.value[0], ~canto.freeze1.lpf] });
	
	~canto.freeze1Window.addToOnClose({ ctrl.remove; });
});

);

)

/*

~canto.freeze1.start;
~canto.freeze1.end;

~canto.freeze1.lpf = 2000;

~canto.freeze1.mixShift = 1;

a = Synth( "canto_magpeakfreeze" );
a.set( \cutup, 0, \cutdur, 0.5/5 );

a.set( \cutup, 1, \cutdur, 0.5/5 );

a.set( \modAmt, 0 );
a.set( \mixShift, 0 );

a.set( \hpf, 200 );
a.set( \t_clear, 1 );

a.release;
*/