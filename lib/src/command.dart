import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:yak_runner/yak_runner.dart';

import 'typedef.dart';

enum CommandCode {
  init,
  run,
  dispose,
  read,
}

mixin SendPortMixin {
  SendPort get port;
}

abstract class Command<T> implements SendPortMixin {
  final CommandCode code;
  const Command(this.port, {required this.code});

  const factory Command.init(Nullary<T> value, SendPort port) = CommandInit;
  const factory Command.dispose(SendPort port) = CommandDispose;
  const factory Command.run(
    TransactionRun<T> transaction,
    SendPort port,
  ) = CommandRun;

  static Command<T> read<T, S>(
          TransactionRead<S, T> transaction, SendPort port) =>
      CommandRead(transaction, port);

  @override
  @nonVirtual
  final SendPort port;

  @override
  @nonVirtual
  operator ==(other) => other is Command<T> && other.code == code;

  @override
  @nonVirtual
  int get hashCode => code.hashCode;
}

class CommandInit<T> extends Command<T> {
  final Nullary<T> value;
  const CommandInit(this.value, super.port) : super(code: CommandCode.run);
}

class CommandRun<T> extends Command<T> {
  final TransactionRun<T> transaction;
  const CommandRun(this.transaction, super.port) : super(code: CommandCode.run);
}

class CommandDispose<T> extends Command<T> {
  const CommandDispose(super.port) : super(code: CommandCode.dispose);
}

class CommandRead<T, S> extends Command<S> {
  final TransactionRead<T, S> transaction;

  const CommandRead(this.transaction, super.port)
      : super(code: CommandCode.read);
}
