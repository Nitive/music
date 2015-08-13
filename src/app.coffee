React = require 'react'
Dropzone = require 'react-dropzone'

FileZone = React.createClass

	onDrop: (files) ->
		console.log files

	render: ->
		<Dropzone className = 'visualization__select'
				onDrop = @onDrop
				multiple = no>
			<input type = 'file' />
			<div className = 'visualization__file-btn'>Выбрать файл</div>
			<div className = 'visualization__outline'>Отпустите файл</div>
		</Dropzone>

Visualization = React.createClass

	render: ->
		<div className = 'visualization'>
			<FileZone />
			<div className = 'visualization__line' />
		</div>



ControlPanel = React.createClass

	render: ->
		<div className = 'control-panel'>
			<div className = 'control-panel__play' />
			<div className = 'control-panel__stop' />
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



Player = React.createClass

	render: ->
		<div className = 'music-player'>
			<Visualization />
			<ControlPanel />
			<Equalizer />
		</div>




App = React.createClass

	render: ->
		<Player />



React.render <App />, document.getElementById 'container'
