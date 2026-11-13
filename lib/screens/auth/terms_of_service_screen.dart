import 'package:flutter/material.dart';

import 'legal_document_screen.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      title: 'Terms of Service',
      children: [
        LegalParagraph('Effective date: March 18, 2026'),
        LegalParagraph(
          'These Terms of Service govern your use of Gospel Beacon, a gospel study and lesson-planning app that lets users create accounts, build lesson plans, manage groups, and share study resources. By creating an account or using Gospel Beacon, you agree to these terms and to the Gospel Beacon Privacy Policy.',
        ),
        LegalHeading('1. Using Gospel Beacon'),
        LegalParagraph(
          'You may use Gospel Beacon only in compliance with these terms and applicable law. If you are using Gospel Beacon on behalf of a family, class, quorum, ward, or other group, you are responsible for having authority to do so.',
        ),
        LegalBulletList([
          'You must provide accurate account information and keep it reasonably current.',
          'You are responsible for activity that happens through your account.',
          'If you are below the age required to form a binding agreement where you live, a parent or legal guardian must review and agree to these terms for you.',
        ]),
        LegalHeading('2. Accounts and Security'),
        LegalParagraph(
          'Gospel Beacon currently uses email-and-password authentication. You are responsible for maintaining the confidentiality of your login credentials and for notifying us promptly if you believe your account has been accessed without permission.',
        ),
        LegalParagraph(
          'Gospel Beacon may send account-related messages needed to verify your email address, help you recover access, or protect the security of the service.',
        ),
        LegalHeading('3. User Content'),
        LegalParagraph(
          'You retain ownership of the content you create in Gospel Beacon, including lesson titles, descriptions, lesson sections, notes, linked resources, profile information, and group content that you submit.',
        ),
        LegalParagraph(
          'You give Gospel Beacon a limited permission to host, store, format, display, and share that content only as needed to operate the app and its group features.',
        ),
        LegalBulletList([
          'Do not upload content you do not have the right to use or share.',
          'Do not upload unlawful, abusive, harassing, misleading, or infringing content.',
          'Do not use Gospel Beacon to scrape user data, interfere with the service, or attempt unauthorized access to accounts, systems, or groups.',
        ]),
        LegalHeading('4. Groups and Shared Content'),
        LegalParagraph(
          'Gospel Beacon includes features that allow users to create groups, invite members, assign roles, share lesson plans with those groups, and use join codes. Content shared to a group may be visible to that group\u2019s members according to the app\u2019s current functionality.',
        ),
        LegalParagraph(
          'If you invite other people into a group, you are responsible for using those features appropriately and for sharing only information you are comfortable making available to the relevant users.',
        ),
        LegalHeading('5. Profile and Resource Features'),
        LegalParagraph(
          'Gospel Beacon may allow you to upload a profile photo or group photo, enter optional profile details such as your name or phone number, and save links to outside study resources. External websites opened from Gospel Beacon or added as resources are governed by their own terms and privacy practices, not Gospel Beacon\u2019s.',
        ),
        LegalHeading('6. Ownership of Gospel Beacon'),
        LegalParagraph(
          'Gospel Beacon and its software, design, branding, and underlying service are owned by Gospel Beacon and its licensors. These terms do not transfer ownership of the app or its intellectual property to you.',
        ),
        LegalParagraph(
          'Subject to these terms, Gospel Beacon grants you a limited, non-exclusive, non-transferable, revocable right to use the app for personal, non-commercial use.',
        ),
        LegalHeading('7. Service Availability and Changes'),
        LegalParagraph(
          'Gospel Beacon may update, improve, suspend, or discontinue features at any time. We may also revise these terms or the Privacy Policy by posting an updated version inside the app or otherwise making it available to users. Your continued use of Gospel Beacon after the updated terms become effective means you accept the revised terms.',
        ),
        LegalHeading('8. Suspension and Termination'),
        LegalParagraph(
          'We may suspend or terminate your access to Gospel Beacon if we reasonably believe you have violated these terms, created risk for other users, misused the service, or used Gospel Beacon unlawfully. You may stop using Gospel Beacon at any time.',
        ),
        LegalParagraph(
          'If your access is terminated, shared content, group data, and other information associated with your account may no longer be available to you.',
        ),
        LegalHeading('9. Disclaimers'),
        LegalParagraph(
          'Gospel Beacon is provided on an "as is" and "as available" basis. To the maximum extent permitted by law, Gospel Beacon disclaims warranties of merchantability, fitness for a particular purpose, non-infringement, and uninterrupted or error-free operation.',
        ),
        LegalParagraph(
          'Gospel Beacon is a study and organization tool. It is not legal, pastoral, medical, or emergency guidance, and it is not guaranteed to preserve content permanently.',
        ),
        LegalHeading('10. Limitation of Liability'),
        LegalParagraph(
          'To the maximum extent permitted by law, Gospel Beacon and its operators will not be liable for indirect, incidental, special, consequential, exemplary, or punitive damages, or for any loss of data, goodwill, profits, or business interruption arising out of or related to your use of Gospel Beacon.',
        ),
        LegalParagraph(
          'If the law does not allow the full exclusion above, Gospel Beacon\u2019s total liability for claims arising from the service will be limited to the amount you paid, if any, to use Gospel Beacon during the 12 months before the event giving rise to the claim.',
        ),
        LegalHeading('11. Governing Law'),
        LegalParagraph(
          'These terms are governed by the laws that apply in the jurisdiction from which Gospel Beacon is operated, without regard to conflict-of-law rules, except where mandatory consumer laws require otherwise.',
        ),
        LegalHeading('12. Contact and Questions'),
        LegalParagraph(
          'If you have questions about these terms or want to request account-related help, please use the contact email or support channel identified for Gospel Beacon in the place where you obtained the app or where Gospel Beacon is officially distributed.',
        ),
      ],
    );
  }
}
