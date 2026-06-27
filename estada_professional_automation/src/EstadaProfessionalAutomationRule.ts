export type Entity = {
  entity_id: string;
  state?: unknown;
  attributes?: Record<string, unknown>;
};

export type ObserverCallback = (oldValue: unknown, newValue: unknown) => void;

export abstract class EstadaProfessionalAutomationRule {
  private readonly observers: Array<{
    entityName: string;
    propertyName?: string;
    callback: ObserverCallback;
  }> = [];

  abstract run(): boolean | Promise<boolean>;

  onEntityChange(
    entity: Entity,
    propertyName: string,
    oldValue: unknown,
    newValue: unknown
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
    callback: ObserverCallback
  ): void {
    this.observers.push({ entityName, propertyName, callback });
  }
}
