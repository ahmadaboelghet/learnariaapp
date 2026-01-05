/* eslint-disable max-len */
const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();

// ===================================================================
// (الجزء الأول: دوال مساعدة)
// ===================================================================

/**
 * جلب اسم المادة للمدرس.
 * @param {string} teacherId
 * @return {Promise<string>}
 */
async function getTeacherSubject(teacherId) {
  try {
    const doc = await admin.firestore().collection("teachers").doc(teacherId).get();
    if (doc.exists) {
      return doc.data().subject || "المادة";
    }
  } catch (e) {
    console.error("Error fetching teacher subject:", e);
  }
  return "المادة";
}

/**
 * إرسال إشعار لولي الأمر.
 * @param {object} studentData
 * @param {object} payload
 * @param {string} context
 * @param {string} studentId
 */
async function sendNotificationToParent(studentData, payload, context, studentId) {
  const parentUserId = studentData.parentUserId;
  const parentPhoneNumber = studentData.parentPhoneNumber;
  let parentUserDoc;

  // 1. البحث باستخدام parentUserId
  if (parentUserId) {
    try {
      const doc = await admin.firestore().collection("users").doc(parentUserId).get();
      if (doc.exists) parentUserDoc = doc;
    } catch (error) {
      console.error(`${context}: Error fetching parent by ID:`, error);
    }
  }

  // 2. البحث باستخدام رقم الهاتف
  if (!parentUserDoc && parentPhoneNumber) {
    try {
      const q = await admin.firestore().collection("users")
          .where("phoneNumber", "==", parentPhoneNumber).limit(1).get();
      if (!q.empty) parentUserDoc = q.docs[0];
    } catch (error) {
      console.error(`${context}: Error querying parent by phone:`, error);
    }
  }

  if (!parentUserDoc) {
    console.log(`${context}: Could not find parent for student ${studentId}`);
    return;
  }

  const fcmToken = parentUserDoc.data().fcmToken;
  if (fcmToken) {
    const message = {
      notification: payload.notification,
      data: payload.data,
      token: fcmToken,
    };
    try {
      await admin.messaging().send(message);
      console.log(`${context}: Notification sent.`);
    } catch (error) {
      console.error(`${context}: Failed sending notification:`, error);
    }
  }
}

// ===================================================================
// (الجزء الثاني: دوال الإشعارات التلقائية - Triggers)
// ===================================================================

// 1. إشعار الغياب
exports.notifyOnAbsence = onDocumentWritten(
    "teachers/{teacherId}/groups/{groupId}/dailyAttendance/{date}",
    async (event) => {
      const teacherId = event.params.teacherId;
      const groupId = event.params.groupId;
      const snap = event.data.after;

      if (!snap || !snap.exists) return;

      const attendanceData = snap.data();
      const records = attendanceData.records || [];
      const subjectName = await getTeacherSubject(teacherId);

      // eslint-disable-next-line no-restricted-syntax
      for (const record of records) {
        if (record.status === "absent") {
          const studentId = record.studentId;
          // eslint-disable-next-line no-await-in-loop
          const sDoc = await admin.firestore().doc(`teachers/${teacherId}/groups/${groupId}/students/${studentId}`).get();

          if (sDoc.exists) {
            const sData = sDoc.data();
            const payload = {
              notification: {
                title: "تنبيه غياب",
                body: `تم تسجيل غياب الطالب ${sData.name} اليوم في مادة ${subjectName}.`,
              },
              data: {"screen": "attendance", "studentId": studentId},
            };
            // eslint-disable-next-line no-await-in-loop
            await sendNotificationToParent(sData, payload, "notifyOnAbsence", studentId);
          }
        }
      }
    });

