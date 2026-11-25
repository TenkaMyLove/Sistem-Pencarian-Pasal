<?php

namespace App\Http\Controllers;

use App\Models\PushSubscription;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

/**
 * Langganan Web Push per perangkat/browser (dipanggil oleh /js/notification.js).
 */
class NotifikasiController extends Controller
{
    /** POST /notifikasi/langganan — simpan/perbarui langganan perangkat ini untuk pegawai yang login */
    public function langganan(Request $request): JsonResponse
    {
        $data = $request->validate([
            'endpoint' => ['required', 'string', 'url:https', 'max:2000'],
            'keys.p256dh' => ['required', 'string', 'max:255'],
            'keys.auth' => ['required', 'string', 'max:255'],
            'contentEncoding' => ['nullable', 'in:aes128gcm,aesgcm'],
        ]);

        PushSubscription::updateOrCreate(
            ['endpoint_hash' => PushSubscription::hashEndpoint($data['endpoint'])],
            [
                'pengguna_id' => $request->attributes->get('user')['id'],
                'endpoint' => $data['endpoint'],
                'public_key' => $data['keys']['p256dh'],
                'auth_token' => $data['keys']['auth'],
                'content_encoding' => $data['contentEncoding'] ?? 'aes128gcm',
                'user_agent' => Str::limit((string) $request->userAgent(), 250, ''),
            ],
        );

        return response()->json(['success' => true]);
    }

    /**
     * POST /notifikasi/berhenti — hapus langganan perangkat ini (tombol matikan / saat logout).
     * Tidak memerlukan login: endpoint push bersifat rahasia per perangkat.
     */
    public function berhenti(Request $request): JsonResponse
    {
        $endpoint = (string) $request->input('endpoint');
        if ($endpoint !== '') {
            PushSubscription::where('endpoint_hash', PushSubscription::hashEndpoint($endpoint))->delete();
        }

        return response()->json(['success' => true]);
    }
}
