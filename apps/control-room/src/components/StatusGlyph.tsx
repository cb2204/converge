import {
  CheckCircle,
  Circle,
  CircleNotch,
  GitBranch,
  Warning,
  XCircle,
} from "@phosphor-icons/react";
import type { PassStatus } from "../types";

interface StatusGlyphProps {
  status: PassStatus;
  size?: number;
}

export function StatusGlyph({ status, size = 18 }: StatusGlyphProps) {
  switch (status) {
    case "complete":
      return <CheckCircle size={size} weight="fill" aria-hidden="true" />;
    case "active":
      return (
        <CircleNotch
          className="status-glyph--spin"
          size={size}
          weight="bold"
          aria-hidden="true"
        />
      );
    case "attention":
      return <Warning size={size} weight="fill" aria-hidden="true" />;
    case "blocked":
      return <XCircle size={size} weight="fill" aria-hidden="true" />;
    case "optional":
    case "skipped":
      return <GitBranch size={size} weight="bold" aria-hidden="true" />;
    default:
      return <Circle size={size} weight="regular" aria-hidden="true" />;
  }
}