// 2. إشعار الدرجات وعدم التسليم
exports.notifyOnNewGrades = onDocumentWritten(
    "teachers/{teacherId}/groups/{groupId}/assignments/{assignmentId}",
    async (event) => {
      const teacherId = event.params.teacherId;
      const groupId = event.params.groupId;
      const assignmentId = event.params.assignmentId;

      const snapAfter = event.data.after;
      // إذا تم حذف المستند، لا تفعل شيئاً
      if (!snapAfter || !snapAfter.exists) return;

      const afterData = snapAfter.data();
      const assignmentName = afterData.name || "واجب/امتحان";
      const scoresAfter = afterData.scores || {};
      const subjectName = await getTeacherSubject(teacherId);

      // حلقة تكرارية لكل الطلاب في قائمة الدرجات
      for (const studentId in scoresAfter) {
        if (Object.prototype.hasOwnProperty.call(scoresAfter, studentId)) {
          const scoreData = scoresAfter[studentId];

          if (scoreData) {
            // جلب بيانات الطالب
            // eslint-disable-next-line no-await-in-loop
            const sDoc = await admin.firestore().doc(`teachers/${teacherId}/groups/${groupId}/students/${studentId}`).get();

            if (sDoc.exists) {
              const sData = sDoc.data();

              // التحقق من وجود درجة (سواء كانت رقم أو نص)
              const hasScore = scoreData.score !== "" && scoreData.score != null;

              // التحقق من حالة التسليم:
              // 1. إذا كان submitted = true (النظام القديم)
              // 2. أو إذا كان submitted غير موجود أصلاً لكن توجد درجة (النظام الجديد للامتحانات)
              const isSubmitted = scoreData.submitted === true || (scoreData.submitted === undefined && hasScore);

              // الحالة الأولى: لم يتم التسليم صراحة (غياب عن الواجب)
              if (scoreData.submitted === false) {
                const payload = {
                  notification: {
                    title: "لم يتم تسليم الواجب",
                    body: `نود إعلامكم بأن الطالب ${sData.name} لم يقم بتسليم واجب "${assignmentName}" في مادة ${subjectName}.`,
                  },
                  data: {"screen": "grades", "assignmentId": assignmentId},
                };
                // eslint-disable-next-line no-await-in-loop
                await sendNotificationToParent(sData, payload, "notifyMissingHomework", studentId);

              // الحالة الثانية: تم رصد درجة (سواء امتحان جديد أو واجب قديم)
              } else if (isSubmitted && hasScore) {
                const payload = {
                  notification: {
                    title: "تم رصد درجة جديدة",
                    body: `حصل الطالب ${sData.name} على ${scoreData.score} في "${assignmentName}" لمادة ${subjectName}.`,
                  },
                  data: {"screen": "grades", "assignmentId": assignmentId},
                };
                // eslint-disable-next-line no-await-in-loop
                await sendNotificationToParent(sData, payload, "notifyOnNewGrades", studentId);
              }
            }
          }
        }
      }
    });

// ===================================================================
// (الجزء الثالث: المهام المجدولة - تتطلب Blaze Plan)
// ===================================================================

// 3. تذكير بمواعيد الدروس (قبل ساعتين)
exports.classReminder = onSchedule({
  schedule: "0 * * * *",
  timeZone: "Africa/Cairo",
}, async (event) => {
  const now = new Date();
  const targetTime = new Date(now.getTime() + 2 * 60 * 60 * 1000); // +2 hours
  const currentHour = targetTime.getHours();
  // تعديل: استخدام getDay() مباشرة (0=الأحد) ليتوافق مع قاعدة البيانات
  const dayIndex = targetTime.getDay();

  console.log(`Checking classes for Day Index: ${dayIndex}, Around Hour: ${currentHour}`);

  const teachersSnap = await admin.firestore().collection("teachers").get();

  // eslint-disable-next-line no-restricted-syntax
  for (const teacherDoc of teachersSnap.docs) {
    // eslint-disable-next-line no-await-in-loop
    const groupsSnap = await teacherDoc.ref.collection("groups").get();

    // eslint-disable-next-line no-restricted-syntax
    for (const groupDoc of groupsSnap.docs) {
      // eslint-disable-next-line no-await-in-loop
      const schedulesSnap = await groupDoc.ref.collection("recurringSchedules").get();

      // eslint-disable-next-line no-restricted-syntax
      for (const schedDoc of schedulesSnap.docs) {
        const sched = schedDoc.data();
        if (sched.days && sched.days.includes(dayIndex)) {
          const [schedHourStr] = sched.time.split(":");
          const schedHour = parseInt(schedHourStr, 10);

          if (schedHour === currentHour) {
            // eslint-disable-next-line no-await-in-loop
            const subjectName = await getTeacherSubject(teacherDoc.id);
            // eslint-disable-next-line no-await-in-loop
            const studentsSnap = await groupDoc.ref.collection("students").get();

            // eslint-disable-next-line no-restricted-syntax
            for (const studentDoc of studentsSnap.docs) {
              const studentData = studentDoc.data();
              const payload = {
                notification: {
                  title: "تذكير بموعد الدرس",
                  body: `تذكير: موعد درس ${subjectName} للطالب ${studentData.name} يبدأ بعد ساعتين (الساعة ${formatTime12Hour(sched.time)}).`,
                },
                data: {"screen": "schedule"},
              };
              // eslint-disable-next-line no-await-in-loop
              await sendNotificationToParent(studentData, payload, "classReminder", studentDoc.id);
            }
          }
        }
      }
    }
  }
});

