extends Spatial

export var city_set: Resource

export var roof_enabled = true

var items = {}

onready var queue = [
	{
		"name": "city",
		"data": {
			"position": Vector3(),
			"rotation": 0,
			"set": city_set,
			"houses": []
		}
	},
]
var delayed_queue = []
onready var rnd = RandomNumberGenerator.new()
var saved_seed = 0

func build_city(item):
	var cset: CitySet = item.data.set
	var center = {
		"name": "center",
		"data": {
			"position": Vector3(),
			"rotation": rnd.randf() * PI * 2.0,
			"town": item,
			"set": item.data.set
		}
	}
	queue.push_back(center)
	var dcount = cset.max_buildings - cset.min_buildings
	var count = cset.min_buildings
	if dcount > 0:
		count += rnd.randi() % dcount
	print("count=", count)
	var l = cset.building_sets.size()
	if l == 0:
		return
	for e in range(count):
		var rot = rnd.randf() * PI * 2.0
		var bset = cset.building_sets[rnd.randi() % l]
		var house = {
			"name": "house",
			"data": {
				"position": Vector3(),
				"rotation": rnd.randf() * PI * 2.0,
				"bset": bset,
				"type": bset.house_type,
				"town": item,
				"placement": "arc",
				"aabb": AABB(),
			}
		}
		queue.push_back(house)
	print("city added")

func get_next_pos(pos, aabbs, xsize, ysize, nxsize, nysize, bset: BuildingSet):
	var npos = pos
	while true:
		var s = rnd.randi() % 4
		npos = pos
		var dx = xsize * 0.5 + nxsize * 0.5 + 0.35 + bset.wing_offset
		var dz = ysize * 0.5 + nysize * 0.5 + 0.35 + bset.wing_offset
		match s:
			0:
				npos += Vector3(dx, 0, 0)
			1:
				npos += Vector3(-dx, 0, 0)
			2:
				npos += Vector3(0, 0, dz)
			3:
				npos += Vector3(0, 0, -dz)
		var nsize = Vector3(nxsize, 0, nysize)
		var aabb: AABB = AABB(npos - nsize * 0.5, nsize + Vector3(0, 3, 0))
		var ok = true
		for e in aabbs:
			if aabb.intersects(e):
				ok = false
				break
			if aabb.encloses(e):
				ok = false
				break
			if e.encloses(aabb):
				ok = false
				break
			if e.intersects(aabb):
				ok = false
				break
		if ok:
			break
	return npos
var proc: Thread


func _ready():
	for e in city_set.items.keys():
		items[e] = city_set.items[e].duplicate()
	for e in items.keys():
		for m in items[e].keys():
			if items[e][m].has("mesh"):
				var mesh: ArrayMesh = items[e][m].mesh
				var surfaces = mesh.get_surface_count()
				var mesh_arrays = []
				var mesh_materials = []
				for s in range(surfaces):
					var surf = mesh.surface_get_arrays(s)
					var mat = mesh.surface_get_material(s)
					mesh_arrays.push_back(surf)
					mesh_materials.push_back(mat)
				if mesh_arrays.size() > 0:
					items[e][m].mesh_arrays = mesh_arrays
					items[e][m].mesh_materials = mesh_materials
			
	proc = Thread.new()
#	proc.start(self, "procedural", null)
	procedural(null)

func can_pass(p1, p2, offset):
	if abs(p1.x - p2.x) < 0.01 || abs(p1.z - p2.z) < 0.01:
		if abs(p1.x - p2.x) < 0.9 + offset && abs(p1.z - p2.z) < 0.9 + offset:
			return true
	return false
