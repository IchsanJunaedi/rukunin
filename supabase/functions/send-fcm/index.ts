import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

// ─── Helper: PEM → ArrayBuffer ────────────────────────────────────────────────

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '')
  const binary = atob(b64)
  const buffer = new ArrayBuffer(binary.length)
  const view = new Uint8Array(buffer)
  for (let i = 0; i < binary.length; i++) {
    view[i] = binary.charCodeAt(i)
  }
  return buffer
}

// ─── Helper: buat JWT untuk Google OAuth2 ─────────────────────────────────────

async function createJwt(clientEmail: string, privateKeyPem: string): Promise<string> {
  const now = Math.floor(Date.now() / 1000)

  const header = { alg: 'RS256', typ: 'JWT' }
  const payload = {
    iss: clientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }

  const encode = (obj: object) =>
    btoa(JSON.stringify(obj))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=+$/, '')

  const headerB64 = encode(header)
  const payloadB64 = encode(payload)
  const signingInput = `${headerB64}.${payloadB64}`

  const keyBuffer = pemToArrayBuffer(privateKeyPem)
  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    keyBuffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(signingInput),
  )

  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '')

  return `${signingInput}.${sigB64}`
}

// ─── Helper: tukar JWT → Access Token ─────────────────────────────────────────

async function getAccessToken(clientEmail: string, privateKeyPem: string): Promise<string> {
  const jwt = await createJwt(clientEmail, privateKeyPem)

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })

  const data = await res.json()
  if (!data.access_token) {
    throw new Error(`Gagal dapat access token: ${JSON.stringify(data)}`)
  }
  return data.access_token as string
}

// ─── Main Handler ─────────────────────────────────────────────────────────────

interface FcmPayload {
  token: string
  title: string
  body?: string
  data?: Record<string, string>
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const payload: FcmPayload = await req.json()

    if (!payload.token || !payload.title) {
      return new Response(
        JSON.stringify({ success: false, error: 'token dan title wajib diisi' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 },
      )
    }

    const projectId = Deno.env.get('FIREBASE_PROJECT_ID')
    const clientEmail = Deno.env.get('FIREBASE_CLIENT_EMAIL')
    const privateKey = Deno.env.get('FIREBASE_PRIVATE_KEY')

    if (!projectId || !clientEmail || !privateKey) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, atau FIREBASE_PRIVATE_KEY belum dikonfigurasi',
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 },
      )
    }

    // Private key dari env mungkin memakai literal \n — ubah ke newline asli
    const privateKeyPem = privateKey.replace(/\\n/g, '\n')

    const accessToken = await getAccessToken(clientEmail, privateKeyPem)

    const fcmRes = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: {
            token: payload.token,
            notification: {
              title: payload.title,
              body: payload.body ?? '',
            },
            data: payload.data ?? {},
            android: {
              priority: 'HIGH',
              notification: { sound: 'default' },
            },
          },
        }),
      },
    )

    const result = await fcmRes.json()
    const success = fcmRes.ok

    return new Response(JSON.stringify({ success, result }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: (error as Error).message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 },
    )
  }
})
