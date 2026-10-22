import { ChevronRight, Clock, Phone } from "lucide-react";
import { formatDuration } from "../lib/format";
import { Avatar, Badge } from "./ui";

// One worker. Pass `onClick` to make the row selectable (Manage tab).
const WorkerRow = ({ worker, now, onClick }) => {
  const Tag = onClick ? "button" : "div";
  const online = Boolean(worker.online);

  return (
    <Tag type={onClick ? "button" : undefined} className={`worker inset${online ? "" : " offline"}`} onClick={onClick}>
      <Avatar online={online} />
      <div className="worker-body">
        <span className="worker-name">{worker.name}</span>
        <div className="meta-row">{worker.grade && <Badge>{worker.grade}</Badge>}</div>
      </div>

      {onClick ? (
        <ChevronRight size={18} className="worker-arrow" />
      ) : (
        <div className="worker-side">
          <span className="plate with-icon">
            <Phone size={12} />
            {worker.phone || "Unknown"}
          </span>
          {online && worker.dutyStarted && (
            <span className="worker-time with-icon">
              <Clock size={12} />
              {formatDuration(now - worker.dutyStarted)}
            </span>
          )}
        </div>
      )}
    </Tag>
  );
};

export default WorkerRow;
