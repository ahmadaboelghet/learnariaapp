//
// functions/index.js
//

const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();

// --- 1. إشعار عند تسجيل غياب الطالب ---
exports.notifyOnAbsence = onDocumentWritten(
    "teachers/{teacherId}/groups/{groupId}/dailyAttendance/{date}",
    async (event) => {
      const path = event.data.after.ref.path;
      console.log(`Function notifyOnAbsence triggered for path: ${path}`);

      const snap = event.data.after;
      if (!snap || !snap.exists) {
        console.log("Document was deleted or does not exist.");
        return;
      }
      const attendanceData = snap.data();
      const records = attendanceData.records;
      const context = event.params;

      for (const record of records) {
        if (record.status === "absent") {
          const studentDocPath = `teachers/${context.teacherId}/groups/` +
                                     `${context.groupId}/students`;
          const studentDoc = await admin
              .firestore()
              .collection(studentDocPath)
              .doc(record.studentId)
              .get();

          if (!studentDoc.exists) {
            console.log(`Student with ID ${record.studentId} not found.`);
            continue;
          }
          const parentPhoneNumber = studentDoc.data().parentPhoneNumber;

          const parentQuery = await admin
              .firestore()
              .collectionGroup("students")
              .where("parentPhoneNumber", "==", parentPhoneNumber)
              .limit(1)
              .get();

          if (!parentQuery.empty) {
            const parentUserDoc = parentQuery.docs[0];
            const fcmToken = parentUserDoc.data().fcmToken;

            if (fcmToken) {
              const studentName = studentDoc.data().name;
              const payload = {
                notification: {
                  title: "غياب الطالب",
                  body: `تم تسجيل ابنك/ابنتك ${studentName} ` +
                                      `كـ "غائب" اليوم.`,
                },
              };
              const studentIdLog = studentDoc.id;
              const msg = `Sending 'absence' notification for student ` +
                                  `${studentIdLog}`;
              console.log(msg);
              await admin.messaging().sendToDevice(fcmToken, payload);
            } else {
              const studentIdLog = studentDoc.id;
              const msg = `FCM token not found for parent of ` +
                                  `student ${studentIdLog}`;
              console.log(msg);
            }
          }
        }
      }
    });

// --- 2. إشعار عند إضافة درجات جديدة ---
exports.notifyOnNewGrades = onDocumentWritten(
    "teachers/{teacherId}/groups/{groupId}/assignments/{assignmentId}",
    async (event) => {
      const path = event.data.after.ref.path;
      console.log(`Function notifyOnNewGrades triggered for path: ${path}`);

      const snap = event.data.after;
      if (!snap || !snap.exists) {
        console.log("Document was deleted or does not exist.");
        return;
      }
      const assignmentData = snap.data();
      const assignmentName = assignmentData.name;
      const scores = assignmentData.scores;
      const context = event.params;

      for (const studentId in scores) {
        if (Object.prototype.hasOwnProperty.call(scores, studentId)) {
          const studentScore = scores[studentId];
          if (studentScore.score) {
            const studentDocPath = `teachers/${context.teacherId}/` +
                        `groups/${context.groupId}/students`;
            const studentDoc = await admin
                .firestore()
                .collection(studentDocPath)
                .doc(studentId)
                .get();
            if (!studentDoc.exists) {
              console.log(`Student with ID ${studentId} not found.`);
              continue;
            }
            const parentPhoneNumber =
                        studentDoc.data().parentPhoneNumber;

            const parentQuery = await admin
                .firestore()
                .collectionGroup("students")
                .where("parentPhoneNumber", "==", parentPhoneNumber)
                .limit(1)
                .get();

            if (!parentQuery.empty) {
              const parentUserDoc = parentQuery.docs[0];
              const fcmToken = parentUserDoc.data().fcmToken;

              if (fcmToken) {
                const studentName = studentDoc.data().name;
                const payload = {
                  notification: {
                    title: "تم إضافة درجة جديدة",
                    body: `تم إضافة درجة "${assignmentName}" ` +
                                          `لابنك/ابنتك ${studentName}.`,
                  },
                };
                const msg = `Sending 'grades' notification for ` +
                                      `student ${studentId}`;
                console.log(msg);
                await admin.messaging()
                    .sendToDevice(fcmToken, payload);
              } else {
                const msg = `FCM token not found for parent of ` +
                                      `student ${studentId}`;
                console.log(msg);
              }
            }
          }
        }
      }
    });


// --- 3. إشعار بتذكير موعد الدرس ---
exports.lessonReminder = onSchedule("every 30 minutes", async (event) => {
  console.log("Function lessonReminder triggered by scheduler.");
  const now = new Date();
  const twoHoursFromNow = new Date(now.getTime() + 2 * 60 * 60 * 1000);

  const schedulesSnapshot = await admin
      .firestore()
      .collectionGroup("recurringSchedules")
      .get();

  for (const doc of schedulesSnapshot.docs) {
    const schedule = doc.data();
    const lessonTime = new Date(`${schedule.date}T${schedule.time}`);

    if (lessonTime > now && lessonTime <= twoHoursFromNow) {
      // (الكود هنا لإرسال إشعار الدرس)
    }
  }
});

// --- 4. إشعار عند عدم تسليم الواجب ---
exports.homeworkNotSubmitted = onSchedule("every day 09:00",
    async (event) => {
      console.log("Function homeworkNotSubmitted triggered by scheduler.");
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      const yesterdayString = yesterday.toISOString().split("T")[0];

      const assignmentsSnapshot = await admin
          .firestore()
          .collectionGroup("assignments")
          .where("date", "==", yesterdayString)
          .get();

      for (const doc of assignmentsSnapshot.docs) {
        const assignment = doc.data();
        // (الكود هنا لإرسال إشعار الواجب)
        console.log(`Checking assignment: ${assignment.name}`);
      }
    });
