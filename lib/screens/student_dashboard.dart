import 'package:flutter/material.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 225, 200, 200),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/images/logo.png', // استبدل برابط شعارك
            width: 30,
            height: 30,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // قسم معلومات المستخدم
              _buildUserInfo(),
              const SizedBox(height: 20),

              // قسم التقارير
              _buildSectionHeader('Reports'),
              const SizedBox(height: 10),
              _buildReportsSection(),
              const SizedBox(height: 20),

              // قسم دورات اليوم
              _buildSectionHeader('Today\'s Courses'),
              const SizedBox(height: 10),
              _buildTodaysCourses(),
              const SizedBox(height: 20),

              // قسم المعلمين
              _buildSectionHeader('Teachers'),
              const SizedBox(height: 10),
              _buildTeachersSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// تبني واجهة معلومات المستخدم
  Widget _buildUserInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Hello, Mr. Mohamed',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Today, 18th September',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.notifications_none, color: Colors.black),
        ),
      ],
    );
  }

  /// تبني رأس القسم المشترك (مثل "Reports", "Today's Courses")
  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Row(
            children: [
              Text(
                'See All',
                style: TextStyle(color: Colors.grey),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ],
    );
  }

  /// تبني قسم التقارير (الواجبات والحضور)
  Widget _buildReportsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildReportCard(
            title: 'Assignments',
            count: '5',
            status: 'Done',
            subjects: '7 Subjects',
            statusColor: Colors.red,
            iconColor: Colors.red,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildReportCard(
            title: 'Attendance',
            count: '95%',
            status: 'Present',
            subjects: '24 days',
            statusColor: Colors.green,
            iconColor: Colors.green,
          ),
        ),
      ],
    );
  }

  /// تبني بطاقة التقرير الفردية (للواجبات أو الحضور)
  Widget _buildReportCard({
    required String title,
    required String count,
    required String status,
    required String subjects,
    required Color statusColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subjects,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward, color: iconColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// تبني قسم دورات اليوم (القائمة الأفقية)
  Widget _buildTodaysCourses() {
    return SizedBox(
      height: 120, // ارتفاع ثابت للبطاقات
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCourseCard(
            title: 'Arabic',
            time: '10:00 - 12:00',
            status: 'Ongoing',
            borderColor: Colors.green,
            statusColor: Colors.green,
          ),
          const SizedBox(width: 16),
          _buildCourseCard(
            title: 'Math',
            time: '12:30 - 2:00',
            status: 'Upcoming',
            borderColor: Colors.red,
            statusColor: Colors.red,
          ),
          const SizedBox(width: 16),
          _buildCourseCard(
            title: 'Physics',
            time: '02:30 - 4:00',
            status: 'Upcoming',
            borderColor: Colors.blue,
            statusColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  /// تبني بطاقة الدورة الفردية
  Widget _buildCourseCard({
    required String title,
    required String time,
    required String status,
    required Color borderColor,
    required Color statusColor,
  }) {
    return Container(
      width: 150, // عرض ثابت لكل بطاقة
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            time,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// تبني قسم المعلمين (القائمة الأفقية)
  Widget _buildTeachersSection() {
    return SizedBox(
      height: 200, // ارتفاع ثابت للبطاقات
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildTeacherCard(
            name: 'Mohamed Ali',
            subject: 'Biology',
            imageUrl: 'https://i.imgur.com/2Y4Y4Yd.png', // استبدل بصورة المعلم
          ),
          const SizedBox(width: 16),
          _buildTeacherCard(
            name: 'Ahmed Hassan',
            subject: 'Math',
            imageUrl: 'https://i.imgur.com/2Y4Y4Yd.png', // استبدل بصورة المعلم
          ),
          const SizedBox(width: 16),
          _buildTeacherCard(
            name: 'Fatma Salem',
            subject: 'Chemistry',
            imageUrl: 'https://i.imgur.com/2Y4Y4Yd.png', // استبدل بصورة المعلم
          ),
        ],
      ),
    );
  }

  /// تبني بطاقة المعلم الفردية
  Widget _buildTeacherCard({
    required String name,
    required String subject,
    required String imageUrl,
  }) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.network(
              imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subject,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.chat_bubble_outline, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// تبني شريط التنقل السفلي
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Progress',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inbox),
          label: 'Inbox',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}