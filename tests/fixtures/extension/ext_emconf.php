<?php

$EM_CONF[$_EXTKEY] = [
    'title' => 'Test Extension',
    'description' => 'Fixture for the tests of the action',
    'category' => 'misc',
    'state' => 'stable',
    'author' => 'Test',
    'author_email' => 'test@example.org',
    'version' => '1.2.3',
    'constraints' => [
        'depends' => [
            'typo3' => '14.3.0-14.3.99',
        ],
    ],
];
