extends Spatial

export var mass = 1300
export var volume = 1.3
var density = 1000
var L_har = 2.2
var S_har = 2.6739

var mass_center = Vector3(0, 0, 0)
var water_disp = Vector3(0, 0, 0)
var dimension = Vector3(2.2, 1.5, 1.325)

var rel_sum_force = Vector3(0, 0, 0)
var abs_sum_force = Vector3(0, 0, 0)
var rel_sum_torque = Vector3(0, 0, 0)
var abs_sum_torque = Vector3(0, 0, 0)

var rel_velocity = Vector3(0, 0, 0)
var abs_velocity = Vector3(0, 0, 0)
var angle_velocity = Vector3(0, 0, 0)

var cf = Vector3(1262.1, 1851, 2135.9)
var ct = Vector3(5750, 6460, 6130)

var inertia = Vector3(617, 792, 1016)
var pr_mass_f = Vector3(591, 1585, 1585)
var pr_mass_t = Vector3(50, 137.4, 137.4)

var max_power1 = 1150
var max_power2 = 562.5
var u_dv = [0, 0, 0, 0, 0, 0, 0, 0]
var reset_signal = 0

var udp_send := PacketPeerUDP.new()
var udp_rec := PacketPeerUDP.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	udp_send.connect_to_host("127.0.0.1", 13042)
	udp_rec.listen(13044, "127.0.0.1", 72)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	eng_fam()
	apparat_fam()
	update(delta)

func eng_fam():
	var ef1 = $Apparat/Engine.get_force1_4(u_dv[0])
	rel_sum_force += ef1
	rel_sum_torque += $Apparat/Engine.get_torque(ef1, mass_center)
	var ef2 = $Apparat/Engine2.get_force1_4(u_dv[1])
	rel_sum_force += ef2
	rel_sum_torque += $Apparat/Engine2.get_torque(ef2, mass_center)
	var ef3 = $Apparat/Engine3.get_force1_4(u_dv[2])
	rel_sum_force += ef3
	rel_sum_torque += $Apparat/Engine3.get_torque(ef3, mass_center)
	var ef4 = $Apparat/Engine4.get_force1_4(u_dv[3])
	rel_sum_force += ef4
	rel_sum_torque += $Apparat/Engine4.get_torque(ef4, mass_center)
	var ef5 = $Apparat/Engine5.get_force5_8(u_dv[4])
	rel_sum_force += ef5
	rel_sum_torque += $Apparat/Engine5.get_torque(ef5, mass_center)
	var ef6 = $Apparat/Engine6.get_force5_8(u_dv[5])
	rel_sum_force += ef6
	rel_sum_torque += $Apparat/Engine6.get_torque(ef6, mass_center)
	var ef7 = $Apparat/Engine7.get_force5_8(u_dv[6])
	rel_sum_force += ef7
	rel_sum_torque += $Apparat/Engine7.get_torque(ef7, mass_center)
	var ef8 = $Apparat/Engine8.get_force5_8(u_dv[7])
	rel_sum_force += ef8
	rel_sum_torque += $Apparat/Engine8.get_torque(ef8, mass_center)

func set_rotation(matrix):
	var cr = cos($Apparat.rotation.x)
	var sr = sin($Apparat.rotation.x)
	var cp = cos($Apparat.rotation.y)
	var sp = sin($Apparat.rotation.y)
	var cy = cos($Apparat.rotation.z)
	var sy = sin($Apparat.rotation.z)
	
	matrix.x.x = cp * cy
	matrix.x.y = cp * sy
	matrix.x.z = -sp
	
	var srsp = sr * sp
	var crsp = cr * sp
	
	matrix.y.x = srsp * cy - cr * sy
	matrix.y.y = srsp * sy + cr * cy
	matrix.y.z = sr * cp
	
	matrix.z.x = crsp * cy + sr * sy
	matrix.z.y = crsp * sy - sr * cy
	matrix.z.z = cr * cp
	
	return matrix

func rotate_vect(mat, vect):
	var tmp = vect
	vect.x = tmp.x * mat.x.x + tmp.y * mat.y.x + tmp.z * mat.z.x
	vect.y = tmp.x * mat.x.y + tmp.y * mat.y.y + tmp.z * mat.z.y
	vect.z = tmp.x * mat.x.z + tmp.y * mat.y.z + tmp.z * mat.z.z
	return vect

