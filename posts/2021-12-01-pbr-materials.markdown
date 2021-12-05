---
title: 'Physically based rendering: materials'
---

3D scenes consist of objects, each of which has a shape and a material. The shape is defined through a mesh: a collection of vertices, edges, and faces living in a 3D world. The material describes the color of the object and how it reflects and transmits light. In this post, I inspect a popular way of expressing the material: a principled BSDF to see how its numerous parameters influence the look of an object.

## Principled BSDF

As a quick reminder from [the previous post](../posts/2021-11-28-pbr-101.html), the way the light bounces of objects is described as a function called BSDF to a computer.

That representation is not natural for people: it's based on the interpretation of light as a multi-dimensional probability density function. To make it easier for artists to define the materials, Disney [came up with a shader](https://static1.squarespace.com/static/58586fa5ebbd1a60e7d76d3e/t/593a3afa46c3c4a376d779f6/1496988449807/s2012_pbs_disney_brdf_notes_v2.pdf)[^1] called Principled BSDF whose inputs are physically-based properties like "roughness" or "metallic" which get translated to a BSDF.

[^1]: a program for drawing pixels on a screen

<figure>
![Principled BSDF Blender node](https://docs.blender.org/manual/en/latest/_images/render_shader-nodes_shader_principled_node.png){width=35%}
    <figcaption>
A node containing all the settings to describe a material using Principled BSDF in Blender.
</figcaption>
</figure>

Principled BSDF has become the industry standard for describing materials. Despite its principle to be as intuitive as possible, it has a lot of parameters one can change, whose meaning is not always obvious, making using the shader overwhelming at first.

Below, I summarize my understanding of various properties the shader has.

## Base color

Color is the most basic property a material can have. 

The standard BSDF formalism doesn't capture the color of objects. To do so, we need to attach an extra property to the light ray containing the color of the light (described as a 3-element RGB vector). Whenever the ray hits an object, its color coordinates get multiplied by the RBG coordinates of the object, decreasing the intensity of the corresponding channels.

Let's consider the ray going in the direction from the sun to the camera:

1. The ray starts perfectly white, with color represented as `(1., 1., 1.)`
2. The ray hits a perfectly red object, i.e. having color (1., 0., 0.). The color of the ray changes to `(1., 0., 0.)`.
3. The ray goes further and hits a grey object of color `(0.5, 0.5, 0.5)`. The ray's color gets multiplied to `(0.5, 0., 0.)`, which corresponds to dark red.
4. The ray hits the camera where it's averaged with other incoming rays, creating an (RGB) pixel.

<figure>
![Change of light ray color diagram](../images/pbr_materials/color.png){width=70%}
    <figcaption>
Diagram showing a change in the light ray color when being reflected from colorful surfaces.
</figcaption>
</figure>

## Specular vs diffuse reflections

The specular reflection model assumes the light rays are reflected under the same angle to the normal as the incoming light[^2].

[^2]: See section [Specular reflection model](../posts/2021-11-28-pbr-101.html#specular-reflection-model) in the previous post.

There is another model of reflection, which assumes that the incident light gets scattered in all directions with equal probability, called [diffuse reflection](https://en.wikipedia.org/wiki/Diffuse_reflection).

The physical mechanism behind the diffuse reflection is like this:

1. The light ray crosses the surface of the material.
2. Inside, the material is mostly empty, except for a small number of particles.
3. When the ray hits a particle, it gets reflected in a random direction. 

<figure>
![Diagram with a diffuse and specular reflections](../images/pbr_materials/diffuse.gif){width=70%}
    <figcaption>
Comparison of specular and diffuse reflection by GianniG46 ([link](https://commons.wikimedia.org/wiki/File:Lambert2.gif)).
</figcaption>
</figure>

Principled BSDF handles these two reflection models by first calculating the light intensity corresponding to each of them separately, and then simply summing them up.

### Subsurface scattering

The behavior of light rays reflecting from the material particles is called _subsurface scattering_. Apart from being reflected in a random direction, the light rays change color during scattering. As the internals of the material may have a different color than the surface (e.g., skin is white-pink and the internal parts of a body are red), the color of the reflected ray may depend on how deep it entered material.

<figure>
![Photo showing subsurface scattering](../images/pbr_materials/subsurface_res.jpg){width=40%}
    <figcaption>
Subsurface scattering in the human hand. Scaled-down [photo by Davepoo2014](https://commons.wikimedia.org/wiki/File:Skin_Subsurface_Scattering.jpg).
</figcaption>
</figure>

The Principled BSDF in Blender has three parameters for controlling the subsurface scattering:

1. Subsurface, controlling overall strength of subsurface scattering. It is a multiplier to the radius.
2. Subsurface color, defining the color of the material internals.
3. Subsurface radius, defining the average depth the light rays enter the material. It is provided as a 3-dimensional vector: one for RGB colors, to allow materials to, e.g., only allow the red color to enter.

## Metallic

There are two types of materials: [conductors](https://en.wikipedia.org/wiki/Electrical_conductor) (often called metallic by the artistic community) and [dielectrics](https://en.wikipedia.org/wiki/Dielectric).

For conductors, the light enters the material to a much smaller depth than for dielectrics. Visually it manifests itself by:

1. Conductors not permitting passing any light through the material. In other words, only dielectrics are transmissive.
2. Both types of materials cause specular reflection (occurring at the surface of the material), but only dielectrics induce a diffuse one (needing to enter the material to a certain depth).
3. The specular reflection itself is of the same color as the incoming light in the case of dielectrics but tinted by the color of the material for conductors.

Physically, materials are either conductors or dielectrics (not anything in between). The parameter in the shader allows for in-between values, which correspond to non-photorealistic blends between the two.

As its alternative name suggests, conductors are basically only metals, whereas dielectrics are all other real-life materials.

<figure>
![Render of a metallic material](../images/pbr_materials/metallic.png){width=40%}
![Render of a dielectric material](../images/pbr_materials/dielectric.png){width=40%}
    <figcaption>
Conductor (left) vs dielectric (right). Dielectric has a bigger proportion of diffuse reflection (flat pink color). The specular reflection is tinted towards pink in case of metallic and white for the dielectric.
</figcaption>
</figure>

## Transmission

For dielectrics, a part of the light shining on the surface is reflected in a specular way, and a part of it enters the material.

For the light that enters the material, a part of it randomly hits the material particles and gets reflected in a diffuse reflection, and the rest passes through the material as transmitted light.

*Transmission* parameter controls the proportion of light that leaves the object on the other side. Value of 1 means that there is no diffuse reflection: the specular parameter decides the strength of the specular reflection, and all the remaining light passes through the object.

The color of the light ray is still multiplied by the base color of the object, allowing the creation of materials like colored glass, which transmit some colors but absorb others.

<figure>
![Render of a transmissive material](../images/pbr_materials/transmission.png){width=40%}
    <figcaption>
Fully transmissive (glass-like) material, with a red base color.
</figcaption>
</figure>

## Index of refraction

Light travels at a different speed in different mediums. It's fastest in a vacuum, with a speed of nearly 300.000 km/s. The ratio between the speed of light in a vacuum to the speed of light in a given material is called its *index of refraction* (IOR). For example, the IOR of glass is 1.33, meaning the light is slower in glass by around 1/3.

The wave-like nature of light can explain an effect called refraction, where the direction of light changes when moving between two mediums with different indices of refraction.

<figure>
![Diagram illustrating Snell's law](../images/pbr_materials/snells_law.png){width=35%}
    <figcaption>
Illustration of Snell's law, which states that the relation between angles of refraction $\theta$ and the indices of refraction $n$ satisfies $n_1\sin \theta_1 = n_2 \sin \theta_2$.
</figcaption>
</figure>

The IOR parameter found in the Principled BSDF controls the refraction angle, allowing the artist to match materials with a known index of refraction.

## Specular

Fresnel reflectance defines that part of the light that is reflected off the surface in a specular way when the light shines on it from the normal direction (i.e., perpendicularly to the surface) for a dielectric.

Physically, it [can be calculated from IOR](https://en.wikipedia.org/wiki/Fresnel_equations#Power_(intensity)_reflection_and_transmission_coefficients) of the material[^4].

[^4]: A similar formula can calculate Fresnel reflectance for conductors, which have a complex index of refraction.

$$f_0 = \frac{(IOR - 1)^2}{(IOR+1)^2}$$

As the resulting values would be between 0 and 8% for most of the materials (although there are dielectrics with higher specular reflection, for example, a diamond specularly reflects 17% of the incoming light), Fresnel reflectance is expressed through a normalized specular parameter as:

$$S = f_0/0.08$$

On that scale, a typical dielectric with $f_0 = 0.04$ will have a specular parameter of $0.5$.

The Fresnel reflectance $f_0$ is also used to calculate the Fresnel effect that causes a higher reflection at grazing (far from the normal) angles

<figure>
![Render of a material with no Fresnel effect](../images/pbr_materials/no_fresnel.png){width=40%}
![Render of a material with Fresnel effect](../images/pbr_materials/fresnel.png){width=40%}
    <figcaption>
Illustration of a fresnel effect. Notice faint, light highlights at the borders of the sphere on the right (with specular >0).
</figcaption>
</figure>

The split between specular and diffuse reflection applies only to the dielectrics. For conductors, all reflection happens in a specular way, so controlling the specular parameter doesn't make physical sense[^4].

[^4]: However, it looks like changing this parameter in Blender does influence the level of Fresnel effect applied.

### Specular tint
As we said before, the specular reflection for dielectrics doesn't change the color of the light ray. To achieve an artistic (non-physically accurate) effect of specular reflection tinting the light towards the base color of the material, Principled BSDF offers the *specular tint* parameter.

## Microfacet model and roughness

One can divide the reflected light can into:

- specular reflection, reflecting the light in the direction under the same angle to the normal as the incident light, and
- diffuse reflection, reflecting the light in all directions, present only for dielectrics.

The surface of the materials is rarely perfectly flat: it often has some general surface and a lot of microscopic variations to it, called microfacets. When a ray of light shines onto a surface with these bumps, it often hits an area whose normal is not the same as the global normal of the surface.

<figure>
![Figure explaining microfacets](https://google.github.io/filament/images/diagram_macrosurface.png){width=80%}
    <figcaption>
A figure (from [Filament documentation](https://google.github.io/filament/Filament.html#figure_microfacets)) explaining the idea of microfacets.
</figcaption>
</figure>

Because of that, the light reflected through a specular reflection doesn't take a single direction but rather a range of angles around it.

Instead of modeling the actual microscopic structure of the material (which would be tedious and computationally inefficient), the renderers are using statistical models[^5] to decide in which direction the rays will (specularly) reflect.

[^5]: Blender allows to choose between two versions of [GGX](https://www.cs.cornell.edu/~srm/publications/EGSR07-btdf.pdf).

The shader has a parameter called *roughness*, controlling how wide the distribution of reflected rays will be. Materials with lower roughness will appear shinier as more highlights will appear on their surface.

<figure>
![Illustration of effect of roughness parameter on the BSDF](https://google.github.io/filament/images/diagram_roughness.png){width=95%}
    <figcaption>
Illustration of the roughness parameter: higher roughness (left), corresponding to a more bumpy surface, causes a wider range of directions of reflected rays. Comes from [Filament docs](https://google.github.io/filament/Filament.html#figure_roughness).
</figcaption>
</figure>

## Anisotropic

For typical materials, the variation in the surface is random, and the specular reflection, on average, goes in the same direction as if the object was flat. High roughness can increase the variance of reflection but doesn't change the mean direction.

For some types of materials, the assumption about the randomness of microfacets is not correct. For example, a surface made of sanded metal, seen on the bottom of a pan, has a regular pattern that systematically changes reflections.

To allow accounting for this effect, Principled BSDF has a parameter called *anisotropy* that modifies the direction of the reflections. The *tangent* setting controls the angles of the reflections, and anisotropy the strength of the effect.

<figure>
![Render of an isotropic material](../images/pbr_materials/isotropic.png){width=40%}
![Render of an anisotropic material](../images/pbr_materials/anisotropic.png){width=40%}
    <figcaption>
Increasing anisotropy (right) allows changing the direction of the specular reflection.
</figcaption>
</figure>

## Clearcoat

The microfacet model assumes that there is a single parameter: roughness describing the "bumpiness" of the material's surface, which doesn't change with the depth of the material.

It makes it hard to capture materials that by themselves are rough but are covered with a coat of shiny paint, like lacquered wood or colorful aluminum cans.

To simplify defining such materials, there is a *clearcoat* parameter that adds a thin layer of colorless paint, with the roughness that we can control separately,  on top of the given material.

<figure>
![Render of material without clearcoat](../images/pbr_materials/no_clearcoat.png){width=40%}
![Render of a material with clearcoatl](../images/pbr_materials/clearcoat.png){width=40%}
    <figcaption>
A can with a high clearcoat (right) has a more shiny look to it.
</figcaption>
</figure>

## Sheen

Another material property that creates a layer on top of the regular material is *sheen*. It is used to describe an effect causing materials like fleece or velvet to be slightly lighter near the borders.

## Principled BSDF in Blender

I looked at how different shader parameters influence the final look of the materials in Blender. It was intimidating at first, but in the end, only 3-4 of them (roughness, metallic, specular, transmission) express most of the variability in the materials.

While I looked specifically at the Blender (Cycles) implementation of the Principled BSDF, other renderers use the same terminology, e.g. [Mitsuba](https://mitsuba2.readthedocs.io/en/latest/generated/plugins.html#bsdfs), or [Filament](https://google.github.io/filament/Materials.html), 
so the understanding of these parameters is useful independent of the actual render used.
