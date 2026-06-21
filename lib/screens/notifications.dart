import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/l10n/app_localizations.dart';
import 'package:learnaria/widgets/glass_container.dart'; // Contains LiquidBackground
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learnaria/services/firestore_api.dart';
import 'package:learnaria/models/notification_item.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      final parentPhone = user?.email?.split('@').first;
      if (parentPhone == null || parentPhone.isEmpty) {
        throw Exception('User phone number not found');
      }

      final fetched = await FirestoreApi().fetchNotifications(parentPhoneNumber: parentPhone);
      
      // Load local read IDs
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList('read_notification_ids') ?? [];

      for (var item in fetched) {
        if (readIds.contains(item.id)) {
          item.isRead = true;
        }
      }

      if (mounted) {
        setState(() {
          _notifications = fetched;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList('read_notification_ids') ?? [];
      
      setState(() {
        for (var n in _notifications) {
          n.isRead = true;
          if (!readIds.contains(n.id)) {
            readIds.add(n.id);
          }
        }
      });

      await prefs.setStringList('read_notification_ids', readIds);
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> _toggleRead(NotificationItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList('read_notification_ids') ?? [];

      setState(() {
        item.isRead = !item.isRead;
        if (item.isRead) {
          if (!readIds.contains(item.id)) {
            readIds.add(item.id);
          }
        } else {
          readIds.remove(item.id);
        }
      });

      await prefs.setStringList('read_notification_ids', readIds);
    } catch (e) {
      debugPrint('Error toggling read state: $e');
    }
  }

  List<NotificationItem> get _filteredNotifications {
    if (_selectedCategory == 'all') return _notifications;
    return _notifications.where((n) => n.category == _selectedCategory).toList();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'grade':
        return AppColors.primaryYello;
      case 'attendance':
        return Colors.blue;
      case 'payment':
        return AppColors.greenSuccess;
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          title: Text(
            appLocalizations.notifications,
            style: AppTextStyles.heading2.copyWith(color: textColor, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                locale == 'ar' ? 'تحديد الكل كمقروء' : 'Mark all as read',
                style: const TextStyle(color: AppColors.primaryYello, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Category Filter Strip
            _buildCategoryFilter(locale, isDark),
            
            // Notification History List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYello),
                      ),
                    )
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              _errorMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        )
                      : _filteredNotifications.isEmpty
                          ? Center(
                              child: Text(
                                appLocalizations.noNotificationsYet,
                                style: AppTextStyles.secondaryText,
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadNotifications,
                              color: AppColors.primaryYello,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: GlassContainer(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: ListView.separated(
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: _filteredNotifications.length,
                                    separatorBuilder: (context, index) => Divider(
                                      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                                      height: 1,
                                      thickness: 0.5,
                                    ),
                                    itemBuilder: (context, index) {
                                      final item = _filteredNotifications[index];
                                      final title = locale == 'ar' ? item.titleAr : item.title;
                                      final body = locale == 'ar' ? item.bodyAr : item.body;
                                      final formattedTime = DateFormat('h:mm a', locale).format(item.timestamp);
                                      final dateLabel = DateUtils.isSameDay(item.timestamp, DateTime.now())
                                          ? (locale == 'ar' ? 'اليوم' : 'Today')
                                          : DateFormat('dd MMM', locale).format(item.timestamp);

                                      return GestureDetector(
                                        onTap: () => _toggleRead(item),
                                        behavior: HitTestBehavior.opaque,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Simple category indicator dot
                                              Container(
                                                margin: const EdgeInsets.only(top: 6),
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: _getCategoryColor(item.category),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              
                                              // Notification Details
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            title,
                                                            style: TextStyle(
                                                              fontSize: 15,
                                                              fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                                                              color: textColor,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          '$dateLabel, $formattedTime',
                                                          style: const TextStyle(
                                                            fontSize: 11,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      body,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: isDark ? Colors.white60 : Colors.black87,
                                                        height: 1.35,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              
                                              // Unread status dot
                                              if (!item.isRead)
                                                Container(
                                                  margin: const EdgeInsets.only(left: 10, top: 6),
                                                  width: 7,
                                                  height: 7,
                                                  decoration: const BoxDecoration(
                                                    color: AppColors.errorRed,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(String locale, bool isDark) {
    final categories = [
      {'id': 'all', 'labelEn': 'All', 'labelAr': 'الكل'},
      {'id': 'grade', 'labelEn': 'Grades', 'labelAr': 'الدرجات'},
      {'id': 'attendance', 'labelEn': 'Attendance', 'labelAr': 'الغياب'},
      {'id': 'payment', 'labelEn': 'Payments', 'labelAr': 'المدفوعات'},
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 10, bottom: 5),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat['id'];
          final label = locale == 'ar' ? cat['labelAr']! : cat['labelEn']!;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = cat['id']!;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.primaryYello 
                    : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected 
                      ? AppColors.primaryYello 
                      : (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight),
                  width: 1.2,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
