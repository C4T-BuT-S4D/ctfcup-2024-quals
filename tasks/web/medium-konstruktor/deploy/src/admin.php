<?

$token = $_GET["token"] ?? "";

if ($token !== $_ENV["SECRET_TOKEN"]) {
    http_response_code(403);
    exit();
}

$FLAG = $_ENV["FLAG"];

setcookie('flag', $FLAG, time() + 3600, '/');
header('Location: /');