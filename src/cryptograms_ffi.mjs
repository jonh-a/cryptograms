export function moveToNextField(nextFieldID) {
  const inputs = Array.from(document
    .querySelectorAll('input'))
    .filter((input) => {
      return parseInt(input.id) >= parseInt(nextFieldID)
    });

  for (let i = 0; i < inputs.length; i++) {
    if (inputs[i].value === '') {
      inputs[i].focus();
      return parseInt(inputs[i].id);
    }
  }
}
