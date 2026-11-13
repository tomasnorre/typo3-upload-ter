#!/usr/bin/env bash
#
# Tests for the Docker image of the action.
#
# Usage: tests/run-tests.sh <image>
#
# The tests run the image with Docker. They make no request to TER:
# the entrypoint tests replace tailor with a stub that records its arguments.

set -uo pipefail

IMAGE="${1:?Usage: tests/run-tests.sh <image>}"
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="$(mktemp -d)"
FAILURES=0
PASSES=0

cleanup() {
  # Files created in the container belong to root.
  docker run --rm -v "$WORK_DIR:/work" --entrypoint sh "$IMAGE" -c 'rm -rf /work/*' >/dev/null 2>&1
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

pass() {
  PASSES=$((PASSES + 1))
  echo "ok - $1"
}

fail() {
  FAILURES=$((FAILURES + 1))
  echo "not ok - $1"
  if [[ -n "${2:-}" ]]; then
    while IFS= read -r line; do echo "    $line"; done <<< "$2"
  fi
}

run_in_image() {
  docker run --rm --entrypoint sh "$IMAGE" -c "$1" 2>&1
}

# --- Image contents ---------------------------------------------------------

for version in 8.3 8.4 8.5; do
  output=$(run_in_image "/usr/bin/php${version//./} -r 'echo PHP_MAJOR_VERSION.\".\".PHP_MINOR_VERSION;'")
  if [[ "$output" == "$version" ]]; then
    pass "php${version//./} reports PHP $version"
  else
    fail "php${version//./} reports PHP $version" "$output"
  fi
done

if run_in_image 'test ! -e /usr/bin/php82 && test ! -e /usr/bin/php81' >/dev/null; then
  pass "PHP 8.1 and 8.2 are not installed"
else
  fail "PHP 8.1 and 8.2 are not installed"
fi

# --- Tailor -----------------------------------------------------------------

# /usr/local/bin/php is the PHP that prepare-release uses. Tailor must not
# depend on it, so the test replaces it with a binary that always fails.
output=$(run_in_image 'ln -sf /bin/false /usr/local/bin/php && tailor --version')
if [[ "$output" == *"Tailor"* ]]; then
  pass "tailor runs without the PHP selected for prepare-release"
else
  fail "tailor runs without the PHP selected for prepare-release" "$output"
fi

mkdir -p "$WORK_DIR/artefact"
cp -R "$TESTS_DIR/fixtures/extension/." "$WORK_DIR/artefact/"
output=$(docker run --rm -v "$WORK_DIR/artefact:/ext" -w /ext --entrypoint sh "$IMAGE" \
  -c 'ln -sf /usr/bin/php83 /usr/local/bin/php && tailor create-artefact 1.2.3 && ls tailor-version-artefact' 2>&1)
if [[ "$output" == *"test_extension_1.2.3.zip"* ]]; then
  pass "tailor builds the archive of an extension"
else
  fail "tailor builds the archive of an extension" "$output"
fi

# --- Entrypoint: PHP version for prepare-release ----------------------------

# Copies the fixture extension into a new git repository with the tag 1.2.3.
# $1: name of the test directory, $2: require.php or "" for none
prepare_repository() {
  local dir="$WORK_DIR/$1" constraint="$2"
  mkdir -p "$dir"
  cp -R "$TESTS_DIR/fixtures/extension/." "$dir/"
  if [[ -n "$constraint" ]]; then
    jq --arg c "$constraint" '.require.php = $c' "$TESTS_DIR/fixtures/extension/composer.json" > "$dir/composer.json"
  fi
  # Signing is off, so that a signing setup of the host cannot change the tag message.
  local git=(git -C "$dir" -c user.name=Test -c user.email=test@example.org -c commit.gpgSign=false -c tag.gpgSign=false)
  "${git[@]}" init -q
  "${git[@]}" add -A
  "${git[@]}" commit -q -m "Initial commit"
  "${git[@]}" tag -a 1.2.3 -m "Release 1.2.3"
  echo "$dir"
}

# Runs the entrypoint with the stub tailor. Prints the output, returns its exit code.
# $1: repository directory, $2: php-version input
run_entrypoint() {
  docker run --rm \
    -v "$1:/github/workspace" -w /github/workspace \
    -v "$TESTS_DIR/fixtures/tailor-stub.sh:/usr/local/bin/tailor:ro" \
    -e GITHUB_REF=refs/tags/v1.2.3 \
    "$IMAGE" test-token "$2" 2>&1
}

# $1: test name, $2: require.php, $3: php-version input, $4: expected PHP version
assert_prepare_release_php() {
  local name="$1" dir output actual
  dir=$(prepare_repository "$name" "$2")
  output=$(run_entrypoint "$dir" "$3")
  actual=$(cat "$dir/prepare-release-php.txt" 2>/dev/null)
  if [[ "$actual" == "$4" && -f "$dir/tailor-args.txt" ]]; then
    pass "require.php '$2', php-version '$3': prepare-release runs on PHP $4"
  else
    fail "require.php '$2', php-version '$3': prepare-release runs on PHP $4 (got '$actual')" "$output"
  fi
}

assert_prepare_release_php no-constraint "" "" 8.5
assert_prepare_release_php caret-82 "^8.2" "" 8.5
assert_prepare_release_php tilde-83 "~8.3.0" "" 8.3
assert_prepare_release_php range-below-85 ">=8.3 <8.5" "" 8.4
assert_prepare_release_php auto-tilde-84 "~8.4.0" auto 8.4
assert_prepare_release_php explicit-83 "^8.2" 8.3 8.3
assert_prepare_release_php explicit-84 "~8.3.0" 8.4 8.4

dir=$(prepare_repository unsatisfiable "~8.2.0")
output=$(run_entrypoint "$dir" "")
if [[ "$(cat "$dir/prepare-release-php.txt" 2>/dev/null)" == "8.5" && "$output" == *"::warning::"*"~8.2.0"* ]]; then
  pass "no installed PHP satisfies require.php: warning and PHP 8.5"
else
  fail "no installed PHP satisfies require.php: warning and PHP 8.5" "$output"
fi

dir=$(prepare_repository invalid-constraint "not a constraint")
output=$(run_entrypoint "$dir" "")
if [[ "$output" == *"::warning::Could not read the PHP constraint"* && "$output" == *"Using PHP 8.5 for prepare-release"* ]]; then
  pass "unreadable require.php: warning and PHP 8.5"
else
  fail "unreadable require.php: warning and PHP 8.5" "$output"
fi

for removed in 8.1 8.2; do
  dir=$(prepare_repository "removed-$removed" "~8.3.0")
  output=$(run_entrypoint "$dir" "$removed")
  if [[ "$(cat "$dir/prepare-release-php.txt" 2>/dev/null)" == "8.3" && "$output" == *"::warning::PHP $removed is no longer available"* && -f "$dir/tailor-args.txt" ]]; then
    pass "php-version $removed: warning, then auto"
  else
    fail "php-version $removed: warning, then auto" "$output"
  fi
done

dir=$(prepare_repository unsupported-input "^8.2")
output=$(run_entrypoint "$dir" "7.4")
status=$?
if [[ $status -ne 0 && "$output" == *"::error::PHP 7.4 is not available"* && ! -e "$dir/tailor-args.txt" ]]; then
  pass "php-version 7.4: error, nothing is published"
else
  fail "php-version 7.4: error, nothing is published (exit $status)" "$output"
fi

dir=$(prepare_repository publish-arguments "^8.2")
output=$(run_entrypoint "$dir" "")
expected="ter:publish --comment=Release 1.2.3 1.2.3"
actual=$(cat "$dir/tailor-args.txt" 2>/dev/null)
if [[ "$actual" == "$expected" ]]; then
  pass "tailor ter:publish receives the tag message and the version"
else
  fail "tailor ter:publish receives the tag message and the version (got '$actual')" "$output"
fi

# --- Entrypoint with the real tailor against a fake TER ---------------------

dir=$(prepare_repository fake-ter "^8.2")
cp "$TESTS_DIR/fixtures/fake-ter.php" "$WORK_DIR/fake-ter.php"
# GitHub Actions mounts HOME=/github/home into the container; the test creates it.
output=$(docker run --rm \
  -v "$dir:/github/workspace" -w /github/workspace \
  -v "$WORK_DIR/fake-ter.php:/fake-ter/router.php:ro" \
  -e GITHUB_REF=refs/tags/v1.2.3 -e HOME=/github/home \
  -e TYPO3_REMOTE_BASE_URI=http://127.0.0.1:8080/ \
  --entrypoint bash "$IMAGE" \
  -c 'mkdir -p "$HOME" && php85 -S 127.0.0.1:8080 -t /github/workspace /fake-ter/router.php >/dev/null 2>&1 & sleep 1; /entrypoint.sh test-token auto' 2>&1)
status=$?
request=$(cat "$dir/fake-ter-request.json" 2>/dev/null)
if [[ $status -eq 0 ]] \
  && [[ "$(jq -r '.method + " " + .uri' <<< "$request")" == "POST /api/v1/extension/test_extension/1.2.3" ]] \
  && [[ "$(jq -r '.authorization' <<< "$request")" == "Bearer test-token" ]] \
  && [[ "$(jq -r '.description' <<< "$request")" == "Release 1.2.3" ]] \
  && [[ "$(jq -r '.sha256Matches' <<< "$request")" == "true" ]]; then
  pass "tailor ter:publish uploads the archive with token, version and tag message"
else
  fail "tailor ter:publish uploads the archive with token, version and tag message (exit $status)" "$output
$request"
fi

echo
echo "$PASSES passed, $FAILURES failed"
[[ $FAILURES -eq 0 ]]
