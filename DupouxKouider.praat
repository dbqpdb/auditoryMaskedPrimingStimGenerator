# TODO: Need to write header to data file.
# TODO: Need to figure out what data to write to the data file, clean up the user options (go for simple for this initial release)
# TODO: Warn if a target is incompletely masked.
# TODO: Notify in data file if any components had to be resampled.
# TODO: Test



# DupouxKouider.praat
# V0.9, pre-release

# Original concoction (adapted with modifications from D&K2005) by: Scott Jackson
# Modified 11 Aug 2012 by KTS
# Modified 25 Aug 2012 by KTS
# Modified 2013 by SW
# Modified 2016 by JG

# Rewritten Aug 2016 by db (brenner@ualberta.ca)
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#

# Constants that are unlikely to need changing often.
minResynthPitch = 75
maxResynthPitch = 600

# dB to attenuate masks and prime
quietness = 15

# Compression type & amount or fixed duration
compressionType$ = "ratio"
compressionValue = 0.35

# Sampling frequency
sr = 44100

# Duration of ramps on joining ends of concatenants.
concatenationRampDuration = 0.005

# Select and validate the input trial table
itemTableFile$ = chooseReadFile$: "Select tab-delimited trial table..."
if !fileReadable(itemTableFile$)
	exitScript: "No readable trial table selected. Did you expect me to make one up myself? Aborting."
endif

outputDataFile$ = chooseWriteFile$: "Choose output data file, dataphile...", "FileyMcFileface.txt"

writeInfoLine: "Checking out <", itemTableFile$, ">..."
itemTable = Read Table from tab-separated file: itemTableFile$
nRows = Get number of rows
nCols = Get number of columns
writeInfoLine: tab$, "The file has <", nCols, "> fields each for <", nRows, "> stimuli."

# Whether we're masking the stimuli or presenting them in the clear.
maskingFlag = 0
maskCompression
hasTargetCol = 0
hasPrimeCol = 0
hasItemNameCol = 0
hasCompressionRatioCol = 0
hasMaskCompressionRatioCol = 0
hasPrimeCompressionRatioCol = 0
hasMaskCompressionDurationCol = 0
hasPrimeCompressionDurationCol = 0
hasFwdMaskCol = 0
numBkwdMaskCols = 0
for c to nCols
	clab$ = Get column label: c
	if clab$ == "Target"
		hasTargetCol = 1
	elsif clab$ == "Prime"
		hasPrimeCol = 1
	elsif clab$ == "ItemName"
		hasItemNameCol = 1
	elsif clab$ == "DurationRatio" | clab$ == "CompressionRatio"
		hasCompressionRatioCol = 1
	elsif clab$ == "MaskCompressionRatio"
		hasMaskCompressionRatioCol = 1
	elsif clab$ == "PrimeCompressionRatio"
		hasPrimeCompressionRatioCol = 1
	elsif clab$ == "MaskCompressionDuration"
		hasMaskCompressionDurationCol = 1
	elsif clab$ == "PrimeCompressionDuration"
		hasPrimeCompressionDurationCol = 1
	elsif clab$ == "FwdMask"
		hasFwdMaskCol = 1
		maskingFlag = 1
	elsif index_regex$ (clab$, "^BkwdMask\d+$")
		numBkwdMaskCols = numBkwdMaskCols + 1
		maskingFlag = 1
	endif
endfor

# Tell the user if something's immediately awry
if !(hasTargetCol & hasPrimeCol & hasFileNameCol)
	exitScript: "Curses, foiled again! Can't proceed without targets, primes, and output item names. Must have columns \"Target\", \"Prime\", and \"ItemName\". Aborting."
endif

# Show a summary of the columns and make initial option guesses
appendInfoLine: Here are my guesses for what you're trying to do based on your trial table (you'll be able to change these in a moment):
appendInfoLine: tab$, "The input trial table seems to be in order. I've found the Target, Prime, and ItemName columns I need."

# Making simple prime-target stims only?
if maskingFlag
	appendInfoLine: "I see *Mask* columns, yeah?... Looks like we're doing masked priming."