func build_roof_side(item):
	var xsize = item.data.size.x
	var ysize = item.data.size.y
	var v = Vector3(item.data.size.x * 0.5, 0, item.data.size.y * 0.5)
	var position1 = item.data.position - v
	var position2 = item.data.position + v
	var offset1 = Vector3()
	var offset1a = Vector3()
	var offset2 = Vector3()
	var offset2a = Vector3()
	var pa1 = Vector3()
	var pa2 = Vector3()
	var pb1 = Vector3()
	var pb2 = Vector3()
	var rot = PI
	var xloop = xsize
	var yloop = ysize
	var side = 0
	if xsize > ysize:
		offset1 = Vector3(1, 0, 0)
		offset1a = Vector3(-1, 0, 0)
		offset2 = Vector3(0, 0.5, 1)
		offset2a = Vector3(0, 0.5, -1)
		rot = PI
		yloop = ysize * 0.5
		xloop = xsize
		position1 += Vector3(-1, 0, 0)
		position2 -= Vector3(-1, 0, 0)
		side = 0
	else:
		offset2 = Vector3(0, 0, 1)
		offset2a = Vector3(0, 0, -1)
		offset1 = Vector3(1, 0.5, 0)
		offset1a = Vector3(-1, 0.5, 0)
		rot = -PI * 0.5
		yloop = ysize
		xloop = xsize * 0.5
		position1 += Vector3(-1, -0.5, 1)
		position2 -= Vector3(-1, 0.5, 1)
		side = 1
	for x in range(xloop):
		pa1 += offset1
		pa2 += offset1a
		pb1 = Vector3()
		pb2 = Vector3()
		for y in range(yloop):
			if (side == 0 && x == xloop - 1) || (side == 1 && y == 0):
				var offta = Vector3()
				var offtb = Vector3()
				if side == 1:
					offta = -offset2
					offtb = -offset2a
				else:
					offta = offset1
					offtb = offset1a
				var s0 = {
						"name": "roof_side_left",
						"data": {
							"rotation": rot,
							"position": position1 + Vector3(0, 3, 0) + pa1 + pb1 + offta,
							"wing": item.data.wing
						}
				}
				queue.push_back(s0)
				var s2 = {
						"name": "roof_side_left",
						"data": {
							"rotation": rot + PI,
							"position": position2 + Vector3(0, 3, 0) + pa2 + pb2 + offtb,
							"wing": item.data.wing
						}
				}
				queue.push_back(s2)
				var h = y if side == 0 else x
				for e in range(h):
					var sx1 = {
						"name": "roof_side_left_block",
						"data": {
							"rotation": rot,
							"position": position1 + Vector3(0, 3, 0) + pa1 + pb1 - (e + 1) * Vector3(0, 0.5, 0) + offta,
							"wing": item.data.wing
						}
					}
					queue.push_back(sx1)
					var sx3 = {
						"name": "roof_side_left_block",
						"data": {
							"rotation": rot - PI,
							"position": position2 + Vector3(0, 3, 0) + pa2 + pb2 - (e + 1) * Vector3(0, 0.5, 0) + offtb,
							"wing": item.data.wing
						}
					}
					queue.push_back(sx3)
			if (side == 0 && x == 0) || (side == 1 && y == yloop - 1):
				var offta = Vector3()
				var offtb = Vector3()
				if side == 1:
					offta = -offset1
					offtb = -offset1a
				else:
					offta = -offset1
					offtb = -offset1a
				var s1 = {
						"name": "roof_side_right",
						"data": {
							"rotation": rot,
							"position": position1 + Vector3(0, 3, 0) + pa1 + pb1 + offset1 + offta,
							"wing": item.data.wing
						}
				}
				queue.push_back(s1)
				var s3 = {
						"name": "roof_side_right",
						"data": {
							"rotation": rot - PI,
							"position": position2 + Vector3(0, 3, 0) + pa2 + pb2 + offset1a + offtb,
							"wing": item.data.wing
						}
				}
				queue.push_back(s3)
				var h = y if side == 0 else x
				for e in range(h):
					var sx2 = {
						"name": "roof_side_right_block",
						"data": {
							"rotation": rot,
							"position": position1 + Vector3(0, 3, 0) + pa1 + pb1 - (e + 1) * Vector3(0, 0.5, 0) + offset1 + offta,
							"wing": item.data.wing
						}
					}
					queue.push_back(sx2)
					var sx4 = {
						"name": "roof_side_right_block",
						"data": {
							"rotation": rot - PI,
							"position": position2 + Vector3(0, 3, 0) + pa2 + pb2 - (e + 1) * Vector3(0, 0.5, 0) + offset1a + offtb,
							"wing": item.data.wing
						}
					}
					queue.push_back(sx4)
			pb1 += offset2
			pb2 += offset2a

func build_roof(item):
	var xsize = item.data.size.x
	var ysize = item.data.size.y
	var v = Vector3(item.data.size.x * 0.5, 0, item.data.size.y * 0.5)
	var position1 = item.data.position - v
	var position2 = item.data.position + v
	var offset1 = Vector3()
	var offset1a = Vector3()
	var offset2 = Vector3()
	var offset2a = Vector3()
	var xstep = 1
	var ystep = 1
	var rot = PI
	var xloop = xsize
	var yloop = ysize
	position1 = item.data.position - v
	position2 = item.data.position + v
	var side = 0
	if xsize > ysize:
		xstep = 1
		ystep = 1
		offset1 = Vector3(1, 0, 0)
		offset1a = Vector3(-1, 0, 0)
		offset2 = Vector3(0, 0.5, 1)
		offset2a = Vector3(0, 0.5, -1)
		rot = PI
		yloop = ysize * 0.5
		xloop = xsize
		position1 += Vector3(-1, 0, 0)
		position2 -= Vector3(-1, 0, 0)
#					print("a")
		side = 0
	else:
		xstep = 1
		ystep = 1
		offset2 = Vector3(0, 0, 1)
		offset2a = Vector3(0, 0, -1)
		offset1 = Vector3(1, 0.5, 0)
		offset1a = Vector3(-1, 0.5, 0)
		rot = -PI * 0.5
		yloop = ysize
		xloop = xsize * 0.5
		position1 += Vector3(-1, -0.5, 1)
		position2 -= Vector3(-1, 0.5, 1)
