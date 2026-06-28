import WebSocket from "ws";
import type { Entity } from "./EstadaProfessionalAutomationRule.js";

export type EntityStateValue = string | number | boolean | null | undefined;

type StateChangedCallback = (
  entity: Entity,
  oldEntity?: Entity,
) => void | Promise<void>;

export class HomeAssistantClient {
  private ws?: WebSocket;
  private nextId = 1;
  private entities = new Map<string, Entity>();
  private callbacks: StateChangedCallback[] = [];

  constructor(
    private readonly url: string,
    private readonly token: string,
  ) {}

  getEntity(entityName: string): Entity | undefined {
    return this.entities.get(this.normalizeEntityId(entityName));
  }

  onStateChanged(callback: StateChangedCallback): void {
    this.callbacks.push(callback);
  }

  async connectForever(): Promise<void> {
    for (;;) {
      try {
        await this.connectOnce();
      } catch (error) {
        console.error("[HA] connection failed", error);
      }
      await new Promise((resolve) => setTimeout(resolve, 5000));
    }
  }

  async setEntity(
    value: EntityStateValue,
    entityName: string,
    attributeName?: string,
  ): Promise<void> {
    const entityId = this.normalizeEntityId(entityName);

    if (attributeName && attributeName !== "state") {
      const currentEntity = this.entities.get(entityId);
      const nextState = currentEntity?.state ?? "unknown";
      const nextAttributes = {
        ...(currentEntity?.attributes ?? {}),
        [attributeName]: value,
      };

      await this.sendCommand({
        type: "rest_command",
        path: `/api/states/${entityId}`,
        method: "POST",
        content_type: "application/json",
        payload: JSON.stringify({
          state: String(nextState),
          attributes: nextAttributes,
        }),
      });

      this.entities.set(entityId, {
        entity_id: entityId,
        state: nextState,
        attributes: nextAttributes,
        last_changed: currentEntity?.last_changed,
        last_updated: new Date().toISOString(),
      });
      return;
    }

    const domain = entityId.split(".")[0];

    if (
      domain === "switch" ||
      domain === "input_boolean" ||
      domain === "light"
    ) {
      const service = this.valueToBoolean(value) ? "turn_on" : "turn_off";
      await this.sendCommand({
        type: "call_service",
        domain,
        service,
        service_data: { entity_id: entityId },
      });
      return;
    }

    await this.sendCommand({
      type: "rest_command",
      path: `/api/states/${entityId}`,
      method: "POST",
      content_type: "application/json",
      payload: JSON.stringify({ state: String(value) }),
    });
  }

  private async connectOnce(): Promise<void> {
    this.ws = new WebSocket(this.url);
    let connectionError: Error | undefined;

    this.ws.on("message", (raw) => {
      void (async () => {
        try {
          const msg = JSON.parse(raw.toString());
          if (msg.type === "auth_required") {
            this.ws?.send(
              JSON.stringify({ type: "auth", access_token: this.token }),
            );
          } else if (msg.type === "auth_ok") {
            console.log("[HA] authenticated");
            await this.loadInitialStates();
            await this.subscribeStateChanged();
          } else if (
            msg.type === "event" &&
            msg.event?.event_type === "state_changed"
          ) {
            await this.handleStateChanged(msg.event.data);
          } else if (msg.type === "auth_invalid") {
            connectionError = new Error(
              `Home Assistant auth invalid: ${msg.message}.`,
            );
            this.ws?.close();
          }
        } catch (error) {
          connectionError =
            error instanceof Error ? error : new Error(String(error));
          this.ws?.close();
        }
      })();
    });

    await new Promise<void>((resolve, reject) => {
      this.ws?.once("open", () => resolve());
      this.ws?.once("error", reject);
      this.ws?.once("close", () =>
        reject(new Error("Home Assistant websocket closed")),
      );
    });

    await new Promise<void>((_resolve, reject) => {
      this.ws?.once("close", () =>
        reject(connectionError ?? new Error("Home Assistant websocket closed")),
      );
      this.ws?.once("error", (error) => reject(connectionError ?? error));
    });
  }

  private async loadInitialStates(): Promise<void> {
    const result = await this.sendCommand({ type: "get_states" });
    for (const state of result as Entity[]) {
      this.entities.set(state.entity_id, state);
    }
    console.log(`[HA] loaded ${this.entities.size} entities`);
  }

  private async subscribeStateChanged(): Promise<void> {
    await this.sendCommand({
      type: "subscribe_events",
      event_type: "state_changed",
    });
  }

  private async handleStateChanged(data: {
    entity_id: string;
    old_state?: Entity;
    new_state?: Entity;
  }): Promise<void> {
    if (!data.new_state) {
      return;
    }

    const oldEntity = data.old_state;
    const newEntity = data.new_state;
    this.entities.set(newEntity.entity_id, newEntity);

    for (const callback of this.callbacks) {
      await callback(newEntity, oldEntity);
    }
  }

  private async sendCommand(
    payload: Record<string, unknown>,
  ): Promise<unknown> {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
      throw new Error("Home Assistant websocket is not connected.");
    }

    const id = this.nextId++;
    const command = { id, ...payload };

    return new Promise((resolve, reject) => {
      const onMessage = (raw: WebSocket.RawData) => {
        const msg = JSON.parse(raw.toString());
        if (msg.id !== id) {
          return;
        }

        this.ws?.off("message", onMessage);
        if (msg.success === false) {
          reject(new Error(JSON.stringify(msg.error)));
        } else {
          resolve(msg.result);
        }
      };

      this.ws?.on("message", onMessage);
      this.ws?.send(JSON.stringify(command));
    });
  }

  private normalizeEntityId(entityName: string): string {
    return entityName.includes(".") ? entityName : `switch.${entityName}`;
  }

  private valueToBoolean(value: EntityStateValue): boolean {
    return value === true || value === "on" || value === "true" || value === 1;
  }
}
