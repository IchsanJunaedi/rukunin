import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Groq from 'https://esm.sh/groq-sdk'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const groqApiKey = Deno.env.get('GROQ_API_KEY')
    if (!groqApiKey) {
      throw new Error('GROQ_API_KEY tidak ditemukan di Secrets')
    }

    const groq = new Groq({ apiKey: groqApiKey })
    const { question, community_id, month, year } = await req.json()

    const currentMonth = month || new Date().getMonth() + 1
    const currentYear = year || new Date().getFullYear()

    // 1. Data Fetching (Logika kamu sudah solid)
    const { data: invoices } = await supabase
      .from('invoices')
      .select('amount, status')
      .eq('community_id', community_id).eq('month', currentMonth).eq('year', currentYear)

    const { data: expenses } = await supabase
      .from('expenses')
      .select('amount')
      .eq('community_id', community_id)

    const totalCollected = invoices?.filter(inv => inv.status === 'paid').reduce((sum, inv) => sum + Number(inv.amount), 0) || 0
    const totalExpense = expenses?.reduce((sum, exp) => sum + Number(exp.amount), 0) || 0

    // 2. Prompt Engineering
    const context = `Kamu asisten keuangan RT/RW digital. Pemasukan: Rp${totalCollected.toLocaleString('id-ID')}, Pengeluaran: Rp${totalExpense.toLocaleString('id-ID')}. Jawablah dengan singkat dan ramah.`

    // 3. Panggil Groq (MODEL UPDATE 2026)
    const chatCompletion = await groq.chat.completions.create({
      messages: [
        { role: 'system', content: context },
        { role: 'user', content: question }
      ],
      // Ganti llama3-8b-8192 dengan model terbaru di bawah ini:
      model: 'llama-3.3-70b-versatile',
      temperature: 0.6,
      max_tokens: 1024,
    })

    const answer = chatCompletion.choices[0]?.message?.content || 'Maaf, saya sedang offline.'

    // 4. Simpan log (Pastikan nama kolom sesuai SQL: question, answer)
    await supabase.from('ai_logs').insert({
      community_id,
      question,
      answer,
      month: currentMonth,
      year: currentYear,
    })

    return new Response(JSON.stringify({ success: true, answer }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (error: any) {
    console.error('Software Engineer Log:', error.message)
    return new Response(JSON.stringify({ success: false, error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})