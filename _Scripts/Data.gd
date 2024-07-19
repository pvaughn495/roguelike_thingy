extends RefCounted
class_name Data


## todo: implement movement speed, damage resistance, and other stats
const ENEMIES := {
	"Snake" = {
		"Name" = "Snake",
		"Atlas_Coord" = Vector2i(4,1),
		"HP" = 1,
		"Atk" = 2
	},
	"Dog" = {
		"Name" = "Dog",
		"Atlas_Coord" = Vector2i(5,1),
		"HP" = 2,
		"Atk" = 2
	},
	"Rat" = {
		"Name" = "Rat",
		"Atlas_Coord" = Vector2i(6,1),
		"HP" = 1,
		"Atk" = 1
	},
	"Spider" = {
		"Name" = "Spider",
		"Atlas_Coord" = Vector2i(7,1),
		"HP" = 2,
		"Atk" = 3
	},
	"Cactus" = {
		"Name" = "Cactus",
		"Atlas_Coord" = Vector2i(8,1),
		"HP" = 1,
		"Atk" = 1
	},
	"Specter" = {
		"Name" = "Specter",
		"Atlas_Coord" = Vector2i(9,1),
		"HP" = 1,
		"Atk" = 4
	},
	"Turtle" = {
		"Name" = "Turtle",
		"Atlas_Coord" = Vector2i(10,1),
		"HP" = 1,
		"Atk" = 1
	},
	"Octopus" = {
		"Name" = "Octopus",
		"Atlas_Coord" = Vector2i(11,1),
		"HP" = 5,
		"Atk" = 1
	},
	"Mushroom" = {
		"Name" = "Mushroom",
		"Atlas_Coord" = Vector2i(12,1),
		"HP" = 3,
		"Atk" = 1
	},
	"Skeleton" = {
		"Name" = "Skeleton",
		"Atlas_Coord" = Vector2i(10,0),
		"HP" = 3,
		"Atk" = 2
	},
	"Zombie" = {
		"Name" = "Zombie",
		"Atlas_Coord" = Vector2i(11,0),
		"HP" = 4,
		"Atk" = 1
	},
	"Crab" = {
		"Name" = "Crab",
		"Atlas_Coord" = Vector2i(12,0),
		"HP" = 1,
		"Atk" = 1
	},
	"Eye" = {
		"Name" = "Eye",
		"Atlas_Coord" = Vector2i(13,0),
		"HP" = 3,
		"Atk" = 3
	}
}

## Idea: mix the enemies in the dungeon based on what dungeon depth the player as at
const DUNGEON_ENEMY_PROGRESSION := [3, 6, 9, 12]

## Grouped by stats I guess?
const ENEMY_GROUPS := [["Rat", "Cactus", "Turtle", "Crab"],
	["Dog", "Snake", "Mushroom"],
	["Zombie", "Skeleton", "Spider"],
	["Octopus", "Specter", "Eye"]
	]




