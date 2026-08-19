/// Exceções e failures do domínio.
///
/// Referência: ARCHITECTURE.md §core/error/
abstract class Failure {
  final String message;
  const Failure({required this.message});
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error']) : super(message: message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache error']) : super(message: message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'No internet connection']) : super(message: message);
}

class StockUnavailableFailure extends Failure {
  final int available;
  const StockUnavailableFailure({this.available = 0, String? message})
      : super(message: message ?? 'Stock unavailable');
}

class ReservationExpiredFailure extends Failure {
  const ReservationExpiredFailure() : super(message: 'Reservation expired');
}

class PriceChangedFailure extends Failure {
  final double oldPrice;
  final double newPrice;
  const PriceChangedFailure({this.oldPrice = 0, this.newPrice = 0})
      : super(message: 'Price changed');
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([String message = 'Unexpected error']) : super(message: message);
}

// Exceptions (data layer)
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException({this.message = 'Server error', this.statusCode});
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache error']);
}
