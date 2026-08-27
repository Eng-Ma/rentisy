enum MessageSender { user, assistant, system }

class AiToolAction {
  final String toolName;
  final Map<String, dynamic> arguments;
  final dynamic result;
  final bool isSuccess;

  AiToolAction({
    required this.toolName,
    required this.arguments,
    this.result,
    this.isSuccess = true,
  });

  Map<String, dynamic> toJson() => {
    'toolName': toolName,
    'arguments': arguments,
    'result': result,
    'isSuccess': isSuccess,
  };
}

class AiMessage {
  final String id;
  final MessageSender sender;
  final String text;
  final DateTime timestamp;
  final List<AiToolAction>? executedActions;
  final bool isLoading;

  AiMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.executedActions,
    this.isLoading = false,
  });

  AiMessage copyWith({
    String? text,
    List<AiToolAction>? executedActions,
    bool? isLoading,
  }) {
    return AiMessage(
      id: id,
      sender: sender,
      text: text ?? this.text,
      timestamp: timestamp,
      executedActions: executedActions ?? this.executedActions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
