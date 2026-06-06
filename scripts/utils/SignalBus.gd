extends Node

signal beacon_placed(position: Vector2)
signal beacon_extinguished(position: Vector2)
signal fire_low(level: float)
signal wolf_attacking_beacon(wolf: Node, beacon: Node)
signal sacrifice_triggered()
signal game_over()
