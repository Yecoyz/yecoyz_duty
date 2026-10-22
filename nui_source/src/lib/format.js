// Shifts are saved with epoch seconds. Old shifts may only have the formatted string.
export const shiftStart = (shift) =>
  typeof shift.startTime === "number"
    ? new Date(shift.startTime * 1000)
    : new Date(String(shift.startTimeFormatted).replace(" ", "T"));

export const shiftEnd = (shift) =>
  typeof shift.endTime === "number"
    ? new Date(shift.endTime * 1000)
    : new Date(String(shift.endTimeFormatted).replace(" ", "T"));

export const formatDuration = (seconds) => {
  const safe = Math.max(0, Math.floor(seconds || 0));
  const hours = Math.floor(safe / 3600);
  const minutes = Math.floor((safe % 3600) / 60);
  return hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`;
};

export const formatClock = (seconds) => {
  const safe = Math.max(0, Math.floor(seconds || 0));
  const pad = (n) => String(n).padStart(2, "0");
  return `${pad(Math.floor(safe / 3600))}:${pad(Math.floor((safe % 3600) / 60))}:${pad(safe % 60)}`;
};

export const formatDay = (date) =>
  date.toLocaleDateString("en-US", { weekday: "short", month: "short", day: "numeric" });

export const formatTime = (date) =>
  date.toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit" });

export const PERIODS = ["all", "day", "week", "month"];

const periodStart = (period) => {
  const now = new Date();
  if (period === "day") return new Date(now.getFullYear(), now.getMonth(), now.getDate());
  if (period === "week") {
    const start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    start.setDate(start.getDate() - ((start.getDay() + 6) % 7)); // Monday
    return start;
  }
  if (period === "month") return new Date(now.getFullYear(), now.getMonth(), 1);
  return null;
};

export const filterShifts = (shifts, { period = "all", job = "all" } = {}) => {
  const start = periodStart(period);
  return shifts
    .filter((shift) => job === "all" || shift.job === job)
    .filter((shift) => !start || shiftStart(shift) >= start)
    .sort((a, b) => shiftStart(b) - shiftStart(a));
};

export const shiftStats = (shifts) => {
  const total = shifts.reduce((sum, shift) => sum + (Number(shift.duration) || 0), 0);
  return {
    count: shifts.length,
    total,
    average: shifts.length > 0 ? total / shifts.length : 0,
  };
};

// Every job found in the shift history, for the multijob filter.
export const shiftJobs = (shifts) => {
  const jobs = new Map();
  shifts.forEach((shift) => {
    if (shift.job && !jobs.has(shift.job)) jobs.set(shift.job, shift.jobLabel || shift.job);
  });
  return [...jobs].map(([name, label]) => ({ name, label }));
};
