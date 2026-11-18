import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_app/domain/entities/user.dart';

class AuthState {
  const AuthState({
    required this.isAuthenticated,
    this.email,
    this.name,
    this.role,
    this.status,
    this.hotelId,
    this.isLoading = false,
  });

  final bool isAuthenticated;
  final String? email;
  final String? name;
  final UserRole? role;
  final UserStatus? status;
  final String? hotelId;
  final bool isLoading;

  AuthState copyWith({
    bool? isAuthenticated,
    String? email,
    String? name,
    UserRole? role,
    UserStatus? status,
    String? hotelId,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      status: status ?? this.status,
      hotelId: hotelId ?? this.hotelId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  StreamSubscription<dynamic>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSubscription;

  @override
  AuthState build() {
    _initialize();
    return const AuthState(isAuthenticated: false, isLoading: true);
  }

  Future<void> _initialize() async {
    try {
      _authSubscription?.cancel();
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((firebaseUser) async {
        if (firebaseUser == null) {
          _userDocSubscription?.cancel();
          _userDocSubscription = null;
          state = const AuthState(isAuthenticated: false, isLoading: false);
        } else {
          await _fetchAndListenUserDocument(firebaseUser.uid, firebaseUser.email ?? '');
        }
      });

      ref.onDispose(() {
        _authSubscription?.cancel();
        _userDocSubscription?.cancel();
      });
    } catch (_) {
      // Tolera entornos de pruebas unitarias sin Firebase inicializado
      state = const AuthState(isAuthenticated: false, isLoading: false);
    }
  }

  /// Resuelve el `hotelId` efectivo priorizando el Custom Claim del token JWT
  /// (`request.auth.token.hotelId`) sobre el campo del documento `/users/{uid}`.
  ///
  /// Si ambos existen y no coinciden, lanza un [StateError] para bloquear el
  /// acceso cross-tenant.
  static String resolveTenantHotelId({
    String? tokenClaimHotelId,
    String? documentHotelId,
  }) {
    final claim = tokenClaimHotelId?.trim();
    final doc = documentHotelId?.trim();

    final hasClaim = claim != null && claim.isNotEmpty;
    final hasDoc = doc != null && doc.isNotEmpty;

    if (hasClaim && hasDoc && claim != doc) {
      throw StateError(
        'Acceso denegado: discrepancia cross-tenant entre el claim del token ($claim) y el documento ($doc).',
      );
    }

    if (hasClaim) return claim;
    if (hasDoc) return doc;
    return 'hotel_101';
  }

  /// Extrae de forma segura el Custom Claim `hotelId` del usuario autenticado.
  Future<String?> _readTokenClaimHotelId() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return null;
      final tokenResult = await currentUser.getIdTokenResult();
      final rawClaim = tokenResult.claims?['hotelId'];
      if (rawClaim is String && rawClaim.trim().isNotEmpty) {
        return rawClaim.trim();
      }
    } catch (_) {
      // Tolera entornos de prueba sin Firebase Auth inicializado
    }
    return null;
  }

  /// Escucha en tiempo real los cambios del documento /users/{uid} en Firestore.
  /// Esto permite reaccionar inmediatamente a aprobaciones de cuenta y cambios de rol.
  Future<void> _fetchAndListenUserDocument(String uid, String email) async {
    _userDocSubscription?.cancel();

    final claimHotelId = await _readTokenClaimHotelId();

    // 1. Lectura inmediata para no retrasar el inicio de sesión
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      _updateStateFromSnapshot(doc, email, claimHotelId: claimHotelId);
    } catch (_) {
      state = const AuthState(isAuthenticated: false, isLoading: false);
    }

    // 2. Suscripción a cambios en tiempo real
    _userDocSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
      (doc) {
        _updateStateFromSnapshot(doc, email, claimHotelId: claimHotelId);
      },
      onError: (_) {
        state = const AuthState(isAuthenticated: false, isLoading: false);
      },
    );
  }

  void _updateStateFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String email, {
    String? claimHotelId,
  }) {
    if (doc.exists) {
      final data = doc.data()!;

      final roleStr = data['role'] as String? ?? 'unassigned';
      final statusStr = data['status'] as String? ?? 'active';

      final role = UserRole.values.firstWhere(
        (e) => e.name == roleStr,
        orElse: () => UserRole.unassigned,
      );

      final status = UserStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => UserStatus.pending,
      );

      final String hotelId;
      try {
        hotelId = resolveTenantHotelId(
          tokenClaimHotelId: claimHotelId,
          documentHotelId: data['hotelId'] as String?,
        );
      } catch (_) {
        // Discrepancia cross-tenant entre token y documento: denegar acceso
        state = const AuthState(isAuthenticated: false, isLoading: false);
        try {
          FirebaseAuth.instance.signOut();
        } catch (_) {}
        return;
      }

      state = AuthState(
        isAuthenticated: true,
        email: email,
        name: data['name'] as String? ?? '',
        role: role,
        status: status,
        hotelId: hotelId,
        isLoading: false,
      );
    } else {
      // Documento no existe
      state = const AuthState(isAuthenticated: false, isLoading: false);
      FirebaseAuth.instance.signOut();
    }
  }

  Future<void> login(String email, String password) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw Exception('Ingresa el correo y la contraseña');
    }

    if (!email.contains('@')) {
      throw Exception('Ingresa un correo válido');
    }

    state = state.copyWith(isLoading: true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      await _fetchAndListenUserDocument(credential.user!.uid, credential.user!.email!);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false);
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Credenciales incorrectas');
      }
      throw Exception(e.message ?? 'Error al iniciar sesión');
    } catch (e) {
      state = state.copyWith(isLoading: false);
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  /// Registra un nuevo empleado en Firebase Auth y Firestore.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String hotelId = 'hotel_101',
  }) async {
    if (name.trim().isEmpty) {
      throw Exception('Ingresa el nombre del empleado');
    }
    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw Exception('Ingresa el correo y la contraseña');
    }
    if (!email.contains('@')) {
      throw Exception('Ingresa un correo válido');
    }
    if (password.length < 6) {
      throw Exception('La contraseña debe tener al menos 6 caracteres');
    }

    state = state.copyWith(isLoading: true);

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'role': UserRole.unassigned.name,
        'status': UserStatus.pending.name,
        'hotelId': hotelId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _fetchAndListenUserDocument(credential.user!.uid, email.trim().toLowerCase());
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false);
      throw Exception(e.message ?? 'Error al registrar');
    }
  }

  Future<void> logout() async {
    _userDocSubscription?.cancel();
    _userDocSubscription = null;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'wearablePin': FieldValue.delete(),
          'wearableLinkedAt': FieldValue.delete(),
        });
      } catch (_) {}
    }
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    state = const AuthState(isAuthenticated: false, isLoading: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Provider que expone el hotelId activo de la sesión del usuario.
/// Provee aislamiento multi-tenant a través de toda la aplicación.
/// Por defecto utiliza 'hotel_101' si el usuario no tiene hotelId configurado.
final currentHotelIdProvider = Provider<String>((ref) {
  final authState = ref.watch(authProvider);
  return authState.hotelId ?? 'hotel_101';
});
