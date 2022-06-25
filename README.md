# Speedrun Tower

A couple years ago I wrote a Sega Genesis demo called [Retail Clerk '89](https://HuguesJohnson.com/rc89/). I decided to try making a general-purpose adventure-adjacent game engine out of that code. Instead I created a demo specifically intended for speedrunning.

Speedrun Tower is set in a building with a confusing elevator system. [The design is loosely described here](https://huguesjohnson.com/programming/genesis/random/).

Your goal is to reach the top floor and talk to your co-workers in the fewest steps possible. Unless of course your goal is to visit every floor or view every event in the fewest steps possible. That's three categories right there.

This demo was also an excuse to try different approaches for achieving pseudorandomness on the Sega Genesis.

I am very tempted to port this to other 68k platforms but there are no concrete plans.

**Project Status**

As of June 2022:

- Fully-playable demo that doesn't crash in any way I've found
- Tested on real Sega Genesis model 1 hardware
- So far no "unwinnable" game states have been produced - I don't know if I want to declare it "impossible" though
- I'd like to improve the dialog a bit
- I'd like to add some outdoor scenery

**Links**

[Project page with latest builds](https://HuguesJohnson.com/speedrun-tower/)

**Build Versions**

- Release build: Latest stable version of the demo. The floor connections are all randomized.
- Debug build: Also a stable build but with hard-coded random seeds so the floor connections will always be the same. Things that have timers (like the initial splash screen or text drawing) are faster.
- ATGames build: Same as release build but with hacks to fix the audio on the kind of ATGames devices you'd find at Dollar General.

**Building**

I have only ever built this using [vasm](http://sun.hasenbraten.de/vasm/) with the motorola syntax module. I have no reason to believe this won't work with any other 68000 assembler.

There are additional build tools that require Java 8+ in the /build-tools/ folder. These are not needed to compile the demo from source. However, they are needed if you want to customize sprites, collision maps, or change the memory map. [The source for those tools are here](https://github.com/huguesjohnson/DubbelLib).

**Disclaimers**

This demo is (obviously) not licensed by Sega, there is no relationship between the author of this demo and Sega.

The floors in the building are all loosely inspired by various dysfunctional buildings I've worked in or visited. The people and dialog are completely fictitious. 
