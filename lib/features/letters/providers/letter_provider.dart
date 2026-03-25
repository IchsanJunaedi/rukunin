import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../auth/providers/auth_provider.dart';

// ==========================================
// Model
// ==========================================
class LetterModel {
  final String id;
  final String communityId;
  final String residentId;
  final String letterType;
  final String letterNumber;
  final String? purpose;
  final String? generatedContent;
  final String status;
  final DateTime createdAt;
  final Map<String, dynamic>? resident;

  LetterModel({
    required this.id,
    required this.communityId,
    required this.residentId,
    required this.letterType,
    required this.letterNumber,
    this.purpose,
    this.generatedContent,
    required this.status,
    required this.createdAt,
    this.resident,
  });

  factory LetterModel.fromMap(Map<String, dynamic> map) {
    return LetterModel(
      id: map['id'],
      communityId: map['community_id'],
      residentId: map['resident_id'],
      letterType: map['letter_type'],
      letterNumber: map['letter_number'],
      purpose: map['purpose'],
      generatedContent: map['generated_content'],
      status: map['status'] ?? 'draft',
      createdAt: DateTime.parse(map['created_at']),
      resident: map['profiles'] as Map<String, dynamic>?,
    );
  }
}

const letterTypeLabels = {
  'ktp_kk': 'Pengantar KTP & KK',
  'domisili': 'Keterangan Domisili (SKD)',
  'sktm': 'Keterangan Tidak Mampu (SKTM)',
  'skck': 'Pengantar SKCK',
  'kematian': 'Keterangan Kematian',
  'nikah': 'Pengantar Nikah',
  'sku': 'Keterangan Usaha (SKU)',
  'custom': 'Kustom / Lainnya',
};

// ==========================================
// Providers
// ==========================================

// Fetch letters list
final lettersProvider = FutureProvider.autoDispose<List<LetterModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final profile = await ref.watch(currentProfileProvider.future);
  final communityId = profile?['community_id'];
  if (communityId == null) return [];

  final response = await client
      .from('letters')
      .select('*, profiles:resident_id(full_name, unit_number)')
      .eq('community_id', communityId)
      .order('created_at', ascending: false)
      .limit(50);

  return (response as List).map((e) => LetterModel.fromMap(e)).toList();
});

// Fetch residents for picker
final residentsForLetterProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final profile = await ref.watch(currentProfileProvider.future);
  final communityId = profile?['community_id'];
  if (communityId == null) return [];

  final response = await client
      .from('profiles')
      .select('id, full_name, nik, unit_number')
      .eq('community_id', communityId)
      .eq('role', 'resident')
      .order('full_name');

  return (response as List).cast<Map<String, dynamic>>();
});

// Generate letter state
class GenerateLetterState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? result;

  GenerateLetterState({this.isLoading = false, this.error, this.result});

  GenerateLetterState copyWith({bool? isLoading, String? error, Map<String, dynamic>? result}) {
    return GenerateLetterState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      result: result ?? this.result,
    );
  }
}

class GenerateLetterNotifier extends Notifier<GenerateLetterState> {
  @override
  GenerateLetterState build() => GenerateLetterState();

  Future<void> generate({
    required String residentId,
    required String letterType,
    String? purpose,
  }) async {
    state = GenerateLetterState(isLoading: true);
    try {
      final client = ref.read(supabaseClientProvider);
      final profile = await ref.read(currentProfileProvider.future);
      final communityId = profile?['community_id'];
      if (communityId == null) throw Exception('Community ID tidak ditemukan');

      final response = await client.functions.invoke('generate-letter', body: {
        'community_id': communityId,
        'resident_id': residentId,
        'letter_type': letterType,
        'purpose': purpose,
      });

      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) throw Exception(data['error'] ?? 'Gagal generate surat');

      state = GenerateLetterState(result: data);
    } catch (e) {
      state = GenerateLetterState(error: e.toString());
    }
  }

  void reset() => state = GenerateLetterState();
}

final generateLetterProvider = NotifierProvider<GenerateLetterNotifier, GenerateLetterState>(
  GenerateLetterNotifier.new,
);

// Resident: surat saya yang sudah selesai (diisi di Task 5)
final myLettersProvider = FutureProvider.autoDispose<List<LetterModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final response = await client
      .from('letters')
      .select('*, profiles:resident_id(full_name, unit_number)')
      .eq('resident_id', userId)
      .order('created_at', ascending: false);

  return (response as List).map((e) => LetterModel.fromMap(e)).toList();
});
