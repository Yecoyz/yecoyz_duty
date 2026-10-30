# Yecoyz Duty – Free FiveM Duty Script (ESX / QBCore / Qbox)

**Yecoyz Duty** is a free, open-source **FiveM duty script** for **ESX, QBCore and Qbox**. Players go on and off duty from a modern menu, see who is working right now, and bosses can review and manage their staff's shifts. Includes shift history, worker management, shift corrections and a salary multiplier.

## Quick start

1. Install the dependencies: [ox_lib](https://github.com/overextended/ox_lib), [oxmysql](https://github.com/overextended/oxmysql) and `yecoyz_core`.
2. Download the [latest release](https://github.com/Yecoyz/yecoyz_duty/releases/latest) and extract it into your `resources` folder. Don't rename the folder.
3. Add it to your `server.cfg` after the dependencies and your framework:

```cfg
ensure ox_lib
ensure oxmysql
ensure yecoyz_core
ensure yecoyz_duty
```

4. Set your jobs in `shared/config.lua` and connect your paycheck system. Full guide: [installation docs](https://yecoyz.com/docs/yecoyz_duty/installation).

## Requirements

| Resource | Required |
| --- | --- |
| ESX, QBCore or Qbox | Yes |
| ox_lib | Yes |
| oxmysql | Yes |
| yecoyz_core | Yes |

## Features

- A sleek, modern, and easy-to-use interface designed for a smooth user experience. Easily see which players are online or offline, and whether they are on or off duty. You can also quickly access their phone numbers for easy communication, as well as view their rank within your company or organization.

- History: View how many hours you’ve worked with filters such as all-time, day, week, and month. You can also see the number of shifts and the average time per shift.

- Managing Workers system: This allows the boss or chief of a company to view all employees and monitor their work performance, including shifts, total work time, and average shift duration.

- Shift corrections: The boss or chief can change how long a worker's shift lasted or remove it completely, for example when someone stayed on duty AFK to farm hours. Every change is marked as edited, keeps the original time and is logged in the server console. Configure it with `Config.HistoryManagement`.

- Multiplier System: Rewards players for working longer shifts and staying active on duty. The more you work, the higher your multiplier grows. However, going off duty will gradually decrease the multiplier over time.

<p align="center">
  <a href="https://www.youtube.com/watch?v=ea963DAjAaY" target="_blank">
    <img src="https://img.shields.io/badge/🎥 Preview-red?style=for-the-badge&logo=youtube&logoColor=white" />
  </a>
  <a href="https://yecoyz.com/scripts/yecoyz-duty" target="_blank">
    <img src="https://img.shields.io/badge/🛒 Tebex Store-blue?style=for-the-badge&logo=cart&logoColor=white" />
  </a>
  <a href="https://discord.com/invite/s2NSxrDnNY" target="_blank">
    <img src="https://img.shields.io/badge/💬 Discord-5865F2?style=for-the-badge&logo=discord&logoColor=white" />
  </a>
  <a href="https://ko-fi.com/yecoyz" target="_blank">
    <img src="https://img.shields.io/badge/☕ Support Me-FF5E5B?style=for-the-badge&logo=kofi&logoColor=white" />
  </a>
    <a href="https://yecoyz.com/docs/yecoyz_duty/overview" target="_blank">
    <img src="https://img.shields.io/badge/Documentation-2F80ED?style=for-the-badge" />
  </a>
</p>

## License

Free to use and modify on your own server under the [MIT License](LICENSE). If you share or re-upload this script, with or without changes, you must keep the copyright notice and credit **Yecoyz** as the original author.
