# typo3-upload-ter GitHub Action
GitHub Action that helps you upload your Extensions to [TER](https://extensions.typo3.org).

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
      - uses: actions/checkout@v1
      - uses: tomasnorre/typo3-upload-ter@v2
        with:
          api-token: ${{ secrets.TYPO3_API_TOKEN }}
```

### Requirement

You have to set your extension-key in `composer.json`, this will soon be mandatory in all TYPO3 Extensions.

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

The commit message will be you commit message of your `tag`, both `X.Y.Z` and `vX.Y.Z`-formatted tags are accepted.

### Recommendation

It's recommended to add a `prepare-release` to your composer.json `script`-section, if this exists it will run before zipping and uploading.

This can be helpful to ensure that some files are removed before uploading.

**Example:**
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