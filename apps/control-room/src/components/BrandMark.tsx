import { Sparkle } from "@phosphor-icons/react";

export function BrandMark() {
  return (
    <div className="brand" aria-label="Converge Control Room">
      <span className="brand__mark" aria-hidden="true">
        <Sparkle weight="duotone" />
      </span>
      <span className="brand__word">Converge</span>
      <span className="brand__surface">Control Room</span>
    </div>
  );
}
