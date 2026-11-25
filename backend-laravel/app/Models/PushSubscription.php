<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Minishlink\WebPush\Subscription;

/** Tabel `push_subscriptions` — perangkat/browser pegawai yang mengaktifkan notifikasi Web Push. */
class PushSubscription extends Model
{
    protected $table = 'push_subscriptions';

    protected $fillable = [
        'pengguna_id', 'endpoint', 'endpoint_hash', 'public_key',
        'auth_token', 'content_encoding', 'user_agent',
    ];

    public static function hashEndpoint(string $endpoint): string
    {
        return hash('sha256', $endpoint);
    }

    /** Ubah menjadi objek Subscription milik library minishlink/web-push. */
    public function untukWebPush(): Subscription
    {
        return Subscription::create([
            'endpoint' => $this->endpoint,
            'publicKey' => $this->public_key,
            'authToken' => $this->auth_token,
            'contentEncoding' => $this->content_encoding ?: 'aes128gcm',
        ]);
    }
}