#					print("b")
		side = 1
	var pa1 = Vector3()
	var pa2 = Vector3()
	var pb1 = Vector3()
	var pb2 = Vector3()
	for x in range(0, xloop, xstep):
		pa1 += offset1
		pa2 += offset1a
		pb1 = Vector3()
		pb2 = Vector3()
		for y in range(0, yloop, ystep):
			var r1 = {
				"name": "roof_main",
				"data": {
					"rotation": rot,
					"position": position1 + Vector3(0, 3, 0) + pa1 + pb1,
					"wing": item.data.wing
				}
			}
			queue.push_back(r1)
			var r2 = {
				"name": "roof_main",
				"data": {
					"rotation": rot - PI,
					"position": position2 + Vector3(0, 3, 0) + pa2 + pb2,
					"wing": item.data.wing
				}
			}
			queue.push_back(r2)
			pb1 += offset2
			pb2 += offset2a

func make_rooms(item: Dictionary, size: Vector2):
	var dim = Vector3(size.x, 3.0, size.y)
	var dpos = Vector3(size.x, 0, size.y)
	var xrooms = {
	"name": "rooms",
		"data": {
					"rotation": 0,
					"position": item.data.position,
					"aabb": AABB(item.data.position - dpos * 0.5, dim),
					"size": size,
					"wing": item
		}
	}
	delayed_queue.push_back(xrooms)

func check_valid_cut(item, aabb1, aabb2):
	var ok = true
	for e in item.data.wing.data.items:
		if aabb1.has_point(e.data.position):
			if e.name == "xwindow":
				ok = false
			elif e.name == "xdoor":
				ok = false
		if aabb2.has_point(e.data.position):
			if e.name == "xwindow":
				ok = false
			elif e.name == "xdoor":
				ok = false
	return ok

func split_room_data_x(item, cut):
	var aabb = item.data.aabb
	var offt1 = cut - aabb.position.x
	var offt2 = aabb.size.x - offt1
#	print("/", offt1, " ", offt2, " ", aabb.size.x, "/")
	var pos1 = aabb.position
	var pos2 = Vector3(cut, aabb.position.y, aabb.position.z)
	var sz1 = Vector2(offt1, aabb.size.z)
	var sz2 = Vector2(offt2, aabb.size.z)
	var aabb1 = AABB(pos1, Vector3(offt1, aabb.size.y, aabb.size.z))
	var aabb2 = AABB(pos2, Vector3(offt2, aabb.size.y, aabb.size.z))

	var r1 = {
		"name": "rooms",
		"data": {
			"rotation": 0,
			"position": pos1 + Vector3(sz1.x, 0, sz1.y) * 0.5,
			"aabb": aabb1,
			"size": sz1,
			"wing": item.data.wing
		}
	}
	var r2 = {
		"name": "rooms",
		"data": {
			"rotation": 0,
			"position": pos2 + Vector3(sz2.x, 0, sz2.y) * 0.5,
			"aabb": aabb1,
			"size": sz2,
			"wing": item.data.wing
		}
	}
	queue.push_back(r1)
	queue.push_back(r2)

func split_room_data_z(item, cut):
	var aabb = item.data.aabb
	var offt1 = cut - aabb.position.z
	var offt2 = aabb.size.z - offt1
#	print("/", offt1, " ", offt2, " ", aabb.size.z, "/")
	var pos1 = aabb.position
	var pos2 = aabb.position
	pos2.z = cut
	
	var sz1 = Vector2(aabb.size.x, offt1)
	var sz2 = Vector2(aabb.size.x, offt2)
	var aabb1 = AABB(pos1, Vector3(aabb.size.x, aabb.size.y, offt1))
	var aabb2 = AABB(pos2, Vector3(aabb.size.x, aabb.size.y, offt2))

	var r1 = {
		"name": "rooms",
		"data": {
			"rotation": 0,
			"position": pos1 + Vector3(sz1.x, 0, sz1.y) * 0.5,
			"aabb": aabb1,
			"size": sz1,
			"wing": item.data.wing
		}
	}
	var r2 = {
		"name": "rooms",
		"data": {
			"rotation": 0,
			"position": pos2 + Vector3(sz2.x, 0, sz2.y) * 0.5,
			"aabb": aabb1,
			"size": sz2,
			"wing": item.data.wing
		}
	}
	queue.push_back(r1)
	queue.push_back(r2)

