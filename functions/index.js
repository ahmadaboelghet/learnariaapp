//
// functions/index.js (النسخة النهائية الصحيحة والمُنسّقة حسب ESLint)
//
/* eslint-disable max-len */ // تعطيل مؤقت لبعض القواعد لتسهيل القراءة
const {onDocumentWritten} = require("firebase-functions/v2/firestore");
// const {onSchedule} = require("firebase-functions/v2/scheduler"); // معطل حالياً
const admin = require("firebase-admin");

admin.initializeApp();

// --- مساعدة: دالة لإرسال الإشعار مع معالجة الأخطاء ---
/**
 * Sends a notification payload to a specific FCM token.
 * @param {string} fcmToken The target device token.
 * @param {object} payload The notification payload.
 * @param {string} context Function context for logging (e.g., "notifyOnAbsence").
 * @param {string} parentUserId Parent ID for logging.
 * @param {string} studentId Student ID for logging.
 * @return {Promise<void>}
 */
async function sendNotification(fcmToken, payload, context, parentUserId, studentId) {
  console.log(`${context} (Attempt): Sending notification to parent ${parentUserId} for student ${studentId}`);
  try {
    await admin.messaging().sendToDevice(fcmToken, payload);
    console.log(`${context} (Success ✅): Notification sent successfully.`);
  } catch (error) {
    console.error(`${context} (Error ❌): Failed sending notification to token ${fcmToken}:`, error);
    // يمكنك إضافة منطق لحذف التوكن غير الصالح من Firestore هنا
    // if (error.code === 'messaging/registration-token-not-registered') { ... }
  }
}

// --- 1. إشعار عند تسجيل غياب الطالب ---
exports.notifyOnAbsence = onDocumentWritten(
    "teachers/{teacherId}/groups/{groupId}/dailyAttendance/{date}",
    async (event) => {
      const functionContext = "notifyOnAbsence";
      const teacherId = event.params.teacherId;
      const groupId = event.params.groupId;
      const date = event.params.date;
      console.log(`${functionContext}: Triggered for teachers/${teacherId}/groups/${groupId}/dailyAttendance/${date}`);

      const snap = event.data.after;
      if (!snap || !snap.exists) {
        console.log(`${functionContext}: Document deleted or does not exist.`);
        return;
      }

      const attendanceData = snap.data();
      const records = Array.isArray(attendanceData.records) ? attendanceData.records : [];
      if (records.length === 0) {
        console.log(`${functionContext}: No records found in the document.`);
        return;
      }

      for (const record of records) {
        if (!record || !record.studentId) {
          console.log(`${functionContext}: Skipping record without studentId:`, record);
          continue;
        }

        if (record.status === "absent") {
          const studentId = record.studentId;
          const studentDocPath = `teachers/${teacherId}/groups/${groupId}/students/${studentId}`;
          let studentDoc;

          try {
            studentDoc = await admin.firestore().doc(studentDocPath).get();
          } catch (error) {
            console.error(`${functionContext}: Error fetching student ${studentId}:`, error);
            continue;
          }

          if (!studentDoc.exists) {
            console.log(`${functionContext}: Student ${studentId} not found at path ${studentDocPath}.`);
            continue;
          }

          const studentData = studentDoc.data();
          const parentUserId = studentData.parentUserId;

          if (!parentUserId) {
            console.log(`${functionContext} (Error ❌): 'parentUserId' field not found for student ${studentId}. Skipping.`);
            continue;
          }

          let parentUserDoc;
          try {
            parentUserDoc = await admin.firestore().collection("users").doc(parentUserId).get();
          } catch (error) {
            console.error(`${functionContext}: Error fetching parent user ${parentUserId}:`, error);
            continue;
          }

          if (parentUserDoc.exists) {
            const parentData = parentUserDoc.data();
            const fcmToken = parentData.fcmToken;

            if (fcmToken) {
              const studentName = studentData.name || "طالب";
              const payload = {
                notification: {
                  title: "غياب الطالب",
                  body: `تم تسجيل ابنك/ابنتك ${studentName} كـ "غائب" اليوم.`,
                },
                data: {"screen": "attendance", "studentId": studentId}, // مثال لإضافة بيانات
              };
              await sendNotification(fcmToken, payload, functionContext, parentUserId, studentId);
            } else {
              console.log(`${functionContext} (Error ❌): FCM token not found for parent ${parentUserId} in /users/${parentUserId}`);
            }
          } else {
            console.log(`${functionContext} (Error ❌): Parent user document not found in /users/${parentUserId}`);
          }
        } // end if absent
      } // end for loop
    });

