import 'dart:async';
import 'dart:isolate';

import 'package:yak_runner/yak_runner.dart';

typedef TransactionRun<T> = Unary<FutureOr<T>, T>;
typedef TransactionRead<T, S> = Unary<FutureOr<T>, S>;

/// TO ADD in Yak_result
typedef FutureVoidResultOf<T> = FutureOr<VoidResult<T>>;
