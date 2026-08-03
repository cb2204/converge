export class SnapshotService {
  constructor({ build, cacheMs = 1_500 }) {
    this.build = build;
    this.cacheMs = cacheMs;
    this.cached = null;
    this.cachedAt = 0;
    this.inFlight = null;
  }

  async getSnapshot({ fresh = false } = {}) {
    const cacheIsCurrent =
      this.cached && Date.now() - this.cachedAt < this.cacheMs;
    if (!fresh && cacheIsCurrent) {
      return this.cached;
    }
    if (this.inFlight) {
      return this.inFlight;
    }

    this.inFlight = Promise.resolve()
      .then(() => this.build())
      .then((snapshot) => {
        this.cached = snapshot;
        this.cachedAt = Date.now();
        return snapshot;
      })
      .finally(() => {
        this.inFlight = null;
      });
    return this.inFlight;
  }
}
