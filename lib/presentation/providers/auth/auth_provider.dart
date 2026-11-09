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
    this.isLoading = false,
  });

  final bool isAuthenticated;
  final String? email;
  final String? name;
  final UserRole? role;
  final UserStatus? status;
  final bool isLoading;

  AuthState copyWith({
    bool? isAuthenticated,
    String? email,
    String? name,
    UserRole? role,
    UserStatus? status,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      status: status ?? this.status,
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
  }

  /// Escucha en tiempo real los cambios del documento /users/{uid} en Firestore.
  /// Esto permite reaccionar inmediatamente a aprobaciones de cuenta y cambios de rol.
  Future<void> _fetchAndListenUserDocument(String uid, String email) async {
    _userDocSubscription?.cancel();

    // 1. Lectura inmediata para no retrasar el inicio de sesión
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      _updateStateFromSnapshot(doc, email);
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
        _updateStateFromSnapshot(doc, email);
      },
      onError: (_) {
        state = const AuthState(isAuthenticated: false, isLoading: false);
      },
    );
  }

  void _updateStateFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String email,
  ) {
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

      state = AuthState(
        isAuthenticated: true,
        email: email,
        name: data['name'] as String? ?? '',
        role: role,
        status: status,
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
