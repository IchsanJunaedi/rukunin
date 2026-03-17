import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const { communityId, announcementTitle, announcementBody } = await req.json();

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Fetch semua warga aktif di komunitas ini
  const { data: residents } = await supabase
    .from("profiles")
    .select("id")
    .eq("community_id", communityId)
    .eq("status", "active")
    .eq("role", "resident");

  if (!residents || residents.length === 0) {
    return new Response(JSON.stringify({ inserted: 0 }), { status: 200 });
  }

  // Batch insert notifikasi
  const notifications = residents.map((r: { id: string }) => ({
    community_id: communityId,
    user_id: r.id,
    type: "announcement",
    title: announcementTitle,
    body: announcementBody,
  }));

  await supabase.from("notifications").insert(notifications);

  return new Response(JSON.stringify({ inserted: notifications.length }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
