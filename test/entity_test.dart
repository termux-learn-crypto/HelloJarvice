import 'package:flutter_test/flutter_test.dart';
import 'package:hello_jarvice/core/entity.dart';

void main() {
  group('EntityExtractor', () {
    group('Cities', () {
      test('extracts Delhi from text', () {
        final entities = EntityExtractor.extract('weather in Delhi');
        expect(entities.any((e) => e.type == EntityType.city && e.value == 'Delhi'), isTrue);
      });

      test('extracts Mumbai from text', () {
        final entities = EntityExtractor.extract('Mumbai mein weather');
        expect(entities.any((e) => e.type == EntityType.city && e.value == 'Mumbai'), isTrue);
      });

      test('does not extract non-existent city', () {
        final entities = EntityExtractor.extract('hello world');
        expect(entities.where((e) => e.type == EntityType.city), isEmpty);
      });
    });

    group('Percentages', () {
      test('extracts percentage with %', () {
        final entities = EntityExtractor.extract('volume 50%');
        expect(entities.any((e) => e.type == EntityType.percentage && e.value == 50), isTrue);
      });

      test('extracts percentage with percent word', () {
        final entities = EntityExtractor.extract('set brightness 75 percent');
        expect(entities.any((e) => e.type == EntityType.percentage && e.value == 75), isTrue);
      });

      test('extracts Hindi percentage', () {
        final entities = EntityExtractor.extract('awaaz 30 prasent');
        expect(entities.any((e) => e.type == EntityType.percentage && e.value == 30), isTrue);
      });
    });

    group('Durations', () {
      test('extracts minutes', () {
        final entities = EntityExtractor.extract('timer for 5 minutes');
        expect(entities.any((e) => e.type == EntityType.duration && e.value == 300), isTrue);
      });

      test('extracts hours', () {
        final entities = EntityExtractor.extract('2 ghante ka timer');
        expect(entities.any((e) => e.type == EntityType.duration && e.value == 7200), isTrue);
      });

      test('extracts seconds', () {
        final entities = EntityExtractor.extract('30 second timer');
        expect(entities.any((e) => e.type == EntityType.duration && e.value == 30), isTrue);
      });
    });

    group('Times', () {
      test('extracts time with colon', () {
        final entities = EntityExtractor.extract('alarm at 7:30');
        expect(entities.any((e) => e.type == EntityType.time), isTrue);
      });

      test('extracts time with AM/PM', () {
        final entities = EntityExtractor.extract('set alarm 3pm');
        expect(entities.any((e) => e.type == EntityType.time), isTrue);
      });

      test('extracts Hindi time', () {
        final entities = EntityExtractor.extract('8 baje ka alarm');
        expect(entities.any((e) => e.type == EntityType.time), isTrue);
      });
    });

    group('Phone Numbers', () {
      test('extracts 10-digit phone number', () {
        final entities = EntityExtractor.extract('call 9876543210');
        expect(entities.any((e) => e.type == EntityType.phoneNumber && e.value == '9876543210'), isTrue);
      });

      test('does not extract 9-digit number as phone', () {
        final entities = EntityExtractor.extract('call 123456789');
        expect(entities.where((e) => e.type == EntityType.phoneNumber), isEmpty);
      });
    });

    group('Stream Types', () {
      test('extracts music stream', () {
        final entities = EntityExtractor.extract('volume for music');
        expect(entities.any((e) => e.type == EntityType.streamType && e.value == 'music'), isTrue);
      });

      test('extracts ring stream', () {
        final entities = EntityExtractor.extract('ring volume');
        expect(entities.any((e) => e.type == EntityType.streamType && e.value == 'ring'), isTrue);
      });
    });

    group('URLs', () {
      test('extracts URL', () {
        final entities = EntityExtractor.extract('open https://google.com');
        expect(entities.any((e) => e.type == EntityType.url), isTrue);
      });
    });

    group('extractAppName', () {
      test('extracts app name from open command', () {
        final name = EntityExtractor.extractAppName('kholo youtube');
        expect(name, 'youtube');
      });

      test('extracts app name from launch command', () {
        final name = EntityExtractor.extractAppName('launch chrome');
        expect(name, 'chrome');
      });

      test('returns empty for no app', () {
        final name = EntityExtractor.extractAppName('hello');
        expect(name, '');
      });
    });

    group('extractContactName', () {
      test('extracts contact from call command', () {
        final name = EntityExtractor.extractContactName('call Rahul');
        expect(name, 'Rahul');
      });

      test('extracts contact from message command', () {
        final name = EntityExtractor.extractContactName('message Priya ko');
        expect(name, 'Priya');
      });
    });

    group('extractMessage', () {
      test('extracts message from send command', () {
        final msg = EntityExtractor.extractMessage('bhejo ki hello kaise ho');
        expect(msg, isNotEmpty);
      });
    });

    group('extractRelativeTime', () {
      test('extracts kal', () {
        expect(EntityExtractor.extractRelativeTime('kal subah'), 'kal');
      });

      test('extracts abhi', () {
        expect(EntityExtractor.extractRelativeTime('abhi karo'), 'abhi');
      });

      test('extracts empty for no match', () {
        expect(EntityExtractor.extractRelativeTime('hello'), '');
      });
    });
  });
}