// --- 2. إشعار عند إضافة درجات جديدة ---
exports.notifyOnNewGrades = onDocumentWritten(
    "teachers/{teacherId}/groups/{groupId}/assignments/{assignmentId}",
    async (event) => {
      const functionContext = "notifyOnNewGrades";
      const teacherId = event.params.teacherId;
      const groupId = event.params.groupId;
      const assignmentId = event.params.assignmentId;
      console.log(`${functionContext}: Triggered for teachers/${teacherId}/groups/${groupId}/assignments/${assignmentId}`);

      const snapAfter = event.data.after;
      if (!snapAfter || !snapAfter.exists) {
        console.log(`${functionContext}: Document deleted or does not exist.`);
        return;
      }

      const beforeData = event.data.before ? event.data.before.data() : {};
      const afterData = snapAfter.data();

      const assignmentName = afterData.name || "واجب";
      const scoresAfter = afterData.scores || {};
      const scoresBefore = beforeData.scores || {};


      // المرور على كل طالب له درجة في المستند الجديد
      for (const studentId in scoresAfter) {
        // التأكد من أن المفتاح هو ملك للكائن نفسه وليس للـ prototype
        if (Object.prototype.hasOwnProperty.call(scoresAfter, studentId)) {
          const scoreDataAfter = scoresAfter[studentId];
          // التأكد من أن بيانات الدرجة هي object
          if (typeof scoreDataAfter !== "object" || scoreDataAfter === null) {
            continue;
          }

          const scoreDataBefore = scoresBefore[studentId] || {}; // بيانات الدرجة السابقة (أو فارغة)
          const currentScore = scoreDataAfter.score;

          // إرسال إشعار فقط إذا تمت إضافة درجة لأول مرة، أو تم تغييرها، ولم تكن فارغة
          const shouldNotify = currentScore != null &&
                               currentScore !== "" &&
                               currentScore !== scoreDataBefore.score;

          if (shouldNotify) {
            const studentDocPath = `teachers/${teacherId}/groups/${groupId}/students/${studentId}`;
            let studentDoc;
            try {
              studentDoc = await admin.firestore().doc(studentDocPath).get();
            } catch (error) {
              console.error(`${functionContext}: Error fetching student ${studentId}:`, error);
              continue;
            }

            if (!studentDoc.exists) {
              console.log(`${functionContext}: Student ${studentId} not found at path ${studentDocPath}.`);
              continue;
            }

            const studentData = studentDoc.data();
            const parentUserId = studentData.parentUserId;

            if (!parentUserId) {
              console.log(`${functionContext} (Error ❌): 'parentUserId' field not found for student ${studentId}. Skipping.`);
              continue;
            }

            let parentUserDoc;
            try {
              parentUserDoc = await admin.firestore().collection("users").doc(parentUserId).get();
            } catch (error) {
              console.error(`${functionContext}: Error fetching parent user ${parentUserId}:`, error);
              continue;
            }

            if (parentUserDoc.exists) {
              const parentData = parentUserDoc.data();
              const fcmToken = parentData.fcmToken;

              if (fcmToken) {
                const studentName = studentData.name || "طالب";
                const payload = {
                  notification: {
                    title: "تم إضافة درجة جديدة",
                    body: `تم إضافة درجة "${assignmentName}" لابنك/ابنتك ${studentName}.`,
                  },
                  data: {"screen": "grades", "assignmentId": assignmentId},
                };
                await sendNotification(fcmToken, payload, functionContext, parentUserId, studentId);
              } else {
                console.log(`${functionContext} (Error ❌): FCM token not found for parent ${parentUserId} in /users/${parentUserId}`);
              }
            } else {
              console.log(`${functionContext} (Error ❌): Parent user document not found in /users/${parentUserId}`);
            }
          } // end if shouldNotify
        } // end hasOwnProperty check
      } // end for loop studentId
    });

// --- الدوال المجدولة (إذا كنت تستخدمها) ---
/*
exports.lessonReminder = onSchedule("every 30 minutes", async (event) => {
    // ... logic ...
});

exports.homeworkNotSubmitted = onSchedule("every day 09:00", async (event) => {
    // ... logic ...
});
*/
