import 'package:flutter/material.dart';
// Assuming AppColors and AppTextStyles are defined in app_styles.dart
// import 'package:learnaria_app/utils/app_styles.dart'; // Uncomment if you use AppColors/AppTextStyles here

class ProgressReportScreen extends StatelessWidget {
  const ProgressReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Or a very light grey for the background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // REMOVED: leading IconButton (back button)
        // Set leading to null or an empty Container to remove the back button
        leading: null, // This removes the back button entirely
        automaticallyImplyLeading: false, // Ensures no default back button is added
        title: Text(
          'Progress Report',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Section
              _buildUserInfoSection(),
              SizedBox(height: 20),

              // Attendance Section
              _buildAttendanceSection(),
              SizedBox(height: 20),

              // Feedback Section
              _buildFeedbackSection(),
              SizedBox(height: 20),

              // Month View Section
              _buildMonthViewSection(),
              SizedBox(height: 20), // Adjusted space as bottom nav is external
            ],
          ),
        ),
      ),
      // REMOVED: bottomNavigationBar from here
    );
  }

  Widget _buildUserInfoSection() {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[200],
          child: Icon(Icons.person, color: Colors.grey[600]),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, Mr. Mohamed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                'Today, 18th September', // Dynamically update this if needed
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Image(image: AssetImage('assets/images/notification-bell.png'), height: 24, width: 24), // Replace with your actual settings icon path
        ),
      ],
    );
  }

  Widget _buildAttendanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '90 days',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      '(out of 100 days)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '10 days missed',
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
              SizedBox(height: 5),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '3 upcoming holidays',
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Feedback',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              'See All >',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildFeedbackCard('Arabic', 'excellent', Colors.green, 95),
            ),
            SizedBox(width: 15),
            Expanded(
              child: _buildFeedbackCard('English', 'need improvement', Colors.red, 74),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeedbackCard(String language, String status, Color statusColor, int percentage) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            language,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 5),
          Text(
            status,
            style: TextStyle(
              fontSize: 14,
              color: statusColor,
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Icon(Icons.arrow_forward, color: Colors.black),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthViewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Month View',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: 200, // Adjust height as needed
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              CustomPaint(
                painter: BarChartPainter(),
                child: Container(), // Empty container as child for CustomPaint
              ),
              // "20 Activities" overlay for April bar
              Positioned(
                right: 60, // Adjust based on your bar positions
                bottom: 60, // Adjust to place it correctly above the bar
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '20 Activities',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BarChartPainter extends CustomPainter {
  final List<double> data = [35, 42, 30, 45, 20, 38]; // Example data for Dec, Jan, Feb, Mar, Apr, May
  final List<String> labels = ['Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May'];
  final double maxValue = 45; // Max value in data for scaling

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = (size.width - (data.length - 1) * 20) / data.length; // Adjust spacing
    final barRadius = Radius.circular(5); // For rounded corners of bars

    // Draw horizontal grid lines and Y-axis labels
    final linePaint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) { // For values 0, 10, 20, 30, 40
      final yValue = i * 10;
      final yPosition = size.height - (yValue / maxValue) * size.height; // Scale Y position
      canvas.drawLine(Offset(0, yPosition), Offset(size.width, yPosition), linePaint);

      // Draw Y-axis labels
      TextPainter(
        text: TextSpan(
          text: '$yValue',
          style: TextStyle(color: Colors.grey[600], fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout()
        ..paint(canvas, Offset(-15, yPosition - 7)); // Adjust position for labels
    }

    // Draw bars
    for (int i = 0; i < data.length; i++) {
      final barHeight = (data[i] / maxValue) * size.height;
      final x = i * (barWidth + 20); // Adjust spacing between bars
      final rect = Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight);

      final paint = Paint()
        ..style = PaintingStyle.fill;

      // Specific color for April bar and May bar (lighter)
      if (labels[i] == 'Apr') {
        paint.color = Colors.grey[600]!; // Darker grey for April
      } else if (labels[i] == 'May') {
        paint.color = Colors.grey[300]!; // Lighter grey for May
      } else {
        paint.color = Colors.grey[400]!; // Default grey
      }
      canvas.drawRRect(RRect.fromRectAndRadius(rect, barRadius), paint);

      // Draw month labels
      TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(color: Colors.grey[700], fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout()
        ..paint(canvas, Offset(x + barWidth / 2 - (labels[i].length * 3), size.height + 5)); // Adjust position
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
