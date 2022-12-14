import 'dart:async';
import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:yak_runner/yak_runner.dart';

import 'command.dart';
import 'run.dart';
import 'typedef.dart';

@immutable
abstract class Agent<T> {
  const Agent();

  FutureVoidResultOf<T> dispose();
  FutureResult<T> run(TransactionRun<T> function);
  FutureResult<T> read<S>(TransactionRead<S, T> function);

  static Future<Agent<T>> init<T>(Nullary<T> value) async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(runIsolate<T>, receivePort.sendPort);
    final sendPort = await receivePort.first;
    sendPort.send(Command.init(value, sendPort));
    receivePort.close();
    return AgentImpl<T>(isolate, sendPort);
  }

  @internal
  @protected
  SendPort get sendPort;

  @internal
  @protected
  Isolate get isolate;
}

class AgentImpl<T> implements Agent<T> {
  const AgentImpl(this.isolate, this.sendPort);

  @override
  @nonVirtual
  final SendPort sendPort;

  @override
  final Isolate isolate;

  @override
  FutureResult<S> read<S>(TransactionRead<S, T> transaction) {
    final receivePort = ReceivePort();
    sendPort.send(Command.read<T, S>(transaction, receivePort.sendPort));
    return receivePort.first;
  }

  @override
  FutureResult<T> run(TransactionRun<T> transaction) {
    final receivePort = ReceivePort();
    sendPort.send(Command.run(transaction, receivePort.sendPort));
    return receivePort.first;
  }

  @override
  FutureVoidResultOf<T> dispose() {
    final receivePort = ReceivePort();
    sendPort.send(Command.dispose(receivePort.sendPort));
    return receivePort.first;
  }
}

// class Agent<T> {
//   Isolate? _isolate;
//   final SendPort _sendPort;

//   Agent._(this._isolate, this._sendPort);

//   /// Creates the [Agent] whose initial state is the result of executing [func].
//   static Future<Agent<T>> create<T>(T Function() func) async {
//     ReceivePort receivePort = ReceivePort();
//     Isolate isolate =
//         await Isolate.spawn(_isolateMain<T>, receivePort.sendPort);
//     SendPort sendPort = await receivePort.first;
//     sendPort.send(_Command(_Commands.init, arg0: func));
//     receivePort.close();
//     return Agent<T>._(isolate, sendPort);
//   }

//   /// Send a closure [func] that will be executed in the [Agent]'s [Isolate].
//   /// The result of [func] is assigned to the value of the [Agent].
//   Future<void> update(T Function(T) func) async {
//     if (_isolate == null) {
//       throw StateError('Agent has been killed.');
//     }
//     ReceivePort receivePort = ReceivePort();
//     _sendPort.send(
//         _Command(_Commands.exec, sendPort: receivePort.sendPort, arg0: func));
//     return receivePort.first;
//   }

//   /// Reads the [Agent]'s state with a closure.
//   ///
//   /// [read] is useful for reading a portion of the state held by the agent to
//   /// avoid the overhead of reading the whole state.
//   Future<U> read<U>({U Function(T state)? query}) async {
//     if (_isolate == null) {
//       throw StateError('Agent has been killed.');
//     }
//     ReceivePort receivePort = ReceivePort();
//     _sendPort.send(_Command(_Commands.query,
//         sendPort: receivePort.sendPort, arg0: query ?? (x) => x));
//     final _Result<dynamic> result = await receivePort.first;
//     if (result.error != null) {
//       throw result.error!;
//     } else {
//       return result.value as U;
//     }
//   }

//   /// Kills the agent and returns its state value. This is faster than calling
//   /// [deref] then [kill] since Dart will elide the copy of the result.
//   Future<T> exit() async {
//     // TODO(gaaclarke): Add an exit listener to the isolate so the state of all
//     // Agents can be cleared out.
//     if (_isolate == null) {
//       throw StateError('Agent has been killed.');
//     }
//     _isolate = null;
//     ReceivePort receivePort = ReceivePort();
//     _sendPort.send(_Command(_Commands.exit, sendPort: receivePort.sendPort));
//     dynamic value = await receivePort.first;
//     return value as T;
//   }

//   /// Gets the current error associated with the Agent, null if there is none.
//   ///
//   /// See also:
//   ///   * [resetError]
//   Future<AgentError?> get error async {
//     if (_isolate == null) {
//       throw StateError('Agent has been killed.');
//     }
//     ReceivePort receivePort = ReceivePort();
//     _sendPort
//         .send(_Command(_Commands.getError, sendPort: receivePort.sendPort));
//     dynamic value = await receivePort.first;
//     return value as AgentError?;
//   }

//   /// Resets the [Agent] so it can start receiving messages again.
//   Future<void> resetError() async {
//     if (_isolate == null) {
//       throw StateError('Agent has been killed.');
//     }
//     ReceivePort receivePort = ReceivePort();
//     _sendPort
//         .send(_Command(_Commands.resetError, sendPort: receivePort.sendPort));
//     await receivePort.first;
//   }

//   /// Kills the [Agent]'s isolate. Any interaction with the Agent after this will
//   /// result in a [StateError].
//   void kill() {
//     _isolate = null;
//   }
// }
