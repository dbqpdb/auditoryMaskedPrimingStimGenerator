# DupouxKouider.praat
# V0.9, testing release
# This script is run within Praat, not from the command line.
# It will prompt for an input tab-separated trial table
# and an output data file. It will read component
# sound files from the directory of the trial table,
# and write the output stimuli to the directory of the
# specified data file.

# Original concoction implemented, with modifications,
# from Dupoux & Kouider 2005 by Scott Jackson
# Modified 2012 by KTS
# Modified 2013 by SW
# Modified 2016 by JG

# Rewritten and documented Aug 2016
# by db (brenner@ualberta.ca)

# This software is provided with only the guarantee
# that I've tried my best to create good code for
# the purpose. Please send comments, bug reports,
# feature requests, suggestions to the email above. --db

# This software is provided under GNU General Public License:
#	https://www.gnu.org/licenses/gpl.html
# which means anyone is free to mess with this however
# they please, for any purpose, be it personal, commercial,
# spiritual, or whathaveyou.
# All derivative software must also bear this licensing.
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#

clearinfo

#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
# Default settings
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#

# Min and max pitch for "manipulate" and the
# PSOLA duration compression resynthesis
minResynthPitch = 75
maxResynthPitch = 600

# dB to attenuate masks and prime
quietness = 15

# Set ratioOrDuration to 1 to default to compression
# to a ratio, or set to 2 to default to compress to
# a fixed duration.
ratioOrDuration = 1
# Default ratio or duration
compressionValue = 0.35

# Sampling frequency
sr = 44100

# Duration of ramps on joining ends of concatenants.
catRampDur = 0.005

# Default intensity normalization
# Set to 0 for no normalization by default,
# or to some other value to make that the default
# normalization dB level.
normalizeTo = 0

#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
# I/O details
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#

# Select and validate the input trial table
itemTableFile$ = chooseReadFile$: "Select tab-delimited trial table..."
if !fileReadable(itemTableFile$)
	exitScript: "No readable trial table selected. Did you expect me to make one up myself? Aborting."
endif
wavDir$ = replace_regex$(itemTableFile$, "[^/]+$", "", 1)

itemTable = Read Table from tab-separated file: itemTableFile$
Rename: "TrialTable_" + itemTableFile$
nRows = Get number of rows
nCols = Get number of columns

# Take stock of the columns in the trial table.
hasTargetCol = 0
hasPrimeCol = 0
hasItemNameCol = 0
hasCompressionRatioCol = 0
hasCompressionDurationCol = 0
hasFwdMaskCol = 0
numBkwdMasks = 0
for c to nCols
	clab$ = Get column label: c
	if clab$ == "Target"
		hasTargetCol = 1
	elsif clab$ == "Prime"
		hasPrimeCol = 1
	elsif clab$ == "ItemName"
		hasItemNameCol = 1
	elsif clab$ == "FwdMask"
		hasFwdMaskCol = 1
	elsif index_regex (clab$, "^BkwdMask\d+$")
		numBkwdMasks = numBkwdMasks + 1
	endif
endfor

# Tell the user if something's immediately awry
if !(hasFwdMaskCol & hasPrimeCol & hasTargetCol & numBkwdMasks & hasItemNameCol)
	exitScript: "Curses! I can't proceed without forward masks, primes, targets, backward masks, and output item names. Must have columns ""FwdMask"", ""Prime"", ""Target"", ""BkwdMask1"", and ""ItemName"". Aborting."
endif

# Have the user select the output data file.
# Note: the file browser warns if the file already exists.
outputDataFile$ = chooseWriteFile$: "Choose output data file, dataphile...", "FileyMcFileface.txt"
outDir$ = replace_regex$(outputDataFile$, "[^/]+$", "", 1)

