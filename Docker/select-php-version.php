<?php

/*
 * Prints the first candidate version that satisfies a Composer constraint.
 *
 * Usage: php select-php-version.php <constraint> <version> [<version> ...]
 * Exit code 1 when no candidate satisfies the constraint, 3 when the constraint is invalid.
 */

require '/opt/tailor/vendor/autoload.php';

use Composer\Semver\Semver;

if ($argc < 3) {
    fwrite(STDERR, "Usage: select-php-version.php <constraint> <version> [<version> ...]\n");
    exit(2);
}

$constraint = $argv[1];
foreach (array_slice($argv, 2) as $version) {
    try {
        $satisfied = Semver::satisfies($version, $constraint);
    } catch (\UnexpectedValueException $e) {
        fwrite(STDERR, $e->getMessage() . "\n");
        exit(3);
    }
    if ($satisfied) {
        echo $version;
        exit(0);
    }
}

exit(1);
