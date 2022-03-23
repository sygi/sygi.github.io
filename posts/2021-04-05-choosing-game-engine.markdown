---
title: "Choosing game engine"
---
The idea of telling stories interactively through video games is appealing to me. Some time ago, I started writing a scenario for a first, test game. In this post, I write down my experience of choosing a game engine.

## Motivation
Between grade 6 and entering the workforce at around 25 years old, I haven't played many games. Growing up playing Super Mario Bros, FIFA, or Ages of Empires II, I associated computer games more with cheap adrenaline rushes than discovering new worlds.

It changed dramatically after playing [We Were Here](https://store.steampowered.com/app/582500/We_Were_Here/) and [Divinity Original Sin](https://store.steampowered.com/app/230230/Divinity_Original_Sin_Classic/) with my girlfriend. These are cooperative games with no reflex elements and are more about exploring the game world than defeating opponents.

At the same time, we were a bit disappointed with We Were Here, as, even though we liked the walkie-talkie coop mechanic, the gameplay was centered around solving abstract puzzles: there's a little story to discover there[^1].

[^1]: I read that the sequel, [We Were Here Together](https://store.steampowered.com/app/865360/We_Were_Here_Together/), has more story.

I decided to fix this and try to make a game similar to We Were Here with a stronger focus on the story and learn some game development in the process.

## What is a game engine
Making a game involves a lot of complex elements: checking if game objects collide, networking, playing sounds, etc. Many of these can be done once and reused in many games: one doesn't need to reinvent from scratch how the light bounces from objects or how to communicate player actions in a multi-player game.

The ability to separate some reusable solutions caused the birth of a concept of a *game engine*: a program made to simplify the process of game creation by providing common patterns, allowing the game designers to concentrate on the game's content instead of low-level details.

The fixed solutions provided by the game engine may not always be appropriate for a given game. Bigger game studios producing AAA titles will effectively implement proprietary game engines on their own, which will allow them to optimize hardware usage and production workflow for their games.

For the smaller, independent game creators, game engines available on the market are a godsend, as they allow to start making games without investing thousands of manhours in solving ray-tracing issues or creating animation pipelines.

For my first game, I obviously want to reuse known solutions as much as possible, so I was trying out various game engines to see what they offer.

## Choosing game engine

When searching for the game engine over the internet, two popular choices come up often: Unity and Unreal.

### Unreal

As I hope the mechanics in my game will be relatively simple (to concentrate on the story), the first feature of the game engine I was looking at was: the code language used to write the game. In the case of Unreal, it is C++, which I like, so I decided to try it out first.

For a start, I decided to create a 3D scene with a small city, a lake, a mountain, etc. While I learned lots of both Unreal and general 3D-modelling concepts, creating a 3D scene felt quite overwhelming and more effort than I'd like to put on the visuals alone. It would be exarberated if I needed to make some assets for the game: for the test scene I was taking them from the internet, which wouldn't look good/wouldn't be permitted by the license in a game.

A nice thing that I didn't expect was the option to export the game to HTML5. When thinking about it, I'd certainly like to be able to embed the game on a website: it'll be much easier to show the result of my work if one doesn't need to install anything nor have any particular OS to do so.

Unfortunately, due to all the blows and whistles that Unreal comes with, the final export file was over 100MB, despite my attempts to make it as small as possible. Because of it, I wasn't able to serve it on Github pages, and put it on S3 instead ([link](https://sygi-blog.s3.eu-central-1.amazonaws.com/unreal/MovingUnrealPackaged-HTML5-Shipping.html)).

One idea that I quite liked in Unreal is [blueprints](https://docs.unrealengine.com/en-US/ProgrammingAndScripting/Blueprints/index.html). They are a visual programming language that allows people to connect various object properties without writing code. While writing code feels natural to me, the nicely rendered diagrams showing how the properties are changing look appealing.


<figure>
![Blueprint in Unreal Engine.](../images/game_engines/unreal_blueprint.png){width=70%}
</figure>

Overall, I liked Unreal a lot for what it is: a professional-grade 3D game engine. At the same time, I realized that making a proper 3D game is a big undertaking, and I shouldn't try it for the first game I ever made.

### Unity

After Unreal, I spent a couple of hours playing with its main competitor: Unity.

While it has better support for 2D, it had enough pain points to scare me off quickly.

For a start, while formally supported under Linux, the UI seemed to not look great under Cinnamon, and I remember having some problems with the installation. Linux is clearly not a prime target for Unity.

As the engine is as packed as Unreal, is it loaded slowly and took a lot of disk space. The scenes took a long time to build which would be a hinder to the debugging speed.

Furthermore, the game development language is C#, which I haven't used so far. While it seems similar to Java, and I could learn it, I'd prefer it if I didn't have to.

Finally, the business model of the engine put me off. While Unreal is open-source with a fee to pay when your sales exceed 100k USD/year (which won't happen for me), Unity has a separate "pro" engine available for people who pay for it. While I certainly don't need all the features of a full-fledged game engine, the feeling that further down the line, there may be things I'll not be able to do because I didn't pay was not a good first encounter.

### Evennia

When limiting the scope after getting overwhelmed with 3D in Unreal, I played with the other end of the art-complexity spectrum and tried to make the game purely text-based. I discovered an old, unpopular "in my times" genre of games: [multi-user dungeons (MUDs)](https://en.wikipedia.org/wiki/MUD).

MUDs are similar to Roguelikes in being purely text-based, but MUDs are multi-player by definition, and the available commands are text-based, like `look around` or `go through the door` as opposed to the grid-based movement.

For MUDs, there are also game engines to simplify their building process, which, for example, take care of all the network-related stuff. The one I was playing with is called [Evennia](https://www.evennia.com). It's written in (and uses as the game language) Python what is a plus for me.

As MUDs are inherently simpler (programming-wise) than fancy 3D games, the engine itself doesn't have a lot of code, and I was able to find my way around it pretty quickly. I managed to add a way to display pictures, as I thought an occasional image here and there will make the puzzles more interesting.

In the end, I decided to try 2D graphics again, but as I liked the experience with Evennia I may go back to it some time (for a second game :).

### Godot

After my mixed experience with leading game engines, I looked around the internet more and found [Godot](godotengine.org/). It's a free and open-source game engine that supports both 2D and 3D games. Despite being a powerful game engine, the editor is light (<100 MB) and quick: building a scene takes <1 s, and many changes are hot-reloaded while the game is running. It is important for me, as I left my desktop in London for the pandemic and I'm left with only a laptop with no graphic card now.

I was surprised that even though the engine developers and not able to sponsor the content, there is a lot of tutorials and guides online for using Godot. At the same time, the majority of these tutorials are targeted at beginner programmers/kids; finding higher-level design guides for building big games wasn't easy.

#### Scene tree

The philosophy of game design in Godot revolves around building a *Scene* (which is vaguely equivalent to a *class* in Object-Oriented Programming) with a tree of *Nodes* (like fields, but you can arrange them hierarchically).

<figure>
![Example Scene tree in Godot.](../images/game_engines/godot_tree.png){width=60%}
</figure>

Being able to combine various elements not only in code but also using the editor UI is surprisingly natural for someone who typically only writes code. It particularly helps for visual things like images, as dragging the image to a correct place is simpler than guessing the correct position in code.

This feature is available not only for the built-in classes but also for any other field marked `export` by the programmer. Thanks to that and the extensibility of the engine, I was able to make a plugin that sets a `horizon_line` field in a background image based on a click position. It will make it easy to scale the sprite for the character with the rules of the perspective.

While I like the nodes system overall, I also have a complaint about it. As the `script` (code) is just a text file that can be attached to any number of nodes (not only scenes but also its elements). Because of that, there are many ways to achieve inheritance (sharing of code in a more specific object): you can either use *inherited scenes* or *extend* the script itself.

As a result, it's not clear which entities should be nodes and which should be scenes, and one needs to spend time making decisions that wouldn't be needed if there was only one class-like concept, owning its code as in the OOP principles. To some extent, this problem can be solved by establishing conventions on when to use scenes vs nodes.

#### Language

Godot engine is written in C++, but the default game development language is GDScript, a custom language built for Godot. While writing a whole language for the game engine feels too idiosyncratic to me (seriously, is there not enough unpopular languages?), I somewhat buy [the arguments of developers](https://docs.godotengine.org/en/stable/about/faq.html#what-were-the-motivations-behind-creating-gdscript): they wanted to have a dynamically-typed language but struggled with GIL in Python.

As there is, technically, a way to integrate Godot with Python, I was initially planning to use it, but in the end, GDScript ended up being close enough to Python that I couldn't care enough to spend time changing it.

Of course, it misses some syntactic-sugar features like f-strings or list comprehensions, but I didn't find anything too painful for me language-wise.

For completeness' sake, I should mention that Godot also offers a custom visual programming language (like Unreal's blueprints), and the integration with C# and C++ seems to be easier than the one with python.

## Final words

Game development is hard. I tried a couple of game engines which make the process much easier and ended up with Godot. My initial plans of making a story-rich online coop will probably be replaced with making a small point-and-click adventure game.

As of now, I have most of the story-independent code written and will move on to describe game scenes in more detail, likely followed by creating the assets. You can play the debug scene [here](../data/game_engines/maduka.html).