# Set default form choices based on trial table columns,
# and then let the user over-ride using the form.
# Axe the user for necessary tidbits
beginPause: "Options 1/2"
	comment: "Note: Input component sound files are expected"
	comment: "in the directory of the trial table you selected."

	comment: "Normalize input audio files to...?"
	comment: "Default is ""0"", for no normalization (not 0dB)."
	comment: "Nonzero values are interpreted as deciBel levels."
	comment: "Praat's standard intensity scaling is to 70dB."
	real: "NormalizeTo", normalizeTo

	comment: "How much (dB) shall I attenuate the intensity"
	comment: "of masks and primes?"
	real: "Quietness", 15

	comment: "How many backward masks should I expect for each item?"
	natural: "NumberOfBkwdMasks", numBkwdMasks

	# Change the number two lines down to 1 to make
	# the script default to 
	comment: "Compress primes and masks to ratio or duration?"
	choice: "RatioOrDuration", ratioOrDuration
		option: "Compression ratio"
		option: "Fixed duration"
endPause: "More options!", 1

# If the user said more backward masks than we
# found in the trial table, complain.
if numberOfBkwdMasks > numBkwdMasks
	exitScript: "You've specified " + numberOfBkwdMasks + " but I only find " + numBkwdMasks + " backward mask columns. Check that they are all of the form ""BkwdMaskX"" where X counts up the number of backward masks. E.g., ""BkwdMask1"", ""BkwdMask2"", ""BkwdMask3"", and so on. You have to have at least one, and they all need to have consecutive numbering, even the first one."
elsif numberOfBkwdMasks < numBkwdMasks
	numBkwdMasks = numberOfBkwdMasks
endif

if ratioOrDuration == 2
	compressionType$ = "duration"
else
	compressionType$ = "ratio"
endif

beginPause: "Options 2/2"
	comment: "Compression type: " + compressionType$
	comment: "Enter the compression " + compressionType$
	real: "CompressionValue", compressionValue

	comment: "How much time should I ramp the joining"
	comment: "ends of concatenants? Enter ""0"" for"
	comment: "no ramping."
	real: "CatRampDur", catRampDur

	comment: "Min pitch for the duration compression"
	comment: "resynthesis."
	real: "MinResynthPitch", minResynthPitch

	comment: "Max pitch for the duration compression"
	comment: "resynthesis."
	real: "MaxResynthPitch", maxResynthPitch

	comment: "Thanks for the deets!"
endPause: "Here we go...", 1

# Write the header to the output data file.
header$ = "TrialTable" + tab$ + "Date" + tab$ + "Item" + tab$ + "ForwardMask" + tab$ + "Prime" + tab$ + "Target" + tab$ + "BackwardMasks" + tab$ + "PrimeOnset" + tab$ + "TargetOnset" + tab$ + "TargetOffset" + tab$ + "BwmDur" + tab$ + "StimDur" + tab$ + "CompressType" + tab$ + "CompressValue" + tab$ + "SamplingRate" + tab$ + "ComponentsResampled" + tab$ + "Intensity" + tab$ + "CatRampDur" + tab$ + "MinPitch" + tab$ + "MaxPitch" + tab$ + "Quietness" + tab$ + "IsTargetCovered" + tab$ + "PropClippedSamples"
writeFileLine: outputDataFile$, header$

