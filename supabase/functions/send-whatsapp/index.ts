import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { target, message } = await req.json()

    if (!target || !message) {
      return new Response(
        JSON.stringify({ success: false, error: 'Target and message are required' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const FONNTE_API_KEY = Deno.env.get('FONNTE_API_KEY')
    if (!FONNTE_API_KEY) {
      return new Response(
        JSON.stringify({ success: false, error: 'FONNTE_API_KEY tidak ditemukan di environment' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Auto-format nomor: 08xxx -> 628xxx, +62xxx -> 62xxx
    let formattedTarget = target.toString().trim()
    if (formattedTarget.startsWith('+62')) {
      formattedTarget = formattedTarget.substring(1)
    } else if (formattedTarget.startsWith('0')) {
      formattedTarget = '62' + formattedTarget.substring(1)
    }

    console.log(`[send-whatsapp] Sending to: ${formattedTarget}`)

    const res = await fetch('https://api.fonnte.com/send', {
      method: 'POST',
      headers: {
        'Authorization': FONNTE_API_KEY,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        target: formattedTarget,
        message: message,
        countryCode: '62'
      })
    })

    const data = await res.json()
    console.log(`[send-whatsapp] Fonnte response: ${JSON.stringify(data)}`)

    if (data.status === false) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: data.reason || 'Fonnte menolak pengiriman',
          fonnte: data
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({ success: true, fonnte: data }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error: any) {
    console.error(`[send-whatsapp] Exception: ${error.message}`)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
