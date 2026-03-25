// Fixture data maps for all 12 models.
// Use these in unit tests instead of hardcoding maps inline.

const invoiceMap = {
  'id': 'inv-1',
  'community_id': 'com-1',
  'resident_id': 'res-1',
  'billing_type_id': 'bt-1',
  'amount': '150000',
  'month': 3,
  'year': 2026,
  'due_date': '2026-03-31',
  'status': 'pending',
  'payment_link': null,
  'payment_token': null,
  'wa_sent_at': null,
  'created_at': '2026-03-01T00:00:00.000Z',
  'billing_types': {'name': 'Iuran Bulanan'},
};

const residentMap = {
  'id': 'res-1',
  'community_id': 'com-1',
  'full_name': 'Budi Santoso',
  'unit_number': '12',
  'phone': '08123456789',
  'nik': '3275010101010001',
  'email': 'budi@example.com',
  'status': 'active',
  'photo_url': null,
  'rt_number': 2,
  'block': 'A',
  'motorcycle_count': 1,
  'car_count': 0,
  'created_at': '2026-01-01T00:00:00.000Z',
};

const expenseMap = {
  'id': 'exp-1',
  'community_id': 'com-1',
  'amount': '250000',
  'category': 'Kebersihan',
  'description': 'Bayar tukang sampah',
  'receipt_url': null,
  'expense_date': '2026-03-15',
  'created_by': 'admin-1',
  'created_at': '2026-03-15T10:00:00.000Z',
};

const billingTypeMap = {
  'id': 'bt-1',
  'community_id': 'com-1',
  'name': 'Iuran Bulanan',
  'amount': '150000',
  'billing_day': 10,
  'is_active': true,
  'cost_per_motorcycle': '25000',
  'cost_per_car': '50000',
  'created_at': '2026-01-01T00:00:00.000Z',
};

const announcementMap = {
  'id': 'ann-1',
  'community_id': 'com-1',
  'title': 'Rapat Warga',
  'body': 'Rapat warga akan diadakan pada hari Sabtu.',
  'type': 'info',
  'created_by': 'admin-1',
  'created_at': '2026-03-20T08:00:00.000Z',
};

const complaintMap = {
  'id': 'cmp-1',
  'community_id': 'com-1',
  'resident_id': 'res-1',
  'title': 'Lampu Jalan Mati',
  'description': 'Lampu jalan di depan blok A mati sejak seminggu lalu.',
  'category': 'infrastruktur',
  'status': 'pending',
  'admin_notes': null,
  'photo_url': null,
  'created_at': '2026-03-19T10:00:00.000Z',
  'updated_at': '2026-03-19T10:00:00.000Z',
  'profiles': {'full_name': 'Budi Santoso', 'unit_number': '12'},
};

const letterRequestMap = {
  'id': 'req-1',
  'community_id': 'com-1',
  'resident_id': 'res-1',
  'letter_type': 'domisili',
  'purpose': 'Melamar kerja',
  'notes': null,
  'status': 'pending',
  'admin_notes': null,
  'letter_id': null,
  'created_at': '2026-03-19T10:00:00.000Z',
  'updated_at': '2026-03-19T10:00:00.000Z',
  'profiles': {'full_name': 'Budi Santoso', 'unit_number': '12'},
};

const communityContactMap = {
  'id': 'cc-1',
  'community_id': 'com-1',
  'nama': 'Ahmad Ridwan',
  'jabatan': 'Ketua RT',
  'phone': '08111222333',
  'photo_url': null,
  'urutan': 1,
  'created_at': '2026-03-01T00:00:00.000Z',
  'updated_at': '2026-03-01T00:00:00.000Z',
};

const marketplaceListingMap = {
  'id': 'ml-1',
  'community_id': 'com-1',
  'seller_id': 'res-1',
  'title': 'Nasi Uduk',
  'description': 'Nasi uduk komplit dengan lauk',
  'price': 15000,
  'category': 'makanan',
  'images': ['https://example.com/img1.jpg'],
  'status': 'active',
  'stock': 10,
  'created_at': '2026-03-10T07:00:00.000Z',
  'profiles': {
    'full_name': 'Sari Wulandari',
    'phone': '08199887766',
    'unit_number': '5',
    'photo_url': null,
  },
};

const notificationMap = {
  'id': 'notif-1',
  'community_id': 'com-1',
  'user_id': 'res-1',
  'type': 'payment',
  'title': 'Tagihan Bulan Maret',
  'body': 'Tagihan iuran bulan Maret sudah tersedia.',
  'is_read': false,
  'metadata': null,
  'created_at': '2026-03-01T08:00:00.000Z',
};

const familyMemberMap = {
  'id': 'fm-1',
  'resident_id': 'res-1',
  'full_name': 'Siti Aminah',
  'nik': '3275010101010002',
  'relationship': 'Istri',
};
