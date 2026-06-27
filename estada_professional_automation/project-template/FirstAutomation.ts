export default class FirstAutomation extends EstadaProfessionalAutomationRule {
  run(): boolean {
    console.log("FirstAutomation is running.");

    this.registerObserver("switch.test1", "state", (oldValue, newValue) => {
      console.log(`switch.test1 changed from ${oldValue} to ${newValue}`);

      setTimeout(() => {
        console.log("TODO: set switch.test to the inverse of switch.test1");
      }, 1000);
    });

    return true;
  }
}
