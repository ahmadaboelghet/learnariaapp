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
 * @param {string} teacherId - معرف المدرس
 * @return {Promise<string>} - اسم المادة
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
 * تنسيق التاريخ YYYY-MM-DD.
 * @param {Date} date - كائن التاريخ
 * @return {string}
 */
function formatDate(date) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

/**
 * جلب رقم اليوم من 0 إلى 6.
 * @param {Date} date - كائن التاريخ
 * @return {number}
 */
function getDayDart(date) {
  return date.getDay();
}

/**
 * تحويل الوقت إلى صيغة 12 ساعة.
 * @param {string} timeString - الوقت بصيغة HH:mm
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

/**
 * إرسال إشعار لولي الأمر (نسخة محسنة تدعم تعدد المدرسين).
 * @param {object} studentData - بيانات الطالب
 * @param {object} payload - محتوى الإشعار (Notification Payload)
 * @param {string} context - سياق الوظيفة (للتتبع في الكونسول)
 * @param {string} studentId - معرف الطالب
 * @return {Promise<void>} - وعد يكتمل عند انتهاء المحاولة
 */
async function sendNotificationToParent(studentData, payload, context, studentId) {
  let tokenToSend = null;

  // 1. المحاولة الأولى: البحث عن التوكن داخل بيانات الطالب مباشرة (الأسرع)
  if (studentData.parentFcmToken) {
    tokenToSend = studentData.parentFcmToken;
  }

  // 2. المحاولة الثانية (الحل السحري): البحث في سجل الآباء العام برقم التليفون
  // دي اللي هتحل مشكلة تعدد المدرسين لو التوكن متنسخش لكل الطلاب
  if (!tokenToSend && studentData.parentPhoneNumber) {
    try {
      // تنظيف رقم الهاتف لضمان التطابق (إزالة المسافات)
      const cleanPhone = studentData.parentPhoneNumber.replace(/\s+/g, "").trim();
      const parentDoc = await admin.firestore().collection("parents").doc(cleanPhone).get();

      if (parentDoc.exists && parentDoc.data().fcmToken) {
        tokenToSend = parentDoc.data().fcmToken;
        console.log(`${context}: 🔄 Found token in global 'parents' collection for ${cleanPhone}`);
      }
    } catch (e) {
      console.error(`${context}: Error fetching global parent token:`, e);
    }
  }

  // 3. المحاولة الثالثة: تطبيق الموبايل (users collection)
  if (!tokenToSend) {
    const parentUserId = studentData.parentUserId;
    const parentPhoneNumber = studentData.parentPhoneNumber;
    let parentUserDoc;

    if (parentUserId) {
      try {
        const doc = await admin.firestore().collection("users").doc(parentUserId).get();
        if (doc.exists) parentUserDoc = doc;
      } catch (error) {
        console.error(`${context}: Error fetching parent by ID:`, error);
      }
    }

    if (!parentUserDoc && parentPhoneNumber) {
      try {
        const q = await admin.firestore().collection("users")
            .where("phoneNumber", "==", parentPhoneNumber).limit(1).get();
        if (!q.empty) parentUserDoc = q.docs[0];
      } catch (error) {
        console.error(`${context}: Error querying parent by phone:`, error);
      }
    }

    if (parentUserDoc && parentUserDoc.data().fcmToken) {
      tokenToSend = parentUserDoc.data().fcmToken;
    }
  }

  // ---------------------------------------------------------
  // تنفيذ الإرسال النهائي
  // ---------------------------------------------------------
  if (tokenToSend) {
    const message = {
      notification: payload.notification,
      data: payload.data,
      token: tokenToSend,
    };
    try {
      await admin.messaging().send(message);
      console.log(`${context}: ✅ Notification sent successfully.`);
    } catch (error) {
      console.error(`${context}: ❌ Failed to send notification:`, error);
      // لو التوكن منتهي، ممكن هنا نمسحه من الداتابيز مستقبلاً
    }
  } else {
    console.log(`${context}: ⚠️ No token found for student ${studentId} (Parent: ${studentData.parentPhoneNumber})`);
  }
}

// ===================================================================
// (الجزء الثاني: دوال الإشعارات التلقائية)
// ===================================================================

// 1. إشعار الغياب (محسن للسرعة)
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

      // تحسين السرعة: استخدام Promise.all لإرسال الإشعارات بالتوازي
      const notifications = records
          .filter((r) => r.status === "absent")
          .map(async (record) => {
            const studentId = record.studentId;
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
              return sendNotificationToParent(sData, payload, "notifyOnAbsence", studentId);
            }
          });

      await Promise.all(notifications);
    });

