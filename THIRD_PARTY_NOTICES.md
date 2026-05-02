# Third-Party Notices

## Mechvibes audio

Kutuk bundles keyboard audio from the MIT-licensed
[`hainguyents13/mechvibes`](https://github.com/hainguyents13/mechvibes)
repository.

Kutuk bundles keyboard sounds from two Mechvibes travel sound packs.

The default `Cherry MX Brown` pack comes from `mxbrown-travel`, whose upstream
config names it `MX Brown - Full Travel`. This pack includes regular,
spacebar, enter, and backspace audio files. The source files were renamed to
Kutuk's bundled sound-file convention:

- `press/GENERIC_R0.mp3` -> `cherry-mx-brown_regular_press_1.mp3`
- `press/GENERIC_R1.mp3` -> `cherry-mx-brown_regular_press_2.mp3`
- `press/GENERIC_R2.mp3` -> `cherry-mx-brown_regular_press_3.mp3`
- `press/GENERIC_R3.mp3` -> `cherry-mx-brown_regular_press_4.mp3`
- `press/GENERIC_R4.mp3` -> `cherry-mx-brown_regular_press_5.mp3`
- `release/GENERIC.mp3` -> `cherry-mx-brown_regular_release.mp3`
- `press/SPACE.mp3` -> `cherry-mx-brown_space_press.mp3`
- `release/SPACE.mp3` -> `cherry-mx-brown_space_release.mp3`
- `press/ENTER.mp3` -> `cherry-mx-brown_enter_press.mp3`
- `release/ENTER.mp3` -> `cherry-mx-brown_enter_release.mp3`
- `press/BACKSPACE.mp3` -> `cherry-mx-brown_backspace_press.mp3`
- `release/BACKSPACE.mp3` -> `cherry-mx-brown_backspace_release.mp3`

The optional `Cherry MX Blue` pack comes from `mxblue-travel`, whose upstream
config names it `MX Blue - Full Travel`. The current upstream folder includes
regular press and release audio only, so Kutuk uses its regular-key fallback
for spacebar, enter, backspace, and modifier keys in this pack:

- `press/GENERIC_R0.mp3` -> `cherry-mx-blue_regular_press_1.mp3`
- `press/GENERIC_R1.mp3` -> `cherry-mx-blue_regular_press_2.mp3`
- `press/GENERIC_R2.mp3` -> `cherry-mx-blue_regular_press_3.mp3`
- `press/GENERIC_R3.mp3` -> `cherry-mx-blue_regular_press_4.mp3`
- `press/GENERIC_R4.mp3` -> `cherry-mx-blue_regular_press_5.mp3`
- `release/GENERIC.mp3` -> `cherry-mx-blue_regular_release.mp3`

MIT License

Copyright (c) 2021 Hai Nguyen

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
