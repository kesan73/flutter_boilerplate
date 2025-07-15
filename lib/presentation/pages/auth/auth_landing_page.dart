import 'package:flutter/material.dart';

class AuthLandingPage extends StatelessWidget {
  const AuthLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.phone_android,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '환영합니다!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2c3e50),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'MyApp과 함께 시작해보세요',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF7f8c8d),
                ),
              ),
              const SizedBox(height: 50),
              _buildAuthButton(
                context,
                '로그인',
                () => Navigator.pushNamed(context, '/login'),
                isPrimary: true,
              ),
              const SizedBox(height: 15),
              _buildAuthButton(
                context,
                '회원가입',
                () => Navigator.pushNamed(context, '/signup'),
                isPrimary: false,
              ),
              const SizedBox(height: 30),
              _buildDivider(),
              const SizedBox(height: 20),
              _buildSocialButtons(context),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // 게스트 로그인 처리
                },
                child: const Text(
                  '게스트로 시작하기',
                  style: TextStyle(
                    color: Color(0xFF7f8c8d),
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthButton(
    BuildContext context,
    String text,
    VoidCallback onPressed, {
    required bool isPrimary,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? const Color(0xFF667eea) : Colors.white,
          foregroundColor: isPrimary ? Colors.white : const Color(0xFF667eea),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isPrimary
                ? BorderSide.none
                : const BorderSide(color: Color(0xFF667eea), width: 2),
          ),
          elevation: isPrimary ? 2 : 0,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFe0e0e0),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            '또는',
            style: TextStyle(
              color: Color(0xFFbdc3c7),
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFe0e0e0),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton('G', () {
            // Google 로그인
          }),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSocialButton('🍎', () {
            // Apple 로그인
          }),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSocialButton('K', () {
            // Kakao 로그인
          }),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSocialButton('N', () {
            // Naver 로그인
          }),
        ),
      ],
    );
  }

  Widget _buildSocialButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2c3e50),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFe0e0e0)),
        ),
        elevation: 0,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
