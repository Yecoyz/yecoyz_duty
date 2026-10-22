import { UserRound } from "lucide-react";

export const Button = ({ variant = "primary", size, block, className = "", ...props }) => (
  <button
    type="button"
    className={["btn", `btn-${variant}`, size && `btn-${size}`, block && "btn-block", className].filter(Boolean).join(" ")}
    {...props}
  />
);

export const Badge = ({ tone, children }) => <span className={`badge${tone ? ` badge-${tone}` : ""}`}>{children}</span>;

export const StatusDot = ({ on }) => <span className={`status-dot${on ? " on" : ""}`} />;

export const Avatar = ({ online, large }) => (
  <div className={`avatar${large ? " avatar-lg" : ""}`}>
    <UserRound size={large ? 26 : 20} />
    {online !== undefined && <StatusDot on={online} />}
  </div>
);

export const Stat = ({ label, value, accent }) => (
  <div className="stat inset">
    <span className="label">{label}</span>
    <span className={`stat-value${accent ? " accent" : ""}`}>{value}</span>
  </div>
);

export const EmptyState = ({ icon: Icon, text }) => (
  <div className="empty">
    <div className="icon-tile">
      <Icon size={18} />
    </div>
    <div className="empty-text">{text}</div>
  </div>
);