else
	appendInfoLine: "I don't see any *Mask* columns. I guess we're making prime-target stimuli in the clear."
endif

if hasCompressionRatioCol & !hasMaskCompressionRatioCol

elsif hasCompressionRatioCol & has


# Select input and output directories
wavDir$ = chooseDirectory$: "Choose sound input file directory..."
outDir$ = chooseDirectory$: "Choose sound output directory..."

# Set defaults based on trial table columns, and then let the user over-ride using the form.

# Axe the user for necessary tidbits
form Processing choices
	comment: "Normalize input audio files to...?"
	comment: "Default is \"0\", for no normalization (not 0dB)."
	comment: "Nonzero values are interpreted as deciBel levels."
	comment: "Praat's normal default intensity scaling is to 70dB."
	# Edit the "0" in the following line to change the default value,
	# i.e. if you'd like it to normalize by default.
	real: "NormalizeTo_(dB)", 0

	comment: "How many backward masks should I expect for each item?"
	comment: "(enter 0 for no masking)"
	natural: "NumberOfBkwdMasks", 5

	comment: "Compress primes by ratio or to duration?"
	choice: "PrimeRatioOrDuration", 1
		option: "Compression ratio"
		option: "Resulting duration"

	comment: "Give the prime compression ratio or duration"
	comment: "(enter 0 to query each item using the trial table)"
	real: "PrimeCompressionRatioOrDuration", 0.35

	comment: "Compress masks by ratio or to a fixed duration?"
	choice: "PrimeRatioOrDuration", 1
		option: "Compression ratio"
		option: "Resulting duration"

	comment: "Give the mask compression ratio or duration"
	comment: "(enter 0 to query each individual item using the trial table)"
	real: "MaskCompressionRatioOrDuration", 0.35
endform

# At this point, all settings are specified.

# Write the header to the output data file.
writeFileLine: outputDataFile$, 

