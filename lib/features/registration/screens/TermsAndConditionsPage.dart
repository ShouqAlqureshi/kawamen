import 'package:flutter/material.dart';
import 'package:kawamen/core/utils/theme/ThemedScaffold.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App bar with back button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'الشروط والأحكام',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end, // Right-align for Arabic
                  children: [
                    _buildSectionTitle(context, 'مرحباً بك في تطبيق كَوامِن'),
                    _buildParagraph(
                      'نحن نقدر ثقتك بنا ونلتزم بحماية خصوصيتك وبياناتك الشخصية. يرجى قراءة الشروط والأحكام التالية بعناية قبل استخدام التطبيق أو إنشاء حساب.',
                    ),
                    
                    const SizedBox(height: 16),
                    _buildSectionTitle(context, ' ١. القبول بالشروط'),
                    _buildParagraph(
                      'باستخدامك لتطبيق كَوامِن، فإنك توافق على الالتزام بهذه الشروط والأحكام. إذا كنت لا توافق على أي من هذه الشروط، يرجى عدم استخدام التطبيق.',
                    ),
                    
                    const SizedBox(height: 16),
                    _buildSectionTitle(context, ' ٢. التسجيل والحساب'),
                    _buildParagraph(
                      'يجب أن يكون عمرك 16 عاماً على الأقل لإنشاء حساب في تطبيق كَوامِن. أنت مسؤول عن الحفاظ على سرية كلمة المرور الخاصة بك وعن جميع الأنشطة التي تحدث تحت حسابك.',
                    ),
                    _buildParagraph(
                      'تلتزم بتقديم معلومات دقيقة وكاملة عند إنشاء حسابك وتحديثها عند الضرورة.',
                    ),
                    
                    const SizedBox(height: 16),
                    _buildSectionTitle(context, ' ٣. الخصوصية وجمع البيانات'),
                    _buildParagraph(
                      'نحن نجمع ونستخدم بياناتك الشخصية وفقاً لسياسة الخصوصية الخاصة بنا. باستخدامك للتطبيق، فإنك توافق على جمع واستخدام معلوماتك كما هو موضح في سياسة الخصوصية.',
                    ),
                    _buildParagraph(
                      'يستخدم تطبيق كَوامِن تقنية تحليل المشاعر من خلال الصوت لتقديم خدمات الرفاهية النفسية. أنت توافق على أن يتم تحليل التسجيلات الصوتية التي تقدمها لهذا الغرض.',
                    ),
                    
                    const SizedBox(height: 16),
                    _buildSectionTitle(context, '٤. استخدام التطبيق'),
                    _buildParagraph(
                      'تطبيق كَوامِن مصمم للمساعدة في تحسين الرفاهية النفسية ومراقبة الحالة العاطفية، ولكنه ليس بديلاً عن الاستشارة الطبية أو النفسية المتخصصة.',
                    ),
                    _buildParagraph(
                      'أنت توافق على عدم استخدام التطبيق لأغراض غير قانونية أو محظورة بموجب هذه الشروط.',
                    ),
                    
                    const SizedBox(height: 16),
                    _buildSectionTitle(context, '٥. المحتوى والملكية الفكرية'),
                    _buildParagraph(
                      'جميع حقوق الملكية الفكرية في التطبيق والمحتوى الذي نقدمه مملوكة لنا أو مرخصة لنا. لا يجوز نسخ أو توزيع أو تعديل أي جزء من التطبيق دون إذن كتابي مسبق.',
                    ),
                    
                    const SizedBox(height: 16),
                    _buildSectionTitle(context, '٦. إخلاء المسؤولية'),
                    _buildParagraph(
                      'يتم توفير التطبيق "كما هو" دون أي ضمانات من أي نوع. لا نتحمل المسؤولية عن أي أضرار مباشرة أو غير مباشرة ناتجة عن استخدام التطبيق.',
                    ),
                    _buildParagraph(
                      'المعلومات المقدمة في التطبيق هي لأغراض عامة فقط ولا ينبغي اعتبارها نصيحة طبية أو نفسية.',
                    ),
                    
                    const SizedBox(height: 16),
                    _buildSectionTitle(context, '٧. التغييرات على الشروط'),
                    _buildParagraph(
                      'نحتفظ بالحق في تعديل هذه الشروط في أي وقت. سيتم إخطارك بالتغييرات المهمة عبر التطبيق أو عبر البريد الإلكتروني المسجل.',
                    ),
                    
                    const SizedBox(height: 16),
                    _buildSectionTitle(context, ' ٨. القانون المطبق'),
                    _buildParagraph(
                      'تخضع هذه الشروط للقوانين المعمول بها وسيتم تفسيرها وفقاً لها، دون إعطاء أي تأثير لأي تعارض في القوانين.',
                    ),
                    
                    const SizedBox(height: 16),
                    _buildSectionTitle(context, ' ٩. الاتصال بنا'),
                    _buildParagraph(
                      'إذا كان لديك أي أسئلة أو استفسارات حول هذه الشروط والأحكام،[Contact@kawamen.sa] يرجى التواصل معنا عبر ',
                    ),
                    
                    const SizedBox(height: 32),
                    _buildFooter('تم التحديث في: أبريل 2025'),
                  ],
                ),
              ),
            ),
            
        
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          height: 1.5,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildFooter(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 12,
      ),
      textAlign: TextAlign.center,
    );
  }
}