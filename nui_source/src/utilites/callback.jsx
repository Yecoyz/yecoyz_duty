import { isBrowser, mockShifts } from "../lib/mock";

// Same shape as the server: index/key point at the saved shift.
let mockEmployeeShifts = mockShifts
  .filter((shift) => !shift.job || shift.job === "police")
  .map((shift, index) => ({ ...shift, index: index + 1, key: shift.startTime, editable: Boolean(shift.startTime) }));

const browserResponses = {
  getLocale: () => ({}),
  closePage: () => ({ success: true }),
  getEmployeeHistory: () => mockEmployeeShifts,
  editShift: ({ index, duration }) => {
    mockEmployeeShifts = mockEmployeeShifts.map((shift) =>
      shift.index === index
        ? {
            ...shift,
            duration,
            endTime: shift.startTime + duration,
            edited: { by: "Robert Taylor", at: Math.floor(Date.now() / 1000), originalDuration: shift.edited?.originalDuration ?? shift.duration },
          }
        : shift
    );
    return { success: true, shifts: mockEmployeeShifts };
  },
  removeShift: ({ index }) => {
    mockEmployeeShifts = mockEmployeeShifts.filter((shift) => shift.index !== index);
    return { success: true, shifts: mockEmployeeShifts };
  },
  toggleDuty: () => ({ success: true, isOnDuty: true, dutyStarted: Math.floor(Date.now() / 1000), shifts: mockShifts }),
};

async function post(event, data) {
  return fetch(`https://yecoyz_duty/Eventhandler`, {
    method: "POST",
    headers: {
      "Content-type": "application/json; charset=UTF-8",
    },
    body: JSON.stringify({
      event: event,
      data: data || {},
    }),
  });
}

async function send(event, data) {
  if (isBrowser) return undefined;
  return post(event, data);
}

async function callback(event, data) {
  if (isBrowser) return browserResponses[event]?.(data);
  return post(event, data).then((response) => response.json());
}

export { send, callback };