# Start main loop
for currentItem to nRows

	# Assign component names
	selectObject: itemTable
	itemName$ = Get value: currentItem, "ItemName"
	fwmName$ = Get value: currentItem, "FwdMask"
	primeName$ = Get value: currentItem, "Prime"
	targetName$ = Get value: currentItem, "Target"
	for bwmIndex to numberOfBkwdMasks
		bwmName$[bwmIndex] = Get value: currentItem, "BkwdMask" + string$(bwmIndex)
	endfor

	# Read component files and confirm mono
	fwmTemp = Read from file: wavDir$ + "/" + fwdMaskName$ + ".wav"
	fwm = Convert to mono
	removeObject: fwmTemp
	this_sr = Get sampling frequency
	if this_sr != sr
		fwmTemp = fwm
		fwm = Resample: sr, 50
		removeObject: fwmTemp
	endif

	primeTemp = Read from file: wavDir$ + "/" + primeName$ + ".wav"
	prime = Convert to mono
	removeObject: primeTemp
	this_sr = Get sampling frequency
	if this_sr != sr
		primeTemp = prime
		prime = Resample: sr, 50
		removeObject: primeTemp
	endif

	targetTemp = Read from file: wavDir$ + "/" + targetName$ + ".wav"
	target = Convert to mono
	removeObject: targetTemp
	this_sr = Get sampling frequency
	if this_sr != sr
		targetTemp = target
		target = Resample: sr, 50
		removeObject: targetTemp
	endif

	for bwmIndex to numberOfBkwdMasks
		bwmTemp[bwmIndex] = Read from file: wavDir$ + "/" + bkwdMaskName$[bwmIndex] + ".wav"
		bwm[bwmIndex] = Convert to mono
		removeObject: bwmTemp[bwmIndex]
		this_sr = Get sampling frequency
		if this_sr != sr
			bwmTemp[bwmIndex] = bwm[bwmIndex]
			bwm[bwmIndex] = Resample: sr, 50
			removeObject: bwmTemp[bwmIndex]
		endif
	endfor

	# Normalize if normalizing,
	# attenuate if attenuating,
	# reversate if reversating
	if normalizeTo
		# 'normalizeTo' is the intensity normalization
		# value specified if normalizing (or 0 for no
		# normalization). 'quietness' is the amount to
		# attenuate.

		# For masks, attenuate and reverse
		selectObject: fwm
		Scale intensity: normalizeTo - quietness
		Reverse
		@compressDuration: fwm
		fwm = compressDuration.compressed

		# For prime, attenuate intensity, but no
		# reversal
		selectObject: prime
		Scale intensity: normalizeTo - quietness
		@compressDuration: prime
		prime = compressDuration.compressed

		# For target, normalize only; no attenuation.
		selectObject: target
		Scale intensity: normalizeTo

		# For masks, attenuate and reverse
		for bwmIndex to numberOfBkwdMasks
			selectObject: bwm[bwmIndex]
			Scale intensity: normalizeTo - quietness
			Reverse
			@compressDuration: bwm[bwmIndex]
			bwm[bwmIndex] = compressDuration.compressed
		endfor
		
	else
		# If not normalizing (i.e. 'normalizeTo' == 0)
		# use the original intensity, and subtract
		# 'quietness'
		selectObject: fwm
		db = Get intensity (dB)
		Scale intensity: db - quietness
		Reverse
		@compressDuration: fwm
		fwm = compressDuration.compressed

		# prime, attenuate and compress, but no reversal
		selectObject: prime
		db = Get intensity (dB)
		Scale intensity: db - quietness
		@compressDuration: prime
		prime = compressDuration.compressed

		# No intensity manipulation for target
		# if not normalizing; no reversal or compression.

		# Masks, attenuate, reverse, compress
		for bwmIndex to numberOfBkwdMasks
			selectObject: bwm[bwmIndex]
			db = Get intensity (dB)
			Scale intensity: db - quietness
			Reverse
			@compressDuration: bwm[bwmIndex]
			bwm[bwmIndex] = compressDuration.compressed
		endfor
	endif

	# Concatenate the pieces
	@cat: fwm, prime
	frontEnd = cat.catted
	selectObject: frontEnd
	frontDur = Get total duration
	@cat: frontEnd, target
	frontEnd = cat.catted

	backEnd = Create Sound from formula: "silence", 1, 0, frontDur, 
	for bwmIndex to numberOfBkwdMasks
		@cat: backEnd, bwm[bwmIndex]
		backEnd = cat.catted
	endfor 

	# The final output stimulus
	selectObject: frontEnd, backEnd
	stimStereo = Combine to stereo
	stim = Convert to mono
	removeObject: frontEnd, backEnd, stimStereo
	# Scale final intensity to global spec.
	if normalizeTo
		Scale intensity: normalizeTo
	endif

	# Write stim to WAV and data to the output file
	Write to WAV file: outDir$ + "/" + itemName$ + ".wav"
	appendFileLine: outputDataFile$,  

endfor
appendInfoLine: "So long, and thanks for all the files!"



