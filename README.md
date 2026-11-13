# typo3-upload-ter GitHub Action
GitHub Action that helps you upload your Extensions to [TER](https://extensions.typo3.org).

TYPO3 Tailor always runs on PHP 8.5.

The `php-version` input selects the PHP version for the `prepare-release` script in your `composer.json`. Supported values are 8.3, 8.4, 8.5 and `auto`. With `auto`, the default, the action uses the highest of these versions that satisfies `require.php` in your `composer.json`. If `composer.json` requires no PHP version, or no installed version satisfies it, PHP 8.5 is used.

The PHP version matters only if `prepare-release` runs PHP code, for example `composer install` or a PHP callback. A script that only removes files works with every version.

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
      - uses: tomasnorre/typo3-upload-ter@v3
        with:
          api-token: ${{ secrets.TYPO3_API_TOKEN }}
          # Optional, defaults to auto
          php-version: auto
```

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
