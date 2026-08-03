import {
  ArrowSquareOut,
  FileCode,
  Fingerprint,
  SealCheck,
  WarningCircle,
} from "@phosphor-icons/react";
import type {
  ArtifactRef,
  EntityRef,
  WorkspaceSnapshot,
} from "../types";

interface ProofSurfaceProps {
  snapshot: WorkspaceSnapshot;
  selected: EntityRef | null;
  onSelect: (selection: EntityRef) => void;
  onOpenArtifact: (artifact: ArtifactRef) => void;
}

export function ProofSurface({
  snapshot,
  selected,
  onSelect,
  onOpenArtifact,
}: ProofSurfaceProps) {
  return (
    <section className="surface surface--proof" aria-labelledby="proof-title">
      <header className="surface-header">
        <div>
          <span>Canonical evidence</span>
          <h1 id="proof-title">Proof</h1>
        </div>
        <div className="surface-header__stat">
          <Fingerprint aria-hidden="true" />
          <span>
            <strong>{snapshot.artifacts.length}</strong>
            hash-bound artifacts
          </span>
        </div>
      </header>

      <div className="proof-layout">
        <section className="proof-artifacts" aria-labelledby="artifact-list-title">
          <header>
            <h2 id="artifact-list-title">Artifacts</h2>
            <span>{snapshot.artifacts.length} observed</span>
          </header>
          {snapshot.artifacts.length === 0 ? (
            <div className="inline-state">
              <FileCode aria-hidden="true" />
              No artifacts are attached to this snapshot.
            </div>
          ) : (
            <div className="artifact-table" role="list">
              {snapshot.artifacts.map((artifact) => {
                const active =
                  selected?.kind === "artifact" && selected.id === artifact.id;
                return (
                  <article
                    key={artifact.id}
                    className={`artifact-row ${active ? "artifact-row--selected" : ""}`}
                    role="listitem"
                  >
                    <button
                      type="button"
                      className="artifact-row__select"
                      onClick={() =>
                        onSelect({ kind: "artifact", id: artifact.id })
                      }
                    >
                      <FileCode size={18} aria-hidden="true" />
                      <span>
                        <strong>{artifact.label}</strong>
                        <small>{artifact.path}</small>
                      </span>
                      <span className="artifact-row__kind">{artifact.kind}</span>
                      <code>{artifact.sha256.slice(0, 10)}</code>
                    </button>
                    <button
                      type="button"
                      className="artifact-row__open"
                      onClick={() => onOpenArtifact(artifact)}
                      aria-label={`Open ${artifact.label}`}
                      title="Open verified preview"
                    >
                      <ArrowSquareOut aria-hidden="true" />
                    </button>
                  </article>
                );
              })}
            </div>
          )}
        </section>

        <section className="receipt-stack" aria-labelledby="receipt-list-title">
          <header>
            <h2 id="receipt-list-title">Receipts</h2>
            <span>{snapshot.receipts.availability}</span>
          </header>
          {snapshot.receipts.availability === "unavailable" ? (
            <div className="inline-state">
              <WarningCircle aria-hidden="true" />
              Receipt inventory is unavailable.
            </div>
          ) : snapshot.receipts.items.length === 0 ? (
            <div className="inline-state">
              <SealCheck aria-hidden="true" />
              No settlements have emitted receipts.
            </div>
          ) : (
            snapshot.receipts.items.map((receipt) => (
              <button
                type="button"
                key={receipt.id}
                className={`receipt-card receipt-card--${receipt.integrity} ${
                  selected?.kind === "receipt" && selected.id === receipt.id
                    ? "is-selected"
                    : ""
                }`}
                onClick={() => onSelect({ kind: "receipt", id: receipt.id })}
              >
                <span className="receipt-card__glyph">
                  {receipt.integrity === "verified" ? (
                    <SealCheck weight="fill" aria-hidden="true" />
                  ) : (
                    <WarningCircle weight="fill" aria-hidden="true" />
                  )}
                </span>
                <span>
                  <strong>{receipt.taskId ?? receipt.id}</strong>
                  <small>{receipt.result}</small>
                </span>
                <span className="receipt-card__integrity">{receipt.integrity}</span>
                <time dateTime={receipt.recordedAt ?? undefined}>
                  {receipt.recordedAt
                    ? new Date(receipt.recordedAt).toLocaleDateString()
                    : "No timestamp"}
                </time>
              </button>
            ))
          )}
        </section>
      </div>
    </section>
  );
}
