import 'package:dartz/dartz.dart';

import '../errors/failure.dart';

/// Base class for all use cases
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// No params class for use cases that don't require parameters
class NoParams {
  const NoParams();
}
