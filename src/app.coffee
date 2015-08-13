React = require 'react'



Visualization = React.createClass
	render: ->
		<div className = 'visualization'>
			<div className = 'visualization__line' />
		</div>


ControlPanel = React.createClass
	render: ->
		<div className = 'control-panel'>
			<div className = 'control-panel__play' />
			<div className = 'control-panel__stop' />
			<div className = 'control-panel__song-name' />
		</div>


Equalizer = React.createClass
	render: ->
			<div className = 'equalizer'>
				<div className = 'equalizer__normal' />
				<div className = 'equalizer__pop' />
				<div className = 'equalizer__rock' />
				<div className = 'equalizer__jazz' />
				<div className = 'equalizer__classic' />
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
