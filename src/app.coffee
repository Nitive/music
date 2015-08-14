React = require 'react'
Dropzone = require 'react-dropzone'


window.AudioContext = window.AudioContext or window.webkitAudioContext
context = new AudioContext()


FileZone = React.createClass

	onDrop: (files) ->
		@props.getFile files[0]

	render: ->
		<Dropzone className = 'visualization__select'
				onDrop = @onDrop
				multiple = no>
			<audio id = 'audioFile' />
			<div className = 'visualization__file-btn'>Выбрать файл</div>
			<div className = 'visualization__outline'>Отпустите файл</div>
		</Dropzone>

Visualization = React.createClass

	render: ->
		<div className = 'visualization'>
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
					onClick = {@props.setFilters.bind(null, [16,16,16,16,16,16,16,16,16,16])}
					data-eqlztype = 'pop'
				>Pop</span>
				<span
					className = @active('rock')
					onClick = {@props.setFilters.bind(null, [-16,-16,-16,-16,-16,-16,-16,-16,-16,-16])}
					data-eqlztype = 'rock'
				>Rock</span>
				<span
					className = @active('jazz')
					onClick = {@props.setFilters.bind(null, [16,16,16,16,16,16,16,16,16,16])}
					data-eqlztype = 'jazz'
				>Jazz</span>
				<span
					className = @active('classic')
					onClick = {@props.setFilters.bind(null, [16,16,16,16,16,16,16,16,16,16])}
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
		return filter

	createFilters: ->
		frequencies = [60, 170, 310, 600, 1000, 3000, 6000, 12000, 14000, 16000]
		filters = frequencies.map(@createFilter)
		filters.reduce (prev, curr) ->
			prev.connect curr
			return curr
		return filters

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
		@setState songName: file.name
		@play null, null, yes

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
		@timer = setInterval @updateProgress, 100
	clearTimer: ->
		clearInterval @timer

	componentDidUnmount: ->
		do @clearTimer

	updateProgress: ->
		if audioFile.duration
			if audioFile.currentTime is audioFile.duration
				do @clearTimer
			@setState completed: audioFile.currentTime / audioFile.duration * 100

	componentDidMount: ->
		@source ||= @ctx.createMediaElementSource audioFile
		[first, ..., last] = @filters = do @createFilters
		@source.connect first
		last.connect @ctx.destination

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
