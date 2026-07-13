import 'package:flutter_test/flutter_test.dart';
import 'package:hello_jarvice/core/semantic_interpreter.dart';
import 'package:hello_jarvice/core/capability.dart';

void main() {
  group('SemanticInterpreter', () {
    group('normalizeHinglish', () {
      test('normalizes chalo to open', () {
        final result = SemanticInterpreter.instance.normalizeHinglish('chalao youtube');
        expect(result, contains('open'));
      });

      test('normalizes band karo to close', () {
        final result = SemanticInterpreter.instance.normalizeHinglish('band karo app');
        expect(result, contains('close'));
      });

      test('removes filler words', () {
        final result = SemanticInterpreter.instance.normalizeHinglish('please yaar kholo');
        expect(result, isNot(contains('please')));
        expect(result, isNot(contains('yaar')));
      });

      test('lowercases text', () {
        final result = SemanticInterpreter.instance.normalizeHinglish('OPEN APP');
        expect(result, isNot(contains('OPEN')));
      });
    });

    group('interpret', () {
      test('interprets volume up', () {
        final goals = SemanticInterpreter.instance.interpret('volume badhao');
        expect(goals, isNotEmpty);
        expect(goals.first.operation, Operation.increase);
        expect(goals.first.targetCategory, CapabilityCategory.volume);
      });

      test('interprets mute', () {
        final goals = SemanticInterpreter.instance.interpret('mute karo');
        expect(goals, isNotEmpty);
        expect(goals.first.operation, Operation.mute);
      });

      test('interprets go back', () {
        final goals = SemanticInterpreter.instance.interpret('go back');
        expect(goals, isNotEmpty);
        expect(goals.first.operation, Operation.press);
        expect(goals.first.targetCategory, CapabilityCategory.accessibility);
      });

      test('interprets go home', () {
        final goals = SemanticInterpreter.instance.interpret('home');
        expect(goals, isNotEmpty);
        expect(goals.first.operation, Operation.press);
        expect(goals.first.targetName, 'GO_HOME');
      });

      test('interprets play music', () {
        final goals = SemanticInterpreter.instance.interpret('play music');
        expect(goals, isNotEmpty);
        expect(goals.first.operation, Operation.start);
        expect(goals.first.targetCategory, CapabilityCategory.media);
      });

      test('interprets next song', () {
        final goals = SemanticInterpreter.instance.interpret('next song');
        expect(goals, isNotEmpty);
        expect(goals.first.targetName, 'MEDIA_NEXT');
      });

      test('interprets torch on', () {
        final goals = SemanticInterpreter.instance.interpret('torch on');
        expect(goals, isNotEmpty);
        expect(goals.first.targetCategory, CapabilityCategory.torch);
      });

      test('interprets battery level', () {
        final goals = SemanticInterpreter.instance.interpret('battery kitni hai');
        expect(goals, isNotEmpty);
        expect(goals.first.targetName, 'GET_BATTERY_LEVEL');
      });

      test('interprets time query', () {
        final goals = SemanticInterpreter.instance.interpret('time kya hai');
        expect(goals, isNotEmpty);
        expect(goals.first.targetName, 'GET_CURRENT_TIME');
      });

      test('interprets alarm with time', () {
        final goals = SemanticInterpreter.instance.interpret('alarm at 7am');
        expect(goals, isNotEmpty);
        expect(goals.first.targetCategory, CapabilityCategory.alarm);
      });

      test('interprets wifi on', () {
        final goals = SemanticInterpreter.instance.interpret('wifi on');
        expect(goals, isNotEmpty);
        expect(goals.first.targetCategory, CapabilityCategory.wifi);
      });

      test('interprets bluetooth off', () {
        final goals = SemanticInterpreter.instance.interpret('bluetooth off');
        expect(goals, isNotEmpty);
        expect(goals.first.targetCategory, CapabilityCategory.bluetooth);
      });

      test('interprets open app', () {
        final goals = SemanticInterpreter.instance.interpret('kholo youtube');
        expect(goals, isNotEmpty);
        expect(goals.first.targetCategory, CapabilityCategory.application);
      });

      test('interprets web search', () {
        final goals = SemanticInterpreter.instance.interpret('google for flutter tutorial');
        expect(goals, isNotEmpty);
        expect(goals.first.targetCategory, CapabilityCategory.web);
      });

      test('interprets scroll down', () {
        final goals = SemanticInterpreter.instance.interpret('scroll down');
        expect(goals, isNotEmpty);
        expect(goals.first.targetName, 'SCROLL_DOWN');
      });

      test('returns empty for gibberish', () {
        final goals = SemanticInterpreter.instance.interpret('xyzabc123');
        expect(goals, isEmpty);
      });
    });
  });
}
