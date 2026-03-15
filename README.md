<h1>zmk-config</h1>

This is my [ZMK](https://github.com/zmkfirmware/zmk/) configuration,
which I am currently using on a [Chocofi](https://shop.beekeeb.com/products/presoldered-chocofi-split-keyboard)
and a [Sofle variant](https://ergomech.store/shop/sofle-hybrid-sandwich-style-423).

It uses the [Miryoku](https://github.com/manna-harbour/miryoku) layout,
as implemented by [Miryoku ZMK](https://github.com/manna-harbour/miryoku_zmk),
but builds with the standard ZMK build workflow instead of
[Miryoku ZMK's own](https://github.com/manna-harbour/miryoku_zmk/tree/master/.github/workflows).

<h2>Contents</h2>

<!-- TOC -->
  * [Using Miryoku in a standard ZMK build](#using-miryoku-in-a-standard-zmk-build)
  * [Macros on RGB keys](#macros-on-rgb-keys)
  * [How to add a new keyboard](#how-to-add-a-new-keyboard)
<!-- TOC -->

## Using Miryoku in a standard ZMK build

Ideally, Miryoku ZMK would be a ZMK module.
But it's not, and refactoring it to be a ZMK module
[might be a lot of work](https://github.com/zmkfirmware/zmk/issues/3157#issuecomment-3717328116),
so this repo implements a workaround.

Goals:

* Use Miryoku ZMK keymaps.
* Use the standard ZMK build workflow, instead of Miryoku ZMK's own.
* Customize Miryoku ZMK _without_ modifying it directly (so there is no need to fork it).

How this repo achieves those goals:

* Put Miryoku ZMK `.keymap` (and `.conf`) files in the `config` directory of a standard
  `zmk-config` repo.
* Add Miryoku ZMK to the build, as a West project for workflow builds,
  and as a Git submodule for local builds.
* Define another directory that contains customizations for Miryoku ZMK.
* Use a ZMK "snippet" to make the `#include` directives in Miryoku ZMK
  `.keymap` files resolve correctly.

In more detail:

1. Make Miryoku ZMK available to builds, at `modules/miryoku_zmk`.
    * For workflow builds, define Miryoku ZMK as a West project in [`west.yml`](config/west.yml).
    * For the convenience of local builds that don't use the same `west.yml` as workflow builds,
      define Miryoku ZMK as a Git submodule.
    * This works because workflow builds ignore Git submodules,
      and local builds are under manual control anyway.
      If a local build uses the same `west.yml` as workflow builds
      (or uses another `west.yml` that defines Miryoku ZMK as a West project at the same location)
      then it doesn't need to define a Git submodule.

2. Put the Miryoku ZMK `custom_config.h` file, 
   and any other customizations such as mappings for additional keyboards,
   under [`config/miryoku`](config/miryoku).

3. Miryoku ZMK `.keymap` files refer to other Miryoku ZMK files
   with `#include` directives like this:
    ```c++
    #include "../miryoku/custom_config.h"
    #include "../miryoku/mapping/42/corne.h"
    #include "../miryoku/miryoku.dtsi"
    ```
   I wanted these directives to refer to the customized files under `config/miryoku` if present,
   otherwise to the original Miryoku ZMK files under `modules/miryoku_zmk/miryoku`.
   [A ZMK "snippet" named `miryoku`](snippets/miryoku/snippet.yml) updates the paths
   used by the C preprocessor when processing Devicetree files to make this work.

4. The snippet needs to be used in builds that use Miryoku ZMK.
     * For workflow builds, add `snippet: miryoku` to each entry in `build.yaml`.
     * For local builds, add `-S miryoku` to the `west build` command.

5. With the above in place, Miryoku ZMK `.keymap` (and `.conf`) files can be copied unchanged
   from `modules/miryoku_zmk/config` into the `config` directory, and can be built
   with the standard ZMK build workflow.


## Macros on RGB keys

None of my keyboards have LEDs, and I wanted to use Miryoku's RGB control keys for macros.

To achieve this, `custom_config.h` looks for an adjacent file named `my_macros.h`.
If present, this file can define C preprocessor macros named `MY_MACRO_1` through `MY_MACRO_5`,
which are used as the `bindings` for ZMK macros named `&my_macro_1` through `&my_macro_5`.

For example:
```
#define MY_MACRO_1 \
  &macro_press &kp LSHFT &macro_tap &kp H &macro_release &kp LSHFT  \
  &macro_tap &kp E &kp L &kp L &kp O &kp EXCL
```

These ZMK macros are then bound to the keys that Miryoku uses for RGB controls,
by redefining `MIRYOKU_LAYER_MEDIA` in
[`custom_config.h`](config/miryoku/custom_config.h), as described in
[the Miryoku ZMK customization documentation](https://github.com/manna-harbour/miryoku_zmk#customisation).

`my_macros.h` is excluded from source control, and treated as optional, because sometimes
I wanted to put things in macros without pushing them to the source repository.

## How to add a new keyboard

* For a keyboard that Miryoku ZMK already supports, copy the `.keymap` file and any `.conf` files
  from `modules/miryoku_zmk/config` to the `config` directory.
* For a keyboard that Miryoku ZMK does not support, write a new `.keymap` file, just like you
  would for plain Miryoku ZMK, and put it in the `config` directory.
* Add a new entry or entries to `build.yaml` for the new keyboard. Be sure to add `snippet: miryoku`
  to the entry as described above.
