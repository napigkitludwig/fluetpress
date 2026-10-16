import 'package:flutter/foundation.dart';

/// Base class every controller extends.
///
/// A controller owns **state** and **business logic** for one part of the app.
/// It is a plain [ChangeNotifier]: views listen to it and rebuild, but the
/// controller itself must never build widgets or import `material.dart`.
///
/// It provides the three concerns every controller shares:
///  * a loading flag ([isLoading]),
///  * an error message ([errorMessage]) safe to render,
///  * guarded execution helpers ([runGuarded] / [runGuardedResult]) that turn
///    exceptions and failures into user-facing errors instead of crashes.
abstract class BaseController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  /// `true` while an asynchronous operation is in flight.
  bool get isLoading => _isLoading;

  /// Last user-facing error, or `null`.
  String? get errorMessage => _errorMessage;

  /// Whether [errorMessage] is set.
  bool get hasError => _errorMessage != null;

  /// Whether [dispose] has been called.
  bool get isDisposed => _isDisposed;

  /// Updates [isLoading] and notifies listeners when the value changes.
  @protected
  void setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }
    _isLoading = value;
    notify();
  }

  /// Updates the user-facing error and notifies listeners.
  @protected
  void setError(String? message) {
    if (_errorMessage == message) {
      return;
    }
    _errorMessage = message;
    notify();
  }

  /// Clears any pending error.
  ///
  /// Part of the public API: views may call it (for example when the user edits
  /// the form that produced the error).
  void clearError() => setError(null);

  /// Notifies listeners, unless this controller has been disposed.
  @protected
  void notify() {
    if (_isDisposed) {
      return;
    }
    notifyListeners();
  }

  /// Runs [action], managing [isLoading] and converting unexpected exceptions
  /// into a safe [errorMessage]. Returns `null` when the action threw.
  @protected
  Future<T?> runGuarded<T>(
    Future<T> Function() action, {
    String errorMessage = 'Something went wrong. Please try again.',
  }) async {
    setLoading(true);
    clearError();
    try {
      return await action();
    } catch (error, stackTrace) {
      debugPrint('[$runtimeType] $error\n$stackTrace');
      setError(errorMessage);
      return null;
    } finally {
      setLoading(false);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