# Start stimulus loop
for currentItem to nRows
	# Log whether any components were resampled
	componentsResampled = 0

	# Assign component names
	selectObject: itemTable
	itemName$ = Get value: currentItem, "ItemName"
	# Tell the user what we're doing
	appendInfoLine: currentItem, "/", nRows, tab$, itemName$
	# Store the component file names
	fwmName$ = Get value: currentItem, "FwdMask"
	primeName$ = Get value: currentItem, "Prime"
	targetName$ = Get value: currentItem, "Target"
	for bwmIndex to numBkwdMasks
		bwmName$[bwmIndex] = Get value: currentItem, "BkwdMask" + string$(bwmIndex)
	endfor

	# Read component files, confirm mono
	# and check sampling rates
	fwm = Read from file: wavDir$ + "/" + fwmName$ + ".wav"
	@prepComponent: fwm
	fwm = prepComponent.id
	Rename: "fwm_" + fwmName$

	prime = Read from file: wavDir$ + "/" + primeName$ + ".wav"
	@prepComponent: prime
	prime = prepComponent.id
	Rename: "prime_" + primeName$

	target = Read from file: wavDir$ + "/" + targetName$ + ".wav"
	@prepComponent: target
	target = prepComponent.id
	Rename: "target_" + targetName$

	for bwmIndex to numBkwdMasks
		bwm[bwmIndex] = Read from file: wavDir$ + "/" + bwmName$[bwmIndex] + ".wav"
		@prepComponent: bwm[bwmIndex]
		bwm[bwmIndex] = prepComponent.id
		Rename: "bwm" + string$(bwmIndex) + "_" + bwmName$[bwmIndex]
	endfor

	# Normalize if normalizing,
	# attenuate if attenuating,
	# reversate if reversating
	if normalizeTo
		# 'normalizeTo' is the intensity normalization
		# value specified if normalizing (or 0 for no
		# normalization). 'quietness' is the amount to
		# attenuate.

		# Normalize all components
		selectObject: fwm
		Scale intensity: normalizeTo
		selectObject: prime
		Scale intensity: normalizeTo
		selectObject: target
		Scale intensity: normalizeTo
		for bwmIndex to numBkwdMasks
			selectObject: bwm[bwmIndex]
			Scale intensity: normalizeTo
		endfor
	endif

	# Forward mask: attenuate, compress, reverse
	selectObject: fwm
	db = Get intensity (dB)
	Scale intensity: db - quietness
	Reverse
	@compressDuration: fwm
	fwm = compressDuration.compressed
	Rename: "fwm_" + fwmName$
	fwmDur = Get total duration

	# prime: attenuate and compress
	selectObject: prime
	db = Get intensity (dB)
	Scale intensity: db - quietness
	@compressDuration: prime
	prime = compressDuration.compressed
	Rename: "prime_" + primeName$
	primeDur = Get total duration

	# No further manipulations for target
	selectObject: target
	targetDur = Get total duration

	# Masks, attenuate, reverse, compress
	bwmDur = 0
	for bwmIndex to numBkwdMasks
		selectObject: bwm[bwmIndex]
		db = Get intensity (dB)
		Scale intensity: db - quietness
		Reverse
		@compressDuration: bwm[bwmIndex]
		bwm[bwmIndex] = compressDuration.compressed
		Rename: "bwm" + string$(bwmIndex) + "_" + bwmName$[bwmIndex]
		thisbwmDur = Get total duration
		bwmDur = bwmDur + thisbwmDur
	endfor

	# Check whether target is fully masked
	if bwmDur >= targetDur
		isTargetCovered = 1
	else
		isTargetCovered = 0
	endif

	#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
	# Concatenate all the pieces
	#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#

	@cat: fwm, prime
	frontEnd = cat.catted
	Rename: "frontEnd"
	frontDur = Get total duration
	@cat: frontEnd, target
	frontEnd = cat.catted
	Rename: "frontWithTarget"

	# frontDur is the duration of the fwm
	# and prime together. We start the
	# bwm-ing after that, so we use a silent
	# spacer in the "back" channel.
	backEnd = Create Sound from formula: "silence", 1, 0, frontDur, sr, "0"
	Rename: "backEnd0"
	for bwmIndex to numBkwdMasks
		@cat: backEnd, bwm[bwmIndex]
		backEnd = cat.catted
		Rename: "backEnd" + string$(bwmIndex)
	endfor 

	# The final output stimulus is
	# created by combining the frontEnd
	# with the backEnd (with the silent
	# spacer) as channels of a stereo
	# sound file:
	#
	#---fwm---#--prime--#-------target-------#
	#------silence------#-bwm1-#-bwm2-#-bwm3-#...etc.
	#
	# and then flatten to mono.
	selectObject: frontEnd, backEnd
	stimStereo = Combine to stereo
	Rename: "stimStereo"
	stim = Convert to mono
	Rename: "stim"
	removeObject: frontEnd, backEnd, stimStereo
	# Scale final intensity to global spec.
	if normalizeTo
		Scale intensity: normalizeTo
	endif
	intensity = Get intensity (dB)
	stimDur = Get total duration

	# Check for clipping by hand, then choke
	# the clipping warning.
	stimcopy = Copy: "stimcopy"
	Formula: "if abs(self) >= 1 then 1 else 0 fi"
	clipping = Get mean: 1, 0.0, 0.0
	removeObject: stimcopy
	selectObject: stim

	#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
	# Write stim to WAV and data to the output file
	#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#

	nowarn Write to WAV file: outDir$ + "/" + itemName$ + ".wav"

	# Record the names of the input trial table,
	# item file and components
	out$ = itemTableFile$ + tab$ + date$() + tab$ + itemName$ + tab$ + fwmName$ + tab$ + primeName$ + tab$ + targetName$ + tab$

	# There can be any number of backward masks, and the
	# individuals aren't of much interest, so
	# stitch them together so columns of the
	# output table will be consistent across experiments.
	for bwmIndex to numBkwdMasks
		out$ = out$ + bwmName$[bwmIndex] + "; "
	endfor
	# Strip the extra semicolon
	out$ = out$ - "; "

	# Also add PrimeOnset, TargetOnset, TargetOffset, and BkwdMaskTotalDur
	out$ = out$ + tab$ + string$(fwmDur) + tab$ + string$(frontDur) + tab$ + string$(frontDur + targetDur) + tab$ + string$(bwmDur) + tab$ + string$(stimDur)

	# Add CompressionType, CompressionValue, SR, componentsResampled, Intensity, CatRampDur
	out$ = out$ + tab$ + compressionType$ + tab$ + string$(compressionValue) + tab$ + string$(sr) + tab$ + string$(componentsResampled) + tab$ + string$(intensity) + tab$ + string$(catRampDur) + tab$ + string$(minResynthPitch) + tab$ + string$(maxResynthPitch) + tab$ + string$(quietness) + tab$ + string$(isTargetCovered) + tab$ + fixed$(clipping,4)
	# Write the line to the output file.
	appendFileLine: outputDataFile$, out$
	removeObject: stim