#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
#~#~#~#~#~#~#~#~#~# Old Stuff #~#~#~#~#~#~#~#~#~#
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#

	currentTarget = selected ("Sound")
	fwdMaskPiece = Read from file: wavDir$ + fwdMaskName$ + ".wav"
	Copy... fwdmask

	tempFwdMask = selected ("Sound")

	startdB = Get intensity (dB)

	quietdB = startdB - 15

	Scale intensity... 'quietdB'

	# Create manipulation and index it

	To Manipulation... 0.01 'min_pitch_for_resynthesis' 'max_pitch_for_resynthesis'

	manipulationIdent = selected ("Manipulation")	



	# Extract duration tier and index it

	Extract duration tier

	durationtierIdent = selected ("DurationTier")



	#Add new duration point at specified ratio

	select durationtierIdent

	Add point... 0.01 0.35



	# Do resynthesis

	select durationtierIdent

	plus manipulationIdent

	Replace duration tier

	select manipulationIdent

	Get resynthesis (overlap-add)



	# Rename new sound and index it

	Rename... fwdmask

	currentFwdMask = selected ("Sound")

	

	# Clean up (remove manipulation and duration tier objects)

	select durationtierIdent

	plus manipulationIdent

	plus tempFwdMask

	Remove



	#Read from file... 'sound_file_folder$'\'primeName$'.wav

	Read from file... 'sound_file_folder$''primeName$'.wav

	primePiece = selected ("Sound")

	# select Sound 'primeName$'

	Copy... prime

	tempPrime = selected ("Sound")

	startdB = Get intensity (dB)

	quietdB = startdB - 15

	Scale intensity... 'quietdB'

	# Create manipulation and index it

	To Manipulation... 0.01 'min_pitch_for_resynthesis' 'max_pitch_for_resynthesis'

	manipulationIdent = selected ("Manipulation")	



	# Extract duration tier and index it

	Extract duration tier

	durationtierIdent = selected ("DurationTier")



	# Add new duration point at specified ratio

	select durationtierIdent

	Add point... 0.01 'newDurationRatio'



	# Do resynthesis

	select durationtierIdent

	plus manipulationIdent

	Replace duration tier

	select manipulationIdent

	Get resynthesis (overlap-add)



	# Rename new sound and index it

	Rename... prime

	currentPrime = selected ("Sound")

	

	# Clean up (remove manipulation and duration tier objects)

	select durationtierIdent

	plus manipulationIdent

	plus tempPrime

	Remove




	#Read from file... 'sound_file_folder$'\'bkwdMask4Name$'.wav

	Read from file... 'sound_file_folder$''bkwdMask4Name$'.wav

	bkwdMask4Piece = selected ("Sound")

	# select Sound 'bkwdMask4Name$'

	Copy... bkwdmask4

	tempBkwdMask4 = selected ("Sound")

	startdB = Get intensity (dB)

	quietdB = startdB - 15

	Scale intensity... 'quietdB'

	# Create manipulation and index it

	To Manipulation... 0.01 'min_pitch_for_resynthesis' 'max_pitch_for_resynthesis'

	manipulationIdent = selected ("Manipulation")	



	# Extract duration tier and index it

	Extract duration tier

	durationtierIdent = selected ("DurationTier")



	# Add new duration point at specified ratio

	select durationtierIdent

	Add point... 0.01 0.35



	# Do resynthesis

	select durationtierIdent

	plus manipulationIdent

	Replace duration tier

	select manipulationIdent

	Get resynthesis (overlap-add)



	# Rename new sound and index it

	Rename... bkwdmask4

	currentBkwdMask4 = selected ("Sound")

	

	# Clean up (remove manipulation and duration tier objects)

	select durationtierIdent

	plus manipulationIdent

	plus tempBkwdMask4

	Remove



	#Read from file... 'sound_file_folder$'\'bkwdMask3Name$'.wav

	Read from file... 'sound_file_folder$''bkwdMask3Name$'.wav

	bkwdMask3Piece = selected ("Sound")

	# select Sound 'bkwdMask3Name$'

	Copy... bkwdmask3

	tempBkwdMask3 = selected ("Sound")

	startdB = Get intensity (dB)

	quietdB = startdB - 15

	Scale intensity... 'quietdB'

	# Create manipulation and index it

	To Manipulation... 0.01 'min_pitch_for_resynthesis' 'max_pitch_for_resynthesis'

	manipulationIdent = selected ("Manipulation")	



	# Extract duration tier and index it

	Extract duration tier

	durationtierIdent = selected ("DurationTier")



	# Add new duration point at specified ratio

	select durationtierIdent

	Add point... 0.01 0.35



	# Do resynthesis

	select durationtierIdent

	plus manipulationIdent

	Replace duration tier

	select manipulationIdent

	Get resynthesis (overlap-add)



	# Rename new sound and index it

	Rename... bkwdmask3

	currentBkwdMask3 = selected ("Sound")

	

	# Clean up (remove manipulation and duration tier objects)

	select durationtierIdent

	plus manipulationIdent

	plus tempBkwdMask3

	Remove



	#Read from file... 'sound_file_folder$'\'bkwdMask2Name$'.wav

	Read from file... 'sound_file_folder$''bkwdMask2Name$'.wav

	bkwdMask2Piece = selected ("Sound")

	# select Sound 'bkwdMask2Name$'

	Copy... bkwdmask2

	tempBkwdMask2 = selected ("Sound")

	startdB = Get intensity (dB)

	quietdB = startdB - 15

	Scale intensity... 'quietdB'

	# Create manipulation and index it

	To Manipulation... 0.01 'min_pitch_for_resynthesis' 'max_pitch_for_resynthesis'

	manipulationIdent = selected ("Manipulation")	



	# Extract duration tier and index it

	Extract duration tier

	durationtierIdent = selected ("DurationTier")



	# Add new duration point at specified ratio

	select durationtierIdent

	Add point... 0.01 0.35



	# Do resynthesis

	select durationtierIdent

	plus manipulationIdent

	Replace duration tier

	select manipulationIdent

	Get resynthesis (overlap-add)



	# Rename new sound and index it

	Rename... bkwdmask2

	currentBkwdMask2 = selected ("Sound")

	

	# Clean up (remove manipulation and duration tier objects)

	select durationtierIdent

	plus manipulationIdent

	plus tempBkwdMask2

	Remove



	#Read from file... 'sound_file_folder$'\'bkwdMask1Name$'.wav

	Read from file... 'sound_file_folder$''bkwdMask1Name$'.wav

	bkwdMask1Piece = selected ("Sound")

	# select Sound 'bkwdMask1Name$'

	Copy... bkwdmask1

	tempBkwdMask1 = selected ("Sound")

	startdB = Get intensity (dB)

	quietdB = startdB - 15

	Scale intensity... 'quietdB'

	# Create manipulation and index it

	To Manipulation... 0.01 'min_pitch_for_resynthesis' 'max_pitch_for_resynthesis'

	manipulationIdent = selected ("Manipulation")	



	# Extract duration tier and index it

	Extract duration tier

	durationtierIdent = selected ("DurationTier")



	# Add new duration point at specified ratio

	select durationtierIdent

	Add point... 0.01 0.35



	# Do resynthesis

	select durationtierIdent

	plus manipulationIdent

	Replace duration tier

	select manipulationIdent

	Get resynthesis (overlap-add)



	# Rename new sound and index it

	Rename... bkwdmask1

	currentBkwdMask1 = selected ("Sound")

	

	# Clean up (remove manipulation and duration tier objects)

	select durationtierIdent

	plus manipulationIdent

	plus tempBkwdMask1

	Remove



	# Reverse forward mask

	select 'currentFwdMask'

	Reverse



	# Concatenate forward mask with prime

	select 'currentFwdMask'

	plus 'currentPrime'

	Concatenate

	Rename... Part1

	part1 = selected ("Sound")



	# Concatenate & reverse 4 masks -> backward mask

	select currentBkwdMask4

	plus currentBkwdMask3

	plus currentBkwdMask2

	plus currentBkwdMask1



	Concatenate



	Rename... BkwdMaskAll

	Reverse

	bkwdMaskAll = selected ("Sound")

	

	# Add silence on the end of target to match length of backward mask

	select 'bkwdMaskAll'

	bkwdMaskLength = Get total duration



	select 'currentTarget'

	targetLength = Get total duration

	addLength = bkwdMaskLength - targetLength

	

	if addLength > 0

		Create Sound from formula... silence Mono 0 'addLength' 'sample_rate_of_stimuli' 0

		currentSilence = selected ("Sound")	

		select 'currentTarget'

		plus 'currentSilence'

		Concatenate

		Rename... newtarget

		newTarget = selected ("Sound")

		select 'bkwdMaskAll'

		Copy... NewBkwdMaskAll

		newBkwdMaskAll = selected ("Sound")

	else

		addLength = addLength * -1

		printline WARNING! mask for the target filename 'targetName$', item name 'itemName$' is 'addLength' seconds too short!

		printline The item will be created, but the target will not be completely masked.

		 

		Create Sound from formula... silence Mono 0 'addLength' 'sample_rate_of_stimuli' 0

		currentSilence = selected ("Sound")	

		select 'bkwdMaskAll'

		plus 'currentSilence'

		Concatenate

		Rename... NewBkwdMaskAll

		newBkwdMaskAll = selected ("Sound")

		select 'currentTarget'

		Copy... newtarget

		newTarget = selected ("Sound")

		

		newTargetLength = Get total duration

		select 'newBkwdMaskAll'

		newMaskLength = Get total duration

		

		printline The new mask length (with silence) equals: 'newMaskLength'

		printline The new target length (which should be the same) equals: 'newTargetLength'

		

		

	endif

	

	# Combine target and backward mask as stereo

	select 'newTarget'

	plus 'newBkwdMaskAll'

	Combine to stereo

	Rename... stereoPart2

	stereoPart = selected ("Sound")

	

	# Convert stereo file to mono

	Convert to mono

	Rename... Part2

	part2 = selected ("Sound")



	# Concatenate two big parts

	select 'part1'

	plus 'part2'

	Concatenate

	Rename... 'itemName$'

	Save as WAV file... 'sound_output_folder$'\'itemName$'.wav

	Remove




	# Clean up

	select currentTarget

	plus currentPrime

	plus currentFwdMask

	plus currentBkwdMask1

	plus currentBkwdMask2

	plus currentBkwdMask3

	plus currentBkwdMask4

	plus bkwdMaskAll

	plus currentSilence

	plus newTarget

	plus stereoPart

	plus part1

	plus part2

	# the following are the new clean-up steps

	plus targetPiece

	plus fwdMaskPiece

	plus primePiece

	plus bkwdMask4Piece

	plus bkwdMask3Piece

	plus bkwdMask2Piece

	plus bkwdMask1Piece

	Remove







	



