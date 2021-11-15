extends Spatial

export var u1 = 0
export var u2 = 0

func _ready():
	pass # Replace with function body.


func get_force1_4(u):
	var f1 = u1 * u
	var f2 = u2 * u
	var force = Vector3(f1 * sin(0.728), 0, f2 * cos(0.728))
	return force

func get_force5_8(u):
	var force = Vector3(0, u, 0)
	return force

func get_torque(force, mass_center):
	var dpos = translation - mass_center
	var torque = dpos.cross(force)
	return torque