// 4. تذكير بدفع المصروفات (يوم 6 من كل شهر)
exports.paymentReminder = onSchedule({
  schedule: "0 14 6 * *",
  timeZone: "Africa/Cairo",
}, async (event) => {
  const today = new Date();
  const currentMonth = today.toISOString().slice(0, 7);

  console.log(`Running Payment Reminder for month: ${currentMonth}`);

  const teachersSnap = await admin.firestore().collection("teachers").get();

  // eslint-disable-next-line no-restricted-syntax
  for (const teacherDoc of teachersSnap.docs) {
    // eslint-disable-next-line no-await-in-loop
    const subjectName = await getTeacherSubject(teacherDoc.id);
    // eslint-disable-next-line no-await-in-loop
    const groupsSnap = await teacherDoc.ref.collection("groups").get();

    // eslint-disable-next-line no-restricted-syntax
    for (const groupDoc of groupsSnap.docs) {
      // eslint-disable-next-line no-await-in-loop
      const studentsSnap = await groupDoc.ref.collection("students").get();
      if (studentsSnap.empty) continue;

      // eslint-disable-next-line no-await-in-loop
      const paymentDoc = await groupDoc.ref.collection("payments").doc(currentMonth).get();
      let paidStudentIds = [];

      if (paymentDoc.exists) {
        const records = paymentDoc.data().records || [];
        paidStudentIds = records.filter((r) => r.paid === true).map((r) => r.studentId);
      }

      // eslint-disable-next-line no-restricted-syntax
      for (const studentDoc of studentsSnap.docs) {
        if (!paidStudentIds.includes(studentDoc.id)) {
          const studentData = studentDoc.data();
          const payload = {
            notification: {
              title: "تذكير بدفع المصروفات",
              body: `تذكير بسداد مصروفات شهر ${currentMonth} لمادة ${subjectName} للطالب ${studentData.name}.`,
            },
            data: {"screen": "payments"},
          };
          // eslint-disable-next-line no-await-in-loop
          await sendNotificationToParent(studentData, payload, "paymentReminder", studentDoc.id);
        }
      }
    }
  }
});

// ===================================================================
// (الجزء الرابع: دوال لوحة التحكم والتطبيق)
// ===================================================================

/**
 * تنسيق التاريخ.
 * @param {Date} date
 * @return {string}
 */
function formatDate(date) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

/**
 * جلب رقم اليوم (0 للأحد)
 * @param {Date} date
 * @return {number}
 */
function getDayDart(date) {
  return date.getDay();
}

/**
 * تنسيق الوقت لـ 12 ساعة
 * @param {string} timeString
 * @return {string}
 */
function formatTime12Hour(timeString) {
  if (!timeString) return "";
  const [h, m] = timeString.split(":");
  const hour = parseInt(h);
  const suffix = hour >= 12 ? "PM" : "AM";
  const formattedHour = ((hour + 11) % 12 + 1);
  return `${formattedHour}:${m} ${suffix}`;
}

