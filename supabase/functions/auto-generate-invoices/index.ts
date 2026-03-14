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

    const now = new Date()
    const month = now.getMonth() + 1
    const year = now.getFullYear()

    // Ambil semua komunitas
    const { data: communities, error: commError } = await supabase
      .from('communities')
      .select('id')

    if (commError) throw commError

    let totalGenerated = 0

    for (const community of communities ?? []) {
      // Ambil billing types aktif untuk komunitas ini
      const { data: billingTypes } = await supabase
        .from('billing_types')
        .select('id, amount, billing_day, cost_per_motorcycle, cost_per_car')
        .eq('community_id', community.id)
        .eq('is_active', true)

      if (!billingTypes || billingTypes.length === 0) continue

      // Ambil residents aktif
      const { data: residents } = await supabase
        .from('profiles')
        .select('id, motorcycle_count, car_count')
        .eq('community_id', community.id)
        .eq('role', 'resident')

      if (!residents || residents.length === 0) continue

      for (const bt of billingTypes) {
        // Cek apakah sudah ada tagihan bulan ini untuk billing type ini
        const { data: existing } = await supabase
          .from('invoices')
          .select('id')
          .eq('community_id', community.id)
          .eq('billing_type_id', bt.id)
          .eq('month', month)
          .eq('year', year)
          .limit(1)

        if (existing && existing.length > 0) continue // Sudah ada, skip

        const dueDate = new Date(year, month - 1, bt.billing_day)
        const invoicesData = residents.map((r: any) => {
          const motorCount = r.motorcycle_count ?? 0
          const carCount = r.car_count ?? 0
          const total = bt.amount + (motorCount * (bt.cost_per_motorcycle ?? 0)) + (carCount * (bt.cost_per_car ?? 0))
          return {
            community_id: community.id,
            resident_id: r.id,
            billing_type_id: bt.id,
            amount: total,
            month,
            year,
            due_date: dueDate.toISOString(),
            status: 'pending',
          }
        })

        const { error } = await supabase.from('invoices').insert(invoicesData)
        if (!error) totalGenerated += invoicesData.length
      }
    }

    return new Response(
      JSON.stringify({ success: true, message: `Generated ${totalGenerated} invoices for ${month}/${year}` }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error: any) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
