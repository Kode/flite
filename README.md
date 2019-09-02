# Flite - Flash API implementation for Haxe

This is my own fork of the [InnoGames fork](https://github.com/innogames/openfl/) of the [OpenFL project](https://github.com/openfl/openfl).

The InnoGames fork is proven to be working well on HTML5 for their games and is constantly receiving fixes to improve it even more.

Unfortunately that fork is based on the very old version of OpenFL and it's very hard to update it for the modern upstream OpenFL due to big amount of
structural changes done in the upstream OpenFL and it's not safe to do so for the InnoGames production code, so it will most probably stay the same.

This project however is my personal attempt to strip down everything we don't use in the InnoGames fork and do some more invasive cleanups and refactorings.
For now I removed everything related to Lime (moved the leftovers into `openfl._internal`) and the only supported target is HTML5. After doing more refactorings
my plan is to port from HTML5 to Kha. (UPD: that's now in progress)
