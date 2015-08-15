React = require 'react'
Dropzone = require 'react-dropzone'
ID3 = require 'id3-parser'


window.AudioContext = window.AudioContext or window.webkitAudioContext
context = new AudioContext()


FileZone = React.createClass

	onDrop: (files) ->
		@props.getFile files[0]

	render: ->
		<Dropzone className = 'visualization__select'
				onDrop = @onDrop
				multiple = no
			>
			<audio id = 'audioFile' />
			<span className = 'visualization__file-btn'>Choose file</span>
			<div className = 'visualization__outline'>Drop file to here</div>
		</Dropzone>

Visualization = React.createClass

	goto: (e) ->
		@props.goto (e.clientX - e.target.getBoundingClientRect().left) / e.target.parentElement.offsetWidth

	render: ->
		<div className = 'visualization'>
			<canvas height = 200 width = 500 id = 'vcanvas' />
			<FileZone
				play = @props.play
				getFile = @props.getFile
				/>
			<div
				className = 'visualization__line'
				style = {width: "#{@props.completed}%"}
				onClick = @goto
			/>
		</div>



ControlPanel = React.createClass

	render: ->
		<div className = 'control-panel'>
			{if @props.played
				<div className = 'control-panel__pause' onClick = @props.pause />
			else
				<div className = 'control-panel__play' onClick = @props.play />
			}
			<div className = 'control-panel__stop' onClick = @props.stop />
			<span className = 'control-panel__song-name'>{@props.songName}</span>
		</div>



Equalizer = React.createClass

	active: (btn) ->
		result = "equalizer__#{btn}"
		if @props.active is btn
			result = "#{result} #{result}--active"
		result

	render: ->
			<div className = 'equalizer'>
				<span
					className = @active('normal')
					onClick = {@props.setFilters.bind(null, [0,0,0,0,0,0,0,0,0,0])}
					data-eqlztype = 'normal'
				>Normal</span>
				<span
					className = @active('pop')
					onClick = {@props.setFilters.bind(null, [-1.6, 4.8, 7.2, 8, 5.6, -1.11022e-15, -2.4, -2.4, -1.6, -1.6])}
					data-eqlztype = 'pop'
				>Pop</span>
				<span
					className = @active('rock')
					onClick = {@props.setFilters.bind(null, [8, 4.8, -5.6, -8, -3.2, 4, 8.8, 11.2, 11.2, 11.2])}
					data-eqlztype = 'rock'
				>Rock</span>
				<span
					className = @active('reggae')
					onClick = {@props.setFilters.bind(null, [-1.11022e-15, -1.11022e-15, -1.11022e-15, -5.6, -1.11022e-15, 6.4, 6.4, -1.11022e-15, -1.11022e-15, -1.11022e-15])}
					data-eqlztype = 'reggae'
				>Reggae</span>
				<span
					className = @active('classic')
					onClick = {@props.setFilters.bind(null, [-1.11022e-15, -1.11022e-15, -1.11022e-15, -1.11022e-15, -1.11022e-15, -1.11022e-15, -7.2, -7.2, -7.2, -9.6])}
					data-eqlztype = 'classic'
				>Classic</span>
			</div>



