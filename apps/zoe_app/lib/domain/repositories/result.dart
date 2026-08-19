/// Interfaces de repositórios do domínio.
///
/// Referência: ARCHITECTURE.md §domain/repositories/
import '../../core/error/failures.dart';

/// Resultado genérico: Left = Failure, Right = Success
/// Usando Either simplificado (sem dartz, para manter leve)
class Result<T> {
  final T? data;
  final Failure? failure;

  const Result.success(this.data) : failure = null;
  const Result.error(this.failure) : data = null;

  /// Alias para Result.error (conveniência)
  const Result.failure(this.failure) : data = null;

  bool get isSuccess => failure == null;
  bool get isError => failure != null;

  R fold<R>({
    required R Function(T) onSuccess,
    required R Function(Failure) onFailure,
  }) {
    if (failure != null) return onFailure(failure!);
    return onSuccess(data as T);
  }
}
