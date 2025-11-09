//
// functions/index.js (النسخة الكاملة: إشعارات + دالة جلب البيانات)
// (تم إصلاح فلتر 'path' + أخطاء LINT)
//
/* eslint-disable max-len */
const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

// ===================================================================
// (الجزء الأول: الدوال المساعدة للإشعارات)
// ===================================================================

/**
 * دالة مساعدة لإرسال الإشعار لولي الأمر
 * @param {object} studentData بيانات الطالب
 * @param {object} payload حمولة الإشعار
 * @param {string} functionContext سياق الدالة (للـ logging)
 * @param {string} studentId هوية الطالب (للـ logging)
 * @return {Promise<void>}
 */
async function sendNotificationToParent(studentData, payload, functionContext, studentId) {
  const parentUserId = studentData.parentUserId;
  const parentPhoneNumber = studentData.parentPhoneNumber;
  let parentUserDoc;

  // 1. الأولوية للبحث بـ parentUserId
  if (parentUserId) {
    console.log(`${functionContext} (Info): Found parentUserId ${parentUserId} for student ${studentId}. Fetching directly.`);
    try {
      const doc = await admin.firestore().collection("users").doc(parentUserId).get();
      if (doc.exists) {
        parentUserDoc = doc;
      }
    } catch (error) {
      console.error(`${functionContext}: Error fetching parent by ID ${parentUserId}:`, error);
    }
  }

  // 2. خطة بديلة: البحث برقم الهاتف
  if (!parentUserDoc && parentPhoneNumber) {
    console.log(`${functionContext} (Fallback): parentUserId not found. Searching by phone ${parentPhoneNumber}.`);

    // أولاً: نجرب البحث برقم الهاتف الحقيقي
    try {
      console.log(`${functionContext} (Fallback): Searching by REAL phone number: ${parentPhoneNumber}`);
      const userQuery = await admin.firestore().collection("users")
          .where("phoneNumber", "==", parentPhoneNumber)
          .limit(1)
          .get();
      if (!userQuery.empty) {
        parentUserDoc = userQuery.docs[0];
      }
    } catch (error) {
      console.error(`${functionContext}: Error querying parent by phone ${parentPhoneNumber}:`, error);
    }

    // ثانيًا: إذا فشل، نجرب حيلة الإيميل (للمستخدمين القدامى)
    if (!parentUserDoc) {
      const parentEmail = `${parentPhoneNumber}@learnaria.com`;
      console.log(`${functionContext} (Fallback): Searching by email hack: ${parentEmail}`);
      try {
        const userQuery = await admin.firestore().collection("users")
            .where("email", "==", parentEmail)
            .limit(1)
            .get();
        if (!userQuery.empty) {
          parentUserDoc = userQuery.docs[0];
        }
      } catch (error) {
        console.error(`${functionContext}: Error querying parent by email ${parentEmail}:`, error);
      }
    }
  }

  if (!parentUserDoc) {
    console.log(`${functionContext} (Error ❌): Could not find parent user for student ${studentId} (ID: ${parentUserId}, Phone: ${parentPhoneNumber}).`);
    return;
  }

  // 3. إرسال الإشعار
  const parentData = parentUserDoc.data();
  const fcmToken = parentData.fcmToken;

  if (fcmToken) {
    const message = {
      notification: payload.notification,
      data: payload.data,
      token: fcmToken,
    };
    try {
      console.log(`${functionContext} (Attempt): Sending v1 message to parent ${parentUserDoc.id}`);
      await admin.messaging().send(message);
      console.log(`${functionContext} (Success ✅): Notification sent successfully.`);
    } catch (error) {
      console.error(`${functionContext} (Error ❌): Failed sending notification to token ${fcmToken}:`, error);
    }
  } else {
    console.log(`${functionContext} (Error ❌): FCM token not found for parent ${parentUserDoc.id}.`);
  }
}

// ===================================================================
// (الجزء الثاني: دوال الإشعارات - Triggers)
// ===================================================================

