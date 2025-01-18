# SourceGD
SourceGD is a GDScript module designed for easily generating and exporting Valve Map File assets from Godot 4.

## Usage
Usage is quite simple, begin by creating a `VMF` to store your map.
```GDScript
var out = VMF.new()
```
Create entities and solids using the `CubeSolid` and `Entity` classes.
Add them to the VMF with the `add(BaseEntity)` method
```GDScript
out.add(CubeSolid.new(Vector3(0, 0, 0), Vector3(10, 10, 10)))
```
Finally, call `collapse()` on the `VMF` to convert it to a string.
```GDScript
var out = VMF.new()
out.add(CubeSolid.new(Vector3(64, 64, 64), Vector3(128, 128, 128)))
# creates a 128ux128ux128 cube. placement is centred on the position value
out = out.collapse()
```
SourceGD accepts Y-up vectors and only converts to Z-up when collapsing VVectors to strings, allowing you to manipulate them to your heart's content.
Individual classes can be collapsed, but require a root `VMF` value to determine the entity's ID.

SourceGD includes a class named `VString`, a small utility for creating multiline strings easily.
```GDScript
var out = VString.new([
  "line 1",
  "line 2",
])
out.append("line 3")
out.collapse() # VString does not need a VMF
```

KV parsing support is not planned and will not be added.

## License
SourceGD is provided under the MIT license. See LICENSE for full details.
