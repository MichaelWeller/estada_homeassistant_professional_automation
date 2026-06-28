export default class DelayedInvertTestRule extends EstadaProfessionalAutomationRule {
  private timer?: ReturnType<typeof setTimeout>;

  run(): boolean {
    this.onEntityChanged(
      "input_boolean.test1",
      "state",
      async (_oldValue, newValue) => {
        if (this.timer) {
          clearTimeout(this.timer);
        }

        const test1IsOn = newValue === "on" || newValue === true;
        const targetValue = !test1IsOn;

        this.timer = setTimeout(async () => {
          await this.setEntity(targetValue, "input_boolean.test2");
          this.log(`input_boolean.test2 set to ${targetValue ? "on" : "off"}`);
        }, 1000);
      },
    );

    return true;
  }
}
