declare abstract class EstadaProfessionalAutomationRule {
  abstract run(): boolean | Promise<boolean>;

  onEntityChange(
    entity: { entity_id: string; state?: unknown; attributes?: Record<string, unknown> },
    propertyName: string,
    oldValue: unknown,
    newValue: unknown
  ): void;

  registerObserver(
    entityName: string,
    propertyName: string | undefined,
    callback: (oldValue: unknown, newValue: unknown) => void
  ): void;
}
