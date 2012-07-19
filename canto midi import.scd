(
~canto = ~canto ? EM();

//~canto.mf = SimpleMIDIFile.read( "/Users/woutersnoei/Dropbox/Work/gwyneth/canto_1-9.mid" );

~canto.mf = SimpleMIDIFile.read( thisProcess.nowExecutingPath.dirname +/+ "Canto short 9.mid" );


~canto.mf.timeMode = \seconds;

/* 
midi file format:
- each loop only once (no repeats)
- cc 1 at start of bar, value indicates cell number
- cc 2 is used for non-number cell names (~canto.specialNames)
- cc 3 is used for sub-sections of the loops. It decides when a section is played
	- cc 3, value 1: played the first time the cell plays (before first repetition)
	- cc 3, value 2: played the second time the cell plays (if absent, the first is used)
	- cc 3, value 3: played the last time before switching to a next cell (if absent, the second is used)
	- there must be either at least 2 of these in a cell, or none. Having only one of them doesn't make sense
	- Example:
	
	       (9) <- cell number
		||:                  | 1st repetition    :|| 2nd (=last) repetition |
		||: cc1,9            | cc3,1             :|| cc3,3                  |
*/

(
~canto.cells = []; 
/* [ (
	id: <cell number (Symbol)>, 
	startTime: <startTime in midifile (s)>, 
	duration: <duration of cell (s)>, 
	bridge: true|false, // bridge doesn't repeat
	notes: [ <notes main> ], 
	notesSecond: [ <notes second and later repeats (optional)> ], 
	notesEnd: [ <notes last repeat (optional)> ]
), ... ] 
*/

~canto.specialNames = ( // cc2
	0 + 128: '13a',
	1 + 128: '14a',
	2 + 128: '15a',
	3 + 128: '32a',
	4 + 128: '34a',
	5 + 128: '56a',
	6 + 128: '78a',
	7 + 128: '78b',
	8 + 128: '78c',
);

~canto.bridges = [ 7, '13a', '14a', '15a', 18, 21, 26, 27, 28, 29, '32a', '34a', 75, 76, 77, 79, 80, 85 ]
	.collect(_.asSymbol);

~canto.mf.ccEvents(1).do({ |item| // cells are encoded as cc 1 messages
	~canto.cells = ~canto.cells.add( ( id: item[5], startTime: item[1], bridge: false ) );
});

~canto.mf.ccEvents(2).do({ |item| // extra cells are encoded as cc 2 messages
	~canto.cells = ~canto.cells.add( ( id: item[5] + 128, startTime: item[1], bridge: false ) );
});

~canto.cells = ~canto.cells.sort({ |a,b| a.startTime <= b.startTime });

~canto.getCellStartEnd = { |evt, cell = 1|
	var start, end;
	cell = cell.asSymbol;
	start = evt.cells.detect({ |item| item.id == cell });
	if( start.notNil ) { start = start.startTime } { start = 0 };
	end = evt.cells.detect({ |item| item.startTime > start });
	if( end.notNil ) { end = end.startTime } { end = evt.mf.length };
	[ start, end].round(0.01);
};

~canto.getNotesFromMF = { |evt, start, end, offset = 0|
	// [ track, (relative) start, 'noteOn', cc, nn, velo, duration, upvelo ]
	start = start ? 0;
	end = end ? inf;
	evt.mf.noteSustainEvents.select({ |item|
		(item[1] >= start) && { item[1] < end };
	}).collect({ |item|
		[item[0], item[1] + offset - start] ++ item[2..];
	});
};

~canto.cc3Events = ~canto.mf.ccEvents(3);

~canto.getCC3 = { |evt, start, end|
	// [ [ startTime, value, endTime ], ... ]
	// value 1: main/first repeat
	// value 2: second repeat
	// value 3: last repeat
	var cc3s;
	start = start ? 0;
	end = end ? inf;
	cc3s = evt.cc3Events.select({ |item|
		(item[1] >= start) && { item[1] < end };
	}).collect({ |item|
		[(item[1] - start), item.last];
	}).sort({ |a,b|
		a[0] <= b[0];
	});
	cc3s.do({ |item, i|
		cc3s[i] = item.add( (cc3s[i+1] ?? { [ end - start ] })[0] );
	});
};

~canto.cells.do({ |item, i|
	var startEnd, segments, commonNotes, mainSegment, sort, makeMF;
	item.id = (~canto.specialNames[ item.id ] ? item.id).asSymbol; // convert cell name
	if( ~canto.bridges.includes( item.id ) ) { item.bridge = true }; // set non-repeating cells
	startEnd = ~canto.getCellStartEnd( item.id ); // get cell area in midifile
	item.cc3 = ~canto.getCC3( *startEnd ); // get subsection data (cc3)
	
	makeMF = { |notes|
		var mf;
		mf = SimpleMIDIFile().init1( 13, 75, "10/16").timeMode_(\seconds);
		notes.do({ |note|
			mf.addNote( *(note[[ 4, 5, 1, 6, 7, 3, 0]] ++ [false]) );
		});
		mf.sortMIDIEvents;
		mf.adjustEndOfTrack;
		mf;
	};
	if( item.cc3.size == 0 ) { 
		// no subsections
		item.duration = startEnd[1] - startEnd[0];
		item.notes = ~canto.getNotesFromMF( *startEnd );
	} {
		// analyze subsections:
		segments = ();
		sort = { |array|
			array.sort({ |a,b|
				case { a[0] < b[0] } { true } { a[0] == b[0] } { a[1] <= b[1] } { false }; 
			})
		};
		segments.common = [0, item.cc3.flop[0].sort.first];
		item.cc3.do({ |itemx|
			switch( itemx[1],
				1, { segments.main = (itemx[[0,2]] + item.startTime) ++ [segments.common.last]  },
				2, { segments.second = (itemx[[0,2]] + item.startTime) ++ [segments.common.last] },
				3, { segments.end = (itemx[[0,2]] + item.startTime) ++ [segments.common.last] }
			);
		});
		segments.common = segments.common + item.startTime;
		commonNotes = ~canto.getNotesFromMF( *segments.common );
		mainSegment = segments.main ? segments.second ? segments.end ? [0,0];
		item.notes = sort.( commonNotes ++ ~canto.getNotesFromMF( *mainSegment ) );
		if( segments.second.notNil ) {
			item.notesSecond = sort.( commonNotes ++ ~canto.getNotesFromMF( *segments.second ) );
			item.mfSecond = makeMF.(item.notesSecond);
		};
		if( segments.end.notNil ) {
			item.notesEnd = sort.( commonNotes ++ ~canto.getNotesFromMF( *segments.end ) );
			item.mfEnd = makeMF.(item.notesEnd);

		};
		item.segments = segments;
		item.duration = (segments.common[1] - segments.common[0]) + (mainSegment[1] - mainSegment[0]);
	};
	item.mf = makeMF.(item.notes);
});
);

)

/*
~canto.cells.do({ |item| item.segments.postln }); "";
~canto.cells.do({ |item| item.duration.postln }); "";

~canto.getCC3(0,24)

~canto.getNotesFromMF( *[0,12] );

.play

~canto.current = 2;

(
{
var cell;
loop {
	cell = ~canto.cells.detect({ |item| item.id == ~canto.current.asSymbol });
	cell.mf.play;
	cell.postln;
	cell.duration.postln.wait;
};
}.fork;
)

*/