endfor

removeObject: itemTable
appendInfoLine: "...So long, and thanks for all the files!"


#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
# Procedure definitions
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#

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
	selectObject: .second
	# Ramp the front end of .second
	if catRampDur > 0
		Formula: "if x < 'catRampDur' then self * x/'catRampDur' else self fi"
	endif

	# Seem to need this wonky way of
	# doing it because Praat doesn't
	# pay any attention to the order
	# of selection, but only to the
	# order within the objects window.
	# In order to insure that the
	# second wav comes after the first,
	# we copy and create a new object
	# guaranteed to come last because
	# it's just been created at the
	# bottom of the object window.
	.seccopy = Copy: "SecCopy"
	Rename: "cat.seccopy"
	selectObject: .first
	.firstdur = Get total duration
	# Ramp the back end of .first
	if catRampDur > 0
		Formula: "if x > '.firstdur'-'catRampDur' then self * ('.firstdur'-x)/'catRampDur' else self fi"
	endif
	plusObject: .seccopy
	.catted = Concatenate
	Rename: "cat.catted"
	removeObject: .first, .second, .seccopy
	selectObject: .catted
endproc

# Compress a sound object's duration using
# a ratio or specified duration
# The proc utilizes the global variables
# compressionType$ specifying "ratio" or
# "duration", and compressionValue
# specifying the numeric ratio or duration.
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
	.manip = noprogress To Manipulation: 0.01, 'minResynthPitch', 'maxResynthPitch'
	.durTier = Extract duration tier
	Add point: 0.00, .ratio
	plusObject: .manip
	Replace duration tier
	selectObject: .manip
	.compressed = Get resynthesis (overlap-add)
	removeObject: .manip, .durTier, .object
	selectObject: .compressed
endproc

# flatten and resample if needed
# resulting object is .id
procedure prepComponent: .id
	selectObject: .id
	.numchan = Get number of channels
	if .numchan > 1
		.mono = Convert to mono
		removeObject: .id
		.id = .mono
	endif
	.this_sr = Get sampling frequency
	if .this_sr != sr
		componentsResampled = componentsResampled + 1
		.resampled = .id
		.id = Resample: sr, 50
		removeObject: .resampled
	endif
	selectObject: .id
endproc