class ProcessAABB extends Reference:
	var _aabb: AABB
	var _axis: Vector2
	var _mod_aabb1
	var _mod_aabb2
	var _size = 2
	var _offt: Vector3
	var _cloop: int = 0
	func _init(borders: AABB, axis: Vector2):
		_aabb = borders
		_axis = axis.normalized()
		_mod_aabb1 = _aabb
		_mod_aabb2 = _aabb
		var size = _size
		_offt = Vector3()
		if _axis.x > 0.0:
			_mod_aabb1.size.z = size
			_mod_aabb1.position.z = _aabb.position.z - size * 0.5
			_mod_aabb2.size.z = size
			_mod_aabb2.position.z = _aabb.position.z - size * 0.5 + _aabb.size.z
			_offt.x = 1.0
			_cloop = int(_aabb.size.x)
			
		if _axis.y > 0.0:
			_mod_aabb1.size.x = size
			_mod_aabb1.position.x = _aabb.position.x - size * 0.5
			_mod_aabb2.size.z = size
			_mod_aabb2.position.x = _aabb.position.x - size * 0.5 + _aabb.size.x
			_offt.z = 1.0
			_cloop = int(_aabb.size.z)
	func check_valid_cut(item):
		var ok = true
		for e in item.data.wing.data.items:
			if _mod_aabb1.has_point(e.data.position):
				if e.name == "xwindow":
					ok = false
				elif e.name == "xdoor":
					ok = false
			if _mod_aabb2.has_point(e.data.position):
				if e.name == "xwindow":
					ok = false
				elif e.name == "xdoor":
					ok = false
		return ok
	func iterate(item: Dictionary) -> Array:
		var positions = []
		for c in range(0, _cloop, _size):
			_mod_aabb1.position += _offt * c - _offt
			_mod_aabb2.position += _offt * c - _offt
			if check_valid_cut(item):
				var d = _aabb.position
				if _axis.x > 0:
					positions.push_back(d.x + c + 1.0)
				if _axis.y > 0:
					positions.push_back(d.z + c + 1.0)
		return positions
	func find_cut(item):
		var positions = iterate(item)
		var matching = false
		var cut = -INF
		var cut_d = INF
		var mid = _aabb.position.x + _aabb.size.x * 0.5
		var start = _aabb.position.x
		var end = _aabb.position.x + _aabb.size.x
		for d in positions:
			if d - start < 2:
				continue
			if end - d < 2:
				continue
			if cut_d > abs(d - mid):
				cut_d = abs(d - mid)
				cut = d - 1.0
				matching = true
		return [matching, cut]

func split_room_x(item):
	var p = ProcessAABB.new(item.data.aabb, Vector2(1, 0))
	var result = p.find_cut(item)
	var matching = result[0]
	var cut = result[1]
	if matching:
#		print("matching: ", cut)
		split_room_data_x(item, cut)
	else:
		build_room(item)

func split_room_z(item):
	var p = ProcessAABB.new(item.data.aabb, Vector2(1, 0))
	var result = p.find_cut(item)
	var matching = result[0]
	var cut = result[1]
	if matching:
#		print("matching: ", cut)
		split_room_data_z(item, cut)
	else:
		build_room(item)
		
func conv_item(item, conv):
	var ret = {}
	for e in conv.keys():
		if item.name == e:
			ret.name = conv[e].name
			ret.data = {}
			for d in conv[e].copy:
				if item.data[d] is Dictionary || item.data[d] is Array:
					ret.data[d] = item.data[d].duplicate()
				else:
					ret.data[d] = item.data[d]
			break
	return ret

func build_room(item):
#	print("build rooms ", item.data.aabb)
	var replace = {
		"xwindow": {
			"name": "iwindow",
			"copy": ["position", "rotation", "wing"]
		},
		"xdoor": {
			"name": "idoor",
			"copy": ["position", "rotation", "wing"]
		},
		"xwall": {
			"name": "iwall",
			"copy": ["position", "rotation", "wing"]
		},
	}
	var sz = item.data.size
	var dim = Vector3(sz.x, 3.0, sz.y)
	var rooms_aabb = item.data.aabb
	for h in item.data.wing.data.items:
		if rooms_aabb.has_point(h.data.position):
			var n = conv_item(h, replace)
			if !n.empty():
				queue.push_back(n)
	var corners = [
		{
			"position": item.data.position + Vector3(float(0.0) - sz.x * 0.5, 0, float(0.0) - sz.y * 0.5),
			"rotation": item.data.rotation + PI
		},
		{
			"position": item.data.position + Vector3(float(item.data.size.x) - sz.x * 0.5, 0, float(item.data.size.y) - sz.y * 0.5),
			"rotation": item.data.rotation
		},
		{
			"position": item.data.position + Vector3(float(0.0) - sz.x * 0.5, 0, float(item.data.size.y) - sz.y * 0.5),
			"rotation": item.data.rotation - PI * 0.5
		},
		{
			"position": item.data.position + Vector3(float(item.data.size.x) - sz.x * 0.5, 0, float(0.0) - sz.y * 0.5),
			"rotation": item.data.rotation + PI * 0.5
		},
	]
	for c in corners:
		var n = {
		"name": "iangle",
			"data": {
				"position": c.position,
				"rotation": c.rotation,
				"wing": item.data.wing
			}
		}
		queue.push_back(n)
	for dx in range(0, item.data.size.x, 2):
		for dy in range(0, item.data.size.y, 2):
			var w = {
				"name": "floor",
				"data": {
					"position": item.data.position + Vector3(float(dx) + 1.0 - sz.x * 0.5, 0, float(dy) + 1.0 - sz.y * 0.5),
					"rotation": item.data.rotation,
					"wing": item.data.wing
				}
			}
			queue.push_back(w)
			var c = {
				"name": "ceiling",
				"data": {
					"position": item.data.position + Vector3(float(dx) + 1.0 - sz.x * 0.5, 0, float(dy) + 1.0 - sz.y * 0.5),
					"rotation": item.data.rotation,
					"wing": item.data.wing
				}
			}
			queue.push_back(c)

