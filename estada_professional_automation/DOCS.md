# Estada Professional Automation Docs

## First start

On first start the add-on creates:

```text
/config/Estada_PA/
  README.md
  tsconfig.json
  globals.d.ts
  FirstAutomation.ts
```

## Rule files

Every `*.ts` file in `/config/Estada_PA` may default-export one class derived from `EstadaProfessionalAutomationRule`.
