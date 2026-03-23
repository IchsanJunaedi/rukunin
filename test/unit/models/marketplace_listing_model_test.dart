import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/marketplace/models/marketplace_listing_model.dart';
import '../../helpers/test_data.dart';

void main() {
  group('MarketplaceListingModel', () {
    test('fromMap parses all fields including nested profiles', () {
      final model = MarketplaceListingModel.fromMap(marketplaceListingMap);
      expect(model.id, 'ml-1');
      expect(model.title, 'Nasi Uduk');
      expect(model.price, 15000);
      expect(model.category, 'makanan');
      expect(model.sellerName, 'Sari Wulandari');
      expect(model.images, hasLength(1));
    });

    test('fromMap handles null profiles', () {
      final model = MarketplaceListingModel.fromMap({
        ...marketplaceListingMap,
        'profiles': null,
      });
      expect(model.sellerName, isNull);
      expect(model.sellerPhone, isNull);
    });

    test('fromMap handles null price', () {
      final model = MarketplaceListingModel.fromMap({
        ...marketplaceListingMap,
        'price': null,
      });
      expect(model.price, isNull);
    });

    test('formattedPrice returns Gratis / Nego for null price', () {
      final model = MarketplaceListingModel.fromMap({
        ...marketplaceListingMap,
        'price': null,
      });
      expect(model.formattedPrice, 'Gratis / Nego');
    });

    test('formattedPrice formats with Rp prefix', () {
      final model = MarketplaceListingModel.fromMap(marketplaceListingMap);
      expect(model.formattedPrice, 'Rp 15.000');
    });

    test('isAvailable is true for active status with stock > 0', () {
      final model = MarketplaceListingModel.fromMap(marketplaceListingMap);
      expect(model.isAvailable, isTrue);
    });

    test('isAvailable is false for sold status', () {
      final model = MarketplaceListingModel.fromMap({
        ...marketplaceListingMap,
        'status': 'sold',
      });
      expect(model.isAvailable, isFalse);
    });

    test('fromMap handles empty images list', () {
      final model = MarketplaceListingModel.fromMap({
        ...marketplaceListingMap,
        'images': [],
      });
      expect(model.images, isEmpty);
    });
  });
}
