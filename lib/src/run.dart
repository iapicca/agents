import 'dart:isolate';

import 'package:yak_runner/yak_runner.dart';

import 'command.dart';

void runIsolate<T>(SendPort sendPort) async {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);
  late FutureValueResult<T> state;
  await for (Command<T> command in receivePort) {
    switch (command.code) {
      case CommandCode.init:
        () {
          state = Future.sync((command as CommandInit<T>).value.run);
        }();
        break;
      case CommandCode.run:
        () async {
          /// TODO need to add "run" FutureOr<T> Functions ^ "runAsyncs"
          state = (command as CommandRun<T>).transaction(state);
          command.port.send(state);
        }();
        break;
      case CommandCode.read:
        () async {
          final result = await (command as CommandRead).transaction(state);
          command.port.send(result);
        }();
        break;
      case CommandCode.dispose:
        () {
          Isolate.exit(command.port, state);
        }();
    }
  }
}
