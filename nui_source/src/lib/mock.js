// Sample data so the UI can be worked on in a normal browser (npm run dev).
export const isBrowser = typeof window !== "undefined" && !window.invokeNative;

const now = Math.floor(Date.now() / 1000);
const hour = 3600;

const shift = (job, jobLabel, startedAgo, duration) => ({
  job,
  jobLabel,
  startTime: now - startedAgo,
  endTime: now - startedAgo + duration,
  duration,
});

export const mockShifts = [
  shift("police", "LSPD", 2 * hour, 1 * hour + 12 * 60),
  shift("beanmachine", "Bean Machine", 8 * hour, 4 * hour + 5 * 60),
  shift("police", "LSPD", 30 * hour, 6 * hour + 40 * 60),
  shift("police", "LSPD", 75 * hour, 3 * hour + 2 * 60),
  shift("beanmachine", "Bean Machine", 100 * hour, 2 * hour + 30 * 60),
  shift("police", "LSPD", 200 * hour, 5 * hour + 15 * 60),
  { startTimeFormatted: "2025-04-01 14:20:41", endTimeFormatted: "2025-04-01 21:43:47", duration: 26586 },
];

export const mockData = {
  character: {
    name: "Robert Taylor",
    job: "LSPD",
    jobName: "police",
    grade: "Assistant Chief",
    isOnDuty: true,
    dutyStarted: now - 47 * 60,
    isBoss: true,
  },
  workers: [
    { identifier: "a", name: "Lisa Brown", grade: "Sergeant", phone: "555-456-7890", online: true, dutyStarted: now - 80 * 60 },
    { identifier: "b", name: "Robert Taylor", grade: "Assistant Chief", phone: "555-234-5678", online: true, dutyStarted: now - 47 * 60 },
    { identifier: "c", name: "Stefan Andersson", grade: "Captain", phone: "393-459-9251", online: false },
    { identifier: "d", name: "Sarah Johnson", grade: "Training Officer", phone: "555-987-6543", online: false },
    { identifier: "e", name: "Mike Williams", grade: "Detective", phone: "Unknown", online: false },
  ],
  shifts: mockShifts,
  historyManagement: { edit: true, remove: true, maxHours: 24 },
};
