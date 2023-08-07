# Wiki Visualizer

When working on our wiki (https://github.com/flutter/flutter/wiki/) it
can help to see how the pages link together in real time.

The following command allows one to check out the Flutter wiki:

```bash
git clone git@github.com:flutter/flutter.wiki.git
```

Running the wiki_visualizer program from a checkout of the Flutter
wiki, and piping the output to the `sfdp` or `fdp` programs from the
Graphviz package, as follows, renders a PNG map of the wiki's internal
links:

```bash
dart run --enable-asserts ../cocoon/dev/wiki-visualizer/bin/wiki_visualizer.dart *.md | sfdp -Tpng > map.png
```

(This assumes `cocoon` is checked out in a sibling directory of the
Flutter wiki.)

For example, this image was rendered in this fashion:

![](https://github.com/flutter/flutter/assets/551196/344a626a-9fda-4be1-9c76-2e884f920eec)
