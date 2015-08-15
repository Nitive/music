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

	render: ->
		<div className = 'visualization'>
			<canvas height = 200 width = 500 id = 'vcanvas' />
			<FileZone
				play = @props.play
				getFile = @props.getFile
				/>
			<div className = 'visualization__line' style = {width: "#{@props.completed}%"} />
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
		array = new Uint8Array @analyser.frequencyBinCount
		@analyser.getByteFrequencyData array

		if vcanvas and vcanvas.getContext
			@canvasCtx ||= vcanvas.getContext '2d'
			@canvasCtx.clearRect 0, 0, 500, 200
			gradient = @canvasCtx.createLinearGradient(0,0,0,170)
			gradient.addColorStop  0, '#8f29d9'
			gradient.addColorStop .5, '#39c8d9'
			gradient.addColorStop  1, '#1f5fb9'
			@canvasCtx.fillStyle = gradient
			length = array.length

			width = 6
			between = .5
			offset = 30
			offsetTop = 100
			item = (500 - width - offset * 2) / length - between
			for value, i in array
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

		jsNode = @ctx.createScriptProcessor 2048, 1, 1
		jsNode.onaudioprocess = @drawSpectrum
		last.connect @analyser
		@analyser.connect jsNode
		jsNode.connect @ctx.destination

	componentDidMount: ->
		do @connectSoundNodes

	render: ->
		@ctx = @props.audioContext

		<div className = 'music-player'>
			<Visualization
				play = @play
				completed = @state.completed
				getFile = @getFile
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
