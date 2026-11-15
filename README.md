# typo3-upload-ter GitHub Action
GitHub Action that helps you upload your Extensions to [TER](https://extensions.typo3.org).

The action runs TYPO3 Tailor on PHP 8.5 and uploads the files in the workspace.

## Example usage

```yaml
name: TERUpload

on:
  push:
    tags:
      - "**"

jobs:
  TERUpload:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
    steps:
      - uses: actions/checkout@v7
      - uses: tomasnorre/typo3-upload-ter@v4
        with:
          api-token: ${{ secrets.TYPO3_API_TOKEN }}
```

### Upgrading from v3

v4 changes two things:

- The action no longer runs `composer prepare-release`. If your `composer.json` has this script, add it as a step before the action, as in the [Recommendation](#recommendation) below.
- v4 has no `php-version` input. Tailor always runs on PHP 8.5. Remove the input from your workflow.

### Requirement

You have to set your extension-key in `composer.json`, this is mandatory for all TYPO3 Extensions.

https://docs.typo3.org/m/typo3/reference-coreapi/master/en-us/ExtensionArchitecture/ComposerJson/Index.html#extra

**Example:**
```json
"extra": {
    "typo3/cms": {
        "extension-key": "my_extensionkey",
    }
},
```

### Information

The changelog message will be the message of your annotated tag, otherwise the commit message of the `tag`. Both `X.Y.Z` and `vX.Y.Z`-formatted tags are accepted.

### Recommendation

To remove files before the upload, run a script in a step before the action, with the PHP version that your extension needs. The step must be in the same job as the action, because a second job gets a new checkout.

```yaml
    steps:
      - uses: actions/checkout@v7
      - uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'
      - run: composer prepare-release
      - uses: tomasnorre/typo3-upload-ter@v4
        with:
          api-token: ${{ secrets.TYPO3_API_TOKEN }}
```

**Example of a `prepare-release` script in `composer.json`:**
```json
"scripts": {
    "prepare-release": [
        "@extension-create-libs",
        "rm -rf .devbox",
        "rm -rf Tests/",
        "rm .gitignore",
        "rm .scrutinizer.yml",
        "rm disabled.travis.yml"
    ]
}
```
