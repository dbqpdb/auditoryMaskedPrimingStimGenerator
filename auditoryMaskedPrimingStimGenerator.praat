# auditoryMaskedPrimingStimGenerator.praat
# V0.9999, testing release
# This script is run within Praat, not from the command line.
# It will prompt for
#	@ an input tab-separated trial table
#	@ an output data file to write to
# It will read component sound files from
# 	the directory of the trial table,
# and write the output stimuli to the directory
#	of the specified data file.

# Original concoction implemented, with modifications,
# from Dupoux & Kouider 2005 by Scott Jackson
# Modified 2012 by Kevin Schluter
# Modified 2013 by Samantha Wray
# Modified 2016 by Jonathan Geary

# Rewritten and documented Aug 2016
# by Dan Brenner (brenner@ualberta.ca)

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
# Default parameters & constants
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#

# Specify times in "s" seconds or "ms" milliseconds?
# This converts all time variables  to that unit.
# Make sure to make the default compression duration
# "compressionValueDuration" and catRampDur below agree with
# this unit e.g. if timeUnit$ is "s", maybe
# compressionValueDuration is 0.250 (1/4 second), while if
# timeUnit$ is "ms", compressionValueDuration would be 250 (ms).
timeUnit$ = "ms"

# Set ratioOrDuration to 1 to default to compression
# to a ratio, or set to 2 to default to compress to
# a fixed duration.
ratioOrDuration = 1
# Default ratio and duration
compressionValueRatio = 0.35
compressionValueDuration = 250

# Duration of ramps on joining ends of concatenants.
catRampDur = 5

# Min and max pitch for "manipulate" and the
# PSOLA duration compression resynthesis
minResynthPitch = 75
maxResynthPitch = 600

# dB to attenuate masks and prime
quietness = 15

# Sampling frequency
sr = 44100

# Default intensity normalization
# Set to 0 for no normalization by default,
# or to some other value to make that the default
# normalization dB level.
normalizeTo = 0

# Whether the script should follow
# special debugging options
troubleShooting = 0

#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
# I/O details
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#

# Select and validate the input trial table
itemTableFile$ = chooseReadFile$: "Select tab-delimited trial table..."
if itemTableFile$ == "" | !fileReadable(itemTableFile$)
	exitScript: "No readable trial table selected. Did you expect me to make one up myself?"
endif
# Strip the item table path to get the directory
wavDir$ = replace_regex$(itemTableFile$, "[^/]+$", "", 1)

itemTable = Read Table from tab-separated file: itemTableFile$
Rename: "TrialTable_" + itemTableFile$
nRows = Get number of rows
nCols = Get number of columns

# Validate the trial table and set
# default options accordingly
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

# Note: the file browser warns if the file already exists.
outputDataFile$ = chooseWriteFile$: "Choose output data file, dataphile...", "FileyMcFileface.txt"
if outputDataFile$ == ""
	exitScript: "You didn't select an output file. I can't write to nothing."
endif
outDir$ = replace_regex$(outputDataFile$, "[^/]+$", "", 1)


#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
# Axe the User
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#

# Set defaults based on trial table columns, and then let the user over-ride using the form.
beginPause: "Options 1/2"
	comment: "FILE LOCATIONS: Input component sound files are expected"
	comment: "in the directory of the trial table you selected,"
	comment: "and output sound files will go in the directory"
	comment: "of the data file you chose to write to."

	comment: "INTENSITY NORMALIZATION"
	comment: "Default is ""0"", for no normalization (not 0dB);"
	comment: "Praat's standard intensity scaling is to 70dB"
	real: "NormalizeTo", normalizeTo

	comment: "PRIME/MASK INTENSITY ATTENUATION"
	comment: "How much (dB) should masks and primes be attenuated?"
	real: "Quietness", quietness

	comment: "COMPRESS to RATIO/DURATION?"
	comment: "Compress primes and masks to ratio or duration?"
	choice: "RatioOrDuration", ratioOrDuration
		option: "Compression ratio"
		option: "Fixed duration"
clicked = endPause: "#quit#", "Next options!-->", 2, 1
if clicked == 1
	removeObject: itemTable
	exitScript: "No problem. Ciao!"