// --- 1. إشعار عند تسجيل غياب الطالب ---
exports.notifyOnAbsence = onDocumentWritten(
    "teachers/{teacherId}/groups/{groupId}/dailyAttendance/{date}",
    async (event) => {
      const functionContext = "notifyOnAbsence";
      const teacherId = event.params.teacherId;
      const groupId = event.params.groupId;

      const snap = event.data.after;
      if (!snap || !snap.exists) return;

      const attendanceData = snap.data();
      const records = Array.isArray(attendanceData.records) ? attendanceData.records : [];

      for (const record of records) {
        if (!record || !record.studentId || record.status !== "absent") continue;

        const studentId = record.studentId;
        let studentDoc;
        try {
          studentDoc = await admin.firestore().doc(`teachers/${teacherId}/groups/${groupId}/students/${studentId}`).get();
        } catch (error) {
          console.error(`${functionContext}: Error fetching student ${studentId}:`, error);
          continue;
        }

        if (!studentDoc.exists) continue;

        const studentData = studentDoc.data();
        const payload = {
          notification: {
            title: "غياب الطالب",
            body: `تم تسجيل ابنك/ابنتك ${studentData.name || "طالب"} كـ "غائب" اليوم.`,
          },
          data: {"screen": "attendance", "studentId": studentId},
        };

        await sendNotificationToParent(studentData, payload, functionContext, studentId);
      }
    });

// --- 2. إشعار عند إضافة درجات جديدة ---
exports.notifyOnNewGrades = onDocumentWritten(
    "teachers/{teacherId}/groups/{groupId}/assignments/{assignmentId}",
    async (event) => {
      const functionContext = "notifyOnNewGrades";
      const teacherId = event.params.teacherId;
      const groupId = event.params.groupId;
      const assignmentId = event.params.assignmentId;

      const snapAfter = event.data.after;
      if (!snapAfter || !snapAfter.exists) return;

      const beforeData = event.data.before ? event.data.before.data() : {};
      const afterData = snapAfter.data();
      const assignmentName = afterData.name || "واجب";
      const scoresAfter = afterData.scores || {};
      const scoresBefore = beforeData.scores || {};

      for (const studentId in scoresAfter) {
        if (!Object.prototype.hasOwnProperty.call(scoresAfter, studentId)) continue;

        const scoreDataAfter = scoresAfter[studentId] || {};
        const scoreDataBefore = scoresBefore[studentId] || {};
        const currentScore = scoreDataAfter.score;

        const shouldNotify = currentScore != null && currentScore !== "" && currentScore !== scoreDataBefore.score;

        if (shouldNotify) {
          let studentDoc;
          try {
            studentDoc = await admin.firestore().doc(`teachers/${teacherId}/groups/${groupId}/students/${studentId}`).get();
          } catch (error) {
            console.error(`${functionContext}: Error fetching student ${studentId}:`, error);
            continue;
          }

          if (!studentDoc.exists) continue;

          const studentData = studentDoc.data();
          const payload = {
            notification: {
              title: "تم إضافة درجة جديدة",
              body: `تم إضافة درجة "${assignmentName}" لابنك/ابنتك ${studentData.name || "طالب"}.`,
            },
            data: {"screen": "grades", "assignmentId": assignmentId},
          };

          await sendNotificationToParent(studentData, payload, functionContext, studentId);
        }
      }
    });

// ===================================================================
// (الجزء الثالث: دالة جلب البيانات للـ Home Screen - Callable)
// ===================================================================

// --- دوال مساعدة للوقت والتاريخ (مع إضافة JSDoc) ---

/**
 * Formats a Date object into "yyyy-MM-dd".
 * @param {Date} date The date to format.
 * @return {string} The formatted date string.
 */
function formatDate(date) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

/**
 * Gets the English day name (lowercase).
 * @param {Date} date The date.
 * @return {string} The day name.
 */
function getDayNameEn(date) {
  return date.toLocaleDateString("en-US", {weekday: "long"}).toLowerCase();
}
/**
 * Gets the Arabic day name (lowercase).
 * @param {Date} date The date.
 * @return {string} The day name.
 */
function getDayNameAr(date) {
  return date.toLocaleDateString("ar-SA", {weekday: "long"}).toLowerCase();
}
/**
 * Gets the Dart-compatible weekday (1-7).
 * @param {Date} date The date.
 * @return {number} The day number (1=Mon, 7=Sun).
 */
function getDayDart(date) {
  const day = date.getDay(); // الأحد = 0 ... السبت = 6
  return (day === 0) ? 7 : day; // الاثنين = 1 ... الأحد = 7
}
// --- نهاية الدوال المساعدة ---

