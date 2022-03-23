---
title: "Escape from Auschwitz: a fan T.I.M.E stories scenario"
---

Ever since I got T.I.M.E stories for Christmas a couple of years ago, I was planning to make a fan scenario. I have finally found some time to develop the expansion recently.

T.I.M.E stories is a decksploration board game, about which I wrote a bit [here](https://sygnowski.ml/posts/2020-06-19-time-stories.html). The game itself defines mechanics (somewhat similarly to e.g. RPGs) and sells different scenarios (stories) as expansions. There's a [long list](https://boardgamegeek.com/geeklist/225429/time-stories-print-and-play-scenarios-available-bg) of fan-made scenarios, many of which are really high-quality[^1].

[^1]: I played [Switching Gears](https://boardgamegeek.com/boardgame/200443/switching-gears-fan-expansion-time-stories) and [Pariah Missouri](https://boardgamegeek.com/boardgame/205847/pariah-missouri-fan-expansion-time-stories), and [Varsovia 2100](https://repository.rebel.pl/wydawnictwo/timestories/Varsovia_2100.pdf).

The high-level idea for the story (mild spoilers ahead) is the daring [escape](https://en.wikipedia.org/wiki/Kazimierz_Piechowski) of Kazimierz Piechowski and his fellows from Auschwitz concentration camp.

## Preparations

Initially, the story was meant to be about the escape of [Witold Pilecki](https://en.wikipedia.org/wiki/Witold_Pilecki), but after reading the details of his story I felt that the escape alone was not a worthy enough element of his biography. The escape of Piechowski seemed to fit the mechanics of time stories better.

To better understand the living conditions in the camp, I read [Pilecki's Report](https://en.wikipedia.org/wiki/Pilecki's_Report): a document written by Pilecki and smuggled out by Stanisław Jaster.

I chose that obtaining this report will be the main topic of my scenario.

I also collected maps of Auschwitz I and, with the help of a historian friend, found [the details of this particular escape](http://lekcja.auschwitz.org/en_15_ucieczki/). I tried keeping the scenario close to the real event, although I made small changes to drive the story.

## Technical

I kept notes on the game setting in a markdown note. In there, I wrote there decisions on puzzles, the mechanism to leave and enter the inner camp, locations, the meaning of state tokens, and the like.

As the details of each location started to grow with the actual card texts, I moved them to a separate markdown file. I then wrote a short program that converted this file to a filetree with directories corresponding to locations and png files of each card with the rendered texts.

## Inkscape

After the list of locations and their contents was more or less decided, I started creating the actual cards. I was (still am) planning to create custom graphics for the locations, so I left the backs of the cards blank (apart from location names) and worked mostly on the fronts.

I made the cards in [Inkscape](https://inkscape.org): it was a relatively nice experience. For one type of cards (front, backs, A-cards, etc.) I pasted the background texture and locked it and was adding things on top of it.
When I was adding new elements like shields, tokens, but also choosing the design of text boxes, I was saving a new copy of the "template" card with the additional elements placed outside of the page. This way, I had a file with dozens of tokens, shields, and others ready to be drag and drop to the card page in the default svg template.

One particularly useful thing was the ability to create a card from a given subset of the image file, so I was able to create a couple of cards laying next to each other and easily cut them into separate cards. It was useful in creating the map and a multi-card puzzle.

## Graphic design
All of the graphic elements I used so far weren't created by me. I was surprised I was able to find free fonts (with a license allowing me to use them) on [1001fonts.com](https://www.1001fonts.com), and paper-like textures on [www.myfreetextures.com](https://www.myfreetextures.com). I used a small number of images for item cards [pixabay.com](https://www.pixabay.com).

I made a couple of smaller graphic-design decisions like adding the semi-transparent text boxes below texts to improve readability.

I also chose a font and size for every type of text, with most typical texts written with Lato 15. 15 was quite big, which made it necessary to cut some texts, but I think having less text made the cards better.

## Playtests
I ran two playtests with friends. They discovered many important problems, e.g.:

- initially, I made a camp border a solid line, even around the camp gate and people didn't try to go there because they assumed it wasn't available
- the mechanic for leaving the camp was not explained clearly enough
- story was too linear

I hopefully was able to fix those to a large degree.

## Compiling
Once the cards were ready to play, I wrote a script that copied them in the correct order, as I was developing them in the directory tree based on the location name as above.

Then, I used a small subset of [heresy tools](http://heresy.mrtrashcan.com/home/the-tools/) to join the cards together in a print-and-play pdf.

## Remaining problems
I think my workflow was ok-ish, but definitely could be improved.

In particular, the compiling phase for me included many steps: running the reordering script, moving the cards, substituting alpha with a light-grey (so that empty cards are visible in a pdf), and running heresy tools. This felt like unnecessary manual labor. Using heresy tools in full promise to help with it, but the need to manually enter the sizes and shapes is a no-deal for me. Having a single-step compilation could also allow me to generate a pdf with texts as vector graphics without converting to pngs first as I do now.

Apart from this, my handling of card texts could be improved. Currently, I stored them both in the markdown file and the final svg. Because of this, whenever something needed to be changed, I had to make the change in both places. Also, manually copying the texts to svg caused them to not be positioned in the same way.

Finally, when I figured out how to properly justify text in Inkscape, I already had the texts placed everywhere, so I didn't bother to change them.

## Final words
Without further ado, this is [a link to the scenario](https://drive.google.com/file/d/1MzdS5eCEafiefC1Lmfx_WlrzFDWUweAh/view?usp=sharing) and its [BGG item page](https://rpggeek.com/geeklist/206708/item/8006732#item8006732).

I believe the whole game is finished, except for the custom graphics, which are not necessary for playing and will take a while to finish (it's around 50 images to draw).

If you end up playing it, I'll greatly appreciate [your feedback](https://forms.gle/Pf5pVWJfm1gusz4D6).

Apart from the images, I plan to do a Polish translation soon.

![Game "cover".](../images/auschwitz/cover.png){ width=50% }
