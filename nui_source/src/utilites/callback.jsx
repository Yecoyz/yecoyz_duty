import { isBrowser, mockShifts } from "../lib/mock";

const browserResponses = {
  getLocale: () => ({}),
  closePage: () => ({ success: true }),
  getEmployeeHistory: () => mockShifts.filter((shift) => !shift.job || shift.job === "police"),
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
  if (isBrowser) return browserResponses[event]?.();
  return post(event, data).then((response) => response.json());
}

export { send, callback };
