import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/zoe_colors.dart';
import '../../../core/theme/zoe_typography.dart';
import '../../../core/theme/zoe_spacing.dart';
import '../../cubits/auth/auth_cubit.dart';

class LoginPage extends StatefulWidget {
  final String? returnTo;
  const LoginPage({super.key, this.returnTo});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          final destination = widget.returnTo;
          if (destination != null && destination.isNotEmpty) {
            // Volta para a rota que originou o pedido de login
            context.go(Uri.decodeComponent(destination));
          } else {
            context.go('/home');
          }
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: ZoeColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
      backgroundColor: ZoeColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ZoeSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Logo
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: ZoeColors.secondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Text(
                          'Z',
                          style: TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                            color: ZoeColors.primary,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Bem-vinda ao ZOE', style: ZoeTypography.headlineLarge),
                    const SizedBox(height: 6),
                    Text(
                      'Acesse sua conta para continuar',
                      style: ZoeTypography.bodyMedium.copyWith(color: ZoeColors.mediumGray),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1, end: 0),

              const SizedBox(height: 48),

              // Email
              Text('E-MAIL', style: ZoeTypography.labelMedium.copyWith(letterSpacing: 2)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: ZoeTypography.bodyMedium,
                decoration: _inputDecoration('seu@email.com'),
              ).animate(delay: 200.ms).fadeIn().slideX(begin: -0.05, end: 0),

              const SizedBox(height: 20),

              // Password
              Text('SENHA', style: ZoeTypography.labelMedium.copyWith(letterSpacing: 2)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                style: ZoeTypography.bodyMedium,
                decoration: _inputDecoration('••••••••').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: ZoeColors.mediumGray,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.05, end: 0),

              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text('Esqueceu a senha?', style: ZoeTypography.bodySmall.copyWith(color: ZoeColors.primary)),
                ),
              ),

              const SizedBox(height: 24),

              // Login button
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, authState) {
                  final isLoading = authState is AuthLoading;
                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              final email = _emailController.text.trim();
                              final password = _passwordController.text;
                              if (email.isEmpty || password.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Preencha e-mail e senha'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              context.read<AuthCubit>().login(email, password);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ZoeColors.secondary,
                        foregroundColor: ZoeColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ZoeSpacing.radiusLg),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: ZoeColors.white,
                              ),
                            )
                          : Text(
                              'ENTRAR',
                              style: ZoeTypography.labelLarge.copyWith(color: ZoeColors.white, letterSpacing: 3),
                            ),
                    ),
                  );
                },
              ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1, end: 0),

              const SizedBox(height: 20),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: ZoeColors.lightGray)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('ou', style: ZoeTypography.bodySmall.copyWith(color: ZoeColors.mediumGray)),
                  ),
                  Expanded(child: Divider(color: ZoeColors.lightGray)),
                ],
              ),

              const SizedBox(height: 20),

              // Social buttons
              _SocialButton(icon: Icons.g_mobiledata, label: 'Continuar com Google'),
              const SizedBox(height: 12),
              _SocialButton(icon: Icons.apple, label: 'Continuar com Apple'),

              const SizedBox(height: 32),

              // Register
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Não tem uma conta? ', style: ZoeTypography.bodyMedium.copyWith(color: ZoeColors.mediumGray)),
                    GestureDetector(
                      onTap: () {},
                      child: Text('Criar conta', style: ZoeTypography.bodyMedium.copyWith(color: ZoeColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: ZoeTypography.bodyMedium.copyWith(color: ZoeColors.mediumGray),
      filled: true,
      fillColor: ZoeColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ZoeSpacing.radiusMd),
        borderSide: BorderSide(color: ZoeColors.lightGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ZoeSpacing.radiusMd),
        borderSide: BorderSide(color: ZoeColors.lightGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ZoeSpacing.radiusMd),
        borderSide: const BorderSide(color: ZoeColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SocialButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 24, color: ZoeColors.charcoal),
        label: Text(label, style: ZoeTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ZoeSpacing.radiusMd),
          ),
          side: const BorderSide(color: ZoeColors.lightGray),
        ),
      ),
    );
  }
}