func apparat_fam():
	var friction_f = Vector3(0, 0, 0)
	friction_f.x = cf.x * rel_velocity.x * abs(rel_velocity.x) + 0.1 * cf.x * rel_velocity.x
	friction_f.y = cf.y * rel_velocity.y * abs(rel_velocity.y) + 0.1 * cf.y * rel_velocity.y
	friction_f.z = cf.z * rel_velocity.z * abs(rel_velocity.z) + 0.1 * cf.z * rel_velocity.z
	rel_sum_force -= friction_f
	
	var g_force = Vector3(0, -mass * 10, 0)
	var archimedes = Vector3(0, volume * density * 10, 0)
	abs_sum_force += g_force
	abs_sum_force += archimedes
	
	var rotmat = Basis()
	rotmat = set_rotation(rotmat)
	var dwater_disp = water_disp - mass_center
	var t_water_disp = Vector3()
	t_water_disp.x = dwater_disp.x * rotmat.x.x + dwater_disp.y * rotmat.y.x + dwater_disp.z * rotmat.z.x
	t_water_disp.y = dwater_disp.x * rotmat.x.y + dwater_disp.y * rotmat.y.y + dwater_disp.z * rotmat.z.y
	t_water_disp.z = dwater_disp.x * rotmat.x.z + dwater_disp.y * rotmat.y.z + dwater_disp.z * rotmat.z.z
	var archimedes_tor = Vector3(1000 * volume * t_water_disp.z, 0, -1000 * volume * t_water_disp.x)
	rel_sum_torque -= archimedes_tor
	
	var rot_friction = Vector3()
	rot_friction.x = ct.x * angle_velocity.x * abs(angle_velocity.x) + 0.1 * ct.x * angle_velocity.x
	rot_friction.y = ct.y * angle_velocity.y * abs(angle_velocity.y) + 0.1 * ct.y * angle_velocity.y
	rot_friction.z = ct.z * angle_velocity.z * abs(angle_velocity.z) + 0.1 * ct.z * angle_velocity.z
	rel_sum_torque -= rot_friction

func update(t):
	var rot_mat = Basis()
	rot_mat = set_rotation(rot_mat)
	var inv_rot_mat = rot_mat.inverse()
	abs_sum_force = rotate_vect(inv_rot_mat, abs_sum_force)
	rel_sum_force += abs_sum_force
	abs_sum_force = Vector3(0, 0, 0)
	rel_velocity.x += t * rel_sum_force.x / (mass + pr_mass_f.x)
	rel_velocity.y += t * rel_sum_force.y / (mass + pr_mass_f.y)
	rel_velocity.z += t * rel_sum_force.z / (mass + pr_mass_f.z)
	rel_sum_force = Vector3(0, 0, 0)
	abs_velocity = rel_velocity
	abs_velocity = rotate_vect(rot_mat, abs_velocity)
	$Apparat.translation += abs_velocity * t
	
	angle_velocity.x += t * rel_sum_torque.x / (inertia.x + pr_mass_t.x)
	angle_velocity.y += t * rel_sum_torque.y / (inertia.y + pr_mass_t.y)
	angle_velocity.z += t * rel_sum_torque.z / (inertia.z + pr_mass_t.z)
	$Apparat.rotation += angle_velocity * t
	rel_sum_torque = Vector3(0, 0, 0)

func reset_all():
	u_dv = [0, 0, 0, 0, 0, 0, 0, 0]
	
	rel_sum_force = Vector3(0, 0, 0)
	abs_sum_force = Vector3(0, 0, 0)
	rel_sum_torque = Vector3(0, 0, 0)
	abs_sum_torque = Vector3(0, 0, 0)

	rel_velocity = Vector3(0, 0, 0)
	abs_velocity = Vector3(0, 0, 0)
	angle_velocity = Vector3(0, 0, 0)
	
	$Apparat.translation = Vector3(0, 0, 0)
	$Apparat.rotation = Vector3(0, 0, 0)

func _on_Timer_timeout():
	var spb2 = StreamPeerBuffer.new()
	spb2.put_double($Apparat.translation.x)
	spb2.put_double($Apparat.translation.y)
	spb2.put_double($Apparat.translation.z)
	spb2.put_double(abs_velocity.x)
	spb2.put_double(abs_velocity.y)
	spb2.put_double(abs_velocity.z)
	spb2.put_double($Apparat.rotation.x)
	spb2.put_double($Apparat.rotation.y)
	spb2.put_double($Apparat.rotation.z)
	spb2.put_double(angle_velocity.x)
	spb2.put_double(angle_velocity.y)
	spb2.put_double(angle_velocity.z)
	udp_send.put_packet(spb2.data_array)

func _on_Timer2_timeout():
	var spb = StreamPeerBuffer.new()
	var pkt = udp_rec.get_packet()
	spb.data_array = pkt
	if pkt.size() != 0:
		u_dv[0] = spb.get_double()
		u_dv[1] = spb.get_double()
		u_dv[2] = spb.get_double()
		u_dv[3] = spb.get_double()
		u_dv[4] = spb.get_double()
		u_dv[5] = spb.get_double()
		u_dv[6] = spb.get_double()
		u_dv[7] = spb.get_double()
	reset_signal = spb.get_8()
	if reset_signal == 1:
		reset_all()
		reset_signal = 0
