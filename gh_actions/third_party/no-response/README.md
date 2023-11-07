# No Response

 A GitHub Action that closes Issues where the author hasn't responded to a request for more information.

## Use

Recommended basic configuration:

```yaml
name: No Response

# Both `issue_comment` and `scheduled` event types are required for this Action
# to work properly.
on:
  issue_comment:
    types: [created]
  schedule:
    # Schedule for five minutes after the hour, every hour
    - cron: '5 * * * *'

jobs:
  noResponse:
    runs-on: ubuntu-latest
    steps:
      - uses: lee-dohm/no-response@v0.5.0
        with:
          token: ${{ github.token }}
```

### Inputs

See [`action.yml`](action.yml) for defaults.

- `closeComment` &mdash; Markdown text to post as a comment when an issue is going to be closed. Set to `false` to disable commenting when closing an issue.
- `daysUntilClose` &mdash; Number of days to wait for a response from the original author before closing.
- `responseRequiredColor` &mdash; Color for the `responseRequiredLabel`. **Only** used when creating the label if it does not already exist.
- `responseRequiredLabel` &mdash; Text of the label used to indicate that a response from the original author is required.
- `token` &mdash; Token used to access repo information. The default GitHub Actions token is sufficient.

### Outputs

None.

## Action flow

The intent of this Action is to close issues that have not received a response to a maintainer's request for more information. Many times issues will be filed without enough information to be properly investigated. This Action allows maintainers to label an issue as requiring more information from the original author. If the information is not received in a timely manner, the issue will be closed. If the original author comes back and gives more information, the label is removed and the issue is reopened, if necessary.

### Scheduled

At the scheduled times, it searches for issues that are:

- Open
- Have a label named the same as the `responseRequiredLabel` value in the configuration
- The `responseRequiredLabel` was applied more than `daysUntilClose` ago

For each issue found, it:

1. If `closeComment` is not `false`, posts the contents of `closeComment`
1. Closes the issue

### `issue_comment` Event

When an `issue_comment` event is received, if all of the following are true:

- The author of the comment is the original author of the issue
- The issue has a label named the same as the `responseRequiredLabel` value in the configuration

It will:

1. Remove the `responseRequiredLabel`
1. Reopen the issue if it was closed by someone other than the original author of the issue

## License

[MIT](LICENSE.md)
