extends Node3D


var gameData = preload("res://Resources/GameData.tres")

func Interact():
	pass

func UpdateTooltip():
	gameData.tooltip = "Today is " + Simulation.Weekday()