// دالة جلب البيانات للوحة التحكم
exports.getDashboardData = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be logged in.");
  }

  const parentUid = request.auth.uid;
  let studentNameForDashboard = "Student";
  const reportsMap = new Map();

  try {
    const parentUserDoc = await admin.firestore().collection("users").doc(parentUid).get();
    if (!parentUserDoc.exists || !parentUserDoc.data().phoneNumber) {
      throw new HttpsError("not-found", "Parent user phone number not found.");
    }
    const parentPhoneNumber = parentUserDoc.data().phoneNumber;

    const studentsSnapshot = await admin.firestore()
        .collectionGroup("students")
        .where("parentPhoneNumber", "==", parentPhoneNumber)
        .get();

    if (studentsSnapshot.empty) {
      return {studentName: studentNameForDashboard, reportsByTeacher: []};
    }

    studentNameForDashboard = studentsSnapshot.docs[0].data().name || studentNameForDashboard;

    // eslint-disable-next-line no-restricted-syntax
    for (const studentDoc of studentsSnapshot.docs) {
      const path = (studentDoc && studentDoc.ref) ? studentDoc.ref.path : null;
      if (!path) continue;

      const pathSegments = path.split("/");
      if (pathSegments.length < 6 || pathSegments[4] !== "students") continue;

      const studentId = studentDoc.id;
      const studentData = studentDoc.data();
      if (!studentData) continue;

      const studentName = studentData.name || "N/A";

      if (studentData.parentUserId !== parentUid) {
        try {
          // eslint-disable-next-line no-await-in-loop
          await studentDoc.ref.set({parentUserId: parentUid}, {merge: true});
        } catch (linkError) {
          console.error(`Failed to link student ${studentId}:`, linkError);
        }
      }

      const teacherId = pathSegments[1];
      const groupId = pathSegments[3];
      if (!teacherId || !groupId) continue;

      if (!reportsMap.has(teacherId)) {
        try {
          // eslint-disable-next-line no-await-in-loop
          const teacherDoc = await admin.firestore().collection("teachers").doc(teacherId).get();
          const teacherData = teacherDoc.data() || {};
          reportsMap.set(teacherId, {
            teacherId: teacherId,
            teacherName: teacherData.name || "Unknown Teacher",
            subject: teacherData.subject || "General",
            attendance: [],
            grades: [],
            schedule: [],
          });
        } catch (teacherError) {
          console.error(`Failed to fetch teacher ${teacherId}:`, teacherError);
        }
      }

      const teacherReport = reportsMap.get(teacherId);
      const groupRef = admin.firestore().collection("teachers").doc(teacherId).collection("groups").doc(groupId);

      // --- الجدول ---
      try {
        // eslint-disable-next-line no-await-in-loop
        const schedulesSnap = await groupRef.collection("recurringSchedules").get();
        // eslint-disable-next-line no-await-in-loop
        const exceptionsSnap = await groupRef.collection("scheduleExceptions").get();
        const today = new Date();
        const todayString = formatDate(today);
        const currentDayDart = getDayDart(today);
        const finalSchedule = [];

        for (const doc of schedulesSnap.docs) {
          const data = doc.data();
          const days = data.days || [];
          if (days.length === 0) continue;

          let isClassToday = false;
          if (typeof days[0] === "number") {
            if (days.includes(currentDayDart)) isClassToday = true;
          }

          if (isClassToday && data.time) {
            finalSchedule.push({...data, date: todayString, id: doc.id});
          }
        }

        for (const doc of exceptionsSnap.docs) {
          const data = doc.data();
          if (data.date === todayString) {
            if (data.status === "cancelled") {
              finalSchedule.length = 0;
              break;
            } else if (data.status === "rescheduled" && finalSchedule.length > 0 && data.newTime) {
              finalSchedule[0].time = data.newTime;
            }
          }
        }
        teacherReport.schedule.push(...finalSchedule);
      } catch (e) {
        console.error("Error fetching schedule:", e);
      }

      // --- الحضور ---
      try {
        // eslint-disable-next-line no-await-in-loop
        const attSnap = await groupRef.collection("dailyAttendance").get();
        attSnap.forEach((doc) => {
          const data = doc.data();
          const records = (data.records || []).filter((r) => r.studentId === studentId);
          records.forEach((record) => {
            teacherReport.attendance.push({
              studentName: studentName,
              date: data.date || "N/A",
              status: record.status || "unknown",
            });
          });
        });
      } catch (e) {
        console.error("Error fetching attendance:", e);
      }

      // --- الدرجات ---
      try {
        // eslint-disable-next-line no-await-in-loop
        const assSnap = await groupRef.collection("assignments").get();
        assSnap.forEach((doc) => {
          const data = doc.data();
          const scoreData = data.scores ? data.scores[studentId] : null;
          if (scoreData) {
            teacherReport.grades.push({
              studentName: studentName,
              assignmentName: data.name || "N/A",
              score: scoreData.score,
              date: data.date || "N/A",
              submitted: scoreData.submitted || false,
            });
          }
        });
      } catch (e) {
        console.error("Error fetching grades:", e);
      }
    }

    const finalReports = Array.from(reportsMap.values());
    return {
      studentName: studentNameForDashboard,
      reportsByTeacher: finalReports,
    };
  } catch (error) {
    console.error("Fatal Error in getDashboardData function:", error);
    throw new HttpsError("internal", "An internal error occurred.", error.message);
  }
});

