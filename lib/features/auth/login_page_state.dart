import 'package:flutter_riverpod/flutter_riverpod.dart';

final loginPageProvider = StateNotifierProvider<LoginPageNotifier, LoginPageState>((ref) {
  return LoginPageNotifier();
});

class LoginPageState {
  final bool isSignUp;
  final bool isLoading;
  final bool rememberMe;
  final bool agreeToTerms;
  final bool acknowledgeHipaa;
  final String? mfaChallengeFactorId;

  LoginPageState({
    this.isSignUp = false,
    this.isLoading = false,
    this.rememberMe = false,
    this.agreeToTerms = false,
    this.acknowledgeHipaa = false,
    this.mfaChallengeFactorId,
  });

  LoginPageState copyWith({
    bool? isSignUp,
    bool? isLoading,
    bool? rememberMe,
    bool? agreeToTerms,
    bool? acknowledgeHipaa,
    String? mfaChallengeFactorId,
  }) {
    return LoginPageState(
      isSignUp: isSignUp ?? this.isSignUp,
      isLoading: isLoading ?? this.isLoading,
      rememberMe: rememberMe ?? this.rememberMe,
      agreeToTerms: agreeToTerms ?? this.agreeToTerms,
      acknowledgeHipaa: acknowledgeHipaa ?? this.acknowledgeHipaa,
      mfaChallengeFactorId: mfaChallengeFactorId ?? this.mfaChallengeFactorId,
    );
  }
}

class LoginPageNotifier extends StateNotifier<LoginPageState> {
  LoginPageNotifier() : super(LoginPageState());

  void toggleSignUp() {
    state = state.copyWith(isSignUp: !state.isSignUp);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setRememberMe(bool rememberMe) {
    state = state.copyWith(rememberMe: rememberMe);
  }

  void setAgreeToTerms(bool agreeToTerms) {
    state = state.copyWith(agreeToTerms: agreeToTerms);
  }

  void setAcknowledgeHipaa(bool acknowledgeHipaa) {
    state = state.copyWith(acknowledgeHipaa: acknowledgeHipaa);
  }

  void setMfaChallengeFactorId(String? mfaChallengeFactorId) {
    state = state.copyWith(mfaChallengeFactorId: mfaChallengeFactorId);
  }
}
