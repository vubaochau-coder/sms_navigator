import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/features/sender/data/models/whitelist_config_model.dart';

void main() {
  group('WhitelistEntryModel', () {
    test('toMap serializes address and allowOtp', () {
      const entry = WhitelistEntryModel(address: 'VCB', allowOtp: true);
      expect(entry.toMap(), {'address': 'VCB', 'allowOtp': true});
    });

    test('fromMap parses valid map', () {
      final entry = WhitelistEntryModel.fromMap({
        'address': ' +8498 ',
        'allowOtp': true,
      });
      expect(entry.address, '+8498');
      expect(entry.allowOtp, isTrue);
    });

    test('fromMap defaults allowOtp to false', () {
      final entry = WhitelistEntryModel.fromMap({'address': 'VCB'});
      expect(entry.allowOtp, isFalse);
    });

    test('fromMap handles missing address', () {
      final entry = WhitelistEntryModel.fromMap({});
      expect(entry.address, isEmpty);
      expect(entry.allowOtp, isFalse);
    });

    test('copyWith overrides only provided fields', () {
      const entry = WhitelistEntryModel(address: 'VCB');
      final updated = entry.copyWith(allowOtp: true);
      expect(updated.address, 'VCB');
      expect(updated.allowOtp, isTrue);
    });

    test('equatable compares by value', () {
      expect(
        const WhitelistEntryModel(address: 'VCB', allowOtp: true),
        const WhitelistEntryModel(address: 'VCB', allowOtp: true),
      );
    });
  });

  group('WhitelistMode', () {
    test('fromName parses native names', () {
      expect(WhitelistMode.fromName('EXPLICIT'), WhitelistMode.explicit);
      expect(
        WhitelistMode.fromName('ALL_ADDRESSES'),
        WhitelistMode.allAddresses,
      );
    });

    test('fromName falls back to explicit on unknown value', () {
      expect(WhitelistMode.fromName('OTP_ONLY'), WhitelistMode.explicit);
      expect(WhitelistMode.fromName(null), WhitelistMode.explicit);
    });
  });

  group('WhitelistConfigModel', () {
    test('toMap serializes mode and entries for MethodChannel', () {
      const config = WhitelistConfigModel(
        mode: WhitelistMode.allAddresses,
        entries: [
          WhitelistEntryModel(address: 'VCB', allowOtp: true),
          WhitelistEntryModel(address: '+8498'),
        ],
      );
      expect(config.toMap(), {
        'mode': 'ALL_ADDRESSES',
        'entries': [
          {'address': 'VCB', 'allowOtp': true},
          {'address': '+8498', 'allowOtp': false},
        ],
      });
    });

    test('fromMap round-trips with toMap', () {
      const config = WhitelistConfigModel(
        mode: WhitelistMode.explicit,
        entries: [WhitelistEntryModel(address: 'MOMO', allowOtp: true)],
      );
      expect(WhitelistConfigModel.fromMap(config.toMap()), config);
    });

    test('fromMap drops malformed entries and defaults mode', () {
      final config = WhitelistConfigModel.fromMap({
        'entries': [
          {'address': 'VCB', 'allowOtp': true},
          'garbage',
          {'allowOtp': true},
        ],
      });
      expect(config.mode, WhitelistMode.explicit);
      expect(config.entries.length, 1);
      expect(config.entries.first.address, 'VCB');
    });

    test('empty config is explicit mode with no entries', () {
      const config = WhitelistConfigModel();
      expect(config.mode, WhitelistMode.explicit);
      expect(config.entries, isEmpty);
      expect(config.isEmptyList, isTrue);
    });
  });
}