MusicPlayer = React.createClass
	createFilter: (frequency) ->
		filter = @ctx.createBiquadFilter()
		filter.type = 'peaking'
		filter.frequency.value = frequency
		filter.Q.value = 1
		filter.gain.value = 0
		filter

	createFilters: ->
		frequencies = [60, 170, 310, 600, 1000, 3000, 6000, 12000, 14000, 16000]
		filters = frequencies.map(@createFilter)
		filters.reduce (prev, curr) ->
			prev.connect curr
			return curr
		filters

	setFilters: (gains, e) ->
		@filters.map (filter, i) ->
			filter.gain.value = gains[i] or 0
		@setState activeEqualizer: e.target.getAttribute 'data-eqlztype'

	getInitialState: ->
		played: no
		completed: 0
		songName: ''
		activeEqualizer: 'normal'

	getFile: (file) ->
		audioFile.src = file.preview
		@play null, null, yes
		ID3.parse file
			.then ((tags) ->
				songName = switch
					when tags and tags.band and tags.title   then "#{tags.band} - #{tags.title}"
					when tags and tags.artist and tags.title then "#{tags.artist} - #{tags.title}"
					when tags and tags.title                 then tags.title
					else                                          file.name
				@setState songName: songName
			).bind this

	play: (e, id, force = no) ->
		if audioFile.duration or force
			do audioFile.play
			@setState played: yes
			do @startTimer

	pause: ->
		do audioFile.pause
		@setState played: no
		do @clearTimer

	stop: ->
		do audioFile.pause
		audioFile.currentTime = 0
		@setState played: no
		do @clearTimer
		do @updateProgress

	goto: (to) ->
		audioFile.currentTime = audioFile.duration * to
		do @updateProgress

	startTimer: ->
		@timer = setInterval @updateProgress, 50
	clearTimer: ->
		clearInterval @timer

	componentDidUnmount: ->
		do @clearTimer

	updateProgress: ->
		if audioFile.duration
			if audioFile.currentTime is audioFile.duration
				do @stop
				do @clearTimer
			@setState completed: audioFile.currentTime / audioFile.duration * 100

	drawSpectrum: ->
		soundDataArray = new Uint8Array @analyser.frequencyBinCount
		@analyser.getByteFrequencyData soundDataArray
		for _, i in soundDataArray
			soundDataArray[i] *= 200 / 256

		# exclude safari
		if not audioFile.duration or /^((?!chrome).)*safari/i.test navigator.userAgent
			soundDataArray = [40, 41, 43, 45, 47, 49, 50, 51, 53, 58, 59, 59, 65, 67, 69, 67, 68, 69, 67, 69, 66, 70, 75, 76, 78, 80, 77, 81, 86, 87, 83, 85, 82, 86, 91, 92, 100, 102, 99, 103, 108, 109, 110, 112, 109, 113, 118, 119, 123, 125, 122, 126, 131, 132, 132, 134, 131, 135, 140, 141, 128, 130, 127, 131, 136, 137, 130, 132, 129, 133, 138, 139, 137, 139, 136, 140, 145, 146, 148, 150, 147, 151, 156, 157, 147, 149, 146, 150, 155, 156, 152, 154, 151, 155, 160, 161, 159, 161, 158, 162, 167, 168, 163, 165, 162, 166, 171, 172, 162, 164, 161, 165, 170, 171, 174, 176, 173, 177, 182, 183, 177, 179, 176, 180, 185, 186, 195, 197, 194, 198, 203, 204, 192, 194, 191, 195, 200, 201, 187, 189, 186, 190, 195, 196, 189, 191, 188, 192, 197, 198, 182, 184, 181, 185, 190, 191, 178, 180, 177, 181, 186, 187, 174, 176, 173, 177, 182, 183, 171, 173, 170, 174, 179, 180, 161, 163, 160, 164, 169, 170, 153, 155, 152, 156, 161, 162, 141, 143, 140, 144, 149, 150, 118, 120, 117, 121, 126, 127, 87, 89, 86, 90, 95, 96, 82, 84, 81, 85, 90, 91, 72, 74, 71, 75, 80, 81, 68, 70, 67, 71, 76, 77, 63, 65, 62, 66, 71, 72, 57, 59, 56, 60, 65, 66, 48, 50, 47, 51, 56, 57, 37, 39, 36, 40, 45, 46, 35, 37, 34, 38, 43, 44, 33, 35, 32, 36, 41]

		if vcanvas and vcanvas.getContext
			@canvasCtx ||= vcanvas.getContext '2d'
			@canvasCtx.clearRect 0, 0, 500, 200
			gradient = @canvasCtx.createLinearGradient 0, 0, 0, 170
			gradient.addColorStop  .4, '#8f29d9'
			gradient.addColorStop .7, '#39c8d9'
			gradient.addColorStop  1, '#1f5fb9'
			@canvasCtx.fillStyle = gradient
			length = soundDataArray.length

			width = 4
			between = .5
			offset = 30
			offsetTop = 30
			item = (500 - width - offset * 2) / length - between
			for value, i in soundDataArray
				if i % width is 0
					@canvasCtx.fillRect offset + i * (item + between), 200 - value + offsetTop, item * width, value - offsetTop

	connectSoundNodes: ->
		@analyser = context.createAnalyser()
		@analyser.smoothingTimeConstant = .3
		@analyser.fftSize = 512

		@source ||= @ctx.createMediaElementSource audioFile
		[first, ..., last] = @filters = do @createFilters
		@source.connect first
		last.connect @ctx.destination

		jsNode = @ctx.createScriptProcessor(2048, 1, 1)
		console.log jsNode
		last.connect @analyser
		@analyser.connect jsNode
		jsNode.connect @ctx.destination
		jsNode.onaudioprocess = @drawSpectrum

	componentDidMount: ->
		do @connectSoundNodes

	render: ->
		@ctx = @props.audioContext

		<div className = 'music-player'>
			<Visualization
				play = @play
				completed = @state.completed
				getFile = @getFile
				goto = @goto
			/>
			<ControlPanel
				played = @state.played
				play = @play
				pause = @pause
				stop = @stop
				songName = @state.songName
			/>
			<Equalizer
				active = @state.activeEqualizer
				setFilters = @setFilters
			/>
		</div>




App = React.createClass

	render: ->
		<MusicPlayer audioContext = context />



React.render <App />, document.getElementById 'container'