func have_item(item, item_name):
	var q = item.data.wing.data.house.data.bset.house_type
	if items.has(q):
		if items[q].has(item_name):
			return true
	return false
func get_item(item, item_name):
	var q = item.data.wing.data.house.data.bset.house_type
	assert(items.has(q))
	return items[q][item_name]
func get_item_mesh(item, item_name):
	return get_item(item, item_name).mesh

func init_join(join: Array):
	join.resize(ArrayMesh.ARRAY_MAX)
	for id in range(ArrayMesh.ARRAY_MAX):
		match id:
			ArrayMesh.ARRAY_INDEX:
				join[id] = PoolIntArray()
			ArrayMesh.ARRAY_VERTEX:
				join[id] = PoolVector3Array()
			ArrayMesh.ARRAY_NORMAL:
				join[id] = PoolVector3Array()
			ArrayMesh.ARRAY_TEX_UV:
				join[id] = PoolVector2Array()

func merge_meshes(join: Array, surfaces: Array, xforms: Array):
	var index_offset = 0
	var vertex_offset = 0
	join.resize(ArrayMesh.ARRAY_MAX)
	var xfidx = 0
	for st in surfaces:
		var s = st[0]
		var icount = join[ArrayMesh.ARRAY_INDEX].size()
		var count = join[ArrayMesh.ARRAY_VERTEX].size()
		var xform = xforms[xfidx]
		for id in range(ArrayMesh.ARRAY_MAX):
			match id:
				ArrayMesh.ARRAY_INDEX:
					var data_index1 = Array(join[id] + s[id])
#					var data_index2 = Array(s[id])
#					var icount = data_index1.size()
					print("count: ", count)
#					data_index1.resize(data_index1.size() + data_index2.size())
					for e in range(s[id].size()):
						data_index1[e + icount] = s[id][e] + count
					join[id] = PoolIntArray(data_index1)
					print("final count: ", join[id].size())
				ArrayMesh.ARRAY_VERTEX:
					var data_vertex1 = Array(join[id])
					var data_vertex2 = Array(s[id])
					data_vertex1.resize(join[id].size() + s[id].size())
					for e in range(s[id].size()):
						var g = data_vertex2[e]
						var d = xform.xform(g)
						data_vertex1[e + count] = d
					join[id] = PoolVector3Array(data_vertex1)
				ArrayMesh.ARRAY_NORMAL:
					var data_normal1 = Array(join[id])
					var data_normal2 = Array(s[id])
					for e in range(data_normal2.size()):
						data_normal2[e] = xform.basis.xform(data_normal2[e])
					data_normal1 = data_normal1 + data_normal2
					join[id] = PoolVector3Array(data_normal1)
				ArrayMesh.ARRAY_TEX_UV:
					var data_uv1 = Array(join[id])
					var data_uv2 = Array(s[id])
					join[id] = PoolVector2Array(data_uv1 + data_uv2)
		xfidx += 1
	

func procedural(userdata):
	var start = OS.get_ticks_msec()
	if saved_seed == 0:
		rnd.randomize()
		saved_seed = rnd.seed
	else:
		rnd.seed = saved_seed
	var houses = []
#	var bset: BuildingSet = building_set
	while queue.size() > 0 || delayed_queue.size() > 0:
		if queue.size() == 0:
			for e in delayed_queue:
				if e.has("delay"):
					e.delay -= 1
					if e.delay <= 0:
						queue.push_back(e)
						delayed_queue.erase(e)
						break
				else:
					queue.push_back(e)
					delayed_queue.erase(e)
		if queue.size() == 0 && delayed_queue.size() > 0:
			continue
		var item = queue.pop_front()
		match item.name:
			"center":
				var guild = {
					"name": "guildhouse",
					"data": {
						"set": item.data.set,
						"position": Vector3(),
						"rotation": rnd.randf() * PI * 2.0,
						"town": item.data.town,
					}
				}
				queue.push_back(guild)
				var court = {
					"name": "courthouse",
					"data": {
						"set": item.data.set,
						"position": Vector3(),
						"rotation": rnd.randf() * PI * 2.0,
						"town": item.data.town,
					}
				}
				queue.push_back(court)
			"guildhouse":
				var guildhall = {
					"name": "house",
					"data": {
						"position": Vector3(),
						"rotation": rnd.randf() * PI * 2.0,
						"bset": item.data.set.guildhall_building_set,
						"town": item.data.town,
						"type": item.data.set.guildhall_building_set.house_type,
						"placement": "center",
						"aabb": AABB(),
					}
				}
				queue.push_back(guildhall)
			"courthouse":
				var courthouse = {
					"name": "house",
					"data": {
						"position": Vector3(),
						"rotation": rnd.randf() * PI * 2.0,
						"bset": city_set.guildhall_building_set,
						"town": item,
						"type": city_set.guildhall_building_set.house_type,
						"placement": "center",
						"aabb": AABB(),
					}
				}
				queue.push_back(courthouse)
			"house":
