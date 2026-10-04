/// Base type for recoverable application failures.
///
/// No concrete subtypes are defined yet; this sealed class exists as a
/// placeholder for the error-handling strategy to be elaborated in a
/// future implementation package.
sealed class Failure {
  const Failure(this.message);

  final String message;
}
