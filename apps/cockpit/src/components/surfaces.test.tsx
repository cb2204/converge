import { useState } from "react";
import {
  fireEvent,
  render,
  screen,
  waitFor,
  within,
} from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { CommandDock } from "./CommandDock";
import { ArtifactViewer } from "./ArtifactViewer";
import { HealthSurface } from "./HealthSurface";
import { InspectorPanel } from "./InspectorPanel";
import { ProofSurface } from "./ProofSurface";
import { RunsSurface } from "./RunsSurface";
import { WorkSurface } from "./WorkSurface";
import {
  makeEmptySnapshot,
  makeScenarioSnapshot,
} from "../test/scenarios";

vi.mock("./WorkGraph", () => ({
  WorkGraph: () => <div aria-label="Work dependency graph">Graph projection</div>,
}));

vi.mock("motion/react", () => ({
  AnimatePresence: ({ children }: { children: React.ReactNode }) => children,
  motion: new Proxy(
    {},
    {
      get: (_target, tag: string) => tag,
    },
  ),
  useReducedMotion: () => true,
}));

describe("Cockpit lifecycle surfaces", () => {
  it("renders intentional empty work, run, and receipt states", async () => {
    const user = userEvent.setup();
    const snapshot = makeEmptySnapshot();
    const onSelect = vi.fn();
    const { rerender } = render(
      <WorkSurface
        snapshot={snapshot}
        selected={null}
        onSelect={onSelect}
      />,
    );

    expect(screen.getByText("No work has been decomposed")).toBeTruthy();

    rerender(
      <RunsSurface
        snapshot={snapshot}
        selected={null}
        onSelect={onSelect}
      />,
    );
    expect(screen.getByText("No attempts recorded")).toBeTruthy();

    rerender(
      <ProofSurface
        snapshot={snapshot}
        selected={null}
        onSelect={onSelect}
        onOpenArtifact={vi.fn()}
      />,
    );
    expect(screen.getByText("No settlements have emitted receipts.")).toBeTruthy();

    await user.click(
      screen.getByText("Task specification").closest("button") as HTMLElement,
    );
    expect(onSelect).toHaveBeenCalledWith({
      kind: "artifact",
      id: "artifact_22222222222222222222",
    });
  });

  it("keeps frontier, backlog, completed, and every Task-Spec state distinct", async () => {
    const user = userEvent.setup();
    const onSelect = vi.fn();
    render(
      <WorkSurface
        snapshot={makeScenarioSnapshot()}
        selected={null}
        onSelect={onSelect}
      />,
    );

    await user.click(screen.getByRole("button", { name: "List" }));

    const frontier = screen.getByText("Frontier").closest("section");
    const backlog = screen.getByText("Backlog").closest("section");
    const completed = screen.getByText("Completed").closest("section");
    expect(frontier).toBeTruthy();
    expect(backlog).toBeTruthy();
    expect(completed).toBeTruthy();
    expect(within(frontier as HTMLElement).getByText("Dispatchable frontier task")).toBeTruthy();
    expect(within(backlog as HTMLElement).getByText("Dependency-blocked task")).toBeTruthy();
    expect(within(backlog as HTMLElement).getByText("Task in progress")).toBeTruthy();
    expect(within(backlog as HTMLElement).getByText("Parked task")).toBeTruthy();
    expect(within(completed as HTMLElement).getByText("Completed task")).toBeTruthy();

    await user.click(screen.getByRole("button", { name: /Dependency-blocked task/i }));
    expect(onSelect).toHaveBeenCalledWith({ kind: "task", id: "T-blocked" });
  });

  it("renders RED, retry, resumed, and settled attempts as separate records", async () => {
    const user = userEvent.setup();
    const onSelect = vi.fn();
    render(
      <RunsSurface
        snapshot={makeScenarioSnapshot()}
        selected={null}
        onSelect={onSelect}
      />,
    );

    for (const state of ["red", "retry", "resumed", "settled"]) {
      expect(screen.getByText(state)).toBeTruthy();
    }

    await user.click(screen.getByRole("button", { name: /run-retry/i }));
    expect(onSelect).toHaveBeenCalledWith({ kind: "run", id: "run-retry" });
  });

  it("does not conflate verified, mismatched, and unavailable receipts", () => {
    const onSelect = vi.fn();
    render(
      <ProofSurface
        snapshot={makeScenarioSnapshot()}
        selected={null}
        onSelect={onSelect}
        onOpenArtifact={vi.fn()}
      />,
    );

    expect(screen.getByText("verified")).toBeTruthy();
    expect(screen.getByText("mismatch")).toBeTruthy();
    expect(screen.getByText("unavailable")).toBeTruthy();

    fireEvent.click(screen.getByRole("button", { name: /T-progress/i }));
    expect(onSelect).toHaveBeenCalledWith({
      kind: "receipt",
      id: "receipt-mismatch",
    });
  });

  it("keeps health checks and typed issues selectable", () => {
    const onSelect = vi.fn();
    render(
      <HealthSurface
        snapshot={makeScenarioSnapshot()}
        selected={null}
        onSelect={onSelect}
      />,
    );

    fireEvent.click(screen.getByRole("button", { name: /tracker-config/i }));
    expect(onSelect).toHaveBeenCalledWith({
      kind: "health",
      id: "tracker-config",
    });

    fireEvent.click(
      screen.getByRole("button", {
        name: /Pass 4 needs an owner decision/i,
      }),
    );
    expect(onSelect).toHaveBeenCalledWith({
      kind: "issue",
      id: "issue_11111111111111111111",
    });
  });
});

