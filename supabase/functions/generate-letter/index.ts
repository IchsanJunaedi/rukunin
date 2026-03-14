import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Groq from 'https://esm.sh/groq-sdk'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const letterTypePrompts: Record<string, string> = {
  'ktp_kk': 'Surat Pengantar Pembuatan/Perpanjangan KTP dan Kartu Keluarga',
  'domisili': 'Surat Keterangan Domisili (SKD)',
  'sktm': 'Surat Keterangan Tidak Mampu (SKTM)',
  'skck': 'Surat Pengantar Pengurusan SKCK (Surat Keterangan Catatan Kepolisian)',
  'kematian': 'Surat Keterangan Kematian',
  'nikah': 'Surat Pengantar Nikah (Surat N1/N2)',
  'sku': 'Surat Keterangan Usaha (SKU) Mikro/Kecil',
  'custom': 'Surat Keterangan',
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
    if (!groqApiKey) throw new Error('GROQ_API_KEY tidak ditemukan di Supabase Secrets')

    const groq = new Groq({ apiKey: groqApiKey })

    const {
      community_id,
      resident_id,
      letter_type,
      purpose, // Keperluan tambahan dari admin
    } = await req.json()

    if (!community_id || !resident_id || !letter_type) {
      return new Response(JSON.stringify({ success: false, error: 'community_id, resident_id, letter_type wajib diisi' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // 1. Ambil data warga dan komunitas
    const { data: resident, error: residentErr } = await supabase
      .from('profiles')
      .select('full_name, nik, gender, date_of_birth, place_of_birth, religion, marital_status, occupation, unit_number, phone')
      .eq('id', resident_id)
      .single()

    if (residentErr || !resident) throw new Error('Data warga tidak ditemukan')

    const { data: community, error: communityErr } = await supabase
      .from('communities')
      .select('name, village, district, city, province, rt_number, rw_number, leader_name')
      .eq('id', community_id)
      .single()

    if (communityErr || !community) throw new Error('Data komunitas tidak ditemukan')

    // 2. Hitung nomor surat otomatis
    const currentDate = new Date()
    const romanMonths = ['I','II','III','IV','V','VI','VII','VIII','IX','X','XI','XII']
    const romanMonth = romanMonths[currentDate.getMonth()]
    const year = currentDate.getFullYear()
    
    const { count: letterCount } = await supabase
      .from('letters')
      .select('*', { count: 'exact', head: true })
      .eq('community_id', community_id)

    const letterNumber = `${String((letterCount || 0) + 1).padStart(3, '0')}/RT-${community.rt_number || '01'}/RW-${community.rw_number || '01'}/${romanMonth}/${year}`

    // 3. Susun sistem prompt untuk LLaMA-3
    const namaJenisSurat = letterTypePrompts[letter_type] || 'Surat Keterangan'
    const genderText = resident.gender === 'male' ? 'Laki-laki' : 'Perempuan'
    const purposeText = purpose ? `Keperluan tambahan: ${purpose}` : ''

    // Hitung umur dari date_of_birth
    let ageText = ''
    if (resident.date_of_birth) {
      const birthDate = new Date(resident.date_of_birth)
      const age = Math.floor((currentDate.getTime() - birthDate.getTime()) / (365.25 * 24 * 60 * 60 * 1000))
      ageText = `${age} tahun`
    }

    const systemPrompt = `Kamu adalah aparatur desa/kelurahan yang sangat berpengalaman dalam membuat surat keterangan resmi RT/RW di Indonesia. Tulislah paragraf isi surat keterangan dengan bahasa Indonesia yang sangat baku, formal, dan mengikuti EYD. Jangan menulis kop, nomor surat, atau tanda tangan — hanya bagian PARAGRAF ISI saja (antara "Menerangkan bahwa:" dan "Demikian surat keterangan ini dibuat").

Data Warga:
- Nama: ${resident.full_name}
- NIK: ${resident.nik || '-'}
- Jenis Kelamin: ${genderText}
- TTL: ${resident.place_of_birth || '-'}, ${resident.date_of_birth || '-'}
- Umur: ${ageText}
- Agama: ${resident.religion || '-'}
- Status Perkawinan: ${resident.marital_status || '-'}
- Pekerjaan: ${resident.occupation || '-'}
- Alamat: RT ${community.rt_number}/RW ${community.rw_number}, ${community.village}, ${community.district}, ${community.city}
${purposeText}

Jenis Surat: ${namaJenisSurat}

Tulislah 2-3 paragraf isi surat yang menyatakan bahwa warga tersebut benar-benar tercatat sebagai penduduk di wilayah RT/RW tersebut, dan sebutkan secara spesifik keperluan surat ini sesuai jenis suratnya. Akhiri dengan frasa penutup standar tanpa "Demikian surat ini dibuat" karena itu akan ditulis secara terpisah.`

    // 4. Generate dengan Groq LLaMA-3
    const chatCompletion = await groq.chat.completions.create({
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: `Tuliskan isi ${namaJenisSurat} untuk warga bernama ${resident.full_name}.` }
      ],
      model: 'llama-3.3-70b-versatile',
      temperature: 0.3,
      max_tokens: 512,
    })

    const generatedContent = chatCompletion.choices[0]?.message?.content || ''

    // 5. Simpan ke database letters
    const { data: newLetter, error: insertErr } = await supabase.from('letters').insert({
      community_id,
      resident_id,
      letter_type,
      letter_number: letterNumber,
      purpose: purpose || '',
      generated_content: generatedContent,
      status: 'draft',
      created_at: new Date().toISOString(),
    }).select().single()

    if (insertErr) throw new Error(`Gagal menyimpan surat: ${insertErr.message}`)

    return new Response(JSON.stringify({
      success: true,
      letter_id: newLetter.id,
      letter_number: letterNumber,
      generated_content: generatedContent,
      resident: {
        full_name: resident.full_name,
        nik: resident.nik,
        gender: genderText,
        date_of_birth: resident.date_of_birth,
        place_of_birth: resident.place_of_birth,
        religion: resident.religion,
        marital_status: resident.marital_status,
        occupation: resident.occupation,
        age: ageText,
        address: `RT ${community.rt_number}/RW ${community.rw_number}, ${community.village}, ${community.district}, ${community.city}`,
      },
      community: {
        name: community.name,
        rt_number: community.rt_number,
        rw_number: community.rw_number,
        village: community.village,
        district: community.district,
        city: community.city,
        province: community.province,
        leader_name: community.leader_name,
      },
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (error: any) {
    console.error('generate-letter error:', error.message)
    return new Response(JSON.stringify({ success: false, error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