// 2. إشعار الدرجات وعدم التسليم (تم التعديل ليكون فوري وسريع)
exports.notifyOnNewGrades = onDocumentWritten(
    "teachers/{teacherId}/groups/{groupId}/assignments/{assignmentId}",
    async (event) => {
      const teacherId = event.params.teacherId;
      const groupId = event.params.groupId;
      const assignmentId = event.params.assignmentId;

      const snapAfter = event.data.after;
      if (!snapAfter || !snapAfter.exists) return;

      const afterData = snapAfter.data();
      const assignmentName = afterData.name || "واجب/امتحان";
      const scoresAfter = afterData.scores || {};
      const subjectName = await getTeacherSubject(teacherId);

      // مصفوفة لتخزين عمليات الإرسال وتنفيذها دفعة واحدة
      const sendPromises = [];

      for (const studentId in scoresAfter) {
        if (Object.prototype.hasOwnProperty.call(scoresAfter, studentId)) {
          const scoreData = scoresAfter[studentId];

          if (scoreData) {
            // نجهز العملية ونضيفها للقائمة
            const processStudent = async () => {
              const sDoc = await admin.firestore().doc(`teachers/${teacherId}/groups/${groupId}/students/${studentId}`).get();

              if (sDoc.exists) {
                const sData = sDoc.data();
                const hasScore = scoreData.score !== "" && scoreData.score != null;
                const isSubmitted = scoreData.submitted === true || (scoreData.submitted === undefined && hasScore);

                // الحالة الأولى: لم يتم التسليم (الأولوية للسرعة هنا)
                if (scoreData.submitted === false) {
                  const payload = {
                    notification: {
                      title: "لم يتم تسليم الواجب",
                      body: `نود إعلامكم بأن الطالب ${sData.name} لم يقم بتسليم واجب "${assignmentName}" في مادة ${subjectName}.`,
                    },
                    data: {"screen": "grades", "assignmentId": assignmentId},
                  };
                  await sendNotificationToParent(sData, payload, "notifyMissingHomework", studentId);
                } else if (isSubmitted && hasScore) {
                  // الحالة الثانية: رصد درجة جديدة
                  const payload = {
                    notification: {
                      title: "تم رصد درجة جديدة",
                      body: `حصل الطالب ${sData.name} على ${scoreData.score} في "${assignmentName}" لمادة ${subjectName}.`,
                    },
                    data: {"screen": "grades", "assignmentId": assignmentId},
                  };
                  await sendNotificationToParent(sData, payload, "notifyOnNewGrades", studentId);
                }
              }
            };
            sendPromises.push(processStudent());
          }
        }
      }

      // تنفيذ كل الإشعارات في نفس اللحظة لعدم التأخير
      await Promise.all(sendPromises);
    });

// ===================================================================
// (الجزء الثالث: المهام المجدولة)
// ===================================================================

// 3. تذكير بمواعيد الدروس (قبل الميعاد بـ 30 دقيقة)
exports.classReminder = onSchedule({
  schedule: "*/15 * * * *", // يعمل كل 15 دقيقة لضمان دقة التوقيت
  timeZone: "Africa/Cairo",
}, async (event) => {
  const now = new Date();
  const cairoTimeStr = now.toLocaleString("en-US", {timeZone: "Africa/Cairo"});
  const cairoDate = new Date(cairoTimeStr);

  // نضيف 30 دقيقة على الوقت الحالي
  const targetDate = new Date(cairoDate.getTime() + 30 * 60000);

  const targetHour = targetDate.getHours();
  const targetMinute = targetDate.getMinutes();
  const dayIndex = targetDate.getDay();

  console.log(`Checking classes for Day: ${dayIndex}, Time around: ${targetHour}:${targetMinute}`);

  const teachersSnap = await admin.firestore().collection("teachers").get();

  for (const teacherDoc of teachersSnap.docs) {
    const groupsSnap = await teacherDoc.ref.collection("groups").get();

    for (const groupDoc of groupsSnap.docs) {
      const schedulesSnap = await groupDoc.ref.collection("recurringSchedules").get();

      for (const schedDoc of schedulesSnap.docs) {
        const sched = schedDoc.data();
        if (sched.days && sched.days.includes(dayIndex)) {
          const [hStr, mStr] = sched.time.split(":");
          const schedHour = parseInt(hStr, 10);
          const schedMinute = parseInt(mStr, 10);

          // سماحية 7 دقائق قبل أو بعد لضمان التقاط الموعد
          const isTimeMatch = (schedHour === targetHour) && (Math.abs(schedMinute - targetMinute) <= 7);

          if (isTimeMatch) {
            const subjectName = await getTeacherSubject(teacherDoc.id);
            const studentsSnap = await groupDoc.ref.collection("students").get();

            const notifications = studentsSnap.docs.map(async (studentDoc) => {
              const studentData = studentDoc.data();
              const payload = {
                notification: {
                  title: "اقتراب موعد الدرس",
                  body: `تذكير: درس ${subjectName} للطالب ${studentData.name} يبدأ بعد 30 دقيقة (الساعة ${formatTime12Hour(sched.time)}).`,
                },
                data: {"screen": "schedule"},
              };
              return sendNotificationToParent(studentData, payload, "classReminder", studentDoc.id);
            });
            await Promise.all(notifications);
          }
        }
      }
    }
  }
});


