export class HomeAssistantClient {
  constructor(
    private readonly url: string = process.env.HA_URL || "http://supervisor/core",
    private readonly token: string | undefined = process.env.SUPERVISOR_TOKEN
  ) {}

  get baseUrl(): string {
    return this.url;
  }

  get hasToken(): boolean {
    return Boolean(this.token);
  }
}
