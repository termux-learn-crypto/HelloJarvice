import 'capability.dart';
import 'capability_registry.dart';
import 'semantic_interpreter.dart';
import 'conversation_context.dart';
import '../models/action_plan.dart';

class ActionPlanner {
  static final ActionPlanner instance = ActionPlanner._();
  ActionPlanner._();

  ActionPlan createPlan(List<Goal> goals, String originalInput) {
    final steps = <PlanStep>[];

    for (final goal in goals) {
      final resolvedGoal = _resolveFromContext(goal, originalInput);
      final capability = _findBestCapability(resolvedGoal);
      if (capability == null) continue;

      final parameters = _buildParameters(resolvedGoal, capability);
      final missingRequired = _checkRequiredParams(parameters, capability);

      if (missingRequired.isNotEmpty) {
        steps.add(PlanStep(
          capabilityId: capability.id,
          category: capability.category,
          operation: capability.operation,
          parameters: {...parameters, '_missingRequired': missingRequired},
          status: PlanStepStatus.pending,
        ));
      } else {
        steps.add(PlanStep(
          capabilityId: capability.id,
          category: capability.category,
          operation: capability.operation,
          parameters: parameters,
          status: PlanStepStatus.pending,
        ));
      }
    }

    _resolveDependencies(steps);

    return ActionPlan(steps: steps, originalInput: originalInput);
  }

  Goal _resolveFromContext(Goal goal, String originalInput) {
    final context = ConversationContext.instance;
    if (context.isStale) return goal;

    final resolved = Map<String, dynamic>.from(goal.entities);

    if (resolved['contactName'] == null && context.lastContactName != null) {
      if (originalInput.toLowerCase().contains(RegExp(r'(usko|usse|uska|uski|that one|woh|same|dobara|phir se)'))) {
        resolved['contactName'] = context.lastContactName;
      }
    }

    if (resolved['appName'] == null && context.lastAppName != null) {
      if (originalInput.toLowerCase().contains(RegExp(r'(usme|usko open|that app|woh app)'))) {
        resolved['appName'] = context.lastAppName;
        resolved['packageName'] = context.lastPackageName;
      }
    }

    if (resolved['phoneNumber'] == null && context.lastPhoneNumber != null) {
      if (originalInput.toLowerCase().contains(RegExp(r'(usko|usse|that number|woh number)'))) {
        resolved['phoneNumber'] = context.lastPhoneNumber;
      }
    }

    if (resolved['message'] == null && context.lastMessage != null) {
      if (originalInput.toLowerCase().contains(RegExp(r'(wahi message|same message|phir se|dobara)'))) {
        resolved['message'] = context.lastMessage;
      }
    }

    return Goal(
      operation: goal.operation,
      targetCategory: goal.targetCategory,
      targetName: goal.targetName,
      entities: resolved,
      confidence: goal.confidence,
    );
  }

  Capability? _findBestCapability(Goal goal) {
    final registry = CapabilityRegistry.instance;

    if (goal.targetName != null) {
      final direct = registry.getCapability(goal.targetName!);
      if (direct != null) return direct;
    }

    if (goal.targetCategory != null) {
      final candidates = registry.getByCategory(goal.targetCategory!);
      final matching = candidates.where((c) => c.operation == goal.operation).toList();
      if (matching.isNotEmpty) {
        return matching.first;
      }
      if (candidates.isNotEmpty) {
        return candidates.first;
      }
    }

    return null;
  }

  Map<String, dynamic> _buildParameters(Goal goal, Capability capability) {
    final params = <String, dynamic>{};

    for (final key in goal.entities.keys) {
      params[key] = goal.entities[key];
    }

    final context = ConversationContext.instance;

    if (capability.requiredParameters.contains('contactName') && !params.containsKey('contactName')) {
      if (context.lastContactName != null) {
        params['contactName'] = context.lastContactName;
      }
    }

    if (capability.requiredParameters.contains('appName') && !params.containsKey('appName')) {
      if (context.lastAppName != null) {
        params['appName'] = context.lastAppName;
        if (context.lastPackageName != null) {
          params['packageName'] = context.lastPackageName;
        }
      }
    }

    if (capability.requiredParameters.contains('phoneNumber') && !params.containsKey('phoneNumber')) {
      if (context.lastPhoneNumber != null) {
        params['phoneNumber'] = context.lastPhoneNumber;
      }
    }

    if (capability.requiredParameters.contains('message') && !params.containsKey('message')) {
      if (context.lastMessage != null) {
        params['message'] = context.lastMessage;
      }
    }

    return params;
  }

  List<String> _checkRequiredParams(Map<String, dynamic> params, Capability capability) {
    final missing = <String>[];
    for (final required in capability.requiredParameters) {
      if (!params.containsKey(required) || params[required] == null) {
        missing.add(required);
      }
    }
    return missing;
  }

  void _resolveDependencies(List<PlanStep> steps) {
    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      if (step.category == CapabilityCategory.call && step.parameters.containsKey('contactName')) {
        if (!step.parameters.containsKey('phoneNumber')) {
          steps.insert(i, PlanStep(
            capabilityId: 'RESOLVE_CONTACT',
            category: CapabilityCategory.contact,
            operation: Operation.resolve,
            parameters: {'contactName': step.parameters['contactName']},
            status: PlanStepStatus.pending,
            dependsOnStepIndex: null,
          ));
          steps[i + 1] = step.copyWith(
            parameters: {...step.parameters, '_dependsOnContactLookup': true},
          );
          i++;
        }
      }

      if ((step.category == CapabilityCategory.whatsapp || step.category == CapabilityCategory.message) &&
          step.parameters.containsKey('contactName') &&
          !step.parameters.containsKey('phoneNumber')) {
        if (!steps.any((s) => s.capabilityId == 'RESOLVE_CONTACT' &&
            s.parameters['contactName'] == step.parameters['contactName'])) {
          steps.insert(i, PlanStep(
            capabilityId: 'RESOLVE_CONTACT',
            category: CapabilityCategory.contact,
            operation: Operation.resolve,
            parameters: {'contactName': step.parameters['contactName']},
            status: PlanStepStatus.pending,
            dependsOnStepIndex: null,
          ));
          i++;
        }
      }
    }
  }
}
