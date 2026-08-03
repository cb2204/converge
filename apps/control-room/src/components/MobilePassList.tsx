import { CaretRight } from "@phosphor-icons/react";
import type { PassState } from "../types";
import { StatusGlyph } from "./StatusGlyph";

interface MobilePassListProps {
  passes: PassState[];
  selectedPassId: string;
  onSelectPass: (passId: string) => void;
}

export function MobilePassList({
  passes,
  selectedPassId,
  onSelectPass,
}: MobilePassListProps) {
  return (
    <ol className="mobile-pass-list" aria-label="Converge passes">
      {passes.map((pass) => (
        <li key={pass.id}>
          <button
            type="button"
            className={`mobile-pass ${
              selectedPassId === pass.id ? "mobile-pass--selected" : ""
            }`}
            onClick={() => onSelectPass(pass.id)}
            aria-current={selectedPassId === pass.id ? "step" : undefined}
          >
            <span className={`mobile-pass__glyph status-${pass.status}`}>
              <StatusGlyph status={pass.status} />
            </span>
            <span className="mobile-pass__order">{pass.order}</span>
            <span className="mobile-pass__copy">
              <strong>{pass.shortLabel}</strong>
              <span>{pass.gate.token ?? pass.summary}</span>
            </span>
            <CaretRight size={17} aria-hidden="true" />
          </button>
        </li>
      ))}
    </ol>
  );
}