endif

if ratioOrDuration == 2
	compressionType$ = "duration"
	compressionValue = compressionValueDuration
else
	compressionType$ = "ratio"
	compressionValue = compressionValueRatio
endif

beginPause: "Options 2/2"
	comment: "COMPRESSION " + replace_regex$(compressionType$, ".*", "\U&",1)
	if compressionType$ == "duration"
		comment: "Enter the compression duration (" + timeUnit$ + ")"
	else
		comment: "Enter the compression ratio (0-1)"
	endif
	real: "CompressionValue", compressionValue

	comment: "CONCATENATION RAMPING"
	comment: "How much time (" + timeUnit$ + ") should I ramp the joining"
	comment: "ends of concatenants? Enter ""0"" for"
	comment: "no ramping."
	real: "CatRampDur", catRampDur

	comment: "COMPONENT/STIMULUS SAMPLING RATE"
	integer: "sr", sr

	comment: "OUTPUT TEXT-GRIDS?"
	choice: "grids", 1
		option: "Nope"
		option: "Yep"

	comment: "Thanks for the deets!"
clicked = endPause: "@extraMenu@", "#quit#", "Here we go!-->", 3, 2
# Set prime compression defaults the same
# User can make masks and primes compress
# differently in the "extra options" window
primeRatioOrDuration = ratioOrDuration
primeCompressionType$ = compressionType$
primeCompressionValue = compressionValue

# to boolean
grids = grids - 1

if clicked == 2
	removeObject: itemTable
	exitScript: "No'rries. Later, gator!"
elsif clicked == 1
	beginPause: "Extra options"
		comment: "PRIME COMPRESSION"
		comment: "Prime compression settings if different from masks"
		choice: "primeRatioOrDuration", ratioOrDuration
			option: "Compression ratio"
			option: "Fixed duration"
		real: "primeCompressionValue", primeCompressionValue

		comment: "BACKWARD MASKS"
		comment: "How many backward masks should I use for each item?"
		natural: "NumberOfBkwdMasks", numBkwdMasks

		comment: "PSOLA PITCH SETTINGS"
		comment: "Pitch range for the duration compression"
		real: "MinResynthPitch", minResynthPitch
		real: "MaxResynthPitch", maxResynthPitch

		comment: "TROUBLESHOOTING"
		comment: "Write stims to stereo files?"
		comment: "** Troubleshooting only **"
		choice: "troubleShooting", 1
			option: "No way! I want to use these stims"
			option: "Yes; things're weird"

		comment: "Got it. Thanks!"
	clicked = endPause: "#quit#", "Here we go!-->", 2, 1
	if clicked == 1
		removeObject: itemTable
		exitScript: "No'rries. Later, gator!"
	endif
	if primeRatioOrDuration == 2
		primeCompressionType$ = "duration"
		# the value is directly reassigned in option
		# menu 3
	else
		primeCompressionType$ = "ratio"
		# the value is directly reassigned in option
		# menu 3
	endif

	# If the user said more backward masks than we
	# found in the trial table, complain.
	if numberOfBkwdMasks > numBkwdMasks
		exitScript: "You've specified " + numberOfBkwdMasks + " but I only find " + numBkwdMasks + " backward mask columns. Check that they are all of the form ""BkwdMaskX"" where X counts up the number of backward masks. E.g., ""BkwdMask1"", ""BkwdMask2"", ""BkwdMask3"", and so on. You have to have at least one, and they all need to have consecutive numbering, even the first one."
	# but if they said to use fewer, fine
	elsif numberOfBkwdMasks < numBkwdMasks
		numBkwdMasks = numberOfBkwdMasks
	endif

	# Convert troubleShooting to a logical
	# [1,2] --> [0,1]
	troubleShooting = troubleShooting - 1
endif


# crd is the variable the ramping formula will
# use in the "cat" procedure. It has to be in
# seconds. catRampDur will still contain the
# user-specified form for the data file.
if timeUnit$ == "ms"
	crd = catRampDur / 1000
else
	crd = catRampDur
endif


#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
# Data Header
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#

