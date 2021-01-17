# typo3-upload-ter GitHub Action
GitHub Action that helps you upload your Extensions to TER.

## !!! This is still work in progress.

## Inputs

### `extensionkey`
**Required** The Extension key that you want to upload.

### `username`
**Required** Your TYPO3.org Username - please use github.secrets

### `password`
**Required** Your TYPO3.org Password - please use github.secrets

## Example usage

```yaml 
    uses: tomasnorre/typo3-upload-ter@v1
    with:
        extkey: 'my_extension'
        tag: ${GITHUB_REF#refs/tags/}
        username: ${{ secrets.TYPO3_ORG_USERNAME }}
        password: ${{ secrets.TYPO3_ORG_PASSWORD }}
```