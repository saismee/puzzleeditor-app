class_name Voxel extends MeshInstance3D

static var planes: Dictionary = {
	Surface.NEGATIVE_Y: {
		"vertices": PackedVector3Array([
			Vector3(1,0,0),
			Vector3(1,0,1),
			Vector3(0,0,0),
			Vector3(0,0,0),
			Vector3(1,0,1),
			Vector3(0,0,1),
		]),
		"uv": PackedVector2Array([
			Vector2(1,0),
			Vector2(1,1),
			Vector2(0,0),
			Vector2(0,0),
			Vector2(1,1),
			Vector2(0,1),
		])
	},
	Surface.POSITIVE_Y: {
		"vertices": PackedVector3Array([
			Vector3(0,1,0),
			Vector3(1,1,1),
			Vector3(1,1,0),
			Vector3(0,1,1),
			Vector3(1,1,1),
			Vector3(0,1,0),
		]),
		"uv": PackedVector2Array([
			Vector2(1,0),
			Vector2(0,1),
			Vector2(0,0),
			Vector2(1,1),
			Vector2(0,1),
			Vector2(1,0),
		])
	},
	Surface.POSITIVE_Z: {
		"vertices": PackedVector3Array([
			Vector3(1,0,1),
			Vector3(0,1,1),
			Vector3(0,0,1),
			Vector3(1,0,1),
			Vector3(1,1,1),
			Vector3(0,1,1),
		]),
		"uv": PackedVector2Array([
			Vector2(0,1),
			Vector2(1,0),
			Vector2(1,1),
			Vector2(0,1),
			Vector2(0,0),
			Vector2(1,0),
		])
	},
	Surface.NEGATIVE_Z: {
		"vertices": PackedVector3Array([
			Vector3(0,0,0),
			Vector3(0,1,0),
			Vector3(1,0,0),
			Vector3(0,1,0),
			Vector3(1,1,0),
			Vector3(1,0,0),
		]),
		"uv": PackedVector2Array([
			Vector2(0,1),
			Vector2(0,0),
			Vector2(1,1),
			Vector2(0,0),
			Vector2(1,0),
			Vector2(1,1),
		])
	},
	Surface.NEGATIVE_X: {
		"vertices": PackedVector3Array([
			Vector3(0,0,1),
			Vector3(0,1,0),
			Vector3(0,0,0),
			Vector3(0,0,1),
			Vector3(0,1,1),
			Vector3(0,1,0),
		]),
		"uv": PackedVector2Array([
			Vector2(0,1),
			Vector2(1,0),
			Vector2(1,1),
			Vector2(0,1),
			Vector2(0,0),
			Vector2(1,0),
		])
	},
	Surface.POSITIVE_X: {
		"vertices": PackedVector3Array([
			Vector3(1,0,0),
			Vector3(1,1,0),
			Vector3(1,0,1),
			Vector3(1,1,0),
			Vector3(1,1,1),
			Vector3(1,0,1),
		]),
		"uv": PackedVector2Array([
			Vector2(0,1),
			Vector2(0,0),
			Vector2(1,1),
			Vector2(0,0),
			Vector2(1,0),
			Vector2(1,1),
		])
	}
}

static var material_names: Array[String] = [
	"floor",
	"ceiling",
	"wall",
	"wall",
	"wall",
	"wall"
]

static var rng: RandomNumberGenerator = RandomNumberGenerator.new()
static func _dict_random(dict: Dictionary) -> Variant: #TODO: move to util?
	var out = dict.keys()
	return dict[out[rng.randi() % out.size()]]

var surfaces: Array[Dictionary]
var surface_meshes: Array[MeshInstance3D]

func _generate_plane(surface: Surface, material_name: String) -> MeshInstance3D:
	var surface_mesh: ArrayMesh = ArrayMesh.new()
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	surface_meshes[surface.value] = mesh_instance
	
	var vertices: PackedVector3Array = planes[surface.value].vertices
	var uv: PackedVector2Array = planes[surface.value].uv
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index: int in vertices.size():
		surface_tool.set_uv(uv[index])
		surface_tool.set_normal(-surface.normal)
		surface_tool.add_vertex(vertices[index])
	surface_tool.commit(surface_mesh)
	#surface_mesh.surface_set_material(surface_mesh.get_surface_count()-1, Data.registered_skins[Data.skin].registered_materials[surfaces[surface.value].material].editor_material)
	mesh_instance.mesh = surface_mesh
	mesh_instance.create_trimesh_collision()
	mesh_instance.get_child(0).set_collision_layer_value(2, true)
	return mesh_instance

func _init(parent: Node, pos: Vector3i, portalable: Variant) -> void:
	#Logger.info("new")
	self.position = pos
	self.surfaces.resize(6)
	self.surface_meshes.resize(6)
	for surf_index: int in 6:
		var surface = Surface.new(surf_index)
		var materials = Data.registered_skins[Data.skin].materials
		self.surfaces[surf_index] = {
			"portalable": portalable if (portalable is bool) else Util.has(portalable, surf_index, false),
			"material": _dict_random(materials.portalable.floor),
			"visible": true
		}
		add_child(_generate_plane(surface, surfaces[surf_index].material))
	parent.add_child(self)
	
	set_meta("voxel", pos)
	name = str(pos)
	
	#update()
	update_materials()

func update_materials() -> void:
	var materials = Data.registered_skins[Data.skin].materials
	for surf_index: int in 6:
		var surface = Surface.new(surf_index)
		if surfaces[surf_index].portalable:
			surfaces[surf_index].material = _dict_random(materials.portalable[material_names[surf_index]])
		else:
			surfaces[surf_index].material = _dict_random(materials.unportalable[material_names[surf_index]])
		surface_meshes[surf_index].material_override = Data.registered_skins[Data.skin].registered_materials[surfaces[surf_index].material].editor_material

func update() -> void:
	for surf_index: int in 6:
		var surface = Surface.new(surf_index)
		surface_meshes[surf_index].material_override = Data.registered_skins[Data.skin].registered_materials[surfaces[surf_index].material].editor_material
		if Data.voxels.has(Vector3i(position + surface.normal)):
			if !Util.has(surfaces[surf_index], "visible", true): continue
			surfaces[surf_index].visible = false
			remove_child(surface_meshes[surf_index])
		else:
			if Util.has(surfaces[surf_index], "visible", true): continue
			surfaces[surf_index].visible = true
			add_child(surface_meshes[surf_index])

func serialize() -> Dictionary:
	return {
		surfaces = self.surfaces
	}