# Write the header to the output data file.
header$ = "TrialTable" + tab$ + "Date" + tab$ + "Item" + tab$ + "ForwardMask" + tab$ + "Prime" + tab$ + "Target" + tab$ + "BackwardMasks" + tab$ + "PrimeOnset" + tab$ + "TargetOnset" + tab$ + "TargetOffset" + tab$ + "BwmDur" + tab$ + "StimDur" + tab$ + "MaskCompressType" + tab$ + "MaskCompressValue" + tab$ + "PrimeCompressType" + tab$ + "PrimeCompressValue" + tab$ + "SamplingRate" + tab$ + "Intensity" + tab$ + "CatRampDur" + tab$ + "MinPitch" + tab$ + "MaxPitch" + tab$ + "Quietness" + tab$ + "Notes"
writeFileLine: outputDataFile$, header$


#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
# Stimulus loop
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#

# Start stimulus loop
for currentItem to nRows

	#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
	# Initialize stim-level bits & bobs
	#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#

	# log which components are resampled
	componentsResampled$ = ""

	# keep track of whether any components had
	# durations less than 2*crd
	rampjam = 0

	# keep notes for the stim if the script has any
	notes$ = ""


	#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
	# Process component sounds
	#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#

	# Assign component names
	selectObject: itemTable
	itemName$ = Get value: currentItem, "ItemName"
	appendInfoLine: currentItem, "/", nRows, tab$, itemName$
	fwmName$ = Get value: currentItem, "FwdMask"
	primeName$ = Get value: currentItem, "Prime"
	targetName$ = Get value: currentItem, "Target"
	for bwmIndex to numBkwdMasks
		bwmName$[bwmIndex] = Get value: currentItem, "BkwdMask" + string$(bwmIndex)
	endfor

	# Read component files and prep
	fwm = Read from file: wavDir$ + "/" + fwmName$ + ".wav"
	Rename: "fwm_" + fwmName$
	@prepComponent: fwm
	fwm = prepComponent.id
	Rename: "fwm_" + fwmName$

	prime = Read from file: wavDir$ + "/" + primeName$ + ".wav"
	Rename: "prime_" + primeName$
	@prepComponent: prime
	prime = prepComponent.id
	Rename: "prime_" + primeName$

	target = Read from file: wavDir$ + "/" + targetName$ + ".wav"
	Rename: "target_" + targetName$
	@prepComponent: target
	target = prepComponent.id
	Rename: "target_" + targetName$

	for bwmIndex to numBkwdMasks
		bwm[bwmIndex] = Read from file: wavDir$ + "/" + bwmName$[bwmIndex] + ".wav"
		Rename: "bwm" + string$(bwmIndex) + "_" + bwmName$[bwmIndex]
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

	# forward mask: attenuate, compress, reverse
	selectObject: fwm
	db = Get intensity (dB)
	Scale intensity: db - quietness
	Reverse
	@compressDuration: fwm, "mask"
	fwm = compressDuration.compressed
	Rename: "fwm_" + fwmName$
	fwmDur = Get total duration

	# prime: attenuate and compress
	selectObject: prime
	db = Get intensity (dB)
	Scale intensity: db - quietness
	@compressDuration: prime, "prime"
	prime = compressDuration.compressed
	Rename: "prime_" + primeName$
	primeDur = Get total duration

	# target: no further manipulations
	selectObject: target
	targetDur = Get total duration

	# backward masks: attenuate, reverse, compress
	bwmDur = 0
	for bwmIndex to numBkwdMasks
		selectObject: bwm[bwmIndex]
		db = Get intensity (dB)
		Scale intensity: db - quietness
		Reverse
		@compressDuration: bwm[bwmIndex], "mask"
		bwm[bwmIndex] = compressDuration.compressed
		Rename: "bwm" + string$(bwmIndex) + "_" + bwmName$[bwmIndex]
		thisbwmDur[bwmIndex] = Get total duration
		bwmDur = bwmDur + thisbwmDur[bwmIndex]
	endfor

	# Check whether target is fully masked
	if bwmDur < targetDur
		notes$ = notes$ + "UNDERCLAD TARGET: target is not fully masked (" + fixed$(bwmDur/targetDur * 100, 1) + "% coverage); "
	endif

	
	#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
	# Combine components to form Voltron
	#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#

	# The strategy will be to concatenate
	# fwm, prime, and target in one sound;
	# cat the bwms in another (with a silent
	# spacer on the front so the masks start
	# at target onset), combine into a stereo
	# object, and then flatten to mono.

	# frontEnd, left channel
	@cat: fwm, prime
	frontEnd = cat.catted
	Rename: "frontEnd"
	# frontDur is the target onset time
	frontDur = Get total duration
	@cat: frontEnd, target
	frontEnd = cat.catted
	Rename: "frontWithTarget"

	# backEnd, right channel
	# a silence component is created as a spacer
	# for the channel so that backward masking
	# begins at target onset.
	backEnd = Create Sound from formula: "silence", 1, 0, frontDur, sr, "0"
	Rename: "backEnd0"
	# Then we add the backward masks after that
	# spacer in the back channel
	for bwmIndex to numBkwdMasks
		@cat: backEnd, bwm[bwmIndex]
		backEnd = cat.catted
		Rename: "backEnd" + string$(bwmIndex)
	endfor 

	# The frontEnd and backEnd (with silent spacer)
	# are combined as two channels of a
	# stereo file:
	#
	#--fwm--#--prime--#--------target--------#
	#-----silence-----#-bwm1-#-bwm2-#-bwm3-#-bwm4-#...etc.
	#
	# and then flattened to mono.
	selectObject: frontEnd, backEnd
	stimStereo = Combine to stereo
	stereoDur = Get total duration
	Rename: "stimStereo"

	# Create text-grids if the option was selected
	if grids
		tg = To TextGrid: "FrontChannel BackChannel Notes", ""
		# fwm
		Insert boundary: 1, fwmDur
		Set interval text: 1, 1, "fwm_" + fwmName$

		# prime
		Insert boundary: 1, frontDur
		Set interval text: 1, 2, "prime_" + primeName$

		# target
		Insert boundary: 1, frontDur + targetDur
		Set interval text: 1, 3, "target_" + targetName$

		# bwms go in the right/"back" channel
		now = frontDur
		# Insert first backEnd boundary at target onset
		Insert boundary: 2, now
		# Now add durs of bwms, inserting ending boundaries
		# for each one but the very last
		# (placing a boundary at the very end of the
		# recording may throw an error if there are
		# rounding errors).
		for bwmIndex to numBkwdMasks-1
			now = now + thisbwmDur[bwmIndex]
			Insert boundary: 2, now
			Set interval text: 2, bwmIndex + 1, "bwm" + string$(bwmIndex) + "_" + bwmName$[bwmIndex]
		endfor
		# Assign last mask boundary if within the rec
		# and label
		now = now + thisbwmDur[numBkwdMasks]
		if now < stereoDur
			Insert boundary: 2, now
		endif
		Set interval text: 2, numBkwdMasks+1, "bwm" + string$(numBkwdMasks) + "_" + bwmName$[numBkwdMasks]
	endif

	# reselect the stereo object
	selectObject: stimStereo
	if !troubleShooting
		stim = Convert to mono
		Rename: "stim"
		removeObject: frontEnd, backEnd, stimStereo
	else
		stim = stimStereo
		removeObject: frontEnd, backEnd
		notes$ = notes$ + "**STEREO FOR TESTING**; "
	endif
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
	if clipping
		notes$ = notes$ + "CLIPPING: output stim clipped (" + fixed$(clipping,4) + "); "
	endif
	removeObject: stimcopy
	selectObject: stim


	#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
	# Write stim sound file
	#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#

	# Write stim to WAV and data to the output file
	nowarn Write to WAV file: outDir$ + "/" + itemName$ + ".wav"

	#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
	# Prep data line
	#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#

	# If any components were rampjammed, add to notes$
	if rampjam
		notes$ = notes$ + "RAMPJAM: components have dur < 2*catRampDur; "
	endif

	if componentsResampled$ != ""
		componentsResampled$ = componentsResampled$ - ", "
		notes$ = notes$ + "RESAMPLING: {" + componentsResampled$ + "} resampled on uptake; "
	endif

	#~#~#~#~#								#~#~#~#~#
	#~#~#~#~# NOTES COMPLETE				#~#~#~#~#
	#~#~#~#~# do not add notes beyond here	#~#~#~#~#
	#~#~#~#~#								#~#~#~#~#

	# having added all the notes, strip the final semi
	if notes$ != ""
		notes$ = notes$ - "; "
	endif

	# Write text-grid if that option applies
	if grids
		selectObject: tg
		Set interval text: 3, 1, notes$
		Save as text file: outDir$ + "/" + itemName$ + ".TextGrid"
		removeObject: tg
	endif

	# Record the names of the input trial table,
	# item file and components
	out$ = itemTableFile$ + tab$ + date$() + tab$ + itemName$ + tab$ + fwmName$ + tab$ + primeName$ + tab$ + targetName$ + tab$

	# There can be any number of backward masks, and the
	# individuals aren't of as much interest, so
	# stitch them together so columns of the
	# output table will be consistent across experiments.
	for bwmIndex to numBkwdMasks
		out$ = out$ + bwmName$[bwmIndex] + "; "
	endfor
	# Strip the extra semicolon
	out$ = out$ - "; "

	# Also add PrimeOnset, TargetOnset, TargetOffset, and BkwdMaskTotalDur
	if timeUnit$ == "s"
		out$ = out$ + tab$ + string$(fwmDur) + tab$ + string$(frontDur) + tab$ + string$(frontDur + targetDur) + tab$ + string$(bwmDur) + tab$ + string$(stimDur)
	else
		out$ = out$ + tab$ + string$(round(fwmDur*1000)) + tab$ + string$(round(frontDur*1000)) + tab$ + string$(round((frontDur + targetDur)*1000)) + tab$ + string$(round(bwmDur*1000)) + tab$ + string$(round(stimDur*1000))
	endif

	# Add CompressionType, CompressionValue, SR, Intensity, CatRampDur
	out$ = out$ + tab$ + compressionType$ + tab$ + string$(compressionValue) + tab$ + primeCompressionType$ + tab$ + string$(primeCompressionValue) + tab$ + string$(sr) + tab$ + string$(intensity) + tab$ + string$(catRampDur) + tab$ + string$(minResynthPitch) + tab$ + string$(maxResynthPitch) + tab$ + string$(quietness) + tab$ + notes$
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
# "crd", derived from catRampDur
# near the head of the file.
# This proc removes the two component
# objects. The concatenated sound
# object ID is stored in .catted .
procedure cat: .first, .second
	selectObject: .second
	
	# Ramp the front end of .second
	# Note: crd is the timeUnit$-converted catRampDur
	if crd > 0
		Formula: "if x < 'crd' then self * x/'crd' else self fi"
	endif

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
	Rename: "cat.seccopy"
	.secdur = Get total duration
	selectObject: .first
	.firstdur = Get total duration
	# if the ramp is larger than either component,
	# add to notes.
	if crd > .secdur/2 | crd > .firstdur/2
		rampjam = 1
	endif

	# Ramp the back end of .first
	if crd > 0
		Formula: "if x > '.firstdur'-'crd' then self * ('.firstdur'-x)/'crd' else self fi"
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
procedure compressDuration: .object, .type$
	selectObject: .object
	.origDur = Get total duration
	if compressionType$ == "duration"
		if .type$ == "prime"
			.ratio = primeCompressionValue / .origDur
		else
			.ratio = compressionValue / .origDur
		endif
		# the duration tier is in seconds
		if timeUnit$ = "ms"
			.ratio = .ratio / 1000
		endif
	elsif compressionType$ == "ratio"
		if .type$ == "prime"
			.ratio = primeCompressionValue
		else
			.ratio = compressionValue
		endif
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
	.name$ = selected$: "Sound"
	.numchan = Get number of channels
	if .numchan > 1
		.mono = Convert to mono
		removeObject: .id
		.id = .mono
	endif
	.this_sr = Get sampling frequency
	if .this_sr != sr
		componentsResampled$ = componentsResampled$ + .name$ + ", "
		.resampled = .id
		.id = Resample: sr, 50
		removeObject: .resampled
	endif
	selectObject: .id
endproc

