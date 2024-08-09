extends RefCounted
class_name Data


## todo: implement movement speed, damage resistance, and other stats
const ENEMIES := {
	"Snake" = {
		"Name" = "Snake",
		"Atlas_Coord" = Vector2i(4,1),
		"HP" = 1,
		"Atk" = 2,
		"Vision" = 2
	},
	"Dog" = {
		"Name" = "Dog",
		"Atlas_Coord" = Vector2i(5,1),
		"HP" = 2,
		"Atk" = 2,
		"Vision" = 6
		
	},
	"Rat" = {
		"Name" = "Rat",
		"Atlas_Coord" = Vector2i(6,1),
		"HP" = 1,
		"Atk" = 1,
		"Vision" = 3
	},
	"Spider" = {
		"Name" = "Spider",
		"Atlas_Coord" = Vector2i(7,1),
		"HP" = 2,
		"Atk" = 3,
		"Vision" = 4
	},
	"Cactus" = {
		"Name" = "Cactus",
		"Atlas_Coord" = Vector2i(8,1),
		"HP" = 1,
		"Atk" = 1,
		"Vision" = 1
	},
	"Specter" = {
		"Name" = "Specter",
		"Atlas_Coord" = Vector2i(9,1),
		"HP" = 1,
		"Atk" = 4,
		"Vision" = 7
	},
	"Turtle" = {
		"Name" = "Turtle",
		"Atlas_Coord" = Vector2i(10,1),
		"HP" = 1,
		"Atk" = 1,
		"Vision" = 1
	},
	"Octopus" = {
		"Name" = "Octopus",
		"Atlas_Coord" = Vector2i(11,1),
		"HP" = 5,
		"Atk" = 1,
		"Vision" = 4
	},
	"Mushroom" = {
		"Name" = "Mushroom",
		"Atlas_Coord" = Vector2i(12,1),
		"HP" = 3,
		"Atk" = 1,
		"Vision" = 2
	},
	"Skeleton" = {
		"Name" = "Skeleton",
		"Atlas_Coord" = Vector2i(10,0),
		"HP" = 3,
		"Atk" = 2,
		"Vision" = 4
	},
	"Zombie" = {
		"Name" = "Zombie",
		"Atlas_Coord" = Vector2i(11,0),
		"HP" = 4,
		"Atk" = 1,
		"Vision" = 4
	},
	"Crab" = {
		"Name" = "Crab",
		"Atlas_Coord" = Vector2i(12,0),
		"HP" = 1,
		"Atk" = 1,
		"Vision" = 4
	},
	"Eye" = {
		"Name" = "Eye",
		"Atlas_Coord" = Vector2i(13,0),
		"HP" = 3,
		"Atk" = 3,
		"Vision" = 8
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


## item_class: Potion, Sword, etc. type: Consumable, Weapon, ....
const ITEMS := {
	"Potion" = {
		"Atlas" = Vector2i(7,8),
		"Type" = "Consumable",
		"Heal" = 4
	},
	"Food" = {
		"Atlas" = Vector2i(10,8),
		"Type" = "Consumable",
		"Heal" = 2
	},
	"Sword" = {
		"Atlas" = Vector2i(6,4),
		"Type" = "Weapon",
		"Atk_Pattern" = "Diagonal",
		"Range" = 1,
		"Splash" = false,
		"Atk" = 2
	},
	"Axe" = {
		"Atlas" = Vector2i(7,4),
		"Type" = "Weapon",
		"Atk_Pattern" = "Diagonal",
		"Range" = 1,
		"Splash" = true,
		"Atk" = 1
	},
	"Bow" = {
		"Atlas" = Vector2i(8,4),
		"Type" = "Weapon",
		"Atk" = 0
	},
	"Arrow" = {
		"Atlas" = Vector2i(9,4),
		"Type" = "Ammo",
		"Atk" = 1
	},
	"Spear" = {
		"Atlas" = Vector2i(10,4),
		"Type" = "Weapon",
		"Atk_Pattern" = "Orthogonal",
		"Range" = 2,
		"Splash" = true,
		"Atk" = 1
	},
	"Club" = {
		"Atlas" = Vector2i(10,3),
		"Type" = "Weapon",
		"Atk_Pattern" = "Orthogonal",
		"Range" = 1,
		"Splash" = false,
		"Atk" = 3
	},
	"Shield" = {
		"Atlas" = Vector2i(10,6),
		"Type" = "Shield",
		"Block" = 1
	},
	"Armor" = {
		"Atlas" = Vector2i(10,2),
		"Type" = "Armor",
		"Arm" = 1
	},
	"Ring" = {
		"Atlas" = Vector2i(9,5),
		"Type" = "Ring",
		"Res" = 1
	},
	"Key" = {
		"Atlas" = Vector2i(10,5),
		"Type" = "Key"
	},
	"Fireball" = {
		"Atlas" = Vector2i(8,8),
		"Type" = "Spell",
		"Range" = 6,
		"Atk" = 3,
		"Area" = "Orthogonal",
		"Target" = "Tile"
	},
	"Confusion" = {
		"Atlas" = Vector2i(1,8),
		"Type" = "Spell",
		"Range" = 3,
		"Area" = "Single",
		"Target" = "Enemy",
		"Effect" = "Confusion",
		"Duration" = 2
	},
	"Missile" = {
		"Atlas" = Vector2i(6,8),
		"Type" = "Spell",
		"Range" = 7,
		"Atk" = 3,
		"Area" = "Single",
		"Target" = "Enemy"
	},
	"FairyFire" = {
		"Atlas" = Vector2i(4,8),
		"Type" = "Spell",
		"Range" = 7,
		"Atk" = 5,
		"Area" = "Single",
		"Target" = "Auto"
		
	}
	
}
