---
title: 'Geometry nodes'
---

Blender recently introduced a new way of manipulating 3D meshes: geometry nodes. It combines a standard node-based UI (similar to the one used for constructing materials) with a script-like expressiveness to control each vertex arbitrarily. I learned the basics of geometry nodes and did a simple project using the new mechanism to try them out.

## Attributes and domains

<script type="importmap">
{
    "imports": {
        "three": "https://unpkg.com/three@0.139.0/build/three.module.js",
        "OrbitControls": "https://unpkg.com/three@0.139.0/examples/jsm/controls/OrbitControls.js"
    }
}
</script>
<script type="module" src="../js/three.js"></script>
<script type="module" src="../js/geometry_nodes/buttons.js"></script>
<script type="module" src="../js/options.js"></script>

Internally, Blender represents objects using a couple of matrices. There is a description of a single entity (vertex, edge, face) in each row of such a matrix. Each column corresponds to a single _attribute_: a property of that entity, e.g., its position.

There are as many such matrices as there are types of entities (also known as _domains_): one for vertices, one for faces, etc. 

![One can investigate this representation of a mesh in the [Spreadsheet editor](https://docs.blender.org/manual/en/latest/editors/spreadsheet.html).
](https://docs.blender.org/manual/en/latest/_images/editors_spreadsheet_interface.png){width=90%}

This representation isn't very convenient to use, as operating on a set of numbers is usually not as intuitive as making changes in the UI.

With geometry nodes, the changes to the underlying representation can be made more directly than using the standard workflow.

## Types of nodes
[Geometry nodes](https://docs.blender.org/manual/en/latest/modeling/geometry_nodes/index.html) is a modifier of an existing object: it processes the elements (geometry) of an object in more or less sophisticated ways using nodes.

There are three types of nodes:

1. data flow nodes
2. input nodes
3. function nodes

Blender uses a joint name of _fields_ for the functional and input nodes.

### Data flow nodes
Data flow nodes, which are marked by a green title bar, modify underlying geometry by performing the typical Blender operations like moving, joining two meshes together, or creating new objects.

![[Subdivide mesh](https://docs.blender.org/manual/en/latest/modeling/geometry_nodes/mesh/subdivide_mesh.html): an example data flow node.](https://docs.blender.org/manual/en/latest/_images/modeling_geometry-nodes_mesh_subdivide_node.png){width=30%}

### Input nodes
Input nodes, with red title bars, allow getting some piece of information (stored in the geometry or provided by the user in another way) to be later processed.

![[Position node](https://docs.blender.org/manual/en/latest/modeling/geometry_nodes/input/position.html) is a node that reads the position of the entities in a geometry.](https://docs.blender.org/manual/en/latest/_images/modeling_geometry-nodes_input_position_node.png){width=30%}

### Function nodes
Function nodes, having blue title bars, process data that comes in, and return some output.

![[Map range node](https://docs.blender.org/manual/en/latest/modeling/geometry_nodes/utilities/map_range.html) which maps numbers (or vectors) from one range to another using a given transformation.](https://docs.blender.org/manual/en/latest/_images/render_shader-nodes_converter_map-range_node.png){width=60%}

## Eager vs lazy execution

An attentive reader will see that the Position node shown above doesn't get geometry as an input, even though it reads the positions stored on _some_ geometry.

The incoming geometry is often processed in multiple stages, creating several intermediate geometries before getting the final one. Which one Position node queries for the position of its elements?

To answer this question, one needs to introduce the concept of lazy execution. When we typically think about programming, we are using a mental model of eager execution: there is a number of steps, an algorithm, which we follow from a to z.

In geometry nodes, it would correspond to the nodes being evaluated from left to right: from the ones with no inputs (so we can calculate their outputs) to their children, and so on, until the output node.

For efficiency reasons, geometry nodes don't work like this. Instead, Blender processing system starts execution from the final output node. It looks for the inputs that need to be calculated to evaluate the node's output, and so on until it reaches nodes with no inputs. It is called lazy execution.

This way, if some nodes are not necessary to get the output (e.g. because we added them to the system but didn't use them in the end), they won't be calculated, saving precious milliseconds at the cost of a less intuitive computation model.

Note that a similar graph-based, lazy execution system was used in TensorFlow 1 to evaluate neural networks.

Coming back to the question of choosing the geometry for the Position node: the geometry used will be the last geometry encountered while lazily-processing the execution; in other words, the one closest to the Position node.

In particular, if we connect a single Position node to multiple geometries, it will provide different outputs for them.

<figure>
[![Using input node with multiple geometries](../images/geometry_nodes/context.png){width=90%}](../images/geometry_nodes/context.png)
<figcaption>
Using multiple geometries with an input node. The cube is subdivided first, then the points with $Z<0$ are selected and removed from the subdivided cube, and then the resulting half-cube is rotated.
</figcaption>
</figure>

### Transferring attributes

Sometimes, we want to combine attributes living on multiple geometries, e.g. when we select a piece of geometry based on some attribute, transform it, and then do another transformation using the original selection (and not based on a new geometry).

There are two ways to use attributes on a different geometry than the one they were originally defined on: transfer and capture attribute.

#### Transfer attribute

When using transfer attribute, we take one geometry and an attribute that lies on another geometry, and we copy the attribute to the target geometry to use it there.

<figure>
[![transfer attribute example](../images/geometry_nodes/transfer_example.png){width=90%}](../images/geometry_nodes/transfer_example.png)
<figcaption>
An example of using [transfer attribute](https://docs.blender.org/manual/en/latest/modeling/geometry_nodes/attribute/transfer_attribute.html): we select a piece of geometry based on their position ($Z>0$). Then, we transform the geometry to move it up, but we want to base the selection on the original, not the translated position.
</figcaption>
</figure>

How to "copy the attribute" when the number of elements in the geometries differs? It is resolved by matching the target geometry with the nearest entities of the source geometry and copying the attribute values from them.

#### Capture attribute

An alternative, capture attribute, is used when we don't pass the attribute to another geometry but merely request for the attribute on the current geometry to be preserved for later use.

The capture attribute node takes and returns a geometry to lock the value of an attribute value in place, preventing its re-evaluation on a different geometry further down the chain.

How does the "preservation" work here, when the geometry where we captured the attribute and the one where we use it contain different elements?

Here, as opposed to transfer attribute, we don't evade doing the transformations to the captured attribute. Whenever the geometry is changed by some functions, the same transformations are applied to the captured attribute as to the other attributes (e.g. position), potentially creating new geometry elements with an appropriate value of the captured attribute.

Capture attribute is particularly useful before transformations that drop some attributes, like [Curve to mesh](https://docs.blender.org/manual/en/latest/modeling/geometry_nodes/curve/curve_to_mesh.html) that drops [Curve parameter](https://docs.blender.org/manual/en/latest/modeling/geometry_nodes/curve/spline_parameter.html) input attribute. With capture attribute, we can lock this attribute to live on the geometry, despite the transformations that are happening to it.

#### Comparison
The behavior of transfer and capture attribute can be confusing. To give an example of a situation where their behaviors differ, imagine a scene where we select the top half of a cube, mirror the cube horizontally, then paint the selected part.

With no transfer or capture attributes, the bottom part will be painted: the selection has been reversed and painted afterward.

If we used capture attribute after the selection, the behavior won't change: the bottom part will be painted. The selection, stored in capture attribute, doesn't affect the position attribute, which is changed as usual in the mirror reflection.

On the other hand, if transfer attribute is used, the paint will invert. When choosing the selection to paint, Blender will search for the values of the selection in the original geometry, before the mirror reflection. The reflection will cause the vertices to reorder, but their associated values of the selection won't change, as they are assigned from the nearest vertex in the original geometry. This will make the mirror reflection to not affect the painted part, so only the top will be painted.

<figure>
<div class="three_canvas"></div>
<div class="capture_transfer_nodes"></div>
<figcaption>
<div class="options" id="capture_transfer_option"></div>
</figcaption>
</figure>

## Nodes' sockets
The sockets of the nodes have various colors and shapes.

The color marks the type of the data coming in: <p style="color:#5657bf;display:inline">**purple**</p> for 3D vectors, <p style="color:#8f8f8f;display:inline">**grey**</p> for scalar floats, <p style="color:#bd7dc7;display:inline">**pink**</p> for booleans, and others.

![[Separate XYZ](https://docs.blender.org/manual/en/latest/modeling/geometry_nodes/vector/separate_xyz.html) node, which splits a 3-dimensional vector to its coordinates.](https://docs.blender.org/manual/en/latest/_images/modeling_geometry-nodes_vector_separate-xyz_node.png){width=30%}

The shapes of the sockets correspond to whether the incoming/outgoing data is provided per geometry element (one value per vertex, edge, etc.) or per the whole geometry (e.g. object origin).

The first one (data varying per geometry element) is marked by a diamond, and the socket accepting single data has a shape of a circle.

![It's still possible to inject "single" (circle) data to a diamond "per element" input: in that case, every element of the geometry gets passed the same data, and the accepting diamond socket gets a dot drawn on it, to mark the inputs are uniform across the geometry.](../images/geometry_nodes/socket_type.png){width=70%}

![Passing "diamond" outputs to a "circle" input is not allowed, though: Blender needs a global (one per geometry) input, but it's not clear which one of the per-element outputs it should use.](../images/geometry_nodes/sockets2.png){width=70%}

## Instances
Apart from geometry domains of vertices, edges, and faces, geometry nodes handle _instances_.

They are useful to speed up the processing of multiple identical objects at once: instead of constructing a lot of independent vertices and edges, Blender creates a given instance once and then copies the resulting geometry when needed, similarly to when creating "duplicates" in the UI.

One way to add an instance to the geometry nodes is using an [Object info](https://docs.blender.org/manual/en/latest/modeling/geometry_nodes/input/object_info.html) node. It takes an object present in the scene and adds its geometry to geometry nodes.

![Object info node, allowing to bring a geometry from a different object to geometry nodes.](https://docs.blender.org/manual/en/latest/_images/modeling_geometry-nodes_input_object-info_node.png){width=30%}

We can choose whether the geometry should be added "as an instance" or not, in which case the object will be added as separate vertices, edges, etc.

The placement of the new object can be controlled via the Original/Relative setting.

When using Original, the object's origin (and rotation and scale) is put in the same place as the origin of the object which has the geometry nodes modifier.

When using the Relative setting, the new object is placed such that its location / rotation / scale is the same as it had as a standalone object.

Another node that brings instances into geometry nodes is a [Collection info](https://docs.blender.org/manual/en/latest/modeling/geometry_nodes/input/collection_info.html). It works similarly to the Object info one but accepts collections instead of single objects.

It has two settings:

1. Separate children, which changes whether to add the whole collection as a single instance or to have one instance per object in the collection, and
2. Reset children, which sets to 0 all the local transformations that the objects in the collection have.

## Project: assembling a chess pawn

To experiment with the geometry nodes, I did a small project animating the assembly of a chess pawn from parts.

To divide a pawn (which I modeled in [a previous project](https://sygi.ml/posts/2022-03-23-bezier.html)) into pieces, I used a [cell fracture](https://blender-addons.org/cell-fracture-addon/) add-on.

Then, I added a geometry nodes modifier to a dummy geometry, loaded pieces from a given collection as instances, and created an empty, which will be driving the animation.

Concretely, the pieces which are significantly above the empty will be spread out and rotated randomly, the ones below will be on their final positions, and the ones close to the Z position of the empty, will be in the process of being assembled.

To create the move, I used a couple of standard nodes, and a capture attribute node to capture the stage of the move of every instance to synchronize the rotation with the move.

<figure>
[![Geometry nodes system for the assembly animation](../images/geometry_nodes/assembly_animation.png){width=100%}](../images/geometry_nodes/assembly_animation.png)
<figcaption>
Final geometry nodes used for the animation.
</figcaption>
</figure>

<figure>
<video width="360" height="640" controls="">
<source src="../images/geometry_nodes/animation.mp4" type="video/mp4">
Your browser does not support the video tag.
</video>
<figcaption>Final animation.</figcaption>
</figure>
