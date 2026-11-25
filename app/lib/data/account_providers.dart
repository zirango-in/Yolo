import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Account details that live beside the profile: login methods, phone, email,
/// guest flag, lucky (short) Yolo ID. Maps to /me/account endpoints on Laravel.
class AccountState {
  final String phone;
  final String email;
  final bool isGuest;
  final Set<String> bindings; // phone, email, google, facebook, apple
  final int? luckyId;

  const AccountState({this.phone = '', this.email = '', this.isGuest = false, this.bindings = const {}, this.luckyId});

  AccountState copyWith({String? phone, String? email, bool? isGuest, Set<String>? bindings, int? luckyId}) => AccountState(
        phone: phone ?? this.phone,
        email: email ?? this.email,
        isGuest: isGuest ?? this.isGuest,
        bindings: bindings ?? this.bindings,
        luckyId: luckyId ?? this.luckyId,
      );
}

final accountProvider = NotifierProvider<AccountController, AccountState>(AccountController.new);

class AccountController extends Notifier<AccountState> {
  @override
  AccountState build() => const AccountState();

  void signedInWith(String method, {String phone = '', String email = ''}) => state = AccountState(
        phone: phone,
        email: email,
        isGuest: method == 'guest',
        bindings: method == 'guest' ? {} : {method},
      );

  void setPhone(String phone) => state = state.copyWith(phone: phone, bindings: {...state.bindings, 'phone'});

  void toggleBinding(String method) => state = state.copyWith(
        bindings: state.bindings.contains(method) ? ({...state.bindings}..remove(method)) : {...state.bindings, method},
      );

  void setLuckyId(int id) => state = state.copyWith(luckyId: id);

  void reset() => state = const AccountState();
}

/// Demo OTP rules: the demo code is always 123456. The real code comes by SMS from Laravel.
class OtpService {
  static const demoCode = '123456';
  static Future<void> send(String target) => Future<void>.delayed(const Duration(milliseconds: 600));
  static Future<bool> verify(String target, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return code == demoCode;
  }
}

String maskPhone(String p) => p.length < 6 ? p : '${p.substring(0, p.length - 6)}••••${p.substring(p.length - 2)}';
