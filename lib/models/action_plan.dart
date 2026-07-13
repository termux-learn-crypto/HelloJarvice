import 'package:hello_jarvice/core/capability.dart';

enum PlanStepStatus {
  pending,
  inProgress,
  completed,
  failed,
  skipped,
}

class PlanStep {
  final String capabilityId;
  final CapabilityCategory category;
  final Operation operation;
  final Map<String, dynamic> parameters;
  final PlanStepStatus status;
  final String? failedReason;
  final int? dependsOnStepIndex;
  final bool isParallel;

  const PlanStep({
    required this.capabilityId,
    required this.category,
    required this.operation,
    this.parameters = const {},
    this.status = PlanStepStatus.pending,
    this.failedReason,
    this.dependsOnStepIndex,
    this.isParallel = false,
  });

  PlanStep copyWith({
    PlanStepStatus? status,
    String? failedReason,
    Map<String, dynamic>? parameters,
  }) {
    return PlanStep(
      capabilityId: capabilityId,
      category: category,
      operation: operation,
      parameters: parameters ?? this.parameters,
      status: status ?? this.status,
      failedReason: failedReason ?? this.failedReason,
      dependsOnStepIndex: dependsOnStepIndex,
      isParallel: isParallel,
    );
  }

  bool get isPending => status == PlanStepStatus.pending;
  bool get isCompleted => status == PlanStepStatus.completed;
  bool get isFailed => status == PlanStepStatus.failed;
  bool get isSkipped => status == PlanStepStatus.skipped;

  Map<String, dynamic> toMap() => {
    'capabilityId': capabilityId,
    'category': category.name,
    'operation': operation.name,
    'parameters': parameters,
    'status': status.name,
  };
}

class ActionPlan {
  final List<PlanStep> steps;
  final String originalInput;
  final DateTime createdAt;

  ActionPlan({
    required this.steps,
    required this.originalInput,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isEmpty => steps.isEmpty;
  bool get isNotEmpty => steps.isNotEmpty;
  int get length => steps.length;

  PlanStep? get firstStep => steps.isNotEmpty ? steps.first : null;

  bool get allCompleted => steps.every((s) => s.isCompleted || s.isSkipped);
  bool get anyFailed => steps.any((s) => s.isFailed);

  List<PlanStep> get pendingSteps => steps.where((s) => s.isPending).toList();
  List<PlanStep> get completedSteps => steps.where((s) => s.isCompleted).toList();
  List<PlanStep> get failedSteps => steps.where((s) => s.isFailed).toList();

  PlanStep stepAt(int index) => steps[index];

  ActionPlan updateStep(int index, PlanStep updatedStep) {
    final newSteps = List<PlanStep>.from(steps);
    if (index < newSteps.length) {
      newSteps[index] = updatedStep;
    }
    return ActionPlan(steps: newSteps, originalInput: originalInput, createdAt: createdAt);
  }

  Map<String, dynamic> toMap() => {
    'originalInput': originalInput,
    'steps': steps.map((s) => s.toMap()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };
}
