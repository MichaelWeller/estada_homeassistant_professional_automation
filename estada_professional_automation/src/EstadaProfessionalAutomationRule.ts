export type Entity = {
  entity_id: string;
  state?: unknown;
  attributes?: Record<string, unknown>;
  last_changed?: string;
  last_updated?: string;
};

export type ObserverCallback = (oldValue: unknown, newValue: unknown) => void;

export type EstadaAutomationHostApi = {
  getEntity: (entityName: string) => Entity | undefined;
  setValue: (
    value: string | number | boolean | null | undefined,
    entityName: string,
    attributeName?: string,
  ) => Promise<void>;
  log: (message: string) => void;
  error: (message: string, error?: unknown) => void;
};

export abstract class EstadaProfessionalAutomationRule {
  private host?: EstadaAutomationHostApi;
  private readonly observers: Array<{
    entityName: string;
    propertyName?: string;
    callback: ObserverCallback;
  }> = [];

  abstract run(): boolean | Promise<boolean>;

  attachHost(host: EstadaAutomationHostApi): void {
    this.host = host;
  }

  onEntityChange(
    entity: Entity,
    propertyName: string,
    oldValue: unknown,
    newValue: unknown,
  ): void {
    for (const observer of this.observers) {
      if (observer.entityName !== entity.entity_id) {
        continue;
      }

      if (observer.propertyName && observer.propertyName !== propertyName) {
        continue;
      }

      observer.callback(oldValue, newValue);
    }
  }

  registerObserver(
    entityName: string,
    propertyName: string | undefined,
    callback: ObserverCallback,
  ): void {
    this.observers.push({ entityName, propertyName, callback });
  }

  onEntityChanged(
    entityName: string,
    propertyName: string = "state",
    callback: ObserverCallback,
  ): void {
    this.registerObserver(entityName, propertyName, callback);
  }

  protected getEntity(entityName: string): Entity | undefined {
    return this.host?.getEntity(entityName);
  }

  protected async setEntity(
    value: string | number | boolean | null | undefined,
    entityName: string,
    attributeName?: string,
  ): Promise<void> {
    if (!this.host) {
      throw new Error("Rule host is not attached yet.");
    }

    await this.host.setValue(value, entityName, attributeName);
  }

  protected log(message: string): void {
    this.host?.log(`${this.constructor.name}: ${message}`);
  }

  protected error(message: string, error?: unknown): void {
    this.host?.error(`${this.constructor.name}: ${message}`, error);
  }
}