// 4. تذكير بدفع المصروفات (بداية من يوم 5، كل يومين، للشهر السابق)
exports.paymentReminder = onSchedule({
  schedule: "0 14 * * *", // يعمل يومياً الساعة 2 ظهراً
  timeZone: "Africa/Cairo",
}, async (event) => {
  const now = new Date();
  const cairoTimeStr = now.toLocaleString("en-US", {timeZone: "Africa/Cairo"});
  const cairoDate = new Date(cairoTimeStr);

  const currentDay = cairoDate.getDate();

  // المنطق: ابدأ من يوم 5، وكرر كل يومين (5, 7, 9, 11...)
  // الشرط: اليوم أكبر من أو يساوي 5، والفرق بينه وبين 5 يقبل القسمة على 2
  if (currentDay < 5 || (currentDay - 5) % 2 !== 0) {
    console.log("Not a payment reminder day. Skipping.");
    return;
  }

  // تحديد الشهر السابق (لأننا في يوم 5 من الشهر الجديد بنطالب بفلوس الشهر اللي خلص)
  const prevMonthDate = new Date(cairoDate);
  prevMonthDate.setMonth(prevMonthDate.getMonth() - 1);
  const targetMonth = prevMonthDate.toISOString().slice(0, 7); // Format: YYYY-MM

  console.log(`Running Payment Reminder for PREVIOUS month: ${targetMonth}`);

  const teachersSnap = await admin.firestore().collection("teachers").get();

  for (const teacherDoc of teachersSnap.docs) {
    const subjectName = await getTeacherSubject(teacherDoc.id);
    const groupsSnap = await teacherDoc.ref.collection("groups").get();

    for (const groupDoc of groupsSnap.docs) {
      const studentsSnap = await groupDoc.ref.collection("students").get();
      if (studentsSnap.empty) continue;

      const paymentDoc = await groupDoc.ref.collection("payments").doc(targetMonth).get();
      let paidStudentIds = [];

      if (paymentDoc.exists) {
        const records = paymentDoc.data().records || [];
        paidStudentIds = records.filter((r) => r.paid === true).map((r) => r.studentId);
      }

      const notifications = studentsSnap.docs.map(async (studentDoc) => {
        if (!paidStudentIds.includes(studentDoc.id)) {
          const studentData = studentDoc.data();
          const payload = {
            notification: {
              title: "تذكير هام بالمصروفات",
              body: `نود تذكيركم بسداد مصروفات شهر ${targetMonth} المتأخرة لمادة ${subjectName} للطالب ${studentData.name}.`,
            },
            data: {"screen": "payments"},
          };
          return sendNotificationToParent(studentData, payload, "paymentReminder", studentDoc.id);
        }
      });
      await Promise.all(notifications);
    }
  }
});

// ===================================================================
// (الجزء الرابع: دوال لوحة التحكم والتطبيق)
// ===================================================================

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

// 5. إشعار عند دفع المصروفات
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

      const beforeStatusMap = {};
      beforeRecords.forEach((r) => {
        beforeStatusMap[r.studentId] = r.paid;
      });

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

exports.sendCustomMessage = onCall(async (request) => {
  const {teacherId, groupId, studentId, messageBody} = request.data;

  try {
    const studentDoc = await admin.firestore().doc(`teachers/${teacherId}/groups/${groupId}/students/${studentId}`).get();

    if (!studentDoc.exists) throw new HttpsError("not-found", "الطالب غير موجود");

    const studentData = studentDoc.data();
    const subjectName = await getTeacherSubject(teacherId);

    const payload = {
      notification: {
        title: `رسالة من مدرس ${subjectName}`,
        body: messageBody,
      },
      data: {screen: "profile", studentId: studentId},
    };

    await sendNotificationToParent(studentData, payload, "sendCustomMessage", studentId);

    return {success: true};
  } catch (error) {
    console.error("Error sending custom message:", error);
    throw new HttpsError("internal", error.message);
  }
});
