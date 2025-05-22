import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
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
            _buildSectionTitle('Privacy Policy for FoodAI'),
            _buildParagraph(
              'This Privacy Policy describes how FoodAI ("we," "us," or "our") collects, uses, and shares your personal information when you use our mobile application ("App"). By using the App, you agree to the collection and use of information in accordance with this policy.',
            ),
            
            _buildSectionTitle('1. Information We Collect'),
            _buildParagraph(
              'We collect several types of information from and about users of our App, including:',
            ),
            _buildBulletPoint(
              'Personal information you provide to us, such as your name, email address, gender, age, height, weight, and fitness goals.',
            ),
            _buildBulletPoint(
              'Information about your device, such as your device type, operating system, and unique device identifiers.',
            ),
            _buildBulletPoint(
              'Usage data, such as the features you use, the time and duration of your use, and other statistics.',
            ),
            _buildBulletPoint(
              'Food and nutrition data you enter or capture through the App, including photos of food, meal logs, and calorie information.',
            ),
            
            _buildSectionTitle('2. How We Use Your Information'),
            _buildParagraph(
              'We use the information we collect to:',
            ),
            _buildBulletPoint(
              'Provide, maintain, and improve the App and its features.',
            ),
            _buildBulletPoint(
              'Personalize your experience and deliver content relevant to your interests.',
            ),
            _buildBulletPoint(
              'Calculate and track your nutrition, calories, and progress toward your health goals.',
            ),
            _buildBulletPoint(
              'Communicate with you, including sending you notifications, updates, and support messages.',
            ),
            _buildBulletPoint(
              'Analyze usage patterns and trends to improve the App and develop new features.',
            ),
            
            _buildSectionTitle('3. Sharing Your Information'),
            _buildParagraph(
              'We do not sell your personal information to third parties. We may share your information in the following circumstances:',
            ),
            _buildBulletPoint(
              'With service providers who perform services on our behalf, such as hosting, data analysis, and customer service.',
            ),
            _buildBulletPoint(
              'To comply with legal obligations, such as responding to a court order or government request.',
            ),
            _buildBulletPoint(
              'To protect our rights, property, or safety, or the rights, property, or safety of our users or others.',
            ),
            _buildBulletPoint(
              'In connection with a business transaction, such as a merger, acquisition, or sale of assets.',
            ),
            
            _buildSectionTitle('4. Data Security'),
            _buildParagraph(
              'We take reasonable measures to protect your personal information from unauthorized access, use, or disclosure. However, no method of transmission over the internet or electronic storage is 100% secure, and we cannot guarantee absolute security.',
            ),
            
            _buildSectionTitle('5. Your Choices'),
            _buildParagraph(
              'You can access, update, or delete your personal information through the App settings. You can also choose to disable certain features, such as notifications, through your device settings.',
            ),
            
            _buildSectionTitle('6. Children\'s Privacy'),
            _buildParagraph(
              'The App is not intended for children under the age of 13, and we do not knowingly collect personal information from children under 13. If we learn that we have collected personal information from a child under 13, we will take steps to delete that information.',
            ),
            
            _buildSectionTitle('7. Changes to This Privacy Policy'),
            _buildParagraph(
              'We may update this Privacy Policy from time to time. If we make material changes, we will notify you by email or by posting a notice on the App. Your continued use of the App after such modifications will constitute your acknowledgment of the modified Privacy Policy.',
            ),
            
            _buildSectionTitle('8. Contact Us'),
            _buildParagraph(
              'If you have any questions about this Privacy Policy, please contact us at privacy@foodai.app.',
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

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
