import 'package:flutter_test/flutter_test.dart';
import 'package:hello_jarvice/core/response_generator.dart';
import 'package:hello_jarvice/core/capability_result.dart';

void main() {
  group('ResponseGenerator', () {
    test('generates success response for OPEN_APPLICATION', () {
      final result = CapabilityResult(
        status: CapabilityStatus.success,
        message: 'App opened',
        data: {'value': 'YouTube'},
      );
      final response = ResponseGenerator.instance.generateResponse(result, capabilityId: 'OPEN_APPLICATION');
      expect(response, isNotEmpty);
      expect(response.toLowerCase(), contains('youtube'));
    });

    test('generates success response for SET_ALARM', () {
      final result = CapabilityResult(
        status: CapabilityStatus.success,
        message: 'Alarm set',
        data: {'hour': 7, 'minute': 30},
      );
      final response = ResponseGenerator.instance.generateResponse(result, capabilityId: 'SET_ALARM');
      expect(response, isNotEmpty);
    });

    test('generates error response for FAILED', () {
      final result = CapabilityResult(
        status: CapabilityStatus.failed,
        message: 'Something went wrong',
      );
      final response = ResponseGenerator.instance.generateResponse(result, capabilityId: 'RANDOM');
      expect(response, isNotEmpty);
    });

    test('generates clarification for contactName', () {
      final validResponses = ['Kiska naam batao?', 'Kaun hai ye?', 'Naam toh batao.'];
      final response = ResponseGenerator.instance.generateClarification('contactName');
      expect(response, isNotEmpty);
      expect(validResponses.contains(response), isTrue);
    });

    test('generates clarification for query', () {
      final response = ResponseGenerator.instance.generateClarification('query');
      expect(response, isNotEmpty);
    });

    test('generates multi-step acknowledgment for single step', () {
      final response = ResponseGenerator.instance.generateMultiStepAcknowledgment(['Open YouTube']);
      expect(response, contains('Samajh gaya'));
      expect(response, contains('Open YouTube'));
    });

    test('generates multi-step acknowledgment for multiple steps', () {
      final response = ResponseGenerator.instance.generateMultiStepAcknowledgment(['Step 1', 'Step 2', 'Step 3']);
      expect(response, contains('3 kaam'));
    });
  });
}