#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
# Procedure definitions
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#

# Compress a sound object's duration using
# a ratio or specified duration
# The proc utilizes the global variable
# compressionType$ specifying "ratio" or
# "duration".
# This proc removes the input object after
# compression. The compressed object ID is
# stored in .compressed .
procedure compressDuration: .object
	selectObject: .object
	.origDur = Get total duration
	if compressionType$ == "duration"
		.ratio = compressionValue / .origDur
	elsif compressionType$ == "ratio"
		.ratio = compressionValue
	else
		exitScript: "Invalid compression type (global variable compressionType$). Valid values are ""duration"" or ""ratio""."
	endif
	.manip = To Manipulation: 0.01, 'minResynthPitch', 'maxResynthPitch'
	.durTier = Extract duration tier
	Add point: 0.00, .ratio
	plusObject: .manip
	Replace duration tier
	.compressed = Get resynthesis (overlap-add)
	removeObject: .manip, .durTier, .object
endproc

# Concatenate with ramping to avoid
# discontinuity pops
# .first is the first sound object,
# .second is the second
# This proc depends on the global variable
# "concatenationRampDuration" defined
# near the head of the file.
# This proc removes the two component
# objects. The concatenated sound
# object ID is stored in .catted .
procedure cat: .first, .second
	select: .second
	# Ramp the front end of .second
	Formula: "if x < 'concatenationRampDuration' then self * x/'concatenationRampDuration' else self fi"

	# Seem to need this wonky way of
	# doing it because Praat doesn't
	# pay any attention to the order
	# of selection, but only to the
	# order within the objects window.
	# In order to insure that the
	# second wav comes after the first,
	# we copy and create a new object
	# guaranteed to come last.
	.seccopy = Copy: "SecCopy"
	select: .first
	.firstdur = Get total duration
	# Ramp the back end of .first
	Formula: "if x > '.firstdur'-'concatenationRampDuration' then self * ('.firstdur'-x)/'concatenationRampDuration' else self fi"
	plusObject: .second
	.catted = Concatenate
	removeObject: .first, .second, .seccopy
endproc