#				print(item.name)
				item.data.wings = []
				houses.push_back(item)
				var bset: BuildingSet = item.data.bset
				var wcount = (bset.max_wings - bset.min_wings)
				var wing_count = bset.min_wings
				if wcount > 0:
					wing_count += rnd.randi() % wcount
#				print("wings count:", wcount)
				var pos = Vector3()
				var aabbs = []
				var dxsize = bset.max_wing_size_x - bset.min_wing_size_x
				var dzsize = bset.max_wing_size_z - bset.min_wing_size_z
				var xsize = bset.min_wing_size_x
				if dxsize > 0:
					xsize += 4 * (rnd.randi() % (dxsize / 4))
				var ysize = bset.min_wing_size_z
				if dzsize > 0:
					ysize += 4 * (rnd.randi() % (dzsize / 4))
				var prev = null
				var house_node = Spatial.new()
				for _d in range(wing_count):
					var aabb = AABB(pos - Vector3(xsize, 0, ysize) * 0.5, Vector3(xsize, 3, ysize))
					var w = {
						"name": "wing",
						"data": {
							"size": Vector2(xsize, ysize),
							"walls": [],
							"windows": [],
							"items":[],
							"position": pos,
							"house": item,
							"aabb": aabb,
							"entry": false,
							"pairs": {},
							"adj": [],
							"facades": [],
							"facades_internal": {},
							"rooms": [],
						},
					}
					item.data.aabb = item.data.aabb.merge(aabb)
					if !prev:
						w.data.entry = true
					else:
						prev.data.adj.push_back(w)
						w.data.adj.push_back(prev)
					queue.push_back(w)
					aabbs.push_back(aabb)
					item.data.wings.push_back(w)
					if aabbs.size() > 0:
						var nxsize = bset.min_wing_size_x
						if dxsize > 0:
							nxsize += 4 * (rnd.randi() % (dxsize / 4))
						var nysize = bset.min_wing_size_z
						if dzsize > 0:
							nysize += 4 * (rnd.randi() % (dzsize / 4))
						pos = get_next_pos(pos, aabbs, xsize, ysize, nxsize, nysize, item.data.bset)
						xsize = nxsize
						ysize = nysize
					prev = w
#					print("added wing")
			"wing":
				print(item.name)
				var pos = [Vector3(-1, 0, -1), Vector3(1, 0, -1), Vector3(1, 0, 1), Vector3(-1, 0, 1)]
				var rot = [-PI * 0.5, PI, PI * 0.5, 0]
				var l = [item.data.size.x, item.data.size.y, item.data.size.x, item.data.size.y]
				var o = [Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(0, 0, -1)]
				for p in range(pos.size()):
					var x = {
						"name": "xangle",
						"data": {
							"rotation": rot[p],
							"position": Vector3(pos[p].x * item.data.size.x * 0.5, 0, pos[p].z * item.data.size.y * 0.5) + item.data.position,
							"wing": item
						}
					}
					queue.push_back(x)
					var n = {
						"name": "facade",
						"data": {
							"length": l[p],
							"offset": o[p],
							"rotation": rot[p] - PI * 0.5,
							"position": Vector3(pos[p].x * item.data.size.x * 0.5, 0, pos[p].z * item.data.size.y * 0.5) + item.data.position,
							"items": [],
							"wing": item
						}
					}
					queue.push_back(n)
					item.data.facades.push_back(n)
					item.data.facades_internal[item.data.facades.find(n)] = false
					assert(item.data.has("facades"))
					var r = {
						"name": "roof",
						"data": {
							"position": item.data.position,
							"size": item.data.size,
							"wing": item,
						}
					}
					queue.push_back(r)

#				print("wing done")
			"facade":
				var l = item.data.length
				assert(item.data.wing.data.has("facades"))
				if l > 2:
					var x1 = [
						{
							"name": "xwallh",
							"data": {
								"rotation": item.data.rotation,
								"position": item.data.position,
								"facade": item,
								"wing": item.data.wing
							}
						},
						{
							"name": "walls",
							"data": {
								"rotation": item.data.rotation,
								"position": item.data.position + item.data.offset,
								"length": item.data.length - 2,
								"offset": item.data.offset,
								"facade": item,
								"wing": item.data.wing
							}
						},
						{
							"name": "xwallh",
							"data": {
								"rotation": item.data.rotation,
								"position": item.data.position + (item.data.length - 1)* item.data.offset,
								"facade": item,
								"wing": item.data.wing
							}
						}
					]
					for e in x1:
						queue.push_back(e)
			"walls":
				var l = item.data.length
				var pos = item.data.position
				assert(item.data.wing.data.has("facades"))
				while l >= 1:
					if l >= 2:
						var x = {
								"name": "wall_or_window",
								"data": {
									"rotation": item.data.rotation,
									"position": pos + item.data.offset,
									"walls": item,
									"facade": item.data.facade,
									"wing": item.data.wing
								}
						}
						queue.push_back(x)
						l -= 2
						pos += item.data.offset * 2.0
					else:
						var x = {
								"name": "xwallh",
								"data": {
									"rotation": item.data.rotation,
									"position": pos,
									"walls": item,
									"wing": item.data.wing
								}
						}
						queue.push_back(x)
						item.data.facade.data.items.push_back(x)
						l -= 1
						pos += item.data.offset
			"wall_or_window":
				var bset = item.data.wing.data.house.data.bset
				if rnd.randf() < bset.pwindow:
					item.name = "xwindow"
					item.data.wing.data.windows.push_back(item)
				else:
					item.name = "xwall"
					item.data.wing.data.walls.push_back(item)
				item.data.facade.data.items.push_back(item)
				assert(item.data.wing.data.has("facades"))
				queue.push_back(item)
			"roof":
