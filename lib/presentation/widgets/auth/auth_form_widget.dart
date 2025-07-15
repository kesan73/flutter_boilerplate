import 'package:flutter/material.dart';
import '../../../core/utils/validators.dart';
import '../common/custom_text_field.dart';
import '../common/custom_button.dart';

class AuthFormWidget extends StatefulWidget {
  final AuthFormType formType;
  final VoidCallback? onSubmit;
  final bool isLoading;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController? confirmPasswordController;

  const AuthFormWidget({
    Key? key,
    required this.formType,
    this.onSubmit,
    this.isLoading = false,
    required this.emailController,
    required this.passwordController,
    this.confirmPasswordController,
  }) : super(key: key);

  @override
  State<AuthFormWidget> createState() => _AuthFormWidgetState();
}

class _AuthFormWidgetState extends State<AuthFormWidget> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextField(
            label: 'Email',
            hint: 'Enter your email',
            controller: widget.emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined),
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Password',
            hint: 'Enter your password',
            controller: widget.passwordController,
            obscureText: true,
            prefixIcon: const Icon(Icons.lock_outlined),
            validator: widget.formType == AuthFormType.forgotPassword
                ? null
                : Validators.validatePassword,
          ),
          if (widget.formType == AuthFormType.register &&
              widget.confirmPasswordController != null) ...[
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Confirm Password',
              hint: 'Confirm your password',
              controller: widget.confirmPasswordController!,
              obscureText: true,
              prefixIcon: const Icon(Icons.lock_outlined),
              validator: (value) => Validators.validateConfirmPassword(
                value,
                widget.passwordController.text,
              ),
            ),
          ],
          const SizedBox(height: 24),
          CustomButton(
            text: _getButtonText(),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                widget.onSubmit?.call();
              }
            },
            isLoading: widget.isLoading,
          ),
        ],
      ),
    );
  }

  String _getButtonText() {
    switch (widget.formType) {
      case AuthFormType.login:
        return 'Login';
      case AuthFormType.register:
        return 'Register';
      case AuthFormType.forgotPassword:
        return 'Reset Password';
    }
  }
}

enum AuthFormType { login, register, forgotPassword }
