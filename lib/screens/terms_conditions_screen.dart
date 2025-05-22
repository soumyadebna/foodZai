import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Terms & Conditions',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black87,
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Terms and Conditions for FoodAI'),
            _buildParagraph(
              'These Terms and Conditions ("Terms") govern your use of the FoodAI mobile application ("App") provided by FoodAI ("we," "us," or "our"). By downloading, installing, or using the App, you agree to be bound by these Terms. If you do not agree to these Terms, please do not use the App.',
            ),
            
            _buildSectionTitle('1. Use of the App'),
            _buildParagraph(
              'The App is designed to help you track your nutrition, calories, and health goals. The information provided by the App is for general informational purposes only and is not intended to be a substitute for professional medical advice, diagnosis, or treatment.',
            ),
            
            _buildSectionTitle('2. User Accounts'),
            _buildParagraph(
              'You may be required to create an account to use certain features of the App. You are responsible for maintaining the confidentiality of your account information and for all activities that occur under your account. You agree to provide accurate and complete information when creating your account and to update your information as necessary.',
            ),
            
            _buildSectionTitle('3. Privacy'),
            _buildParagraph(
              'Your privacy is important to us. Our Privacy Policy explains how we collect, use, and protect your personal information. By using the App, you consent to the collection and use of your information as described in our Privacy Policy.',
            ),
            
            _buildSectionTitle('4. Content'),
            _buildParagraph(
              'The App may allow you to submit content, such as food entries, photos, and comments. You retain ownership of any content you submit, but you grant us a non-exclusive, royalty-free, worldwide license to use, reproduce, modify, adapt, publish, translate, and distribute your content in connection with the App.',
            ),
            
            _buildSectionTitle('5. Prohibited Conduct'),
            _buildParagraph(
              'You agree not to use the App for any unlawful purpose or in any way that could damage, disable, overburden, or impair the App. You also agree not to attempt to gain unauthorized access to any part of the App or any system or network connected to the App.',
            ),
            
            _buildSectionTitle('6. Disclaimer of Warranties'),
            _buildParagraph(
              'THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED. TO THE FULLEST EXTENT PERMITTED BY LAW, WE DISCLAIM ALL WARRANTIES, INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.',
            ),
            
            _buildSectionTitle('7. Limitation of Liability'),
            _buildParagraph(
              'TO THE FULLEST EXTENT PERMITTED BY LAW, IN NO EVENT SHALL WE BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING, BUT NOT LIMITED TO, LOSS OF PROFITS, DATA, USE, GOODWILL, OR OTHER INTANGIBLE LOSSES, RESULTING FROM YOUR ACCESS TO OR USE OF OR INABILITY TO ACCESS OR USE THE APP.',
            ),
            
            _buildSectionTitle('8. Changes to Terms'),
            _buildParagraph(
              'We reserve the right to modify these Terms at any time. If we make material changes to these Terms, we will notify you by email or by posting a notice on the App. Your continued use of the App after such modifications will constitute your acknowledgment of the modified Terms and agreement to abide and be bound by the modified Terms.',
            ),
            
            _buildSectionTitle('9. Governing Law'),
            _buildParagraph(
              'These Terms shall be governed by and construed in accordance with the laws of the jurisdiction in which we operate, without regard to its conflict of law provisions.',
            ),
            
            _buildSectionTitle('10. Contact Us'),
            _buildParagraph(
              'If you have any questions about these Terms, please contact us at support@foodai.app.',
            ),
            
            const SizedBox(height: 32),
            
            Center(
              child: Text(
                'Last updated: June 2023',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          height: 1.5,
          color: Colors.black87,
        ),
      ),
    );
  }
}
