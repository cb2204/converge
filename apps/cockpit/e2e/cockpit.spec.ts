import AxeBuilder from "@axe-core/playwright";
import { expect, test, type Page } from "@playwright/test";

interface LiveEnvelope {
  snapshot: {
    schemaVersion: string;
    snapshotId: string;
    source: string;
    method: {
      activePassId: string | null;
    };
    work: { availability: string };
    execution: { availability: string };
    receipts: { availability: string };
  };
  transport: {
    stale: boolean;
    servedAt: string;
    error?: { code: string; message: string };
  };
}

async function requireLiveContract(page: Page) {
  await expect
    .poll(async () => {
      const health = await page.request.get("/api/health");
      if (!health.ok()) return [health.status(), "unhealthy"];
      const document = (await health.json()) as Record<string, unknown>;
      return [document.service, document.mode];
    })
    .toEqual(["converge-cockpit", "read-only"]);

  const response = await page.request.get("/api/snapshot");
  expect(response.ok()).toBe(true);
  const envelope = (await response.json()) as LiveEnvelope;
  expect(envelope.snapshot.schemaVersion).toBe("2.0");
  expect(envelope.snapshot.snapshotId).toMatch(/^ws2_[0-9a-f]{32}$/);
  expect(envelope.snapshot.source).toBe("workspace");
  expect(envelope.transport.stale).toBe(false);
  return envelope;
}

async function openPrimaryView(page: Page, label: string) {
  const viewport = page.viewportSize();
  if (!viewport) throw new Error("Playwright viewport is required");

  if (viewport.width < 768) {
    await page.locator(".mobile-nav button", { hasText: label }).click();
    return;
  }

  const navigation = page.locator("#cockpit-navigation");
  if (viewport.width <= 1023) {
    const toggle = page.locator(".command-bar__panel-toggle--left");
    if ((await toggle.getAttribute("aria-expanded")) !== "true") {
      await toggle.click();
    }
  }
  await navigation.locator(".nav-item", { hasText: label }).click();
}

async function expectWorkspaceState(page: Page, label: string) {
  await expect(
    page.locator(".connection-state").filter({ has: page.locator("svg") }),
  ).toHaveAttribute("aria-label", label);
}

test.beforeEach(async ({ page }) => {
  await page.emulateMedia({ reducedMotion: "reduce" });
});

test("renders only a live WorkspaceSnapshot 2.0 and performs GET requests", async ({
  context,
  page,
}) => {
  const methods: Array<{ method: string; url: string }> = [];
  page.on("request", (request) => {
    methods.push({ method: request.method(), url: request.url() });
  });
  await context.grantPermissions(["clipboard-read", "clipboard-write"]);
  const envelope = await requireLiveContract(page);

  await page.goto("/");
  await expectWorkspaceState(page, "Live workspace");
  await expect(page.getByText("Replay fixture")).toHaveCount(0);
  await expect(page.getByText("Live workspace unavailable")).toHaveCount(0);
  await expect(page.getByRole("main")).toHaveClass(/cockpit-shell/);
  await expect(page.getByText(envelope.snapshot.snapshotId.slice(0, 12))).toHaveCount(
    0,
  );

  const copy = page.getByRole("button", {
    name: "Copy authorized command",
  });
  await expect(copy).toBeEnabled();
  await copy.click();
  await expect(
    page.getByRole("button", { name: "Command copied" }),
  ).toBeVisible();
  await expect(page.getByText("CLI execution required").first()).toBeVisible();

  expect(methods.length).toBeGreaterThan(0);
  expect(
    methods.filter(({ method }) => method !== "GET"),
    `non-GET browser requests: ${JSON.stringify(methods)}`,
  ).toEqual([]);
});

test("navigates every empty lifecycle view without inventing data", async ({
  page,
}) => {
  const envelope = await requireLiveContract(page);
  expect(envelope.snapshot.work.availability).toBe("empty");
  expect(envelope.snapshot.execution.availability).toBe("empty");
  expect(envelope.snapshot.receipts.availability).toBe("empty");

  await page.goto("/");
  await expectWorkspaceState(page, "Live workspace");

  await openPrimaryView(page, "Work");
  await expect(page.getByRole("heading", { name: "Work" })).toBeVisible();
  await expect(page.getByText("No work has been decomposed")).toBeVisible();

  await openPrimaryView(page, "Runs");
  await expect(page.getByRole("heading", { name: "Runs" })).toBeVisible();
  await expect(page.getByText("No attempts recorded")).toBeVisible();

  await openPrimaryView(page, "Proof");
  await expect(page.getByRole("heading", { name: "Proof" })).toBeVisible();
  await expect(
    page.getByText("No settlements have emitted receipts."),
  ).toBeVisible();

  await openPrimaryView(page, "Health");
  await expect(page.getByRole("heading", { name: "Health" })).toBeVisible();

  await openPrimaryView(page, "Journey");
  await expect(
    page.getByRole("region", { name: "Method journey", exact: true }),
  ).toBeVisible();
});

test("fits its viewport and switches to semantic navigation on mobile", async ({
  page,
}) => {
  await requireLiveContract(page);
  await page.goto("/");
  await expectWorkspaceState(page, "Live workspace");

  const viewport = page.viewportSize();
  if (!viewport) throw new Error("Playwright viewport is required");
  const geometry = await page.evaluate(() => ({
    viewportWidth: document.documentElement.clientWidth,
    documentWidth: document.documentElement.scrollWidth,
    viewportHeight: window.innerHeight,
    documentHeight: document.documentElement.scrollHeight,
    bodyHeight: document.body.scrollHeight,
  }));
  expect(geometry.documentWidth).toBeLessThanOrEqual(
    geometry.viewportWidth + 1,
  );
  if (viewport.width >= 768) {
    expect(geometry.documentHeight).toBeLessThanOrEqual(
      geometry.viewportHeight + 1,
    );
    expect(geometry.bodyHeight).toBeLessThanOrEqual(geometry.viewportHeight + 1);
  }

  if (viewport.width < 768) {
    await expect(page.locator(".mobile-nav")).toBeVisible();
    await expect(page.locator(".mobile-pass-list")).toBeVisible();
    await expect(page.locator(".lineage-surface__desktop")).toBeHidden();
  } else {
    await expect(page.locator(".mobile-nav")).toBeHidden();
    await expect(page.locator(".lineage-surface__desktop")).toBeVisible();
  }
});

test("passes WCAG A/AA automated checks and exposes a visible stale state", async ({
  page,
}) => {
  const live = await requireLiveContract(page);
  await page.route("**/api/events", (route) => route.abort("failed"));
  await page.route("**/api/snapshot", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        ...live,
        transport: {
          stale: true,
          servedAt: new Date().toISOString(),
          error: {
            code: "SNAPSHOT_REFRESH_FAILED",
            message: "The CLI snapshot could not be refreshed.",
          },
        },
      }),
    });
  });

  await page.goto("/");
  await expectWorkspaceState(page, "Last-good snapshot");
  await expect(
    page.getByText("The CLI snapshot could not be refreshed."),
  ).toBeVisible();

  const results = await new AxeBuilder({ page })
    .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa"])
    .analyze();
  expect(
    results.violations,
    results.violations
      .map(
        (violation) =>
          `${violation.id}: ${violation.help} (${violation.nodes.length} nodes)`,
      )
      .join("\n"),
  ).toEqual([]);
});
