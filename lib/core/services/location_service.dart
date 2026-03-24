import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// API dari emsifa.com — data wilayah Indonesia resmi
// Source: https://github.com/emsifa/api-wilayah-indonesia
const _baseUrl = 'https://www.emsifa.com/api-wilayah-indonesia/api';

class WilayahModel {
  final String id;
  final String name;
  WilayahModel({required this.id, required this.name});
  factory WilayahModel.fromMap(Map<String, dynamic> m) =>
      WilayahModel(id: m['id'].toString(), name: m['name'].toString());

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is WilayahModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class LocationService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<List<WilayahModel>> getProvinsi() async {
    final res = await _dio.get('$_baseUrl/provinces.json');
    return (res.data as List).map((e) => WilayahModel.fromMap(e)).toList();
  }

  Future<List<WilayahModel>> getKabupaten(String provinsiId) async {
    final res = await _dio.get('$_baseUrl/regencies/$provinsiId.json');
    return (res.data as List).map((e) => WilayahModel.fromMap(e)).toList();
  }

  Future<List<WilayahModel>> getKecamatan(String kabupatenId) async {
    final res = await _dio.get('$_baseUrl/districts/$kabupatenId.json');
    return (res.data as List).map((e) => WilayahModel.fromMap(e)).toList();
  }

  Future<List<WilayahModel>> getKelurahan(String kecamatanId) async {
    final res = await _dio.get('$_baseUrl/villages/$kecamatanId.json');
    return (res.data as List).map((e) => WilayahModel.fromMap(e)).toList();
  }
}

// Provider
final locationServiceProvider = Provider((ref) => LocationService());

final provinsiProvider = FutureProvider.autoDispose<List<WilayahModel>>((ref) {
  return ref.watch(locationServiceProvider).getProvinsi();
});

final kabupatenProvider =
    FutureProvider.autoDispose.family<List<WilayahModel>, String>(
  (ref, provinsiId) =>
      ref.watch(locationServiceProvider).getKabupaten(provinsiId),
);

final kecamatanProvider =
    FutureProvider.autoDispose.family<List<WilayahModel>, String>(
  (ref, kabupatenId) =>
      ref.watch(locationServiceProvider).getKecamatan(kabupatenId),
);

final kelurahanProvider =
    FutureProvider.autoDispose.family<List<WilayahModel>, String>(
  (ref, kecamatanId) =>
      ref.watch(locationServiceProvider).getKelurahan(kecamatanId),
);