describe("Cockpit proof and command boundaries", () => {
  it("copies the exact CLI command without exposing an execution control", async () => {
    const user = userEvent.setup();
    const writeText = vi.fn().mockResolvedValue(undefined);
    Object.defineProperty(window.navigator.clipboard, "writeText", {
      configurable: true,
      value: writeText,
    });
    const snapshot = makeScenarioSnapshot();
    render(<CommandDock snapshot={snapshot} />);

    expect(screen.getByText("cvg review --check")).toBeTruthy();
    expect(screen.getByText("Browser read-only")).toBeTruthy();
    expect(screen.queryByRole("button", { name: /run|execute/i })).toBeNull();

    await user.click(
      screen.getByRole("button", { name: "Copy authorized command" }),
    );
    expect(writeText).toHaveBeenCalledWith("cvg review --check");
    expect(screen.getByRole("button", { name: "Command copied" })).toBeTruthy();
  });

  it("shows inspector history only for explicitly linked signals", async () => {
    const user = userEvent.setup();
    const onTabChange = vi.fn();
    const { rerender } = render(
      <InspectorPanel
        snapshot={makeScenarioSnapshot()}
        selected={{ kind: "run", id: "run-retry" }}
        tab="details"
        expanded
        onTabChange={onTabChange}
        onToggle={vi.fn()}
        onOpenArtifact={vi.fn()}
      />,
    );
    expect(screen.getByText("run-retry")).toBeTruthy();
    expect(screen.queryByText(/Text mentions run-retry/)).toBeNull();

    await user.click(screen.getByRole("tab", { name: "History" }));
    expect(onTabChange).toHaveBeenCalledWith("history");

    rerender(
      <InspectorPanel
        snapshot={makeScenarioSnapshot()}
        selected={{ kind: "run", id: "run-retry" }}
        tab="history"
        expanded
        onTabChange={onTabChange}
        onToggle={vi.fn()}
        onOpenArtifact={vi.fn()}
      />,
    );
    expect(screen.getByText("Retry was requested.")).toBeTruthy();
    expect(screen.getByText("RED evaluation.")).toBeTruthy();
    expect(screen.queryByText(/Text mentions run-retry/)).toBeNull();
  });

  it("keeps artifact reads snapshot-and-digest bound and restores focus", async () => {
    const user = userEvent.setup();
    const snapshot = makeScenarioSnapshot();
    const artifact = snapshot.artifacts[0];
    const fetchSpy = vi.spyOn(globalThis, "fetch").mockResolvedValue(
      new Response(
        JSON.stringify({
          path: artifact.path,
          label: artifact.label,
          kind: artifact.kind,
          content: "canonical proof",
          truncated: false,
          sha256: artifact.sha256,
          snapshotId: snapshot.snapshotId,
        }),
        {
          status: 200,
          headers: { "Content-Type": "application/json" },
        },
      ),
    );

    function Harness() {
      const [open, setOpen] = useState(false);
      return (
        <>
          <button type="button" onClick={() => setOpen(true)}>
            Open canonical proof
          </button>
          <ArtifactViewer
            snapshot={snapshot}
            artifact={open ? artifact : null}
            onClose={() => setOpen(false)}
          />
        </>
      );
    }

    render(<Harness />);
    const opener = screen.getByRole("button", { name: "Open canonical proof" });
    await user.click(opener);

    const close = await screen.findByRole("button", {
      name: "Close artifact viewer",
    });
    await waitFor(() => expect(document.activeElement).toBe(close));
    expect(fetchSpy).toHaveBeenCalledWith(
      `/api/artifact?path=${encodeURIComponent(artifact.path)}&snapshotId=${snapshot.snapshotId}&sha256=${artifact.sha256}`,
      expect.objectContaining({ method: "GET" }),
    );
    expect(await screen.findByText("canonical proof")).toBeTruthy();

    fireEvent.keyDown(window, { key: "Escape" });
    await waitFor(() =>
      expect(
        screen.queryByRole("button", { name: "Close artifact viewer" }),
      ).toBeNull(),
    );
    expect(document.activeElement).toBe(opener);
  });
});
