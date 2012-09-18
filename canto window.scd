(
~canto = ~canto ? EM();

// touchOSC clock
~canto.touchOSC = [ 
	NetAddr( "192.168.2.13", 9000 ), 
	NetAddr( "192.168.2.12", 9000 ),
	NetAddr( "192.168.2.11", 7800 )
];

// midi tap/clock
(
~canto.midiOut = MIDIOut(0, 
	MIDIClient.destinations.detect({ |item| 
		item.device.find( "face" ).notNil 
	}) !? _.uid ? 0
).latency_(0.1);
);

/* // monitor
~canto.midiOut = ( control: { |evt ...args| args.postln });
*/

~canto.sendMIDIOut = { |evt, cellID = 0, index = 0|
	evt.midiOut.control( 0, cellID, index );
};

~canto.makeWindow = { |evt|
	var views, ctrl;
	
	evt.w = Window("canto", Rect(300, 135, 258, 168) ).front;
	evt.w.addFlowLayout;
	
	views = ();
	
	views[ \start ] = SmoothButton( evt.w, 30@30 )
		.label_( ['power', 'power'] )
		.hiliteColor_( Color.green )
		.action_({ |bt|
			switch( bt.value.asInt,
				1, { evt.start },
				0, { evt.end }
			);
		})
		.canFocus_(false);
		
	evt.w.view.decorator.shift(30,0);
		
	views[ \return ] = SmoothButton( evt.w, 30@30 )
		.label_( ['return'] )
		.action_({ |bt|
			evt.currentIndex = 0;
		})
		.canFocus_(false);
		
	views[ \prev ] = SmoothButton( evt.w, 30@30 )
		.label_( ['rewind'] )
		.action_({ |bt|
			evt.currentIndex = (evt.currentIndex - 1).wrap( 0, evt.cells.size );
		})
		.canFocus_(false);
		
	views[ \next ] = SmoothButton( evt.w, 60@30 )
		.label_( ['forward'] )
		.action_({ |bt|
			evt.currentIndex = (evt.currentIndex + 1).wrap( 0, evt.cells.size );
		})
		.canFocus_(false);
	
	views[ \index ] = PopUpMenu( evt.w, 50@30 )
		.items_(
			evt.cells.collect(_.id) ++ [ \end ]
		)
		.value_( evt.currentIndex )
		.font_( Font( Font.defaultSansFace,18 ) )
		.action_({ |pu|
			evt.currentIndex = pu.value;
		})
		.canFocus_(false);
	
	evt.w.view.decorator.nextLine;
	
	evt.w.view.decorator.shift(1,23);
	
	views[ \metro ] = SmoothButton( evt.w, 35@35 )
		.label_( [ "", "" ] )
		.hiliteColor_( Color.yellow )
		.background_( Color.black.alpha_(0.1) )
		.border_(0)
		.canFocus_(false);
		
	evt.w.view.decorator.shift(-36,40);
	
	views[ \beatbar ] = StaticText( evt.w, 50@30 )
		.font_( Font( Font.defaultSansFace,18 ) );
	
	evt.w.view.decorator.shift(0,-63);
		
	views[ \current ] = StaticText( evt.w, 180@100 )
		.string_(
			evt.currentCell !? _.id ? "";
		)
		.align_( \center )
		.font_( Font( Font.defaultSansFace, 64 ) );
		
	views[ \tempo ] = EZSmoothSlider( evt.w, 250@20, "tempo", [50,70,\lin,0.1,60, "bpm"].asSpec )
		.value_( TempoClock.tempo * 60 )
		.action_({ |sl| TempoClock.tempo = sl.value/60 });
		
	views[ \tempo ].sliderView.canFocus_( false );
	views[ \tempo ].numberView.canFocus_( false );
	
		
	ctrl = SimpleController( evt )
		.put( \currentIndex, { 
			{ views[ \index ].value = evt.currentIndex }.defer(0.1) 
		})
		.put( \currentCell, { 
			{ views[ \current ].string = evt.currentCell !? _.id ? "" }.defer(0.1);
			~canto.touchOSC.asArray.do(
				_.sendMsg( "/1/current", (evt.currentCell !? _.id ? "").asString ) 
			);
		})
		.put( \bar, { 
			evt.ddur = evt.ddur ? 2;
			Task({
				var string, cellNr;
				evt.ddur = evt.currentCell !? _.duration ? evt.ddur;
				string = "%/%".format( evt.bar + 1, evt.ddur );
				~canto.touchOSC.asArray.do(_.sendMsg( "/1/beat", 1 ));
				~canto.touchOSC.asArray.do(_.sendMsg( "/1/position", string ));
				views[ \metro ].value = 1;
				 { views[ \beatbar ].string = string; }.defer(0.05);
				 cellNr = (evt.currentCell !? _.id ? "0").asString.extractNumbers[0] ? 0;
				 ~canto.sendMIDIOut( cellNr, 0 );
				 (2/5).wait;
				 ~canto.touchOSC.asArray.do(_.sendMsg( "/1/beat", 0 ));
				 views[ \metro ].value = 0;
			}).start;
			Task({
				~canto.sendMIDIOut.songPtr(0);
				24.do({
					~canto.sendMIDIOut.midiClock;
					(1/24).wait;
				});
			}).start;
			
		});
		
	evt.w.view.keyDownAction_({ |vw, char, mod, unicode, keycode|
		switch( keycode,
			123, { evt.currentIndex = (evt.currentIndex - 1).wrap( 0, evt.cells.size ); },
			124, { evt.currentIndex = (evt.currentIndex + 1).wrap( 0, evt.cells.size ); },
			49, { evt.start; views[ \start ].value = 1; }, // space bar
			51, { evt.currentIndex = 0; }, // backspace
			53, { evt.end; views[ \start ].value = 0; }); // escape
			
	});
		
		
	evt.w.onClose_({
		ctrl.remove;
	});
	
};

~canto.makeWindow;

)