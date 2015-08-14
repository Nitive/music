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
			<input type = 'file' />
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
			<span className = 'control-panel__song-name'>Metallica - Unforgiven III</span>
		</div>



Equalizer = React.createClass

	render: ->
			<div className = 'equalizer'>
				<span className = 'equalizer__normal equalizer__normal--active'> Normal </span>
				<span className = 'equalizer__pop'> Pop </span>
				<span className = 'equalizer__rock'> Rock </span>
				<span className = 'equalizer__jazz'> Jazz </span>
				<span className = 'equalizer__classic'> Classic </span>
			</div>



MusicPlayer = React.createClass

	getInitialState: ->
		played: no
		completed: 0

	getFile: (file) ->
		ctx = @props.audioContext
		audioFile.src = file.preview
		source = ctx.createMediaElementSource audioFile
		source.connect ctx.destination
		@play null, null, yes
		do @startTimer

	play: (e, id, force = no) ->
		if audioFile.duration or force
			do audioFile.play
			@setState played: yes

	pause: ->
		do audioFile.pause
		@setState played: no

	stop: ->
		do audioFile.pause
		audioFile.currentTime = 0
		@setState played: no

	startTimer: ->
		@timer = setInterval @tick, 100
	clearTimer: ->
		clearInterval @timer

	componentDidUnmount: ->
		do @clearTimer

	tick: ->
		if audioFile.duration
			if audioFile.currentTime is audioFile.duration
				do @clearTimer
			@setState completed: audioFile.currentTime / audioFile.duration * 100


	render: ->
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
			/>
			<Equalizer />
		</div>




App = React.createClass

	render: ->
		<MusicPlayer audioContext = context />



React.render <App />, document.getElementById 'container'
