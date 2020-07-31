This directory contains resources that the Flutter team uses during 
the development of cocoon.

## Luci builder file
`cocoon_try_builders.json` contains the supported luci try builders 
for cocoon. It follows format:
```json
{
    "builders":[
        {
            "name":"xxx",
            "repo":"cocoon"
        }
    ]
}
```
This file will be mainly used in [`flutter/cocoon`](https://github.com/flutter/cocoon)
to trigger LUCI presubmit tasks.

If any new changes, please validate json contents by running
`dart validat_json.dart cocoon_try_builders.json`.

