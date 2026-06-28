import { mkdir, copyFile, access, writeFile, readdir } from "node:fs/promises";
import { constants } from "node:fs";
import path from "node:path";
import { build } from "esbuild";
import { pathToFileURL } from "node:url";
import chokidar from "chokidar";
import {
  EstadaProfessionalAutomationRule,
  type Entity,
} from "./EstadaProfessionalAutomationRule.js";
import { HomeAssistantClient } from "./HomeAssistantClient.js";

const RULES_PATH = process.env.RULES_PATH || "/config/Estada_PA";
const TEMPLATE_PATH = "/app/project-template";
const COMPILE_ERROR_LOG = "/config/Estada_PA_CompileErrors.log";
const BUILD_PATH = "/tmp/estada_pa_build";
const HA_URL = process.env.HA_URL || "ws://supervisor/core/websocket";

const rawHaToken = process.env.HA_TOKEN ?? process.env.SUPERVISOR_TOKEN;
const HA_TOKEN = rawHaToken
  ?.trim()
  .replace(/^['\"]|['\"]$/g, "")
  .replace(/^Bearer\s+/i, "")
  .trim();

function isRuleSourceFile(fileName: string): boolean {
  return fileName.endsWith(".ts") && !fileName.endsWith(".d.ts");
}

// Keep template rules simple by making the base class available as a global symbol.
(
  globalThis as {
    EstadaProfessionalAutomationRule?: typeof EstadaProfessionalAutomationRule;
  }
).EstadaProfessionalAutomationRule = EstadaProfessionalAutomationRule;

async function exists(filePath: string): Promise<boolean> {
  try {
    await access(filePath, constants.F_OK);
    return true;
  } catch {
    return false;
  }
}

async function copyIfMissing(source: string, target: string): Promise<void> {
  if (await exists(target)) {
    console.log(`[estada-pa] keeping existing file: ${target}`);
    return;
  }

  await mkdir(path.dirname(target), { recursive: true });
  await copyFile(source, target);
  console.log(`[estada-pa] created starter file: ${target}`);
}

async function ensureStarterProject(): Promise<void> {
  await mkdir(RULES_PATH, { recursive: true });

  const templateFiles = await readdir(TEMPLATE_PATH);
  for (const fileName of templateFiles) {
    const source = path.join(TEMPLATE_PATH, fileName);
    const target = path.join(RULES_PATH, fileName);
    await copyIfMissing(source, target);
  }
}

async function compileRules(): Promise<string[]> {
  await mkdir(BUILD_PATH, { recursive: true });

  const files = (await readdir(RULES_PATH))
    .filter(isRuleSourceFile)
    .map((fileName) => path.join(RULES_PATH, fileName));

  if (files.length === 0) {
    console.log(`[estada-pa] no TypeScript rules found in ${RULES_PATH}`);
    return [];
  }

  try {
    await build({
      entryPoints: files,
      outdir: BUILD_PATH,
      bundle: false,
      platform: "node",
      format: "esm",
      target: "node22",
      sourcemap: true,
      logLevel: "silent",
    });

    await writeFile(COMPILE_ERROR_LOG, "", "utf8");
    console.log(`[estada-pa] compiled ${files.length} rule file(s)`);
    return files.map((file) =>
      path.join(BUILD_PATH, path.basename(file).replace(/\.ts$/, ".js")),
    );
  } catch (error) {
    const message =
      error instanceof Error ? error.stack || error.message : String(error);
    await writeFile(COMPILE_ERROR_LOG, message, "utf8");
    console.error(
      `[estada-pa] compile failed. Details written to ${COMPILE_ERROR_LOG}`,
    );
    return [];
  }
}

async function loadRules(
  compiledFiles: string[],
  haClient: HomeAssistantClient,
): Promise<EstadaProfessionalAutomationRule[]> {
  const loadedRules: EstadaProfessionalAutomationRule[] = [];

  for (const compiledFile of compiledFiles) {
    try {
      const moduleUrl = `${pathToFileURL(compiledFile).href}?t=${Date.now()}`;
      const imported = await import(moduleUrl);
      const RuleClass = imported.default;

      if (typeof RuleClass !== "function") {
        console.warn(`[estada-pa] ${compiledFile} has no default export`);
        continue;
      }

      const rule = new RuleClass();
      rule.attachHost({
        getEntity: (entityName: string) => haClient.getEntity(entityName),
        setValue: async (
          value: string | number | boolean | null | undefined,
          entityName: string,
          attributeName?: string,
        ) => {
          await haClient.setEntity(value, entityName, attributeName);
        },
        log: (message: string) => console.log(`[estada-pa] ${message}`),
        error: (message: string, error?: unknown) =>
          console.error(`[estada-pa] ${message}`, error),
      });

      if (typeof rule.run === "function") {
        const result = await rule.run();
        console.log(
          `[estada-pa] rule ${RuleClass.name || compiledFile} run() => ${result}`,
        );

        if (result !== false) {
          loadedRules.push(rule);
        }
      }
    } catch (error) {
      console.error(`[estada-pa] failed to load rule ${compiledFile}`, error);
    }
  }

  return loadedRules;
}

async function compileAndLoad(
  haClient: HomeAssistantClient,
): Promise<EstadaProfessionalAutomationRule[]> {
  const compiledFiles = await compileRules();
  return await loadRules(compiledFiles, haClient);
}

function getChangedProperties(
  oldEntity: Entity | undefined,
  newEntity: Entity,
): Array<[string, unknown, unknown]> {
  const changes: Array<[string, unknown, unknown]> = [];

  if (!oldEntity || oldEntity.state !== newEntity.state) {
    changes.push(["state", oldEntity?.state, newEntity.state]);
  }

  const keys = new Set([
    ...Object.keys(oldEntity?.attributes ?? {}),
    ...Object.keys(newEntity.attributes ?? {}),
  ]);

  for (const key of keys) {
    const oldValue = oldEntity?.attributes?.[key];
    const newValue = newEntity.attributes?.[key];
    if (JSON.stringify(oldValue) !== JSON.stringify(newValue)) {
      changes.push([key, oldValue, newValue]);
    }
  }

  return changes;
}

async function main(): Promise<void> {
  console.log("[estada-pa] Estada Professional Automation starting");
  console.log(`[estada-pa] rules path: ${RULES_PATH}`);

  if (!HA_TOKEN) {
    throw new Error(
      "HA_TOKEN is missing. Ensure homeassistant_api is enabled or set HA_TOKEN explicitly.",
    );
  }

  const haClient = new HomeAssistantClient(HA_URL, HA_TOKEN);
  let activeRules: EstadaProfessionalAutomationRule[] = [];

  await ensureStarterProject();
  activeRules = await compileAndLoad(haClient);

  haClient.onStateChanged(async (newEntity, oldEntity) => {
    const changes = getChangedProperties(oldEntity, newEntity);
    for (const [propertyName, oldValue, newValue] of changes) {
      for (const rule of activeRules) {
        rule.onEntityChange(newEntity, propertyName, oldValue, newValue);
      }
    }
  });

  chokidar
    .watch(RULES_PATH, {
      ignoreInitial: true,
      depth: 0,
    })
    .on("all", async (event, filePath) => {
      const fileName = path.basename(filePath);
      if (!isRuleSourceFile(fileName)) {
        return;
      }

      console.log(`[estada-pa] ${event}: ${filePath}`);
      activeRules = await compileAndLoad(haClient);
    });

  await haClient.connectForever();
}

main().catch(async (error) => {
  const message =
    error instanceof Error ? error.stack || error.message : String(error);
  await writeFile(COMPILE_ERROR_LOG, message, "utf8").catch(() => undefined);
  console.error("[estada-pa] fatal startup error", error);
  process.exit(1);
});
