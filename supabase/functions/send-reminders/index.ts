import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const FONNTE_API_KEY = Deno.env.get('FONNTE_API_KEY') ?? ''
    
    const now = new Date()
    const month = now.getMonth() + 1
    const year = now.getFullYear()

    // Ambil semua tagihan pending bulan ini yang belum dikirimi WA
    const { data: invoices, error } = await supabase
      .from('invoices')
      .select(`
        id, amount, month, year, due_date,
        billing_types(name),
        profiles:resident_id(full_name, phone),
        communities!inner(name, bank_name, account_number, account_name)
      `)
      .eq('month', month)
      .eq('year', year)
      .or('status.eq.pending,status.eq.overdue')

    if (error) throw error
    if (!invoices || invoices.length === 0) {
      return new Response(
        JSON.stringify({ success: true, message: 'Tidak ada tagihan pending bulan ini' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    let sent = 0
    let failed = 0

    for (const inv of invoices) {
      const phone = (inv.profiles as any)?.phone
      if (!phone) { failed++; continue }

      // Format nomor
      let target = phone.toString().trim()
      if (target.startsWith('+62')) target = target.substring(1)
      else if (target.startsWith('0')) target = '62' + target.substring(1)

      const fullName = (inv.profiles as any)?.full_name ?? 'Warga'
      const billingName = (inv.billing_types as any)?.name ?? 'Iuran'
      const amount = parseFloat(inv.amount)
      const nominal = new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(amount)
      const community = (inv.communities as any)
      const rwName = community?.name ?? 'Pengurus RW'
      const bankInfo = community?.bank_name ? `\nBank ${community.bank_name}\nNo. Rek: ${community.account_number}\na/n: ${community.account_name}` : ''

      const message = `Halo *${fullName}*,\nPengingat dari ${rwName}!\n\nTagihan *${billingName}* bulan ${month}/${year} sebesar *${nominal}* masih belum lunas.\n\nSilakan transfer ke:${bankInfo}\n\nAbaikan jika sudah membayar. Terima kasih! 🙏`

      const res = await fetch('https://api.fonnte.com/send', {
        method: 'POST',
        headers: { 'Authorization': FONNTE_API_KEY, 'Content-Type': 'application/json' },
        body: JSON.stringify({ target, message, countryCode: '62' })
      })

      const data = await res.json()
      if (data.status === false) failed++
      else sent++
    }

    return new Response(
      JSON.stringify({ success: true, sent, failed }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error: any) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
