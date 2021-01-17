# typo3-upload-ter GitHub Action
GitHub Action that helps you upload your Extensions to TER.

## !!! This is still work in progress.

## Example usage

```yaml
    uses: tomasnorre/typo3-upload-ter@v1
    with:
      username: ${{ secrets.TYPO3_ORG_USERNAME }}
      password: ${{ secrets.TYPO3_ORG_PASSWORD }}

```

### Requirement

You have to set your extensionkey in `composer.json`, this will soon be mandatory in all TYPO3 Extensions.

https://docs.typo3.org/m/typo3/reference-coreapi/master/en-us/ExtensionArchitecture/ComposerJson/Index.html#extra

**Example:**
```json 
"extra": {
    "typo3/cms": {
        "extension-key": "my_extensionkey",
    }
},
```

### Recommendation

It's recommended to add a `prepare-release` to your composer.json `script`-section, if this exists it will run before zipping and uploading.

This can be helpful to ensure that some files are removed before uploading.

**Example:**
```json
"prepare-release": [
    "@extension-create-libs",
    "rm -rf .devbox",
    "rm -rf Tests/",
    "rm .gitignore",
    "rm .scrutinizer.yml",
    "rm disabled.travis.yml"
],
```