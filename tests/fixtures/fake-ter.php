<?php

/*
 * Replaces the TER REST API in the tests (router for `php -S`).
 * Records the request in fake-ter-request.json and answers like a successful upload.
 */

$file = $_FILES['file'] ?? null;
$request = [
    'method' => $_SERVER['REQUEST_METHOD'],
    'uri' => $_SERVER['REQUEST_URI'],
    'authorization' => $_SERVER['HTTP_AUTHORIZATION'] ?? '',
    'description' => $_POST['description'] ?? null,
    'gplCompliant' => $_POST['gplCompliant'] ?? null,
    'file' => $file['name'] ?? null,
    'sha256Matches' => $file !== null && hash_file('sha256', $file['tmp_name']) === ($_POST['sha256'] ?? ''),
];
file_put_contents(getcwd() . '/fake-ter-request.json', json_encode($request, JSON_PRETTY_PRINT));

header('Content-Type: application/json');
echo json_encode(['extension_key' => 'test_extension', 'version' => '1.2.3']);
