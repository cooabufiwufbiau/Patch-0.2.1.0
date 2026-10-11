extends Node


var gameData = preload("res://Resources/GameData.tres")


enum Type{Icon, Geometry, Character}
@export var type = Type.Icon

@export_group("2D")
@export var targetIcon: Sprite2D
@export var summerIcon: Texture2D
@export var winterIcon: Texture2D

@export_group("3D")
@export var targetMeshes: Array[MeshInstance3D]
@export var summerMaterial: Material
@export var winterMaterial: Material

@export_group("Character")
@export var targetMesh: MeshInstance3D
@export var summerClothing: Array[Material]
@export var winterClothing: Array[Material]

func _ready() -> void :
	Update()

func Update():

	if type == Type.Icon:
		if gameData.season == 1: targetIcon.texture = summerIcon
		elif gameData.season == 2: targetIcon.texture = winterIcon

	elif type == Type.Geometry:
		for mesh in targetMeshes:
			if gameData.season == 1:
				mesh.set_surface_override_material(0, summerMaterial)
			elif gameData.season == 2:
				mesh.set_surface_override_material(0, winterMaterial)

	elif type == Type.Character:
		var surfaceCount = targetMesh.get_surface_override_material_count()

		if surfaceCount == 2:
			if gameData.season == 1:
				targetMesh.set_surface_override_material(0, summerClothing[0])
				targetMesh.set_surface_override_material(1, summerClothing[1])
			elif gameData.season == 2:
				targetMesh.set_surface_override_material(0, winterClothing[0])
				targetMesh.set_surface_override_material(1, winterClothing[1])