// دالة التحقق من وجود ولي الأمر
exports.checkParentExists = onCall(async (request) => {
  const parentPhoneNumber = request.data.phoneNumber;
  if (!parentPhoneNumber) {
    throw new HttpsError("invalid-argument", "The function must be called with a 'phoneNumber' argument.");
  }

  try {
    const studentsSnapshot = await admin.firestore()
        .collectionGroup("students")
        .where("parentPhoneNumber", "==", parentPhoneNumber)
        .limit(1)
        .get();

    return {exists: !studentsSnapshot.empty};
  } catch (error) {
    console.error("Error in checkParentExists function:", error);
    throw new HttpsError("internal", "An internal error occurred.", error.message);
  }
});

// 5. إشعار عند دفع المصروفات (جديد)
exports.notifyOnPayment = onDocumentWritten(
    "teachers/{teacherId}/groups/{groupId}/payments/{month}",
    async (event) => {
      const teacherId = event.params.teacherId;
      const groupId = event.params.groupId;
      const month = event.params.month;

      const snapAfter = event.data.after;
      const snapBefore = event.data.before;

      if (!snapAfter || !snapAfter.exists) return;

      const afterData = snapAfter.data();
      const beforeData = snapBefore.exists ? snapBefore.data() : {records: []};

      const afterRecords = afterData.records || [];
      const beforeRecords = beforeData.records || [];

      // خريطة لمعرفة حالة الدفع السابقة
      const beforeStatusMap = {};
      beforeRecords.forEach((r) => {
        beforeStatusMap[r.studentId] = r.paid;
      });

      // جلب بيانات المدرس
      let teacherName = "المستر";
      let subjectName = "المادة";

      try {
        const teacherDoc = await admin.firestore().collection("teachers").doc(teacherId).get();
        if (teacherDoc.exists) {
          const tData = teacherDoc.data();
          teacherName = tData.name || "المستر";
          subjectName = tData.subject || "المادة";
        }
      } catch (e) {
        console.error("Error fetching teacher info:", e);
      }

      // البحث عن الطلاب
      // eslint-disable-next-line no-restricted-syntax
      for (const record of afterRecords) {
        const isNowPaid = record.amount > 0;
        const wasPaid = beforeStatusMap[record.studentId] === true;
        const amountPaid = record.amount || 0;

        if (isNowPaid && !wasPaid) {
          const studentId = record.studentId;

          // eslint-disable-next-line no-await-in-loop
          const sDoc = await admin.firestore().doc(`teachers/${teacherId}/groups/${groupId}/students/${studentId}`).get();

          if (sDoc.exists) {
            const sData = sDoc.data();
            const payload = {
              notification: {
                title: "تأكيد سداد المصروفات",
                // تم إضافة ${teacherName} هنا لإصلاح الخطأ
                body: `تم استلام مبلغ ${amountPaid} جنيه مصاريف شهر ${month} لمادة ${subjectName} مع ${teacherName} للطالب ${sData.name}. شكراً لكم.`,
              },
              data: {"screen": "payments", "month": month},
            };

            // eslint-disable-next-line no-await-in-loop
            await sendNotificationToParent(sData, payload, "notifyOnPayment", studentId);
          }
        }
      }
    });


// أضف هذا الكود في نهاية ملف index.js

exports.sendCustomMessage = onCall(async (request) => {
  const {teacherId, groupId, studentId, messageBody} = request.data;

  try {
    // جلب بيانات الطالب
    const studentDoc = await admin.firestore().doc(`teachers/${teacherId}/groups/${groupId}/students/${studentId}`).get();

    if (!studentDoc.exists) throw new HttpsError("not-found", "الطالب غير موجود");

    const studentData = studentDoc.data();
    const subjectName = await getTeacherSubject(teacherId);

    // تجهيز الإشعار
    const payload = {
      notification: {
        title: `رسالة من مدرس ${subjectName}`,
        body: messageBody,
      },
      data: {screen: "profile", studentId: studentId},
    };

    // الإرسال باستخدام الدالة المساعدة الموجودة في ملفك
    await sendNotificationToParent(studentData, payload, "sendCustomMessage", studentId);

    return {success: true};
  } catch (error) {
    console.error("Error sending custom message:", error);
    throw new HttpsError("internal", error.message);
  }
});
