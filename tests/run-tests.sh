#!/usr/bin/env bash
#
# Tests for the Docker image of the action.
#
# Usage: tests/run-tests.sh <image>
#
# Every test runs the image with Docker. No test makes a request to TER.

set -uo pipefail

IMAGE="${1:?Usage: tests/run-tests.sh <image>}"
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="$(mktemp -d)"
FAILURES=0
output=""

cleanup() {
  # Files created in the container belong to root.
  docker run --rm -v "$WORK_DIR:/work" --entrypoint sh "$IMAGE" -c 'rm -rf /work/*' >/dev/null 2>&1
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

# check <description> <command...>
# Runs the command. Prints "ok" if it succeeds, otherwise "not ok" and $output.
check() {
  local description="$1"
  shift
  if "$@"; then
    echo "ok - $description"
  else
    echo "not ok - $description"
    FAILURES=$((FAILURES + 1))
    echo "$output" | sed 's/^/    /'
  fi
}

# contains <text> <part>: succeeds if text contains part.
contains() {
  [[ "$1" == *"$2"* ]]
}

# --- Tailor -----------------------------------------------------------------

# /usr/local/bin/php is the PHP for prepare-release. Tailor must not use it,
# so the test points it to a binary that always fails.
output=$(docker run --rm --entrypoint sh "$IMAGE" -c 'ln -sf /bin/false /usr/local/bin/php && tailor --version' 2>&1)
check "tailor does not use the PHP for prepare-release" contains "$output" "Tailor"

# --- Entrypoint -------------------------------------------------------------

# new_repository <name> <require.php or "">
# Copies the fixture extension into a new git repository with the tag 1.2.3.
new_repository() {
  local dir="$WORK_DIR/$1"
  mkdir -p "$dir"
  cp -R "$TESTS_DIR/fixtures/extension/." "$dir/"
  if [[ -n "$2" ]]; then
    jq --arg c "$2" '.require.php = $c' "$TESTS_DIR/fixtures/extension/composer.json" > "$dir/composer.json"
  fi
  # No signing, so that the git configuration of the host cannot change the tag message.
  local git=(git -C "$dir" -c user.name=Test -c user.email=test@example.org -c commit.gpgSign=false -c tag.gpgSign=false)
  "${git[@]}" init -q
  "${git[@]}" add -A
  "${git[@]}" commit -q -m "Initial commit"
  "${git[@]}" tag -a 1.2.3 -m "Release 1.2.3"
  echo "$dir"
}

# run_entrypoint <repository> <php-version input>
# Runs the entrypoint with tests/fixtures/tailor-stub.sh in place of tailor.
# The stub writes its arguments to tailor-args.txt.
run_entrypoint() {
  docker run --rm \
    -v "$1:/github/workspace" -w /github/workspace \
    -v "$TESTS_DIR/fixtures/tailor-stub.sh:/usr/local/bin/tailor:ro" \
    -e GITHUB_REF=refs/tags/v1.2.3 \
    "$IMAGE" test-token "$2" 2>&1
}

# prepare-release in the fixture writes its PHP version to prepare-release-php.txt.
prepare_release_php() {
  cat "$1/prepare-release-php.txt" 2>/dev/null
}

# require.php, php-version input, expected PHP version for prepare-release. "-" is empty.
case_number=0
while read -r constraint input expected; do
  [[ "$constraint" == "-" ]] && constraint=""
  [[ "$input" == "-" ]] && input=""
  case_number=$((case_number + 1))
  dir=$(new_repository "case-$case_number" "$constraint")
  output=$(run_entrypoint "$dir" "$input")
  check "require.php '$constraint', php-version '$input': PHP $expected" test "$(prepare_release_php "$dir")" = "$expected"
done <<'CASES'
-         -     8.5
^8.2      -     8.5
~8.3.0    -     8.3
>=8.3,<8.5 -     8.4
~8.4.0    auto  8.4
^8.2      8.3   8.3
~8.3.0    8.4   8.4
~8.3.0    8.1   8.3
~8.3.0    8.2   8.3
~8.2.0    -     8.5
CASES

dir=$(new_repository removed-version "~8.3.0")
output=$(run_entrypoint "$dir" 8.2)
check "php-version 8.2 prints a warning" contains "$output" "::warning::PHP 8.2 is no longer available"

dir=$(new_repository unsatisfiable "~8.2.0")
output=$(run_entrypoint "$dir" "")
check "require.php that no PHP satisfies prints a warning" contains "$output" "::warning::No installed PHP version"

dir=$(new_repository invalid-constraint "not a constraint")
output=$(run_entrypoint "$dir" "")
check "require.php that cannot be parsed prints a warning" contains "$output" "::warning::No installed PHP version"
# Composer itself stops prepare-release here, so the test reads the log.
check "require.php that cannot be parsed: PHP 8.5" contains "$output" "Using PHP 8.5 for prepare-release"

dir=$(new_repository unsupported-input "^8.2")
output=$(run_entrypoint "$dir" 7.4)
status=$?
check "php-version 7.4 prints an error" contains "$output" "::error::PHP 7.4 is not available"
check "php-version 7.4 stops the action" test "$status" -ne 0
check "php-version 7.4 publishes nothing" test ! -e "$dir/tailor-args.txt"

dir=$(new_repository publish-arguments "^8.2")
output=$(run_entrypoint "$dir" "")
check "tailor gets the tag message and the version" \
  test "$(cat "$dir/tailor-args.txt" 2>/dev/null)" = "ter:publish --comment=Release 1.2.3 1.2.3"

# --- Entrypoint with the real tailor and a fake TER -------------------------

# tests/fixtures/fake-ter.php answers like TER and writes the request to fake-ter-request.json.
# GitHub Actions mounts HOME=/github/home into the container, so the test creates it.
dir=$(new_repository fake-ter "^8.2")
cp "$TESTS_DIR/fixtures/fake-ter.php" "$WORK_DIR/fake-ter.php"
output=$(docker run --rm \
  -v "$dir:/github/workspace" -w /github/workspace \
  -v "$WORK_DIR/fake-ter.php:/fake-ter/router.php:ro" \
  -e GITHUB_REF=refs/tags/v1.2.3 -e HOME=/github/home \
  -e TYPO3_REMOTE_BASE_URI=http://127.0.0.1:8080/ \
  --entrypoint bash "$IMAGE" \
  -c 'mkdir -p "$HOME" && php85 -S 127.0.0.1:8080 -t /github/workspace /fake-ter/router.php >/dev/null 2>&1 & sleep 1; /entrypoint.sh test-token auto' 2>&1)
status=$?
request=$(cat "$dir/fake-ter-request.json" 2>/dev/null)
output="$output
Request: $request"
check "upload: the action succeeds" test "$status" -eq 0
check "upload: method and path" test "$(jq -r '.method + " " + .uri' <<< "$request")" = "POST /api/v1/extension/test_extension/1.2.3"
check "upload: token" test "$(jq -r '.authorization' <<< "$request")" = "Bearer test-token"
check "upload: tag message" test "$(jq -r '.description' <<< "$request")" = "Release 1.2.3"
check "upload: checksum of the archive" test "$(jq -r '.sha256Matches' <<< "$request")" = "true"

echo
echo "$FAILURES failed"
[[ $FAILURES -eq 0 ]]
