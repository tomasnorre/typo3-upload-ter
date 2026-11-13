<?php

// Prints the first version (arguments 2 to n) that satisfies the Composer constraint (argument 1).
// Exits with 1 if no version satisfies the constraint or if the constraint is not valid.

require '/opt/tailor/vendor/autoload.php';

foreach (array_slice($argv, 2) as $version) {
    try {
        if (Composer\Semver\Semver::satisfies($version, $argv[1])) {
            echo $version;
            exit(0);
        }
    } catch (UnexpectedValueException $e) {
        exit(1);
    }
}
exit(1);
