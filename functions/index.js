//
// functions/index.js (النسخة النهائية - تستخدم v1 API .send())
//
/* eslint-disable max-len */
const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * دالة مساعدة للبحث عن ولي الأمر بالإيميل وإرسال الإشعار
 * @param {string} parentPhoneNumber رقم هاتف ولي الأمر (e.g., "+20100...")
 * @param {object} payload حمولة الإشعار (notification + data).
 * @param {string} context سياق الدالة (للـ logging).
 * @param {string} studentId هوية الطالب (للـ logging).
 * @return {Promise<void>}
 */
async function sendNotificationToParentByPhone(parentPhoneNumber, payload, context, studentId) {
  if (!parentPhoneNumber) {
    console.log(`${context} (Error ❌): Student ${studentId} has no 'parentPhoneNumber'. Skipping.`);
    return;
  }

  // 1. بناء الإيميل من رقم الهاتف
  const parentEmail = `${parentPhoneNumber}@learnaria.app`;

  let parentUserDoc;
  try {
    // 2. البحث في collection 'users' باستخدام الإيميل
    console.log(`${context} (Info): Searching for parent user with email: ${parentEmail}`);
    const userQuery = await admin.firestore().collection("users")
        .where("email", "==", parentEmail) // <-- [تم التغيير] البحث بالإيميل
        .limit(1)
        .get();

    if (userQuery.empty) {
      console.log(`${context} (Error ❌): Parent user not found with email ${parentEmail} for student ${studentId}.`);
      return;
    }

    parentUserDoc = userQuery.docs[0];
  } catch (error) {
    console.error(`${context}: Error querying parent user by email ${parentEmail}:`, error);
    return;
  }

  const parentData = parentUserDoc.data();
  const parentUserId = parentUserDoc.id;
  const fcmToken = parentData.fcmToken;

  if (fcmToken) {
    // --- [التغيير الرئيسي هنا] ---
    // 3. بناء الرسالة (v1 API)
    // الدالة الجديدة تتطلب أن يكون التوكن جزءًا من الرسالة نفسها
    const message = {
      notification: payload.notification,
      data: payload.data,
      token: fcmToken, // <-- التوكن يوضع هنا
    };

    // 4. إرسال الرسالة باستخدام .send()
    try {
      console.log(`${context} (Attempt): Sending v1 message to parent ${parentUserId} (token: ${fcmToken})`);

      // [تم التغيير] استخدام .send() بدلاً من .sendToDevice()
      await admin.messaging().send(message);

      console.log(`${context} (Success ✅): Notification sent successfully.`);
    } catch (error) {
      console.error(`${context} (Error ❌): Failed sending notification to token ${fcmToken}:`, error);
      // (هنا يمكنك إضافة منطق لحذف التوكن إذا كان غير صالح)
      // if (error.code === 'messaging/registration-token-not-registered') { ... }
    }
    // --- نهاية التغيير ---
  } else {
    console.log(`${context} (Error ❌): FCM token not found for parent ${parentUserId} (email ${parentEmail}).`);
  }
}


// --- 1. إشعار عند تسجيل غياب الطالب ---
// (هذه الدالة لا تحتاج أي تغيير، لأنها تستدعي الدالة المساعدة)
exports.notifyOnAbsence = onDocumentWritten(
    "teachers/{teacherId}/groups/{groupId}/dailyAttendance/{date}",
    async (event) => {
      const functionContext = "notifyOnAbsence";
      const teacherId = event.params.teacherId;
      const groupId = event.params.groupId;
      console.log(`${functionContext}: Triggered for teachers/${teacherId}/groups/${groupId}/dailyAttendance/{date}`);

      const snap = event.data.after;
      if (!snap || !snap.exists) return;

      const attendanceData = snap.data();
      const records = Array.isArray(attendanceData.records) ? attendanceData.records : [];

      for (const record of records) {
        if (!record || !record.studentId || record.status !== "absent") {
          continue;
        }

        const studentId = record.studentId;
        let studentDoc;
        try {
          studentDoc = await admin.firestore().doc(`teachers/${teacherId}/groups/${groupId}/students/${studentId}`).get();
        } catch (error) {
          console.error(`${functionContext}: Error fetching student ${studentId}:`, error);
          continue;
        }

        if (!studentDoc.exists) {
          console.log(`${functionContext}: Student ${studentId} not found.`);
          continue;
        }

        const studentData = studentDoc.data();
        const parentPhoneNumber = studentData.parentPhoneNumber;
        const studentName = studentData.name || "طالب";

        const payload = {
          notification: {
            title: "غياب الطالب",
            body: `تم تسجيل ابنك/ابنتك ${studentName} كـ "غائب" اليوم.`,
          },
          data: {"screen": "attendance", "studentId": studentId},
        };

        await sendNotificationToParentByPhone(parentPhoneNumber, payload, functionContext, studentId);
      }
    });

// --- 2. إشعار عند إضافة درجات جديدة ---
// (هذه الدالة لا تحتاج أي تغيير، لأنها تستدعي الدالة المساعدة)
exports.notifyOnNewGrades = onDocumentWritten(
    "teachers/{teacherId}/groups/{groupId}/assignments/{assignmentId}",
    async (event) => {
      const functionContext = "notifyOnNewGrades";
      const teacherId = event.params.teacherId;
      const groupId = event.params.groupId;
      const assignmentId = event.params.assignmentId;
      console.log(`${functionContext}: Triggered for teachers/${teacherId}/groups/${groupId}/assignments/${assignmentId}`);

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

          if (!studentDoc.exists) {
            console.log(`${functionContext}: Student ${studentId} not found.`);
            continue;
          }

          const studentData = studentDoc.data();
          const parentPhoneNumber = studentData.parentPhoneNumber;
          const studentName = studentData.name || "طالب";

          const payload = {
            notification: {
              title: "تم إضافة درجة جديدة",
              body: `تم إضافة درجة "${assignmentName}" لابنك/ابنتك ${studentName}.`,
            },
            data: {"screen": "grades", "assignmentId": assignmentId},
          };

          await sendNotificationToParentByPhone(parentPhoneNumber, payload, functionContext, studentId);
        }
      }
    });
