<?php

/*
| CORS: mengizinkan aplikasi mobile (Flutter) dan web lain memanggil /api/*
*/

return [
    'paths' => ['api/*'],
    'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    'allowed_origins' => ['*'],
    'allowed_origins_patterns' => [],
    'allowed_headers' => ['Content-Type', 'Authorization', 'Accept'],
    'exposed_headers' => [],
    'max_age' => 0,
    'supports_credentials' => false,
];
