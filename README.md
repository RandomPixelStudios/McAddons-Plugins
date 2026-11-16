# MC Addons Plugins

The community plugin registry for [MC Addons](https://github.com/RandomPixelStudios/McAddons).
Everything merged into `main` shows up in the in-game plugin browser (press **K**, or the **Plugins** button on the title / pause screen).

## Publish a plugin

1. Fork this repo.
2. Add a folder `plugins/<your_id>/` with at least `plugin.json` and `main.lua` (optional: `icon.png`, more `.lua` modules).
3. Open a pull request. CI validates the manifest, file types/sizes and Lua syntax.
4. A maintainer reviews the code and the requested permissions. After merge, CI regenerates `index.json`
   with download URLs pinned to the merge commit and a SHA-256 for every file.

Test locally first: copy the folder into `.minecraft/mcaddons/plugins/` – it hot-reloads on every save.

```bash
python3 scripts/build_index.py --check   # same validation CI runs
```

## Rules

* Allowed: `.lua .json .png .ogg .mcmeta .mcfunction .nbt .md .txt`, max 2 MiB per file, 16 MiB per plugin.
* `assets/` needs the `resources` permission, `data/` needs `data`.
* Request the smallest set of permissions you need. `commands.run` (run any command as console) gets extra scrutiny.
* No obfuscated code.

See the [Lua API reference](https://github.com/RandomPixelStudios/McAddons#lua-api) for everything a plugin can do.