#				print("roof")
				if roof_enabled:
					build_roof_side(item)
					build_roof(item)
			"city":
				build_city(item)
			_:
				if have_item(item, item.name):
					item.data.mesh = get_item_mesh(item, item.name)
					item.data.mesh_arrays = get_item(item, item.name).mesh_arrays
					var xform = Transform().rotated(Vector3(0, 1, 0), item.data.rotation)
					xform.origin = item.data.position
					item.data.transform = xform
					item.data.wing.data.items.push_back(item)

	var finish = OS.get_ticks_msec() - start
	print("elapsed: ", finish, "ms")
	if houses.size() == 0:
		return
	for h in houses:
		var entry = h.data.wings[0]
		var exits = {}
		var adj_pairs = []
		var item_pairs_a = []
		var item_pairs_b = []
		var uniq_a = []
		var uniq_b = []
		for e in h.data.wings:
			for adj in e.data.adj:
				if e == adj:
					continue
				adj_pairs.push_back([e, adj])
		var elegible = ["xwindow", "xwall"]
		for r in adj_pairs:
			var e = r[0]
			var ew = r[1]
			for t in e.data.items:
				for x in ew.data.items:
					if t == x:
						continue
					if t.name in elegible && x.name in elegible:
						item_pairs_a.push_back(t)
						item_pairs_b.push_back(x)
						if !t in uniq_a:
							uniq_a.push_back(t)
						if !x in uniq_b:
							uniq_b.push_back(x)
		for t in uniq_a:
			for x in uniq_b:
				if t == x:
					continue
				var p1 = t.data.position
				var p2 = x.data.position
				var need_wall = false
				if abs(p1.x - p2.x) <= 1.0 && abs(p1.z - p2.z) < 0.45:
					need_wall = true
				if abs(p1.x - p2.x) < 0.45 && abs(p1.z - p2.z) <= 1.0:
					need_wall = true
				if abs(p1.x - p2.x) <= 3.0 && abs(p1.z - p2.z) < 0.45 && abs(p1.z - p2.z) > 0.1:
					need_wall = true
				if abs(p1.z - p2.z) <= 3.0 && abs(p1.x - p2.x) < 0.45 && abs(p1.x - p2.x) > 0.1:
					need_wall = true
				if need_wall:
					if t.name == "xwindow":
						t.name = "xwall"
						t.data.mesh = get_item_mesh(t, t.name)
					if x.name == "xwindow":
						x.name = "xwall"
						x.data.mesh = get_item_mesh(x, x.name)
		var xa1 = []
		var xa2 = []
		for r in range(item_pairs_a.size()):
			var t = item_pairs_a[r]
			var x = item_pairs_b[r]
			var p1 = t.data.position
			var p2 = x.data.position
			if abs(p1.x - p2.x) < 10.0 || abs(p1.z - p2.z) < 10.0:
				xa1.push_back(t)
				xa2.push_back(x)
		for r in range(xa1.size()):
			var dp1 = xa1[r]
			var dp2 = xa2[r]
			if exits.has(h.data.wings.find(dp1.data.wing)):
				continue
			if dp1.name == "xwall" && dp2.name == "xwall":
				var p1 = dp1.data.position
				var p2 = dp2.data.position
				var offset = h.data.bset.wing_offset
				if can_pass(p1, p2, offset):
					dp1.name = "xdoor"
					dp1.data.mesh = get_item_mesh(dp1, dp1.name)
					dp2.name = "xdoor"
					dp2.data.mesh = get_item_mesh(dp2, dp2.name)
					exits[h.data.wings.find(dp1.data.wing)] = [dp1, dp2]
					exits[h.data.wings.find(dp2.data.wing)] = [dp2, dp1]
					assert(dp1.data.has("wing"))
					assert(dp1.data.wing.data.has("facades"))
					dp1.data.wing.data.facades_internal[dp1.data.wing.data.facades.find(dp1.data.facade)] = true
					dp2.data.wing.data.facades_internal[dp2.data.wing.data.facades.find(dp2.data.facade)] = true
	finish = OS.get_ticks_msec() - start
	print("elapsed1d: ", finish, "ms")

	for h in houses:
		var outer_items = []
		for e in h.data.wings:
			for f in e.data.facades:
				if !e.data.facades_internal[e.data.facades.find(f)]:
					for m in f.data.items:
						if m.name in ["xwall", "xwindow"]:
							outer_items.push_back(m)
		var idx1 = rnd.randi() % outer_items.size()
		var idx2 = rnd.randi() % outer_items.size()
		var idx3 = rnd.randi() % outer_items.size()
		var idx4 = rnd.randi() % outer_items.size()
		var idx5 = rnd.randi() % outer_items.size()
		var idx = -1
		for xid in [idx1, idx2, idx3, idx4, idx5]:
			if outer_items[xid].name == "xwall":
				idx = xid
				break
		if idx < 0:
			idx = idx1
		var edoor = outer_items[idx]
		edoor.name = "xdoor"
		edoor.data.mesh = get_item_mesh(edoor, edoor.name)
			
	for h in houses:
		for e in h.data.wings:
			make_rooms(e, e.data.size)
	while queue.size() > 0 || delayed_queue.size() > 0:
		if queue.size() == 0:
			for e in delayed_queue:
				if e.has("delay"):
					e.delay -= 1
					if e.delay <= 0:
						queue.push_back(e)
						delayed_queue.erase(e)
						break
				else:
					queue.push_back(e)
					delayed_queue.erase(e)
		if queue.size() == 0 && delayed_queue.size() > 0:
			continue
		var item = queue.pop_front()
		match item.name:
			"rooms":
				print("rooms")
				var sz = item.data.size
				build_room(item)
			_:
				if have_item(item, item.name):
					item.data.mesh = get_item_mesh(item, item.name)
					item.data.mesh_arrays = get_item(item, item.name).mesh_arrays
					var xform = Transform().rotated(Vector3(0, 1, 0), item.data.rotation)
					xform.origin = item.data.position
					item.data.transform = xform
					item.data.wing.data.items.push_back(item)

	var rd = city_set.radius
	var circ = rd * 2.0 * PI
	var ang = 0.0
	var loops = 0
	var max_radius = 0
	var center_pos = Vector3()
	var center_ang = 0.0
	var center_rd = 0.0
	var center_max_radius = 0
	var center_circ = center_rd * 2.0 * PI
	for h in houses:
		if h.data.placement == "center":
			h.data.position = center_pos
			var house_sz = h.data.aabb.size
			var house_radius = max(house_sz.x, house_sz.z)
			if center_max_radius < house_radius:
				center_max_radius = house_radius
			if center_circ <= 0.0:
				center_rd += center_max_radius * 1.5
				center_circ = center_rd * 2.0 * PI
			var da = house_radius * 2.0 / center_circ * 2.0 * PI
			center_ang += da
			if center_ang > PI * 2.0:
				center_ang -= PI * 2.0
				center_rd += center_max_radius * 2.0
				center_circ = center_rd * 2.0 * PI
			center_pos.x = center_rd * cos(center_ang)
			center_pos.z = center_rd * sin(center_ang)
		elif h.data.placement == "arc":
			var house_sz = h.data.aabb.size
			var house_radius = max(house_sz.x, house_sz.z)
			if max_radius < house_radius:
				max_radius = house_radius
			var da = house_radius * 2.0 / circ * 2.0 * PI
			h.data.position.x = rd * cos(ang)
			h.data.position.z = rd * sin(ang)
			ang += da
			if ang > PI * 2.0:
				ang -= PI
				loops += 1
				rd += max_radius * 2.0
				circ = rd * 2.0 * PI
	for h in houses:
		var house_node = Spatial.new()
		var xform = Transform().rotated(Vector3(0, 1, 0), h.data.rotation)
		xform.origin = h.data.position
		house_node.transform = xform
		var house_s = []
		init_join(house_s)
		var surf = []
		var xforms = []
		var mat
		var count = 0
		print("starting merge")
		for e in h.data.wings:
			for t in e.data.items:
				if !t.name == "xdoor":
					if !mat:
						mat = t.data.mesh.surface_get_material(0)
					assert(t.data.has("mesh_arrays"))
					surf.push_back(t.data.mesh_arrays)
					xforms.push_back(t.data.transform)
					count += 1
				else:
#				print("m ", count)
					var mi = MeshInstance.new()
					mi.mesh = t.data.mesh
					mi.transform = t.data.transform
					house_node.add_child(mi)
					mi.create_trimesh_collision()
		print("surf: ", surf.size())
		merge_meshes(house_s, surf, xforms)
		print("merged")
		var new_mesh: ArrayMesh = ArrayMesh.new()
		new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, house_s)
		new_mesh.surface_set_material(0, mat)
		var mi = MeshInstance.new()
		mi.mesh = new_mesh
		mi.create_trimesh_collision()
		house_node.add_child(mi)
		call_deferred("add_child", house_node)
	finish = OS.get_ticks_msec() - start
	print("elapsed2: ", finish, "ms")
