<?php

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    exit();
}

$data = json_decode(file_get_contents('php://input'), true);
if (json_last_error() !== JSON_ERROR_NONE) {
    http_response_code(400);
    exit();
}

$dir = $_ENV["DATA_DIRECTORY"];

function uuidv4()
{
  $data = random_bytes(16);

  $data[6] = chr(ord($data[6]) & 0x0f | 0x40); // set version to 0100
  $data[8] = chr(ord($data[8]) & 0x3f | 0x80); // set bits 6-7 to 10
    
  return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
}

$uuid = uuidv4();
$filename = "{$dir}/{$uuid}.json";

file_put_contents($filename, json_encode($data));

header('Content-Type: application/json; charset=utf-8');
echo json_encode(["uuid" => $uuid]);