exports.getDashboardData = onCall(async (request) => {
  // 1. التأكد أن المستخدم مسجل دخوله
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be logged in.");
  }

  const parentUid = request.auth.uid;
  let studentNameForDashboard = "Student";
  const reportsMap = new Map();

  try {
    // 2. جلب رقم هاتف ولي الأمر من /users/{uid}
    const parentUserDoc = await admin.firestore().collection("users").doc(parentUid).get();
    if (!parentUserDoc.exists || !parentUserDoc.data().phoneNumber) {
      throw new HttpsError("not-found", "Parent user phone number not found.");
    }
    const parentPhoneNumber = parentUserDoc.data().phoneNumber;
    console.log(`Fetching dashboard for UID: ${parentUid}, Phone: ${parentPhoneNumber}`);

    // 3. البحث عن الطلاب المرتبطين برقم الهاتف
    const studentsSnapshot = await admin.firestore()
        .collectionGroup("students")
        .where("parentPhoneNumber", "==", parentPhoneNumber)
        .get();

    if (studentsSnapshot.empty) {
      console.log(`No students found for phone: ${parentPhoneNumber}`);
      return {studentName: studentNameForDashboard, reportsByTeacher: []};
    }

    console.log(`Found ${studentsSnapshot.docs.length} students for phone: ${parentPhoneNumber}`);
    studentNameForDashboard = studentsSnapshot.docs[0].data().name || studentNameForDashboard;

    // 4. المرور على كل طالب وتجميع بياناته
    for (const studentDoc of studentsSnapshot.docs) {
      // --- [هذا هو الإصلاح] ---
      // الفلتر الحقيقي والمهم هو التأكد من المسار
      // هنتأكد إن المستند سليم وإن المسار هو المسار اللي إحنا عايزينه
      // (استخدمنا .ref بدلاً من .reference)
      if (!studentDoc || !studentDoc.ref || !studentDoc.ref.path) {
        console.warn(`Found an invalid/corrupt document (no ref or path), skipping.`);
        continue;
      }

      const pathSegments = studentDoc.ref.path.split("/");
      // المسار الصحيح هو: teachers/{id}/groups/{id}/students/{id} (6 أجزاء)
      if (pathSegments.length < 6 || pathSegments[4] !== "students") {
        console.warn(`Invalid path structure for student doc: ${studentDoc.ref.path}. Skipping.`);
        continue; // <-- ده هيعمل skip لأي مسار غلط (زي /users/id/students/id)
      }
      // --- [نهاية الإصلاح] ---

      const studentId = studentDoc.id;
      const studentData = studentDoc.data();

      // [إصلاح إضافي] نتأكد إن بيانات الطالب موجودة
      if (!studentData) {
        console.warn(`Student doc ${studentId} has no data. Skipping.`);
        continue;
      }

      const studentName = studentData.name || "N/A";

      // 5. ربط الطالب بـ parentUserId
      if (studentData.parentUserId !== parentUid) {
        try {
          await studentDoc.ref.set({parentUserId: parentUid}, {merge: true}); // (استخدمنا .ref)
          console.log(`Linked student ${studentId} to parent ${parentUid}`);
        } catch (linkError) {
          console.error(`Failed to link student ${studentId}:`, linkError);
        }
      }

      // 6. جلب المسارات والـ IDs
      // (تم نقلها فوق داخل الفلتر)
      const teacherId = pathSegments[1];
      const groupId = pathSegments[3];
      if (!teacherId || !groupId) continue;

      // 7. جلب بيانات المعلم (مرة واحدة فقط)
      if (!reportsMap.has(teacherId)) {
        try {
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
          reportsMap.set(teacherId, {
            teacherId: teacherId, teacherName: "Unknown Teacher", subject: "General",
            attendance: [], grades: [], schedule: [],
          });
        }
      }

      const teacherReport = reportsMap.get(teacherId);

      // 8. جلب بيانات الحصص (Attendance, Grades, Schedule)
      const groupRef = admin.firestore().collection("teachers").doc(teacherId).collection("groups").doc(groupId);

      // --- الجدول ---
      try {
        const schedulesSnap = await groupRef.collection("recurringSchedules").get();
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
          if (typeof days[0] === "string") {
            const dayNameEn = getDayNameEn(today);
            const dayNameAr = getDayNameAr(today);
            const daysLower = days.map((d) => d.toString().toLowerCase());
            if (daysLower.includes(dayNameEn) || daysLower.includes(dayNameAr)) isClassToday = true;
          } else if (typeof days[0] === "number") {
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
    } // نهاية لفة الطلاب

    // 9. تحويل الـ Map إلى Array وإرسال الرد
    const finalReports = Array.from(reportsMap.values());
    console.log(`Successfully fetched data for ${finalReports.length} teachers.`);
    return {
      studentName: studentNameForDashboard,
      reportsByTeacher: finalReports,
    };
  } catch (error) {
    console.error("Fatal Error in getDashboardData function:", error);
    throw new HttpsError("internal", "An internal error occurred.", error.message);
  }
});
