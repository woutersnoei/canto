~canto = ~canto ? EM();

thisProcess.slotPut( \openPorts, [] );
thisProcess.openUDPPort(9000);

~canto.makeRecvWindow = { |evt|
	var views, ctrl;
	
	evt.oscFuncs.do(_.remove);
	
	evt.rw = Window("canto", Rect(128, 64, 1400, 900) ).front;
	evt.rw.addFlowLayout;
	
	evt.rw.view.background = Color.black;
	
	views = ();
	
	evt.rw.asView.decorator.shift( 180, 100 );
	
	views[ \metro ] = SmoothButton( evt.rw, 270@270 )
		.label_( [ "", "" ] )
		.hiliteColor_( Color.yellow )
		.background_( Color.black.alpha_(0.1) )
		.border_(0)
		.value_(1)
		.canFocus_(false);
		
	evt.rw.asView.decorator.shift( 0, -100 );
		
	views[ \current ] = StaticText( evt.rw, 900@700 )
		.string_(
			evt.currentCell !? _.id ? "1";
		)
		.align_( \center )
		.font_( Font( Font.defaultSansFace, 600 ) )
		.stringColor_( Color.white );
		
	evt.rw.asView.decorator.nextLine;
	
	evt.rw.asView.decorator.shift( 0, -260 );
		
	views[ \beatbar ] = StaticText( evt.rw, 660@160 )
		.font_( Font( Font.defaultSansFace, 160 ) )
		.align_( \center )
		.string_( "1/4" )
		.stringColor_( Color.white );
		
	evt.oscFuncs = [
		OSCFunc( { |msg| { views[ \current ].string = msg[1].asString }.defer }, '/1/current' ),
		OSCFunc( { |msg| { views[ \beatbar ].string = msg[1].asString }.defer }, '/1/position' ),
		OSCFunc( { |msg| { views[ \metro ].value = msg[1] }.defer }, '/1/beat' ),
	];
		
	evt.rw.onClose_({
		evt.oscFuncs.do(_.free);
	});
	
};

~canto.makeRecvWindow;





